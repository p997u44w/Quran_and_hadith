import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'theme/nexa_tokens.dart';
import 'screens/root_screen.dart';

/// تم فعلی اپ. بعد از لاگین، با رنگ‌های اختصاصیِ همون مرکز
/// (که ادمین از پنل خودش تنظیم کرده) آپدیت می‌شه.
final ValueNotifier<SchoolTheme> appTheme = ValueNotifier(SchoolTheme.defaultTheme);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // اجرای رابط کاربری را به خواندن تنظیمات وابسته نکن؛ اگر SharedPreferences
  // یا هر پلاگین دیگری دیر جواب بدهد، صفحه Splash سیستم نباید معطل بماند.
  runApp(const NexaApp());
  // تنظیمات ظاهری را بعد از بالا آمدن اولین فریم بخوان.
  SettingsService.load();
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SchoolTheme>(
      valueListenable: appTheme,
      builder: (context, theme, _) {
        return MaterialApp(
          title: theme.appName ?? 'مرکز قرآن و حدیث',
          debugShowCheckedModeBanner: false,
          locale: const Locale('fa', 'IR'),
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.vazirmatnTextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: NexaTokens.bgDeep,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0E6B50),
              primary: theme.primary,
              secondary: theme.secondary,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: NexaTokens.bgDeep,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.secondary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF12382E).withOpacity(0.88),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: NexaTokens.goldSoft.withOpacity(0.22))),
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
          home: const RootScreen(),
        );
      },
    );
  }
}
