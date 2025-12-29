import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/order_controller.dart';
import 'package:selforder/controllers/reservation_controller.dart';
import 'package:selforder/controllers/version_controller.dart';
import 'package:selforder/routes/app_pages.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:selforder/widgets/version_check_dialog.dart';
import 'package:toastification/toastification.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.init();
  await Firebase.initializeApp();
  await setupFCM();

  runApp(ToastificationWrapper(child: const MyApp()));
}

Future<void> setupFCM() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(alert: true, badge: true, sound: true);

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    if (AuthService.isLoggedIn) {
      await AuthService.sendFcmTokenToServer(fcmToken);
    }
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    if (AuthService.isLoggedIn) {
      await AuthService.sendFcmTokenToServer(newToken);
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      if (message.data['type'] == 'reservation') {
        Future.delayed(const Duration(milliseconds: 500), () {
          final reservationController = Get.find<ReservationController>();
          reservationController.loadReservations();
        });
      }
      if (message.data['type'] == 'order') {
        Future.delayed(Duration(milliseconds: 500), () {
          final orderController = Get.find<OrderController>();
          orderController.loadOrders();
        });
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'reservation') {
      Get.toNamed('${AppRoutes.MAIN}/reservation');
      Future.delayed(const Duration(milliseconds: 500), () {
        final reservationController = Get.find<ReservationController>();
        reservationController.loadReservations();
      });
    }
    if (message.data['type'] == 'order') {
      Get.toNamed('${AppRoutes.MAIN}/orders');
      Future.delayed(Duration(milliseconds: 500), () {
        final orderController = Get.find<OrderController>();
        orderController.loadOrders();
      });
    }
  });

  RemoteMessage? initialMessage = await FirebaseMessaging.instance
      .getInitialMessage();
  if (initialMessage != null) {
    if (initialMessage.data['type'] == 'reservation') {
      Future.delayed(const Duration(seconds: 1), () {
        Get.toNamed('${AppRoutes.MAIN}/reservation');
        Future.delayed(const Duration(milliseconds: 500), () {
          final reservationController = Get.find<ReservationController>();
          reservationController.loadReservations();
        });
      });
    }
    if (initialMessage.data['type'] == 'order') {
      Future.delayed(const Duration(seconds: 1), () {
        Get.toNamed('${AppRoutes.MAIN}/orders');
        Future.delayed(Duration(milliseconds: 500), () {
          final orderController = Get.find<OrderController>();
          orderController.loadOrders();
        });
      });
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }

  void _checkAppVersion() async {
    await Future.delayed(const Duration(seconds: 1));
    final versionController = Get.put(VersionController());
    await versionController.checkVersion();
    if (versionController.needsUpdate.value) {
      Get.dialog(
        VersionCheckDialog(controller: versionController),
        barrierDismissible: false,
      );
    }
  }

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
