import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../../utils/user_session.dart';

class DeviceService {
  final StorageService _storage = StorageService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<void> initDeviceIdentity() async {
    if (UserSession.deviceUUID != null && UserSession.deviceHash != null) return;

    try {
      String? storedUuid = await _storage.getDeviceUUID();
      String? storedHash = await _storage.getDeviceHash();

      if (storedUuid != null && storedHash != null) {
        UserSession.deviceUUID = storedUuid;
        UserSession.deviceHash = storedHash;
      } else {
        // Generate new identity
        final String uuid = const Uuid().v4();
        final String hash = await _generateDeviceHash();

        await _storage.saveDeviceIdentity(uuid, hash);
        UserSession.deviceUUID = uuid;
        UserSession.deviceHash = hash;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _generateDeviceHash() async {
    String deviceData = '';
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceData = '${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}-${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceData = '${iosInfo.name}-${iosInfo.model}-${iosInfo.identifierForVendor}-${iosInfo.systemVersion}';
      } else {
        deviceData = 'desktop-${Platform.operatingSystem}-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      deviceData = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
    }

    final bytes = utf8.encode(deviceData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
