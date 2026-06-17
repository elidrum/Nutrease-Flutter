import 'food.dart';

/// Ricerca alimenti client-side, pura e deterministica (ADR-0029).
///
/// Gira sul dataset in cache in memoria: normalizza (minuscole + rimozione
/// esplicita degli accenti), spezza la query sugli spazi, richiede che ogni
/// token corrisponda (AND) e ordina i match esatto > prefisso > sottostringa >
/// fuzzy (Levenshtein, 1 refuso), con i pari risolti per nome.
abstract final class FoodSearch {
  /// Livelli di match: più basso = più rilevante.
  static const int _tierExact = 0;
  static const int _tierPrefix = 1;
  static const int _tierSubstring = 2;
  static const int _tierFuzzy = 3;

  /// Mappa esplicita degli accenti (nessuna dipendenza da ICU/librerie).
  static const Map<String, String> _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Restituisce fino a [limit] alimenti di [all] che corrispondono a [query],
  /// i più rilevanti per primi. Una query vuota non dà risultati.
  static List<Food> search(List<Food> all, String query, {int limit = 50}) {
    final tokens = normalize(query)
        .split(' ')
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const [];

    final scored = <(Food, int)>[];
    for (final food in all) {
      final score = _score(normalize(food.name), tokens);
      if (score != null) scored.add((food, score));
    }

    scored.sort((a, b) {
      final byScore = a.$2.compareTo(b.$2);
      if (byScore != 0) return byScore;
      return a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
    });

    return [for (final (food, _) in scored.take(limit)) food];
  }

  /// Porta in minuscolo e rimuove gli accenti carattere per carattere.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Rilevanza totale di [name] per [tokens] (somma dei livelli per-token), o
  /// `null` se anche un solo token non corrisponde (semantica AND).
  static int? _score(String name, List<String> tokens) {
    var total = 0;
    for (final token in tokens) {
      final tier = _tokenTier(name, token);
      if (tier == null) return null;
      total += tier;
    }
    return total;
  }

  static int? _tokenTier(String name, String token) {
    if (name == token) return _tierExact;
    if (name.startsWith(token)) return _tierPrefix;
    if (name.contains(token)) return _tierSubstring;
    // Fuzzy: un singolo refuso rispetto a una qualsiasi parola del nome.
    for (final word in name.split(' ')) {
      if (word.isNotEmpty && levenshtein(word, token) <= 1) return _tierFuzzy;
    }
    return null;
  }

  /// Classica distanza di Levenshtein a due righe.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 0; i < a.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final substitutionCost = a[i] == b[j] ? 0 : 1;
        current[j + 1] = [
          current[j] + 1, // inserimento
          previous[j + 1] + 1, // cancellazione
          previous[j] + substitutionCost, // sostituzione
        ].reduce((x, y) => x < y ? x : y);
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[b.length];
  }
}
