import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../models/commercial_launch_policy.dart';
import '../models/manaloom_plan.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class CommercialCheckoutResult {
  const CommercialCheckoutResult({
    required this.activated,
    required this.requiresExternalPayment,
    required this.message,
    this.checkoutUrl,
  });

  final bool activated;
  final bool requiresExternalPayment;
  final String message;
  final String? checkoutUrl;
}

class CommercialProvider extends ChangeNotifier {
  CommercialProvider({
    SharedPreferencesLoader? preferencesLoader,
    DateTime Function()? now,
    ApiClient? apiClient,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _now = now ?? DateTime.now,
       _apiClient = apiClient ?? ApiClient();

  static const _planKey = 'manaloom.commercial.plan';
  static const _usagePeriodKey = 'manaloom.commercial.ai_usage_period';
  static const _usageCountKey = 'manaloom.commercial.ai_usage_count';

  final SharedPreferencesLoader _preferencesLoader;
  final DateTime Function() _now;
  final ApiClient _apiClient;

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;
  Future<void>? _remoteRefreshFuture;
  Future<void>? _sessionResetFuture;
  int _remoteRefreshGeneration = 0;
  bool _isLoaded = false;
  bool _isRemoteSynced = false;
  bool _isRefreshingRemote = false;
  String? _lastRemoteError;
  ManaLoomPlanTier _tier = ManaLoomPlanTier.free;
  String _periodKey = _periodFrom(DateTime.now());
  int _usedAiActions = 0;
  int? _monthlyAiLimitOverride;

  bool get isLoaded => _isLoaded;
  bool get isRemoteSynced => _isRemoteSynced;
  bool get isRefreshingRemote => _isRefreshingRemote;
  String? get lastRemoteError => _lastRemoteError;
  ManaLoomPlanTier get tier => _tier;
  ManaLoomPlan get plan => ManaLoomPlan.forTier(_tier);
  bool get isPro => _tier == ManaLoomPlanTier.pro;
  String get periodKey => _periodKey;
  int get usedAiActions => _usedAiActions;
  int get monthlyAiLimit => _monthlyAiLimitOverride ?? plan.monthlyAiLimit;
  int get remainingAiActions =>
      (monthlyAiLimit - _usedAiActions).clamp(0, monthlyAiLimit);
  bool get canUseAi => remainingAiActions > 0;

  AiUsageSnapshot get usageSnapshot => AiUsageSnapshot(
    plan: plan,
    periodKey: _periodKey,
    used: _usedAiActions,
    limitOverride: _monthlyAiLimitOverride,
  );

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

  Future<void> refreshFromServer() {
    final reset = _sessionResetFuture;
    if (reset != null) {
      return reset.then((_) => refreshFromServer());
    }
    final existing = _remoteRefreshFuture;
    if (existing != null) return existing;

    final generation = _remoteRefreshGeneration;
    final refresh = _refreshFromServer(generation);
    _remoteRefreshFuture = refresh;
    return refresh.whenComplete(() {
      if (identical(_remoteRefreshFuture, refresh)) {
        _remoteRefreshFuture = null;
      }
    });
  }

  Future<void> _refreshFromServer(int generation) async {
    await load();
    if (generation != _remoteRefreshGeneration) return;
    _isRefreshingRemote = true;
    _lastRemoteError = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/users/me/plan');
      if (generation != _remoteRefreshGeneration) return;
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final payload = response.data as Map<String, dynamic>;
        final planPayload = payload['plan'];
        if (planPayload is Map<String, dynamic>) {
          await _applyRemotePlan(planPayload);
          _isRemoteSynced = true;
          _lastRemoteError = null;
        } else {
          _isRemoteSynced = false;
          _lastRemoteError = 'O servidor retornou um plano inválido.';
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _isRemoteSynced = false;
      } else {
        _isRemoteSynced = false;
        _lastRemoteError = 'Não foi possível sincronizar o plano agora.';
      }
    } catch (error) {
      if (generation != _remoteRefreshGeneration) return;
      _isRemoteSynced = false;
      _lastRemoteError = 'Plano remoto indisponível.';
      debugPrint('[CommercialProvider] refreshFromServer failed: $error');
    } finally {
      if (generation == _remoteRefreshGeneration) {
        _isRefreshingRemote = false;
        notifyListeners();
      }
    }
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

  Future<CommercialCheckoutResult> startProCheckout() async {
    await load();
    if (CommercialLaunchPolicy.isFreeBeta) {
      return const CommercialCheckoutResult(
        activated: false,
        requiresExternalPayment: false,
        message: CommercialLaunchPolicy.betaCheckoutMessage,
      );
    }
    try {
      final response = await _apiClient.post('/users/me/plan/checkout', {
        'plan_name': ManaLoomPlanTier.pro.id,
      });
      final data =
          response.data is Map<String, dynamic>
              ? response.data as Map<String, dynamic>
              : const <String, dynamic>{};

      final planPayload = data['plan'];
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          planPayload is Map<String, dynamic>) {
        await _applyRemotePlan(planPayload);
        _isRemoteSynced = true;
        notifyListeners();
        return CommercialCheckoutResult(
          activated: true,
          requiresExternalPayment: false,
          message: data['message']?.toString() ?? 'Plano Pro ativado.',
          checkoutUrl: data['checkout_url']?.toString(),
        );
      }

      final checkoutUrl = data['checkout_url']?.toString();
      return CommercialCheckoutResult(
        activated: false,
        requiresExternalPayment: true,
        checkoutUrl:
            checkoutUrl == null || checkoutUrl.trim().isEmpty
                ? null
                : checkoutUrl,
        message:
            data['message']?.toString() ??
            'O ManaLoom Pro ainda não está disponível para contratação.',
      );
    } catch (error) {
      debugPrint('[CommercialProvider] startProCheckout failed: $error');
      return const CommercialCheckoutResult(
        activated: false,
        requiresExternalPayment: true,
        message: 'Não foi possível iniciar o checkout agora.',
      );
    }
  }

  Future<void> clearRemoteSnapshot() {
    _remoteRefreshGeneration += 1;
    _remoteRefreshFuture = null;
    final existing = _sessionResetFuture;
    if (existing != null) return existing;

    final reset = _clearRemoteSnapshot();
    _sessionResetFuture = reset;
    return reset.whenComplete(() {
      if (identical(_sessionResetFuture, reset)) {
        _sessionResetFuture = null;
      }
    });
  }

  Future<void> _clearRemoteSnapshot() async {
    await load();
    _isRemoteSynced = false;
    _isRefreshingRemote = false;
    _lastRemoteError = null;
    _tier = ManaLoomPlanTier.free;
    _periodKey = _periodFrom(_now());
    _usedAiActions = 0;
    _monthlyAiLimitOverride = null;
    final prefs = _preferences ?? await _preferencesLoader();
    _preferences = prefs;
    await prefs.setString(_planKey, _tier.id);
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

  Future<void> _applyRemotePlan(Map<String, dynamic> planPayload) async {
    final tier = ManaLoomPlanTierLabel.fromId(
      planPayload['plan_name']?.toString(),
    );
    final used = _readInt(planPayload['ai_requests_used']) ?? 0;
    final limit =
        _readInt(planPayload['ai_monthly_limit']) ??
        ManaLoomPlan.forTier(tier).monthlyAiLimit;

    _tier = tier;
    _usedAiActions = used.clamp(0, limit);
    _monthlyAiLimitOverride = limit;
    final remotePeriodStart = DateTime.tryParse(
      planPayload['usage_period_start']?.toString() ?? '',
    );
    _periodKey = _periodFrom(remotePeriodStart?.toUtc() ?? _now());

    final prefs = _preferences ?? await _preferencesLoader();
    _preferences = prefs;
    await prefs.setString(_planKey, tier.id);
    await _saveUsage();
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _periodFrom(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }
}
