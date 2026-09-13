import 'package:flutter_test/flutter_test.dart';
import 'package:simmano_pengajian_v1_lite/main.dart';

void main() {
  testWidgets('Login page tampil', (tester) async {
    await tester.pumpWidget(const SimmanoPengajianApp());
    expect(find.text('SIMMANO PENGAJIAN'), findsWidgets);
    expect(find.text('Masuk ke aplikasi'), findsOneWidget);
    expect(find.text('Nama pengguna'), findsOneWidget);
  });
}
