import 'dart:typed_data';

import 'package:app_locustaf/core/providers/async_action_state.dart';
import 'package:app_locustaf/features/comunicados/domain/models/comunicado_model.dart';
import 'package:app_locustaf/features/comunicados/presentation/providers/comunicados_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validación en runtime de [ComunicadoActionNotifier.createComunicado]
/// (NOT-04): debe exigir exactamente uno de PDF o contenido y fallar con un
/// mensaje amigable en lugar de un `assert` (que se elimina en release).
void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  test('sin PDF ni contenido falla con mensaje amigable', () async {
    await container.read(comunicadoActionProvider.notifier).createComunicado(
          title: 'Aviso',
          targetType: TargetType.all,
        );

    final state = container.read(comunicadoActionProvider);
    expect(state.status, AsyncActionStatus.failure);
    expect(state.error.toString(), contains('PDF'));
  });

  test('con PDF y contenido a la vez falla', () async {
    await container.read(comunicadoActionProvider.notifier).createComunicado(
          title: 'Aviso',
          content: 'texto',
          pdfFile: PlatformFile(
            name: 'aviso.pdf',
            size: 4,
            bytes: Uint8List(4),
          ),
          targetType: TargetType.all,
        );

    expect(
      container.read(comunicadoActionProvider).status,
      AsyncActionStatus.failure,
    );
  });
}
