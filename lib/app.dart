import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';

class DocLockApp extends StatelessWidget {
  const DocLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocLock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LoginPage(),
    );
  }
}
