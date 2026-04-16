#!/bin/bash
# ========================================
# 明道云数据一键部署脚本 (m7i)
# 在m7i上SSH执行即可完成全部部署
# 用法: bash m7i-deploy-all.sh
# ========================================
set -e

echo "============================================"
echo "  明道云数据部署 - m7i一键执行"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# ── Step 1: Git pull 获取表结构文档 ──
echo "📄 Step 1/3: 拉取表结构文档..."
cd /home/ubuntu/projects/.github
git pull origin main
echo "  ✅ 文档已同步到 docs/mdy-migration/"
ls -la docs/mdy-migration/
echo ""

# ── Step 2: 检查AWS CLI ──
echo "🔑 Step 2/3: 检查AWS CLI配置..."
if ! command -v aws &> /dev/null; then
    echo "  安装AWS CLI..."
    sudo apt install -y awscli
fi

# 检查是否已有凭据
if ! aws sts get-caller-identity &> /dev/null; then
    echo "  ⚠️  AWS凭据未配置，请先运行: aws configure"
    echo "     使用 shenzhen-nas-sync 用户的 Access Key"
    echo "     Region: us-east-1"
    exit 1
fi
echo "  ✅ AWS凭据已配置"
echo ""

# ── Step 3: 从S3下载数据 ──
echo "📦 Step 3/3: 从S3下载明道云数据..."
TARGET_DIR="/data/mdy-migration"
BUCKET="wande-nas-sync"
S3_PREFIX="万德明道云数据0316"

sudo mkdir -p "${TARGET_DIR}/mongodb"
sudo mkdir -p "${TARGET_DIR}/mysql"
sudo chown -R ubuntu:ubuntu "${TARGET_DIR}"

echo "  检查S3连接..."
aws s3 ls "s3://${BUCKET}/${S3_PREFIX}/" --region us-east-1 || {
    echo "❌ S3连接失败，请检查凭据"
    exit 1
}

echo ""
echo "  下载MongoDB数据 (9个文件, ~1GB)..."
for file in mdwsrows.tar.gz mdworkflow.tar.gz mdworksheetlog.tar.gz mdworksheet.tar.gz mdinbox.tar.gz mdservicedata.tar.gz mdintegration.tar.gz mdmap.tar.gz small_dbs.tar.gz; do
    echo "    ⬇️  ${file}..."
    aws s3 cp "s3://${BUCKET}/${S3_PREFIX}/mongodb/${file}" "${TARGET_DIR}/mongodb/${file}" --region us-east-1
done

echo ""
echo "  下载MySQL数据..."
echo "    ⬇️  mysql-dump.tar.gz..."
aws s3 cp "s3://${BUCKET}/${S3_PREFIX}/mysql/mysql-dump.tar.gz" "${TARGET_DIR}/mysql/mysql-dump.tar.gz" --region us-east-1

echo ""
echo "============================================"
echo "  ✅ 部署完成！"
echo "============================================"
echo ""
echo "📄 表结构文档:"
echo "   /home/ubuntu/projects/.github/docs/mdy-migration/mingdao_s3_data_mapping.md"
echo "   /home/ubuntu/projects/.github/docs/mdy-migration/mingdao_s3_data_mapping.json"
echo ""
echo "📦 数据文件:"
ls -lh "${TARGET_DIR}/mongodb/"
echo ""
ls -lh "${TARGET_DIR}/mysql/"
echo ""
echo "💾 总大小:"
du -sh "${TARGET_DIR}"
echo "============================================"
