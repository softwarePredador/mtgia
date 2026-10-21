import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/api/api_client.dart';
import 'package:manaloom/features/battle/services/interactive_battle_service.dart';

/// Um 409 do servidor vira mensagem para quem está jogando. A distinção
/// importa: uma diz que o app se recupera sozinho, a outra parece falha.
class _ErrorApiClient extends ApiClient {
  _ErrorApiClient(this.code);

  final String code;

  @override
  Future<ApiResponse> get(String endpoint) async =>
      ApiResponse(409, {'error': code});
}

void main() {
  const recoverable = 'A mesa avançou antes desta escolha. O estado será atualizado.';

  Future<InteractiveBattleGatewayException> failureFor(String code) async {
    final service = InteractiveBattleService(apiClient: _ErrorApiClient(code));
    try {
      await service.get('session-1');
      fail('esperava InteractiveBattleGatewayException para $code');
    } on InteractiveBattleGatewayException catch (error) {
      return error;
    }
  }

  test('not_waiting recebe a mesma mensagem de recuperação que action_stale', () async {
    // É o erro que o servidor realmente devolve num duplo toque ou quando a
    // rede demora: a primeira ação já pôs a sessão em `action_pending`, e a
    // segunda bate na checagem de status antes do UPDATE condicional.
    final notWaiting = await failureFor('interactive_battle_not_waiting');
    expect(notWaiting.message, recoverable);
  });

  test('action_stale continua com a mensagem de recuperação', () async {
    final stale = await failureFor('interactive_battle_action_stale');
    expect(stale.message, recoverable);
  });

  test('erro desconhecido NÃO recebe a mensagem de recuperação', () async {
    // Guarda contra "consertar" isto alargando o ramo até engolir tudo:
    // prometer recuperação automática onde ela não existe é pior que o
    // fallback genérico.
    final unknown = await failureFor('interactive_battle_engine_exploded');
    expect(unknown.message, isNot(recoverable));
  });
}
