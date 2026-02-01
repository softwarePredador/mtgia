import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/deck_provider.dart';

class DeckImportScreen extends StatefulWidget {
  const DeckImportScreen({super.key});

  @override
  State<DeckImportScreen> createState() => _DeckImportScreenState();
}

class _DeckImportScreenState extends State<DeckImportScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _listController = TextEditingController();
  final _commanderController = TextEditingController();
  
  String _selectedFormat = 'commander';
  bool _isImporting = false;
  List<String> _notFoundLines = [];
  List<String> _warnings = [];
  int _cardsImported = 0;
  String? _error;

  final _formats = [
    'commander',
    'standard',
    'modern',
    'pioneer',
    'legacy',
    'vintage',
    'pauper',
    'brawl',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _listController.dispose();
    _commanderController.dispose();
    super.dispose();
  }

  bool get _isCommanderFormat => 
      _selectedFormat == 'commander' || _selectedFormat == 'brawl';

  Future<void> _importDeck() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o nome do deck')),
      );
      return;
    }

    if (_listController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole a lista de cartas')),
      );
      return;
    }

    setState(() {
      _isImporting = true;
      _error = null;
      _notFoundLines = [];
      _warnings = [];
    });

    final provider = context.read<DeckProvider>();
    final result = await provider.importDeckFromList(
      name: _nameController.text,
      format: _selectedFormat,
      list: _listController.text,
      description: _descriptionController.text.isNotEmpty 
          ? _descriptionController.text 
          : null,
      commander: _commanderController.text.isNotEmpty 
          ? _commanderController.text 
          : null,
    );

    if (!mounted) return;

    setState(() {
      _isImporting = false;
      _notFoundLines = List<String>.from(result['not_found_lines'] ?? []);
      _warnings = List<String>.from(result['warnings'] ?? []);
      _cardsImported = result['cards_imported'] ?? 0;
    });

    if (result['success'] == true) {
      final deck = result['deck'];
      
      // Se houve cartas não encontradas, mostra resultado com opção de editar
      if (_notFoundLines.isNotEmpty) {
        _showResultDialog(
          success: true,
          deckId: deck?['id'],
          cardsImported: _cardsImported,
          notFound: _notFoundLines,
          warnings: _warnings,
        );
      } else {
        // Tudo ok, vai direto pro deck
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deck importado com $_cardsImported cartas!'),
            backgroundColor: Colors.green,
          ),
        );
        if (deck?['id'] != null) {
          context.go('/decks/${deck['id']}');
        } else {
          context.go('/decks');
        }
      }
    } else {
      setState(() {
        _error = result['error'];
      });
      
      // Se houve erro mas tem cartas não encontradas, mostra pra ajudar
      if (_notFoundLines.isNotEmpty) {
        _showResultDialog(
          success: false,
          notFound: _notFoundLines,
          error: _error,
        );
      }
    }
  }

  void _showResultDialog({
    required bool success,
    String? deckId,
    int cardsImported = 0,
    List<String> notFound = const [],
    List<String> warnings = const [],
    String? error,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.warning,
              color: success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(success ? 'Importação Concluída' : 'Atenção'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (success) ...[
                Text(
                  '✅ $cardsImported cartas importadas com sucesso!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              if (error != null) ...[
                Text(
                  '❌ $error',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              
              if (warnings.isNotEmpty) ...[
                const Text(
                  '⚠️ Avisos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                ...warnings.map((w) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $w'),
                )),
                const SizedBox(height: 16),
              ],
              
              if (notFound.isNotEmpty) ...[
                Text(
                  '❓ ${notFound.length} cartas não encontradas:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: notFound.map((line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.close, size: 16, color: Colors.red),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dica: Verifique a ortografia ou tente usar o nome em inglês.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!success)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Corrigir Lista'),
            ),
          if (success) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Volta pra lista de decks
                context.go('/decks');
              },
              child: const Text('Ver Decks'),
            ),
            if (deckId != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/decks/$deckId');
                },
                child: const Text('Abrir Deck'),
              ),
          ],
        ],
      ),
    );
  }

  void _pasteExample() {
    _listController.text = '''1 Sol Ring
1 Arcane Signet
1 Command Tower
1 Lightning Greaves
4 Island
4 Mountain
1 Counterspell''';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colar Lista de Cartas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/decks'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instruções
            Card(
              color: theme.colorScheme.secondary.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Dica',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cole a lista de cartas copiada de sites como:\n'
                      'Moxfield, Archidekt, TappedOut, EDHRec...\n\n'
                      'Formatos aceitos:\n'
                      '• "1 Sol Ring" ou "1x Sol Ring"\n'
                      '• "4 Lightning Bolt (m10)" - com set\n'
                      '• "1 Krenko [Commander]" - marca comandante',
                      style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Nome do Deck
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Deck *',
                hintText: 'Ex: Urza Artifacts',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            
            const SizedBox(height: 16),

            // Formato
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              decoration: const InputDecoration(
                labelText: 'Formato *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _formats.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f[0].toUpperCase() + f.substring(1)),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedFormat = value);
                }
              },
            ),
            
            const SizedBox(height: 16),

            // Comandante (só para Commander/Brawl)
            if (_isCommanderFormat) ...[
              TextField(
                controller: _commanderController,
                decoration: const InputDecoration(
                  labelText: 'Comandante (opcional)',
                  hintText: 'Ex: Urza, Lord High Artificer',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                  helperText: 'Ou marque na lista com [Commander]',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Descrição
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                hintText: 'Ex: Deck focado em artefatos...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),

            // Lista de Cartas
            Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Lista de Cartas *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _pasteExample,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Exemplo'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _listController,
              decoration: InputDecoration(
                hintText: 'Cole sua lista aqui...\n\n1 Sol Ring\n1 Arcane Signet\n4 Island\n...',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              maxLines: 15,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: theme.colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Contador de linhas
            Text(
              '${_listController.text.split('\n').where((l) => l.trim().isNotEmpty).length} linhas',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),

            // Erro
            if (_error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.withOpacity(0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botão Importar
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importDeck,
                icon: _isImporting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isImporting ? 'Criando deck...' : 'Criar Deck com esta Lista',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
