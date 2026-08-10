import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'counterproposal is linked and replaces the pending offer atomically',
    () {
      final source = File('routes/trades/index.dart').readAsStringSync();

      expect(source, contains("body['counter_to_trade_id']"));
      expect(
        source,
        contains("counteredTrade['receiver_id'].toString() != userId"),
      );
      expect(
        source,
        contains("counteredTrade['sender_id'].toString() != receiverId"),
      );
      expect(source, contains("counteredTrade['status'] != 'pending'"));
      expect(source, contains("counteredTrade['type'] != 'trade'"));
      expect(source, contains('FOR UPDATE'));
      expect(source, contains("SET status = 'declined'"));
      expect(source, contains('Contraproposta da proposta'));
      expect(source, contains('Contraproposta enviada em uma nova negociação'));
      expect(source, contains("'counter_to_trade_id': counterToTradeId"));

      final declineIndex = source.indexOf("SET status = 'declined'");
      final availabilityIndex = source.indexOf('_requireTradeItemsAvailable(');
      final offerIndex = source.indexOf('INSERT INTO trade_offers (');
      expect(declineIndex, greaterThan(0));
      expect(availabilityIndex, greaterThan(declineIndex));
      expect(offerIndex, greaterThan(availabilityIndex));
    },
  );
}
