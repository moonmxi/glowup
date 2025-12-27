# GlowUp 课堂助手（Android + 本地服务）

GlowUp 面向乡村学校，强调「低网可用、鼓励式反馈、老师省力、孩子开心」。本版本将应用改造为 **客户端 / 服务端分离** 架构：Flutter 客户端负责教学流程与本地 AI 生成，「GlowUp 小光」在端侧完成点评与故事编排；轻量化 Dart 服务端用于班级、作品与互动数据的持久化。

## 架构一览
- `client/`：Flutter 应用（Android）
  - 教师端：课堂故事工作室、班级管理、作品橱窗
  - 学生端：小光 AI 聊天室（文本 + 图片点评）、作品上传与班级作品浏览
  - 本地 AI：`lib/services/ai_analyzers.dart` 内提供点评、教案、陪聊等离线算法
- `server/`：纯 Dart 服务（无需数据库），默认监听 `http://localhost:3000/api`
  - 负责注册登录、班级管理、课堂故事、作品点赞评论等
  - 数据以 JSON 存储在 `server/data` 下，文件可直接查看/备份

## 教师端亮点
### 课堂故事工作室（`lib/modules/teacher/teacher_module.dart`）
- 将 AI 教案、视觉、动画、音乐、色彩分析、节奏实验「串联为课堂故事」：老师先创建主题 → 小光依次生成素材 → 本地预览满意后再上传服务端
- 上传时可指定可见范围：「指定班级」或「全平台」，便于跨班分享或内部共创
- 每一步都支持重新生成、失败提示与本地工作台快捷入口（继续在动画/绘画/音乐工作室深度调整）

### 班级管理与互动
- 教师可创建/解散多个班级，系统自动生成六位编码；学生端通过编码加入
- 橱窗支持按班级/全平台筛选、点赞评论、每日点赞 Top3 榜单

## 学生端亮点
### 小光 AI 聊天室（`StudentAiStudioPage`）
- 文本聊天：小光以温暖引导提问，鼓励孩子用音乐和颜色表达想法
- 图片点评：学生上传本地作品，小光给出鼓励式点评 + 名家风格联想 + 可操作建议
- 聊天记录本地保留，弱网也能快速响应

### 作品上传与浏览
- 「我的班级 / 全平台」双视角浏览作品，支持点赞鼓励
- 学生上传的作品与教师 AI 作品分开标记，方便老师查看、点评与整理

### 班级加入
- 在「我的」页输入班级编码即可加入；加入后首页会展示班级信息与小光的每日鼓励

## 后端服务（`server/`）
- 运行方式：
  ```bash
  cd server
  dart pub get
  dart run bin/server.dart 3000   # 默认 3000 端口
  ```
- 数据文件：`data/users.json`、`classrooms.json`、`stories.json`、`content.json`
- 作品接口支持点赞、评论、按班级/全平台筛选，并提供每日点赞 Top3

> 若在设备上测试，可通过 `--define=API_BASE_URL=http://<局域网IP>:3000/api` 注入接口地址（见 `lib/services/app_api_service.dart`）。

## 核心源码导览
- 状态管理：`lib/state/`
  - `auth_state.dart`：登录、班级列表、个人资料
  - `classroom_state.dart`：班级与故事管理
  - `story_orchestrator_state.dart`：课堂故事全流程状态、上传逻辑
  - `showcase_state.dart`：作品橱窗，支持按 scope/班级加载
- 教师端 UI：`lib/modules/teacher/teacher_module.dart`
- 学生端 UI：`lib/modules/student/student_module.dart`
- 本地 AI 能力：`lib/services/ai_analyzers.dart`
- 轻量 Dart 服务：`server/lib/api.dart`

## 开发与运行
1. 启动本地服务：`dart run bin/server.dart`
2. 在 `client/` 内安装依赖：`flutter pub get`
3. 运行应用：`flutter run`（默认读取 `10.0.2.2:3000/api`，模拟器可直接使用）

## 后续可拓展方向
- 为本地 AI 生成结果接入真实模型或更强离线推理能力
- 增加作品附件真实上传（目前示例存储 meta 与描述）
- 教师端新增课堂即时互动（提问、随机点名等）
- 服务端接入持久化数据库、权限体系与更精细的统计数据

> 当前版本聚焦教学演示与产品结构验证，强调「无需网络也能工作」，欢迎在此基础上继续扩展。小光会一直陪着乡村孩子发光。 ✨
