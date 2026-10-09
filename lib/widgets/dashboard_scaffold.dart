import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../theme/nexa_tokens.dart';
import '../screens/login_screen.dart';
import 'animated_mesh_background.dart';
import 'effects_toggle.dart';
import 'brand_logo.dart';

class DashboardItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  DashboardItem({required this.title, required this.icon, required this.onTap});
}

class DashboardScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<DashboardItem> items;

  const DashboardScaffold({super.key, required this.title, required this.subtitle, required this.items});

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
    _refreshSchoolBranding();
  }

  Future<void> _refreshSchoolBranding() async {
    final theme = await SchoolTheme.fetch();
    if (!mounted) return;
    appTheme.value = theme;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const LoginScreen()),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = appTheme.value.primary;
    final secondary = appTheme.value.secondary;

    return Scaffold(
      backgroundColor: NexaTokens.bgDeep,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 178,
            pinned: true,
            backgroundColor: primary,
            actions: [
              const Padding(padding: EdgeInsets.only(top: 6), child: EffectsToggle()),
              const SizedBox(width: 6),
              IconButton(icon: const Icon(Icons.logout_rounded), onPressed: () => _logout(context)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: ValueListenableBuilder<bool>(
                valueListenable: SettingsService.animationsEnabled,
                builder: (context, effectsOn, _) => AnimatedMeshBackground(
                  enabled: effectsOn,
                  primary: primary,
                  secondary: secondary,
                  showParticles: false,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 46),
                      child: Row(
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(14), child: Container(color: Colors.white.withOpacity(0.10), padding: const EdgeInsets.all(6), child: const BrandLogo(width: 42, height: 42))),
                          const SizedBox(width: 10),
                          Expanded(child: Text(widget.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF103A2F).withOpacity(0.82),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: secondary.withOpacity(0.28)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: secondary, size: 27),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('به نام خداوند قرآن و نور', style: TextStyle(color: Color(0xFFF2D88D), fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('هر روز، گامی در مسیر تلاوت و فهم کلام وحی', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.auto_awesome_rounded, color: secondary.withOpacity(0.8), size: 19),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.02,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = widget.items[i];
                  // هر کارت با تاخیر کمی نسبت به قبلی fade+slide می‌شه (حس ورود مرحله‌ای)
                  final start = (i * 0.08).clamp(0.0, 0.7);
                  final anim = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
                  );
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(anim),
                      child: _DashboardCard(item: item, secondary: secondary),
                    ),
                  );
                },
                childCount: widget.items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final DashboardItem item;
  final Color secondary;
  const _DashboardCard({required this.item, required this.secondary});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.item.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF174638).withOpacity(0.92),
                const Color(0xFF0B2A22).withOpacity(0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: widget.secondary.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: widget.secondary.withOpacity(0.16), shape: BoxShape.circle),
                child: Icon(widget.item.icon, color: widget.secondary, size: 27),
              ),
              const SizedBox(height: 12),
              Text(widget.item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback page for a route that is intentionally unavailable in the current build.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: NexaTokens.glassFill,
                  shape: BoxShape.circle,
                  border: Border.all(color: NexaTokens.glassBorder),
                ),
                child: Icon(Icons.dashboard_customize_rounded, size: 38, color: appTheme.value.secondary),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'این بخش در نسخه فعلی مسیر مستقیمی ندارد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: NexaTokens.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
