import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/voice_command.dart';
import 'alarm_manager.dart';
import 'stopwatch_service.dart';
import 'audio_alarm_service.dart';

class VoiceService {
  static final VoiceService instance = VoiceService._internal();
  VoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> spokenWordsNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> soundLevelNotifier = ValueNotifier<double>(0.0);
  final ValueNotifier<List<VoiceCommandResult>> commandHistoryNotifier =
      ValueNotifier<List<VoiceCommandResult>>([]);

  void clearHistory() {
    commandHistoryNotifier.value = [];
  }

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('Speech error: $val');
          isListeningNotifier.value = false;
          soundLevelNotifier.value = 0.0;
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            isListeningNotifier.value = false;
            soundLevelNotifier.value = 0.0;
          }
        },
      );
    } catch (e) {
      debugPrint('Speech initialize exception: $e');
      _isInitialized = false;
    }
    return _isInitialized;
  }

  Future<void> startListening({Function(String)? onLiveResult}) async {
    final available = await initSpeech();
    if (!available) {
      // If mic is not available, we still allow speech simulation
      debugPrint('Speech recognition not available on this platform/device');
      return;
    }

    spokenWordsNotifier.value = '';
    isListeningNotifier.value = true;
    AudioAlarmService.instance.playBeep();

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'vi_VN',
        partialResults: true,
        listenMode: stt.ListenMode.confirmation,
      ),
      onSoundLevelChange: (level) {
        soundLevelNotifier.value = level;
      },
      onResult: (val) {
        spokenWordsNotifier.value = val.recognizedWords;
        onLiveResult?.call(val.recognizedWords);
        if (val.finalResult) {
          isListeningNotifier.value = false;
          soundLevelNotifier.value = 0.0;
          processVoiceCommand(val.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    isListeningNotifier.value = false;
    soundLevelNotifier.value = 0.0;
  }

  /// Processes text into intent and dispatches execution
  VoiceCommandResult processVoiceCommand(String rawText) {
    final text = rawText.trim().toLowerCase();
    VoiceCommandResult result;

    // 1. Stopwatch commands
    if (_containsAny(text, ['bắt đầu bấm giờ', 'chạy bấm giờ', 'bật bấm giờ', 'start stopwatch', 'start'])) {
      StopwatchService.instance.start();
      result = VoiceCommandResult(
        type: VoiceCommandType.startStopwatch,
        rawSpokenText: rawText,
        responseMessage: 'Đã bắt đầu đồng hồ bấm giờ!',
        isSuccess: true,
      );
    } else if (_containsAny(text, ['dừng bấm giờ', 'tạm dừng', 'ngừng bấm giờ', 'pause stopwatch', 'stop stopwatch', 'stop'])) {
      StopwatchService.instance.pause();
      result = VoiceCommandResult(
        type: VoiceCommandType.stopStopwatch,
        rawSpokenText: rawText,
        responseMessage: 'Đã tạm dừng đồng hồ bấm giờ!',
        isSuccess: true,
      );
    } else if (_containsAny(text, ['đặt lại bấm giờ', 'reset bấm giờ', 'xóa bấm giờ', 'reset stopwatch', 'reset'])) {
      StopwatchService.instance.reset();
      result = VoiceCommandResult(
        type: VoiceCommandType.resetStopwatch,
        rawSpokenText: rawText,
        responseMessage: 'Đã đặt lại đồng hồ bấm giờ về 00:00:00!',
        isSuccess: true,
      );
    } else if (_containsAny(text, ['ghi vòng', 'bấm vòng', 'vòng mới', 'lap', 'split'])) {
      StopwatchService.instance.recordLap();
      result = VoiceCommandResult(
        type: VoiceCommandType.lapStopwatch,
        rawSpokenText: rawText,
        responseMessage: 'Đã ghi lại 1 vòng bấm giờ (Lap)!',
        isSuccess: true,
      );
    }
    // 2. Relative alarm (sau X phút)
    else if (text.contains('phút nữa') || text.contains('sau') && text.contains('phút')) {
      final minuteMatch = RegExp(r'(\d+)\s*phút').firstMatch(text);
      if (minuteMatch != null) {
        final addMin = int.tryParse(minuteMatch.group(1) ?? '5') ?? 5;
        final target = DateTime.now().add(Duration(minutes: addMin));
        final tod = TimeOfDay(hour: target.hour, minute: target.minute);

        AlarmManager.instance.addAlarm(
          time: tod,
          label: 'Hẹn giờ sau $addMin phút (Voice)',
        );

        result = VoiceCommandResult(
          type: VoiceCommandType.setAlarm,
          rawSpokenText: rawText,
          responseMessage: 'Đã đặt báo thức sau $addMin phút (lúc ${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')})!',
          isSuccess: true,
          alarmTime: tod,
        );
      } else {
        result = _fallbackResult(rawText);
      }
    }
    // 3. Absolute alarm (đặt báo thức lúc X giờ Y phút)
    else if (_containsAny(text, ['báo thức', 'đặt giờ', 'hẹn giờ', 'alarm', 'wake up'])) {
      final parsedTime = _parseTimeFromText(text);
      if (parsedTime != null) {
        AlarmManager.instance.addAlarm(
          time: parsedTime,
          label: 'Báo thức giọng nói (${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')})',
        );

        result = VoiceCommandResult(
          type: VoiceCommandType.setAlarm,
          rawSpokenText: rawText,
          responseMessage: 'Đã đặt báo thức thành công lúc ${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')}!',
          isSuccess: true,
          alarmTime: parsedTime,
        );
      } else {
        result = VoiceCommandResult(
          type: VoiceCommandType.unknown,
          rawSpokenText: rawText,
          responseMessage: 'Chưa nhận diện được thời gian. Vui lòng nói ví dụ: "Đặt báo thức lúc 7 giờ 30" hoặc "Báo thức 6h sáng".',
          isSuccess: false,
        );
      }
    } else {
      result = _fallbackResult(rawText);
    }

    // Save history
    commandHistoryNotifier.value = [result, ...commandHistoryNotifier.value];
    AudioAlarmService.instance.playBeep();
    return result;
  }

  TimeOfDay? _parseTimeFromText(String text) {
    // Check patterns:
    // 1. "7h30", "7:30", "07:30"
    final regexColon = RegExp(r'(\d{1,2})[:hH](\d{1,2})?');
    final matchColon = regexColon.firstMatch(text);

    int? hour;
    int minute = 0;

    if (matchColon != null) {
      hour = int.tryParse(matchColon.group(1) ?? '');
      if (matchColon.group(2) != null && matchColon.group(2)!.isNotEmpty) {
        minute = int.tryParse(matchColon.group(2)!) ?? 0;
      }
    } else {
      // 2. "7 giờ 30", "8 giờ"
      final regexWord = RegExp(r'(\d{1,2})\s*(?:giờ|tiếng)\s*(\d{1,2})?');
      final matchWord = regexWord.firstMatch(text);
      if (matchWord != null) {
        hour = int.tryParse(matchWord.group(1) ?? '');
        if (matchWord.group(2) != null) {
          minute = int.tryParse(matchWord.group(2)!) ?? 0;
        }
      }
    }

    if (hour == null || hour < 0 || hour > 24) return null;
    if (minute < 0 || minute >= 60) minute = 0;

    // AM/PM adjustments
    final isPM = text.contains('chiều') || text.contains('tối') || text.contains('đêm') || text.contains('pm');
    final isAM = text.contains('sáng') || text.contains('am');

    if (isPM && hour < 12) {
      hour += 12;
    } else if (isAM && hour == 12) {
      hour = 0;
    }

    if (hour >= 24) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  bool _containsAny(String source, List<String> keywords) {
    for (final k in keywords) {
      if (source.contains(k)) return true;
    }
    return false;
  }

  VoiceCommandResult _fallbackResult(String raw) {
    return VoiceCommandResult(
      type: VoiceCommandType.unknown,
      rawSpokenText: raw,
      responseMessage: 'Chưa hiểu lệnh. Thử nói: "Bắt đầu bấm giờ", "Ghi vòng", hoặc "Đặt báo thức lúc 7 giờ 30".',
      isSuccess: false,
    );
  }
}
