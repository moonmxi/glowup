# GlowUp 课堂助手

GlowUp 面向乡村与资源受限学校，提供 **Flutter 客户端 + 纯 Dart 服务端** 的本地化教学助手：老师可在端侧生成课堂故事、AI 教案、音乐/视觉素材，学生则能进行作品上传、AI 鼓励式点评与班级互动。最新版本强化了「色彩小助手」的离线 CV 能力（主色调 PALETTE、HSL 明度/饱和度、情绪倾向），弱网环境也可完成图像分析。

## 仓库结构
- `client/`：Flutter 应用（Android / Web / Desktop）
  - 核心入口：`lib/app.dart`、`lib/main.dart`
  - 教师模块：`lib/modules/teacher/teacher_module.dart`
  - 色彩小助手：`lib/screens/analysis/image_analysis_page.dart`
  - 本地 AI 能力：`lib/services/ai_analyzers.dart`
- `server/`：轻量 Dart 服务
  - 接口入口：`bin/server.dart`
  - 静态数据：`data/*.json`

## 快速开始
### 先决条件
- Flutter 3.24+（包含 Dart SDK）
- Dart SDK（已随 Flutter 提供）
- Chrome / Android Studio / 物理设备（任选其一）

### 启动服务器
```bash
cd server
dart pub get
dart run bin/server.dart 3000   # 可自定义端口
```
> 默认监听 `http://localhost:3000/api`，数据保存在 `server/data/`，可直接备份或热更新。

### 启动客户端
```bash
cd client
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api  # Android 模拟器
```
- Web/桌面端可直接使用 `http://localhost:3000/api`
- 真机调试请替换为电脑局域网 IP，例如 `http://192.168.0.12:3000/api`

## 主要特性
- **课堂故事工作室**：老师可按步骤生成教案、背景图、音乐、视频并一键上传班级。
- **AI 教学背景图调优**：提供「主色滑块」「风格选择」「重生成」「评分反馈」等前端增强，帮助老师快速调参。
- **色彩小助手（离线 CV）**：
  - 主色调 (PALETTE)：K-Means 变体聚类，输出 3-4 个色板。
  - 明度/饱和度：HSL 转换得出情绪倾向（明亮=快乐、灰暗=沉静等）。
  - 识别结果可在弱网环境直接呈现，无需调用服务端。
- **轻量服务端**：所有数据以 JSON 文件存储，便于本地演示与备份。

## 开发提示
- 修改 `client/lib/services/app_api_service.dart` 可自定义 API 路径或鉴权策略。
- `client/lib/services/ai_analyzers.dart` 中预留了接入真实模型的接口，可按需替换算法实现。
- 建议使用 `flutter format` / `dart format` 保持代码风格一致。

## 贡献
欢迎提交 Issue / PR，共同完善 GlowUp：
1. Fork 仓库并创建分支。
2. 提交代码后发起 Pull Request，说明变更内容与测试方式。
3. 如涉及 UI 变更，请附上截图或录屏，便于 Review。

## 许可
项目采用 [MIT License](LICENSE)。
