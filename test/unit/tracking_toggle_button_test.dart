import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:monamie_app/app/modules/monamie/controller/tracking_toggle_controller.dart';
import 'package:monamie_app/app/modules/monamie/ui/widgets/tracking_toggle_button.dart';

class FakeTrackingToggleController implements TrackingToggleController {
  @override
  final RxBool isTrackingEnabled;

  @override
  final RxBool isTrackingLoading;

  int toggleCalls = 0;
  Future<void> Function()? onToggle;

  FakeTrackingToggleController({
    bool enabled = false,
    bool loading = false,
    this.onToggle,
  })  : isTrackingEnabled = enabled.obs,
        isTrackingLoading = loading.obs;

  @override
  Future<void> toggleService() async {
    if (isTrackingLoading.value) return;
    toggleCalls++;
    if (onToggle != null) {
      await onToggle!();
    }
  }
}

Widget _buildTestApp(TrackingToggleController controller) {
  return MaterialApp(
    home: Scaffold(
      body: TrackingToggleButton(controller: controller),
    ),
  );
}

void main() {
  group('TrackingToggleButton - Testes de Estados e Feedback Visual', () {
    testWidgets('Estado Inativo: exibe vermelho, ícone location_off e botão habilitado',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: false, loading: false);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.red);
      expect(fab.tooltip, 'Ativar compartilhamento de localização');
      expect(fab.onPressed, isNotNull);

      expect(find.byIcon(Icons.location_off), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Ao tocar, deve disparar o toggleService
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(fakeCtrl.toggleCalls, 1);
    });

    testWidgets('Estado Ativando (Loading): exibe laranja, spinner e botão desabilitado',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: false, loading: true);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.orange.shade800);
      expect(fab.tooltip, 'Ativando compartilhamento de localização...');
      expect(fab.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);

      // Toque com botão desabilitado não deve incrementar chamadas
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(fakeCtrl.toggleCalls, 0);
    });

    testWidgets('Estado Ativo: exibe verde, ícone location_on e botão habilitado',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: true, loading: false);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.green);
      expect(fab.tooltip, 'Desativar compartilhamento de localização');
      expect(fab.onPressed, isNotNull);

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Ao tocar, dispara toggleService
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      expect(fakeCtrl.toggleCalls, 1);
    });

    testWidgets('Estado Desativando (Loading): exibe laranja, spinner e tooltip correto',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: true, loading: true);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.orange.shade800);
      expect(fab.tooltip, 'Desativando compartilhamento de localização...');
      expect(fab.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Transição Reativa Completa: Vermelho -> Laranja (Loading) -> Verde (Ativo)',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: false, loading: false);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      // 1. Inicial: Vermelho e desligado
      var fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.red);
      expect(find.byIcon(Icons.location_off), findsOneWidget);

      // 2. Usuário clica: entra em estado de carregamento
      fakeCtrl.isTrackingLoading.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // Animação do AnimatedSwitcher

      fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.orange.shade800);
      expect(fab.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 3. Processo conclui com sucesso: torna-se ativo
      fakeCtrl.isTrackingEnabled.value = true;
      fakeCtrl.isTrackingLoading.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250)); // Animação do AnimatedSwitcher

      fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.green);
      expect(fab.onPressed, isNotNull);
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Transição com Falha/Cancelamento: Vermelho -> Laranja (Loading) -> Vermelho',
        (WidgetTester tester) async {
      final fakeCtrl = FakeTrackingToggleController(enabled: false, loading: false);

      await tester.pumpWidget(_buildTestApp(fakeCtrl));

      // 1. Inicia carregamento
      fakeCtrl.isTrackingLoading.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 2. Operação falha ou é cancelada pelo usuário
      fakeCtrl.isTrackingLoading.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      final fab = tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));
      expect(fab.backgroundColor, Colors.red);
      expect(fab.onPressed, isNotNull);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });
  });
}

