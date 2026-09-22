import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as router;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/context_models.dart' show AvailableContext, ActiveContext;
import 'services/contextResolutionService.dart';

final Router router = router.Router();

Future<void> setupContextRoutes() async {
  router.get('/contexts/available', (shelf.Request request) async {
    final tenantId = request.headers['tenant-id'];
    if (tenantId == null) {
      return shelf.Response.badRequest('Tenant ID is required');
    }

    try {
      final availableContexts = await ContextResolutionService.resolveAvailableContexts(tenantId);
      return shelf.Response.ok(
        json.encode(availableContexts.map((context) => context.toJson()).toList()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Error resolving contexts: $e');
    }
  });

  router.post('/contexts/active', (shelf.Request request) async {
    final tenantId = request.headers['tenant-id'];
    final contextId = request.headers['context-id'];

    if (tenantId == null || contextId == null) {
      return shelf.Response.badRequest('Tenant ID and Context ID are required');
    }

    try {
      final activeContext = await ContextResolutionService.selectActiveContext(tenantId, contextId);
      return shelf.Response.ok(
        json.encode(activeContext.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Error selecting active context: $e');
    }
  });

  // Exponer el router
  shelf.Handler handler = router.router;
}