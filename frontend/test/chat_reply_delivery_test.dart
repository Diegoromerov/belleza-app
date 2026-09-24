import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:clock/clock.dart';
import 'package:beauty_app/services/reply_reconcile.dart';

void main() {
  group('ReplyReconciler — Guardián unitario de entrega de respuestas de AURA', () {
    test('(a) consulta de inmediato al arrancar y luego cada 4 s', () {
      fakeAsync((async) {
        int pollCount = 0;
        final reconciler = ReplyReconciler(
          pollInterval: const Duration(seconds: 4),
          maxDuration: const Duration(seconds: 90),
          getNow: () => clock.now(),
        );

        expect(reconciler.isRunning, false);
        reconciler.start(onPoll: () async {
          pollCount++;
        });

        // (a.1) Invocación inmediata en t=0
        expect(pollCount, 1);
        expect(reconciler.isRunning, true);

        // (a.2) Invocación a los 4 s
        async.elapse(const Duration(seconds: 4));
        expect(pollCount, 2);

        // (a.3) Invocación a los 8 s
        async.elapse(const Duration(seconds: 4));
        expect(pollCount, 3);

        reconciler.stop();
        expect(reconciler.isRunning, false);
      });
    });

    test('(b) se detiene cuando el último mensaje es de AURA (sender_id == "0")', () {
      fakeAsync((async) {
        final messages = <Map<String, String>>[
          {'id': '1', 'sender_id': '7', 'content': 'Hola AURA'},
        ];

        final reconciler = ReplyReconciler(
          pollInterval: const Duration(seconds: 4),
          maxDuration: const Duration(seconds: 90),
          getNow: () => clock.now(),
        );

        reconciler.start(onPoll: () async {
          final lastMsg = messages.isNotEmpty ? messages.last : null;
          if (lastMsg != null && lastMsg['sender_id'] == '0') {
            reconciler.stop();
          }
        });

        expect(reconciler.isRunning, true);

        // Simular respuesta de AURA recibida en la siguiente consulta
        async.elapse(const Duration(seconds: 4));
        messages.add({'id': '2', 'sender_id': '0', 'content': '¡Hola! ¿En qué puedo ayudarte?'});

        // Siguiente tick (8s) detecta que el último mensaje es de AURA
        async.elapse(const Duration(seconds: 4));
        expect(reconciler.isRunning, false);
      });
    });

    test('(c) se detiene al recibir un push chat_message', () {
      fakeAsync((async) {
        int pollCount = 0;
        final reconciler = ReplyReconciler(
          pollInterval: const Duration(seconds: 4),
          maxDuration: const Duration(seconds: 90),
          getNow: () => clock.now(),
        );

        reconciler.start(onPoll: () async {
          pollCount++;
        });

        expect(pollCount, 1);
        async.elapse(const Duration(seconds: 4));
        expect(pollCount, 2);

        // Simular llegada de push WebSocket
        reconciler.stop();
        expect(reconciler.isRunning, false);

        // Transcurren 10s extra y no debe haber más polls
        async.elapse(const Duration(seconds: 10));
        expect(pollCount, 2);
      });
    });

    test('(d) se detiene automáticamente al vencer el límite de 90 s', () {
      fakeAsync((async) {
        int pollCount = 0;
        final reconciler = ReplyReconciler(
          pollInterval: const Duration(seconds: 4),
          maxDuration: const Duration(seconds: 90),
          getNow: () => clock.now(),
        );

        reconciler.start(onPoll: () async {
          pollCount++;
        });

        // Avanzar a 88 segundos (debería seguir activo)
        async.elapse(const Duration(seconds: 88));
        expect(reconciler.isRunning, true);

        // Al pasar de 90 s (ej: 92 s tick), debe detenerse automáticamente
        async.elapse(const Duration(seconds: 4));
        expect(reconciler.isRunning, false);

        final pollsAtDeadline = pollCount;
        async.elapse(const Duration(seconds: 20));
        expect(pollCount, pollsAtDeadline);
      });
    });
  });
}
