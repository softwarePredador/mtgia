import 'dart:io';

import '../lib/database.dart';

Future<void> main() async {
  final db = Database();
  await db.connect();
  final conn = db.connection;

  try {
    print('Lendo o script SQL...');
    final sqlScript = await File('database_setup.sql').readAsString();
    
    // Separa os comandos SQL pelo ponto e vírgula
    final commands = sqlScript.split(';').where((s) => s.trim().isNotEmpty).toList();

    print('Executando ${commands.length} comandos SQL...');

    // Executa cada comando individualmente
    for (final command in commands) {
      await conn.execute(command);
    }
    
    print('Tabelas criadas com sucesso!');
  } catch (e) {
    print('Ocorreu um erro ao executar o script SQL: $e');
  } finally {
    await conn.close();
    print('Conexão com o banco de dados fechada.');
  }
}
