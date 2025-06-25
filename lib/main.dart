import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vault/bindings/file_binding.dart';
import 'controllers/auth_controller.dart';
import 'views/pin_lock_screen.dart';
import 'views/file_hider_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Secure Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      initialBinding: FileBinding(),
      getPages: [
        GetPage(name: '/', page: () => const SplashScreen()),
        GetPage(name: '/pinlock', page: () => const PinLockScreen()),
        GetPage(name: '/vault', page: () =>  FileHiderScreen()),
      ],
    );
  }
}

// SplashScreen to check biometric and PIN on app start
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController authController = Get.find();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    bool canUseBiometrics = await authController.checkBiometrics();

    if (canUseBiometrics) {
      bool authenticated = await authController.authenticateWithBiometrics();
      if (authenticated) {
        Get.offNamed('/vault');
        return;
      }
    }

    // If biometric not available or fails, show PIN lock
    // For demo, if no PIN is set, set default PIN = "1234"
    if (authController.pin.value.isEmpty) {
      authController.setPin('1234'); // You can implement PIN setup flow later
    }

    Get.offNamed('/pinlock');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
