import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../widgets/animated_mesh_background.dart';
import '../widgets/effects_toggle.dart';
import '../widgets/glass_card.dart';
import '../widgets/brand_logo.dart';
import 'register_chooser_screen.dart';
import 'login_chooser_screen.dart';

/// صفحه‌ی اولِ اپ: فقط دو دکمه — «ورود» (برای کسی که قبلاً ثبت‌نام کرده) و
/// «ثبت‌نام» (برای اولین بار). ورود اول میاد چون بیشتر کاربرها قبلاً ثبت‌نام کردن.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleFade;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _logoScale = CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack));
    _titleFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.25, 0.65, curve: Curves.easeOut));
    _buttonsFade = CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));
    _buttonsSlide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entrance, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)));
    _entrance.forward();

    _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 6000));
    if (SettingsService.animationsEnabled.value) _float.repeat(reverse: true);
    SettingsService.animationsEnabled.addListener(_syncFloat);

    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (update == null || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (context) => PopScope(
        canPop: !update.forceUpdate,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0B2A21),
          title: Text('نسخه‌ی جدید ${update.versionName} موجود است', style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Text(update.changelog, style: const TextStyle(color: Colors.white70)),
          actions: [
            if (!update.forceUpdate)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('بعدا')),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(update.apkUrl), mode: LaunchMode.externalApplication),
              child: const Text('دانلود نسخه جدید'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncFloat() {
    if (SettingsService.animationsEnabled.value) {
      _float.repeat(reverse: true);
    } else {
      _float.stop();
      _float.value = 0;
    }
  }

  @override
  void dispose() {
    SettingsService.animationsEnabled.removeListener(_syncFloat);
    _entrance.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      body: ValueListenableBuilder<bool>(
        valueListenable: SettingsService.animationsEnabled,
        builder: (context, effectsOn, _) {
          return AnimatedMeshBackground(
            enabled: effectsOn,
            primary: primary,
            secondary: secondary,
            child: SafeArea(
              child: Stack(
                children: [
                  const Positioned(top: 6, left: 6, child: EffectsToggle()),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoScale,
                              child: AnimatedBuilder(
                                animation: _float,
                                builder: (context, child) {
                                  final dy = effectsOn ? (-6 + 12 * _float.value) : 0.0;
                                  return Transform.translate(offset: Offset(0, dy), child: child);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: secondary.withOpacity(0.45), blurRadius: 22, spreadRadius: 2),
                                      BoxShadow(color: primary.withOpacity(0.35), blurRadius: 16, spreadRadius: 0),
                                    ],
                                  ),
                                  child: const BrandLogo(width: 150),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FadeTransition(
                            opacity: _titleFade,
                            child: Column(
                              children: [
                                Text(
                                  'مرکز قرآن و حدیث',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text('مرکز قرآن و حدیث و تربیت قرآنی', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06251E).withOpacity(0.58),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: secondary.withOpacity(0.42)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 7))],
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.auto_stories_rounded, color: secondary, size: 24),
                                const SizedBox(height: 8),
                                const Text(
                                  'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Color(0xFFF3D88B), fontSize: 21, fontWeight: FontWeight.w700, height: 1.8),
                                ),
                                const SizedBox(height: 3),
                                const Text('و قرآن را شمرده و روشن بخوان', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 3),
                                Text('سوره مزّمّل، آیه ۴', style: TextStyle(color: secondary.withOpacity(0.95), fontSize: 11)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          FadeTransition(
                            opacity: _buttonsFade,
                            child: SlideTransition(
                              position: _buttonsSlide,
                              child: GlassCard(
                                blurEnabled: effectsOn,
                                borderRadius: 28,
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    _AuthChoiceButton(
                                      icon: Icons.login_rounded,
                                      label: 'ورود',
                                      color: secondary,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginChooserScreen())),
                                    ),
                                    const SizedBox(height: 12),
                                    _AuthChoiceButton(
                                      icon: Icons.person_add_alt_1_rounded,
                                      label: 'ثبت‌نام',
                                      color: secondary,
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterChooserScreen())),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class _AuthChoiceButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AuthChoiceButton({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 58,
    child: Material(
      color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.16))),
          child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), const Icon(Icons.chevron_left_rounded, color: Colors.white38)]),
        ),
      ),
    ),
  );
}
