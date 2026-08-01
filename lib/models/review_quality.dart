/// How well the user recalled a card during a review.
///
/// This follows the simplified 4-button scheme popularized by Anki, which
/// is itself a practical simplification of SuperMemo's original SM-2
/// algorithm (which used quality grades 0-5).
enum ReviewQuality { again, hard, good, easy }
