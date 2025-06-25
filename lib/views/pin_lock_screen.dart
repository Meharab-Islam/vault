// lib/app/views/pin_lock_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final AuthController authController = Get.find();
  final TextEditingController pinController = TextEditingController();

  String errorText = '';

  void _verifyPin() {
    if (authController.verifyPin(pinController.text)) {
      Get.offNamed('/vault'); // navigate to your vault screen
    } else {
      setState(() {
        errorText = 'Invalid PIN, please try again';
      });
      pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '4-digit PIN',
                errorText: errorText.isEmpty ? null : errorText,
              ),
              onSubmitted: (_) => _verifyPin(),
            ),
            ElevatedButton(onPressed: _verifyPin, child: const Text('Unlock')),
          ],
        ),
      ),
    );
  }
}
