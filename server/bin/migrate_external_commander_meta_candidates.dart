import '../lib/database.dart';

Future<void> main() async {
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
