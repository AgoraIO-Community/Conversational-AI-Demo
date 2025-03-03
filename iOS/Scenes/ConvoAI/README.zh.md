# 🌟 声网对话式 AI 引擎体验应用

*其他语言版本：[English](README.md)*

声网对话式 AI 引擎重新定义了人机交互界面，突破了传统文字交互，实现了高拟真、自然流畅的实时语音对话，让 AI 真正"开口说话"。适用于创新场景如：

- 🤖 智能助手
- 💞 情感陪伴
- 🗣️ 口语陪练
- 🎧 智能客服
- 📱 智能硬件
- 🎮 沉浸式游戏 NPC

## 🚀 一、快速开始

这个部分主要介绍如何快速跑通声网对话式 AI 引擎体验应用项目。

### 📱 1.1 环境准备

- Xcode 15.0 及以上版本
- iOS 15.0 及以上的手机设备

### ⚙️ 1.2 运行项目

#### 1.2.1 获取 APP ID 和 APP 证书

- 进入[声网控制台](https://console.shengwang.cn/overview)
- 点击创建项目
  ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_1.jpg)
- 选择项目基础配置，鉴权机制需要选择**安全模式**
  ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/sdhy_2.jpg)
- 获取项目 APP ID 与 APP 证书

#### 1.2.2 开启对话式 AI 引擎功能权限

- 在[声网控制台](https://console.shengwang.cn/product/ConversationAI?tab=config)开启权限
  ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/ConvoAI.png)

#### 1.2.3 获取 RESTful API 密钥

- 在[声网控制台](https://console.shengwang.cn/settings/restfulApi)点击添加密钥
  ![图片](https://accktvpic.oss-cn-beijing.aliyuncs.com/pic/github_readme/ent-full/restful.png)
- 下载密钥文件，复制 BASIC_AUTH_KEY 和 BASIC_AUTH_SECRET

#### 1.2.4 获取 LLM 配置信息

- 自行在 LLM 厂商官网获取相关配置信息

#### 1.2.5 获取 TTS 配置信息

- 自行在 TTS 厂商官网获取相关配置信息

#### 1.2.6 配置项目

- 打开 `iOS` 项目，在 [**KeyCenter.swift**](../../Agent/KeyCenter.swift) 文件中填写上述获取的配置信息：

``` Swift
    #----------- AppId --------------
    static let APP_ID: String = <声网 App ID>
    static let CERTIFICATE: String? = <声网 App Certificate>
    
    #----------- Basic Auth ---------------
    static let BASIC_AUTH_KEY: String = <声网 RESTful API KEY>
    static let BASIC_AUTH_SECRET: String = <声网 RESTful API SECRET>
    
    #----------- LLM -----------
    static let LLM_URL: String = <LLM 厂商的 API BASE URL>
    static let LLM_API_KEY: String? = <LLM 厂商的 API KEY>
    static let LLM_SYSTEM_MESSAGES: String? = <LLM Prompt>
    static let LLM_MODEL: String? = <LLM Model>
    
    #----------- TTS -----------
    static let TTS_VENDOR: String = <TTS 厂商>
    static let TTS_PARAMS: [String : Any] = <TTS 参数>
```

- 在iOS目录执行`pod install` 后运行项目，即可开始您的体验

## 🗂️ 二、项目结构导览

| 路径                                                                                                    | 描述                                      |
| ------------------------------------------------------------------------------------------------------- | ----------------------------------------- |
| [AgentManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/AgentManager.swift)               | 对话式 AI 引擎 RESTful 接口实现和数据模型 |
| [RTCManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/RTCManager.swift)                   | RTC 音视频通信相关实现                    |
| [AgentPreferenceManager.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Manager/AgentPreferenceManager.swift) | Agent状态管理                    |
| [Main/](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main)                                                  | UI 界面组件和交互页面                    |
| [Main/Chat](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main/Chat)                                         | 聊天页面的视图及控制器                    |
| [AgentInformationViewController.swift](Scenes/VoiceAgent/VoiceAgent/Classes/Main/Setting/VC/AgentInformationViewController.swift) | 智能体运行状态信息展示对话框                    |
| [AgentSettingViewController.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Main/Setting/VC/AgentSettingViewController.swift) | 智能体参数配置设置对话框                   |
| [Utils/](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Utils)                                                | 实用工具类和辅助函数                      |
| [ConversationSubtitleController.swift](iOS/Scenes/VoiceAgent/VoiceAgent/Classes/Utils/ConversationSubtitleController.swift) | 实时对话字幕解析工具                      |


## 📚 三、相关资源

- 📖 查看我们的 [对话式 AI 引擎文档](https://doc.shengwang.cn/doc/convoai/restful/landing-page) 了解更多详情
- 🧩 访问 [Agora SDK 示例](https://github.com/AgoraIO) 获取更多教程和示例代码
- 👥 在 [Agora 开发者社区](https://github.com/AgoraIO-Community) 探索开发者社区管理的优质代码仓库
- 💬 如有疑问，欢迎在 [Stack Overflow](https://stackoverflow.com/questions/tagged/agora.io) 提问

## 💡 四、问题反馈

如果您在集成过程中遇到任何问题或有改进建议：

- 🤖 可通过[声网支持](https://ticket.shengwang.cn/form?type_id=&sdk_product=&sdk_platform=&sdk_version=&current=0&project_id=&call_id=&channel_name=)获取智能客服帮助或联系技术支持人员
- ✉️ 发送邮件至 [support@agora.io](mailto:support@agora.io) 获取专业支持

## 📜 五、许可证

本项目采用 MIT 许可证 (The MIT License)。
