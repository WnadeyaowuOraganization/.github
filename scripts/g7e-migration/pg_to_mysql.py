#!/usr/bin/env python3
"""
PG → MySQL SQL 方言转换器（流式处理，支持大文件）

用法:
  python3 pg_to_mysql.py schema schema_pg.sql  > schema_mysql.sql
  python3 pg_to_mysql.py data   data_pg.sql    > data_mysql.sql

覆盖范围（够用即可，不追求 100% 完美）：
  Schema：
    - 去 public. 前缀，去 "xxx" 改 `xxx`
    - PG 类型 → MySQL 类型 (jsonb→json, timestamp→datetime, boolean→tinyint(1),
      text[]→json, uuid→varchar(36), bytea→longblob, serial/bigserial→auto_increment)
    - 去 OWNER TO / CREATE SEQUENCE / ALTER SEQUENCE / SELECT pg_catalog.*
    - 去 CREATE EXTENSION / SET / COMMENT ON
    - CREATE INDEX 的 USING gin|gist|ivfflat 改 USING btree
    - 主键约束 ALTER TABLE ... ADD CONSTRAINT ... PRIMARY KEY 保留
    - DEFAULT nextval(...) 改 AUTO_INCREMENT（保守处理）
    - DEFAULT CURRENT_TIMESTAMP 保留

  Data (INSERTs):
    - INSERT INTO public.x → INSERT INTO `x`
    - 去类型 cast ::type
    - E'...' → '...'
    - true/false → 1/0（仅在 VALUE 列表内，字符串内保留）
    - PG 数组 '{a,b,c}' → '["a","b","c"]' (JSON)
"""
import re
import sys

