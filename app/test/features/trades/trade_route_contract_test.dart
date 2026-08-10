import 'package:flutter_test/flutter_test.dart';
import 'package:manaloom/features/trades/trade_route_contract.dart';

void main() {
  test(
    'canonical marketplace, wishlist and quotes destinations stay distinct',
    () {
      expect(marketplaceRouteLocation, '/collection?tab=1');
      expect(wishlistRouteLocation, '/collection?tab=0&list=want');
      expect(quotesRouteLocation, '/community?tab=3');
      expect({
        marketplaceRouteLocation,
        wishlistRouteLocation,
        quotesRouteLocation,
      }, hasLength(3));
    },
  );

  test('proposal URL preserves receiver, physical item, type and origin', () {
    final location = createTradeRouteLocation(
      receiverId: '11111111-1111-4111-8111-111111111111',
      binderItemId: '22222222-2222-4222-8222-222222222222',
      type: 'mixed',
      source: 'deck_missing',
      deckId: '33333333-3333-4333-8333-333333333333',
    );
    final uri = Uri.parse(location);
    final parsed = TradeProposalDeepLink.fromUri(uri);

    expect(uri.path, '/trades/create/11111111-1111-4111-8111-111111111111');
    expect(parsed.binderItemId, '22222222-2222-4222-8222-222222222222');
    expect(parsed.type, 'mixed');
    expect(parsed.source, 'deck_missing');
    expect(parsed.deckId, '33333333-3333-4333-8333-333333333333');
    expect(parsed.counterTradeId, isNull);
  });

  test('counterproposal URL rebuilds from backend trade reference', () {
    final location = createTradeRouteLocation(
      receiverId: '11111111-1111-4111-8111-111111111111',
      type: 'trade',
      source: 'counter',
      counterTradeId: '44444444-4444-4444-8444-444444444444',
    );
    final uri = Uri.parse(location);
    final parsed = TradeProposalDeepLink.fromUri(uri);

    expect(uri.queryParameters, isNot(contains('item')));
    expect(parsed.type, 'trade');
    expect(parsed.source, 'counter');
    expect(parsed.counterTradeId, '44444444-4444-4444-8444-444444444444');
  });

  test('unsupported type and source fail closed to the safe contract', () {
    final parsed = TradeProposalDeepLink.fromUri(
      Uri.parse('/trades/create/user-1?type=auction&source=unknown'),
    );

    expect(parsed.type, 'trade');
    expect(parsed.source, isNull);
  });
}
