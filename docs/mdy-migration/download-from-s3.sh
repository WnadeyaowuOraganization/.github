#!/bin/bash
# 明道云数据从S3下载到m7i本地
# 在m7i上执行: bash /home/ubuntu/projects/.github/docs/mdy-migration/download-from-s3.sh
# 
# 前提条件: 
#   - AWS CLI 已安装 (apt install awscli / pip install awscli)
#   - AWS credentials 已配置 (aws configure)
#     Access Key: AKIA5FXOC4FAPS6MYKVE
#     Region: us-east-1

set -e

TARGET_DIR="/data/mdy-migration"
BUCKET="wande-nas-sync"
S3_PREFIX="万德明道云数据0316"

echo "=========================================="
echo "明道云数据下载脚本"
echo "S3源: s3://${BUCKET}/${S3_PREFIX}/"
echo "目标: ${TARGET_DIR}/"
echo "=========================================="

# 创建目标目录
sudo mkdir -p "${TARGET_DIR}/mongodb"
sudo mkdir -p "${TARGET_DIR}/mysql"
sudo chown -R ubuntu:ubuntu "${TARGET_DIR}"

# 检查AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI 未安装。请先安装: sudo apt install awscli"
    exit 1
fi

# 检查S3访问
echo ""
echo "检查S3连接..."
aws s3 ls "s3://${BUCKET}/${S3_PREFIX}/" --region us-east-1 || {
    echo "❌ 无法访问S3桶。请先配置AWS credentials: aws configure"
    exit 1
}

echo ""
echo "开始下载..."
echo ""

# MongoDB files (9个)
MONGO_FILES=(
    "mdwsrows.tar.gz:189MB:核心业务数据行"
    "mdworkflow.tar.gz:559MB:审批流定义和历史"
    "mdworksheetlog.tar.gz:111MB:数据变更日志"
    "mdworksheet.tar.gz:15MB:表结构定义"
    "mdinbox.tar.gz:60MB:站内信通知"
    "mdservicedata.tar.gz:54MB:附件文件元数据"
    "mdintegration.tar.gz:29MB:集成配置"
    "mdmap.tar.gz:22MB:映射关系"
    "small_dbs.tar.gz:7MB:30+小型数据库"
)

echo "📦 下载MongoDB数据 (共9个文件)..."
for item in "${MONGO_FILES[@]}"; do
    IFS=':' read -r file size desc <<< "$item"
    echo "  ⬇️  ${file} (${size}) - ${desc}"
    aws s3 cp "s3://${BUCKET}/${S3_PREFIX}/mongodb/${file}" "${TARGET_DIR}/mongodb/${file}" --region us-east-1
done

# MySQL file (1个)
echo ""
echo "📦 下载MySQL数据..."
echo "  ⬇️  mysql-dump.tar.gz (5MB) - MySQL原始数据文件"
aws s3 cp "s3://${BUCKET}/${S3_PREFIX}/mysql/mysql-dump.tar.gz" "${TARGET_DIR}/mysql/mysql-dump.tar.gz" --region us-east-1

echo ""
echo "=========================================="
echo "✅ 下载完成！"
echo ""
echo "文件清单:"
ls -lh "${TARGET_DIR}/mongodb/"
echo ""
ls -lh "${TARGET_DIR}/mysql/"
echo ""
echo "总大小:"
du -sh "${TARGET_DIR}"
echo ""
echo "下一步: 解压并开始迁移"
echo "  cd ${TARGET_DIR}"
echo "  tar xzf mongodb/mdworksheet.tar.gz -C mongodb/  # 表结构定义"
echo "  tar xzf mongodb/small_dbs.tar.gz -C mongodb/     # 小型数据库"
echo "  tar xzf mongodb/mdwsrows.tar.gz -C mongodb/      # 核心数据行"
echo "=========================================="
