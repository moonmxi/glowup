import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/glowup_theme.dart';
import 'hub/ai_hub_page.dart';
import 'hub/classroom_tools_page.dart';
import 'profile/profile_page.dart';
import 'showcase/showcase_gallery_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  final _pages = const [
    AiHubPage(),
    ClassroomToolsPage(),
    ShowcaseGalleryPage(),
    ProfilePage(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      title: AppConstants.aiToolsModuleName,
      subtitle: '探索 AI 创意工具箱',
      icon: Icons.auto_awesome,
      accent: GlowUpColors.breeze,
    ),
    _NavItem(
      title: AppConstants.classroomToolsModuleName,
      subtitle: '高效课堂与教学资源',
      icon: Icons.school,
      accent: GlowUpColors.cobalt,
    ),
    _NavItem(
      title: AppConstants.showcaseGalleryName,
      subtitle: '作品陈列与灵感集锦',
      icon: Icons.photo_library,
      accent: GlowUpColors.sky,
    ),
    _NavItem(
      title: '个人中心',
      subtitle: '偏好设置与账户信息',
      icon: Icons.person,
      accent: GlowUpColors.plum,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = _navItems[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FBFF),
              Color(0xFFFFF4EA),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      GlowUpColors.primary,
                      GlowUpColors.primary.withValues(alpha: 0.92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GlowUpColors.primary.withValues(alpha: 0.28),
                      blurRadius: 36,
                      offset: const Offset(0, 22),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 24, 40, 12),
                      child: _Header(
                        title: item.title,
                        subtitle: item.subtitle,
                        accent: item.accent,
                        onInfoPressed: _currentIndex == 0
                            ? () => _showGuide(
                                  context,
                                  title: '课堂魔法小贴士',
                                  tips: const [
                                    '从“动画”“小画廊”“音乐角”“色彩小助手”“节奏实验室”进入对应课堂工具。',
                                    '先尝试预设灵感/示例，再根据班级主题调整提示语或参数。',
                                    '生成或分析后的素材可直接预览或保存离线，在弱网环境依然可靠。',
                                  ],
                                )
                            : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                      child: _NavigationPills(
                        items: _navItems,
                        currentIndex: _currentIndex,
                        onChanged: (index) {
                          if (index == _currentIndex) return;
                          setState(() => _currentIndex = index);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final curved = CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutQuart,
                      );
                      final offsetTween = Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      );
                      return FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: offsetTween.animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      key: ValueKey(_currentIndex),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: GlowUpColors.midnight
                                .withValues(alpha: 0.08),
                            blurRadius: 48,
                            offset: const Offset(0, 28),
                          ),
                        ],
                        border: Border.all(
                          color: GlowUpColors.outline.withValues(alpha: 0.6),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: IndexedStack(
                          index: _currentIndex,
                          children: _pages,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuide(
    BuildContext context, {
    required String title,
    required List<String> tips,
  }) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '课堂指南',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: Colors.transparent,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeInBack,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: curved,
                      child: child,
                    ),
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 48,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: GlowUpColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            IconButton(
                              tooltip: '关闭',
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ...tips.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key == tips.length - 1 ? 0 : 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 28,
                                      width: 28,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: GlowUpColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: GlowUpColors.primary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.check),
                            label: const Text('好，开始动手'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.onInfoPressed,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onInfoPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 780;
        return Column(
          crossAxisAlignment:
              isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GlowUp 创意课堂',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white.withOpacity(0.92),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: theme.textTheme.displaySmall?.copyWith(
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(color: Colors.white.withOpacity(0.82)),
                      ),
                    ],
                  ),
                ),
                if (onInfoPressed != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: FilledButton.icon(
                      onPressed: onInfoPressed,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('课堂提示'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.18),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 4,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NavigationPills extends StatefulWidget {
  const _NavigationPills({
    required this.items,
    required this.currentIndex,
    required this.onChanged,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  State<_NavigationPills> createState() => _NavigationPillsState();
}

class _NavigationPillsState extends State<_NavigationPills> {
  double _hoverIndex = -1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final navItems = <Widget>[];
        for (var i = 0; i < widget.items.length; i++) {
          final item = widget.items[i];
          final selected = i == widget.currentIndex;
          final hovering = i == _hoverIndex.toInt();
          navItems.add(
            Padding(
              padding: EdgeInsets.only(right: i == widget.items.length - 1 ? 0 : 12),
              child: _NavPill(
                item: item,
                compact: isCompact,
                selected: selected,
                hovering: hovering,
                onEnter: () => setState(() => _hoverIndex = i.toDouble()),
                onExit: () => setState(() => _hoverIndex = -1),
                onTap: () => widget.onChanged(i),
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: GlowUpColors.primary.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(children: navItems),
            ),
          ),
        );
      },
    );
  }
}

class _NavPill extends StatefulWidget {
  const _NavPill({
    required this.item,
    required this.compact,
    required this.selected,
    required this.hovering,
    required this.onTap,
    required this.onEnter,
    required this.onExit,
  });

  final _NavItem item;
  final bool compact;
  final bool selected;
  final bool hovering;
  final VoidCallback onTap;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = widget.selected;
    final hovering = widget.hovering;
    final baseColor = selected
        ? widget.item.accent
        : GlowUpColors.midnight.withValues(alpha: 0.32);

    final backgroundColor = selected
        ? widget.item.accent.withValues(alpha: 0.16)
        : hovering
            ? GlowUpColors.primary.withValues(alpha: 0.1)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => widget.onEnter(),
      onExit: (_) => widget.onExit(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 18 : 24,
            vertical: widget.compact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? widget.item.accent.withValues(alpha: 0.4)
                  : GlowUpColors.outline.withValues(alpha: 0.6),
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: widget.item.accent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: widget.compact ? 32 : 36,
                width: widget.compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: selected
                      ? widget.item.accent.withValues(alpha: 0.32)
                      : widget.item.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.item.icon,
                  size: widget.compact ? 20 : 22,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: widget.compact ? 10 : 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: baseColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedOpacity(
                    opacity: selected ? 1 : 0.7,
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      widget.item.subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: widget.compact ? 13 : 14,
                        color: GlowUpColors.midnight.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
