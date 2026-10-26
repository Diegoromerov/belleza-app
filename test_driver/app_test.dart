import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Smoke test', () {
    final scaffold = find.byValueKey('mainScaffold');
    FlutterDriver driver;

    setUpAll(() async => driver = await FlutterDriver.connect());
    tearDownAll(() async => driver?.close());

    test('app launches and shows MainScaffold', () async {
      await driver.waitFor(scaffold);
    });
  });
}
