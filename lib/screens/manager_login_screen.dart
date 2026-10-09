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

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({super.key});
  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _rememberMe = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  Future<void> _loadRememberedLogin() async {
    final saved = await ApiService.getRememberedLogin('manager');
    if (!mounted || saved == null) return;
    setState(() {
      _rememberMe = true;
      _usernameCtrl.text = saved['username'] ?? '';
    });
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.postHub('auth/login-manager', {
      'username': _usernameCtrl.text.trim(),
      'password': _passwordCtrl.text,
    });
    if (res['success'] == true) {
      final role = res['user']?['role'];
      if (role == 'admin') {
        await ApiService.forgetSchool();
      } else if (res['school']?['code'] != null) {
        await ApiService.resolveSchool('${res['school']['code']}');
      }
      await ApiService.saveSession(res['token'], res['user']);
      if (_rememberMe) {
        await ApiService.saveRememberedLogin('manager', {
          'username': _usernameCtrl.text.trim(),
        });
      } else {
        await ApiService.clearRememberedLogin('manager');
      }

      appTheme.value = await SchoolTheme.fetch();
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == 'admin' ? const AdminHome() : const ManagerHome()));
    } else {
      setState(() { _error = res['message'] ?? 'خطا در ورود'; _loading = false; });
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('ورود مدیر'), backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn, primary: primary, secondary: secondary, showParticles: false,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 84, 20, 30),
                child: GlassCard(
                  blurEnabled: effectsOn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('ورود مدیر مرکز یا ادمین کل', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),
                      AnimatedGlassField(controller: _usernameCtrl, label: 'نام کاربری', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'رمز عبور',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white70),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.18))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: secondary)),
                        ),
                        onSubmitted: (_) => _loading ? null : _submit(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                      ],
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged: (value) => setState(() => _rememberMe = value ?? false),
                        title: const Text('مرا به خاطر بسپار', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: secondary,
                      ),
                      const SizedBox(height: 8),
                      AnimatedPrimaryButton(label: 'ورود', loading: _loading, color: secondary, onPressed: _submit),
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
