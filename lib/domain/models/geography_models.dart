import 'json_parsing_utils.dart';
import 'route_feed_models.dart';

Map<String, String> _parseStringMap(dynamic value) {
  if (value is! Map) return const <String, String>{};
  final result = <String, String>{};
  value.forEach((key, val) {
    if (key == null || val == null) return;
    final k = key.toString().trim();
    final v = val.toString().trim();
    if (k.isNotEmpty && v.isNotEmpty) {
      result[k] = v;
    }
  });
  return Map<String, String>.unmodifiable(result);
}

String _resolveLocalizedName({
  required String name,
  required String defaultName,
  required Map<String, String> nameTranslations,
  required String lang,
}) {
  final trimmedLang = lang.trim().toLowerCase();
  if (trimmedLang.isNotEmpty) {
    final direct = nameTranslations[trimmedLang] ?? nameTranslations[lang.trim()];
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }
  }
  if (name.trim().isNotEmpty) {
    return name.trim();
  }
  if (defaultName.trim().isNotEmpty) {
    return defaultName.trim();
  }
  final trFallback = nameTranslations['tr'];
  if (trFallback != null && trFallback.trim().isNotEmpty) {
    return trFallback.trim();
  }
  final enFallback = nameTranslations['en'];
  if (enFallback != null && enFallback.trim().isNotEmpty) {
    return enFallback.trim();
  }
  for (final candidate in nameTranslations.values) {
    if (candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }
  return '';
}

bool _matchesAnyCandidate(
  String normalizedQuery,
  String Function(String) normalizer,
  Iterable<String> candidates,
) {
  if (normalizedQuery.isEmpty) return true;
  for (final candidate in candidates) {
    if (candidate.trim().isEmpty) continue;
    if (normalizer(candidate).contains(normalizedQuery)) {
      return true;
    }
  }
  return false;
}

/// Coğrafya ağacındaki ilçe (`GeoDistrict`) düğümü (`GET /geography/tree`).
class GeographyDistrictNode {
  const GeographyDistrictNode({
    required this.id,
    required this.slug,
    required this.citySlug,
    required this.countryCode,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.placesCount,
  });

  factory GeographyDistrictNode.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';
    return GeographyDistrictNode(
      id: json['id']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim() ?? '',
      citySlug: json['city_slug']?.toString().trim() ?? '',
      countryCode: json['country_code']?.toString().trim().toUpperCase() ?? '',
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      placesCount: parseJsonInt(json['places_count']),
    );
  }

  final String id;
  final String slug;
  final String citySlug;
  final String countryCode;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final int placesCount;

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }

  bool matchesQuery(
    String normalizedQuery,
    String Function(String) normalizer,
  ) {
    return _matchesAnyCandidate(normalizedQuery, normalizer, <String>[
      name,
      defaultName,
      slug,
      ...nameTranslations.values,
    ]);
  }
}

/// Coğrafya ağacındaki şehir düğümü (`GET /geography/tree`).
class GeographyCityNode {
  const GeographyCityNode({
    required this.id,
    required this.slug,
    required this.countryCode,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.imageUrl,
    required this.isPopular,
    required this.placesCount,
    required this.routesCount,
    this.districts = const <GeographyDistrictNode>[],
  });

  factory GeographyCityNode.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';
    final translations = _parseStringMap(json['name_translations']);
    final rawDistricts = json['districts'];
    final districts = rawDistricts is List
        ? rawDistricts
            .whereType<Map>()
            .map(
              (item) => GeographyDistrictNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyDistrictNode>[];

    return GeographyCityNode(
      id: json['id']?.toString().trim() ?? '',
      slug: json['slug']?.toString().trim() ?? '',
      countryCode: json['country_code']?.toString().trim().toUpperCase() ?? '',
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: translations,
      imageUrl: json['image_url']?.toString().trim() ?? '',
      isPopular: parseJsonBool(json['is_popular']),
      placesCount: parseJsonInt(json['places_count']),
      routesCount: parseJsonInt(json['routes_count']),
      districts: districts,
    );
  }

  final String id;
  final String slug;
  final String countryCode;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final String imageUrl;
  final bool isPopular;
  final int placesCount;
  final int routesCount;
  final List<GeographyDistrictNode> districts;

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }

  bool matchesQuery(
    String normalizedQuery,
    String Function(String) normalizer,
  ) {
    return _matchesAnyCandidate(normalizedQuery, normalizer, <String>[
      name,
      defaultName,
      slug,
      ...nameTranslations.values,
    ]);
  }
}

/// Ülke kodu için ISO 4217 para birimi fallback bilgisi.
class CountryCurrencyFallback {
  const CountryCurrencyFallback({
    required this.code,
    required this.symbol,
    required this.nameTr,
  });

  final String code;
  final String symbol;
  final String nameTr;
}