def convert_schema(text: str) -> str:
    out = []
    skip_block = False
    in_func_body = False  # PL/pgSQL 函数体 $$...$$
    for line in text.splitlines():
        stripped = line.strip()

        # 函数体块：任何 $$ 都翻转状态（成对出现）
        dd_count = stripped.count('$$')
        if in_func_body:
            if dd_count >= 1:
                in_func_body = False
                # 若同一行有两个 $$（罕见），保持为 False
                if dd_count >= 2:
                    in_func_body = False
            continue
        if dd_count >= 1:
            # 行内出现 $$，进入函数体（除非同一行也关闭，dd_count>=2）
            if dd_count == 1:
                in_func_body = True
            continue

        # 整行跳过的模式
        if not stripped or stripped.startswith('--') or stripped.startswith('\\'):
            continue
        if stripped.startswith(('SET ', 'SELECT pg_catalog.', 'COMMENT ON ',
                                'CREATE EXTENSION', 'CREATE SCHEMA',
                                'ALTER SCHEMA', 'ALTER DATABASE',
                                'ALTER TYPE', 'CREATE TYPE',
                                'CREATE FUNCTION', 'CREATE OR REPLACE FUNCTION',
                                'CREATE TRIGGER', 'CREATE PROCEDURE',
                                'REVOKE', 'GRANT',
                                'CREATE PUBLICATION', 'CREATE SUBSCRIPTION',
                                'ALTER PUBLICATION',
                                'CREATE POLICY', 'ALTER TABLE ONLY')):
            skip_block = True
        if skip_block:
            if stripped.endswith(';') or stripped.endswith('$$;'):
                skip_block = False
            continue

        # 去 OWNER / 所有权
        if 'OWNER TO' in stripped:
            continue
        # CREATE SEQUENCE / ALTER SEQUENCE 跳过（我们用 AUTO_INCREMENT 代替）
        if re.match(r'(CREATE|ALTER)\s+SEQUENCE\b', stripped, re.I):
            skip_block = True
            if stripped.endswith(';'):
                skip_block = False
            continue

        # 标识符：去 public. 前缀
        line = re.sub(r'\bpublic\.', '', line)

        # 引号：PG " " → MySQL ` `
        # 只替换在标识符上下文（表名/列名位置），这里保守用双引号→反引号
        line = re.sub(r'"([a-zA-Z_][a-zA-Z0-9_]*)"', r'`\1`', line)

        # 类型映射
        type_map = [
            (r'\btimestamp without time zone\b', 'DATETIME'),
            (r'\btimestamp with time zone\b', 'DATETIME'),
            (r'\btimestamptz\b', 'DATETIME'),
            (r'\btimestamp\b(?!\s*\()', 'DATETIME'),
            (r'\bjsonb\b', 'JSON'),
            (r'\btext\[\]', 'JSON'),
            (r'\bvarchar\[\]', 'JSON'),
            (r'\binteger\[\]', 'JSON'),
            (r'\bbigint\[\]', 'JSON'),
            (r'\bboolean\b', 'TINYINT(1)'),
            (r'\bbool\b', 'TINYINT(1)'),
            (r'\buuid\b', 'VARCHAR(36)'),
            (r'\binet\b', 'VARCHAR(45)'),
            (r'\bbytea\b', 'LONGBLOB'),
            (r'\bbigserial\b', 'BIGINT AUTO_INCREMENT'),
            (r'\bserial\b', 'INT AUTO_INCREMENT'),
            (r'\bdouble precision\b', 'DOUBLE'),
            (r'\breal\b', 'FLOAT'),
            (r'\bcharacter varying\b', 'VARCHAR'),
            (r'\bcharacter\(', 'CHAR('),
            (r'\bvector\([0-9]+\)', 'JSON'),     # pgvector 退化为 JSON 数组
        ]
        for pat, rep in type_map:
            line = re.sub(pat, rep, line, flags=re.I)

        # DEFAULT nextval(...) → 留空（因 PK 改 AUTO_INCREMENT）
        line = re.sub(r"DEFAULT\s+nextval\([^)]+\)(::[a-zA-Z_]+)?", '', line, flags=re.I)
        # 去残余类型 cast (::TYPE 或 ::"Type") — 必须大小写不敏感
        line = re.sub(r"::[a-zA-Z_][a-zA-Z0-9_\[\] ]*", '', line)
        # DEFAULT true/false → 1/0
        line = re.sub(r'DEFAULT\s+true\b', 'DEFAULT 1', line, flags=re.I)
        line = re.sub(r'DEFAULT\s+false\b', 'DEFAULT 0', line, flags=re.I)
        # DEFAULT now() / current_timestamp → CURRENT_TIMESTAMP
        line = re.sub(r'\bDEFAULT\s+now\(\)', 'DEFAULT CURRENT_TIMESTAMP', line, flags=re.I)
        # MySQL 不支持 CHECK(col = ANY(ARRAY[...]))，整行删这些约束
        if re.match(r'\s*CONSTRAINT\s+\S+\s+CHECK\b', line, re.I):
            # 去尾部逗号，删除整行
            continue

        # MySQL 不允许 TEXT/JSON/BLOB 列有 DEFAULT（1101）— 除非 DEFAULT (expr)
        # 去掉这类列的 DEFAULT 子句
        line = re.sub(r"(\b(?:TEXT|JSON|LONGBLOB|BLOB)\b)\s+DEFAULT\s+'[^']*'",
                      r'\1', line, flags=re.I)
        line = re.sub(r"(\b(?:TEXT|JSON|LONGBLOB|BLOB)\b)\s+DEFAULT\s+[^,\s]+",
                      r'\1', line, flags=re.I)

        # 残余 PG 数组类型 `foo text[]` 已被 type_map 覆盖，但若仍有 `[]` 残影删掉
        line = re.sub(r'\[\]', '', line)

        # gen_random_uuid() / uuid_generate_v4() → 空 DEFAULT
        line = re.sub(r"DEFAULT\s+(gen_random_uuid|uuid_generate_v4)\s*\(\s*\)", '', line, flags=re.I)

        # CREATE INDEX USING gin/gist/ivfflat → btree
        line = re.sub(r'USING\s+(gin|gist|ivfflat|spgist|brin)', 'USING btree', line, flags=re.I)

        # 去 WITH (OIDS=FALSE) / WITH 子句（PG 表选项）
        line = re.sub(r'\bWITH\s*\([^)]*\)', '', line)
        # 去 TABLESPACE
        line = re.sub(r'\bTABLESPACE\s+\S+', '', line)

        # AS IDENTITY / GENERATED ALWAYS AS IDENTITY → AUTO_INCREMENT
        line = re.sub(r'GENERATED\s+(ALWAYS|BY\s+DEFAULT)\s+AS\s+IDENTITY(?:\s*\([^)]*\))?',
                      'AUTO_INCREMENT', line, flags=re.I)

        out.append(line)

    return '\n'.join(out) + '\n'


