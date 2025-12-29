import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../services/native_file_picker.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class ImageAnalysisPage extends StatefulWidget {
  const ImageAnalysisPage({
    super.key,
    this.initialImageBytes,
    this.initialLabel,
  });

  final Uint8List? initialImageBytes;
  final String? initialLabel;

  @override
  State<ImageAnalysisPage> createState() => _ImageAnalysisPageState();
}

class _ImageAnalysisPageState extends State<ImageAnalysisPage> {
  Uint8List? _imageBytes;
  img.Image? _decoded;
  Rect? _selection;
  Map<String, String>? _stats;
  Color? _sampleColor;
  String? _sampleHex;
  bool _loading = false;
  String? _sourceLabel;
  _GlobalImageInsights? _globalInsights;
  bool _analyzingInsights = false;
  int _analysisToken = 0;

  final GlobalKey _imageKey = GlobalKey();
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    if (widget.initialImageBytes != null) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialImage();
      });
    }
  }

  Future<void> _loadInitialImage() async {
    try {
      final bytes = widget.initialImageBytes;
      if (bytes == null) return;
      await _ingestBytes(bytes, label: widget.initialLabel ?? '生成图片');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _loading = true;
    });
    try {
      final picked = await pickNativeImage();
      if (picked == null) return;
      await _ingestBytes(picked.bytes, label: picked.name);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选取图片失败：${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst(RegExp('^Exception: '), '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选取图片失败：$message')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _ingestBytes(Uint8List bytes, {String? label}) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法解析图片，请更换文件。')),
      );
      return;
    }
    final token = ++_analysisToken;
    setState(() {
      _imageBytes = bytes;
      _decoded = decoded;
      _selection = null;
      _stats = null;
      _sampleColor = null;
      _sourceLabel = label;
      _globalInsights = null;
      _analyzingInsights = true;
    });
    _scheduleGlobalAnalysis(decoded, token);
  }

  void _scheduleGlobalAnalysis(img.Image decoded, int token) {
    Future<_GlobalImageInsights>(
      () => _generateGlobalImageInsights(decoded),
    ).then((result) {
      if (!mounted || token != _analysisToken) return;
      setState(() {
        _globalInsights = result;
        _analyzingInsights = false;
      });
    }).catchError((error) {
      debugPrint('Global image analysis failed: $error');
      if (!mounted || token != _analysisToken) return;
      setState(() {
        _analyzingInsights = false;
      });
    });
  }

  Offset? _mapToImage(Offset localPos) {
    final decoded = _decoded;
    if (decoded == null) return null;
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final size = renderBox.size;

    final imageAspect = decoded.width / decoded.height;
    final boxAspect = size.width / size.height;

    double usedWidth;
    double usedHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > boxAspect) {
      usedWidth = size.width;
      usedHeight = size.width / imageAspect;
      offsetY = (size.height - usedHeight) / 2;
    } else {
      usedHeight = size.height;
      usedWidth = size.height * imageAspect;
      offsetX = (size.width - usedWidth) / 2;
    }

    final dx = (localPos.dx - offsetX).clamp(0, usedWidth);
    final dy = (localPos.dy - offsetY).clamp(0, usedHeight);

    final px = dx / usedWidth * decoded.width;
    final py = dy / usedHeight * decoded.height;
    if (px.isNaN || py.isNaN) return null;
    return Offset(px, py);
  }

  void _onTapDown(TapDownDetails details) {
    final decoded = _decoded;
    if (decoded == null) return;
    final pixel = _mapToImage(details.localPosition);
    if (pixel == null) return;

    final result = _collectStats(decoded, Rect.fromLTWH(pixel.dx, pixel.dy, 1, 1));

    setState(() {
      _sampleColor = result.averageColor;
      _stats = result.values;
      _sampleHex = result.hex;
      _selection = null;
    });
  }

  void _onPanStart(DragStartDetails details) {
    final start = _mapToImage(details.localPosition);
    if (start == null) return;
    setState(() {
      _dragStart = start;
      _selection = Rect.fromLTWH(start.dx, start.dy, 0, 0);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    final current = _mapToImage(details.localPosition);
    if (current == null) return;
    setState(() {
      _selection = Rect.fromPoints(_dragStart!, current);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final decoded = _decoded;
    final region = _selection;
    if (decoded == null || region == null) return;

    final normalized = Rect.fromLTRB(
      region.left.clamp(0, decoded.width.toDouble()),
      region.top.clamp(0, decoded.height.toDouble()),
      region.right.clamp(0, decoded.width.toDouble()),
      region.bottom.clamp(0, decoded.height.toDouble()),
    );
    if (normalized.width <= 1 && normalized.height <= 1) return;

    final result = _collectStats(decoded, normalized);

    setState(() {
      _stats = result.values;
      _sampleColor = result.averageColor;
      _sampleHex = result.hex;
    });
  }

  _RegionStats _collectStats(img.Image decoded, Rect region) {
    int left = region.left.floor();
    int top = region.top.floor();
    int right = region.right.ceil();
    int bottom = region.bottom.ceil();

    left = max(0, min(left, decoded.width - 1));
    top = max(0, min(top, decoded.height - 1));
    right = max(left + 1, min(right, decoded.width));
    bottom = max(top + 1, min(bottom, decoded.height));

    final width = right - left;
    final height = bottom - top;
    final totalPixels = width * height;

    double sumR = 0;
    double sumG = 0;
    double sumB = 0;
    int minR = 255, minG = 255, minB = 255;
    int maxR = 0, maxG = 0, maxB = 0;

    for (int y = top; y < bottom; y++) {
      for (int x = left; x < right; x++) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        sumR += r;
        sumG += g;
        sumB += b;
        if (r < minR) minR = r.toInt();
        if (g < minG) minG = g.toInt();
        if (b < minB) minB = b.toInt();
        if (r > maxR) maxR = r.toInt();
        if (g > maxG) maxG = g.toInt();
        if (b > maxB) maxB = b.toInt();
      }
    }

    final avgR = (sumR / totalPixels) / 255;
    final avgG = (sumG / totalPixels) / 255;
    final avgB = (sumB / totalPixels) / 255;
    final luminance = 0.2126 * avgR + 0.7152 * avgG + 0.0722 * avgB;
    final hue = _rgbToHue(avgR, avgG, avgB);

    final values = {
      '样本像素': totalPixels.toString(),
      '平均 R': avgR.toStringAsFixed(3),
      '平均 G': avgG.toStringAsFixed(3),
      '平均 B': avgB.toStringAsFixed(3),
      '最亮 RGB': '($maxR, $maxG, $maxB)',
      '最暗 RGB': '($minR, $minG, $minB)',
      '亮度': '${(luminance * 100).toStringAsFixed(1)} %',
      '色相 (°)': hue.toStringAsFixed(1),
    };

    final rInt = (avgR * 255).round().clamp(0, 255);
    final gInt = (avgG * 255).round().clamp(0, 255);
    final bInt = (avgB * 255).round().clamp(0, 255);
    final averageColor = Color.fromARGB(255, rInt, gInt, bInt);
    final hex = '#${rInt.toRadixString(16).padLeft(2, '0')}${gInt.toRadixString(16).padLeft(2, '0')}${bInt.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
    values['主色 Hex'] = hex;

    return _RegionStats(averageColor: averageColor, values: values, hex: hex);
  }

  double _rgbToHue(double r, double g, double b) {
    final maxVal = max(r, max(g, b));
    final minVal = min(r, min(g, b));
    final delta = maxVal - minVal;
    if (delta == 0) return 0;
    if (maxVal == r) {
      return (60 * ((g - b) / delta) + 360) % 360;
    }
    if (maxVal == g) {
      return 60 * ((b - r) / delta) + 120;
    }
    return 60 * ((r - g) / delta) + 240;
  }

  _GlobalImageInsights _generateGlobalImageInsights(img.Image decoded) {
    final width = decoded.width;
    final height = decoded.height;
    final totalPixels = width * height;
    const targetSamples = 3500;
    final step = max(1, sqrt(totalPixels / targetSamples).floor());

    final buckets = <String, _PaletteBucket>{};
    double sumLightness = 0;
    double sumSaturation = 0;
    int count = 0;

    for (int y = 0; y < height; y += step) {
      for (int x = 0; x < width; x += step) {
        final pixel = decoded.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        final hsl = _rgbToHslColor(r, g, b);
        sumLightness += hsl.lightness;
        sumSaturation += hsl.saturation;
        count++;

        final key = '${pixel.r ~/ 32}_${pixel.g ~/ 32}_${pixel.b ~/ 32}';
        final bucket = buckets.putIfAbsent(key, _PaletteBucket.new);
        bucket.count++;
        bucket.sumR += pixel.r;
        bucket.sumG += pixel.g;
        bucket.sumB += pixel.b;
      }
    }

    final palette = buckets.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    final colors = palette.take(4).map((bucket) {
      final r = (bucket.sumR / bucket.count).round().clamp(0, 255);
      final g = (bucket.sumG / bucket.count).round().clamp(0, 255);
      final b = (bucket.sumB / bucket.count).round().clamp(0, 255);
      return Color.fromARGB(255, r, g, b);
    }).toList();
    if (colors.isEmpty) {
      colors.add(const Color(0xFFCCCCCC));
    }
    while (colors.length < 3) {
      colors.add(colors.last);
    }

    final brightness = count == 0 ? 0.0 : (sumLightness / count).clamp(0.0, 1.0).toDouble();
    final saturation = count == 0 ? 0.0 : (sumSaturation / count).clamp(0.0, 1.0).toDouble();
    final mood = _describeMood(brightness, saturation);
    String narrative;
    switch (mood) {
      case MoodTone.bright:
        narrative = '整体亮度高，适合讲述快乐、节日或阳光主题。';
        break;
      case MoodTone.soft:
        narrative = '明度与饱和度适中，可引导孩子描述温柔、治愈的画面。';
        break;
      case MoodTone.moody:
        narrative = '画面偏灰暗，可结合“夜晚”“雨天”等故事氛围进行创作。';
        break;
      case MoodTone.vivid:
        narrative = '颜色饱和度高，鼓励学生表达热烈、运动感十足的情绪。';
        break;
    }

    return _GlobalImageInsights(
      palette: colors,
      brightness: brightness,
      saturation: saturation,
      moodLabel: _moodLabel(mood),
      narrative: narrative,
    );
  }

  _HslColor _rgbToHslColor(double r, double g, double b) {
    final maxVal = max(r, max(g, b));
    final minVal = min(r, min(g, b));
    final delta = maxVal - minVal;
    final lightness = (maxVal + minVal) / 2;
    double saturation = 0;
    if (delta != 0) {
      final denom = max(0.001, 1 - (2 * lightness - 1).abs());
      saturation = delta / denom;
    }
    return _HslColor(lightness: lightness, saturation: saturation.clamp(0.0, 1.0));
  }

  MoodTone _describeMood(double brightness, double saturation) {
    if (brightness >= 0.68 && saturation >= 0.45) return MoodTone.bright;
    if (brightness <= 0.35 && saturation <= 0.35) return MoodTone.moody;
    if (saturation >= 0.6) return MoodTone.vivid;
    return MoodTone.soft;
  }

  String _moodLabel(MoodTone tone) {
    switch (tone) {
      case MoodTone.bright:
        return '明亮 · 快乐';
      case MoodTone.moody:
        return '灰暗 · 沉静';
      case MoodTone.vivid:
        return '高饱和 · 热烈';
      case MoodTone.soft:
        return '柔和 · 平稳';
    }
  }

  String _formatPercent(double value) {
    final pct = (value * 100).clamp(0, 100);
    return '${pct.toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('色彩小助手'),
        actions: [
          IconButton(
            tooltip: '选择图片',
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '帮助老师精准讲解色彩：点击图片或框选区域查看 RGB、亮度和色相数据。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: GlowUpColors.dusk.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_imageBytes == null)
                _EmptyState(onPick: _pickImage)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_sourceLabel != null && _sourceLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '来源：${_sourceLabel!}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: GlowUpColors.dusk.withValues(alpha: 0.6)),
                        ),
                      ),
                    GestureDetector(
                      onTapDown: _onTapDown,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: AspectRatio(
                        aspectRatio: _decoded!.width / _decoded!.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                _imageBytes!,
                                key: _imageKey,
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (_selection != null)
                              _SelectionOverlay(
                                selection: _selection!,
                                imageSize: Size(
                                  _decoded!.width.toDouble(),
                                  _decoded!.height.toDouble(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_sampleColor != null) ...[
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _sampleColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _sampleHex ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    GlowCard(
                      child: _stats == null
                          ? const Text('点击或框选作品区域，即可查看色彩数据。')
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _stats!.entries
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 120,
                                            child: Text(
                                              entry.key,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          Expanded(child: Text(entry.value)),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    if (_analyzingInsights)
                      const GlowCard(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text('正在离线识别主色调与明度…'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_globalInsights != null) ...[
                      GlowCard(
                        child: _GlobalInsightsView(
                          insights: _globalInsights!,
                          brightnessLabel: _formatPercent(_globalInsights!.brightness),
                          saturationLabel: _formatPercent(_globalInsights!.saturation),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    GlowCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '教学建议',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 8),
                          Text('• 数值化的 RGB 帮助孩子理解“暖色”“冷色”的差别。'),
                          Text('• 对比亮度可提醒学生增加层次、避免画面发灰。'),
                          Text('• 色相信息可延伸到自然观察，如秋天叶子的颜色变化。'),
                        ],
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

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({required this.selection, required this.imageSize});

  final Rect selection;
  final Size imageSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SelectionPainter(selection, imageSize),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter(this.selection, this.imageSize);

  final Rect selection;
  final Size imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final imageAspect = imageSize.width / imageSize.height;
    final boxAspect = size.width / size.height;

    double usedWidth;
    double usedHeight;
    double offsetX = 0;
    double offsetY = 0;

    if (imageAspect > boxAspect) {
      usedWidth = size.width;
      usedHeight = size.width / imageAspect;
      offsetY = (size.height - usedHeight) / 2;
    } else {
      usedHeight = size.height;
      usedWidth = size.height * imageAspect;
      offsetX = (size.width - usedWidth) / 2;
    }

    final scaleX = usedWidth / imageSize.width;
    final scaleY = usedHeight / imageSize.height;

    final drawRect = Rect.fromLTWH(
      offsetX + selection.left * scaleX,
      offsetY + selection.top * scaleY,
      selection.width.abs() * scaleX,
      selection.height.abs() * scaleY,
    );

    final fill = Paint()
      ..color = GlowUpColors.bloom.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(drawRect, fill);

    final border = Paint()
      ..color = GlowUpColors.dusk
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(drawRect, border);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.selection != selection || oldDelegate.imageSize != imageSize;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: GlowUpColors.lavender.withValues(alpha: 0.25),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.palette_outlined, size: 48, color: GlowUpColors.dusk),
              SizedBox(height: 12),
              Text('从相册或文件中选择一张作品照片来开始分析'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.photo_library),
          label: const Text('选择图片'),
        ),
      ],
    );
  }
}

class _RegionStats {
  const _RegionStats({
    required this.averageColor,
    required this.values,
    required this.hex,
  });

  final Color averageColor;
  final Map<String, String> values;
  final String hex;
}

class _GlobalInsightsView extends StatelessWidget {
  const _GlobalInsightsView({
    required this.insights,
    required this.brightnessLabel,
    required this.saturationLabel,
  });

  final _GlobalImageInsights insights;
  final String brightnessLabel;
  final String saturationLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '识别结果（离线）',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: GlowUpColors.mist,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '本地 CV',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GlowUpColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '主色调 (PALETTE)',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: insights.palette
              .map((color) => _PaletteSwatch(color: color, hex: _hexFromColor(color)))
              .toList(),
        ),
        const SizedBox(height: 16),
        _InsightMetricBar(
          label: '明度',
          value: insights.brightness,
          displayValue: brightnessLabel,
          barColor: GlowUpColors.sunset,
        ),
        const SizedBox(height: 8),
        _InsightMetricBar(
          label: '饱和度',
          value: insights.saturation,
          displayValue: saturationLabel,
          barColor: GlowUpColors.lavender,
        ),
        const SizedBox(height: 16),
        Text(
          '情绪倾向：${insights.moodLabel}',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          insights.narrative,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Text(
          '识别内容',
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const _InsightBullet(
          text: '离线计算 · lib/services/ai_analyzers.dart 中的轻量级 CV 算法在端侧运行，弱网环境也可用。',
        ),
        const _InsightBullet(
          text: '特征提取 · 实时解析摄像头/作品图像，输出主色调 PALETTE + HSL 明度/饱和度，用于情绪判断。',
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.color, required this.hex});

  final Color color;
  final String hex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          hex,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InsightMetricBar extends StatelessWidget {
  const _InsightMetricBar({
    required this.label,
    required this.value,
    required this.displayValue,
    required this.barColor,
  });

  final String label;
  final double value;
  final String displayValue;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(displayValue, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: GlowUpColors.mist,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class _InsightBullet extends StatelessWidget {
  const _InsightBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalImageInsights {
  const _GlobalImageInsights({
    required this.palette,
    required this.brightness,
    required this.saturation,
    required this.moodLabel,
    required this.narrative,
  });

  final List<Color> palette;
  final double brightness;
  final double saturation;
  final String moodLabel;
  final String narrative;
}

class _PaletteBucket {
  _PaletteBucket();

  int count = 0;
  double sumR = 0;
  double sumG = 0;
  double sumB = 0;
}

class _HslColor {
  const _HslColor({required this.lightness, required this.saturation});

  final double lightness;
  final double saturation;
}

enum MoodTone { bright, soft, moody, vivid }

String _hexFromColor(Color color) {
  final r = color.red.toRadixString(16).padLeft(2, '0');
  final g = color.green.toRadixString(16).padLeft(2, '0');
  final b = color.blue.toRadixString(16).padLeft(2, '0');
  return '#${(r + g + b).toUpperCase()}';
}
