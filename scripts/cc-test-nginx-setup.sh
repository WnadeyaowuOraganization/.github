#!/bin/bash
# cc-test-nginx-setup.sh — 为所有kimi目录生成独立nginx配置
#
# 每个kimi{N}获得:
#   - 前端端口: 8100+N
#   - 前端静态文件: /apps/wande-ai-front-kimi{N}/
#   - /prod-api/ 代理到后端: 7100+N
#
# 用法:
#   sudo bash cc-test-nginx-setup.sh          # 生成全部20个配置
#   sudo bash cc-test-nginx-setup.sh kimi18   # 只生成kimi18

NGINX_CONF_DIR="/etc/nginx/sites-enabled"

generate_config() {
  local num=$1
  local tag="kimi${num}"
  local fe_port=$((8100 + num))
  local be_port=$((7100 + num))
  local front_dir="/apps/wande-ai-front-${tag}"
  local conf_file="${NGINX_CONF_DIR}/wande-${tag}"

  # 创建前端目录
  mkdir -p "$front_dir"

  # 如果没有前端文件，从dev复制
  if [ ! -f "$front_dir/index.html" ]; then
    if [ -d "/apps/wande-ai-front" ] && [ -f "/apps/wande-ai-front/index.html" ]; then
      rsync -a /apps/wande-ai-front/ "$front_dir/"
      echo "  复制dev前端到 $front_dir"
    fi
  fi

  cat > "$conf_file" << EOF
server {
    listen ${fe_port};
    server_name localhost;

    location / {
        root ${front_dir};
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /prod-api/ {
        proxy_pass http://127.0.0.1:${be_port}/;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 60s;
        proxy_read_timeout 120s;
        proxy_send_timeout 120s;
        client_max_body_size 50m;
    }
}
EOF

  echo "✓ ${tag}: frontend=${fe_port} -> backend=${be_port} (${front_dir})"
}

# === 主逻辑 ===
if [ -n "$1" ]; then
  # 单个kimi
  num=$(echo "$1" | grep -oE '[0-9]+$')
  if [ -z "$num" ]; then
    echo "用法: $0 [kimi{N}]"
    exit 1
  fi
  generate_config "$num"
else
  # 全部20个
  echo "生成20个kimi独立nginx配置..."
  for i in $(seq 1 20); do
    generate_config "$i"
  done
fi

# 测试并重载nginx
nginx -t 2>&1
if [ $? -eq 0 ]; then
  nginx -s reload
  echo ""
  echo "✅ nginx配置已生效"
else
  echo ""
  echo "❌ nginx配置有误，请检查"
  exit 1
fi
