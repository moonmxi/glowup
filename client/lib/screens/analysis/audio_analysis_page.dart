import 'dart:async';
import 'dart:math';

import 'package:fftea/fftea.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../services/native_file_picker.dart';
import '../../theme/glowup_theme.dart';
import '../../widgets/glow_card.dart';

class AudioAnalysisPage extends StatefulWidget {
  const AudioAnalysisPage({
    super.key,
    this.initialAudioBytes,
    this.initialLabel,
  });

  final Uint8List? initialAudioBytes;
  final String? initialLabel;

  @override
  State<AudioAnalysisPage> createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  final AudioPlayer _player = AudioPlayer();

  static const double _chartWindowSeconds = 4.0;

  StreamSubscription<Duration>? _positionSub;
  Duration? _audioDuration;
  Uint8List? _audioBytes;
  String? _metaInfo;
  String? _sourceLabel;

  bool _isLoading = false;
  double _currentDb = 0;
  double _currentPitch = 0;
  double _currentTime = 0;

  List<_AnalysisPoint> _amplitude = [];
  List<_AnalysisPoint> _pitch = [];
  List<_AnalysisPoint> _displayAmplitude = [];
  List<_AnalysisPoint> _displayPitch = [];

  @override
  void initState() {
    super.initState();
    _positionSub = _player.positionStream.listen(_handlePosition);
    final initialBytes = widget.initialAudioBytes;
    if (initialBytes != null && initialBytes.isNotEmpty) {
      _beginLoading();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await _ingestAudioBytes(
            initialBytes,
            displayName: widget.initialLabel,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('音频加载失败：$e')),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _beginLoading() {
    setState(() {
      _isLoading = true;
      _audioDuration = null;
      _audioBytes = null;
      _metaInfo = null;
      _sourceLabel = null;
      _currentDb = 0;
      _currentPitch = 0;
      _currentTime = 0;
      _amplitude = [];
      _pitch = [];
      _displayAmplitude = [];
      _displayPitch = [];
    });
  }

  Future<void> _pickAudio() async {
    _beginLoading();
    try {
      final picked = await pickNativeAudio();
      if (picked == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法读取音频文件，请重试。')),
          );
        }
        return;
      }
      await _ingestAudioBytes(
        bytes,
        displayName: picked.name,
        mimeType: picked.mimeType,
      );
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音频选择失败：${e.message ?? e.code}')),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音频处理失败：${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音频处理失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _ingestAudioBytes(
    Uint8List bytes, {
    String? displayName,
    String? mimeType,
  }) async {
    if (!mounted) return;

    final analysis = await _analyzeAudioBytes(bytes);
    if (!mounted) return;

    try {
      final dataUri = Uri.dataFromBytes(
        bytes,
        mimeType: mimeType ?? 'audio/wav',
      );
      await _player.setAudioSource(AudioSource.uri(dataUri));
      _audioDuration = _player.duration ?? analysis.duration;
    } catch (e) {
      // Playback is optional; analysis results are still valid.
      debugPrint('Audio player initialization failed: $e');
      _audioDuration = analysis.duration;
    }

    final amplitudeWindow =
        _windowAround(analysis.amplitude, 0, _chartWindowSeconds);
    final pitchWindow =
        _windowAround(analysis.pitch, 0, _chartWindowSeconds);

    final labelParts = <String>[
      if (displayName != null && displayName.trim().isNotEmpty)
        displayName.trim(),
      analysis.metaInfo,
    ];

    setState(() {
      _audioBytes = bytes;
      _sourceLabel = displayName;
      _metaInfo = labelParts.join(' · ');
      _amplitude = analysis.amplitude;
      _pitch = analysis.pitch;
      _displayAmplitude = amplitudeWindow;
      _displayPitch = pitchWindow;
      _currentDb = analysis.initialDb;
      _currentPitch = analysis.initialPitch;
      _currentTime = 0;
      _isLoading = false;
    });
  }

  void _handlePosition(Duration position) {
    if (_amplitude.isEmpty && _pitch.isEmpty) return;
    final seconds = position.inMilliseconds / 1000.0;

    final ampPoint =
        _amplitude.isNotEmpty ? _nearestPoint(_amplitude, seconds) : null;
    final pitchPoint =
        _pitch.isNotEmpty ? _nearestPoint(_pitch, seconds) : null;

    final windowAmplitude =
        _windowAround(_amplitude, seconds, _chartWindowSeconds);
    final windowPitch =
        _windowAround(_pitch, seconds, _chartWindowSeconds);

    setState(() {
      _currentTime = seconds;
      if (ampPoint != null) {
        _currentDb = ampPoint.value;
      }
      if (pitchPoint != null) {
        _currentPitch = pitchPoint.value;
      }
      _displayAmplitude = windowAmplitude;
      _displayPitch = windowPitch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = _audioBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('节奏实验室'),
        actions: [
          IconButton(
            tooltip: '选择音频',
            onPressed: _isLoading ? null : _pickAudio,
            icon: const Icon(Icons.audio_file),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '把课堂里的儿歌、器乐或自然声音导入，实时查看响度与主频率走势，帮助老师指导孩子唱准唱好。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          GlowUpColors.dusk.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (!hasAudio)
                _EmptyAudioState(onPick: _pickAudio)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_sourceLabel != null && _sourceLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '来源：${_sourceLabel!}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: GlowUpColors.dusk
                                    .withValues(alpha: 0.65),
                              ),
                        ),
                      ),
                    if (_metaInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _metaInfo!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    _PlayerControls(
                      player: _player,
                      duration: _audioDuration,
                    ),
                    const SizedBox(height: 20),
                    _AnalysisMeters(
                      currentDb: _currentDb,
                      currentPitch: _currentPitch,
                      currentTime: _currentTime,
                    ),
                    const SizedBox(height: 20),
                    _ChartSection(
                      amplitude: _displayAmplitude,
                      pitch: _displayPitch,
                      windowSeconds: _chartWindowSeconds,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<_AudioAnalysisResult> _analyzeAudioBytes(Uint8List bytes) async {
    final data = await compute(_analyzeAudioWorker, bytes);
    final amplitude = _pointsFromData(
      (data['amplitudeTimes'] as List<dynamic>? ?? const [])
          .cast<num>(),
      (data['amplitudeValues'] as List<dynamic>? ?? const [])
          .cast<num>(),
    );
    final pitch = _pointsFromData(
      (data['pitchTimes'] as List<dynamic>? ?? const []).cast<num>(),
      (data['pitchValues'] as List<dynamic>? ?? const []).cast<num>(),
    );

    return _AudioAnalysisResult(
      amplitude: amplitude,
      pitch: pitch,
      duration: Duration(milliseconds: data['durationMillis'] as int),
      metaInfo: data['metaInfo'] as String,
      initialDb: (data['initialDb'] as num).toDouble(),
      initialPitch: (data['initialPitch'] as num).toDouble(),
    );
  }

  List<_AnalysisPoint> _pointsFromData(
    List<num> times,
    List<num> values,
  ) {
    final length = min(times.length, values.length);
    final points = <_AnalysisPoint>[];
    for (int i = 0; i < length; i++) {
      points.add(_AnalysisPoint(
        times[i].toDouble(),
        values[i].toDouble(),
      ));
    }
    return points;
  }

  List<_AnalysisPoint> _windowAround(
    List<_AnalysisPoint> points,
    double time,
    double span,
  ) {
    if (points.isEmpty) return const [];
    final half = span / 2;
    final start = max(0, time - half);
    final end = time + half;
    final windowed =
        points.where((p) => p.time >= start && p.time <= end).toList();
    if (windowed.isNotEmpty) {
      if (windowed.length == 1 && points.length > 1) {
        final point = windowed.first;
        final index = points.indexOf(point);
        if (index != -1) {
          final expanded = <_AnalysisPoint>[];
          if (index > 0) expanded.add(points[index - 1]);
          expanded.add(point);
          if (index < points.length - 1) expanded.add(points[index + 1]);
          return expanded;
        }
      }
      return windowed;
    }
    return [_nearestPoint(points, time)];
  }

  _AnalysisPoint _nearestPoint(List<_AnalysisPoint> points, double time) {
    int low = 0;
    int high = points.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (points[mid].time < time) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    final index = low.clamp(0, points.length - 1);
    return points[index];
  }

}

class _PlayerControls extends StatefulWidget {
  const _PlayerControls({
    required this.player,
    required this.duration,
  });

  final AudioPlayer player;
  final Duration? duration;

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  late StreamSubscription<PlayerState> _playerStateSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playerStateSub = widget.player.playerStateStream.listen((state) {
      final playing = state.playing;
      if (playing != _isPlaying) {
        setState(() => _isPlaying = playing);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player)) {
      _playerStateSub.cancel();
      _playerStateSub = widget.player.playerStateStream.listen((state) {
        final playing = state.playing;
        if (playing != _isPlaying) {
          setState(() => _isPlaying = playing);
        }
      });
    }
  }

  @override
  void dispose() {
    _playerStateSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: _isPlaying ? '暂停' : '播放',
              onPressed: duration == null
                  ? null
                  : () async {
                      if (_isPlaying) {
                        await widget.player.pause();
                      } else {
                        await widget.player.play();
                      }
                    },
              icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
              iconSize: 36,
            ),
            if (duration != null)
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: widget.player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final progress = duration.inMilliseconds == 0
                        ? 0.0
                        : (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: progress),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(position, duration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration position, Duration total) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final posMinutes = twoDigits(position.inMinutes.remainder(60));
    final posSeconds = twoDigits(position.inSeconds.remainder(60));
    final totalMinutes = twoDigits(total.inMinutes.remainder(60));
    final totalSeconds = twoDigits(total.inSeconds.remainder(60));
    return '$posMinutes:$posSeconds / $totalMinutes:$totalSeconds';
  }
}

class _AnalysisMeters extends StatelessWidget {
  const _AnalysisMeters({
    required this.currentDb,
    required this.currentPitch,
    required this.currentTime,
  });

  final double currentDb;
  final double currentPitch;
  final double currentTime;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MeterTile(
            title: '当前响度',
            value: '${currentDb.toStringAsFixed(1)} dB',
            icon: Icons.graphic_eq,
          ),
          _MeterTile(
            title: '当前主频率',
            value: '${currentPitch.toStringAsFixed(1)} Hz',
            icon: Icons.multiline_chart,
          ),
          _MeterTile(
            title: '播放进度',
            value: '${currentTime.toStringAsFixed(1)} s',
            icon: Icons.timer_outlined,
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.amplitude,
    required this.pitch,
    required this.windowSeconds,
  });

  final List<_AnalysisPoint> amplitude;
  final List<_AnalysisPoint> pitch;
  final double windowSeconds;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '响度趋势（最近 ${windowSeconds.toStringAsFixed(0)} 秒）',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _AnalysisChart(
          points: amplitude,
          color: GlowUpColors.primary,
          title: '响度 dB',
        ),
        const SizedBox(height: 20),
        Text(
          '主频趋势（最近 ${windowSeconds.toStringAsFixed(0)} 秒）',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _AnalysisChart(
          points: pitch,
          color: GlowUpColors.accent,
          title: '主频 Hz',
        ),
      ],
    );
  }
}

class _MeterTile extends StatelessWidget {
  const _MeterTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: GlowUpColors.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisChart extends StatelessWidget {
  const _AnalysisChart({
    required this.points,
    required this.color,
    required this.title,
  });

  final List<_AnalysisPoint> points;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    final chartPoints = points
        .map(
          (p) => FlSpot(p.time, p.value),
        )
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    if (chartPoints.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: GlowUpColors.mist,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('暂无数据'),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: _suggestInterval(chartPoints.map((e) => e.y)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _suggestInterval(chartPoints.map((e) => e.x)),
              ),
            ),
          ),
          gridData: FlGridData(
            drawVerticalLine: true,
            horizontalInterval: _suggestInterval(chartPoints.map((e) => e.y)),
            verticalInterval: _suggestInterval(chartPoints.map((e) => e.x)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor:
                  GlowUpColors.primary.withValues(alpha: 0.8),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartPoints,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _suggestInterval(Iterable<double> values) {
    final clean = values.where((value) => value.isFinite).toList();
    if (clean.isEmpty) return 1;
    final maxValue = clean.reduce(max);
    final minValue = clean.reduce(min);
    final span = (maxValue - minValue).abs();
    if (span == 0) return maxValue == 0 ? 1 : maxValue.abs() / 2;
    final rough = span / 4;
    if (rough <= 0) return 1;
    final magnitude =
        pow(10, (log(rough) / ln10).floorToDouble()).toDouble();
    final normalized = rough / magnitude;
    double step;
    if (normalized < 1.5) {
      step = 1;
    } else if (normalized < 3) {
      step = 2;
    } else if (normalized < 7) {
      step = 5;
    } else {
      step = 10;
    }
    return step * magnitude;
  }
}

class _EmptyAudioState extends StatelessWidget {
  const _EmptyAudioState({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入课堂里的儿歌、器乐或自然声音',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            '上传 WAV 或 MP3 音频，小光会帮你显示响度与主频率走势，辅助课堂教学。',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.folder_open),
            label: const Text('选择音频文件'),
          ),
        ],
      ),
    );
  }
}