/// Bilinmeyen veya eşleşmeyen ülkeler için varsayılan para birimi (`USD`).
const CountryCurrencyFallback kDefaultCountryCurrencyFallback =
    CountryCurrencyFallback(
      code: 'USD',
      symbol: r'$',
      nameTr: 'ABD Doları',
    );

const Map<String, CountryCurrencyFallback> _countryCurrencyFallbackByCode =
    <String, CountryCurrencyFallback>{
  'TR': CountryCurrencyFallback(code: 'TRY', symbol: '₺', nameTr: 'Türk Lirası'),
  'DE': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'FR': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'BE': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'IT': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'ES': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'NL': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'GR': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'HR': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'ME': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'SI': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'AT': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'PT': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'IE': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'FI': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'SK': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'EE': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'LV': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'LT': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'CY': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'MT': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'LU': CountryCurrencyFallback(code: 'EUR', symbol: '€', nameTr: 'Euro'),
  'GB': CountryCurrencyFallback(
    code: 'GBP',
    symbol: '£',
    nameTr: 'İngiliz Sterlini',
  ),
  'BA': CountryCurrencyFallback(
    code: 'BAM',
    symbol: 'KM',
    nameTr: 'Bosna Hersek Konvertibl Markı',
  ),
  'RS': CountryCurrencyFallback(
    code: 'RSD',
    symbol: 'din.',
    nameTr: 'Sırp Dinarı',
  ),
  'AL': CountryCurrencyFallback(
    code: 'ALL',
    symbol: 'L',
    nameTr: 'Arnavutluk Leki',
  ),
  'MK': CountryCurrencyFallback(
    code: 'MKD',
    symbol: 'ден',
    nameTr: 'Makedon Dinarı',
  ),
  'BG': CountryCurrencyFallback(
    code: 'BGN',
    symbol: 'лв',
    nameTr: 'Bulgar Levası',
  ),
  'CH': CountryCurrencyFallback(
    code: 'CHF',
    symbol: 'CHF',
    nameTr: 'İsviçre Frangı',
  ),
  'CZ': CountryCurrencyFallback(
    code: 'CZK',
    symbol: 'Kč',
    nameTr: 'Çek Korunası',
  ),
  'HU': CountryCurrencyFallback(
    code: 'HUF',
    symbol: 'Ft',
    nameTr: 'Macar Forinti',
  ),
  'PL': CountryCurrencyFallback(
    code: 'PLN',
    symbol: 'zł',
    nameTr: 'Polonya Zlotisi',
  ),
  'DK': CountryCurrencyFallback(
    code: 'DKK',
    symbol: 'kr',
    nameTr: 'Danimarka Kronu',
  ),
  'NO': CountryCurrencyFallback(
    code: 'NOK',
    symbol: 'kr',
    nameTr: 'Norveç Kronu',
  ),
  'SE': CountryCurrencyFallback(
    code: 'SEK',
    symbol: 'kr',
    nameTr: 'İsveç Kronu',
  ),
  'RO': CountryCurrencyFallback(
    code: 'RON',
    symbol: 'lei',
    nameTr: 'Romen Leyi',
  ),
  'RU': CountryCurrencyFallback(
    code: 'RUB',
    symbol: '₽',
    nameTr: 'Rus Rublesi',
  ),
  'GE': CountryCurrencyFallback(
    code: 'GEL',
    symbol: '₾',
    nameTr: 'Gürcistan Larisi',
  ),
  'AZ': CountryCurrencyFallback(
    code: 'AZN',
    symbol: '₼',
    nameTr: 'Azerbaycan Manatı',
  ),
  'TH': CountryCurrencyFallback(
    code: 'THB',
    symbol: '฿',
    nameTr: 'Tayland Bahtı',
  ),
  'JP': CountryCurrencyFallback(
    code: 'JPY',
    symbol: '¥',
    nameTr: 'Japon Yeni',
  ),
  'KR': CountryCurrencyFallback(
    code: 'KRW',
    symbol: '₩',
    nameTr: 'Güney Kore Wonu',
  ),
  'ID': CountryCurrencyFallback(
    code: 'IDR',
    symbol: 'Rp',
    nameTr: 'Endonezya Rupiahı',
  ),
  'SG': CountryCurrencyFallback(
    code: 'SGD',
    symbol: r'S$',
    nameTr: 'Singapur Doları',
  ),
  'MY': CountryCurrencyFallback(
    code: 'MYR',
    symbol: 'RM',
    nameTr: 'Malezya Ringgiti',
  ),
  'HK': CountryCurrencyFallback(
    code: 'HKD',
    symbol: r'HK$',
    nameTr: 'Hong Kong Doları',
  ),
  'AE': CountryCurrencyFallback(
    code: 'AED',
    symbol: 'د.إ',
    nameTr: 'BAE Dirhemi',
  ),
  'SA': CountryCurrencyFallback(
    code: 'SAR',
    symbol: '﷼',
    nameTr: 'Suudi Arabistan Riyali',
  ),
  'QA': CountryCurrencyFallback(
    code: 'QAR',
    symbol: 'QR',
    nameTr: 'Katar Riyali',
  ),
  'CN': CountryCurrencyFallback(
    code: 'CNY',
    symbol: '¥',
    nameTr: 'Çin Yuanı',
  ),
  'IN': CountryCurrencyFallback(
    code: 'INR',
    symbol: '₹',
    nameTr: 'Hindistan Rupisi',
  ),
  'US': CountryCurrencyFallback(
    code: 'USD',
    symbol: r'$',
    nameTr: 'ABD Doları',
  ),
  'CA': CountryCurrencyFallback(
    code: 'CAD',
    symbol: r'CA$',
    nameTr: 'Kanada Doları',
  ),
  'MX': CountryCurrencyFallback(
    code: 'MXN',
    symbol: r'MX$',
    nameTr: 'Meksika Pesosu',
  ),
  'BR': CountryCurrencyFallback(
    code: 'BRL',
    symbol: r'R$',
    nameTr: 'Brezilya Reali',
  ),
  'AR': CountryCurrencyFallback(
    code: 'ARS',
    symbol: r'AR$',
    nameTr: 'Arjantin Pesosu',
  ),
  'CL': CountryCurrencyFallback(
    code: 'CLP',
    symbol: r'CL$',
    nameTr: 'Şili Pesosu',
  ),
  'PE': CountryCurrencyFallback(
    code: 'PEN',
    symbol: 'S/',
    nameTr: 'Peru Solü',
  ),
  'CO': CountryCurrencyFallback(
    code: 'COP',
    symbol: r'CO$',
    nameTr: 'Kolombiya Pesosu',
  ),
  'EG': CountryCurrencyFallback(
    code: 'EGP',
    symbol: 'E£',
    nameTr: 'Mısır Lirası',
  ),
  'MA': CountryCurrencyFallback(
    code: 'MAD',
    symbol: 'MAD',
    nameTr: 'Fas Dirhemi',
  ),
  'ZA': CountryCurrencyFallback(
    code: 'ZAR',
    symbol: 'R',
    nameTr: 'Güney Afrika Randı',
  ),
  'AU': CountryCurrencyFallback(
    code: 'AUD',
    symbol: r'A$',
    nameTr: 'Avustralya Doları',
  ),
  'NZ': CountryCurrencyFallback(
    code: 'NZD',
    symbol: r'NZ$',
    nameTr: 'Yeni Zelanda Doları',
  ),
};

