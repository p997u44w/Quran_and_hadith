import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminSchoolManagementScreen extends StatefulWidget {
  final Map school;
  const AdminSchoolManagementScreen({super.key, required this.school});

  @override
  State<AdminSchoolManagementScreen> createState() => _AdminSchoolManagementScreenState();
}

class _AdminSchoolManagementScreenState extends State<AdminSchoolManagementScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.get('hub/admin-school-overview?school_id=${widget.school['id']}', auth: true);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _data = Map<String, dynamic>.from(res['data'] ?? {});
      } else {
        _error = res['message']?.toString() ?? 'دریافت اطلاعات مرکز ناموفق بود';
      }
    });
  }

  Widget _stat(String title, dynamic value, IconData icon) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Icon(icon, size: 24),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      ),
    ),
  );

  Widget _section(String title, IconData icon, List<dynamic> items, Widget Function(Map) builder) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text('$title (${items.length})'),
        children: items.isEmpty
            ? [const Padding(padding: EdgeInsets.all(16), child: Text('موردی ثبت نشده'))]
            : items.map((e) => builder(Map<String, dynamic>.from(e))).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final school = Map<String, dynamic>.from(_data['school'] ?? widget.school);
    final classes = List<dynamic>.from(_data['classes'] ?? []);
    final teachers = List<dynamic>.from(_data['teachers'] ?? []);
    final students = List<dynamic>.from(_data['students'] ?? []);
    final exams = List<dynamic>.from(_data['exams'] ?? []);
    final assignments = List<dynamic>.from(_data['assignments'] ?? []);
    final announcements = List<dynamic>.from(_data['announcements'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: Text('مدیریت ${school['name'] ?? 'مرکز'}'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      Card(child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.school_rounded)),
                        title: Text(school['name']?.toString() ?? '-'),
                        subtitle: Text('کد: ${school['code'] ?? '-'}  •  شهر: ${school['city'] ?? '-'}'),
                        trailing: Text(school['status']?.toString() ?? '-'),
                      )),
                      const SizedBox(height: 8),
                      Row(children: [
                        _stat('کلاس', classes.length, Icons.class_rounded),
                        const SizedBox(width: 8),
                        _stat('معلم', teachers.length, Icons.person_rounded),
                        const SizedBox(width: 8),
                        _stat('قرآن آموز', students.length, Icons.groups_rounded),
                      ]),
                      const SizedBox(height: 8),
                      _section('امتحانات', Icons.assignment_rounded, exams, (e) => ListTile(
                        title: Text(e['title']?.toString() ?? '-'),
                        subtitle: Text('${e['class_name'] ?? '-'} • ${e['teacher_name'] ?? '-'}\nسوال: ${e['question_count'] ?? 0} • شرکت‌کننده: ${e['submission_count'] ?? 0}\n${e['created_at'] ?? ''}'),
                        isThreeLine: true,
                      )),
                      _section('تکالیف', Icons.menu_book_rounded, assignments, (a) => ListTile(
                        title: Text(a['title']?.toString() ?? '-'),
                        subtitle: Text('${a['class_name'] ?? '-'} • ${a['teacher_name'] ?? '-'}\nکد: ${a['assignment_code'] ?? '-'} • ارسال: ${a['submission_count'] ?? 0}\nموعد: ${a['due_date'] ?? '-'}'),
                        isThreeLine: true,
                      )),
                      _section('استادها', Icons.school_outlined, teachers, (t) => ListTile(
                        title: Text(t['full_name']?.toString() ?? '-'),
                        subtitle: Text('نام کاربری: ${t['username'] ?? '-'}\nکلاس‌ها: ${t['classes'] ?? '-'}\nموبایل: ${t['phone'] ?? '-'}'),
                        isThreeLine: true,
                      )),
                      _section('قرآن آموزها', Icons.groups_outlined, students, (s) => ListTile(
                        title: Text(s['full_name']?.toString() ?? '-'),
                        subtitle: Text('کلاس: ${s['class_name'] ?? '-'}\nنام کاربری: ${s['username'] ?? '-'} • موبایل: ${s['phone'] ?? '-'}\nکد ملی: ${s['national_code'] ?? '-'}'),
                        isThreeLine: true,
                      )),
                      _section('اطلاعیه‌ها', Icons.campaign_outlined, announcements, (a) => ListTile(
                        title: Text(a['title']?.toString() ?? '-'),
                        subtitle: Text('${a['class_name'] ?? 'همه کلاس‌ها'} • ${a['created_at'] ?? ''}\n${a['content'] ?? ''}'),
                        isThreeLine: true,
                      )),
                    ],
                  ),
                ),
    );
  }
}
