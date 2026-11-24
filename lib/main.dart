import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_modules.dart';
import 'features/auth/auth_module.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AuthModule.init();
  if (!kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform)) {
    AuthModule.gateway.registerGateway(reportsModule.gateway);
  }
  runApp(AuthScope(controller: AuthModule.controller, child: const AspalApp()));
}

class AspalApp extends StatelessWidget {
  const AspalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASPAL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}