class _AudioAnalysisResult {
  const _AudioAnalysisResult({
    required this.amplitude,
    required this.pitch,
    required this.duration,
    required this.metaInfo,
    required this.initialDb,
    required this.initialPitch,
  });

  final List<_AnalysisPoint> amplitude;
  final List<_AnalysisPoint> pitch;
  final Duration duration;
  final String metaInfo;
  final double initialDb;
  final double initialPitch;
}

class _AnalysisPoint {
  const _AnalysisPoint(this.time, this.value);

  final double time;
  final double value;
}

@pragma('vm:entry-point')
Map<String, dynamic> _analyzeAudioWorker(Uint8List bytes) {
  final parsed = _parseWav(bytes);
  final samples = parsed.samples;
  final sampleRate = parsed.sampleRate;
  if (samples.isEmpty) {
    throw FormatException('未找到有效的音频数据');
  }

  const windowSize = 1024;
  const hopSize = windowSize ~/ 2;
  final fft = FFT(windowSize);
  final window = List<double>.generate(
    windowSize,
    (i) => 0.5 - 0.5 * cos(2 * pi * i / windowSize),
  );

  final amplitudePoints = <_AnalysisPoint>[];
  final pitchPoints = <_AnalysisPoint>[];

  for (int start = 0;
      start + windowSize < samples.length;
      start += hopSize) {
    final windowed = List<double>.generate(
      windowSize,
      (i) => samples[start + i] * window[i],
    );
    double sumSq = 0;
    for (final value in windowed) {
      sumSq += value * value;
    }
    final rms = sqrt(sumSq / windowSize);
    final time = start / sampleRate;
    amplitudePoints.add(_AnalysisPoint(time, _rmsToDb(rms)));

    double freq = 0;
    if (rms > 1e-6) {
      final spectrum = fft.realFft(windowed);
      final mags = spectrum.squareMagnitudes();
      final minIndex = max(1, (50 * windowSize / sampleRate).round());
      final maxIndex = min(
        mags.length - 1,
        (1000 * windowSize / sampleRate).round(),
      );
      if (maxIndex > minIndex) {
        double maxMag = 0;
        int bestIndex = minIndex;
        for (int i = minIndex; i <= maxIndex; i++) {
          if (mags[i] > maxMag) {
            maxMag = mags[i];
            bestIndex = i;
          }
        }
        freq = bestIndex * sampleRate / windowSize;
      }
    }
    pitchPoints.add(_AnalysisPoint(time, freq));
  }

  final initialDb = amplitudePoints.isEmpty
      ? 0.0
      : amplitudePoints.first.value;
  final initialPitch = pitchPoints.isEmpty
      ? 0.0
      : pitchPoints.first.value;

  return {
    'amplitudeTimes': amplitudePoints.map((e) => e.time).toList(),
    'amplitudeValues': amplitudePoints.map((e) => e.value).toList(),
    'pitchTimes': pitchPoints.map((e) => e.time).toList(),
    'pitchValues': pitchPoints.map((e) => e.value).toList(),
    'durationMillis':
        ((samples.length / sampleRate) * 1000).round(),
    'metaInfo':
        '采样率 ${sampleRate.toStringAsFixed(0)} Hz · 时长 ${(samples.length / sampleRate).toStringAsFixed(1)} 秒',
    'initialDb': initialDb,
    'initialPitch': initialPitch,
  };
}

