import 'dart:math';

/// Gerenciador de jobs assíncronos de otimização de deck.
///
/// Permite que o endpoint retorne 202 imediatamente enquanto o
/// processamento pesado (IA + múltiplos fallbacks) roda em background.
/// O cliente faz polling via GET /ai/optimize/jobs/:id.
///
/// Armazenamento in-memory (singleton). Jobs expiram após 30 minutos.
class OptimizeJobStore {
  OptimizeJobStore._();

  static final _jobs = <String, OptimizeJob>{};

  /// Cria um novo job e retorna seu ID.
  static String create({
    required String deckId,
    required String archetype,
    String? userId,
  }) {
    _cleanup();
    final id = _generateId();
    _jobs[id] = OptimizeJob(
      id: id,
      deckId: deckId,
      archetype: archetype,
      userId: userId,
    );
    return id;
  }

  /// Busca um job pelo ID.
  static OptimizeJob? get(String id) => _jobs[id];

  /// Atualiza o progresso de um job.
  static void progress(
    String id, {
    required String stage,
    required int stageNumber,
  }) {
    final job = _jobs[id];
    if (job == null) return;
    job.status = 'processing';
    job.stage = stage;
    job.stageNumber = stageNumber;
    job.updatedAt = DateTime.now();
  }

  /// Marca o job como concluído com o resultado.
  static void complete(String id, {required Map<String, dynamic> result}) {
    final job = _jobs[id];
    if (job == null) return;
    job.status = 'completed';
    job.stage = 'Concluído';
    job.result = result;
    job.updatedAt = DateTime.now();
  }

  /// Marca o job como falho.
  static void fail(String id, {required String error}) {
    final job = _jobs[id];
    if (job == null) return;
    job.status = 'failed';
    job.stage = 'Erro';
    job.error = error;
    job.updatedAt = DateTime.now();
  }

  /// Remove jobs com mais de 30 minutos para não vazar memória.
  static void _cleanup() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
    _jobs.removeWhere((_, job) => job.createdAt.isBefore(cutoff));
  }

  static String _generateId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

/// Representa um job de otimização em andamento.
class OptimizeJob {
  final String id;
  final String deckId;
  final String archetype;
  final String? userId;

  String status; // pending, processing, completed, failed
  String stage;
  int stageNumber;
  final int totalStages;

  Map<String, dynamic>? result;
  String? error;

  final DateTime createdAt;
  DateTime updatedAt;

  OptimizeJob({
    required this.id,
    required this.deckId,
    required this.archetype,
    this.userId,
    this.status = 'pending',
    this.stage = 'Iniciando...',
    this.stageNumber = 0,
    this.totalStages = 6,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  bool get isTerminal => status == 'completed' || status == 'failed';

  Map<String, dynamic> toJson() => {
        'job_id': id,
        'deck_id': deckId,
        'archetype': archetype,
        'status': status,
        'stage': stage,
        'stage_number': stageNumber,
        'total_stages': totalStages,
        if (result != null) 'result': result,
        if (error != null) 'error': error,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
