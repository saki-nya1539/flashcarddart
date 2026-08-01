import 'package:flutter/foundation.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';
import '../models/review_quality.dart';
import '../models/review_scheduler.dart';

class DeckNotFoundException implements Exception {
  DeckNotFoundException(this.deckId);
  final String deckId;
  @override
  String toString() => 'Deck not found: $deckId';
}

class CardNotFoundException implements Exception {
  CardNotFoundException(this.cardId);
  final String cardId;
  @override
  String toString() => 'Flashcard not found: $cardId';
}

class EmptyFieldException implements Exception {
  EmptyFieldException(this.field);
  final String field;
  @override
  String toString() => '$field must not be empty';
}

/// Aggregate statistics for a single deck.
class DeckStats {
  const DeckStats({
    required this.totalCards,
    required this.dueCount,
    required this.masteredCount,
    required this.averageEaseFactor,
  });

  final int totalCards;
  final int dueCount;
  final int masteredCount;
  final double averageEaseFactor;
}

/// In-memory store for decks and flashcards, with change notification so
/// Flutter widgets can rebuild via [ListenableBuilder].
///
/// A production app would persist this to disk (e.g. via `sqflite` or
/// `shared_preferences`); this portfolio version deliberately keeps
/// everything in memory to avoid extra dependencies and to keep the core
/// scheduling logic easy to unit test in isolation from any storage layer.
class DeckStore extends ChangeNotifier {
  final List<Deck> _decks = [];
  final List<Flashcard> _cards = [];
  int _nextDeckId = 1;
  int _nextCardId = 1;

  List<Deck> get decks => List.unmodifiable(_decks);

  Deck _findDeck(String deckId) {
    return _decks.firstWhere(
      (d) => d.id == deckId,
      orElse: () => throw DeckNotFoundException(deckId),
    );
  }

  Flashcard _findCard(String cardId) {
    return _cards.firstWhere(
      (c) => c.id == cardId,
      orElse: () => throw CardNotFoundException(cardId),
    );
  }

  Deck addDeck(String name, {String description = ''}) {
    if (name.trim().isEmpty) throw EmptyFieldException('name');
    final deck = Deck(id: 'deck-${_nextDeckId++}', name: name.trim(), description: description.trim());
    _decks.add(deck);
    notifyListeners();
    return deck;
  }

  void deleteDeck(String deckId) {
    _findDeck(deckId); // throws if missing
    _decks.removeWhere((d) => d.id == deckId);
    _cards.removeWhere((c) => c.deckId == deckId);
    notifyListeners();
  }

  /// Adds a new card to [deckId]. Its initial `dueDate` is [now] (so it is
  /// immediately due for review); defaults to the real current time when
  /// [now] is omitted. Tests that need a fixed clock should pass [now]
  /// explicitly instead of relying on the wall-clock default.
  Flashcard addCard(String deckId, String front, String back, {DateTime? now}) {
    _findDeck(deckId); // ensure the deck exists
    if (front.trim().isEmpty) throw EmptyFieldException('front');
    if (back.trim().isEmpty) throw EmptyFieldException('back');
    final card = Flashcard(
      id: 'card-${_nextCardId++}',
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      dueDate: now,
    );
    _cards.add(card);
    notifyListeners();
    return card;
  }

  void updateCard(String cardId, {String? front, String? back}) {
    final card = _findCard(cardId);
    if (front != null) {
      if (front.trim().isEmpty) throw EmptyFieldException('front');
      card.front = front.trim();
    }
    if (back != null) {
      if (back.trim().isEmpty) throw EmptyFieldException('back');
      card.back = back.trim();
    }
    notifyListeners();
  }

  void deleteCard(String cardId) {
    _findCard(cardId); // throws if missing
    _cards.removeWhere((c) => c.id == cardId);
    notifyListeners();
  }

  List<Flashcard> cardsInDeck(String deckId) {
    _findDeck(deckId);
    return _cards.where((c) => c.deckId == deckId).toList();
  }

  List<Flashcard> dueCards(String deckId, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final due = cardsInDeck(deckId).where((c) => c.isDue(reference)).toList();
    due.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return due;
  }

  Flashcard reviewCard(String cardId, ReviewQuality quality, {DateTime? now}) {
    final card = _findCard(cardId);
    ReviewScheduler.schedule(card, quality, now: now);
    notifyListeners();
    return card;
  }

  DeckStats statsFor(String deckId, {DateTime? now}) {
    final cards = cardsInDeck(deckId);
    final reference = now ?? DateTime.now();
    final dueCount = cards.where((c) => c.isDue(reference)).length;
    final masteredCount = cards.where((c) => c.isMastered).length;
    final avgEase =
        cards.isEmpty ? 0.0 : cards.map((c) => c.easeFactor).reduce((a, b) => a + b) / cards.length;
    return DeckStats(
      totalCards: cards.length,
      dueCount: dueCount,
      masteredCount: masteredCount,
      averageEaseFactor: avgEase,
    );
  }
}