double _rmsToDb(double rms) {
  if (rms <= 0) return -120;
  return 20 * log(rms) / ln10;
}

class _ParsedWav {
  const _ParsedWav({required this.samples, required this.sampleRate});

  final List<double> samples;
  final int sampleRate;
}

_ParsedWav _parseWav(Uint8List bytes) {
  if (bytes.length < 44) {
    throw FormatException('音频格式不受支持，请使用 WAV 文件');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(0, Endian.little) != 0x46464952 ||
      data.getUint32(8, Endian.little) != 0x45564157) {
    throw FormatException('音频格式不受支持，请使用 WAV 文件');
  }
  final format = data.getUint16(20, Endian.little);
  if (format != 1) {
    throw FormatException('仅支持 PCM WAV 格式');
  }
  final channels = data.getUint16(22, Endian.little);
  final sampleRate = data.getUint32(24, Endian.little);
  final bitsPerSample = data.getUint16(34, Endian.little);
  const dataOffset = 44;
  final sampleCount =
      (bytes.length - dataOffset) ~/ (bitsPerSample ~/ 8);

  final samples = List<double>.generate(sampleCount, (i) {
    final offset = dataOffset + i * (bitsPerSample ~/ 8);
    int value;
    switch (bitsPerSample) {
      case 16:
        value = data.getInt16(offset, Endian.little);
        return value / 32768.0;
      case 8:
        value = data.getUint8(offset);
        return (value - 128) / 128.0;
      default:
        throw FormatException('暂不支持 $bitsPerSample 位深的 WAV');
    }
  });

  if (channels > 1) {
    final downmixed = <double>[];
    for (int i = 0; i < samples.length; i += channels) {
      double sum = 0;
      for (int ch = 0; ch < channels; ch++) {
        sum += samples[i + ch];
      }
      downmixed.add(sum / channels);
    }
    return _ParsedWav(samples: downmixed, sampleRate: sampleRate);
  }

  return _ParsedWav(samples: samples, sampleRate: sampleRate);
}
