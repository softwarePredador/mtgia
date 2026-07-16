# ManaLoom Mobile Release Runbook

Data: 2026-07-15
Status: `ANDROID_SIGNED_AND_PUBLISHED`

## Android

Build reproduzivel, sempre a partir do mesmo SHA de `origin/master`:

```sh
./scripts/manaloom_build_android_release.sh
```

Publicacao no servidor ManaLoom:

```sh
MANALOOM_RELEASE_SOURCE_SHA=<sha-do-build> \
MANALOOM_RELEASE_VERSION=<versao> \
./scripts/manaloom_publish_android_release.sh
```

Release atual:

- APK: `https://evolution-manaloom-web-public.2ta7qx.easypanel.host/downloads/manaloom-android.apk`;
- manifest: `https://evolution-manaloom-web-public.2ta7qx.easypanel.host/downloads/release.json`;
- servico: `evolution_manaloom-releases`;
- AAB: backup privado no servidor, nunca exposto pelo Nginx.

Contratos de seguranca:

- keystore fora do Git em `~/.manaloom/signing/android/`;
- senhas no Keychain do macOS;
- `app/android/key.properties` local e ignorado;
- backup do keystore e do AAB em `/opt/manaloom/` no servidor novo;
- APK e AAB verificados antes da publicacao;
- download publico comparado por SHA-256.

Upload certificate SHA-256:

```text
15:F8:D2:0C:A2:89:92:A0:CE:01:0D:6C:0B:45:F3:65:FE:10:E6:7C:C3:49:B6:34:DA:F0:45:64:A5:0E:3C:28
```

## iOS

O bundle id e `com.mtgia.mtgApp`. A publicacao exige que esse App ID exista em
uma Apple Developer Team pertencente ao ManaLoom e que a conta esteja carregada
no Xcode. Nao assinar o ManaLoom com certificados de outros produtos ou
empresas apenas para produzir um IPA.

O build release sem assinatura foi validado e preservado na area privada do
servidor. Ele nao e instalavel nem publicavel ate o provisioning correto ser
fornecido.
