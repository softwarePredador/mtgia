import '../lib/database.dart';

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    print('Garantindo colunas derivadas em meta_decks...');
    await conn.execute('ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS placement TEXT');
    await conn.execute(
      'ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS commander_name TEXT',
    );
    await conn.execute(
      'ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS partner_commander_name TEXT',
    );
    await conn.execute(
      'ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS shell_label TEXT',
    );
    await conn.execute(
      'ALTER TABLE meta_decks ADD COLUMN IF NOT EXISTS strategy_archetype TEXT',
    );
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_meta_decks_commander_name
      ON meta_decks (commander_name)
      WHERE format IN ('EDH', 'cEDH') AND commander_name IS NOT NULL
    ''');
    await conn.execute('''
      CREATE INDEX IF NOT EXISTS idx_meta_decks_partner_commander_name
      ON meta_decks (partner_commander_name)
      WHERE format IN ('EDH', 'cEDH') AND partner_commander_name IS NOT NULL
    ''');
    print('Colunas e indices garantidos com sucesso!');
  } catch (e) {
    print('Erro ao migrar banco: $e');
  } finally {
    await conn.close();
  }
}
