# API契约规范

> 前后端接口契约是前后端之间的**唯一接口真相源**。任何新增、修改、删除API都必须先更新契约文件，再实现代码。

## 目录结构

```
shared/api-contracts/
├── README.md              ← 本文档
├── cockpit/               ← 超管驾驶舱模块
│   ├── wecom.yaml
│   ├── approval.yaml
│   └── ...
├── crm/                   ← CRM模块
│   ├── opportunity.yaml
│   └── ...
├── execution/             ← 执行管理模块
├── d3/                    ← D3参数化设计模块
├── sales/                 ← 销售记录模块
└── ...                    ← 按业务模块分目录
```

## 契约文件格式（YAML）

```yaml
# 模块名: xxx
# 最后更新: 2026-04-04
# 关联Issue: #1234

endpoints:
  - method: GET
    path: /wande/xxx/list
    description: 分页查询列表
    auth: true
    permission: "wande:xxx:list"
    params:
      - name: pageNum
        in: query
        type: integer
        required: false
    response:
      code: 200
      data:
        type: PageInfo<XxxVo>
        fields:
          - name: id
            type: Long
          - name: name
            type: String

  - method: POST
    path: /wande/xxx
    description: 新增
    auth: true
    permission: "wande:xxx:add"
    body:
      type: XxxBo
      fields:
        - name: name
          type: String
          required: true
    response:
      code: 200
      data:
        type: XxxVo
```

## 契约规则

1. **契约先行** — 新增/修改API时，先更新契约文件，再写代码
2. **前后端共同遵守** — 后端Controller的路径和参数必须与契约一致，前端API调用也必须与契约一致
3. **fullstack Issue强制** — module:fullstack的Issue必须先提交契约才能开始编码
4. **backend/frontend Issue建议** — 涉及新增API的Issue也应同步更新契约
5. **一个模块一个目录** — 按业务模块分目录，一个yaml文件对应一组相关接口

## Agent Teams 联动开发（module:fullstack Issue专用）

### 触发条件

Issue标签包含 `module:fullstack`

### 接口契约优先原则

开发前后端联动功能前，必须先更新 `shared/api-contracts/` 下的契约文件：

1. 读取Issue全部内容，理解完整需求
2. 创建或更新对应模块的契约文件
3. 契约先commit: `contract: update xxx api contract for #N`
4. 然后才创建Agent Team

### 契约最低标准

- HTTP方法 (GET/POST/PUT/DELETE)
- 完整路径（含动态参数 `{paramName}`）
- 参数传递方式 (path/query/body)
- 参数类型定义
- 返回字段列表

### Agent Teams 创建模板

```
创建3-Agent团队开发Issue #N:
- Backend Agent: 在 backend/ 目录按契约实现API，参考 shared/api-contracts/
- Frontend Agent: 在 frontend/ 目录按契约实现页面，API调用必须与契约一致
- Integration Agent: 验证前后端一致性 — 前端API路径与后端@RequestMapping对比
```

### 文件隔离规则

- Backend Agent: 只改 backend/ 下的文件
- Frontend Agent: 只改 frontend/ 下的文件
- Integration Agent: 只改 e2e/、shared/ 下的文件

### 编译门控（全部通过才能提交）

- 后端: `cd backend && mvn clean compile -Pprod -DskipTests`
- 前端: `cd frontend && pnpm build`
- 契约一致性: shared/api-contracts/ 中所有路径在两端均有对应实现
