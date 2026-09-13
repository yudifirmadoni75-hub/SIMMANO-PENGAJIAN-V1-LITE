import 'package:flutter_test/flutter_test.dart';
import 'package:simmano_pengajian_v1_lite/main.dart';
void main(){testWidgets('login page renders', (tester) async {await tester.pumpWidget(const App());expect(find.text('SIMMANO PENGAJIAN V1 Lite'), findsOneWidget);expect(find.text('Masuk'), findsOneWidget);});}
