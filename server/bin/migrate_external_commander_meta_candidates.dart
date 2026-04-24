import '../lib/database.dart';

class ExternalCommanderMetaMigrationConfig {
  const ExternalCommanderMetaMigrationConfig({
    required this.apply,
    required this.showHelp,
  });

  final bool apply;
  final bool showHelp;

  bool get dryRun => !apply;

  static ExternalCommanderMetaMigrationConfig parse(List<String> args) {
    var apply = false;
    var dryRun = false;
    var showHelp = false;

    for (final arg in args) {
      if (arg == '--apply') {
        apply = true;
        continue;
      }
      if (arg == '--dry-run') {
        dryRun = true;
        continue;
      }
      if (arg == '--help' || arg == '-h') {
        showHelp = true;
      }
    }

    if (apply && dryRun) {
      throw ArgumentError('Use apenas um modo: --apply ou --dry-run.');
    }

    return ExternalCommanderMetaMigrationConfig(
      apply: apply,
      showHelp: showHelp,
    );
  }
}

void _printUsage() {
  print('Uso: dart run bin/migrate_external_commander_meta_candidates.dart [--apply]');
  print('');
  print('Sem --apply o comando roda em dry-run e nao altera o banco.');
}

Future<void> main(List<String> args) async {
  final config = ExternalCommanderMetaMigrationConfig.parse(args);
  if (config.showHelp) {
    _printUsage();
    return;
  }

  if (config.dryRun) {
    print('Migration dry-run only.');
    print('Plano:');
    print('- garantir tabela external_commander_meta_candidates');
    print('- garantir coluna legal_status');
    print('- recriar chk_external_commander_meta_status com valor staged');
    print('- garantir indices de suporte');
    print('Nenhuma alteracao foi aplicada. Use --apply para escrever no banco.');
    return;
  }

  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    print('Criando tabela external_commander_meta_candidates...');
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS external_commander_meta_candidates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        source_name TEXT NOT NULL,
        source_host TEXT,
        source_url TEXT UNIQUE NOT NULL,
        deck_name TEXT NOT NULL,
        commander_name TEXT,
        partner_commander_name TEXT,
        format TEXT NOT NULL DEFAULT 'commander',
        subformat TEXT,
        archetype TEXT,
        card_list TEXT NOT NULL,
        placement TEXT,
        color_identity TEXT[] DEFAULT '{}',
        is_commander_legal BOOLEAN,
        validation_status TEXT NOT NULL DEFAULT 'candidate',
        legal_status TEXT,
        validation_notes TEXT,
        research_payload JSONB NOT NULL DEFAULT '{}',
        imported_by TEXT NOT NULL DEFAULT 'copilot_cli_web_agent',
        promoted_to_meta_decks_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT chk_external_commander_meta_status CHECK (
          validation_status IN ('candidate', 'staged', 'validated', 'rejected', 'promoted')
        )
      )
    ''');
    await conn.execute('''
      ALTER TABLE external_commander_meta_candidates
      ADD COLUMN IF NOT EXISTS legal_status TEXT
    ''');

    await conn.execute('''
      ALTER TABLE external_commander_meta_candidates
      DROP CONSTRAINT IF EXISTS chk_external_commander_meta_status
    ''');

    await conn.execute('''
      ALTER TABLE external_commander_meta_candidates
      ADD CONSTRAINT chk_external_commander_meta_status CHECK (
        validation_status IN ('candidate', 'staged', 'validated', 'rejected', 'promoted')
      )
    ''');

    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_external_commander_meta_status
      ON external_commander_meta_candidates (validation_status)
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_external_commander_meta_subformat
      ON external_commander_meta_candidates (subformat)
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_external_commander_meta_commander
      ON external_commander_meta_candidates (commander_name)
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_external_commander_meta_color_identity
      ON external_commander_meta_candidates USING GIN (color_identity)
    ''');

    print('Tabela external_commander_meta_candidates pronta.');
  } catch (e) {
    print('Erro ao migrar banco: $e');
    rethrow;
  } finally {
    await conn.close();
  }
}
