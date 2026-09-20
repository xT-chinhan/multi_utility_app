import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/voice_command.dart';
import '../../services/voice_service.dart';
import '../../theme/app_theme.dart';

class VoiceScreen extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const VoiceScreen({super.key, this.onSwitchTab});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _customCommandController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _quickCommandPresets = [
    'Bắt đầu bấm giờ',
    'Tạm dừng bấm giờ',
    'Ghi vòng (Lap)',
    'Đặt lại bấm giờ',
    'Đặt báo thức lúc 7 giờ 30',
    'Báo thức lúc 6h sáng',
    'Hẹn giờ sau 10 phút',
    'Đặt báo thức lúc 22h15',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    VoiceService.instance.isListeningNotifier.addListener(_onListeningChanged);
  }

  void _onListeningChanged() {
    if (VoiceService.instance.isListeningNotifier.value) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    VoiceService.instance.isListeningNotifier.removeListener(_onListeningChanged);
    _pulseController.dispose();
    _customCommandController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    final voice = VoiceService.instance;
    if (voice.isListeningNotifier.value) {
      await voice.stopListening();
    } else {
      await voice.startListening();
    }
  }

  void _executeCommand(String text) {
    if (text.trim().isEmpty) return;
    _customCommandController.clear();
    FocusScope.of(context).unfocus();

    final result = VoiceService.instance.processVoiceCommand(text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result.responseMessage)),
          ],
        ),
        backgroundColor: result.isSuccess ? AppTheme.voiceColor : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voice = VoiceService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ Lý Giọng Nói AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Microphone Big Button with Acoustic Sound Wave Effect
            Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: voice.isListeningNotifier,
                builder: (context, isListening, child) {
                  return Column(
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final progress = (_pulseAnimation.value - 1.0) / 0.25; // 0.0 to 1.0
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Acoustic sound wave ripple 3 (outermost)
                                if (isListening)
                                  Container(
                                    width: 120 + 75 * progress,
                                    height: 120 + 75 * progress,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.redAccent.withAlpha(((1.0 - progress) * 80).round()),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                // Acoustic sound wave ripple 2 (middle)
                                if (isListening)
                                  Container(
                                    width: 120 + 40 * progress,
                                    height: 120 + 40 * progress,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.redAccent.withAlpha(((1.0 - progress) * 40).round()),
                                      border: Border.all(
                                        color: Colors.redAccent.withAlpha(((1.0 - progress) * 140).round()),
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                // Core mic button with pulse scale and dynamic acoustic glow
                                Transform.scale(
                                  scale: isListening ? (1.0 + 0.08 * progress) : 1.0,
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isListening ? Colors.redAccent : AppTheme.voiceColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isListening ? Colors.redAccent : AppTheme.voiceColor)
                                              .withAlpha(isListening ? (80 + (60 * progress).round()) : 60),
                                          blurRadius: isListening ? 28 : 16,
                                          spreadRadius: isListening ? 6 : 2,
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _toggleListening,
                                        customBorder: const CircleBorder(),
                                        child: Icon(
                                          isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                                          color: Colors.white,
                                          size: 56,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Sound Wave Frequency Equalizer (active when listening)
                      if (isListening) ...[
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            final p = _pulseController.value;
                            final heights = [
                              10.0 + 16.0 * math.sin(p * math.pi * 2).abs(),
                              16.0 + 22.0 * math.sin((p + 0.2) * math.pi * 2).abs(),
                              22.0 + 20.0 * math.sin((p + 0.4) * math.pi * 2).abs(),
                              28.0 + 16.0 * math.sin((p + 0.6) * math.pi * 2).abs(),
                              22.0 + 20.0 * math.sin((p + 0.8) * math.pi * 2).abs(),
                              16.0 + 22.0 * math.sin((p + 0.3) * math.pi * 2).abs(),
                              10.0 + 16.0 * math.sin((p + 0.5) * math.pi * 2).abs(),
                            ];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: heights.map((h) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: 4,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      Text(
                        isListening ? 'ĐANG THU NHẬN SÓNG ÂM GIỌNG NÓI (vi-VN)...' : 'Chạm để nói câu lệnh',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isListening ? Colors.redAccent : AppTheme.voiceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hỗ trợ đặt báo thức, bấm giờ, tạm dừng, reset, ghi vòng',
                        style: TextStyle(fontSize: 12, color: theme.hintColor),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Live recognized words card
            ValueListenableBuilder<String>(
              valueListenable: voice.spokenWordsNotifier,
              builder: (context, words, child) {
                if (words.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.voiceColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.voiceColor.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.graphic_eq_rounded, color: AppTheme.voiceColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '"$words"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Quick Preset Command Chips
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, color: AppTheme.voiceColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Thử Nhanh Câu Lệnh (1-Tap Test)',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickCommandPresets.map((cmd) {
                        return ActionChip(
                          avatar: const Icon(Icons.volume_up_rounded, size: 14),
                          label: Text(cmd),
                          onPressed: () => _executeCommand(cmd),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Manual command input for testing without microphone
                    TextField(
                      controller: _customCommandController,
                      decoration: InputDecoration(
                        hintText: 'Hoặc gõ câu lệnh vào đây để test...',
                        hintStyle: TextStyle(fontSize: 13, color: theme.hintColor),
                        prefixIcon: const Icon(Icons.keyboard_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send_rounded, color: AppTheme.voiceColor),
                          onPressed: () => _executeCommand(_customCommandController.text),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: _executeCommand,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Command History Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Lịch Sử Nhận Diện & Thực Thi',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<List<VoiceCommandResult>>(
                  valueListenable: voice.commandHistoryNotifier,
                  builder: (context, list, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${list.length} lệnh',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.voiceColor),
                        ),
                        if (list.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            tooltip: 'Xóa lịch sử',
                            onPressed: () => voice.clearHistory(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            ValueListenableBuilder<List<VoiceCommandResult>>(
              valueListenable: voice.commandHistoryNotifier,
              builder: (context, history, child) {
                if (history.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'Chưa có câu lệnh nào được thực thi.\nHãy bấm mic hoặc chọn 1 câu lệnh mẫu ở trên!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: item.isSuccess
                              ? AppTheme.voiceColor.withAlpha(60)
                              : Colors.orange.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isSuccess
                                  ? AppTheme.voiceColor.withAlpha(30)
                                  : Colors.orange.withAlpha(30),
                            ),
                            child: Icon(
                              item.isSuccess ? Icons.check_rounded : Icons.priority_high_rounded,
                              color: item.isSuccess ? AppTheme.voiceColor : Colors.orange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '"${item.rawSpokenText}"',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.responseMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: item.isSuccess ? AppTheme.voiceColor : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (item.type == VoiceCommandType.setAlarm)
                            TextButton(
                              onPressed: () => widget.onSwitchTab?.call(2), // Switch to Alarm tab
                              child: const Text('Xem Báo Thức', style: TextStyle(fontSize: 11)),
                            )
                          else if (item.type == VoiceCommandType.startStopwatch ||
                              item.type == VoiceCommandType.stopStopwatch ||
                              item.type == VoiceCommandType.lapStopwatch)
                            TextButton(
                              onPressed: () => widget.onSwitchTab?.call(3), // Switch to Stopwatch tab
                              child: const Text('Xem Bấm Giờ', style: TextStyle(fontSize: 11)),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
