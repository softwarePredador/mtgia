import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../cards/providers/card_provider.dart';
import '../../cards/screens/card_detail_screen.dart';
import '../../decks/models/deck_card_item.dart';

typedef LifeCounterCardSearchProviderFactory = CardProvider Function();

Future<void> showLifeCounterNativeCardSearchSheet(
  BuildContext context, {
  LifeCounterCardSearchProviderFactory? providerFactory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _LifeCounterNativeCardSearchSheet(
        providerFactory: providerFactory,
      );
    },
  );
}

class _LifeCounterNativeCardSearchSheet extends StatefulWidget {
  const _LifeCounterNativeCardSearchSheet({this.providerFactory});

  final LifeCounterCardSearchProviderFactory? providerFactory;

  @override
  State<_LifeCounterNativeCardSearchSheet> createState() =>
      _LifeCounterNativeCardSearchSheetState();
}

class _LifeCounterNativeCardSearchSheetState
    extends State<_LifeCounterNativeCardSearchSheet> {
  static const List<String> _suggestions = <String>[
    'Sol Ring',
    'Command Tower',
    'Cyclonic Rift',
    'Swords to Plowshares',
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(BuildContext context, String query) {
    context.read<CardProvider>().searchCards(query.trim());
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => widget.providerFactory?.call() ?? CardProvider(),
      child: Builder(
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 12,
              ),
              child: FractionallySizedBox(
                heightFactor: 0.92,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundAbyss,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.outlineMuted),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 28,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Card Search',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: AppTheme.fontXxl,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'ManaLoom now owns this shell surface while the Lotus tabletop stays unchanged.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: AppTheme.fontMd,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                              color: AppTheme.textSecondary,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.outlineMuted),
                      Expanded(
                        child: Consumer<CardProvider>(
                          builder: (context, provider, _) {
                            final hasQuery =
                                _controller.text.trim().length >= 3;
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                16,
                              ),
                              children: [
                                TextField(
                                  key: const Key(
                                    'life-counter-native-card-search-input',
                                  ),
                                  controller: _controller,
                                  textInputAction: TextInputAction.search,
                                  onChanged: (value) {
                                    setState(() {});
                                    if (value.trim().length >= 3) {
                                      _runSearch(context, value);
                                    } else {
                                      provider.clearSearch();
                                    }
                                  },
                                  onSubmitted:
                                      (value) => _runSearch(context, value),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search cards',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                    suffixIcon:
                                        _controller.text.isEmpty
                                            ? null
                                            : IconButton(
                                              key: const Key(
                                                'life-counter-native-card-search-clear',
                                              ),
                                              onPressed: () {
                                                _controller.clear();
                                                provider.clearSearch();
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final suggestion in _suggestions)
                                      _CardSearchSuggestionChip(
                                        chipKey: Key(
                                          'life-counter-native-card-search-suggestion-${suggestion.toLowerCase().replaceAll(' ', '-')}',
                                        ),
                                        label: suggestion,
                                        onTap: () {
                                          _controller.text = suggestion;
                                          setState(() {});
                                          _runSearch(context, suggestion);
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                if (!hasQuery)
                                  const Text(
                                    'Type at least 3 letters or use a quick suggestion.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: AppTheme.fontMd,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  )
                                else if (provider.isLoading)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 18),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (provider.errorMessage != null)
                                  Text(
                                    provider.errorMessage!,
                                    key: const Key(
                                      'life-counter-native-card-search-error',
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.error,
                                      fontSize: AppTheme.fontSm,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                else if (provider.searchResults.isEmpty)
                                  Text(
                                    'No card found for "${_controller.text.trim().toUpperCase()}".',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: AppTheme.fontMd,
                                      fontWeight: FontWeight.w600,
                                      height: 1.35,
                                    ),
                                  )
                                else
                                  Column(
                                    key: const Key(
                                      'life-counter-native-card-search-results',
                                    ),
                                    children: [
                                      for (
                                        int index = 0;
                                        index < provider.searchResults.length &&
                                            index < 8;
                                        index += 1
                                      )
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _CardSearchResultTile(
                                            tileKey: Key(
                                              'life-counter-native-card-search-result-$index',
                                            ),
                                            card: provider.searchResults[index],
                                          ),
                                        ),
                                    ],
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CardSearchSuggestionChip extends StatelessWidget {
  const _CardSearchSuggestionChip({
    required this.chipKey,
    required this.label,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: chipKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.outlineMuted),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontXs,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardSearchResultTile extends StatelessWidget {
  const _CardSearchResultTile({required this.tileKey, required this.card});

  final Key tileKey;
  final DeckCardItem card;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: tileKey,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)),
          );
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineMuted),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSlate,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.style_rounded,
                  color: AppTheme.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontMd,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (card.typeLine.trim().isNotEmpty) card.typeLine,
                        if (card.setCode.trim().isNotEmpty)
                          card.setCode.toUpperCase(),
                      ].join('  •  '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontSm,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppTheme.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
