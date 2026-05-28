import 'package:dart_frog/dart_frog.dart';

import '../[id].dart' as community_deck_route;

/// Dedicated route for GET /community/decks/following.
///
/// The dynamic `/community/decks/:id` branch still accepts id="following" for
/// backward compatibility, but this file makes the app-facing collection route
/// explicit for route discovery and contract tests.
Future<Response> onRequest(RequestContext context) {
  return community_deck_route.getFollowingFeed(context);
}
