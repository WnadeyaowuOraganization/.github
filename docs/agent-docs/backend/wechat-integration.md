# 微信接入指南

## 概述

项目支持接入个人微信公众号和企业微信。

## 依赖

使用开源的微信 Java SDK：
- **个人微信公众号**：`weixin-java-mp`（4.4.0版本）
- **企业微信**：`weixin-java-cp`（4.4.0版本）

## 配置

在 `ruoyi-admin/src/main/resources/application-dev.yml` 中添加以下配置（去掉注释并填写真实值）：

### 个人微信公众号配置

```yaml
wechat:
  mp:
    # 是否启用
    enabled: true
    # 公众号appId
    appId: wxa123456789012345
    # 公众号密钥
    secret: abcdef1234567890abcdef1234567890
    # 消息加密token
    token: your_token
    # 消息加密aesKey（43位）
    aesKey: your_aes_key
```

### 企业微信配置

```yaml
wechat:
  cp:
    # 是否启用
    enabled: true
    # 企业ID
    corpId: ww1234567890abcdef
    appConfigs:
      - agentId: 1000002
        # 应用密钥
        secret: your_agent_secret
        # 消息加密token
        token: your_agent_token
        # 消息加密aesKey
        aesKey: your_agent_aes_key
```

## 获取配置参数

### 个人微信公众号

1. 登录 [微信公众平台](https://mp.weixin.qq.com/)
2. 进入「开发」->「基本配置」
3. 获取 AppID 和 AppSecret
4. 配置服务器配置：
   - 服务器地址(URL)：`https://your-domain/wx/mp`
   - 令牌(Token)：与配置文件中的 token 一致
   - 消息加解密密钥：与配置文件中的 aesKey 一致

### 企业微信

1. 登录 [企业微信管理后台](https://work.weixin.qq.com/)
2. 进入「应用管理」->「应用」->「创建应用」或选择已有应用
3. 获取 AgentId 和 Secret
4. 企业ID可在「我的企业」->「企业信息」中查看

## 接口说明

### 个人微信公众号

- **接入验证接口**：`GET /wx/mp`
- **消息接收接口**：`POST /wx/mp`

### 企业微信

- **接入验证接口**：`GET /wx/cp`
- **消息接收接口**：`POST /wx/cp`

## 代码结构

```
ruoyi-wechat/
├── src/main/java/org/ruoyi/
│   ├── config/
│   │   ├── WxMpProperties.java       // 个人微信配置属性
│   │   ├── WxMpConfiguration.java    // 个人微信配置类
│   │   ├── WxCpProperties.java       // 企业微信配置属性
│   │   └── WxCpConfiguration.java    // 企业微信配置类
│   ├── controller/
│   │   ├── WxMpPortalController.java // 个人微信公众号控制器
│   │   ├── WxPortalController.java   // 企业微信控制器
│   │   └── WeixinServerController.java
│   ├── handler/                      // 消息处理器
│   └── service/                      // 微信相关服务
└── pom.xml
```

## 消息处理

消息处理使用 `me.chanjar.weixin.mp.bean.message.WxMpXmlMessage` 对象，支持以下类型：

- 文本消息
- 图片消息
- 语音消息
- 视频消息
- 地理位置消息
- 链接消息
- 事件消息（关注/取消关注、菜单点击、扫码、位置上报等）

## 扩展开发

### 添加新的消息处理器

1. 在 `ruoyi-wechat/src/main/java/org/ruoyi/handler/` 目录下创建新的处理器类
2. 继承 `AbstractHandler` 或实现 `WxMpMessageHandler` 接口
3. 在 `WxMpConfiguration` 中配置路由规则

### 调用微信API

使用 `WxMpService` 和 `WxCpService` 对象可以调用微信官方API，支持：

- 发送消息
- 获取用户信息
- 创建菜单
- 上传素材
- 客服功能
- 等其他功能

## 部署注意事项

1. 确保服务器可以被微信服务器访问（必须使用80或443端口）
2. 配置正确的域名解析和SSL证书（建议使用HTTPS）
3. 消息加密配置要与微信后台保持一致
4. 应用服务器必须有稳定的网络连接
