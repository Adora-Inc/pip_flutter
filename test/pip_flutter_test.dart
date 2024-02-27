import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pip_flutter/pipflutter_player.dart';

void main() {
  const MethodChannel channel = MethodChannel('pip_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(PipFlutterPlayer, '42');
  });
}
