import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/core/services/message_draft_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('persists text and idempotency key per social channel', () async {
    final store = MessageDraftStore();

    await store.save(
      'direct:conversation-1',
      const MessageDraft(
        text: 'proposta de troca',
        clientRequestId: 'request-stable-1',
      ),
    );

    final restored = await store.load('direct:conversation-1');
    expect(restored.text, 'proposta de troca');
    expect(restored.clientRequestId, 'request-stable-1');
    expect((await store.load('trade:trade-1')).isEmpty, isTrue);
  });

  test('clears persisted draft after successful delivery', () async {
    final store = MessageDraftStore();
    await store.save('trade:trade-1', const MessageDraft(text: 'envio amanhã'));

    await store.clear('trade:trade-1');

    expect((await store.load('trade:trade-1')).isEmpty, isTrue);
  });

  test('invalid stored payload fails closed as an empty draft', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'manaloom.social_message_draft.v1.ZGlyZWN0OmNvbnZlcnNhdGlvbi0x',
      '{invalid',
    );
    final store = MessageDraftStore();

    final restored = await store.load('direct:conversation-1');

    expect(restored.isEmpty, isTrue);
  });
}
