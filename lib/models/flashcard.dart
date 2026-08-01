/// A single flashcard belonging to a deck.
///
/// The scheduling fields (`easeFactor`, `intervalDays`, `repetitions`,
/// `dueDate`) are maintained by [ReviewScheduler] using a simplified
/// SM-2 spaced-repetition algorithm; callers should not mutate them
/// directly outside of that class.
class Flashcard {
  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.repetitions = 0,
    DateTime? dueDate,
    this.lastReviewed,
  }) : dueDate = dueDate ?? DateTime.now();

  final String id;
  final String deckId;
  String front;
  String back;
  double easeFactor;
  int intervalDays;
  int repetitions;
  DateTime dueDate;
  DateTime? lastReviewed;

  /// Whether this card is due for review at or before [now].
  bool isDue(DateTime now) => !dueDate.isAfter(now);

  /// A card is considered "mastered" once spaced repetition has pushed its
  /// review interval past three weeks.
  bool get isMastered => intervalDays >= 21;
}
