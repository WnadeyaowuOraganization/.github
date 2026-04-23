---
name: excel-io
description: Excel 导入导出开发规范 — @ExcelProperty / @ExcelDictConvert 注解、ExcelUtil 工具、Controller 标准签名
type: skill
---

# Excel 导入导出规范

底层引擎：**FastExcel**（`cn.idev.excel`，非 EasyExcel）。统一入口 `org.ruoyi.common.excel.utils.ExcelUtil`。所有导入/导出 **必须** 通过 `ExcelUtil` 调用，禁止直接操作 POI / FastExcel 底层 API。

## 何时使用

- Controller 新增 `/export` 接口（`@SaCheckPermission("<模块>:<资源>:export"` + `BusinessType.EXPORT`）
- Controller 新增 `/importData` + `/importTemplate` 接口
- 列需做字典翻译、合并单元格、必填校验、下拉级联、图片列
- 处理上传的 xlsx/xls 文件

## VO 注解速查表

| 注解 | 位置 | 用途 |
|------|------|------|
| `@ExcelIgnoreUnannotated` | 类级（**推荐**，来自 `cn.idev.excel.annotation`） | 未加 `@ExcelProperty` 的字段不导出，避免 BaseEntity 公共字段污染表头 |
| `@ExcelProperty(value="中文表头")` | 字段 | 声明列名；顺序按字段声明顺序 |
| `@ExcelProperty(value="...", converter = ExcelDictConvert.class)` | 字段 | 字典翻译列，**必须**配合 `@ExcelDictFormat` |
| `@ExcelDictFormat(dictType = "sys_user_sex")` | 字段 | 指定字典 type；或用 `readConverterExp = "0=男,1=女"` 内联 |
| `@ExcelIgnore` | 字段 | 强制跳过（不用 `@ExcelIgnoreUnannotated` 时用） |
| `@ColumnWidth(20)` | 字段/类 | 列宽（字符数）；不写时走 `LongestMatchColumnWidthStyleStrategy` 自适应 |
| `@NumberFormat("#.##")` | 字段 | 数字格式化 |
| `@CellMerge(mergeBy="...")` | 字段 | 启用合并单元格（配合 `exportExcel(..., merge=true, ...)`） |
| `@ExcelRequired` | 字段 | 导入必填校验（`DataWriteHandler` 会在模板生成批注） |

**导出 VO 命名**：`XxxExportVO`（后缀大写 VO 或 Vo 均可，项目内两种并存）。**导入 VO 命名**：`XxxImportVo`。与业务 `XxxVo` 隔离，禁止复用列表 VO 做导出。

## 导出标准骨架

### VO

```java
@Data
@ExcelIgnoreUnannotated
public class ProjectMineExportVO implements Serializable {
    @Serial private static final long serialVersionUID = 1L;

    @ExcelProperty(value = "项目标题")
    private String projectName;

    @ExcelProperty(value = "状态", converter = ExcelDictConvert.class)
    @ExcelDictFormat(dictType = "project_mine_status")
    private String mineStatus;

    @ExcelProperty(value = "投资金额(万元)")
    private BigDecimal projectScale;
}
```

### Controller（返回 void，response 由 ExcelUtil 写）

```java
@SaCheckPermission("biz:tender:projectMine:export")
@Log(title = "项目矿场", businessType = BusinessType.EXPORT)
@GetMapping("/export")
public void export(ProjectMineListDTO dto, HttpServletResponse response) {
    List<ProjectMineExportVO> list = projectMineService.buildExportList(dto);
    ExcelUtil.exportExcel(list, "项目矿场", ProjectMineExportVO.class, response);
}
```

**铁律**：
- 方法签名 `public void`，**禁止** `R<Void>` / `ResponseEntity`（会破坏 Content-Type + 附件头）
- **禁止** Service 层直接写 response；Service 只返回 `List<ExportVO>`，Controller 调 `ExcelUtil.exportExcel`
- `@Log(businessType = BusinessType.EXPORT)` 必加（审计）
- 权限码结尾固定 `:export`
- 大数据量导出走分页循环 + `ExcelWriterWrapper`（`ExcelUtil.exportExcel(headType, os, consumer)`），**禁止**一次 `selectList` 全表

## 导入标准骨架

### 导入 VO（带校验注解）

```java
@Data
@ExcelIgnoreUnannotated
public class ProjectMineImportVo {
    @ExcelProperty(value = "项目标题")
    @NotBlank(message = "项目标题不能为空")
    private String projectName;

    @ExcelProperty(value = "状态", converter = ExcelDictConvert.class)
    @ExcelDictFormat(dictType = "project_mine_status")
    private String mineStatus;
}
```

### Listener（继承 `AnalysisEventListener` + 实现 `ExcelListener<T>`）

