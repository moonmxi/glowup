import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/profile_state.dart';
import '../../state/resource_state.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('无法打开链接，请检查网络。')),
      );
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'hello@glowup.app',
      queryParameters: {
        'subject': 'GlowUp 课堂助手反馈',
        'body': '您好，我想反馈/咨询：',
      },
    );
    final messenger = ScaffoldMessenger.of(context);
    final launched = await launchUrl(uri);
    if (!launched) {
      messenger.showSnackBar(
        const SnackBar(content: Text('无法打开邮件客户端。')),
      );
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('数据与隐私说明'),
        content: const Text(
          'GlowUp 仅在本地缓存生成的教案与素材，不会上传学生个人信息。'
          '\n\n心理相关功能上线前，会提供明确的家长与教师知情提示。'
          '\n如需导出数据，可在“离线包管理”中手动备份。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  void _showOfflineSheet(
    BuildContext context,
    ResourceLibraryState resourceState,
  ) {
    final info = resourceState.offlineInfo;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: GlowUpColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '离线包管理',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              '总大小：${info.totalSizeGb.toStringAsFixed(1)} GB\n已缓存：${(info.progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: info.progress.clamp(0.0, 1.0)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                resourceState.syncOfflinePackage();
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已尝试同步离线包，请稍候查看进度。')),
                );
              },
              icon: const Icon(Icons.sync),
              label: const Text('手动同步一次'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<ProfileState>();
    final offlineInfo = context.watch<ResourceLibraryState>().offlineInfo;
    final resourceState = context.read<ResourceLibraryState>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '个人中心',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            GlowCard(
              child: _TeacherProfileCard(
                teacherName: profile.teacherName,
                schoolName: profile.schoolName,
                badges: profile.badges,
              ),
            ),
            GlowCard(
              child: _PreferenceCard(profile: profile),
            ),
            GlowCard(
              child: _SystemSettingsCard(
                offlineProgress: offlineInfo.progress,
                onManageOffline: () =>
                    _showOfflineSheet(context, resourceState),
                onPrivacy: () => _showPrivacyDialog(context),
                onFeedback: () => _sendFeedback(context),
              ),
            ),
            GlowCard(
              child: _AboutCard(
                onOpenRepo: () =>
                    _openUrl(context, 'https://github.com/glowup-ai/app'),
                onOpenLocalization: () => _openUrl(
                  context,
                  'https://docs.glowup.app/localization',
                ),
                onOpenTeam: () => _openUrl(
                  context,
                  'https://docs.glowup.app/team',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherProfileCard extends StatelessWidget {
  const _TeacherProfileCard({
    required this.teacherName,
    required this.schoolName,
    required this.badges,
  });

  final String teacherName;
  final String schoolName;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final initials = _initialsFromName(teacherName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: GlowUpColors.dusk,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolName,
                style: textTheme.bodySmall?.copyWith(
                  color: GlowUpColors.dusk.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: badges
              .map((badge) => _BadgeChip(label: badge))
              .toList(growable: false),
        ),
      ],
    );
  }
}

String _initialsFromName(String name) {
  if (name.isEmpty) {
    return 'GL';
  }
  final runes = name.runes.toList();
  if (runes.isEmpty) {
    return 'GL';
  }
  if (runes.length == 1) {
    return String.fromCharCode(runes.first);
  }
  return String.fromCharCode(runes[0]) + String.fromCharCode(runes[1]);
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: GlowUpColors.lavender.withValues(alpha: 0.3),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: GlowUpColors.dusk,
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({required this.profile});

  final ProfileState profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profileActions = context.read<ProfileState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '课堂偏好',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.language),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: AppLanguage.values.map((lang) {
                  final selected = profile.language == lang;
                  return ChoiceChip(
                    label: Text(lang == AppLanguage.zh ? '中文（简体）' : 'English'),
                    selected: selected,
                    onSelected: (_) => profileActions.updateLanguage(lang),
                    selectedColor: GlowUpColors.breeze,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : GlowUpColors.dusk,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: profile.largeText,
          onChanged: profileActions.toggleLargeText,
          title: const Text('大字号模式'),
          subtitle: Text(
            '适配老旧投影与后排学生可视范围',
            style: textTheme.bodySmall?.copyWith(
              color: GlowUpColors.dusk.withValues(alpha: 0.7),
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: profile.highContrast,
          onChanged: profileActions.toggleHighContrast,
          title: const Text('无障碍对比度'),
          subtitle: Text(
            '提升色彩对比，关怀弱视学生',
            style: textTheme.bodySmall?.copyWith(
              color: GlowUpColors.dusk.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _SystemSettingsCard extends StatelessWidget {
  const _SystemSettingsCard({
    required this.offlineProgress,
    required this.onManageOffline,
    required this.onPrivacy,
    required this.onFeedback,
  });

  final double offlineProgress;
  final VoidCallback onManageOffline;
  final VoidCallback onPrivacy;
  final VoidCallback onFeedback;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '系统设置',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.download_done,
          title: '离线包管理',
          subtitle:
              '已缓存 ${(offlineProgress * 100).round()}% · 支持蓝牙/数据线导出',
          trailing: const Icon(Icons.launch),
          onTap: onManageOffline,
        ),
        const Divider(height: 1),
        _SettingTile(
          icon: Icons.privacy_tip_outlined,
          title: '数据与隐私说明',
          subtitle: '解释采集范围与心理安全提醒流程',
          onTap: onPrivacy,
        ),
        const Divider(height: 1),
        _SettingTile(
          icon: Icons.bug_report,
          title: '反馈与日志导出',
          subtitle: '邮件发送建议时可附带日志压缩包',
          onTap: onFeedback,
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.onOpenRepo,
    required this.onOpenLocalization,
    required this.onOpenTeam,
  });

  final VoidCallback onOpenRepo;
  final VoidCallback onOpenLocalization;
  final VoidCallback onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '关于 GlowUp',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _SettingTile(
          icon: Icons.code,
          title: '开源许可',
          subtitle: 'MIT License · GitHub.com/glowup-ai',
          onTap: onOpenRepo,
        ),
        const Divider(height: 1),
        _SettingTile(
          icon: Icons.language_outlined,
          title: '国际化支持',
          subtitle: '中英双语 · 可扩展少数民族语言包',
          onTap: onOpenLocalization,
        ),
        const Divider(height: 1),
        _SettingTile(
          icon: Icons.people_outline,
          title: '团队鸣谢',
          subtitle: '教师共创 7 人 · AI 伙伴 3 模块',
          onTap: onOpenTeam,
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(Icons.info, color: GlowUpColors.bloom),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '版本 0.1.0 · 适配 Android 8+ 低配设备 · 支持离线演示模式。',
                  style: textTheme.bodySmall?.copyWith(
                    color: GlowUpColors.dusk.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: GlowUpColors.lavender.withValues(alpha: 0.34),
        child: Icon(icon, color: GlowUpColors.dusk),
      ),
      title: Text(
        title,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(
          color: GlowUpColors.dusk.withValues(alpha: 0.7),
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
