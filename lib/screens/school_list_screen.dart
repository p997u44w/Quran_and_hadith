import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'feature_screens.dart';
import 'admin_school_management_screen.dart';

class SchoolListScreen extends StatefulWidget {
  const SchoolListScreen({super.key});
  @override
  State<SchoolListScreen> createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  List<dynamic> _schools = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final res = await ApiService.get('admin/list-schools');
    if (!mounted) return;
    setState(() { _schools = res['success'] == true ? res['data'] : []; _loading = false; });
  }

  Future<void> _action(String action, Map school) async {
    final name = school['name']?.toString() ?? 'این مرکز';
    final isDelete = action == 'delete';
    final isSuspend = action == 'suspend';
    final title = isDelete ? 'حذف مرکز' : isSuspend ? 'تعلیق مرکز' : 'فعال‌سازی مرکز';
    final message = isDelete
        ? 'مرکز «$name» و اطلاعات آن برای همیشه حذف می‌شود. این کار قابل برگشت نیست.'
        : isSuspend
            ? 'مرکز «$name» تعلیق می‌شود. اطلاعات باقی می‌ماند و ادمین همچنان می‌تواند آن را مشاهده کند، اما کاربران مرکز نمی‌توانند فعالیت کنند.'
            : 'مرکز «$name» دوباره فعال شود؟';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isDelete ? 'حذف نهایی' : 'تأیید')),
      ],
    ));
    if (ok != true) return;
    final res = await ApiService.post('admin/$action-school', {'school_id': school['id']}, auth: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? (res['success'] == true ? 'انجام شد' : 'عملیات ناموفق بود'))));
    if (res['success'] == true) _load();
  }

  Color _parseColor(String value, Color fallback) {
    final h = value.replaceAll('#', '');
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(h)) return Color(int.parse('FF$h', radix: 16));
    return fallback;
  }

  Future<void> _openThemeDialog(Map school) async {
    final primaryCtrl = TextEditingController(text: school['theme_primary_color']?.toString() ?? '#2F5FFF');
    final secondaryCtrl = TextEditingController(text: school['theme_secondary_color']?.toString() ?? '#FFB020');
    String? pickedLogoPath;
    await showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      backgroundColor: const Color(0xFF0B2A21),
      title: Text('تم «${school['name']}»', style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('این رنگ‌ها و لوگو در تمام صفحات اپ مرکز اعمال می‌شوند.', style: TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 12),
        TextField(controller: primaryCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رنگ اصلی مثل #2F5FFF', labelStyle: TextStyle(color: Colors.white54))),
        const SizedBox(height: 10),
        TextField(controller: secondaryCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رنگ دوم مثل #FFB020', labelStyle: TextStyle(color: Colors.white54))),
        const SizedBox(height: 12),
        Container(height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: LinearGradient(colors: [_parseColor(primaryCtrl.text, const Color(0xFF0A5B4D)), _parseColor(secondaryCtrl.text, const Color(0xFFD8A12A))]))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () async { final img = await ImagePicker().pickImage(source: ImageSource.gallery); if (img != null) setState(() => pickedLogoPath = img.path); }, icon: const Icon(Icons.image_outlined), label: Text(pickedLogoPath == null ? 'انتخاب لوگو / آیکون مرکز' : 'تصویر انتخاب شد ✓')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
        FilledButton(onPressed: () async {
          final ok1 = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(primaryCtrl.text.trim());
          final ok2 = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(secondaryCtrl.text.trim());
          if (!ok1 || !ok2) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('کد رنگ باید مثل #2F5FFF باشد'))); return; }
          final res = await ApiService.uploadMultipart('admin/set-school-theme', {
            'school_id': school['id'].toString(),
            'primary_color': primaryCtrl.text.trim(),
            'secondary_color': secondaryCtrl.text.trim(),
          }, filePath: pickedLogoPath, fileField: 'logo');
          if (ctx.mounted) Navigator.pop(ctx);
          if (res['success'] == true) _load();
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']?.toString() ?? (res['success'] == true ? 'تم ذخیره شد' : 'خطا'))));
        }, child: const Text('ذخیره تم')),
      ],
    )));
  }

  Future<void> _openBrandingDialog(Map school) async {
    final nameCtrl = TextEditingController(text: school['app_name'] ?? school['name']);
    String? pickedIconPath;
    await showDialog(context: context, builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
      backgroundColor: const Color(0xFF0B2A21),
      title: Text('برندینگ «${school['name']}»', style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('این تنظیمات برای build اختصاصی مرکز استفاده می‌شوند.', style: TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 14),
        TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم اپ', labelStyle: TextStyle(color: Colors.white54))),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: () async { final img = await ImagePicker().pickImage(source: ImageSource.gallery); if (img != null) setDialogState(() => pickedIconPath = img.path); }, icon: const Icon(Icons.image_outlined), label: Text(pickedIconPath == null ? 'انتخاب آیکون' : 'آیکون انتخاب شد ✓')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
        TextButton(onPressed: () async { final res = await ApiService.uploadMultipart('admin/set-school-branding', {'school_id': school['id'].toString(), 'app_name': nameCtrl.text.trim()}, filePath: pickedIconPath, fileField: 'icon'); if (context.mounted) Navigator.pop(context); if (res['success'] == true) _load(); }, child: const Text('ذخیره')),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مدیریت مدارس'), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _schools.isEmpty
              ? const Center(child: Text('هنوز مرکزای ثبت نشده'))
              : ListView.separated(
                  padding: const EdgeInsets.all(14), itemCount: _schools.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final s = Map<String, dynamic>.from(_schools[i]);
                    final suspended = s['status'] == 'suspended';
                    return Card(child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                      ListTile(
                        leading: CircleAvatar(child: Icon(suspended ? Icons.pause_circle_outline : Icons.school_rounded)),
                        title: Text(s['name']?.toString() ?? '-'),
                        subtitle: Text('کد: ${s['code'] ?? '-'}\nوضعیت: ${s['status'] ?? '-'}${s['api_base_url'] != null ? '\nAPI: ${s['api_base_url']}' : ''}'),
                        isThreeLine: true,
                      ),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        FilledButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSchoolManagementScreen(school: s))), icon: const Icon(Icons.open_in_new_rounded, size: 18), label: const Text('ورود به مرکز')),
                        OutlinedButton.icon(onPressed: () => _action(suspended ? 'unsuspend' : 'suspend', s), icon: Icon(suspended ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18), label: Text(suspended ? 'فعال‌سازی' : 'تعلیق')),
                        OutlinedButton.icon(onPressed: () => _action('delete', s), icon: const Icon(Icons.delete_forever_rounded, size: 18), label: const Text('حذف'), style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent)),
                        IconButton(tooltip: 'تنظیمات', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSettingsScreen(schoolId: '${s['id']}', schoolName: s['name']))), icon: const Icon(Icons.settings_outlined)),
                        IconButton(tooltip: 'تم و لوگو', onPressed: () => _openThemeDialog(s), icon: const Icon(Icons.palette_outlined)),
                        IconButton(tooltip: 'نام اپ و آیکون انتشار', onPressed: () => _openBrandingDialog(s), icon: const Icon(Icons.phone_android_rounded)),
                      ]),
                    ])));
                  },
                ),
    );
  }
}