/// Verilen ISO 3166-1 alpha-2 ülke kodu (örn. `'TR'`, `'TH'`, `'JP'`) için
/// güvenli ISO 4217 para birimi fallback eşlemesini döndürür.
CountryCurrencyFallback resolveCountryCurrencyFallback(String? countryCode) {
  final normalized = countryCode?.trim().toUpperCase() ?? '';
  if (normalized.isEmpty) return kDefaultCountryCurrencyFallback;
  return _countryCurrencyFallbackByCode[normalized] ??
      kDefaultCountryCurrencyFallback;
}

/// USD bazlı döviz kuru modeli (`GET /geography/tree` ve `GET /geography/exchange-rates`).
class GeographyExchangeRate {
  const GeographyExchangeRate({
    required this.code,
    required this.symbol,
    required this.nameTr,
    required this.ratePerUsd,
    this.fetchedAt,
  });

  factory GeographyExchangeRate.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString().trim().toUpperCase() ?? '';
    final baseline = kBaselineExchangeRates[code];
    final rawSymbol = json['symbol']?.toString().trim() ?? '';
    final rawNameTr = json['name_tr']?.toString().trim() ?? '';
    final parsedRate = parseJsonDouble(json['rate_per_usd']);
    final ratePerUsd = parsedRate > 0
        ? parsedRate
        : (baseline?.ratePerUsd ?? (code == 'USD' ? 1.0 : 0.0));

    return GeographyExchangeRate(
      code: code,
      symbol: rawSymbol.isNotEmpty ? rawSymbol : (baseline?.symbol ?? code),
      nameTr: rawNameTr.isNotEmpty ? rawNameTr : (baseline?.nameTr ?? code),
      ratePerUsd: ratePerUsd,
      fetchedAt: parseJsonDateTime(json['fetched_at']),
    );
  }

  final String code;
  final String symbol;
  final String nameTr;
  final double ratePerUsd;
  final DateTime? fetchedAt;
}

