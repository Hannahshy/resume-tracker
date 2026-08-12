# 简历投递管理

<div align="center">
  <p><strong>一个本地优先的 macOS 求职工作台</strong></p>
  <p>记录投递进度、整理 JD、保存多轮面试复盘，并支持截图识别岗位信息。</p>
  <p>
    <img alt="platform" src="https://img.shields.io/badge/macOS-11%2B-1f2937?style=flat-square">
    <img alt="storage" src="https://img.shields.io/badge/Data-Local%20First-8b5cf6?style=flat-square">
    <img alt="ocr" src="https://img.shields.io/badge/OCR-On%20Device-f59e0b?style=flat-square">
    <img alt="license" src="https://img.shields.io/badge/License-MIT-111827?style=flat-square">
  </p>
</div>

![看板首页](docs/board-view.jpg)

## 这是什么

这是一个给求职阶段使用的本地工具：把零散的投递记录、岗位 JD、截图信息和面试复盘，收进一个可以长期维护的桌面应用里。

它默认只把数据保存在你的电脑上，不需要账号，不依赖在线数据库。截图识别使用 macOS Vision，在本机完成，不会把图片发到第三方 OCR 服务。

## 功能亮点

- 投递列表和看板双视图切换
- 统一管理公司、岗位、进度、心仪度、薪资、地点和面试时间
- 支持“职位描述 / 岗位职责 / 任职要求”三栏记录
- 支持从文件、拖拽和剪贴板直接粘贴截图识别 JD
- 支持多轮面试记录，带富文本复盘编辑器
- 数据本地持久化，`data.json` 不会进入 Git 仓库
- 提供 macOS 桌面快捷应用

## 界面预览

<table>
  <tr>
    <td width="50%" valign="top">
      <img alt="首页概览" src="docs/board-view.jpg">
      <p><strong>首页 / 看板页</strong><br>查看投递概览、下一场面试和各阶段分布。</p>
    </td>
    <td width="50%" valign="top">
      <img alt="列表页" src="docs/list-view.jpg">
      <p><strong>列表页</strong><br>按进度、心仪度和关键词快速筛选与查看。</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img alt="新增投递" src="docs/new-application.jpg">
      <p><strong>新增投递记录</strong><br>一次填完整个岗位信息，后续持续追踪。</p>
    </td>
    <td width="50%" valign="top">
      <img alt="截图识别" src="docs/ocr-import.jpg">
      <p><strong>截图识别</strong><br>可选择图片、拖入图片，或直接按 <code>⌘V</code> 粘贴截图。</p>
    </td>
  </tr>
  <tr>
    <td colspan="2" valign="top" align="center">
      <img alt="面试复盘" src="docs/interview-notes.jpg">
      <p><strong>面试记录页</strong><br>每一轮都能单独记录问题、回答、感受和改进点。</p>
    </td>
  </tr>
</table>

> README 中的截图使用虚构演示数据生成，不包含真实求职记录。

## 安装

### 系统要求

- macOS 11 或更高版本
- Node.js 18 或更高版本
- macOS Command Line Tools

安装 Node.js：[nodejs.org](https://nodejs.org/)

如果系统缺少 Command Line Tools，可在终端运行：

```bash
xcode-select --install
```

### 安装步骤

1. 在 GitHub 页面点击 `Code` -> `Download ZIP`
2. 解压项目文件
3. 双击 `install-macos.command`
4. 安装完成后，桌面会出现“简历投递管理”

如果 macOS 第一次阻止运行安装程序：

1. 在 Finder 中右键点击 `install-macos.command`
2. 选择“打开”
3. 在确认窗口中再次选择“打开”

应用会安装到：

```text
~/Applications/简历投递管理.app
```

个人数据默认保存在：

```text
~/Library/Application Support/ResumeTracker/data.json
```

再次运行安装程序会更新应用，但不会覆盖已有 `data.json`。

## 使用流程

1. 新增一条投递记录，先填基本信息和投递链接
2. 从招聘页面复制文本，或打开“截图识别”直接粘贴截图
3. 把职位描述、岗位职责、任职要求分别保存到对应文本框
4. 面试推进后，在同一条记录里持续添加每一轮面试复盘

## 数据与隐私

- 应用仅监听 `127.0.0.1`，不会暴露给局域网其他设备
- 所有求职记录默认保存在本地 `data.json`
- OCR 识别走 macOS Vision，本机处理
- 项目不会收集、上传或分析个人求职数据
- `data.json` 已加入 `.gitignore`，不会被提交到 Git 仓库

建议定期备份 `~/Library/Application Support/ResumeTracker/data.json`。

## 本地开发

```bash
git clone https://github.com/Hannahshy/resume-tracker.git
cd resume-tracker
npm start
```

然后访问 [http://127.0.0.1:3000](http://127.0.0.1:3000)。

如果需要本地 OCR，可运行 `install-macos.command`，或手动编译：

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

最后一个目录包含全部个人数据；如需保留记录，请先备份 `data.json`。

## License

[MIT](LICENSE)
