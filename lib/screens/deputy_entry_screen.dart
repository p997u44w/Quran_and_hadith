import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_glass_field.dart';
import '../widgets/animated_primary_button.dart';
import 'manager_home.dart';
import 'admin_home.dart';

/// ورودی استاد یار: اول کد مرکز، بعد اطلاعات هویتی. همین فرم هم ثبت‌نام اولیه‌ست
/// هم ورودهای بعدی.
class DeputyEntryScreen extends StatefulWidget {
  const DeputyEntryScreen({super.key});
  @override
  State<DeputyEntryScreen> createState() => _DeputyEntryScreenState();
}

class _DeputyEntryScreenState extends State<DeputyEntryScreen> {
  final _schoolCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final resolved = await ApiService.resolveSchool(_schoolCodeCtrl.text.trim().toUpperCase());
    if (resolved['success'] != true) {
      setState(() { _error = resolved['message'] ?? 'کد مرکز معتبر نیست'; _loading = false; });
      return;
    }
    final res = await ApiService.post('auth/register-deputy', {
      'school_code': _schoolCodeCtrl.text.trim(),
      'full_name': _nameCtrl.text.trim(),
      'national_code': _nationalCodeCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });

    if (res['success'] == true) {
      await ApiService.saveSession(res['token'], res['user']);
      appTheme.value = await SchoolTheme.fetch();
      if (!mounted) return;
      final role = res['user']['role'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminHome() : const ManagerHome()),
      );
    } else {
      setState(() {
        _error = res['message'] ?? 'خطا در ثبت‌نام';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ثبت‌نام استاد یار')),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: primary,
            secondary: secondary,
            showParticles: false,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 84, 20, 30),
                child: GlassCard(
                  blurEnabled: effectsOn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('کد مرکز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('این کد رو از مدیر مرکز بگیرید', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _schoolCodeCtrl, label: 'کد مرکز', icon: Icons.qr_code_rounded),
                      const SizedBox(height: 18),
                      const Text('اطلاعات استاد یار', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      const SizedBox(height: 12),
                      AnimatedGlassField(controller: _nameCtrl, label: 'نام و نام‌خانوادگی', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _nationalCodeCtrl,
                        label: 'کد ملی',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _phoneCtrl,
                        label: 'شماره موبایل',
                        icon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                      ],
                      const SizedBox(height: 18),
                      AnimatedPrimaryButton(label: 'ثبت‌نام', loading: _loading, color: secondary, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
