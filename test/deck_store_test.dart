import 'package:flutter_test/flutter_test.dart';
import 'package:flashcarddart/models/review_quality.dart';
import 'package:flashcarddart/services/deck_store.dart';

void main() {
  group('DeckStore', () {
    late DeckStore store;

    setUp(() {
      store = DeckStore();
    });

    test('addDeck rejects a blank name', () {
      expect(() => store.addDeck('   '), throwsA(isA<EmptyFieldException>()));
    });

    test('addCard requires an existing deck', () {
      expect(() => store.addCard('missing-deck', 'Q', 'A'), throwsA(isA<DeckNotFoundException>()));
    });

    test('addCard rejects a blank front or back', () {
      final deck = store.addDeck('英単語');
      expect(() => store.addCard(deck.id, '', 'answer'), throwsA(isA<EmptyFieldException>()));
      expect(() => store.addCard(deck.id, 'question', ''), throwsA(isA<EmptyFieldException>()));
    });

    test('deleteDeck also removes its cards', () {
      final deck = store.addDeck('英単語');
      store.addCard(deck.id, 'apple', 'りんご');
      store.deleteDeck(deck.id);

      expect(store.decks, isEmpty);
      expect(() => store.cardsInDeck(deck.id), throwsA(isA<DeckNotFoundException>()));
    });

    test('deleteCard on an unknown id throws', () {
      expect(() => store.deleteCard('missing-card'), throwsA(isA<CardNotFoundException>()));
    });

    test('dueCards only returns cards whose dueDate has passed', () {
      final deck = store.addDeck('英単語');
      final now = DateTime(2026, 6, 1);
      final card1 = store.addCard(deck.id, 'apple', 'りんご', now: now);
      final card2 = store.addCard(deck.id, 'banana', 'バナナ', now: now);

      // card1 is reviewed twice with "easy", pushing it days into the future.
      store.reviewCard(card1.id, ReviewQuality.easy, now: now);
      store.reviewCard(card1.id, ReviewQuality.easy, now: now);

      final due = store.dueCards(deck.id, now: now.add(const Duration(hours: 1)));

      expect(due.map((c) => c.id), contains(card2.id));
      expect(due.map((c) => c.id), isNot(contains(card1.id)));
    });

    test('dueCards is sorted by dueDate ascending', () {
      final deck = store.addDeck('英単語');
      final now = DateTime(2026, 6, 1);
      final cardA = store.addCard(deck.id, 'A', 'a', now: now);
      final cardB = store.addCard(deck.id, 'B', 'b', now: now);

      // Both start due "now"; review A with "again" so it becomes due
      // 1 day later than B (which stays due immediately).
      store.reviewCard(cardA.id, ReviewQuality.again, now: now);

      final due = store.dueCards(deck.id, now: now.add(const Duration(days: 2)));
      expect(due.first.id, cardB.id);
      expect(due.last.id, cardA.id);
    });

    test('statsFor reports totals, due count, and mastered count', () {
      final deck = store.addDeck('英単語');
      final now = DateTime(2026, 6, 1);
      final card = store.addCard(deck.id, 'apple', 'りんご');
      store.addCard(deck.id, 'banana', 'バナナ');

      // Repeatedly review the first card with "easy" until its interval
      // grows past the 21-day "mastered" threshold.
      for (var i = 0; i < 5; i++) {
        store.reviewCard(card.id, ReviewQuality.easy, now: now);
      }

      final stats = store.statsFor(deck.id, now: now);
      expect(stats.totalCards, 2);
      expect(stats.masteredCount, greaterThanOrEqualTo(1));
    });

    test('statsFor on an empty deck reports zeroes', () {
      final deck = store.addDeck('空のデッキ');
      final stats = store.statsFor(deck.id);

      expect(stats.totalCards, 0);
      expect(stats.dueCount, 0);
      expect(stats.masteredCount, 0);
      expect(stats.averageEaseFactor, 0.0);
    });

    test('updateCard rejects blank values but allows partial updates', () {
      final deck = store.addDeck('英単語');
      final card = store.addCard(deck.id, 'apple', 'りんご');

      expect(() => store.updateCard(card.id, front: ''), throwsA(isA<EmptyFieldException>()));

      store.updateCard(card.id, front: 'green apple');
      final updated = store.cardsInDeck(deck.id).first;
      expect(updated.front, 'green apple');
      expect(updated.back, 'りんご'); // untouched
    });

    test('notifies listeners on mutation', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      final deck = store.addDeck('英単語');
      store.addCard(deck.id, 'apple', 'りんご');

      expect(notifications, 2);
    });
  });
}
