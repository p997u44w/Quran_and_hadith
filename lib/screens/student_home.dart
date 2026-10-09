import 'package:flutter/material.dart';
import '../widgets/dashboard_scaffold.dart';
import '../services/api_service.dart';
import 'feature_screens.dart';

class StudentHome extends StatelessWidget {
  const StudentHome({super.key});


  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'پنل قرآن آموز',
      subtitle: 'تکالیف کلاس شما و پیام‌های استادها',
      items: [
        DashboardItem(
          title: 'ارسال تکالیف',
          icon: Icons.menu_book_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignmentScreen())),
        ),
        DashboardItem(
          title: 'اطلاعیه‌ها',
          icon: Icons.campaign_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen(student: true))),
        ),
        DashboardItem(
          title: 'استادهای من',
          icon: Icons.co_present_rounded,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MyTeachersScreen())),
        ),
      ],
    );
  }
}
