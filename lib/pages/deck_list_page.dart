import 'package:flutter/material.dart';

import '../services/deck_store.dart';
import 'deck_edit_page.dart';
import 'stats_page.dart';
import 'study_session_page.dart';

/// Page 1 of 4: the home page, listing all decks with quick actions to
/// edit, study, or view stats for each one.
class DeckListPage extends StatelessWidget {
  const DeckListPage({super.key, required this.store});

  final DeckStore store;

  Future<void> _showAddDeckDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新しいデッキ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'デッキ名'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '説明(任意)'),
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
            child: const Text('作成'),
          ),
        ],
      ),
    );

    if (created == true && nameController.text.trim().isNotEmpty) {
      store.addDeck(nameController.text, description: descController.text);
    }
  }

  Future<void> _confirmDeleteDeck(BuildContext context, String deckId, String deckName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('デッキを削除しますか？'),
        content: Text('「$deckName」とその中のカードをすべて削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      store.deleteDeck(deckId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlashCardDart — デッキ一覧')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.decks.isEmpty) {
            return const Center(
              child: Text('デッキがありません。右下の + から作成してください。'),
            );
          }
          return ListView.builder(
            itemCount: store.decks.length,
            itemBuilder: (context, index) {
              final deck = store.decks[index];
              final stats = store.statsFor(deck.id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(deck.name),
                  subtitle: Text(
                    '${stats.totalCards}枚 ・ 復習待ち ${stats.dueCount}枚 ・ 習得済み ${stats.masteredCount}枚',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeckEditPage(store: store, deckId: deck.id)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart),
                        tooltip: '統計',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StatsPage(store: store, deckId: deck.id)),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.school),
                        tooltip: '学習開始',
                        onPressed: stats.dueCount == 0
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudySessionPage(store: store, deckId: deck.id),
                                  ),
                                ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'その他の操作',
                        onSelected: (value) {
                          if (value == 'delete') {
                            _confirmDeleteDeck(context, deck.id, deck.name);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'delete', child: Text('デッキを削除')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeckDialog(context),
        tooltip: '新しいデッキ',
        child: const Icon(Icons.add),
      ),
    );
  }
}