/// Backend DB kurları henüz yüklenmediğinde veya ilgili para birimi DB'de
/// bulunamadığında kullanılan güvenli taban (baseline) `1 USD = X` kur kataloğu.
const Map<String, GeographyExchangeRate> kBaselineExchangeRates =
    <String, GeographyExchangeRate>{
  'USD': GeographyExchangeRate(
    code: 'USD',
    symbol: r'$',
    nameTr: 'ABD Doları',
    ratePerUsd: 1.0,
  ),
  'TRY': GeographyExchangeRate(
    code: 'TRY',
    symbol: '₺',
    nameTr: 'Türk Lirası',
    ratePerUsd: 34.5,
  ),
  'EUR': GeographyExchangeRate(
    code: 'EUR',
    symbol: '€',
    nameTr: 'Euro',
    ratePerUsd: 0.92,
  ),
  'GBP': GeographyExchangeRate(
    code: 'GBP',
    symbol: '£',
    nameTr: 'İngiliz Sterlini',
    ratePerUsd: 0.79,
  ),
  'CHF': GeographyExchangeRate(
    code: 'CHF',
    symbol: 'CHF',
    nameTr: 'İsviçre Frangı',
    ratePerUsd: 0.88,
  ),
  'JPY': GeographyExchangeRate(
    code: 'JPY',
    symbol: '¥',
    nameTr: 'Japon Yeni',
    ratePerUsd: 154.0,
  ),
  'THB': GeographyExchangeRate(
    code: 'THB',
    symbol: '฿',
    nameTr: 'Tayland Bahtı',
    ratePerUsd: 34.8,
  ),
  'AED': GeographyExchangeRate(
    code: 'AED',
    symbol: 'د.إ',
    nameTr: 'BAE Dirhemi',
    ratePerUsd: 3.6725,
  ),
  'SAR': GeographyExchangeRate(
    code: 'SAR',
    symbol: '﷼',
    nameTr: 'Suudi Arabistan Riyali',
    ratePerUsd: 3.75,
  ),
  'CNY': GeographyExchangeRate(
    code: 'CNY',
    symbol: '¥',
    nameTr: 'Çin Yuanı',
    ratePerUsd: 7.22,
  ),
  'KRW': GeographyExchangeRate(
    code: 'KRW',
    symbol: '₩',
    nameTr: 'Güney Kore Wonu',
    ratePerUsd: 1390.0,
  ),
  'IDR': GeographyExchangeRate(
    code: 'IDR',
    symbol: 'Rp',
    nameTr: 'Endonezya Rupiahı',
    ratePerUsd: 15800.0,
  ),
  'INR': GeographyExchangeRate(
    code: 'INR',
    symbol: '₹',
    nameTr: 'Hindistan Rupisi',
    ratePerUsd: 84.4,
  ),
  'CAD': GeographyExchangeRate(
    code: 'CAD',
    symbol: r'CA$',
    nameTr: 'Kanada Doları',
    ratePerUsd: 1.4,
  ),
  'AUD': GeographyExchangeRate(
    code: 'AUD',
    symbol: r'A$',
    nameTr: 'Avustralya Doları',
    ratePerUsd: 1.54,
  ),
  'NZD': GeographyExchangeRate(
    code: 'NZD',
    symbol: r'NZ$',
    nameTr: 'Yeni Zelanda Doları',
    ratePerUsd: 1.69,
  ),
  'MXN': GeographyExchangeRate(
    code: 'MXN',
    symbol: r'MX$',
    nameTr: 'Meksika Pesosu',
    ratePerUsd: 20.3,
  ),
  'BRL': GeographyExchangeRate(
    code: 'BRL',
    symbol: r'R$',
    nameTr: 'Brezilya Reali',
    ratePerUsd: 5.78,
  ),
  'ARS': GeographyExchangeRate(
    code: 'ARS',
    symbol: r'AR$',
    nameTr: 'Arjantin Pesosu',
    ratePerUsd: 1000.0,
  ),
  'CLP': GeographyExchangeRate(
    code: 'CLP',
    symbol: r'CL$',
    nameTr: 'Şili Pesosu',
    ratePerUsd: 970.0,
  ),
  'PEN': GeographyExchangeRate(
    code: 'PEN',
    symbol: 'S/',
    nameTr: 'Peru Solü',
    ratePerUsd: 3.78,
  ),
  'COP': GeographyExchangeRate(
    code: 'COP',
    symbol: r'CO$',
    nameTr: 'Kolombiya Pesosu',
    ratePerUsd: 4400.0,
  ),
  'EGP': GeographyExchangeRate(
    code: 'EGP',
    symbol: 'E£',
    nameTr: 'Mısır Lirası',
    ratePerUsd: 49.3,
  ),
  'MAD': GeographyExchangeRate(
    code: 'MAD',
    symbol: 'MAD',
    nameTr: 'Fas Dirhemi',
    ratePerUsd: 9.95,
  ),
  'ZAR': GeographyExchangeRate(
    code: 'ZAR',
    symbol: 'R',
    nameTr: 'Güney Afrika Randı',
    ratePerUsd: 18.0,
  ),
  'BAM': GeographyExchangeRate(
    code: 'BAM',
    symbol: 'KM',
    nameTr: 'Bosna Hersek Konvertibl Markı',
    ratePerUsd: 1.8,
  ),
  'RSD': GeographyExchangeRate(
    code: 'RSD',
    symbol: 'din.',
    nameTr: 'Sırp Dinarı',
    ratePerUsd: 108.0,
  ),
  'ALL': GeographyExchangeRate(
    code: 'ALL',
    symbol: 'L',
    nameTr: 'Arnavutluk Leki',
    ratePerUsd: 91.0,
  ),
  'MKD': GeographyExchangeRate(
    code: 'MKD',
    symbol: 'ден',
    nameTr: 'Makedon Dinarı',
    ratePerUsd: 56.5,
  ),
  'BGN': GeographyExchangeRate(
    code: 'BGN',
    symbol: 'лв',
    nameTr: 'Bulgar Levası',
    ratePerUsd: 1.8,
  ),
  'CZK': GeographyExchangeRate(
    code: 'CZK',
    symbol: 'Kč',
    nameTr: 'Çek Korunası',
    ratePerUsd: 23.5,
  ),
  'HUF': GeographyExchangeRate(
    code: 'HUF',
    symbol: 'Ft',
    nameTr: 'Macar Forinti',
    ratePerUsd: 380.0,
  ),
  'PLN': GeographyExchangeRate(
    code: 'PLN',
    symbol: 'zł',
    nameTr: 'Polonya Zlotisi',
    ratePerUsd: 4.05,
  ),
  'DKK': GeographyExchangeRate(
    code: 'DKK',
    symbol: 'kr',
    nameTr: 'Danimarka Kronu',
    ratePerUsd: 6.88,
  ),
  'NOK': GeographyExchangeRate(
    code: 'NOK',
    symbol: 'kr',
    nameTr: 'Norveç Kronu',
    ratePerUsd: 10.9,
  ),
  'SEK': GeographyExchangeRate(
    code: 'SEK',
    symbol: 'kr',
    nameTr: 'İsveç Kronu',
    ratePerUsd: 10.7,
  ),
  'RUB': GeographyExchangeRate(
    code: 'RUB',
    symbol: '₽',
    nameTr: 'Rus Rublesi',
    ratePerUsd: 96.0,
  ),
  'SGD': GeographyExchangeRate(
    code: 'SGD',
    symbol: r'S$',
    nameTr: 'Singapur Doları',
    ratePerUsd: 1.34,
  ),
  'MYR': GeographyExchangeRate(
    code: 'MYR',
    symbol: 'RM',
    nameTr: 'Malezya Ringgiti',
    ratePerUsd: 4.45,
  ),
  'HKD': GeographyExchangeRate(
    code: 'HKD',
    symbol: r'HK$',
    nameTr: 'Hong Kong Doları',
    ratePerUsd: 7.78,
  ),
  'QAR': GeographyExchangeRate(
    code: 'QAR',
    symbol: 'QR',
    nameTr: 'Katar Riyali',
    ratePerUsd: 3.64,
  ),
  'GEL': GeographyExchangeRate(
    code: 'GEL',
    symbol: '₾',
    nameTr: 'Gürcistan Larisi',
    ratePerUsd: 2.72,
  ),
  'AZN': GeographyExchangeRate(
    code: 'AZN',
    symbol: '₼',
    nameTr: 'Azerbaycan Manatı',
    ratePerUsd: 1.7,
  ),
  'RON': GeographyExchangeRate(
    code: 'RON',
    symbol: 'lei',
    nameTr: 'Romen Leyi',
    ratePerUsd: 4.58,
  ),
};

