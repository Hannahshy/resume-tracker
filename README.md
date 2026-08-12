# 简历投递管理

一个本地优先的 macOS 求职管理工具，用于记录简历投递、岗位 JD、多轮面试进度与复盘。

所有求职数据默认保存在你的电脑中，不需要注册账号。截图文字识别使用 macOS Vision，在本机完成，不会将截图上传到第三方 OCR 服务。

## 主要功能

- 简历投递列表与进度看板
- 投递状态、心仪度、薪资、地点和面试时间管理
- 职位描述、岗位职责与任职要求记录
- 从文件、拖拽或剪贴板截图识别岗位信息
- 多轮面试记录与富文本复盘
- JSON 文件本地持久化存储
- macOS 桌面快捷应用

## 系统要求

- macOS 11 或更高版本
- Node.js 18 或更高版本
- macOS Command Line Tools（用于编译本地 OCR 组件）

安装 Node.js：[nodejs.org](https://nodejs.org/)

如果系统缺少 Command Line Tools，可在“终端”运行：

```bash
xcode-select --install
```

## 安装

1. 在 GitHub 页面点击 **Code → Download ZIP**。
2. 解压下载的文件。
3. 双击 `install-macos.command`。
4. 安装完成后，桌面会出现“简历投递管理”。

如果 macOS 第一次阻止运行安装程序：

1. 在 Finder 中右键点击 `install-macos.command`。
2. 选择“打开”。
3. 在确认窗口中再次选择“打开”。

安装程序会把应用放在：

```text
~/Applications/简历投递管理.app
```

个人数据保存在：

```text
~/Library/Application Support/ResumeTracker/data.json
```

再次运行安装程序可以更新应用，已有的 `data.json` 不会被覆盖。

## 使用截图识别

1. 打开一条投递记录。
2. 在“职位描述 & 岗位职责 & 要求”旁点击“截图识别”。
3. 选择图片、拖入图片，或截图后直接按 `⌘V`。
4. 检查自动分栏结果并点击“填入岗位信息”。

支持 PNG、JPG、HEIC 和 TIFF，单张图片最大 12MB。

## 数据与隐私

- 应用仅监听 `127.0.0.1`，局域网中的其他设备无法访问。
- 求职记录保存在本机 `data.json` 中。
- OCR 使用 macOS Vision 在本机处理。
- 项目不会收集、上传或分析个人求职数据。
- `data.json` 已加入 `.gitignore`，不会被提交到 Git 仓库。

建议定期备份个人数据文件。更新或重新安装应用时不要删除上述数据目录。

## 本地开发

```bash
git clone https://github.com/Hannahshy/resume-tracker.git
cd resume-tracker
npm start
```

然后访问 [http://127.0.0.1:3000](http://127.0.0.1:3000)。首次启动时会自动创建空的 `data.json`。

如果需要截图 OCR，可运行 `install-macos.command`，或手动编译：

```bash
mkdir -p .build/clang-cache .build/swift-cache
CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache" \
SWIFT_MODULE_CACHE_PATH="$PWD/.build/swift-cache" \
xcrun swiftc ocr.swift -O -o .build/ResumeTrackerOCR
```

## 卸载

关闭应用后删除：

```text
~/Applications/简历投递管理.app
~/Desktop/简历投递管理.app
~/Library/Application Support/ResumeTracker
```

最后一个目录包含所有个人数据；如需保留记录，请先备份 `data.json`。

## 示例数据

仓库中的 `data.example.json` 仅用于展示数据结构，不包含真实求职信息。应用首次安装会创建空数据文件。

## License

[MIT](LICENSE)
