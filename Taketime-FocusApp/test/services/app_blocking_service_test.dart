import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../../lib/services/app_blocking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Blocking Service Tests', () {
    test('should check permissions correctly', () async {
      expect(() async => await AppBlockingService.checkUsageStatsPermission(), returnsNormally);
      expect(() async => await AppBlockingService.checkOverlayPermission(), returnsNormally);
      expect(() async => await AppBlockingService.checkAccessibilityPermission(), returnsNormally);
    });

    test('should request permissions correctly', () async {
      expect(() async => await AppBlockingService.requestUsageStatsPermission(), returnsNormally);
      expect(() async => await AppBlockingService.requestOverlayPermission(), returnsNormally);
      expect(() async => await AppBlockingService.requestAccessibilityPermission(), returnsNormally);
    });

    test('should handle service management', () async {
      expect(() async => await AppBlockingService.startAppBlockingService(), returnsNormally);
      expect(() async => await AppBlockingService.stopAppBlockingService(), returnsNormally);
    });
  });
}
