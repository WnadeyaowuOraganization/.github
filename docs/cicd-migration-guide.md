# CI/CD迁移指南 - 统一post-task.sh

## 背景

post-task.sh脚本已从各项目迁移到`.github`项目统一管理。
新的位置：`/home/ubuntu/projects/.github/scripts/post-task.sh`

## 迁移步骤

### 1. 更新GitHub Actions工作流

修改`.github/workflows/build-deploy-dev.yml`中的post-task步骤：

**旧配置：**
```yaml
      - name: 执行post-task脚本
        run: |
          cd /home/ubuntu/projects/wande-ai-backend
          git fetch origin ${{ github.ref_name }}
          git checkout ${{ github.ref_name }}
          git pull origin ${{ github.ref_name }}
          
          export REPO_FULL="WnadeyaowuOraganization/wande-ai-backend"
          export PROJECT_DIR="/home/ubuntu/projects/wande-ai-backend"
          export BRANCH="${{ github.ref_name }}"
          
          bash script/post-task.sh
```

**新配置：**
```yaml
      - name: 执行post-task脚本
        run: |
          cd /home/ubuntu/projects/wande-ai-backend
          git fetch origin ${{ github.ref_name }}
          git checkout ${{ github.ref_name }}
          git pull origin ${{ github.ref_name }}
          
          export REPO_FULL="WnadeyaowuOraganization/wande-ai-backend"
          export PROJECT_DIR="/home/ubuntu/projects/wande-ai-backend"
          export BRANCH="${{ github.ref_name }}"
          
          # 使用统一的post-task.sh
          bash /home/ubuntu/projects/.github/scripts/post-task.sh
```

### 2. 删除项目本地的post-task.sh

迁移完成后，可以删除各项目本地的`script/post-task.sh`：

```bash
rm /home/ubuntu/projects/wande-ai-backend/script/post-task.sh
rm /home/ubuntu/projects/wande-ai-front/script/post-task.sh
rm /home/ubuntu/projects/wande-data-pipeline/script/post-task.sh
# ... 其他项目
```

### 3. 更新编程CC的CLAUDE.md

在各项目的`CLAUDE.md`中，更新post-task.sh的引用路径：

**旧描述：**
```bash
bash script/post-task.sh
```

**新描述：**
```bash
bash /home/ubuntu/projects/.github/scripts/post-task.sh
```

## 优势

1. **统一管理**：一处修改，所有项目生效
2. **减少重复**：避免25+个项目的脚本重复
3. **便于维护**：修复bug只需修改一个文件
4. **一致性**：确保所有项目使用相同的post-task逻辑

## 注意事项

- 统一脚本依赖`/home/ubuntu/projects/.github/scripts/get-gh-token.sh`
- 确保环境变量`REPO_FULL`、`PROJECT_DIR`、`BRANCH`正确设置
- 各项目需要在G7e runner上执行，确保能访问统一脚本路径
