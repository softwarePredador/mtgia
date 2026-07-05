int estimateRecommendationBracketPowerLevel({
  required int totalCards,
  required int rampCount,
  required int drawCount,
  required int removalCount,
  required double averageCmc,
}) {
  if (totalCards < 40) return 1;
  if (rampCount >= 14 &&
      drawCount >= 12 &&
      removalCount >= 8 &&
      averageCmc < 2.6) {
    return 5;
  }
  if (rampCount >= 12 && drawCount >= 10 && averageCmc < 2.8) return 4;
  if (rampCount >= 10 && drawCount >= 8 && removalCount >= 6) return 3;
  return 2;
}
