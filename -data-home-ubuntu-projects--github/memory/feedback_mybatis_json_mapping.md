---
name: MyBatis JSON/custom类型resultMap建议
description: MyBatis resultMap含JSON/自定义类型时，直接跳过resultMap映射在Service层手动填充
type: feedback
---

MyBatis resultMap 中含 JSON/自定义类型时，直接跳过 resultMap 映射，在 Service 层手动填充。

**来源**: kimi5 (CC #3212 BOM设备进度追踪)

**为什么**: MapStruct String→List 转换失败、MySQL delayed 保留字等卡点均源于 resultMap 自动映射复杂类型
**如何应用**: 新建 Entity 含 JSON 字段或自定义类型时，Mapper XML 不用 resultMap 自动映射，Controller/Service 层手动赋值
