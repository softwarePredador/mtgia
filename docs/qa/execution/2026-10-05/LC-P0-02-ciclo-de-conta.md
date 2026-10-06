# Receipt — LC-P0-02: ciclo de login, logout e troca de conta — 2026-10-05

- Branch `claude/frente-contador-de-vida-ibnawb`. Raia do app. Nada tocou a produção.
- `AuthProvider.notifyListeners` liga o escopo antes de avisar os listeners: autenticado abre o namespace do usuário, não autenticado fecha. Assim o roteador nunca monta o contador com a conta anterior.
- Logout e expiração do token fecham o namespace sem apagar: a conta reencontra a mesa no próximo login. `logout(purgeLocalAccountData: true)`, usado pela exclusão de conta no perfil, apaga só os dados daquela conta neste aparelho. Restart reabre o namespace da conta salva.

## Evidência

`app/test/features/auth/providers/auth_provider_life_counter_scope_test.dart`, 4/4: logout fecha A, B começa limpo e A recupera a mesa; expiração fecha sem apagar e barra a escrita atrasada; exclusão apaga a conta; restart reabre.

Falta: o roteiro em Android físico (A → logout → B, restart, token expirado) no lote do `BT-UIEV-001`.
