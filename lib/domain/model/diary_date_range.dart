/// Intervallo di giorni inclusivo per la vista diario dello specialista (RF20).
///
/// Value object puro e testabile: [from] e [to] sono normalizzati a sola data
/// (mezzanotte locale); [days] conta l'arco inclusivo e [maxDays] codifica il
/// limite di 92 giorni di ADR-0017 (intervalli più lunghi esplodono in troppe
/// chiamate PostgREST parallele). Il limite vero lo applica
/// `GetPatientDiaryRangeUseCase`; questo modello espone solo la regola.
class DiaryDateRange {
  /// Inizio inclusivo (sola data, mezzanotte locale).
  final DateTime from;

  /// Fine inclusiva (sola data, mezzanotte locale).
  final DateTime to;

  /// Limite di sicurezza sull'arco inclusivo (ADR-0017).
  static const int maxDays = 92;

  DiaryDateRange({required DateTime from, required DateTime to})
      : from = _dateOnly(from),
        to = _dateOnly(to);

  /// Solo oggi.
  factory DiaryDateRange.today() {
    final today = _dateOnly(DateTime.now());
    return DiaryDateRange(from: today, to: today);
  }

  /// Ultimi 7 giorni (oggi più i 6 precedenti).
  factory DiaryDateRange.last7() {
    final today = _dateOnly(DateTime.now());
    return DiaryDateRange(from: today.subtract(const Duration(days: 6)), to: today);
  }

  /// Ultimi 30 giorni (oggi più i 29 precedenti).
  factory DiaryDateRange.last30() {
    final today = _dateOnly(DateTime.now());
    return DiaryDateRange(from: today.subtract(const Duration(days: 29)), to: today);
  }

  /// Intervallo personalizzato; gli estremi sono normalizzati a sola data e
  /// riordinati così [from] non è mai dopo [to].
  factory DiaryDateRange.custom(DateTime from, DateTime to) {
    final a = _dateOnly(from);
    final b = _dateOnly(to);
    return a.isAfter(b)
        ? DiaryDateRange(from: b, to: a)
        : DiaryDateRange(from: a, to: b);
  }

  /// Numero di giorni inclusivo nell'intervallo (today → 1, last7 → 7,
  /// last30 → 30).
  ///
  /// Calcolato via epoch-day UTC così i cambi di ora legale non spostano il conteggio.
  int get days => _epochDay(to) - _epochDay(from) + 1;

  /// Vero quando l'intervallo supera il limite di sicurezza [maxDays] (ADR-0017).
  bool get exceedsCap => days > maxDays;

  /// Tutte le date dell'intervallo (crescenti), come [DateTime] locali a sola
  /// data — le chiavi del fan-out per-giorno delle letture del diario.
  List<DateTime> get dates {
    final result = <DateTime>[];
    for (var epoch = _epochDay(from); epoch <= _epochDay(to); epoch++) {
      final utc = DateTime.fromMillisecondsSinceEpoch(
          epoch * Duration.millisecondsPerDay,
          isUtc: true);
      result.add(DateTime(utc.year, utc.month, utc.day));
    }
    return result;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Giorni dall'epoch Unix, calcolati alla mezzanotte UTC (immune all'ora legale).
  static int _epochDay(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}
