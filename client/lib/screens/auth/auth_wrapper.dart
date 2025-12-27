import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../modules/student/student_module.dart';
import '../../modules/teacher/teacher_module.dart';
import '../../state/auth_state.dart';
import 'role_selection_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 在应用启动时初始化认证状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        // 如果还在初始化中，显示加载界面
        if (!auth.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 如果已经登录，根据用户角色跳转到对应模块
        if (auth.isAuthenticated && auth.user != null) {
          if (auth.user!.isTeacher) {
            return const TeacherModule();
          } else if (auth.user!.isStudent) {
            return const StudentModule();
          }
        }

        // 如果未登录，显示角色选择页面
        return const RoleSelectionPage();
      },
    );
  }
}