import 'package:flutter/material.dart';

import 'pages/deck_list_page.dart';
import 'services/deck_store.dart';

void main() {
  runApp(FlashCardDartApp(store: DeckStore()));
}

class FlashCardDartApp extends StatelessWidget {
  const FlashCardDartApp({super.key, required this.store});

  final DeckStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlashCardDart',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: DeckListPage(store: store),
    );
  }
}
