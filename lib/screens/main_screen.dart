import 'package:flutter/material.dart';
import '../services/alarm_manager.dart';
import '../theme/app_theme.dart';
import 'converter/converter_screen.dart';
import 'youtube/youtube_screen.dart';
import 'alarm/alarm_screen.dart';
import 'alarm/widgets/alarm_ring_dialog.dart';
import 'stopwatch/stopwatch_screen.dart';
import 'voice/voice_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isShowingAlarmDialog = false;

  @override
  void initState() {
    super.initState();
    AlarmManager.instance.ringingAlarmNotifier.addListener(_onAlarmRinging);
  }

  @override
  void dispose() {
    AlarmManager.instance.ringingAlarmNotifier.removeListener(_onAlarmRinging);
    super.dispose();
  }

  void _onAlarmRinging() {
    final ringing = AlarmManager.instance.ringingAlarmNotifier.value;
    if (ringing != null && !_isShowingAlarmDialog && mounted) {
      _isShowingAlarmDialog = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlarmRingDialog(alarm: ringing),
      ).then((_) {
        _isShowingAlarmDialog = false;
      });
    }
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showArchitectureDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.hub_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Mô Hình 8 Agent Swarm'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔹 4 Agent Phân Tích (Analysis Swarm):',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
              SizedBox(height: 4),
              Text('1. Agent Requirements & Domain Analyst: Đặc tả 5 chức năng, logic thông báo nhiệt độ.'),
              Text('2. Agent UI/UX Architect: Thiết kế giao diện Material 3, bảng màu 5 tab và motion.'),
              Text('3. Agent Media & Audio Architect: YouTube player lifecycle & PCM audio alert tone.'),
              Text('4. Agent State & NLP Architect: Luồng reactive singleton & parser regex tiếng Việt.'),
              SizedBox(height: 12),
              Text(
                '🔹 4 Agent Thực Thi (Execution Swarm):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
              SizedBox(height: 4),
              Text('5. Agent Scaffold & Navigation: Cấu hình project, theme, model và router.'),
              Text('6. Agent Converter & YouTube: Triển khai Module 1 (Đơn vị) & Module 2 (YouTube).'),
              Text('7. Agent Alarm & Stopwatch: Triển khai Module 3 (Báo thức) & Module 4 (Bấm giờ).'),
              Text('8. Agent Voice & QA Integrator: Triển khai Module 5 (Voice AI) & Kiểm thử.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const ConverterScreen(),
      const YoutubeScreen(),
      const AlarmScreen(),
      const StopwatchScreen(),
      VoiceScreen(onSwitchTab: _switchTab),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getTabColor(_currentIndex).withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getTabIcon(_currentIndex),
                color: _getTabColor(_currentIndex),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _getTabTitle(_currentIndex),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            tooltip: 'Kiến trúc 8 Agent Swarm',
            onPressed: _showArchitectureDialog,
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            tooltip: widget.isDarkMode ? 'Chuyển Chế độ Sáng' : 'Chuyển Chế độ Tối',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // IndexedStack preserves state of video, timer, and inputs across tabs!
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            selectedIcon: Icon(Icons.swap_horiz_rounded, color: AppTheme.converterColor),
            label: 'Đổi Đơn Vị',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_display_outlined),
            selectedIcon: Icon(Icons.smart_display_rounded, color: AppTheme.youtubeColor),
            label: 'YouTube',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_rounded),
            selectedIcon: Icon(Icons.alarm_on_rounded, color: AppTheme.alarmColor),
            label: 'Báo Thức',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded, color: AppTheme.stopwatchColor),
            label: 'Bấm Giờ',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_rounded),
            selectedIcon: Icon(Icons.mic_rounded, color: AppTheme.voiceColor),
            label: 'Voice AI',
          ),
        ],
      ),
    );
  }

  IconData _getTabIcon(int idx) {
    switch (idx) {
      case 0: return Icons.swap_horiz_rounded;
      case 1: return Icons.smart_display_rounded;
      case 2: return Icons.alarm_rounded;
      case 3: return Icons.timer_rounded;
      case 4: return Icons.mic_rounded;
      default: return Icons.dashboard_rounded;
    }
  }

  Color _getTabColor(int idx) {
    switch (idx) {
      case 0: return AppTheme.converterColor;
      case 1: return AppTheme.youtubeColor;
      case 2: return AppTheme.alarmColor;
      case 3: return AppTheme.stopwatchColor;
      case 4: return AppTheme.voiceColor;
      default: return AppTheme.primaryBlue;
    }
  }

  String _getTabTitle(int idx) {
    switch (idx) {
      case 0: return 'Quy Đổi Đơn Vị';
      case 1: return 'YouTube Player';
      case 2: return 'Đồng Hồ Báo Thức';
      case 3: return 'Đồng Hồ Bấm Giờ';
      case 4: return 'Trợ Lý Giọng Nói';
      default: return 'Smart Utility Hub';
    }
  }
}
