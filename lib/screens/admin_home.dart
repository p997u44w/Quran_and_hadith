import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import 'pending_schools_screen.dart';
import 'school_list_screen.dart';
import 'people_directory_screen.dart';
import 'admin_school_management_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل ادمین کل',
      subtitle: 'مدیریت مراکز و تنظیمات کلی سیستم',
      items: [
        DashboardItem(
          title: 'افراد و سوابق مدارس',
          icon: Icons.manage_accounts_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleDirectoryScreen())),
        ),
        DashboardItem(
          title: 'مدیریت مدارس',
          icon: Icons.admin_panel_settings_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolListScreen())),
        ),
        DashboardItem(
          title: 'درخواست‌های مرکز',
          icon: Icons.pending_actions_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingSchoolsScreen())),
        ),
        DashboardItem(
          title: 'لیست مراکز',
          icon: Icons.school_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolListScreen())),
        ),
        DashboardItem(
          title: 'تم هر مرکز',
          icon: Icons.palette_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolListScreen())),
        ),
        DashboardItem(
          title: 'محدودیت پیام آزاد',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolListScreen())),
        ),
      ],
    );
  }
}
