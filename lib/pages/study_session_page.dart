import 'package:flutter/material.dart';

import '../models/flashcard.dart';
import '../models/review_quality.dart';
import '../services/deck_store.dart';

/// Page 3 of 4: the study session — flip through cards that are due for
/// review today, and rate each one to reschedule it.
class StudySessionPage extends StatefulWidget {
  const StudySessionPage({super.key, required this.store, required this.deckId});

  final DeckStore store;
  final String deckId;

  @override
  State<StudySessionPage> createState() => _StudySessionPageState();
}

class _StudySessionPageState extends State<StudySessionPage> {
  late List<Flashcard> _queue;
  bool _showingBack = false;
  int _reviewedCount = 0;

  @override
  void initState() {
    super.initState();
    _queue = widget.store.dueCards(widget.deckId);
  }

  void _flip() => setState(() => _showingBack = !_showingBack);

  void _rate(ReviewQuality quality) {
    final card = _queue.first;
    widget.store.reviewCard(card.id, quality);
    setState(() {
      _queue.removeAt(0);
      _showingBack = false;
      _reviewedCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('学習セッション')),
        body: Center(
          child: Text('お疲れさまでした！$_reviewedCount枚を復習しました。'),
        ),
      );
    }

    final card = _queue.first;
    return Scaffold(
      appBar: AppBar(title: Text('学習セッション（残り${_queue.length}枚）')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _flip,
                child: Card(
                  elevation: 4,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _showingBack ? card.back : card.front,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_showingBack)
              FilledButton(onPressed: _flip, child: const Text('答えを見る'))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RateButton(
                    label: 'もう一度',
                    color: Colors.red,
                    onPressed: () => _rate(ReviewQuality.again),
                  ),
                  _RateButton(
                    label: '難しい',
                    color: Colors.orange,
                    onPressed: () => _rate(ReviewQuality.hard),
                  ),
                  _RateButton(
                    label: '普通',
                    color: Colors.blue,
                    onPressed: () => _rate(ReviewQuality.good),
                  ),
                  _RateButton(
                    label: '簡単',
                    color: Colors.green,
                    onPressed: () => _rate(ReviewQuality.easy),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.label, required this.color, required this.onPressed});

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
