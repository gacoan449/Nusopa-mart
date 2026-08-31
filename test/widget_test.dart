import 'package:flutter_test/flutter_test.dart';
import 'package:nusopa_mart/main.dart';

void main() {
  testWidgets('Nusopa.Mart app starts', (tester) async {
    await tester.pumpWidget(const NusopaMartApp());
    expect(find.text('Nusopa.Mart'), findsOneWidget);
  });
}
