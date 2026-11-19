import 'package:flutter_test/flutter_test.dart';
import 'package:al_tayer/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    expect(const AlTayerApp(), isNotNull);
  });
}