/// Verilen ISO 4217 para birimi kodu için taban (fallback) kur kaydını döndürür.
GeographyExchangeRate? resolveBaselineExchangeRate(String? currencyCode) {
  final normalized = currencyCode?.trim().toUpperCase() ?? '';
  if (normalized.isEmpty) return null;
  return kBaselineExchangeRates[normalized];
}

/// Ülkenin bulunduğu yarım küre (`NORTHERN` / `SOUTHERN`).
enum GeographyHemisphere {
  northern('NORTHERN', 'Kuzey Yarım Küre'),
  southern('SOUTHERN', 'Güney Yarım Küre');

  const GeographyHemisphere(this.apiValue, this.labelTr);

  final String apiValue;
  final String labelTr;

  static const Set<String> _southernCountryCodes = <String>{
    'ID',
    'BR',
    'AR',
    'CL',
    'PE',
    'ZA',
    'AU',
    'NZ',
  };

  /// Backend JSON'undan gelen `hemisphere` değerini çözer; gelmezse
  /// (eski önbellek/fallback) ülke ve kıta kodundan güvenli çıkarım yapar.
  static GeographyHemisphere fromApi(
    String? raw, {
    required String countryCode,
    required String continentCode,
  }) {
    final normalized = raw?.trim().toUpperCase() ?? '';
    if (normalized == northern.apiValue) {
      return northern;
    }
    if (normalized == southern.apiValue) {
      return southern;
    }

    final normalizedCountry = countryCode.trim().toUpperCase();
    final normalizedContinent = continentCode.trim().toUpperCase();
    if (_southernCountryCodes.contains(normalizedCountry) ||
        normalizedContinent == 'OCEANIA' ||
        (normalizedContinent == 'SOUTH_AMERICA' &&
            normalizedCountry != 'CO')) {
      return southern;
    }
    return northern;
  }
}

