import 'package:flutter/material.dart';

import '../services/deck_store.dart';

/// Page 4 of 4: aggregate statistics for a single deck.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key, required this.store, required this.deckId});

  final DeckStore store;
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final deck = store.decks.firstWhere((d) => d.id == deckId);
    return Scaffold(
      appBar: AppBar(title: Text('${deck.name} — 統計')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final stats = store.statsFor(deckId);
          final masteredRatio = stats.totalCards == 0 ? 0.0 : stats.masteredCount / stats.totalCards;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatTile(label: '総カード数', value: '${stats.totalCards}枚'),
              _StatTile(label: '本日の復習待ち', value: '${stats.dueCount}枚'),
              _StatTile(label: '習得済み(間隔21日以上)', value: '${stats.masteredCount}枚'),
              _StatTile(
                label: '平均難易度係数(ease factor)',
                value: stats.averageEaseFactor.toStringAsFixed(2),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: masteredRatio, minHeight: 12),
              ),
              const SizedBox(height: 4),
              Text('習得率: ${(masteredRatio * 100).toStringAsFixed(0)}%'),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
