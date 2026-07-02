import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/manaloom_plan.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class CommercialProvider extends ChangeNotifier {
  CommercialProvider({
    SharedPreferencesLoader? preferencesLoader,
    DateTime Function()? now,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now;

  static const _planKey = 'manaloom.commercial.plan';
  static const _usagePeriodKey = 'manaloom.commercial.ai_usage_period';
  static const _usageCountKey = 'manaloom.commercial.ai_usage_count';

  final SharedPreferencesLoader _preferencesLoader;
  final DateTime Function() _now;

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;
  bool _isLoaded = false;
  ManaLoomPlanTier _tier = ManaLoomPlanTier.free;
  String _periodKey = _periodFrom(DateTime.now());
  int _usedAiActions = 0;

  bool get isLoaded => _isLoaded;
  ManaLoomPlanTier get tier => _tier;
  ManaLoomPlan get plan => ManaLoomPlan.forTier(_tier);
  bool get isPro => _tier == ManaLoomPlanTier.pro;
  String get periodKey => _periodKey;
  int get usedAiActions => _usedAiActions;
  int get monthlyAiLimit => plan.monthlyAiLimit;
  int get remainingAiActions =>
      (monthlyAiLimit - _usedAiActions).clamp(0, monthlyAiLimit);
  bool get canUseAi => remainingAiActions > 0;

  AiUsageSnapshot get usageSnapshot =>
      AiUsageSnapshot(plan: plan, periodKey: _periodKey, used: _usedAiActions);

  Future<void> load() {
    if (_isLoaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final prefs = await _preferencesLoader();
    _preferences = prefs;
    _tier = ManaLoomPlanTierLabel.fromId(prefs.getString(_planKey));
    _periodKey = prefs.getString(_usagePeriodKey) ?? _periodFrom(_now());
    _usedAiActions = prefs.getInt(_usageCountKey) ?? 0;
    await _rolloverIfNeeded();
    _isLoaded = true;
    notifyListeners();
  }

  Future<bool> consumeAiAction(AiUsageKind kind) async {
    await load();
    await _rolloverIfNeeded();
    if (!canUseAi) return false;
    _usedAiActions += 1;
    await _saveUsage();
    notifyListeners();
    return true;
  }

  Future<void> setPlan(ManaLoomPlanTier tier) async {
    await load();
    if (_tier == tier) return;
    _tier = tier;
    final prefs = _preferences ?? await _preferencesLoader();
    await prefs.setString(_planKey, tier.id);
    await _rolloverIfNeeded();
    notifyListeners();
  }

  Future<void> resetUsageForCurrentPeriod() async {
    await load();
    _periodKey = _periodFrom(_now());
    _usedAiActions = 0;
    await _saveUsage();
    notifyListeners();
  }

  Future<void> _rolloverIfNeeded() async {
    final currentPeriod = _periodFrom(_now());
    if (_periodKey == currentPeriod) return;
    _periodKey = currentPeriod;
    _usedAiActions = 0;
    await _saveUsage();
  }

  Future<void> _saveUsage() async {
    final prefs = _preferences ?? await _preferencesLoader();
    _preferences = prefs;
    await prefs.setString(_usagePeriodKey, _periodKey);
    await prefs.setInt(_usageCountKey, _usedAiActions);
  }

  static String _periodFrom(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
