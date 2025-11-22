// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/index.dart' as index;
import '../routes/users/register.dart' as users_register;
import '../routes/users/login.dart' as users_login;
import '../routes/decks/index.dart' as decks_index;
import '../routes/cards/index.dart' as cards_index;

import '../routes/_middleware.dart' as middleware;
import '../routes/decks/_middleware.dart' as decks_middleware;

void main() async {
  final address = InternetAddress.tryParse('') ?? InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  hotReload(() => createServer(address, port));
}

Future<HttpServer> createServer(InternetAddress address, int port) {
  final handler = Cascade().add(buildRootHandler()).handler;
  return serve(handler, address, port);
}

Handler buildRootHandler() {
  final pipeline = const Pipeline().addMiddleware(middleware.middleware);
  final router = Router()
    ..mount('/cards', (context) => buildCardsHandler()(context))
    ..mount('/decks', (context) => buildDecksHandler()(context))
    ..mount('/users', (context) => buildUsersHandler()(context))
    ..mount('/', (context) => buildHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildCardsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => cards_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildDecksHandler() {
  final pipeline = const Pipeline().addMiddleware(decks_middleware.middleware);
  final router = Router()
    ..all('/', (context) => decks_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildUsersHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/register', (context) => users_register.onRequest(context,))..all('/login', (context) => users_login.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

