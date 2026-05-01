import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> isAvailable() async{
    try{
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException{
      return false;
    }
  }
  
  Future<bool> authenticate() async{
    try {
      return await _auth.authenticate(
        localizedReason: 'Login dengan biometrik',
        options: const AuthenticationOptions(
         biometricOnly: true,
        stickyAuth: true,
        sensitiveTransaction: false,
      ),
      );
    } on PlatformException catch(e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

}
