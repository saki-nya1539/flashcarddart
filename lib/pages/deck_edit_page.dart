import 'package:flutter/material.dart';

import '../services/deck_store.dart';

/// Page 2 of 4: add, edit, and delete the flashcards inside a single deck.
class DeckEditPage extends StatelessWidget {
  const DeckEditPage({super.key, required this.store, required this.deckId});

  final DeckStore store;
  final String deckId;

  Future<void> _showCardDialog(
    BuildContext context, {
    String? cardId,
    String initialFront = '',
    String initialBack = '',
  }) async {
    final frontController = TextEditingController(text: initialFront);
    final backController = TextEditingController(text: initialBack);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(cardId == null ? 'カードを追加' : 'カードを編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '表(質問)'),
            ),
            TextField(
              controller: backController,
              decoration: const InputDecoration(labelText: '裏(答え)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (saved != true) return;
    if (frontController.text.trim().isEmpty || backController.text.trim().isEmpty) return;

    if (cardId == null) {
      store.addCard(deckId, frontController.text, backController.text);
    } else {
      store.updateCard(cardId, front: frontController.text, back: backController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = store.decks.firstWhere((d) => d.id == deckId);
    return Scaffold(
      appBar: AppBar(title: Text('${deck.name} — カード編集')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final cards = store.cardsInDeck(deckId);
          if (cards.isEmpty) {
            return const Center(
              child: Text('カードがありません。右下の + から追加してください。'),
            );
          }
          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                title: Text(card.front),
                subtitle: Text(card.back),
                onTap: () => _showCardDialog(
                  context,
                  cardId: card.id,
                  initialFront: card.front,
                  initialBack: card.back,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '削除',
                  onPressed: () => store.deleteCard(card.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCardDialog(context),
        tooltip: 'カードを追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
