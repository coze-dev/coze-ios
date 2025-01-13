# coze-swift

一个基于 火山引擎 RTC 技术的 iOS 实时语音演示项目，使用 Swift 语言开发。

## 快速入门

详细的快速入门指南请参考：[Coze iOS（Swift）实时语音快速入门](https://bytedance.larkoffice.com/docx/TFfHdgES2o9pMBxieKqcXeadnjd)

快速开始步骤：

1. 环境准备

   - 确保满足环境要求
   - 安装必要的开发工具

2. 项目配置

   - 克隆项目并安装依赖
   - 配置 API 信息

3. 运行项目
   - 使用 Xcode 打开项目
   - 在真机上进行调试

详细步骤请参考上述快速入门文档。

## 功能特性

- 实时音视频通话
- 基于 火山引擎 RTC 的实时语音对话
- 扣子 OpenAPI 接口集成

## 环境要求

- iOS 11.0+
- Xcode 14.1+
- Swift 5.0+
- CocoaPods

## 安装说明

1. 克隆项目到本地：

```bash
git clone https://github.com/coze-dev/coze-ios
cd coze-swift
```

2. 安装依赖：

```bash
pod install
```

3. 配置 API 信息：

   - 复制 `coze-swift/Config/APIConfig.swift.template` 为 `coze-swift/Config/APIConfig.swift`
   - 在 `APIConfig.swift` 中配置您的 accessToken、botId、voiceId

4. 使用 Xcode 打开 `coze-swift.xcworkspace`
5. 选择真机设备进行调试

## 项目结构

- `Config/APIConfig.swift`：配置 API 相关信息
- `Models/ApiResponse.swift`：API 返回数据结构
- `Services/NetworkService.swift`：API 请求封装
- `ViewController.swift`：主界面

## 使用说明

1. 启动应用后，确保已正确配置
2. 按照界面提示进行实时对话操作
3. 可以通过界面控制音视频开关等功能

## 注意事项

- 请确保在使用前正确配置 APIConfig.swift 文件
- 务必使用真机调试
- 确保设备已授权摄像头和麦克风权限

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进项目。

## 许可证

本项目基于 MIT 许可证开源。

## 联系方式

如有问题，请通过 Issue 与我们联系。
