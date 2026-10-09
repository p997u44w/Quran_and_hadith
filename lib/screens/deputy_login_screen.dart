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

class DeputyLoginScreen extends StatefulWidget {
  const DeputyLoginScreen({super.key});

  @override
  State<DeputyLoginScreen> createState() => _DeputyLoginScreenState();
}

class _DeputyLoginScreenState extends State<DeputyLoginScreen> {
  final _classCodeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _nationalCodeCtrl = TextEditingController();

  bool _loading = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _classCodeCtrl.dispose();
    _nameCtrl.dispose();
    _nationalCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedLogin() async {
    final saved = await ApiService.getRememberedLogin('deputy');
    if (!mounted || saved == null) return;

    setState(() {
      _rememberMe = true;
      _classCodeCtrl.text = '${saved['class_code'] ?? ''}';
      _nameCtrl.text = '${saved['full_name'] ?? ''}';
      _nationalCodeCtrl.text = '${saved['national_code'] ?? ''}';
    });
  }

  Future<void> _submit() async {
    final classCode = _classCodeCtrl.text.trim().toUpperCase();
    final fullName = _nameCtrl.text.trim();
    final nationalCode = _nationalCodeCtrl.text.trim();

    if (classCode.isEmpty || fullName.isEmpty || nationalCode.isEmpty) {
      setState(() {
        _error = 'کد کلاس، نام و کد ملی را کامل وارد کنید';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // اول کد کلاس را پیدا می‌کنیم تا مسیر مرکز مشخص شود.
      final resolved = await ApiService.resolveClass(classCode);
      if (resolved['success'] != true) {
        if (!mounted) return;
        setState(() {
          _error = resolved['message'] ?? 'کد کلاس معتبر نیست';
          _loading = false;
        });
        return;
      }

      final res = await ApiService.post(
        'auth/login-deputy',
        {
          'class_code': classCode,
          'full_name': fullName,
          'national_code': nationalCode,
        },
      );

      if (res['success'] == true) {
        final token = res['token'];
        final user = res['user'];

        if (token == null || user is! Map<String, dynamic>) {
          if (!mounted) return;
          setState(() {
            _error = 'پاسخ ورود از سرور کامل نیست';
            _loading = false;
          });
          return;
        }

        await ApiService.saveSession(token, user);

        if (_rememberMe) {
          await ApiService.saveRememberedLogin(
            'deputy',
            {
              'class_code': classCode,
              'full_name': fullName,
              'national_code': nationalCode,
            },
          );
        } else {
          await ApiService.clearRememberedLogin('deputy');
        }

        appTheme.value = await SchoolTheme.fetch();

        if (!mounted) return;

        final role = '${user['role'] ?? 'deputy'}';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                role == 'admin' ? const AdminHome() : const ManagerHome(),
          ),
        );
      } else {
        if (!mounted) return;
        setState(() {
          _error = res['message'] ?? 'خطا در ورود';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'ارتباط با سرور برقرار نشد';
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
      appBar: AppBar(
        title: const Text('ورود استاد یار'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
                      AnimatedGlassField(
                        controller: _classCodeCtrl,
                        label: 'کد کلاس',
                        icon: Icons.qr_code_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _nameCtrl,
                        label: 'نام و نام‌خانوادگی',
                        icon: Icons.person_outline_rounded,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AnimatedGlassField(
                        controller: _nationalCodeCtrl,
                        label: 'کد ملی',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ],
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: _loading
                            ? null
                            : (value) =>
                                setState(() => _rememberMe = value ?? false),
                        title: const Text(
                          'مرا به خاطر بسپار',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: secondary,
                      ),
                      const SizedBox(height: 8),
                      AnimatedPrimaryButton(
                        label: 'ورود',
                        loading: _loading,
                        color: secondary,
                        onPressed: _loading ? null : _submit,
                      ),
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
