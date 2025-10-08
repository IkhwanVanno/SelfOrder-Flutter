import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/routes/app_pages.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Self Order',
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.MAIN,
      getPages: AppPages.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}