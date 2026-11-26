/// Backend JSON yanıtlarındaki esnek tipleri (örn. PostgreSQL decimal string'leri)
/// güvenli şekilde Dart tiplerine dönüştüren yardımcı fonksiyonlar.
int parseJsonInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt() ?? fallback;
  }
  return fallback;
}

double parseJsonDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return double.tryParse(trimmed) ?? fallback;
  }
  return fallback;
}

bool parseJsonBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

List<String> parseJsonStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .where((item) => item != null)
      .map((item) => item.toString().trim())
      .where((text) => text.isNotEmpty)
      .toList(growable: false);
}

Map<String, double> parseJsonDoubleMap(dynamic value) {
  if (value is! Map) return const <String, double>{};
  final result = <String, double>{};
  value.forEach((key, val) {
    if (key == null) return;
    final k = key.toString().trim();
    if (k.isEmpty) return;
    result[k] = parseJsonDouble(val);
  });
  return Map<String, double>.unmodifiable(result);
}

Map<String, int> parseJsonIntMap(dynamic value) {
  if (value is! Map) return const <String, int>{};
  final result = <String, int>{};
  value.forEach((key, val) {
    if (key == null) return;
    final k = key.toString().trim();
    if (k.isEmpty) return;
    result[k] = parseJsonInt(val);
  });
  return Map<String, int>.unmodifiable(result);
}

DateTime? parseJsonDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}
