# 工作流程

## 任务来源

**所有开发任务通过 GitHub Issue 下发，由调度器分配。**

调度器已完成：选定Issue → 创建工作目录 `./issues/issue-<N>` → 签出feature分支。
你启动时已在feature分支上，工作目录已创建。

**你需要做的第一件事**：
1. 执行 `gh issue view <N> --repo WnadeyaowuOraganization/wande-play/pipeline --comments` 读取Issue完整内容和所有评论
2. **恢复工作**：如果 `./issues/issue-<N>/task.md` 已存在，读取后继续

**跨项目依赖**：`blocked-by: backend#N`。格式：`WnadeyaowuOraganization/<repo>#<N>`

## 三阶段开发流程

### 第一阶段：准备

1. **读取Issue**：`gh issue view <N> --repo WnadeyaowuOraganization/wande-play/pipeline --comments`
2. **读取对应管线文档**：根据Issue类别读取 `docs/pipeline-*.md`
3. **创建 task.md**：在 `./issues/issue-<N>/` 下创建任务文件
4. **需求评估**：
   - **A: 可执行** → 继续第二阶段
   - **B: 需确认** → 标签改为 `status:plan` + **Project Status改为pause** → 结束
   - **C: 不可执行** → 标签改为 `status:blocked` + **Project Status改为pause** → 结束

   B/C情况下更新Project看板：
   ```bash
   bash /home/ubuntu/projects/.github/scripts/update-project-status.sh <N> "pause"
   ```

> 注意：工作目录和feature分支已由调度器pre-task创建。

### 第二阶段：开发 + 本地验证

1. 按 task 逐步开发采集脚本
2. **本地测试运行**：确保脚本可以正常执行（连接数据库、调用API等）
3. **验证数据落库**：检查目标表是否有正确的数据写入
4. 持续记录踩坑/发现到 task.md

#### ⛔ 验证门禁

| 检查项 | 验证方式 | 必须状态 |
|--------|---------|---------|
| 脚本可运行 | `python3 pipelines/xxx/script.py` 无报错 | PASS |
| 数据正确落库 | psql查询目标表有数据 | PASS |
| 表名规范 | 所有新表 `wdpp_` 前缀 + `create_time`/`update_time` | PASS |

### 第三阶段：提交收尾

1. **完善 task.md**：补充验收清单、完成情况、偏差说明、踩坑记录
2. **commit**：
   ```bash
   git add -A
   git commit -m "feat(管线类别): 功能描述 #<Issue号>"
   ```
3. **push feature分支**：
   ```bash
   git push origin feature-<功能描述>
   ```
4. **创建PR**：创建feature→dev的PR（body含 Fixes #N）


## git 分支规范

- **main**: 生产分支
- **dev**: 开发/测试分支
- **feature-<功能>**: 从 dev 签出（由调度器创建）


