/// A named collection of flashcards, e.g. "TOEIC単語" or "基本情報技術者".
class Deck {
  Deck({required this.id, required this.name, this.description = ''});

  final String id;
  String name;
  String description;
}