```java
@Slf4j
public class ProjectMineImportListener
    extends AnalysisEventListener<ProjectMineImportVo>
    implements ExcelListener<ProjectMineImportVo> {

    private final IProjectMineService service = SpringUtils.getBean(IProjectMineService.class);
    private int successNum = 0, failureNum = 0;
    private final StringBuilder successMsg = new StringBuilder();
    private final StringBuilder failureMsg = new StringBuilder();

    @Override
    public void invoke(ProjectMineImportVo vo, AnalysisContext ctx) {
        try {
            ValidatorUtils.validate(vo);           // 逐行 JSR-303 校验
            service.insertFromImport(vo);          // 单行入库（Service 内 @Transactional）
            successNum++;
            successMsg.append("<br/>").append(successNum).append("、").append(vo.getProjectName()).append(" 导入成功");
        } catch (Exception e) {
            failureNum++;
            String msg = e instanceof ConstraintViolationException cve
                ? StreamUtils.join(cve.getConstraintViolations(), ConstraintViolation::getMessage, ", ")
                : e.getMessage();
            failureMsg.append("<br/>").append(failureNum).append("、").append(vo.getProjectName()).append(" 导入失败：").append(msg);
            log.error("import error", e);
        }
    }

    @Override public void doAfterAllAnalysed(AnalysisContext ctx) { }

    @Override
    public ExcelResult<ProjectMineImportVo> getExcelResult() {
        return new ExcelResult<>() {
            public String getAnalysis() {
                if (failureNum > 0) {
                    failureMsg.insert(0, "导入失败，共 " + failureNum + " 条：");
                    throw new ServiceException(failureMsg.toString());
                }
                successMsg.insert(0, "导入成功，共 " + successNum + " 条：");
                return successMsg.toString();
            }
            public List<ProjectMineImportVo> getList() { return null; }
            public List<String> getErrorList() { return null; }
        };
    }
}
```

### Controller

```java
@Log(title = "项目矿场", businessType = BusinessType.IMPORT)
@SaCheckPermission("biz:tender:projectMine:import")
@PostMapping(value = "/importData", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
public R<Void> importData(@RequestPart("file") MultipartFile file, boolean updateSupport) throws Exception {
    ExcelResult<ProjectMineImportVo> result = ExcelUtil.importExcel(
        file.getInputStream(), ProjectMineImportVo.class, new ProjectMineImportListener(updateSupport));
    return R.ok(result.getAnalysis());
}

@PostMapping("/importTemplate")
public void importTemplate(HttpServletResponse response) {
    ExcelUtil.exportExcel(new ArrayList<>(), "项目矿场导入模板", ProjectMineImportVo.class, response);
}
```

**批量入库优化**：listener 内累计到阈值（如 200 行）`batchInsert` 一次，`doAfterAllAnalysed` 冲刷剩余；Service 方法 `@Transactional(rollbackFor = Exception.class)`。

## 进阶

### 字典翻译

VO 字段用 `converter = ExcelDictConvert.class` + `@ExcelDictFormat(dictType="...")`。导出：值 → label；导入：label → 值（自动反查 `DictService`）。无字典时可用 `readConverterExp = "0=男,1=女,2=未知"` 内联。

### 合并单元格

VO 字段加 `@CellMerge(mergeBy="分组字段")`，Controller 用 `ExcelUtil.exportExcel(list, sheetName, clazz, true, response)`（`merge=true`）。

### 下拉框 / 级联下拉

`ExcelUtil.exportExcel(list, sheetName, clazz, response, List<DropDownOptions> options)`。`DropDownOptions` 见 `org.ruoyi.common.excel.core.DropDownOptions`。

### 图片列

VO 字段声明为 `byte[]` / `URL` / `File` / `InputStream`，FastExcel 自动识别；行高需配 `@ContentRowHeight(60)`。

### 模板填充（固定格式报表）

模板放 `ruoyi-admin/src/main/resources/excel/xxx.xlsx`，占位 `{.属性}` / `{key.属性}`，用 `ExcelUtil.exportTemplate` / `exportTemplateMultiList` / `exportTemplateMultiSheet`。

## 红线

- **禁止** 手动 `new HSSFWorkbook` / `new XSSFWorkbook` / `new SXSSFWorkbook` — 统一走 `ExcelUtil`
- **禁止** 直接 `import com.alibaba.excel.*`（旧 EasyExcel）— 本项目用 FastExcel（`cn.idev.excel.*`）
- **禁止** 大文件全量 `selectList` 后 `exportExcel` — 超过 5 万行改用 `ExcelUtil.exportExcel(headType, os, consumer)` 分页写
- **禁止** 在 Controller 手动 `response.setHeader("Content-Disposition", ...)` — `ExcelUtil` 已处理编码（`FileUtils.setAttachmentResponseHeader`）
- **禁止** 导出方法返回 `R<Void>` / `ResponseEntity` — 必须 `void`
- **禁止** Service 层持有 `HttpServletResponse` — 只返回 `List<ExportVO>`
- **禁止** 导入 Listener 不做逐行 try/catch — 一行异常会中断整个导入
- **导入必须事务**：Service 的 `insertFromImport` 加 `@Transactional(rollbackFor = Exception.class)`；批量路径在批次方法上加事务
- **禁止** 用业务 `XxxVo` 做导出 VO — 列多且字段类型不匹配（如 JSON 字段），必须建独立 `XxxExportVO`
- **禁止** 修改 `ruoyi-common-excel` 模块源码 — 有需求改通用能力先 cc-report 找研发经理
- **禁止** 导入漏 `@Log(businessType = BusinessType.IMPORT)` / 导出漏 `BusinessType.EXPORT` — 审计缺失

## 验证

```bash
# 导出
curl -OJ -H "Authorization: Bearer $TOKEN" "http://localhost:710<N>/wande/projectMine/export?status=1"
file *.xlsx   # 确认 Microsoft Excel 2007+

# 导入
curl -H "Authorization: Bearer $TOKEN" -F "file=@sample.xlsx" \
  "http://localhost:710<N>/wande/projectMine/importData?updateSupport=false"
# 期待 R.ok + msg 含 "导入成功，共 N 条"
```

同步写 JUnit：MockMvc `multipart("/importData").file(...)` + `get("/export")` 断言 `Content-Type` 含 `spreadsheetml.sheet`。
