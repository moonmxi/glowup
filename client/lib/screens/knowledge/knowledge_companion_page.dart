import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class KnowledgeCompanionPage extends StatefulWidget {
  const KnowledgeCompanionPage({super.key});

  @override
  State<KnowledgeCompanionPage> createState() => _KnowledgeCompanionPageState();
}

class _KnowledgeCompanionPageState extends State<KnowledgeCompanionPage> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, dynamic>> _conversations = [];
  bool _isThinking = false;

  final List<String> _quickQuestions = [
    '为什么天空是蓝色的？',
    '彩虹是怎么形成的？',
    '为什么会有四季变化？',
    '鸟儿为什么会飞？',
    '花朵为什么有不同的颜色？',
    '为什么会下雨？',
    '星星为什么会闪烁？',
    '蝴蝶是怎么变成的？',
  ];

  final List<Map<String, String>> _categories = [
    {'name': '自然科学', 'icon': '🌿', 'color': 'mint'},
    {'name': '动物世界', 'icon': '🐾', 'color': 'peach'},
    {'name': '天文地理', 'icon': '🌟', 'color': 'breeze'},
    {'name': '艺术创作', 'icon': '🎨', 'color': 'sunset'},
    {'name': '生活常识', 'icon': '🏠', 'color': 'lavender'},
    {'name': '历史文化', 'icon': '📚', 'color': 'dusk'},
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _conversations.add({
        'type': 'question',
        'content': question,
        'timestamp': DateTime.now(),
      });
      _isThinking = true;
    });

    _questionController.clear();

    await Future.delayed(const Duration(seconds: 2));

    final answer = _generateAnswer(question);
    
    setState(() {
      _conversations.add({
        'type': 'answer',
        'content': answer,
        'timestamp': DateTime.now(),
      });
      _isThinking = false;
    });
  }

  String _generateAnswer(String question) {
    final answers = {
      '为什么天空是蓝色的？': '天空看起来是蓝色的，是因为阳光中的蓝色光线被空气中的小颗粒散射得最多。就像你用手电筒照射有灰尘的地方，光线会被散开一样！',
      '彩虹是怎么形成的？': '彩虹是阳光和雨滴一起创造的美丽现象！当阳光穿过空中的小雨滴时，白色的阳光就像通过三棱镜一样，分解成了红、橙、黄、绿、蓝、靛、紫七种颜色。',
      '为什么会有四季变化？': '四季变化是因为地球在围绕太阳转动时是倾斜的。就像一个倾斜的陀螺在转动，不同的地方会轮流接受更多或更少的阳光，所以就有了春夏秋冬。',
      '鸟儿为什么会飞？': '鸟儿能飞是因为它们有特殊的身体结构：轻盈的骨头、强壮的翅膀肌肉，还有羽毛！羽毛的形状能帮助它们在空中产生升力，就像飞机的翅膀一样。',
      '花朵为什么有不同的颜色？': '花朵有不同颜色是为了吸引不同的昆虫来帮助传播花粉。红色吸引蝴蝶，黄色吸引蜜蜂，白色在夜晚吸引蛾子。每种颜色都有它的小秘密！',
    };

    return answers[question] ?? '这是一个很棒的问题！让我想想... 大自然中有很多奇妙的现象，每一个都有它独特的原理。你的好奇心真棒，继续保持探索的精神吧！';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.knowledgeModule),
        backgroundColor: GlowUpColors.card,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: GlowUpColors.breeze.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.psychology, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppConstants.aiName}的知识小课堂',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '有什么想知道的，尽管问我吧！',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: GlowUpColors.dusk.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_conversations.isEmpty) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '知识分类',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return _buildCategoryCard(category);
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    GlowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '热门问题',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickQuestions.map((question) {
                              return InkWell(
                                onTap: () => _askQuestion(question),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: GlowUpColors.breeze.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: GlowUpColors.breeze.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    question,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: GlowUpColors.breeze,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _conversations.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _conversations.length && _isThinking) {
                    return _buildThinkingBubble();
                  }
                  
                  final conversation = _conversations[index];
                  return _buildConversationBubble(conversation);
                },
              ),
            ),
          ],
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GlowUpColors.card,
              border: Border(
                top: BorderSide(
                  color: GlowUpColors.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: '问问${AppConstants.aiName}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: GlowUpColors.mist,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: _askQuestion,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: GlowUpColors.breeze,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _isThinking 
                        ? null 
                        : () => _askQuestion(_questionController.text),
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${category['name']}分类功能即将上线')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getCategoryColor(category['color']!).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getCategoryColor(category['color']!).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              category['icon']!,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category['name']!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getCategoryColor(category['color']!),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String colorName) {
    switch (colorName) {
      case 'mint': return GlowUpColors.mint;
      case 'peach': return GlowUpColors.peach;
      case 'breeze': return GlowUpColors.breeze;
      case 'sunset': return GlowUpColors.sunset;
      case 'lavender': return GlowUpColors.lavender;
      case 'dusk': return GlowUpColors.dusk;
      default: return GlowUpColors.breeze;
    }
  }

  Widget _buildConversationBubble(Map<String, dynamic> conversation) {
    final isQuestion = conversation['type'] == 'question';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isQuestion ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isQuestion) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlowUpColors.breeze.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: GlowUpColors.breeze,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isQuestion 
                    ? GlowUpColors.breeze 
                    : GlowUpColors.card,
                borderRadius: BorderRadius.circular(16),
                border: isQuestion 
                    ? null 
                    : Border.all(color: GlowUpColors.outline),
              ),
              child: Text(
                conversation['content'],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isQuestion ? Colors.white : null,
                      height: 1.4,
                    ),
              ),
            ),
          ),
          if (isQuestion) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GlowUpColors.sunset.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: GlowUpColors.sunset,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GlowUpColors.breeze.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.psychology,
              size: 20,
              color: GlowUpColors.breeze,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GlowUpColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GlowUpColors.outline),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${AppConstants.aiName}正在思考',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: GlowUpColors.dusk.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(GlowUpColors.breeze),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}