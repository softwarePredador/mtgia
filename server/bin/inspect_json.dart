import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final file = File('AtomicCards.json');
  if (!await file.exists()) {
    print('Arquivo não encontrado.');
    return;
  }

  final content = await file.readAsString();
  final Map<String, dynamic> data = jsonDecode(content);
  final Map<String, dynamic> cardsMap = data['data'];

  if (cardsMap.isNotEmpty) {
    final firstKey = cardsMap.keys.first;
    final firstValue = cardsMap[firstKey];
    
    print('Chave: $firstKey');
    print('Tipo do Valor: ${firstValue.runtimeType}');
    
    if (firstValue is List && firstValue.isNotEmpty) {
      print('Primeiro item da lista:');
      print(jsonEncode(firstValue[0]));
    }
  }
}