# --- data 转换（每行一个 INSERT，流式处理）---
INSERT_RE = re.compile(r'^INSERT INTO (?:public\.)?"?([a-zA-Z_][a-zA-Z0-9_]*)"?\s*\(')

def convert_data_line(line: str) -> str:
    if not line.startswith('INSERT INTO'):
        return ''
    # 换表名引用风格 public.x → `x`
    line = re.sub(r'INSERT INTO public\."?([a-zA-Z_][a-zA-Z0-9_]*)"?', r'INSERT INTO `\1`', line)
    line = re.sub(r'INSERT INTO "([a-zA-Z_][a-zA-Z0-9_]*)"', r'INSERT INTO `\1`', line)

    # 列名双引号 → 反引号
    # 仅处理括号列表里的 "col"
    def fix_cols(m):
        inside = m.group(1)
        fixed = re.sub(r'"([a-zA-Z_][a-zA-Z0-9_]*)"', r'`\1`', inside)
        return '(' + fixed + ')'
    line = re.sub(r'\(((?:"[^"]+"(?:,\s*)?)+)\)\s+VALUES', lambda m: fix_cols(m) + ' VALUES', line)

    # 去类型 cast `::jsonb` `::character varying` 等
    line = re.sub(r"::[a-zA-Z_][a-zA-Z0-9_\[\] ]*", '', line)

    # E'...' 转义字符串 → '...' （MySQL 默认也能处理 \n）
    line = re.sub(r"E'", "'", line)

    # PG datetime 时区后缀 '+00' / '-05' 剥离 （MySQL DATETIME 不接受）
    # 匹配 '2026-04-02 15:30:10.123456+00' → '2026-04-02 15:30:10.123456'
    line = re.sub(r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d+)?)[+-]\d{2}(?::\d{2})?'",
                  r"\1'", line)

    # true/false → 1/0（在 VALUE 列表里，但字符串内也可能有 true/false。
    # 采用简单策略：整词 true/false 后跟 , 或 ) 的替换为 1/0）
    line = re.sub(r'\btrue\b(\s*[,)])', r'1\1', line)
    line = re.sub(r'\bfalse\b(\s*[,)])', r'0\1', line)

    # PG 数组字面量 '{a,b,c}' → '["a","b","c"]'
    # 保守处理：仅当 '{...}' 整段内无引号嵌套时转换
    def array_to_json(m):
        inner = m.group(1)
        if not inner:
            return "'[]'"
        items = [x.strip() for x in inner.split(',')]
        quoted = ['"' + x.replace('"','\\"') + '"' for x in items]
        return "'[" + ','.join(quoted) + "]'"
    line = re.sub(r"'\{([^{}']*)\}'", array_to_json, line)

    return line


def main():
    mode = sys.argv[1]
    path = sys.argv[2]
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        if mode == 'schema':
            print("SET FOREIGN_KEY_CHECKS=0;")
            print("SET UNIQUE_CHECKS=0;")
            print("SET sql_mode='NO_ENGINE_SUBSTITUTION';")
            text = f.read()
            sys.stdout.write(convert_schema(text))
            print("SET FOREIGN_KEY_CHECKS=1;")
        elif mode == 'data':
            print("SET FOREIGN_KEY_CHECKS=0;")
            print("SET UNIQUE_CHECKS=0;")
            n = 0
            buf = None  # 累积多行 INSERT
            for line in f:
                if buf is None:
                    if line.startswith('INSERT INTO'):
                        buf = line.rstrip('\n')
                    else:
                        continue
                else:
                    buf += '\n' + line.rstrip('\n')
                # 完整 INSERT 以 ");" 结尾（且不在字符串内部）—
                # 简化判断：以 ); 结尾（去尾部空白后）
                stripped = buf.rstrip()
                if stripped.endswith(');'):
                    # 字符串内换行 → \n 转义，避免 MySQL 解析错
                    out = convert_data_line(buf.replace('\n', '\\n'))
                    if out:
                        print(out)
                        n += 1
                    buf = None
            print("SET FOREIGN_KEY_CHECKS=1;")
            print(f"-- 共转换 {n} 条 INSERT", file=sys.stderr)
        else:
            print("mode must be schema or data", file=sys.stderr)
            sys.exit(1)

if __name__ == '__main__':
    main()
