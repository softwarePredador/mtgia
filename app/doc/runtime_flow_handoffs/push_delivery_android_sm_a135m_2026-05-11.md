# Push Delivery Android SM A135M - 2026-05-11

## Resultado

**PASS** para entrega real FCM no Android fisico `SM A135M`
(`R58T300SREH`) contra o backend publico.

## Ambiente

- Data/hora: 2026-05-11, ~10:47 BRT.
- Device alvo: `SM A135M`, adb `R58T300SREH`, Android 14/API 34.
- Backend usado pelo app:
  `https://evolution-cartinhas.8ktevp.easypanel.host`.
- Backend `/health`: `healthy`, `git_sha=70303922a57bd1d2f91115f5cb5977ee8c3c123d`.
- Branch local: `master`, sincronizada com `origin/master` em
  `7030392 Implement realtime notifications refresh`.

## Descoberta de device

`flutter devices` listou `SM A135M (mobile) • R58T300SREH • android-arm •
Android 14 (API 34)`.

`adb devices -l` confirmou `R58T300SREH device usb:2-1 product:a13ub
model:SM_A135M device:a13`.

## Comando runtime

O comando Flutter executado pelo orquestrador host foi:

```bash
cd app
flutter test integration_test/android_fcm_delivery_runtime_test.dart \
  -d R58T300SREH \
  --dart-define=API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --dart-define=PUBLIC_API_BASE_URL=https://evolution-cartinhas.8ktevp.easypanel.host \
  --reporter expanded \
  --no-version-check
```

O orquestrador host apenas fez a parte que o `integration_test` no device nao
consegue fazer sozinho: enviar `KEYCODE_HOME`, gerar uma nova
`direct_message` por segundo usuario QA via API publica e tocar na notificacao
do sistema Android correspondente. Nenhum token, JWT ou senha foi registrado.

## Prova

- Firebase inicializou no app.
- Permissao de notificacao ficou `authorized`.
- `PUT /users/me/fcm-token` retornou `200` e o log registrou somente
  `token_present=true`.
- Evento real `direct_message` em foreground chegou via FCM:
  `FCM_FOREGROUND_CALLBACK type=direct_message has_reference=true`.
- Badge/lista atualizaram na tela de Notificacoes sem sair da tela:
  `/notifications/count`, `/notifications` e `/conversations` retornaram `200`.
- Com o app em background, nova `direct_message` real gerou notificacao do
  sistema Android no canal `manaloom_notifications`.
- O toque na notificacao disparou `FCM_TAP_CALLBACK type=direct_message`,
  navegou para `/messages/:conversationId` e carregou a conversa/mensagem.
- Resultado final do harness: `00:32 +1: All tests passed!`.

## Evidencias locais

Arquivos sanitizados em
`app/doc/runtime_flow_proofs_2026-05-11_android_fcm_sm_a135m/`:

- `android_fcm_delivery_flutter_test.log`
- `android_fcm_delivery_logcat_sanitized.log`
- `android_fcm_delivery_notification_dump_sanitized.log`
- `android_notification_shade_uiautomator.xml`

Os logs preservam prova operacional e removem tokens, UUIDs completos e
conteudo de notificacoes de outros apps.

## O que foi real

- App Flutter debug instalado e executado no Android fisico.
- Backend publico real.
- Registro de FCM token real.
- Entrega FCM real em foreground.
- Notificacao de sistema Android real em background.
- Tap real na notificacao navegando pelo payload app-facing
  `type/reference_id`.

## O que foi mockado

Nada no app/backend/FCM foi mockado. O orquestrador apenas automatizou a acao
externa de background, criacao do evento e toque na notificacao.

## Ajustes aplicados

- `AndroidManifest.xml` declara `android.permission.POST_NOTIFICATIONS`.
- `MainActivity` cria o canal nativo `manaloom_notifications`, alinhado ao
  `channel_id` usado pelo backend FCM.
- `android_fcm_delivery_runtime_test.dart` passou a aguardar um gatilho externo
  para o evento de background, evitando falso "background" enquanto o app ainda
  estava em foreground.

## Bloqueios / riscos

Nenhum bloqueio atual. Nao foram observados crash, ANR, tela branca, overflow,
4xx/5xx, timeout, permissao negada, token ausente ou erro cru no fluxo
validado.

## Menor proxima acao

Manter este harness para novas alteracoes de push e repetir a prova no
proximo build candidato Android.