/// Coğrafya ağacındaki ülke düğümü (`GET /geography/tree`).
class GeographyCountryNode {
  const GeographyCountryNode({
    required this.id,
    required this.code,
    required this.continentCode,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.aliases,
    required this.flagEmoji,
    required this.imageUrl,
    required this.placesCount,
    required this.routesCount,
    required this.cities,
    this.hemisphere = GeographyHemisphere.northern,
    this.currencyCode = 'USD',
    this.currencySymbol = r'$',
    this.currencyNameTr = 'ABD Doları',
  });

  factory GeographyCountryNode.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';
    final code = json['code']?.toString().trim().toUpperCase() ?? '';
    final continentCode =
        json['continent_code']?.toString().trim().toUpperCase() ?? '';
    final fallbackCurrency = resolveCountryCurrencyFallback(code);
    final rawCurrencyCode =
        json['currency_code']?.toString().trim().toUpperCase() ?? '';
    final rawCurrencySymbol = json['currency_symbol']?.toString().trim() ?? '';
    final rawCurrencyNameTr =
        json['currency_name_tr']?.toString().trim() ?? '';
    final currencyCode =
        rawCurrencyCode.isNotEmpty ? rawCurrencyCode : fallbackCurrency.code;
    final baselineCurrency = kBaselineExchangeRates[currencyCode];
    final currencySymbol = rawCurrencySymbol.isNotEmpty
        ? rawCurrencySymbol
        : (currencyCode == fallbackCurrency.code
            ? fallbackCurrency.symbol
            : (baselineCurrency?.symbol ?? currencyCode));
    final currencyNameTr = rawCurrencyNameTr.isNotEmpty
        ? rawCurrencyNameTr
        : (currencyCode == fallbackCurrency.code
            ? fallbackCurrency.nameTr
            : (baselineCurrency?.nameTr ?? currencyCode));

    final rawCities = json['cities'];
    final cities = rawCities is List
        ? rawCities
            .whereType<Map>()
            .map(
              (item) => GeographyCityNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyCityNode>[];

    return GeographyCountryNode(
      id: json['id']?.toString().trim() ?? '',
      code: code,
      continentCode: continentCode,
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      aliases: parseJsonStringList(json['aliases']),
      flagEmoji: json['flag_emoji']?.toString().trim() ?? '',
      imageUrl: json['image_url']?.toString().trim() ?? '',
      placesCount: parseJsonInt(json['places_count']),
      routesCount: parseJsonInt(json['routes_count']),
      cities: cities,
      hemisphere: GeographyHemisphere.fromApi(
        json['hemisphere']?.toString(),
        countryCode: code,
        continentCode: continentCode,
      ),
      currencyCode: currencyCode,
      currencySymbol: currencySymbol,
      currencyNameTr: currencyNameTr,
    );
  }

  final String id;
  final String code;
  final String continentCode;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final List<String> aliases;
  final String flagEmoji;
  final String imageUrl;
  final int placesCount;
  final int routesCount;
  final List<GeographyCityNode> cities;
  final GeographyHemisphere hemisphere;
  final String currencyCode;
  final String currencySymbol;
  final String currencyNameTr;

  ContinentFilter get continentFilter => ContinentFilter.fromCode(continentCode);

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }

  bool matchesQuery(
    String normalizedQuery,
    String Function(String) normalizer,
  ) {
    return _matchesAnyCandidate(normalizedQuery, normalizer, <String>[
      name,
      defaultName,
      code,
      ...aliases,
      ...nameTranslations.values,
    ]);
  }

  CountryFilterOption toCountryFilterOption({
    bool useRoutesCount = true,
    String lang = 'tr',
  }) {
    return CountryFilterOption(
      code: code,
      nameTr: localizedName(lang),
      flagEmoji: flagEmoji,
      continent: continentFilter,
      publishedRouteCount: useRoutesCount ? routesCount : placesCount,
    );
  }
}

/// Coğrafya ağacındaki alt bölge (region) düğümü (`GET /geography/tree`).
class GeographyRegionNode {
  const GeographyRegionNode({
    required this.id,
    required this.uuid,
    required this.code,
    required this.continentCode,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.imageUrl,
    required this.countryCodes,
    required this.countryNames,
    required this.placesCount,
    required this.routesCount,
  });

