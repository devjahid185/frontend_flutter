class BangladeshTime {
  const BangladeshTime._();

  static const offset = Duration(hours: 6);

  static DateTime now() => DateTime.now().toUtc().add(offset);

  static DateTime fromDateTime(DateTime value) => value.toUtc().add(offset);

  static DateTime? tryParse(dynamic value) {
    final raw = '${value ?? ''}'.trim();
    if (raw.isEmpty || raw == 'null') return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : fromDateTime(parsed);
  }

  static String todayIso() {
    final value = now();
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}
