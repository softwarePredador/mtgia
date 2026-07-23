import 'dart:async';

import '../api/api_client.dart';
import '../resilience/offline_capability.dart';

enum FriendlyErrorContext {
  authLogin,
  authRegister,
  authProfile,
  deckGenerate,
  deckSave,
  deckDetails,
  deckOptimize,
  deckValidate,
  deckPricing,
  setsCatalog,
  setCards,
  tradeList,
  tradeDetail,
  tradeCreate,
  tradeAction,
  tradeMessage,
  directMessage,
  binder,
  marketplace,
  generic,
}

class FriendlyErrorMapper {
  const FriendlyErrorMapper._();

  static String fromApiResponse(
    ApiResponse response, {
    FriendlyErrorContext context = FriendlyErrorContext.generic,
    String? fallback,
  }) {
    return fromStatusCode(
      response.statusCode,
      body: response.data,
      context: context,
      fallback: fallback,
    );
  }

  static String fromStatusCode(
    int statusCode, {
    Object? body,
    FriendlyErrorContext context = FriendlyErrorContext.generic,
    String? fallback,
  }) {
    final specific = statusCode < 500
        ? _messageFromBody(body, context: context)
        : null;
    if (specific != null) return specific;

    if (statusCode == 400 || statusCode == 422) {
      return switch (context) {
        FriendlyErrorContext.authRegister =>
          'Não foi possível criar sua conta. Revise os dados e tente novamente.',
        FriendlyErrorContext.deckGenerate =>
          'Não conseguimos gerar um deck válido com essa descrição. Ajuste o pedido e tente novamente.',
        FriendlyErrorContext.deckSave =>
          'Não foi possível salvar este deck. Revise a lista e tente novamente.',
        FriendlyErrorContext.deckOptimize =>
          'Não foi possível otimizar este deck agora. Revise a lista e tente novamente.',
        FriendlyErrorContext.deckValidate =>
          'Não foi possível validar este deck agora. Revise a lista e tente novamente.',
        FriendlyErrorContext.tradeCreate =>
          'Não foi possível enviar a proposta. Revise os itens, valores e tente novamente.',
        FriendlyErrorContext.tradeAction =>
          'Esta ação não pôde ser concluída. Atualize a troca e tente novamente.',
        FriendlyErrorContext.binder =>
          'Não foi possível atualizar o fichário. Revise os dados e tente novamente.',
        FriendlyErrorContext.marketplace =>
          'Não foi possível carregar o marketplace com esses filtros. Ajuste a busca e tente novamente.',
        _ =>
          fallback ??
              'Não foi possível concluir a ação. Revise os dados e tente novamente.',
      };
    }

    if (statusCode == 401) {
      return switch (context) {
        FriendlyErrorContext.authLogin => 'Email ou senha inválidos.',
        FriendlyErrorContext.authRegister =>
          'Não foi possível criar a sessão. Tente entrar novamente.',
        _ => 'Sua sessão expirou. Faça login novamente para continuar.',
      };
    }

    if (statusCode == 403) {
      return 'Você não tem permissão para realizar esta ação.';
    }

    if (statusCode == 404) {
      return switch (context) {
        FriendlyErrorContext.deckDetails => 'Não encontramos este deck.',
        FriendlyErrorContext.setsCatalog => 'Não encontramos essas coleções.',
        FriendlyErrorContext.setCards =>
          'Não encontramos esta coleção no catálogo local.',
        FriendlyErrorContext.tradeDetail => 'Não encontramos esta troca.',
        _ => fallback ?? 'Não encontramos o conteúdo solicitado.',
      };
    }

    if (statusCode == 409 || statusCode == 423) {
      return switch (context) {
        FriendlyErrorContext.tradeCreate || FriendlyErrorContext.tradeAction =>
          'Esta troca mudou ou algum item não está mais disponível. Atualize e tente novamente.',
        FriendlyErrorContext.binder =>
          'Este item foi atualizado em outro lugar. Recarregue o fichário e tente novamente.',
        _ =>
          fallback ??
              'As informações mudaram. Atualize a tela e tente novamente.',
      };
    }

    if (statusCode == 429) {
      return 'Muitas tentativas em sequência. Aguarde um instante e tente novamente.';
    }

    if (statusCode >= 500) {
      return 'Servidor indisponível no momento. Tente novamente em instantes.';
    }

    return fallback ?? 'Não foi possível concluir a ação. Tente novamente.';
  }

