# FlutterNotePad

<p align="center">
  <img src="assets/images/logo.png" width="128" height="128" alt="FlutterNotePad Logo">
</p>

<p align="center">
  <strong>跨平台轻量级文本编辑器</strong>
</p>

<p align="center">
  <a href="https://github.com/linfon18/FlutterNotePad/releases">
    <img src="https://img.shields.io/github/v/release/linfon18/FlutterNotePad?style=flat-square" alt="Release">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/linfon18/FlutterNotePad?style=flat-square" alt="License">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/Flutter-3.24+-blue?style=flat-square&logo=flutter" alt="Flutter">
  </a>
</p>

---

## ✨ 功能特性

- 📝 **跨平台文本编辑** - 支持 Windows、macOS、Linux、Android 和 Web
- 🎨 **自定义主题** - 支持自定义主题色和背景图片
- 🌓 **主题切换** - 深色/浅色/自动三种模式
- 📄 **Markdown 支持** - 实时预览和分屏编辑
- 🔍 **文本查找** - 支持大小写敏感和全字匹配
- 🪵 **日志高亮** - error/warn 关键字着色显示
- 📊 **JSON 工具** - 格式化、压缩、验证、Dart 类生成
- 🔷 **C# 语法高亮** - 完整的 C# 语法支持
- 🌐 **多编码支持** - UTF-8、GBK、Latin-1 自动检测
- 📦 **大文件优化** - 分段读取避免卡顿

## 📥 下载安装

### 最新版本

前往 [Releases](https://github.com/linfon18/FlutterNotePad/releases) 页面下载对应平台的安装包。

| 平台 | 下载 | 说明 |
|------|------|------|
| Windows | `FlutterNotePad-Windows-x64.zip` | 解压后运行 `notepad.exe` |
| Android | `app-release.apk` / `app-release.aab` | 安装 APK 或从应用商店下载 |
| Linux | `FlutterNotePad-Linux-x64.tar.gz` | 解压后运行 `flutter_notepad` |
| macOS | `FlutterNotePad-macOS.zip` | 解压后运行 `.app` |
| Web | `FlutterNotePad-Web.zip` | 部署到 Web 服务器或本地打开 |

### 系统要求

- **Windows**: Windows 10/11 x64
- **Android**: Android 5.0 (API 21) 及以上
- **Linux**: 支持 GTK3 的 Linux 发行版
- **macOS**: macOS 10.14 及以上
- **Web**: 现代浏览器（Chrome, Firefox, Edge, Safari）

## 🚀 快速开始

### 从源码构建

```bash
# 克隆仓库
git clone https://github.com/linfon18/FlutterNotePad.git
cd FlutterNotePad

# 安装依赖
flutter pub get

# 运行调试版本
flutter run

# 构建发布版本
flutter build windows --release    # Windows
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android AppBundle
flutter build linux --release      # Linux
flutter build macos --release      # macOS
flutter build web --release        # Web
```

## 🛠️ 技术栈

- [Flutter](https://flutter.dev) - UI 框架
- [Dart](https://dart.dev) - 编程语言
- [window_manager](https://pub.dev/packages/window_manager) - 窗口管理
- [file_selector](https://pub.dev/packages/file_selector) - 文件选择
- [flutter_markdown](https://pub.dev/packages/flutter_markdown) - Markdown 渲染
- [shared_preferences](https://pub.dev/packages/shared_preferences) - 本地存储

## 📸 截图

<p align="center">
  <img src="screenshots/screenshot1.png" width="80%" alt="主界面">
</p>

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的修改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

## 📄 许可证

本项目采用 [MIT](LICENSE) 许可证开源。

## 👨‍💻 开发者

**linfon18** @ Loft Games

- GitHub: [@linfon18](https://github.com/linfon18)

---

<p align="center">
  <sub>仅 Flutter 初学入手尝试，不保证更新</sub>
</p>
