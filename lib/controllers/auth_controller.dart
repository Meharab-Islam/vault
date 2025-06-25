// lib/app/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

class AuthController extends GetxController {
  final LocalAuthentication auth = LocalAuthentication();
  var isAuthenticated = false.obs;
  var pin = ''.obs; // store PIN in memory, for demo only; use secure storage for real apps

  Future<bool> checkBiometrics() async {
    try {
      return await auth.canCheckBiometrics || await auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Secure Vault',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      isAuthenticated.value = didAuthenticate;
      return didAuthenticate;
    } catch (e) {
      isAuthenticated.value = false;
      return false;
    }
  }

  void setPin(String value) {
    pin.value = value;
  }

  bool verifyPin(String input) {
    return input == pin.value;
  }
}
