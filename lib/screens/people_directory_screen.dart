import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PeopleDirectoryScreen extends StatefulWidget {
  const PeopleDirectoryScreen({super.key});

  @override
  State<PeopleDirectoryScreen> createState() => _PeopleDirectoryScreenState();
}

class _PeopleDirectoryScreenState extends State<PeopleDirectoryScreen> {
  List<Map<String, dynamic>> schools = [];
  List<Map<String, dynamic>> adminSchools = [];

  int? selectedSchoolId;
  bool loading = true;
  bool isAdmin = false;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final user = await ApiService.currentUser;
      final admin = user?['role'] == 'admin';

      if (admin && adminSchools.isEmpty) {
        final sr = await ApiService.get('admin/list-schools');

        if (sr['success'] == true && sr['data'] is List) {
          adminSchools = (sr['data'] as List)
              .whereType<Map>()
              .map((x) => Map<String, dynamic>.from(x))
              .toList();

          selectedSchoolId ??= adminSchools.isNotEmpty
              ? int.tryParse('${adminSchools.first['id']}')
              : null;
        }
      }

      // مدیر/استاد یار: مرکز خودشان
      // ادمین: مرکز انتخاب‌شده از لیست مدارس
      if (admin && selectedSchoolId == null) {
        if (!mounted) return;
        setState(() {
          isAdmin = true;
          schools = [];
          loading = false;
          error = adminSchools.isEmpty ? 'مرکزای برای نمایش وجود ندارد' : null;
        });
        return;
      }

      final path = admin
          ? 'hub/school-people?school_id=$selectedSchoolId'
          : 'school/people';

      final r = await ApiService.get(path);

      if (!mounted) return;

      if (r['success'] == true) {
        final rawSchools = r['data']?['schools'];

        final normalized = rawSchools is List
            ? rawSchools
                .whereType<Map>()
                .map((x) => Map<String, dynamic>.from(x))
                .toList()
            : <Map<String, dynamic>>[];

        setState(() {
          isAdmin = admin;
          schools = normalized;
          loading = false;
          error = null;
        });
      } else {
        setState(() {
          isAdmin = admin;
          loading = false;
          error = r['message'] ?? 'خطا در دریافت اطلاعات';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'ارتباط با سرور برقرار نشد';
      });
    }
  }

  void _changeSchool(int? value) {
    if (value == null || value == selectedSchoolId) return;

    setState(() {
      selectedSchoolId = value;
      loading = true;
      error = null;
    });

    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('افراد و سوابق مرکز'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(14),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (isAdmin && adminSchools.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: selectedSchoolId,
                      decoration: const InputDecoration(
                        labelText: 'انتخاب مرکز',
                        prefixIcon: Icon(Icons.school_rounded),
                      ),
                      items: adminSchools
                          .map<DropdownMenuItem<int>>(
                            (school) => DropdownMenuItem<int>(
                              value: int.tryParse('${school['id']}'),
                              child: Text(
                                '${school['name'] ?? 'مرکز'}',
                              ),
                            ),
                          )
                          .where((item) => item.value != null)
                          .toList(),
                      onChanged: _changeSchool,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._buildDirectory(),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildDirectory() {
    if (schools.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'اطلاعاتی برای نمایش وجود ندارد',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    final result = <Widget>[];

    for (final block in schools) {
      final school = block['school'] is Map
          ? Map<String, dynamic>.from(block['school'] as Map)
          : <String, dynamic>{};

      final teachers = block['teachers'] is List
          ? block['teachers'] as List
          : const [];

      final students = block['students'] is List
          ? block['students'] as List
          : const [];

      result.add(
        Card(
          child: ListTile(
            leading: const Icon(Icons.school_rounded),
            title: Text('${school['name'] ?? 'مرکز'}'),
            subtitle: Text(
              'استاد: ${teachers.length}  •  قرآن آموز: ${students.length}',
            ),
          ),
        ),
      );

      result.add(const SizedBox(height: 8));

      result.add(
        const Text(
          'استادها',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      for (final rawTeacher in teachers) {
        if (rawTeacher is! Map) continue;

        final teacher = Map<String, dynamic>.from(rawTeacher);
        final rawClasses = teacher['classes'] is List
            ? teacher['classes'] as List
            : const [];

        final classes = rawClasses
            .whereType<Map>()
            .map((c) => '${c['name'] ?? ''}')
            .where((name) => name.isNotEmpty)
            .join('، ');

        result.add(
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person),
              ),
              title: Text('${teacher['full_name'] ?? ''}'),
              subtitle: Text(
                'کد ملی: ${teacher['national_code'] ?? '-'}\n'
                'تلفن: ${teacher['phone'] ?? '-'}\n'
                'کلاس‌ها: ${classes.isEmpty ? '-' : classes}',
              ),
              isThreeLine: true,
            ),
          ),
        );
      }

      result.add(const SizedBox(height: 8));

      result.add(
        const Text(
          'قرآن آموزان و سوابق',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      for (final rawStudent in students) {
        if (rawStudent is! Map) continue;

        final student = Map<String, dynamic>.from(rawStudent);

        final assignmentHistory = student['assignment_history'] is List
            ? student['assignment_history'] as List
            : const [];

        final examHistory = student['exam_history'] is List
            ? student['exam_history'] as List
            : const [];

        result.add(
          Card(
            child: ExpansionTile(
              leading: const CircleAvatar(
                child: Icon(Icons.school),
              ),
              title: Text('${student['full_name'] ?? ''}'),
              subtitle: Text(
                'کلاس: ${student['class_name'] ?? '-'}  •  '
                'کد ملی: ${student['national_code'] ?? '-'}',
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('تلفن: ${student['phone'] ?? '-'}'),
                      Text(
                        'میانگین تکالیف: '
                        '${student['assignments_average'] ?? '-'}',
                      ),
                      Text(
                        'امتیاز: ${student['points_total'] ?? 0}',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تاریخچه تکالیف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...assignmentHistory
                          .whereType<Map>()
                          .map(
                            (rawAssignment) => ListTile(
                              dense: true,
                              title: Text(
                                '${rawAssignment['title'] ?? ''}',
                              ),
                              subtitle: Text(
                                'ثبت: '
                                '${rawAssignment['submitted_at'] ?? 'ارسال نشده'}'
                                ' • نمره: '
                                '${rawAssignment['score'] ?? '-'} / '
                                '${rawAssignment['max_score'] ?? '-'}'
                                '${rawAssignment['is_late'] == 1 ? ' • دیرکرد' : ''}',
                              ),
                            ),
                          ),
                      const Divider(),
                      const Text(
                        'تاریخچه امتحان‌ها',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...examHistory
                          .whereType<Map>()
                          .map(
                            (rawExam) => ListTile(
                              dense: true,
                              title: Text(
                                '${rawExam['title'] ?? ''}',
                              ),
                              subtitle: Text(
                                'نمره: ${rawExam['score'] ?? '-'} • '
                                '${rawExam['submitted_at'] ?? 'شرکت نکرده'}',
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return result;
  }
}
