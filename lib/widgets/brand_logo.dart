import 'package:flutter/material.dart';
import '../main.dart';

/// لوگوی مرکز/برند فاطمی را از برندینگ سرور نشان می‌دهد و اگر هنوز برندینگ تنظیم نشده
/// باشد، لوگوی پیش‌فرض Nexa را نمایش می‌دهد.
class BrandLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;
  const BrandLogo({super.key, this.width = 120, this.height, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    final url = appTheme.value.logoUrl ?? appTheme.value.iconUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url, width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => Image.asset('assets/logo/nexa_logo.png', width: width, height: height, fit: fit),
      );
    }
    return Image.asset('assets/logo/nexa_logo.png', width: width, height: height, fit: fit);
  }
}
