import 'flashcard.dart';
import 'review_quality.dart';

/// A simplified SM-2 spaced-repetition scheduler.
///
/// This mirrors the well-known SuperMemo SM-2 algorithm as popularized by
/// Anki's 4-button review scheme, rather than the original SM-2's 0-5
/// quality grades:
///
/// * "again"  — the card was forgotten; repetitions reset and it comes
///   back tomorrow with a slightly lower ease factor.
/// * "hard" / "good" / "easy" — the card was recalled; the interval grows
///   (1 day -> 6 days -> interval * ease factor), and the ease factor is
///   nudged down / left alone / nudged up respectively.
///
/// The ease factor is clamped to a minimum of 1.3, matching SM-2, so that
/// difficult cards don't spiral into ever-shrinking intervals.
class ReviewScheduler {
  static const double minEaseFactor = 1.3;

  /// Applies [quality] to [card], mutating its scheduling fields in place
  /// and returning the same instance for convenience.
  static Flashcard schedule(Flashcard card, ReviewQuality quality, {DateTime? now}) {
    final reviewedAt = now ?? DateTime.now();
    card.lastReviewed = reviewedAt;

    if (quality == ReviewQuality.again) {
      card.repetitions = 0;
      card.intervalDays = 1;
      card.easeFactor = _clampEase(card.easeFactor - 0.2);
      card.dueDate = reviewedAt.add(const Duration(days: 1));
      return card;
    }

    final nextInterval = _nextInterval(card);
    card.repetitions += 1;
    card.intervalDays = nextInterval;

    switch (quality) {
      case ReviewQuality.hard:
        card.easeFactor = _clampEase(card.easeFactor - 0.15);
        break;
      case ReviewQuality.good:
        break;
      case ReviewQuality.easy:
        card.easeFactor = _clampEase(card.easeFactor + 0.15);
        break;
      case ReviewQuality.again:
        break; // unreachable: handled above
    }

    card.dueDate = reviewedAt.add(Duration(days: nextInterval));
    return card;
  }

  static int _nextInterval(Flashcard card) {
    if (card.repetitions == 0) return 1;
    if (card.repetitions == 1) return 6;
    return (card.intervalDays * card.easeFactor).round();
  }

  static double _clampEase(double value) => value < minEaseFactor ? minEaseFactor : value;
}
