import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() => runApp(const AspalApp());

class AspalApp extends StatelessWidget {
  const AspalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASPAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
