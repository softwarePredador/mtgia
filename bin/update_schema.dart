import 'dart:io';
import '../lib/database.dart';

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    print('Iniciando atualização do schema...');

    // 1. Dropar tabelas que precisam ser recriadas (Decks e DeckCards)
    // Não vamos dropar 'cards' para manter os dados.
    print('Removendo tabelas antigas (decks, deck_cards, matchups, simulations)...');
    await conn.execute('DROP TABLE IF EXISTS battle_simulations');
    await conn.execute('DROP TABLE IF EXISTS deck_matchups');
    await conn.execute('DROP TABLE IF EXISTS deck_cards');
    await conn.execute('DROP TABLE IF EXISTS decks');

    // 2. Ler e executar o script de setup completo
    print('Lendo database_setup.sql...');
    final sqlScript = await File('database_setup.sql').readAsString();
    
    // Separa os comandos SQL pelo ponto e vírgula
    final commands = sqlScript.split(';').where((s) => s.trim().isNotEmpty).toList();

    print('Executando criação das novas tabelas (Users, Rules, Legalities, Decks)...');

    for (final command in commands) {
      try {
        await conn.execute(command);
      } catch (e) {
        // Ignora erro se a tabela já existe (ex: cards), mas mostra outros erros
        if (!e.toString().contains('already exists')) {
          print('Aviso ao executar comando: $e');
        }
      }
    }
    
    print('Schema atualizado com sucesso!');
  } catch (e) {
    print('Erro fatal na atualização: $e');
  } finally {
    await conn.close();
  }
}