  factory GeographyRegionNode.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final code = json['code']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';
    return GeographyRegionNode(
      id: id.isNotEmpty ? id : code,
      uuid: json['uuid']?.toString().trim() ?? '',
      code: code.isNotEmpty ? code : id,
      continentCode:
          json['continent_code']?.toString().trim().toUpperCase() ?? '',
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      imageUrl: json['image_url']?.toString().trim() ?? '',
      countryCodes: parseJsonStringList(json['country_codes'])
          .map((c) => c.toUpperCase())
          .toList(growable: false),
      countryNames: parseJsonStringList(json['country_names']),
      placesCount: parseJsonInt(json['places_count']),
      routesCount: parseJsonInt(json['routes_count']),
    );
  }

  final String id;
  final String uuid;
  final String code;
  final String continentCode;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final String imageUrl;
  final List<String> countryCodes;
  final List<String> countryNames;
  final int placesCount;
  final int routesCount;

  ContinentFilter get continentFilter => ContinentFilter.fromCode(continentCode);

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }

  bool matchesQuery(
    String normalizedQuery,
    String Function(String) normalizer,
  ) {
    return _matchesAnyCandidate(normalizedQuery, normalizer, <String>[
      name,
      defaultName,
      code,
      id,
      ...nameTranslations.values,
    ]);
  }

  RouteRegionCatalogItem toRouteRegionCatalogItem({String lang = 'tr'}) {
    return RouteRegionCatalogItem(
      id: id.isNotEmpty ? id : code,
      name: localizedName(lang),
      continent: continentFilter,
      countryCodes: countryCodes,
      countryTags: countryNames.isNotEmpty ? countryNames : countryCodes,
      imageUrl: imageUrl,
    );
  }
}

/// Coğrafya ağacındaki kıta düğümü (`GET /geography/tree`).
class GeographyContinentNode {
  const GeographyContinentNode({
    required this.id,
    required this.code,
    required this.continentFilter,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.imageUrl,
    required this.placesCount,
    required this.routesCount,
    required this.regions,
    required this.countries,
  });

  factory GeographyContinentNode.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString().trim().toUpperCase() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';

    final rawRegions = json['regions'];
    final regions = rawRegions is List
        ? rawRegions
            .whereType<Map>()
            .map(
              (item) => GeographyRegionNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyRegionNode>[];

    final rawCountries = json['countries'];
    final countries = rawCountries is List
        ? rawCountries
            .whereType<Map>()
            .map(
              (item) => GeographyCountryNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyCountryNode>[];

    return GeographyContinentNode(
      id: json['id']?.toString().trim() ?? '',
      code: code,
      continentFilter: ContinentFilter.fromCode(code),
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      imageUrl: json['image_url']?.toString().trim() ?? '',
      placesCount: parseJsonInt(json['places_count']),
      routesCount: parseJsonInt(json['routes_count']),
      regions: regions,
      countries: countries,
    );
  }

  final String id;
  final String code;
  final ContinentFilter continentFilter;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final String imageUrl;
  final int placesCount;
  final int routesCount;
  final List<GeographyRegionNode> regions;
  final List<GeographyCountryNode> countries;

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }

  bool matchesQuery(
    String normalizedQuery,
    String Function(String) normalizer,
  ) {
    return _matchesAnyCandidate(normalizedQuery, normalizer, <String>[
      name,
      defaultName,
      code,
      ...nameTranslations.values,
    ]);
  }

  RouteContinentCatalogItem toRouteContinentCatalogItem({String lang = 'tr'}) {
    return RouteContinentCatalogItem(
      continent: continentFilter,
      name: localizedName(lang),
      imageUrl: imageUrl,
      regions: regions
          .map((region) => region.toRouteRegionCatalogItem(lang: lang))
          .toList(growable: false),
    );
  }
}

/// Coğrafya ağacındaki global özet seçeneği (`global_option`).
class GeographyGlobalOption {
  const GeographyGlobalOption({
    required this.code,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.imageUrl,
    required this.placesCount,
    required this.routesCount,
  });

  factory GeographyGlobalOption.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? 'Global';
    final defaultName = json['default_name']?.toString().trim() ?? 'Global';
    return GeographyGlobalOption(
      code: json['code']?.toString().trim().toUpperCase() ?? 'GLOBAL',
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      imageUrl: json['image_url']?.toString().trim() ?? '',
      placesCount: parseJsonInt(json['places_count']),
      routesCount: parseJsonInt(json['routes_count']),
    );
  }

  final String code;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final String imageUrl;
  final int placesCount;
  final int routesCount;

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }
}

/// `GET /geography/tree` tam yanıt modeli.
class GeographyTreeResponse {
  const GeographyTreeResponse({
    required this.lang,
    required this.globalOption,
    required this.continents,
    required this.popularCities,
    required this.popularRegions,
    required this.popularContinents,
    this.exchangeRates = const <GeographyExchangeRate>[],
  });

