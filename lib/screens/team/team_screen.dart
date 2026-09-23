import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/team_member.dart';
import '../../theme/app_theme.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  final List<TeamMember> _members = const [
    TeamMember(
      name: 'Nguyễn Văn An',
      studentId: '2180600001',
      role: 'Nhóm Trưởng & AI Engineer',
      department: 'Khoa Công Nghệ Thông Tin - HUTECH',
      email: 'an.nv21@hutech.edu.vn',
      phone: '0901234567',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
      contributions: [
        'Điều phối dự án & Thiết kế kiến trúc Swarm',
        'Module 4 & 5: Tích hợp Google ML Kit (Text, Voice, OCR, Realtime)',
        'Cấu hình AndroidManifest & Quyền hệ thống',
      ],
    ),
    TeamMember(
      name: 'Trần Thị Bình',
      studentId: '2180600002',
      role: 'Mobile Developer (Voice & Alarm)',
      department: 'Khoa Công Nghệ Thông Tin - HUTECH',
      email: 'binh.tt21@hutech.edu.vn',
      phone: '0902345678',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      contributions: [
        'Module 3: Báo thức bằng giọng nói đa ngôn ngữ (Việt - Anh)',
        'Tích hợp Android Intent gọi Đồng hồ thật của hệ thống',
        'Bộ lọc nhận diện âm thanh & Giảm rung màn hình mic',
      ],
    ),
    TeamMember(
      name: 'Lê Hoàng Cường',
      studentId: '2180600003',
      role: 'UI/UX & Integration Developer',
      department: 'Khoa Công Nghệ Thông Tin - HUTECH',
      email: 'cuong.lh21@hutech.edu.vn',
      phone: '0903456789',
      avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400',
      contributions: [
        'Module 1: Chuyển đổi giao diện BottomNavigationBar',
        'Module 2: Màn hình Cá Nhân (Gọi điện SĐT cài đặt & Gọi app YouTube)',
        'Module 6: Tab thông tin nhóm & Hiệu ứng lướt Card 3D',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Nhóm Thực Hiện'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Header Instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.pink.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink.withAlpha(60)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swipe_rounded, color: Colors.pink, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Lướt qua trái / phải để xem từng thành viên',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Swipeable PageView Cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _members.length,
              onPageChanged: (idx) {
                setState(() => _currentPage = idx);
              },
              itemBuilder: (context, index) {
                final m = _members[index];
                return AnimatedScale(
                  scale: _currentPage == index ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Member Avatar with decorative ring
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.pink.shade400, AppTheme.primaryBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(m.avatarUrl),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Name
                          Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Student ID Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'MSSV: ${m.studentId}',
                              style: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Role & Department
                          Text(
                            m.role,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.deepPurple,
                            ),
                          ),
                          Text(
                            m.department,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Contributions List
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nhiệm vụ & Đóng góp:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: m.contributions.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 6),
                              itemBuilder: (ctx, i) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        m.contributions[i],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // Quick Call Button
                          ElevatedButton.icon(
                            onPressed: () => _makeCall(m.phone),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              minimumSize: const Size.fromHeight(42),
                            ),
                            icon: const Icon(Icons.phone_rounded, size: 18),
                            label: Text('Liên hệ: ${m.phone}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Page Indicator Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_members.length, (idx) {
              final isSel = _currentPage == idx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSel ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSel ? AppTheme.primaryBlue : Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
