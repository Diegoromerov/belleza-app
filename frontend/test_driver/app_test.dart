import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('App smoke test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        await driver.close();
      }
    });

    test('starts at home screen', () async {
      // Simple check: wait for any widget with a key 'mainScaffold'
      final SerializableFinder scaffold = find.byValueKey('mainScaffold');
      await driver.waitFor(scaffold);
    });
  });
}
