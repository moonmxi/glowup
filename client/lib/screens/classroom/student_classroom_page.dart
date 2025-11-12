import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../state/classroom_state.dart';
import '../../state/showcase_state.dart';
import '../../theme/glowup_theme.dart';
import '../../utils/platform_file_helper.dart';

class StudentClassroomPage extends StatefulWidget {
  const StudentClassroomPage({super.key});

  @override
  State<StudentClassroomPage> createState() => _StudentClassroomPageState();
}

class _StudentClassroomPageState extends State<StudentClassroomPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isHandRaised = false;
  bool _isMicOn = false;
  bool _isCameraOn = false;
  final String _currentActivity = '自由创作';
  final int _timeRemaining = 1800;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('课堂'),
        backgroundColor: GlowUpColors.secondary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        actions: [
          IconButton(
            onPressed: () => _showClassroomInfo(context),
            icon: const Icon(Icons.info_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: '课堂', icon: Icon(Icons.class_)),
            Tab(text: '作品', icon: Icon(Icons.create)),
            Tab(text: '互动', icon: Icon(Icons.chat)),
            Tab(text: '资源', icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassroomTab(),
          _buildWorksTab(),
          _buildInteractionTab(),
          _buildResourcesTab(),
        ],
      ),
    );
  }

  Widget _buildClassroomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentActivity(),
          const SizedBox(height: 20),
          _buildClassroomControls(),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 20),
          _buildClassmates(),
        ],
      ),
    );
  }

  Widget _buildCurrentActivity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [GlowUpColors.secondary, GlowUpColors.peach],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_filled,
                  color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                '当前活动',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(_timeRemaining ~/ 60).toString().padLeft(2, '0')}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentActivity,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '发挥你的想象力，创作一幅关于春天的画作',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isHandRaised ? Icons.pan_tool : Icons.pan_tool_outlined,
            label: '举手',
            isActive: _isHandRaised,
            onTap: () => setState(() => _isHandRaised = !_isHandRaised),
          ),
          _buildControlButton(
            icon: _isMicOn ? Icons.mic : Icons.mic_off,
            label: '麦克风',
            isActive: _isMicOn,
            onTap: () => setState(() => _isMicOn = !_isMicOn),
          ),
          _buildControlButton(
            icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
            label: '摄像头',
            isActive: _isCameraOn,
            onTap: () => setState(() => _isCameraOn = !_isCameraOn),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? GlowUpColors.secondary : Colors.grey[200],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? GlowUpColors.secondary : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速操作',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard('提交作品', Icons.upload, () => _submitWork()),
            _buildActionCard('查看任务', Icons.assignment, () => _viewTasks()),
            _buildActionCard('求助老师', Icons.help, () => _askForHelp()),
            _buildActionCard('分享屏幕', Icons.screen_share, () => _shareScreen()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GlowUpColors.secondary.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: GlowUpColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassmates() {
    final classmates = [
      {'name': '小红', 'status': '在线', 'activity': '正在绘画'},
      {'name': '小刚', 'status': '在线', 'activity': '正在思考'},
      {'name': '小丽', 'status': '离线', 'activity': ''},
      {'name': '小华', 'status': '在线', 'activity': '正在创作'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '同学状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '在线 ${classmates.where((c) => c['status'] == '在线').length}/${classmates.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: classmates.length,
          itemBuilder: (context, index) {
            final classmate = classmates[index];
            final isOnline = classmate['status'] == '在线';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            isOnline ? GlowUpColors.secondary : Colors.grey,
                        child: Text(
                          classmate['name']![0],
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classmate['name']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (isOnline && classmate['activity']!.isNotEmpty)
                          Text(
                            classmate['activity']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isOnline)
                    IconButton(
                      onPressed: () => _chatWithClassmate(classmate['name']!),
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                      color: GlowUpColors.secondary,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWorksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkSubmission(),
          const SizedBox(height: 20),
          _buildMyWorks(),
        ],
      ),
    );
  }

  Widget _buildWorkSubmission() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '作品提交',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.grey[300]!, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 32, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  '点击上传作品',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () => _uploadWork(),
                  icon: const Icon(Icons.upload),
                  label: const Text('上传作品'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlowUpColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveAsDraft(),
                icon: const Icon(Icons.save),
                label: const Text('保存草稿'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyWorks() {
    final works = [
      {'title': '春天的花园', 'type': '妙手画坊', 'status': '已提交', 'score': '95'},
      {'title': '快乐的歌', 'type': '旋律工坊', 'status': '草稿', 'score': ''},
      {'title': '彩虹城堡', 'type': '妙手画坊', 'status': '已评分', 'score': '88'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '我的作品',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: works.length,
          itemBuilder: (context, index) {
            final work = works[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: GlowUpColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      work['type'] == '妙手画坊'
                          ? Icons.image
                          : Icons.music_note,
                      color: GlowUpColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          work['title']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              work['type']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(work['status']!)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                work['status']!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(work['status']!),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (work['score']!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: GlowUpColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        work['score']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GlowUpColors.accent,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInteractionTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildChatMessage('老师', '大家开始创作吧！', true),
              _buildChatMessage('小红', '老师，我可以用蓝色吗？', false),
              _buildChatMessage('老师', '当然可以，蓝色很棒！', true),
              _buildChatMessage('我', '我画了一朵花', false),
              _buildChatMessage('老师', '很好！继续加油', true),
            ],
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatMessage(String sender, String message, bool isTeacher) {
    final isMe = sender == '我';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  isTeacher ? GlowUpColors.accent : GlowUpColors.secondary,
              child: Text(
                sender[0],
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? GlowUpColors.secondary : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTeacher
                            ? GlowUpColors.accent
                            : GlowUpColors.secondary,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: GlowUpColors.secondary,
              child: const Text(
                '我',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '输入消息...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: GlowUpColors.secondary,
            child: IconButton(
              onPressed: () => _sendMessage(),
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    final resources = [
      {'title': '绘画基础教程', 'type': 'PDF', 'size': '2.5MB'},
      {'title': '色彩搭配指南', 'type': 'PDF', 'size': '1.8MB'},
      {'title': '创意思维训练', 'type': 'Video', 'size': '15.2MB'},
      {'title': '音乐节拍练习', 'type': 'Audio', 'size': '5.1MB'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final resource = resources[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getResourceColor(resource['type']!).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getResourceIcon(resource['type']!),
                  color: _getResourceColor(resource['type']!),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${resource['type']} • ${resource['size']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _downloadResource(resource['title']!),
                icon: const Icon(Icons.download),
                color: GlowUpColors.secondary,
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '已提交':
        return Colors.blue;
      case '草稿':
        return Colors.orange;
      case '已评分':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getResourceColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'Video':
        return Colors.blue;
      case 'Audio':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'Video':
        return Icons.play_circle;
      case 'Audio':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showClassroomInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('课堂信息'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('课程：美术创作课'),
            Text('老师：张老师'),
            Text('时间：14:00-15:30'),
            Text('参与人数：25人'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _submitWork() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Work submitted successfully')),
    );
  }

  void _viewTasks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viewing tasks')),
    );
  }

  void _askForHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help request sent to teacher')),
    );
  }

  void _shareScreen() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Screen sharing started')),
    );
  }

  void _chatWithClassmate(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with $name')),
    );
  }

  static const Set<String> _imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
  };

  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
  };

  static const Set<String> _audioExtensions = {
    'mp3',
    'wav',
    'aac',
    'm4a',
    'flac',
    'ogg',
  };

  Future<void> _uploadWork() async {
    final auth = context.read<AuthState>();
    final messenger = ScaffoldMessenger.of(context);
    final classroomState = context.read<ClassroomState>();
    final showcaseState = context.read<ShowcaseState>();
    final classroom = classroomState.classroom;
    final classId = classroom?.id;
    if (!auth.isAuthenticated) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('请先登录后再上传作品')),
      );
      return;
    }

    final result = await FilePicker.platform
        .pickFiles(type: FileType.media, withData: true);
    if (result == null) return;
    final picked = result.files.single;

    final resolved = await resolvePlatformFile(picked);
    if (resolved == null) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('无法读取所选文件，请重新尝试')),
      );
      return;
    }

    final ext = picked.extension ??
        (picked.name.contains('.') ? picked.name.split('.').last : '');

    final kind = _inferKindFromExtension(picked.extension);

    bool success = false;
    try {
      success = await showcaseState.uploadContent(
        title: picked.name.isNotEmpty ? picked.name : '课堂作品',
        kind: kind,
        description: '课堂作品提交',
        visibility: 'classes',
        classroomIds: classId != null ? [classId] : const [],
        fileBytes: resolved.bytes,
        fileName: resolved.name,
        fileMimeType: resolved.mimeType,
        metadata: {
          'uploader': auth.user?.username ?? 'student',
          'source': 'student_classroom',
          if (ext.isNotEmpty) 'extension': ext,
        },
        preview: {
          'fileName': picked.name,
          'type': 'user_upload',
        },
        teacherGenerated: false,
        aiGenerated: false,
      );
    } finally {}

    if (!mounted) return;
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('作品上传成功')),
      );
      await showcaseState.loadFeed(scope: 'classes', classId: classId);
    } else {
      final message = showcaseState.error ?? '作品上传失败，请稍后再试';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _inferKindFromExtension(String? extension) {
    final ext = extension?.toLowerCase() ?? '';
    if (_imageExtensions.contains(ext)) return 'image';
    if (_videoExtensions.contains(ext)) return 'video';
    if (_audioExtensions.contains(ext)) return 'music';
    return 'lesson';
  }

  void _saveAsDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved as draft')),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent')),
    );
  }

  void _downloadResource(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $title')),
    );
  }
}
