import 'package:dart_frog/dart_frog.dart';

import '../../lib/catalog_read_guard.dart';

/// BT-CAT-03: leitura do catálogo sem chamada a serviço de fora (D-35).
Handler middleware(Handler handler) => handler.use(catalogReadGuard());
