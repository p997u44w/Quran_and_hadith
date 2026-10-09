import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import '../services/api_service.dart';
import 'feature_screens.dart';
import 'people_directory_screen.dart';

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});

  Future<void> _showSchoolCode(BuildContext context) async {
    final res = await ApiService.get('school/get-info');
    if (!context.mounted) return;
    final code = res['success'] == true ? res['data']['code'] : null;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B2A21),
        title: const Text('کد مرکز', style: TextStyle(color: Colors.white)),
        content: Text(
          code ?? 'خطا در دریافت کد',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('بستن'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل مدیر مرکز',
      subtitle: 'مدیریت کلاس‌ها، قرآن آموزان و استادهای مرکز شما',
      items: [
        DashboardItem(
          title: 'همه افراد و سوابق',
          icon: Icons.manage_accounts_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleDirectoryScreen())),
        ),
        DashboardItem(
          title: 'کلاس‌ها',
          icon: Icons.meeting_room_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassesScreen())),
        ),
        DashboardItem(
          title: 'قرآن آموزان',
          icon: Icons.groups_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleScreen(teachers: false))),
        ),
        DashboardItem(
          title: 'استادها',
          icon: Icons.co_present_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleScreen(teachers: true))),
        ),
        DashboardItem(
          title: 'اطلاعیه‌ها',
          icon: Icons.campaign_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
        ),
        DashboardItem(
          title: 'بایگانی تکالیف و نمره‌ها',
          icon: Icons.inventory_2_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
        ),
        DashboardItem(
          title: 'کد مرکز',
          icon: Icons.qr_code_rounded,
          onTap: () => _showSchoolCode(context),
        ),
      ],
    );
  }
}

