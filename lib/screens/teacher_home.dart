import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import 'feature_screens.dart';

class TeacherHome extends StatelessWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل استاد',
      subtitle: 'کلاس‌های شما، از پایه پایین به بالا',
      items: [
        DashboardItem(
          title: 'کلاس‌های من',
          icon: Icons.class_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherClassesScreen())),
        ),
        DashboardItem(
          title: 'تکلیف چندرسانه‌ای جدید',
          icon: Icons.assignment_add,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAssignmentScreen())),
        ),
        DashboardItem(
          title: 'بایگانی تکالیف و نمره‌ها',
          icon: Icons.inventory_2_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
        ),
        DashboardItem(
          title: 'پیام‌ها',
          icon: Icons.chat_bubble_outline_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagesScreen())),
        ),
      ],
    );
  }
}