  factory GeographyTreeResponse.fromJson(Map<String, dynamic> json) {
    final rawGlobal = json['global_option'];
    final globalOption = rawGlobal is Map
        ? GeographyGlobalOption.fromJson(Map<String, dynamic>.from(rawGlobal))
        : null;

    final rawContinents = json['continents'];
    final continents = rawContinents is List
        ? rawContinents
            .whereType<Map>()
            .map(
              (item) => GeographyContinentNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyContinentNode>[];

    final rawPopular = json['popular_suggestions'];
    final popularMap = rawPopular is Map
        ? Map<String, dynamic>.from(rawPopular)
        : const <String, dynamic>{};

    final popularCities = popularMap['cities'] is List
        ? (popularMap['cities'] as List)
            .whereType<Map>()
            .map(
              (item) => GeographyCityNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyCityNode>[];

    final popularRegions = popularMap['regions'] is List
        ? (popularMap['regions'] as List)
            .whereType<Map>()
            .map(
              (item) => GeographyRegionNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyRegionNode>[];

    final popularContinents = popularMap['continents'] is List
        ? (popularMap['continents'] as List)
            .whereType<Map>()
            .map(
              (item) => GeographyContinentNode.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <GeographyContinentNode>[];

    final rawExchangeRates = json['exchange_rates'];
    final exchangeRates = rawExchangeRates is List
        ? rawExchangeRates
            .whereType<Map>()
            .map(
              (item) => GeographyExchangeRate.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((rate) => rate.code.isNotEmpty)
            .toList(growable: false)
        : const <GeographyExchangeRate>[];

    return GeographyTreeResponse(
      lang: json['lang']?.toString().trim() ?? 'tr',
      globalOption: globalOption,
      continents: continents,
      popularCities: popularCities,
      popularRegions: popularRegions,
      popularContinents: popularContinents,
      exchangeRates: exchangeRates,
    );
  }

  final String lang;
  final GeographyGlobalOption? globalOption;
  final List<GeographyContinentNode> continents;
  final List<GeographyCityNode> popularCities;
  final List<GeographyRegionNode> popularRegions;
  final List<GeographyContinentNode> popularContinents;
  final List<GeographyExchangeRate> exchangeRates;
}

/// `GET /geography/search` sonuç öğesi.
class GeographySearchResultItem {
  const GeographySearchResultItem({
    required this.type,
    required this.id,
    required this.code,
    required this.name,
    required this.defaultName,
    required this.nameTranslations,
    required this.subtitle,
    this.continentCode,
    this.countryCode,
    this.regionCode,
    this.cityName,
    this.flagEmoji,
    this.imageUrl = '',
  });

  factory GeographySearchResultItem.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString().trim() ?? '';
    final defaultName = json['default_name']?.toString().trim() ?? '';
    final rawContinentCode = json['continent_code']?.toString().trim();
    final rawCountryCode = json['country_code']?.toString().trim();
    final rawRegionCode = json['region_code']?.toString().trim();
    final rawCityName = json['city_name']?.toString().trim();
    final rawFlagEmoji = json['flag_emoji']?.toString().trim();

    final rawCode = json['code']?.toString().trim() ?? '';
    final rawSlug = json['slug']?.toString().trim() ?? '';

    return GeographySearchResultItem(
      type: json['type']?.toString().trim().toLowerCase() ?? '',
      id: json['id']?.toString().trim() ?? '',
      code: rawCode.isNotEmpty ? rawCode : rawSlug,
      name: name.isNotEmpty ? name : defaultName,
      defaultName: defaultName.isNotEmpty ? defaultName : name,
      nameTranslations: _parseStringMap(json['name_translations']),
      subtitle: json['subtitle']?.toString().trim() ?? '',
      continentCode: (rawContinentCode != null && rawContinentCode.isNotEmpty)
          ? rawContinentCode.toUpperCase()
          : null,
      countryCode: (rawCountryCode != null && rawCountryCode.isNotEmpty)
          ? rawCountryCode.toUpperCase()
          : null,
      regionCode: (rawRegionCode != null && rawRegionCode.isNotEmpty)
          ? rawRegionCode
          : null,
      cityName:
          (rawCityName != null && rawCityName.isNotEmpty) ? rawCityName : null,
      flagEmoji: (rawFlagEmoji != null && rawFlagEmoji.isNotEmpty)
          ? rawFlagEmoji
          : null,
      imageUrl: json['image_url']?.toString().trim() ?? '',
    );
  }

  final String type;
  final String id;
  final String code;
  final String name;
  final String defaultName;
  final Map<String, String> nameTranslations;
  final String subtitle;
  final String? continentCode;
  final String? countryCode;
  final String? regionCode;
  final String? cityName;
  final String? flagEmoji;
  final String imageUrl;

  ContinentFilter? get continentFilter =>
      continentCode != null && continentCode!.isNotEmpty
          ? ContinentFilter.fromCode(continentCode)
          : null;

  String localizedName([String lang = 'tr']) {
    return _resolveLocalizedName(
      name: name,
      defaultName: defaultName,
      nameTranslations: nameTranslations,
      lang: lang,
    );
  }
}
