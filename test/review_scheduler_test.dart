import 'package:flutter_test/flutter_test.dart';
import 'package:flashcarddart/models/flashcard.dart';
import 'package:flashcarddart/models/review_quality.dart';
import 'package:flashcarddart/models/review_scheduler.dart';

void main() {
  group('ReviewScheduler', () {
    test('first successful review schedules an interval of 1 day', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now);

      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);

      expect(card.repetitions, 1);
      expect(card.intervalDays, 1);
      expect(card.dueDate, now.add(const Duration(days: 1)));
    });

    test('second successful review schedules an interval of 6 days', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now);

      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.good, now: now.add(const Duration(days: 1)));

      expect(card.repetitions, 2);
      expect(card.intervalDays, 6);
    });

    test('third+ successful review multiplies interval by ease factor', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now, easeFactor: 2.5);

      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);

      expect(card.repetitions, 3);
      expect(card.intervalDays, 15); // 6 * 2.5 = 15
    });

    test('"again" resets repetitions and shortens the interval to 1 day', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now);

      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.again, now: now);

      expect(card.repetitions, 0);
      expect(card.intervalDays, 1);
    });

    test('ease factor never drops below 1.3', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now, easeFactor: 1.35);

      ReviewScheduler.schedule(card, ReviewQuality.again, now: now);
      ReviewScheduler.schedule(card, ReviewQuality.hard, now: now);

      expect(card.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('"easy" increases the ease factor', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now, easeFactor: 2.5);

      ReviewScheduler.schedule(card, ReviewQuality.easy, now: now);

      expect(card.easeFactor, closeTo(2.65, 0.0001));
    });

    test('"hard" decreases the ease factor', () {
      final now = DateTime(2026, 1, 1);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now, easeFactor: 2.5);

      ReviewScheduler.schedule(card, ReviewQuality.hard, now: now);

      expect(card.easeFactor, closeTo(2.35, 0.0001));
    });

    test('lastReviewed is stamped with the review time', () {
      final now = DateTime(2026, 3, 10, 9, 30);
      final card = Flashcard(id: 'c1', deckId: 'd1', front: 'Q', back: 'A', dueDate: now);

      ReviewScheduler.schedule(card, ReviewQuality.good, now: now);

      expect(card.lastReviewed, now);
    });
  });
}
