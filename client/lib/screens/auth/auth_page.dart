import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/glowup_theme.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.role});

  final String role;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _classroomCodeController = TextEditingController();
  bool _isLogin = true;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _classroomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final isTeacher = widget.role == 'teacher';
    final title = _isLogin ? '登录${isTeacher ? '教师' : '学生'}账号' : '注册${isTeacher ? '教师' : '学生'}账号';
    final accent = isTeacher ? GlowUpColors.primary : GlowUpColors.secondary;
  final gradientEnd = accent.withOpacity(isTeacher ? 0.14 : 0.2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: accent,
        foregroundColor: isTeacher ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientEnd, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      elevation: 14,
                      shadowColor: accent.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: accent.withOpacity(0.18)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      accent.withOpacity(isTeacher ? 0.9 : 0.85),
                                      accent.withOpacity(isTeacher ? 0.72 : 0.68),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(0.24),
                                      blurRadius: 24,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GlowUp ${isTeacher ? '教师' : '学生'}平台',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isTeacher
                                          ? '欢迎回来，用艺术故事连接班级的每一天。'
                                          : '欢迎加入，让色彩与音乐点亮你的创意冒险。',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.white.withOpacity(0.85),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (!_isLogin && isTeacher)
                                Text(
                                  '注册成功后会自动生成课堂邀请码，请妥善保管并分享给学生。',
                                  style: TextStyle(color: accent.withOpacity(0.75)),
                                ),
                              if (!_isLogin && !isTeacher)
                                Text(
                                  '请向老师索要课堂邀请码，以加入正确的教室。',
                                  style: TextStyle(color: accent.withOpacity(0.75)),
                                ),
                              if ((!_isLogin && isTeacher) || (!_isLogin && !isTeacher))
                                const SizedBox(height: 20),
                              TextFormField(
                                controller: _usernameController,
                                decoration: _fieldDecoration(
                                  label: '用户名',
                                  icon: Icons.person_outline,
                                  accent: accent,
                                  isTeacher: isTeacher,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty ? '请输入用户名' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscure,
                                decoration: _fieldDecoration(
                                  label: '密码',
                                  icon: Icons.lock_outline,
                                  accent: accent,
                                  isTeacher: isTeacher,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscure ? Icons.visibility_off : Icons.visibility,
                                      color: accent,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.length < 6 ? '密码至少 6 位' : null,
                              ),
                              if (!_isLogin && !isTeacher) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _classroomCodeController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: _fieldDecoration(
                                    label: '课堂邀请码',
                                    icon: Icons.meeting_room_outlined,
                                    accent: accent,
                                    isTeacher: isTeacher,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty ? '请输入课堂邀请码' : null,
                                ),
                              ],
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    shadowColor: accent.withOpacity(0.28),
                                  ),
                                  onPressed: auth.isLoading ? null : _submit,
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(_isLogin ? '登录' : '注册'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (auth.error != null && auth.error!.isNotEmpty)
                                Text(
                                  auth.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 12),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: accent,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isLogin = !_isLogin;
                                        });
                                      },
                                child: Text(_isLogin ? '还没有账号？立即注册' : '已有账号？立即登录'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    required Color accent,
    required bool isTeacher,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: accent),
      suffixIcon: suffix,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: accent.withOpacity(0.25)),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accent.withOpacity(0.25)),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accent, width: 1.6),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthState>();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final role = widget.role;

    bool success = false;
    if (_isLogin) {
      success = await auth.login(username: username, password: password);
    } else {
      success = await auth.register(
        username: username,
        password: password,
        role: role,
        classroomCode: role == 'student' ? _classroomCodeController.text.trim() : null,
      );
      if (success && role == 'teacher' && mounted) {
        final code = auth.classroom?.code;
        if (code != null) {
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('课堂邀请码'),
              content: Text('注册成功！请将邀请码 $code 分享给学生。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('好的'),
                ),
              ],
            ),
          );
        }
      }
    }

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }
}