  static String fromException(
    Object? error, {
    FriendlyErrorContext context = FriendlyErrorContext.generic,
    String? fallback,
  }) {
    if (error == null) {
      return fallback ?? 'Não foi possível concluir a ação. Tente novamente.';
    }

    if (error is TimeoutException) {
      return 'A conexão demorou mais que o esperado. Tente novamente em instantes.';
    }

    final raw = error.toString().trim();
    final normalized = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '')
        .trim();
    final lower = normalized.toLowerCase();

    final statusMatch = RegExp(r'\b(4\d\d|5\d\d)\b').firstMatch(lower);
    if (statusMatch != null) {
      final code = int.tryParse(statusMatch.group(1)!);
      if (code != null) {
        return fromStatusCode(code, context: context, fallback: fallback);
      }
    }

    if (_looksLikeNetworkError(lower, error.runtimeType.toString())) {
      return offlineContractForContext(context).disconnectedMessage;
    }

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'A conexão demorou mais que o esperado. Tente novamente em instantes.';
    }

    if (_looksLikeAiUnavailable(lower)) {
      return 'A IA não conseguiu responder agora. Tente novamente em instantes.';
    }

    if (lower.contains('resolver todas as cartas') ||
        lower.contains('resolve failed') ||
        lower.contains('resolver cartas') ||
        lower.contains('resolve all cards') ||
        lower.contains('cards/resolve')) {
      return 'Não foi possível encontrar todas as cartas. Revise a lista e tente novamente.';
    }

    if (lower.contains('deck não encontrado') ||
        lower.contains('deck nao encontrado')) {
      return 'Não encontramos este deck. Atualize a lista e tente novamente.';
    }

    if (lower.contains('resposta invalida') ||
        lower.contains('resposta inválida') ||
        lower.contains('invalid response') ||
        lower.contains('format exception')) {
      return 'Recebemos uma resposta inesperada. Atualize a tela e tente novamente.';
    }

    if (!_looksTechnical(normalized) && normalized.isNotEmpty) {
      return normalized;
    }

    return fallback ?? _fallbackForContext(context);
  }

  static String _fallbackForContext(FriendlyErrorContext context) {
    return switch (context) {
      FriendlyErrorContext.authLogin =>
        'Não foi possível entrar agora. Confira seus dados e tente novamente.',
      FriendlyErrorContext.authRegister =>
        'Não foi possível criar sua conta agora. Tente novamente em instantes.',
      FriendlyErrorContext.deckGenerate =>
        'Não foi possível gerar o deck agora. Ajuste a descrição e tente novamente.',
      FriendlyErrorContext.deckSave =>
        'Não foi possível salvar o deck agora. Tente novamente em instantes.',
      FriendlyErrorContext.deckDetails =>
        'Não foi possível carregar este deck. Tente novamente.',
      FriendlyErrorContext.deckOptimize =>
        'Não foi possível otimizar este deck agora. Tente novamente em instantes.',
      FriendlyErrorContext.deckValidate =>
        'Não foi possível validar este deck agora. Tente novamente.',
      FriendlyErrorContext.setsCatalog =>
        'Não foi possível carregar as coleções agora. Verifique a conexão e tente novamente.',
      FriendlyErrorContext.setCards =>
        'Não foi possível carregar as cartas desta coleção agora. Tente novamente.',
      FriendlyErrorContext.tradeCreate =>
        'Não foi possível enviar a proposta agora. Tente novamente.',
      FriendlyErrorContext.tradeAction =>
        'Não foi possível atualizar esta troca agora. Tente novamente.',
      FriendlyErrorContext.tradeMessage =>
        'Não foi possível enviar a mensagem agora. Tente novamente.',
      FriendlyErrorContext.directMessage =>
        'Não foi possível carregar ou enviar mensagens agora. Tente novamente.',
      FriendlyErrorContext.binder =>
        'Não foi possível atualizar o fichário agora. Tente novamente.',
      FriendlyErrorContext.marketplace =>
        'Não foi possível carregar o marketplace agora. Tente novamente.',
      _ => 'Não foi possível concluir a ação. Tente novamente.',
    };
  }

  static OfflineFlowContract offlineContractForContext(
    FriendlyErrorContext context,
  ) {
    final flow = switch (context) {
      FriendlyErrorContext.authLogin ||
      FriendlyErrorContext.authRegister => OfflineProductFlow.authentication,
      FriendlyErrorContext.authProfile => OfflineProductFlow.profileSettings,
      FriendlyErrorContext.deckGenerate =>
        OfflineProductFlow.deckGenerateImport,
      FriendlyErrorContext.deckSave => OfflineProductFlow.deckEdit,
      FriendlyErrorContext.deckDetails ||
      FriendlyErrorContext.deckValidate => OfflineProductFlow.deckRead,
      FriendlyErrorContext.deckOptimize => OfflineProductFlow.deckOptimize,
      FriendlyErrorContext.deckPricing => OfflineProductFlow.marketplace,
      FriendlyErrorContext.setsCatalog ||
      FriendlyErrorContext.setCards => OfflineProductFlow.cardCatalog,
      FriendlyErrorContext.tradeList ||
      FriendlyErrorContext.tradeDetail ||
      FriendlyErrorContext.tradeCreate ||
      FriendlyErrorContext.tradeAction => OfflineProductFlow.trades,
      FriendlyErrorContext.tradeMessage => OfflineProductFlow.directMessages,
      FriendlyErrorContext.directMessage => OfflineProductFlow.directMessages,
      FriendlyErrorContext.binder => OfflineProductFlow.binderMutation,
      FriendlyErrorContext.marketplace => OfflineProductFlow.marketplace,
      FriendlyErrorContext.generic => OfflineProductFlow.genericOnlineAction,
    };
    return offlineContractFor(flow);
  }

  static String? _messageFromBody(
    Object? body, {
    required FriendlyErrorContext context,
  }) {
    if (body is! Map) return null;
    final value = body['error'] ?? body['message'];
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final lower = text.toLowerCase();

    if (lower.contains('invalid credential') ||
        lower.contains('invalid password') ||
        lower.contains('credenciais') ||
        lower.contains('senha inválida') ||
        lower.contains('senha invalida')) {
      return 'Email ou senha inválidos.';
    }

    if (lower.contains('email') &&
        (lower.contains('already') ||
            lower.contains('exists') ||
            lower.contains('uso') ||
            lower.contains('cadastrado'))) {
      return 'Este email já está em uso.';
    }

    if ((lower.contains('username') ||
            lower.contains('usuário') ||
            lower.contains('usuario')) &&
        (lower.contains('already') ||
            lower.contains('exists') ||
            lower.contains('uso') ||
            lower.contains('cadastrado'))) {
      return 'Este nome de usuário já está em uso.';
    }

    if (lower.contains('item') &&
        (lower.contains('available') ||
            lower.contains('dispon') ||
            lower.contains('ownership') ||
            lower.contains('owner'))) {
      return 'Algum item desta proposta não está mais disponível. Atualize e tente novamente.';
    }

    if (lower.contains('status') &&
        (context == FriendlyErrorContext.tradeAction ||
            context == FriendlyErrorContext.tradeCreate)) {
      return 'Esta troca mudou de status. Atualize e tente novamente.';
    }

    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Muitas tentativas em sequência. Aguarde um instante e tente novamente.';
    }

    if (!_looksTechnical(text)) {
      return text;
    }

    return null;
  }

  static bool _looksLikeNetworkError(String lower, String runtimeType) {
    final type = runtimeType.toLowerCase();
    return type.contains('socketexception') ||
        type.contains('clientexception') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed') ||
        lower.contains('network is unreachable') ||
        lower.contains('xmlhttprequest error');
  }

  static bool _looksLikeAiUnavailable(String lower) {
    return lower.contains('openai') ||
        lower.contains('ai/generate') ||
        lower.contains('ai unavailable') ||
        lower.contains('quota') ||
        lower.contains('model');
  }

  static bool _looksTechnical(String text) {
    final lower = text.toLowerCase();
    return lower.contains('exception') ||
        lower.contains('stacktrace') ||
        lower.contains('stack trace') ||
        lower.contains('dioexception') ||
        lower.contains('requestoptions') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('stateerror') ||
        lower.contains('format exception') ||
        lower.contains('http ') ||
        lower.contains('statuscode') ||
        lower.contains('status code') ||
        lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('/auth/') ||
        lower.contains('/decks') ||
        lower.contains('/trades') ||
        lower.contains('/sets') ||
        lower.contains('/cards') ||
        lower.contains('trace') ||
        lower.contains('package:') ||
        lower.contains('dart:');
  }
}
