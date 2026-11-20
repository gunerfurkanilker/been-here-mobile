import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../data/stores/geography_store.dart';
import '../../../../domain/models/geography_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/filters/been_here_search_filter_controller.dart';

/// Üstteki 4'lü İlerleme Ağacı
enum RouteWizardStep {
  locations(0, 'Seçili Konumlar'),
  dates(1, 'Seçili Tarih'),
  budget(2, 'Seçili Bütçe'),
  travelers(3, 'Seçili Ziyaretçi');

  const RouteWizardStep(this.stepIndex, this.label);
  final int stepIndex;
  final String label;
}

class BuilderCityCatalogItem {
  const BuilderCityCatalogItem({
    required this.name,
    required this.countryCode,
    required this.countryName,
    required this.imageUrl,
  });

  final String name;
  final String countryCode;
  final String countryName;
  final String imageUrl;
}

class BuilderCountryCatalogItem {
  const BuilderCountryCatalogItem({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.imageUrl,
    required this.cities,
    this.hemisphere = GeographyHemisphere.northern,
    String currencyCode = '',
    String currencySymbol = '',
    String currencyNameTr = '',
  })  : _rawCurrencyCode = currencyCode,
        _rawCurrencySymbol = currencySymbol,
        _rawCurrencyNameTr = currencyNameTr;

  final String code;
  final String name;
  final String flagEmoji;
  final String imageUrl;
  final List<BuilderCityCatalogItem> cities;
  final GeographyHemisphere hemisphere;
  final String _rawCurrencyCode;
  final String _rawCurrencySymbol;
  final String _rawCurrencyNameTr;

  String get currencyCode {
    final raw = _rawCurrencyCode.trim().toUpperCase();
    if (raw.isNotEmpty) return raw;
    return resolveCountryCurrencyFallback(code).code;
  }

  String get currencySymbol {
    final raw = _rawCurrencySymbol.trim();
    if (raw.isNotEmpty) return raw;
    final resolvedCode = currencyCode;
    final fallback = resolveCountryCurrencyFallback(code);
    if (resolvedCode == fallback.code) return fallback.symbol;
    return resolveBaselineExchangeRate(resolvedCode)?.symbol ?? resolvedCode;
  }

  String get currencyNameTr {
    final raw = _rawCurrencyNameTr.trim();
    if (raw.isNotEmpty) return raw;
    final resolvedCode = currencyCode;
    final fallback = resolveCountryCurrencyFallback(code);
    if (resolvedCode == fallback.code) return fallback.nameTr;
    return resolveBaselineExchangeRate(resolvedCode)?.nameTr ?? resolvedCode;
  }
}

/// Seçili ülkelerden veya popüler katalogdan türetilen tekilleştirilmiş para birimi seçeneği
class BuilderCountryCurrencyOption {
  const BuilderCountryCurrencyOption({
    required this.code,
    required this.symbol,
    required this.nameTr,
    required this.countryNames,
    required this.flagEmojis,
  });

  final String code;
  final String symbol;
  final String nameTr;
  final List<String> countryNames;
  final List<String> flagEmojis;

  String get flagsText => flagEmojis.join();
  String get countriesSummary => countryNames.join(', ');
}

/// Kıtaların Alt Bölgeleri (Örn: Batı Avrupa, Doğu Avrupa, İskandinavya)
class BuilderSubRegionCatalogItem {
  const BuilderSubRegionCatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.countries,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<BuilderCountryCatalogItem> countries;
}

class BuilderContinentCatalogItem {
  const BuilderContinentCatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.subRegions,
  });

  final String id;
  final String name;
  final String imageUrl;
  final List<BuilderSubRegionCatalogItem> subRegions;

  List<BuilderCountryCatalogItem> get allCountries => [
        for (final sr in subRegions) ...sr.countries,
      ];
}

enum RouteDateMode {
  flexible('FLEXIBLE', 'Esnek Tarihler'),
  instantTrip('CURRENT_OR_PAST_TRIP', 'Anlık Gezi'),
  seasons('SEASONS', 'Mevsimler'),
  customRange('CUSTOM_RANGE', 'Belirli Tarihler');

  const RouteDateMode(this.apiValue, this.labelTr);
  final String apiValue;
  final String labelTr;
}

/// Adım 2 (Tarih Aralığı Seçimi) içindeki alt ekran durumu
enum RouteDateSubView {
  hub,
  flexibleMonths,
  instantCalendar,
  seasons,
  specificCalendar,
}

/// Mevsimler modundaki 4 mevsim (2x2 sıra: Yaz | İlkbahar, Sonbahar | Kış)
enum RouteSeason {
  summer('SUMMER', 'Yaz'),
  spring('SPRING', 'İlkbahar'),
  autumn('AUTUMN', 'Sonbahar'),
  winter('WINTER', 'Kış');

  const RouteSeason(this.apiValue, this.labelTr);
  final String apiValue;
  final String labelTr;
}

/// Backend rota oluşturma / sihirbaz API gönderimi için tarih özeti modeli
class RouteDateSelectionPayload {
  const RouteDateSelectionPayload({
    required this.dateMode,
    this.startDate,
    this.endDate,
    this.flexiblePeriod,
    required this.dateRangeLabel,
  });

  final String dateMode;
  final String? startDate;
  final String? endDate;
  final String? flexiblePeriod;
  final String dateRangeLabel;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date_mode': dateMode,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (flexiblePeriod != null) 'flexible_period': flexiblePeriod,
      'date_range_label': dateRangeLabel,
    };
  }
}

enum RouteBudgetCurrency {
  tryCurrency('₺', 'TRY', 100000),
  eurCurrency('€', 'EUR', 5000),
  usdCurrency('\$', 'USD', 5000);

  const RouteBudgetCurrency(this.symbol, this.code, this.maxLimit);
  final String symbol;
  final String code;
  final double maxLimit;
}

class RouteBuilderViewModel extends ChangeNotifier
    implements BeenHereSearchFilterController {
  RouteBuilderViewModel({
    this._geographyStore,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _geographyStore?.addListener(_handleGeographyStoreChanged);
  }

  final GeographyStore? _geographyStore;
  final DateTime Function() _clock;

  void _handleGeographyStoreChanged() {
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  @override
  void dispose() {
    _geographyStore?.removeListener(_handleGeographyStoreChanged);
    super.dispose();
  }

  RouteWizardStep _currentStep = RouteWizardStep.locations;
  RouteWizardStep get currentStep => _currentStep;

  /// Ortak arama paneli ve filtre çubuğunda kullanılan toggle/kaldırılabilir filtre hapları
  /// (Rota için seçilen _selectedCountryCodes / _selectedCityKeys alanlarından tamamen bağımsızdır)
  final List<RouteFeedFilterPill> _filterPills = <RouteFeedFilterPill>[];

  /// 1. Satır: Aktif Seçili Kıta (Varsayılan: null — tüm ülkeler doğrudan listelenir)
  /// Null olduğunda tüm ülkeler doğrudan listelenir.
  String? _activeContinentId;
  String? get activeContinentId => _activeContinentId;

  /// 2. Satır: Aktif Seçili Alt Bölge
  String? _activeSubRegionId;
  String? get activeSubRegionId => _activeSubRegionId;

  /// 3. Satır: Ülke ve Şehir Adı Filtresi
  String _searchFilterQuery = '';
  String get searchFilterQuery => _searchFilterQuery;

  /// Seçili ülke kodları
  final Set<String> _selectedCountryCodes = <String>{};
  Set<String> get selectedCountryCodes =>
      Set<String>.unmodifiable(_selectedCountryCodes);

  /// Seçili şehir anahtarları ('countryCode:cityName')
  final Set<String> _selectedCityKeys = <String>{};
  Set<String> get selectedCityKeys =>
      Set<String>.unmodifiable(_selectedCityKeys);

  // Tarih, Bütçe, Ziyaretçi state'leri
  RouteDateMode _dateMode = RouteDateMode.flexible;
  RouteDateMode get dateMode => _dateMode;

  RouteDateSubView _dateSubView = RouteDateSubView.hub;
  RouteDateSubView get dateSubView => _dateSubView;

  // Mod 1: Esnek Tarihler (Ay Aralığı)
  DateTime? _flexibleStartMonth;
  DateTime? get flexibleStartMonth => _flexibleStartMonth;
  DateTime? _flexibleEndMonth;
  DateTime? get flexibleEndMonth => _flexibleEndMonth;

  // Mod 2: Anlık Gezi (Bugünü kapsayan aralık)
  DateTimeRange? _instantTripRange;
  DateTimeRange? get instantTripRange => _instantTripRange;
  DateTime? _instantTripPendingDate;
  DateTime? get instantTripPendingDate => _instantTripPendingDate;
  String? _instantTripValidationError;
  String? get instantTripValidationError => _instantTripValidationError;

  // Mod 3: Mevsimler
  GeographyHemisphere _selectedHemisphere = GeographyHemisphere.northern;
  GeographyHemisphere get selectedHemisphere => _selectedHemisphere;
  bool _hasManualHemisphereOverride = false;
  bool get hasManualHemisphereOverride => _hasManualHemisphereOverride;
  final Set<RouteSeason> _selectedSeasons = <RouteSeason>{};
  Set<RouteSeason> get selectedSeasons => Set<RouteSeason>.unmodifiable(_selectedSeasons);

  // Mod 4: Belirli Tarihler (Bugün ve ileri tarihler)
  DateTimeRange? _customDateRange;
  DateTime? _specificPendingStartDate;
  DateTime? get specificPendingStartDate => _specificPendingStartDate;
  DateTimeRange? get customDateRange =>
      _dateMode == RouteDateMode.instantTrip ? _instantTripRange : _customDateRange;
  DateTimeRange? get specificDateRange => _customDateRange;

  bool _isBudgetEnabled = true;
  bool get isBudgetEnabled => _isBudgetEnabled;

  String _userCurrencyCode = 'TRY';
  String get userCurrencyCode => _userCurrencyCode;
  String get secondaryCurrencyCode => 'USD';

  RouteBudgetCurrency get currency {
    switch (_userCurrencyCode) {
      case 'EUR':
        return RouteBudgetCurrency.eurCurrency;
      case 'USD':
        return RouteBudgetCurrency.usdCurrency;
      default:
        return RouteBudgetCurrency.tryCurrency;
    }
  }

  double _minBudget = 0.0;
  double? _maxBudget;
  double get minBudget => _minBudget;
  double? get maxBudget => _maxBudget;
  bool get isMaxBudgetOpenEnded => _maxBudget == null;

  final List<String> _addedCountryCurrencyCodes = <String>[];
  List<String> get addedCountryCurrencyCodes =>
      List<String>.unmodifiable(_addedCountryCurrencyCodes);

  int _adultsCount = 2;
  int _childrenCount = 0;
  int get adultsCount => _adultsCount;
  int get childrenCount => _childrenCount;
  int get totalTravelersCount => _adultsCount + _childrenCount;

  /// Fotoğrafı bulunmayan şehir ve ülke kartlarında kullanılacak yerel yer tutucu görsel.
  static const String cityPlaceholderAsset =
      'assets/images/city_placeholder_skyline.jpg';

  /// Türkçe karakter duyarlı arama normalizasyonu
  static String _normalizeTr(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  // ===========================================================================
  // KITA -> ALT BÖLGE -> ÜLKE -> ŞEHİR KATALOĞU
  // ===========================================================================
  static const List<BuilderContinentCatalogItem> continentsCatalog = [
    // 1. AVRUPA
    BuilderContinentCatalogItem(
      id: 'europe',
      name: 'Avrupa',
      imageUrl:
          'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=700&q=80',
      subRegions: [
        // 1.1 BATI AVRUPA (Taslaktaki örnek ülke/şehirlerle uyumlu)
        BuilderSubRegionCatalogItem(
          id: 'western_europe',
          name: 'Batı Avrupa',
          imageUrl:
              'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'ES',
              name: 'İspanya',
              flagEmoji: '🇪🇸',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Sevilla',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Cadiz',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Madrid',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Barselona',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'TR',
              name: 'Türkiye',
              flagEmoji: '🇹🇷',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'İstanbul',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'İzmir',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Ankara',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Fethiye',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Marmaris',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'FR',
              name: 'Fransa',
              flagEmoji: '🇫🇷',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Paris',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Lyon',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Marsilya',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'GB',
              name: 'İngiltere',
              flagEmoji: '🇬🇧',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Londra',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Manchester',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'York',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'IT',
              name: 'İtalya',
              flagEmoji: '🇮🇹',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Roma',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Floransa',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Venedik',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'BE',
              name: 'Belçika',
              flagEmoji: '🇧🇪',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Brugge',
                  countryCode: 'BE',
                  countryName: 'Belçika',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Brüksel',
                  countryCode: 'BE',
                  countryName: 'Belçika',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'NL',
              name: 'Hollanda',
              flagEmoji: '🇳🇱',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Amsterdam',
                  countryCode: 'NL',
                  countryName: 'Hollanda',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Rotterdam',
                  countryCode: 'NL',
                  countryName: 'Hollanda',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),

        // 1.2 DOĞU AVRUPA
        BuilderSubRegionCatalogItem(
          id: 'eastern_europe',
          name: 'Doğu Avrupa',
          imageUrl:
              'https://images.unsplash.com/photo-1541849546-216549ae216d?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'CZ',
              name: 'Çekya',
              flagEmoji: '🇨🇿',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Prag',
                  countryCode: 'CZ',
                  countryName: 'Çekya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Cesky Krumlov',
                  countryCode: 'CZ',
                  countryName: 'Çekya',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'HU',
              name: 'Macaristan',
              flagEmoji: '🇭🇺',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Budapeşte',
                  countryCode: 'HU',
                  countryName: 'Macaristan',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Estergon',
                  countryCode: 'HU',
                  countryName: 'Macaristan',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'PL',
              name: 'Polonya',
              flagEmoji: '🇵🇱',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Krakov',
                  countryCode: 'PL',
                  countryName: 'Polonya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Varşova',
                  countryCode: 'PL',
                  countryName: 'Polonya',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),

        // 1.3 İSKANDİNAVYA
        BuilderSubRegionCatalogItem(
          id: 'scandinavia',
          name: 'İskandinavya',
          imageUrl:
              'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'NO',
              name: 'Norveç',
              flagEmoji: '🇳🇴',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Oslo',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Bergen',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Tromsø',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'SE',
              name: 'İsveç',
              flagEmoji: '🇸🇪',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Stockholm',
                  countryCode: 'SE',
                  countryName: 'İsveç',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Göteborg',
                  countryCode: 'SE',
                  countryName: 'İsveç',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 2. ASYA
    BuilderContinentCatalogItem(
      id: 'asia',
      name: 'Asya',
      imageUrl:
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=700&q=80',
      subRegions: [
        BuilderSubRegionCatalogItem(
          id: 'east_asia',
          name: 'Doğu Asya',
          imageUrl:
              'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'JP',
              name: 'Japonya',
              flagEmoji: '🇯🇵',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Tokyo',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Kyoto',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Osaka',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'RU',
              name: 'Rusya',
              flagEmoji: '🇷🇺',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Moskova',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'St. Petersburg',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Kazan',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
        BuilderSubRegionCatalogItem(
          id: 'southeast_asia',
          name: 'Güneydoğu Asya',
          imageUrl:
              'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'TH',
              name: 'Tayland',
              flagEmoji: '🇹🇭',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Phuket',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Bangkok',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Chiang Mai',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 3. AFRİKA
    BuilderContinentCatalogItem(
      id: 'africa',
      name: 'Afrika',
      imageUrl:
          'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=700&q=80',
      subRegions: [
        BuilderSubRegionCatalogItem(
          id: 'north_africa',
          name: 'Kuzey Afrika',
          imageUrl:
              'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'MA',
              name: 'Fas',
              flagEmoji: '🇲🇦',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Marakeş',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Kazablanka',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Şafşavan',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
        BuilderSubRegionCatalogItem(
          id: 'south_africa_region',
          name: 'Güney Afrika',
          imageUrl:
              'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'ZA',
              name: 'Güney Afrika',
              flagEmoji: '🇿🇦',
              hemisphere: GeographyHemisphere.southern,
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Cape Town',
                  countryCode: 'ZA',
                  countryName: 'Güney Afrika',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Johannesburg',
                  countryCode: 'ZA',
                  countryName: 'Güney Afrika',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 4. KUZEY AMERİKA
    BuilderContinentCatalogItem(
      id: 'north_america',
      name: 'Kuzey Amerika',
      imageUrl:
          'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=700&q=80',
      subRegions: [
        BuilderSubRegionCatalogItem(
          id: 'usa_canada',
          name: 'ABD & Kanada',
          imageUrl:
              'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'US',
              name: 'ABD',
              flagEmoji: '🇺🇸',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'New York',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'San Francisco',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Los Angeles',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'CA',
              name: 'Kanada',
              flagEmoji: '🇨🇦',
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Toronto',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Vancouver',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Montreal',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 5. OKYANUSYA
    BuilderContinentCatalogItem(
      id: 'oceania',
      name: 'Okyanusya',
      imageUrl:
          'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=700&q=80',
      subRegions: [
        BuilderSubRegionCatalogItem(
          id: 'australia_nz',
          name: 'Avustralya & Yeni Zelanda',
          imageUrl:
              'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=700&q=80',
          countries: [
            BuilderCountryCatalogItem(
              code: 'AU',
              name: 'Avustralya',
              flagEmoji: '🇦🇺',
              hemisphere: GeographyHemisphere.southern,
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Sidney',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Melbourne',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Brisbane',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl: '',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'NZ',
              name: 'Yeni Zelanda',
              flagEmoji: '🇳🇿',
              hemisphere: GeographyHemisphere.southern,
              imageUrl: '',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Queenstown',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Auckland',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl: '',
                ),
                BuilderCityCatalogItem(
                  name: 'Wellington',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl: '',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  static String cityKey(String countryCode, String cityName) =>
      '$countryCode:$cityName';

  static String _canonicalContinentId(ContinentFilter filter, String rawCode) {
    switch (filter) {
      case ContinentFilter.europe:
        return 'europe';
      case ContinentFilter.asia:
        return 'asia';
      case ContinentFilter.africa:
        return 'africa';
      case ContinentFilter.northAmerica:
        return 'north_america';
      case ContinentFilter.southAmerica:
        return 'south_america';
      case ContinentFilter.oceania:
        return 'oceania';
      case ContinentFilter.global:
        return rawCode.trim().toLowerCase();
    }
  }

  static String _sanitizeLocationImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.toLowerCase().contains('images.unsplash.com')) {
      return '';
    }
    return trimmed;
  }

  static BuilderCountryCatalogItem _mapCountryNodeToBuilder(
    GeographyCountryNode country,
    String lang,
  ) {
    final countryName = country.localizedName(lang).isNotEmpty
        ? country.localizedName(lang)
        : country.name;
    final mappedCities = country.cities.map((city) {
      final cityName = city.localizedName(lang).isNotEmpty
          ? city.localizedName(lang)
          : city.name;
      return BuilderCityCatalogItem(
        name: cityName,
        countryCode: country.code,
        countryName: countryName,
        imageUrl: _sanitizeLocationImageUrl(city.imageUrl),
      );
    }).toList(growable: false);

    var resolvedCountryImage = _sanitizeLocationImageUrl(country.imageUrl);
    if (resolvedCountryImage.isEmpty) {
      for (final city in mappedCities) {
        if (city.imageUrl.trim().isNotEmpty) {
          resolvedCountryImage = city.imageUrl;
          break;
        }
      }
    }

    return BuilderCountryCatalogItem(
      code: country.code,
      name: countryName,
      flagEmoji: country.flagEmoji,
      imageUrl: resolvedCountryImage,
      hemisphere: country.hemisphere,
      currencyCode: country.currencyCode,
      currencySymbol: country.currencySymbol,
      currencyNameTr: country.currencyNameTr,
      cities: mappedCities,
    );
  }

  /// Yüklü `GeographyStore` varsa DB coğrafya ağacını, aksi halde statik kataloğu döndürür.
  @protected
  List<BuilderContinentCatalogItem> get activeContinentsCatalog {
    final store = _geographyStore;
    if (store == null || !store.hasLoaded || store.continents.isEmpty) {
      return continentsCatalog;
    }

    final lang = store.lang;
    return store.continents.map((continentNode) {
      final continentId = _canonicalContinentId(
        continentNode.continentFilter,
        continentNode.code,
      );
      final continentName = continentNode.localizedName(lang).isNotEmpty
          ? continentNode.localizedName(lang)
          : continentNode.name;

      final countriesByCode = <String, GeographyCountryNode>{
        for (final country in continentNode.countries)
          country.code.toUpperCase(): country,
      };
      final assignedCodes = <String>{};

      final subRegions = <BuilderSubRegionCatalogItem>[];
      for (final regionNode in continentNode.regions) {
        final regionId =
            regionNode.id.isNotEmpty ? regionNode.id : regionNode.code;
        final regionName = regionNode.localizedName(lang).isNotEmpty
            ? regionNode.localizedName(lang)
            : regionNode.name;
        final regionCountries = <BuilderCountryCatalogItem>[];
        for (final rawCode in regionNode.countryCodes) {
          final upperCode = rawCode.trim().toUpperCase();
          final countryNode = countriesByCode[upperCode];
          if (countryNode != null) {
            assignedCodes.add(upperCode);
            regionCountries.add(_mapCountryNodeToBuilder(countryNode, lang));
          }
        }
        subRegions.add(
          BuilderSubRegionCatalogItem(
            id: regionId,
            name: regionName,
            imageUrl: regionNode.imageUrl,
            countries: regionCountries,
          ),
        );
      }

      final unassignedCountries = continentNode.countries
          .where((c) => !assignedCodes.contains(c.code.toUpperCase()))
          .map((c) => _mapCountryNodeToBuilder(c, lang))
          .toList(growable: false);
      if (unassignedCountries.isNotEmpty) {
        subRegions.add(
          BuilderSubRegionCatalogItem(
            id: continentNode.regions.isEmpty
                ? '${continentId}_all'
                : '${continentId}_other',
            name: continentNode.regions.isEmpty ? continentName : 'Diğer',
            imageUrl: continentNode.imageUrl,
            countries: unassignedCountries,
          ),
        );
      }

      return BuilderContinentCatalogItem(
        id: continentId,
        name: continentName,
        imageUrl: continentNode.imageUrl,
        subRegions: subRegions,
      );
    }).toList(growable: false);
  }

  /// Aktif seçili kıta objesi (Null ise tüm dünyayı listeler)
  BuilderContinentCatalogItem? get activeContinent {
    if (_activeContinentId == null) return null;
    for (final c in activeContinentsCatalog) {
      if (c.id == _activeContinentId) return c;
    }
    return null;
  }

  /// Aktif seçili alt bölge objesi
  BuilderSubRegionCatalogItem? get activeSubRegion {
    final cont = activeContinent;
    if (cont == null || _activeSubRegionId == null) return null;
    for (final sr in cont.subRegions) {
      if (sr.id == _activeSubRegionId) return sr;
    }
    return null;
  }

  /// Seçili kıtanın alt bölgeleri (Batı Avrupa, Doğu Avrupa, İskandinavya...)
  List<BuilderSubRegionCatalogItem> get currentSubRegions {
    final cont = activeContinent;
    if (cont == null) return const [];
    return cont.subRegions;
  }

  /// Herhangi bir filtre (kıta, bölge veya arama metni) aktif mi?
  bool get hasActiveFilter =>
      _activeContinentId != null ||
      _activeSubRegionId != null ||
      _searchFilterQuery.isNotEmpty;

  /// Kıta çipine tıklandığında:
  /// Tekrar aynı kıtaya basılırsa kaldırılır (toggle). Farklı kıta seçilirse alt bölge null yapılır.
  void selectContinent(String? continentId) {
    if (_activeContinentId == continentId) {
      _activeContinentId = null;
      _activeSubRegionId = null;
    } else {
      _activeContinentId = continentId;
      _activeSubRegionId = null;
    }
    notifyListeners();
  }

  /// Kıta filtresini kaldırır
  void clearContinentFilter() {
    _activeContinentId = null;
    _activeSubRegionId = null;
    notifyListeners();
  }

  /// Alt bölge çipine tıklandığında:
  /// Tekrar tıklanırsa kaldırılır (toggle).
  void selectSubRegion(String? subRegionId) {
    if (_activeSubRegionId == subRegionId) {
      _activeSubRegionId = null;
    } else {
      _activeSubRegionId = subRegionId;
    }
    notifyListeners();
  }

  /// Alt bölge filtresini kaldırır
  void clearSubRegionFilter() {
    _activeSubRegionId = null;
    notifyListeners();
  }

  /// Arama kutusu metnini günceller
  void updateSearchFilterQuery(String query) {
    _searchFilterQuery = _normalizeTr(query);
    notifyListeners();
  }

  /// Arama filtresini temizler
  void clearSearchFilter() {
    _searchFilterQuery = '';
    notifyListeners();
  }

  /// Tüm görüntüleme filtrelerini sıfırlar (kullanıcının seçtiği rota ülke/şehirlerine dokunmaz)
  void clearAllFilters() {
    _activeContinentId = null;
    _activeSubRegionId = null;
    _searchFilterQuery = '';
    _filterPills.clear();
    notifyListeners();
  }

  // ===========================================================================
  // BeenHereSearchFilterController SÖZLEŞMESİ
  // ===========================================================================

  @override
  Future<void> triggerRemoteGeographySearch(String query) async {
    final store = _geographyStore;
    if (store == null || (store.hasLoaded && store.tree != null)) return;
    await store.searchRemote(query, lang: store.lang);
  }

  static ContinentFilter _mapContinentId(String id) {
    switch (id) {
      case 'europe':
        return ContinentFilter.europe;
      case 'asia':
        return ContinentFilter.asia;
      case 'africa':
        return ContinentFilter.africa;
      case 'north_america':
        return ContinentFilter.northAmerica;
      case 'south_america':
        return ContinentFilter.southAmerica;
      case 'oceania':
        return ContinentFilter.oceania;
      default:
        return ContinentFilter.global;
    }
  }

  ({
    BuilderContinentCatalogItem continent,
    BuilderSubRegionCatalogItem subRegion,
  })? _findLocationForCountry(String countryCode) {
    for (final continent in activeContinentsCatalog) {
      for (final subRegion in continent.subRegions) {
        for (final country in subRegion.countries) {
          if (country.code == countryCode) {
            return (continent: continent, subRegion: subRegion);
          }
        }
      }
    }
    return null;
  }

  @override
  List<RouteFeedFilterPill> get filterPills =>
      List<RouteFeedFilterPill>.unmodifiable(_filterPills);

  @override
  bool get hasFilterPills => _filterPills.isNotEmpty;

  @override
  int get enabledFilterPillsCount =>
      _filterPills.where((p) => p.isEnabled).length;

  @override
  int get activeFilterCount => enabledFilterPillsCount;

  @override
  List<RouteContinentCatalogItem> get searchContinentsCatalog {
    return activeContinentsCatalog.map((c) {
      final continentFilter = _mapContinentId(c.id);
      return RouteContinentCatalogItem(
        continent: continentFilter,
        name: c.name,
        imageUrl: c.imageUrl,
        regions: c.subRegions.map((sr) {
          return RouteRegionCatalogItem(
            id: sr.id,
            name: sr.name,
            continent: continentFilter,
            countryCodes:
                sr.countries.map((country) => country.code).toList(growable: false),
            countryTags:
                sr.countries.map((country) => country.name).toList(growable: false),
            imageUrl: sr.imageUrl,
          );
        }).toList(growable: false),
      );
    }).toList(growable: false);
  }

  @override
  int countItemsForContinent(ContinentFilter continent) {
    for (final c in activeContinentsCatalog) {
      if (_mapContinentId(c.id) == continent) {
        return c.allCountries.map((country) => country.code).toSet().length;
      }
    }
    return 0;
  }

  @override
  int countItemsForRegion(RouteRegionCatalogItem region) {
    for (final c in activeContinentsCatalog) {
      for (final sr in c.subRegions) {
        if (sr.id == region.id) {
          return sr.countries.length;
        }
      }
    }
    return region.countryCodes.length;
  }

  @override
  String get itemCountUnitLabel => 'Ülke';

  @override
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      final dbSuggestions = store.buildSearchSuggestions(
        query,
        lang: store.lang,
      );
      if (dbSuggestions.isNotEmpty) {
        return dbSuggestions;
      }
    }

    final trimmed = query.trim();
    final q = _normalizeTr(trimmed);

    if (q.isEmpty) {
      return const [
        RouteSearchSuggestion(
          id: 'popular:city:marmaris',
          type: RouteSearchSuggestionType.city,
          title: 'Marmaris',
          subtitle: 'Avrupa - Türkiye',
          pill: RouteFeedFilterPill(
            id: 'city:marmaris',
            type: RouteFilterPillType.city,
            label: 'Marmaris',
            cityName: 'Marmaris',
            countryCode: 'TR',
          ),
        ),
        RouteSearchSuggestion(
          id: 'popular:city:roma',
          type: RouteSearchSuggestionType.city,
          title: 'Roma',
          subtitle: 'Avrupa - İtalya',
          pill: RouteFeedFilterPill(
            id: 'city:roma',
            type: RouteFilterPillType.city,
            label: 'Roma',
            cityName: 'Roma',
            countryCode: 'IT',
          ),
        ),
        RouteSearchSuggestion(
          id: 'popular:city:madrid',
          type: RouteSearchSuggestionType.city,
          title: 'Madrid',
          subtitle: 'Avrupa - İspanya',
          pill: RouteFeedFilterPill(
            id: 'city:madrid',
            type: RouteFilterPillType.city,
            label: 'Madrid',
            cityName: 'Madrid',
            countryCode: 'ES',
          ),
        ),
        RouteSearchSuggestion(
          id: 'popular:region:western_europe',
          type: RouteSearchSuggestionType.region,
          title: 'Batı Avrupa',
          subtitle: 'Avrupa - Bölge',
          pill: RouteFeedFilterPill(
            id: 'region:western_europe',
            type: RouteFilterPillType.region,
            label: 'Batı Avrupa',
            regionId: 'western_europe',
            continent: ContinentFilter.europe,
          ),
        ),
        RouteSearchSuggestion(
          id: 'popular:continent:EUROPE',
          type: RouteSearchSuggestionType.continent,
          title: 'Avrupa',
          subtitle: 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:EUROPE',
            type: RouteFilterPillType.continent,
            label: 'Avrupa',
            continent: ContinentFilter.europe,
          ),
        ),
      ];
    }

    final suggestions = <RouteSearchSuggestion>[
      RouteSearchSuggestion(
        id: 'keyword:$q',
        type: RouteSearchSuggestionType.keyword,
        title: '$trimmed ile arama yap',
        subtitle: '(kelime ile arama)',
        pill: RouteFeedFilterPill(
          id: 'keyword:$q',
          type: RouteFilterPillType.keyword,
          label: '"$trimmed"',
          keyword: trimmed,
        ),
      ),
    ];

    final seenCityIds = <String>{};
    final seenCountryCodes = <String>{};
    final catalog = activeContinentsCatalog;

    // 1. Eşleşen şehirler
    for (final continent in catalog) {
      for (final subRegion in continent.subRegions) {
        for (final country in subRegion.countries) {
          for (final city in country.cities) {
            final normCity = _normalizeTr(city.name);
            if (normCity.contains(q) && seenCityIds.add(normCity)) {
              suggestions.add(
                RouteSearchSuggestion(
                  id: 'city:$normCity',
                  type: RouteSearchSuggestionType.city,
                  title: city.name,
                  subtitle: '${continent.name} - ${country.name}',
                  pill: RouteFeedFilterPill(
                    id: 'city:$normCity',
                    type: RouteFilterPillType.city,
                    label: city.name,
                    cityName: city.name,
                    countryCode: country.code,
                  ),
                ),
              );
            }
          }
        }
      }
    }

    // 2. Eşleşen ülkeler
    for (final continent in catalog) {
      for (final subRegion in continent.subRegions) {
        for (final country in subRegion.countries) {
          if ((_normalizeTr(country.name).contains(q) ||
                  _normalizeTr(country.code) == q) &&
              seenCountryCodes.add(country.code)) {
            suggestions.add(
              RouteSearchSuggestion(
                id: 'country:${country.code}',
                type: RouteSearchSuggestionType.country,
                title: country.name,
                subtitle: '${continent.name} - Ülke',
                pill: RouteFeedFilterPill(
                  id: 'country:${country.code}',
                  type: RouteFilterPillType.country,
                  label: country.name,
                  countryCode: country.code,
                ),
              ),
            );
          }
        }
      }
    }

    // 3. Eşleşen alt bölgeler ve kıtalar
    for (final continent in catalog) {
      final continentFilter = _mapContinentId(continent.id);
      for (final subRegion in continent.subRegions) {
        if (_normalizeTr(subRegion.name).contains(q)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'region:${subRegion.id}',
              type: RouteSearchSuggestionType.region,
              title: subRegion.name,
              subtitle: '${continent.name} - Bölge',
              pill: RouteFeedFilterPill(
                id: 'region:${subRegion.id}',
                type: RouteFilterPillType.region,
                label: subRegion.name,
                regionId: subRegion.id,
                continent: continentFilter,
              ),
            ),
          );
        }
      }
      if (_normalizeTr(continent.name).contains(q)) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'continent:${continentFilter.code}',
            type: RouteSearchSuggestionType.continent,
            title: continent.name,
            subtitle: 'Kıta',
            pill: RouteFeedFilterPill(
              id: 'continent:${continentFilter.code}',
              type: RouteFilterPillType.continent,
              label: continent.name,
              continent: continentFilter,
            ),
          ),
        );
      }
    }

    return suggestions;
  }

  @override
  void applyFilterPills(List<RouteFeedFilterPill> pills) {
    _filterPills.clear();
    final seenIds = <String>{};
    for (final pill in pills) {
      if (!seenIds.add(pill.id)) continue;
      if (pill.type == RouteFilterPillType.keyword) {
        _filterPills.removeWhere((p) => p.type == RouteFilterPillType.keyword);
      }
      _filterPills.add(pill);
    }
    notifyListeners();
  }

  @override
  void toggleFilterPill(String pillId) {
    final index = _filterPills.indexWhere((p) => p.id == pillId);
    if (index == -1) return;
    _filterPills[index] = _filterPills[index].copyWith(
      isEnabled: !_filterPills[index].isEnabled,
    );
    notifyListeners();
  }

  @override
  void removeFilterPill(String pillId) {
    final before = _filterPills.length;
    _filterPills.removeWhere((p) => p.id == pillId);
    if (_filterPills.length != before) {
      notifyListeners();
    }
  }

  /// Yalnızca görüntüleme filtre haplarını temizler; kullanıcının rota için seçtiği
  /// ülke ve şehir seçimlerini (_selectedCountryCodes / _selectedCityKeys) ASLA silmez.
  @override
  void clearAllFilterPills() {
    if (_filterPills.isEmpty) return;
    _filterPills.clear();
    notifyListeners();
  }

  @override
  bool get isNearbyMode => false;

  @override
  String get detectedLocationLabel => '';

  @override
  void toggleNearbySearch() {}

  @override
  double get selectedMinBudgetTl => 0;

  @override
  double get selectedMaxBudgetTl => 0;

  @override
  bool get isBudgetFilterActive => false;

  @override
  String get budgetFilterCompactLabel => '';

  @override
  void updateBudgetRange(double minTl, double maxTl) {}

  @override
  void resetBudgetFilter() {}

  bool _countryMatchesWholeLocationPill(
    BuilderCountryCatalogItem country,
    RouteFeedFilterPill pill,
  ) {
    switch (pill.type) {
      case RouteFilterPillType.continent:
        final loc = _findLocationForCountry(country.code);
        return loc != null &&
            pill.continent != null &&
            _mapContinentId(loc.continent.id) == pill.continent;
      case RouteFilterPillType.region:
        final loc = _findLocationForCountry(country.code);
        return loc != null &&
            pill.regionId != null &&
            loc.subRegion.id == pill.regionId;
      case RouteFilterPillType.country:
        return pill.countryCode != null && country.code == pill.countryCode;
      case RouteFilterPillType.city:
      case RouteFilterPillType.district:
      case RouteFilterPillType.keyword:
        return false;
    }
  }

  GeographyCityNode? _findCityNode(String countryCode, String cityName) {
    final store = _geographyStore;
    if (store == null || !store.hasLoaded) return null;
    final normTarget = _normalizeTr(cityName);
    for (final city in store.getCityNodesForCountry(countryCode)) {
      if (_normalizeTr(city.localizedName(store.lang)) == normTarget ||
          _normalizeTr(city.name) == normTarget) {
        return city;
      }
    }
    return null;
  }

  bool _countryOrAncestorsMatchQuery(
    BuilderCountryCatalogItem country,
    String normalizedQuery,
  ) {
    final loc = _findLocationForCountry(country.code);
    if (_normalizeTr(country.name).contains(normalizedQuery) ||
        _normalizeTr(country.code) == normalizedQuery ||
        (loc != null &&
            (_normalizeTr(loc.subRegion.name).contains(normalizedQuery) ||
                _normalizeTr(loc.continent.name).contains(normalizedQuery)))) {
      return true;
    }

    final store = _geographyStore;
    if (store == null || !store.hasLoaded) return false;

    if (store.findCountry(country.code)?.matchesQuery(
          normalizedQuery,
          _normalizeTr,
        ) ??
        false) {
      return true;
    }
    if (loc != null) {
      if (store.findRegion(loc.subRegion.id)?.matchesQuery(
            normalizedQuery,
            _normalizeTr,
          ) ??
          false) {
        return true;
      }
      if (store
              .findContinent(_mapContinentId(loc.continent.id))
              ?.matchesQuery(normalizedQuery, _normalizeTr) ??
          false) {
        return true;
      }
    }
    return false;
  }

  bool _cityMatchesQuery(
    BuilderCityCatalogItem city,
    String normalizedQuery,
  ) {
    if (_normalizeTr(city.name).contains(normalizedQuery)) return true;
    return _findCityNode(city.countryCode, city.name)?.matchesQuery(
          normalizedQuery,
          _normalizeTr,
        ) ??
        false;
  }

  bool _cityMatchesCityPill(
    BuilderCityCatalogItem city,
    RouteFeedFilterPill pill,
  ) {
    if (pill.type != RouteFilterPillType.city &&
        pill.type != RouteFilterPillType.district) {
      return false;
    }
    final target = _normalizeTr(pill.cityName ?? '');
    if (target.isEmpty) return false;
    final countryOk =
        pill.countryCode == null || pill.countryCode == city.countryCode;
    if (!countryOk) return false;
    if (_normalizeTr(city.name) == target) return true;
    final cityNode = _findCityNode(city.countryCode, city.name);
    if (cityNode == null) return false;
    if (_normalizeTr(cityNode.name) == target ||
        _normalizeTr(cityNode.defaultName) == target) {
      return true;
    }
    return cityNode.nameTranslations.values
        .any((translated) => _normalizeTr(translated) == target);
  }

  /// Alt tarafta satır satır ([Ülke] -> [Şehir1] [Şehir2] [Şehir3]) listelenecek ülkeler
  List<BuilderCountryCatalogItem> get displayedCountries {
    final catalog = activeContinentsCatalog;
    List<BuilderCountryCatalogItem> rawSource;

    if (_activeContinentId == null) {
      // 1. Kıta seçili değil: Tüm kıtalardaki ülkeler listelenir
      rawSource = [
        for (final c in catalog) ...c.allCountries,
      ];
    } else if (_activeSubRegionId == null) {
      // 2. Kıta seçili ama alt bölge seçili değil: o kıtanın tüm ülkeleri
      final cont = activeContinent;
      rawSource = cont != null
          ? cont.allCountries
          : [for (final c in catalog) ...c.allCountries];
    } else {
      // 3. Hem kıta hem alt bölge seçili: o alt bölgenin ülkeleri
      final cont = activeContinent;
      if (cont != null && cont.subRegions.isNotEmpty) {
        final sub = cont.subRegions.firstWhere(
          (sr) => sr.id == _activeSubRegionId,
          orElse: () => cont.subRegions.first,
        );
        rawSource = sub.countries;
      } else {
        rawSource = [for (final c in catalog) ...c.allCountries];
      }
    }

    final seenCodes = <String>{};
    final source = rawSource
        .where((country) => seenCodes.add(country.code))
        .toList(growable: false);

    final enabledPills = _filterPills.where((p) => p.isEnabled).toList();
    final locationPills = enabledPills
        .where((p) => p.type != RouteFilterPillType.keyword)
        .toList();
    final keywordPills = enabledPills
        .where((p) => p.type == RouteFilterPillType.keyword)
        .toList();

    return source.where((country) {
      if (locationPills.isNotEmpty) {
        final matchesWholeCountry = locationPills.any(
          (pill) => _countryMatchesWholeLocationPill(country, pill),
        );
        final matchesAnyCity = country.cities.any(
          (city) =>
              locationPills.any((pill) => _cityMatchesCityPill(city, pill)),
        );
        if (!matchesWholeCountry && !matchesAnyCity) {
          return false;
        }
      }

      if (keywordPills.isNotEmpty) {
        final displayedCities = getDisplayedCitiesForCountry(country);
        for (final pill in keywordPills) {
          final kw = _normalizeTr(pill.keyword ?? pill.label);
          if (kw.isEmpty) continue;
          final matchesCountryOrRegion =
              _countryOrAncestorsMatchQuery(country, kw);
          final matchesDisplayedCity =
              displayedCities.any((city) => _cityMatchesQuery(city, kw));
          if (!matchesCountryOrRegion && !matchesDisplayedCity) {
            return false;
          }
        }
      }

      if (_searchFilterQuery.isNotEmpty) {
        final countryOrRegionMatch =
            _countryOrAncestorsMatchQuery(country, _searchFilterQuery);
        final cityMatch = country.cities.any(
          (city) => _cityMatchesQuery(city, _searchFilterQuery),
        );
        if (!countryOrRegionMatch && !cityMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Bir ülke satırının sağ tarafında gösterilecek şehirler
  /// (Aktif şehir/kelime hapı varsa eşleşen şehirler, ülke/bölge/kıta eşleştiyse tüm şehirleri gelir)
  List<BuilderCityCatalogItem> getDisplayedCitiesForCountry(
    BuilderCountryCatalogItem country,
  ) {
    final enabledPills = _filterPills.where((p) => p.isEnabled).toList();
    final locationPills = enabledPills
        .where((p) => p.type != RouteFilterPillType.keyword)
        .toList();
    final keywordPills = enabledPills
        .where((p) => p.type == RouteFilterPillType.keyword)
        .toList();

    List<BuilderCityCatalogItem> cities = country.cities;

    if (locationPills.isNotEmpty) {
      final matchesWholeCountry = locationPills.any(
        (pill) => _countryMatchesWholeLocationPill(country, pill),
      );
      if (!matchesWholeCountry) {
        final cityPills = locationPills
            .where(
              (p) =>
                  p.type == RouteFilterPillType.city ||
                  p.type == RouteFilterPillType.district,
            )
            .toList();
        cities = cities
            .where(
              (city) =>
                  cityPills.any((pill) => _cityMatchesCityPill(city, pill)),
            )
            .toList();
      }
    }

    if (keywordPills.isNotEmpty) {
      for (final pill in keywordPills) {
        final kw = _normalizeTr(pill.keyword ?? pill.label);
        if (kw.isEmpty) continue;
        if (!_countryOrAncestorsMatchQuery(country, kw)) {
          cities = cities.where((city) => _cityMatchesQuery(city, kw)).toList();
        }
      }
    }

    if (_searchFilterQuery.isNotEmpty &&
        !_countryOrAncestorsMatchQuery(country, _searchFilterQuery)) {
      cities = cities
          .where((city) => _cityMatchesQuery(city, _searchFilterQuery))
          .toList();
    }

    return cities;
  }

  // --- Seçim İşlemleri (Tekil Seçim / Long Press / Sağ Üst Toggle) ---

  bool isCountrySelected(String countryCode) =>
      _selectedCountryCodes.contains(countryCode);

  bool isCitySelected(BuilderCityCatalogItem city) =>
      _selectedCityKeys.contains(cityKey(city.countryCode, city.name));

  /// İlgili ülkede seçilmiş olan şehirlerin adlarını liste olarak döndürür
  List<String> getSelectedCityNamesForCountry(BuilderCountryCatalogItem country) {
    return country.cities
        .where((c) => isCitySelected(c))
        .map((c) => c.name)
        .toList();
  }

  /// İlgili ülkenin tüm şehirleri seçili mi?
  bool areAllCitiesInCountrySelected(BuilderCountryCatalogItem country) {
    if (country.cities.isEmpty) return false;
    return country.cities.every(
      (c) => _selectedCityKeys.contains(cityKey(country.code, c.name)),
    );
  }

  /// Ülke kartına tıklandığında ülkeyi seçer/bırakır
  void toggleCountrySelection(BuilderCountryCatalogItem country) {
    if (_selectedCountryCodes.contains(country.code)) {
      _selectedCountryCodes.remove(country.code);
      for (final city in country.cities) {
        _selectedCityKeys.remove(cityKey(country.code, city.name));
      }
    } else {
      _selectedCountryCodes.add(country.code);
    }
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  /// Şehir kartına tıklandığında şehri seçer/bırakır (ve bağlı olduğu ülkeyi otomatik işaretler)
  void toggleCitySelection(BuilderCityCatalogItem city) {
    final key = cityKey(city.countryCode, city.name);
    if (_selectedCityKeys.contains(key)) {
      _selectedCityKeys.remove(key);
    } else {
      _selectedCityKeys.add(key);
      _selectedCountryCodes.add(city.countryCode);
    }
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  /// Ülke kartına basılı tutulduğunda (Long Press) veya ülke kartının sağ üst toggle'ına basıldığında
  /// o ülkenin tüm şehirlerini tek seferde seçer veya temizler!
  void toggleSelectAllCitiesOfCountry(BuilderCountryCatalogItem country) {
    final allSelected = areAllCitiesInCountrySelected(country);

    if (allSelected) {
      _selectedCountryCodes.remove(country.code);
      for (final c in country.cities) {
        _selectedCityKeys.remove(cityKey(country.code, c.name));
      }
    } else {
      _selectedCountryCodes.add(country.code);
      for (final c in country.cities) {
        _selectedCityKeys.add(cityKey(country.code, c.name));
      }
    }
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  /// Alt bölge kartına basılı tutulduğunda o alt bölgedeki tüm ülke ve şehirleri seçer/temizler
  void toggleSelectAllInSubRegion(BuilderSubRegionCatalogItem subRegion) {
    final allSelected = subRegion.countries.every(areAllCitiesInCountrySelected);
    for (final country in subRegion.countries) {
      if (allSelected) {
        _selectedCountryCodes.remove(country.code);
        for (final c in country.cities) {
          _selectedCityKeys.remove(cityKey(country.code, c.name));
        }
      } else {
        _selectedCountryCodes.add(country.code);
        for (final c in country.cities) {
          _selectedCityKeys.add(cityKey(country.code, c.name));
        }
      }
    }
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  /// Bir ülkenin seçim özet metnini döndürür:
  /// Örn: "Türkiye -> Tümü" veya "Türkiye -> İzmir, Ankara"
  String getCountrySelectionSummaryText(BuilderCountryCatalogItem country) {
    final selectedInCountry = country.cities
        .where((c) => _selectedCityKeys.contains(cityKey(country.code, c.name)))
        .map((c) => c.name)
        .toList();

    final allCitiesSelected = country.cities.isNotEmpty &&
        country.cities.every(
          (c) => _selectedCityKeys.contains(cityKey(country.code, c.name)),
        );

    final isCountryMarked = _selectedCountryCodes.contains(country.code);

    if (allCitiesSelected || (isCountryMarked && selectedInCountry.isEmpty)) {
      return '${country.name} -> Tümü';
    } else if (selectedInCountry.isNotEmpty) {
      return '${country.name} -> ${selectedInCountry.join(', ')}';
    } else {
      return '';
    }
  }

  bool isCountryOrAnyCitySelected(BuilderCountryCatalogItem country) {
    if (_selectedCountryCodes.contains(country.code)) return true;
    return country.cities.any(
      (c) => _selectedCityKeys.contains(cityKey(country.code, c.name)),
    );
  }

  /// Aktif görüntülenen tüm ülke ve şehirler seçili mi? (Filtre barı sağındaki hızlı toggle için)
  bool get areAllCurrentLocationsSelected {
    final countries = displayedCountries;
    if (countries.isEmpty) return false;
    return countries.every(areAllCitiesInCountrySelected);
  }

  void toggleSelectAllInCurrentView() {
    final countries = displayedCountries;
    if (countries.isEmpty) return;

    final allSelected = areAllCurrentLocationsSelected;
    for (final c in countries) {
      if (allSelected) {
        _selectedCountryCodes.remove(c.code);
        for (final city in c.cities) {
          _selectedCityKeys.remove(cityKey(c.code, city.name));
        }
      } else {
        _selectedCountryCodes.add(c.code);
        for (final city in c.cities) {
          _selectedCityKeys.add(cityKey(c.code, city.name));
        }
      }
    }
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  int get totalSelectedCountryCount => _selectedCountryCodes.length;
  int get totalSelectedCityCount => _selectedCityKeys.length;
  bool get hasAnyDestinationSelected =>
      _selectedCountryCodes.isNotEmpty || _selectedCityKeys.isNotEmpty;

  /// Tüm seçili ülke ve şehirleri tek seferde sıfırlar
  void clearAllDestinationSelections() {
    _selectedCountryCodes.clear();
    _selectedCityKeys.clear();
    _addedCountryCurrencyCodes.clear();
    _hasManualHemisphereOverride = false;
    _syncRecommendedHemisphere();
    notifyListeners();
  }

  String get bottomButtonLabel {
    if (!hasAnyDestinationSelected) {
      return '0 Ülke, 0 Şehir Seçildi';
    }
    return '$totalSelectedCountryCount Ülke, $totalSelectedCityCount Şehir Seçildi';
  }

  // --- Sihirbaz Adım Geçişleri ---

  void goToStep(RouteWizardStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void goToNextStep() {
    final nextIdx = _currentStep.stepIndex + 1;
    if (nextIdx < RouteWizardStep.values.length) {
      _currentStep = RouteWizardStep.values[nextIdx];
      notifyListeners();
    }
  }

  void goToPreviousStep() {
    final prevIdx = _currentStep.stepIndex - 1;
    if (prevIdx >= 0) {
      _currentStep = RouteWizardStep.values[prevIdx];
      notifyListeners();
    }
  }

  // --- Tarih & Bütçe & Ziyaretçi Yardımcıları ---

  static const List<String> turkishMonthNames = <String>[
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static const List<String> turkishShortMonthNames = <String>[
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];

  DateTime get _today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get todayDate => _today;

  static String formatMonthYear(DateTime month) {
    return '${turkishMonthNames[month.month - 1]} ${month.year}';
  }

  static String formatIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _truncate(String value, int maxLen) {
    if (value.length <= maxLen) return value;
    return value.substring(0, maxLen).trimRight();
  }

  void setDateMode(RouteDateMode mode) {
    _dateMode = mode;
    if (mode == RouteDateMode.seasons && !_hasManualHemisphereOverride) {
      _syncRecommendedHemisphere();
    }
    notifyListeners();
  }

  void openDateModeSubView(RouteDateMode mode) {
    _dateMode = mode;
    _instantTripValidationError = null;
    switch (mode) {
      case RouteDateMode.flexible:
        _dateSubView = RouteDateSubView.flexibleMonths;
        break;
      case RouteDateMode.instantTrip:
        _instantTripPendingDate = null;
        _dateSubView = RouteDateSubView.instantCalendar;
        break;
      case RouteDateMode.seasons:
        if (!_hasManualHemisphereOverride) {
          _syncRecommendedHemisphere();
        }
        _dateSubView = RouteDateSubView.seasons;
        break;
      case RouteDateMode.customRange:
        _specificPendingStartDate = null;
        _dateSubView = RouteDateSubView.specificCalendar;
        break;
    }
    notifyListeners();
  }

  void returnToDateHub() {
    _dateSubView = RouteDateSubView.hub;
    _instantTripPendingDate = null;
    _instantTripValidationError = null;
    _specificPendingStartDate = null;
    notifyListeners();
  }

  bool get hasSelectedDateValue {
    switch (_dateMode) {
      case RouteDateMode.flexible:
        return _flexibleStartMonth != null;
      case RouteDateMode.instantTrip:
        return _instantTripRange != null;
      case RouteDateMode.seasons:
        return _selectedSeasons.isNotEmpty;
      case RouteDateMode.customRange:
        return _customDateRange != null;
    }
  }

  void clearDateSelection() {
    _flexibleStartMonth = null;
    _flexibleEndMonth = null;
    _instantTripRange = null;
    _instantTripPendingDate = null;
    _instantTripValidationError = null;
    _selectedSeasons.clear();
    _customDateRange = null;
    _specificPendingStartDate = null;
    _dateMode = RouteDateMode.flexible;
    notifyListeners();
  }

  // --- Mod 1: Esnek Tarihler (12 aylık görünüm) ---

  List<DateTime> get flexibleMonthOptions {
    final t = _today;
    return List<DateTime>.generate(
      12,
      (index) => DateTime(t.year, t.month + index),
      growable: false,
    );
  }

  void selectFlexibleMonth(DateTime month) {
    final normalized = DateTime(month.year, month.month);
    _dateMode = RouteDateMode.flexible;
    if (_flexibleStartMonth == null || _flexibleEndMonth != null) {
      _flexibleStartMonth = normalized;
      _flexibleEndMonth = null;
    } else if (normalized == _flexibleStartMonth) {
      _flexibleStartMonth = normalized;
      _flexibleEndMonth = null;
    } else if (normalized.isBefore(_flexibleStartMonth!)) {
      _flexibleEndMonth = _flexibleStartMonth;
      _flexibleStartMonth = normalized;
    } else {
      _flexibleEndMonth = normalized;
    }
    notifyListeners();
  }

  void clearFlexibleMonths() {
    _flexibleStartMonth = null;
    _flexibleEndMonth = null;
    notifyListeners();
  }

  /// Hızlı esnek dönem kısayolu ("Tek Ay", "2 Aylık Dönem", "3 Aylık Dönem")
  void applyFlexibleDurationShortcut(int monthCount) {
    final options = flexibleMonthOptions;
    if (options.isEmpty) return;
    final clampedCount = monthCount.clamp(1, options.length);
    _dateMode = RouteDateMode.flexible;

    if (clampedCount == 1) {
      _flexibleStartMonth ??= options.first;
      _flexibleEndMonth = null;
      notifyListeners();
      return;
    }

    int startIdx = 0;
    if (_flexibleStartMonth != null) {
      final foundIdx = options.indexOf(_flexibleStartMonth!);
      if (foundIdx >= 0) {
        startIdx = foundIdx;
      }
    }
    if (startIdx + clampedCount - 1 >= options.length) {
      startIdx = options.length - clampedCount;
    }

    _flexibleStartMonth = options[startIdx];
    _flexibleEndMonth = options[startIdx + clampedCount - 1];
    notifyListeners();
  }

  String get formattedFlexiblePeriod {
    final start = _flexibleStartMonth;
    if (start == null) return '';
    final end = _flexibleEndMonth;
    if (end == null || end == start) {
      return formatMonthYear(start);
    }
    return '${formatMonthYear(start)} - ${formatMonthYear(end)}';
  }

  // --- Mod 2: Anlık Gezi (Bugünü kapsama zorunluluğu) ---

  List<DateTime> get instantCalendarMonths {
    final t = _today;
    final minDate = t.subtract(const Duration(days: 14));
    final firstMonth = DateTime(minDate.year, minDate.month);
    final lastMonth = DateTime(t.year, t.month + 6);
    final totalMonths = (lastMonth.year - firstMonth.year) * 12 +
        (lastMonth.month - firstMonth.month) +
        1;
    return List<DateTime>.generate(
      totalMonths,
      (i) => DateTime(firstMonth.year, firstMonth.month + i),
      growable: false,
    );
  }

  bool isDateRangeIncludingToday(DateTimeRange range) {
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    return !s.isAfter(_today) && !e.isBefore(_today);
  }

  bool validateAndSetInstantTripRange(DateTimeRange range) {
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    final ordered = s.isAfter(e)
        ? DateTimeRange(start: e, end: s)
        : DateTimeRange(start: s, end: e);

    _dateMode = RouteDateMode.instantTrip;
    _instantTripPendingDate = null;

    if (!isDateRangeIncludingToday(ordered)) {
      _instantTripValidationError =
          'Anlık gezi için seçilen tarih aralığı bugünü kapsamalıdır.';
      notifyListeners();
      return false;
    }

    _instantTripRange = ordered;
    _instantTripValidationError = null;
    notifyListeners();
    return true;
  }

  void selectInstantTripDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final t = _today;
    _dateMode = RouteDateMode.instantTrip;

    if (_instantTripPendingDate == null) {
      _instantTripPendingDate = d;
      _instantTripValidationError = null;
      if (d == t) {
        _instantTripRange = DateTimeRange(start: d, end: d);
      } else {
        _instantTripRange = null;
      }
      notifyListeners();
      return;
    }

    final first = _instantTripPendingDate!;
    final ordered = d.isBefore(first)
        ? DateTimeRange(start: d, end: first)
        : DateTimeRange(start: first, end: d);
    validateAndSetInstantTripRange(ordered);
  }

  void clearInstantTripRange() {
    _instantTripRange = null;
    _instantTripPendingDate = null;
    _instantTripValidationError = null;
    notifyListeners();
  }

  /// `CalendarDatePicker2` (`CalendarDatePicker2Type.range`) callback adaptörü: Anlık Gezi
  ///
  /// Tek gün `[d]` geldiğinde `d == today` ise doğrudan `[today, today]` olarak onaylar;
  /// `d != today` ise `instantTripPendingDate = d` olarak bekletir.
  /// İki gün `[d1, d2]` geldiğinde bugünü kapsayıp kapsamadığını doğrular;
  /// kapsamıyorsa `instantTripValidationError` ayarlanır ve aralık reddedilir.
  void applyInstantTripCalendarDates(List<DateTime?> dates) {
    final normalized = dates
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList(growable: false)
      ..sort();

    if (normalized.isEmpty) {
      clearInstantTripRange();
      return;
    }

    _dateMode = RouteDateMode.instantTrip;
    if (normalized.length == 1) {
      final d = normalized.first;
      _instantTripPendingDate = d;
      _instantTripValidationError = null;
      if (d == _today) {
        _instantTripRange = DateTimeRange(start: d, end: d);
      } else {
        _instantTripRange = null;
      }
      notifyListeners();
      return;
    }

    final range = DateTimeRange(start: normalized.first, end: normalized.last);
    validateAndSetInstantTripRange(range);
  }

  DateTimeRange instantTodayRange() => DateTimeRange(start: _today, end: _today);

  DateTimeRange instantLastDaysRange(int days) {
    final count = days < 1 ? 1 : days;
    return DateTimeRange(
      start: _today.subtract(Duration(days: count - 1)),
      end: _today,
    );
  }

  DateTimeRange instantThisWeekRange() {
    final t = _today;
    final monday = t.subtract(Duration(days: t.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6));
    return DateTimeRange(start: monday, end: sunday);
  }

  void applyInstantTodayShortcut() {
    validateAndSetInstantTripRange(instantTodayRange());
  }

  void applyInstantLastDaysShortcut(int days) {
    validateAndSetInstantTripRange(instantLastDaysRange(days));
  }

  void applyInstantThisWeekShortcut() {
    validateAndSetInstantTripRange(instantThisWeekRange());
  }

  // --- Mod 3: Mevsimler (Yarım Küre Algılama + Çoklu Seçim) ---

  /// Seçili ülke kodları ile seçili şehirlerden türetilen benzersiz ülke kodları
  Set<String> get selectedDestinationCountryCodes {
    final codes = <String>{..._selectedCountryCodes};
    for (final key in _selectedCityKeys) {
      final idx = key.indexOf(':');
      if (idx > 0) {
        codes.add(key.substring(0, idx).toUpperCase());
      }
    }
    return codes;
  }

  GeographyHemisphere _resolveCountryHemisphere(String countryCode) {
    final upper = countryCode.trim().toUpperCase();
    for (final continent in activeContinentsCatalog) {
      for (final subRegion in continent.subRegions) {
        for (final country in subRegion.countries) {
          if (country.code.toUpperCase() == upper) {
            return country.hemisphere;
          }
        }
      }
    }
    return GeographyHemisphere.fromApi(
      null,
      countryCode: upper,
      continentCode: '',
    );
  }

  /// Seçili destinasyonlardaki ülkelerin yarım küre çoğunluğuna göre önerilen yarım küre
  GeographyHemisphere get recommendedHemisphere {
    int northernCount = 0;
    int southernCount = 0;
    for (final code in selectedDestinationCountryCodes) {
      if (_resolveCountryHemisphere(code) == GeographyHemisphere.southern) {
        southernCount++;
      } else {
        northernCount++;
      }
    }
    if (southernCount > northernCount) {
      return GeographyHemisphere.southern;
    }
    return GeographyHemisphere.northern;
  }

  void _syncRecommendedHemisphere() {
    if (!_hasManualHemisphereOverride) {
      _selectedHemisphere = recommendedHemisphere;
    }
  }

  void setHemisphere(GeographyHemisphere hemisphere) {
    _selectedHemisphere = hemisphere;
    _hasManualHemisphereOverride = true;
    notifyListeners();
  }

  void toggleSeason(RouteSeason season) {
    _dateMode = RouteDateMode.seasons;
    if (_selectedSeasons.contains(season)) {
      _selectedSeasons.remove(season);
    } else {
      _selectedSeasons.add(season);
    }
    notifyListeners();
  }

  ({int startMonth, int endMonth, int startYear, int endYear})
      seasonMonthRange(RouteSeason season, [GeographyHemisphere? hemisphere]) {
    final hemi = hemisphere ?? _selectedHemisphere;
    final int startMonth;
    final int endMonth;
    switch ((hemi, season)) {
      case (GeographyHemisphere.northern, RouteSeason.spring):
        startMonth = 3;
        endMonth = 5;
      case (GeographyHemisphere.northern, RouteSeason.summer):
        startMonth = 6;
        endMonth = 8;
      case (GeographyHemisphere.northern, RouteSeason.autumn):
        startMonth = 9;
        endMonth = 11;
      case (GeographyHemisphere.northern, RouteSeason.winter):
        startMonth = 12;
        endMonth = 2;
      case (GeographyHemisphere.southern, RouteSeason.spring):
        startMonth = 9;
        endMonth = 11;
      case (GeographyHemisphere.southern, RouteSeason.summer):
        startMonth = 12;
        endMonth = 2;
      case (GeographyHemisphere.southern, RouteSeason.autumn):
        startMonth = 3;
        endMonth = 5;
      case (GeographyHemisphere.southern, RouteSeason.winter):
        startMonth = 6;
        endMonth = 8;
    }

    final t = _today;
    if (startMonth > endMonth) {
      // Yıl geçişli mevsim (Aralık - Şubat)
      if (t.month <= endMonth) {
        return (
          startMonth: startMonth,
          endMonth: endMonth,
          startYear: t.year - 1,
          endYear: t.year,
        );
      }
      return (
        startMonth: startMonth,
        endMonth: endMonth,
        startYear: t.year,
        endYear: t.year + 1,
      );
    }

    final year = endMonth < t.month ? t.year + 1 : t.year;
    return (
      startMonth: startMonth,
      endMonth: endMonth,
      startYear: year,
      endYear: year,
    );
  }

  String formatSeasonMonthRange(
    RouteSeason season, [
    GeographyHemisphere? hemisphere,
  ]) {
    final range = seasonMonthRange(season, hemisphere);
    final startName = turkishMonthNames[range.startMonth - 1];
    final endName = turkishMonthNames[range.endMonth - 1];
    if (range.startYear == range.endYear) {
      return '$startName - $endName ${range.endYear}';
    }
    return '$startName ${range.startYear} - $endName ${range.endYear}';
  }

  String get formattedSelectedSeasonsTitle {
    if (_selectedSeasons.isEmpty) return '';
    final ordered = RouteSeason.values
        .where(_selectedSeasons.contains)
        .map((s) => s.labelTr)
        .toList(growable: false);
    if (ordered.length == 1) return ordered.first;
    if (ordered.length == 2) return '${ordered[0]} ve ${ordered[1]}';
    return '${ordered.sublist(0, ordered.length - 1).join(', ')} ve ${ordered.last}';
  }

  String get formattedSelectedSeasonRanges {
    if (_selectedSeasons.isEmpty) return '';
    final ordered = RouteSeason.values.where(_selectedSeasons.contains).toList()
      ..sort((a, b) {
        final ra = seasonMonthRange(a);
        final rb = seasonMonthRange(b);
        final cmpYear = ra.startYear.compareTo(rb.startYear);
        if (cmpYear != 0) return cmpYear;
        return ra.startMonth.compareTo(rb.startMonth);
      });
    return ordered.map(formatSeasonMonthRange).join(' / ');
  }

  // --- Mod 4: Belirli Tarihler (Yalnızca bugün ve ileri tarihler) ---

  List<DateTime> get specificCalendarMonths {
    final t = _today;
    return List<DateTime>.generate(
      12,
      (i) => DateTime(t.year, t.month + i),
      growable: false,
    );
  }

  bool isSpecificDateSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(_today);
  }

  void selectSpecificDateDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isBefore(_today)) {
      return;
    }
    _dateMode = RouteDateMode.customRange;
    if (_specificPendingStartDate == null) {
      _specificPendingStartDate = d;
      _customDateRange = DateTimeRange(start: d, end: d);
    } else {
      final first = _specificPendingStartDate!;
      _customDateRange = d.isBefore(first)
          ? DateTimeRange(start: d, end: first)
          : DateTimeRange(start: first, end: d);
      _specificPendingStartDate = null;
    }
    notifyListeners();
  }

  void clearSpecificDateRange() {
    _customDateRange = null;
    _specificPendingStartDate = null;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange range) {
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    if (s.isBefore(_today) || e.isBefore(_today)) {
      return;
    }
    _customDateRange = s.isAfter(e)
        ? DateTimeRange(start: e, end: s)
        : DateTimeRange(start: s, end: e);
    _specificPendingStartDate = null;
    _dateMode = RouteDateMode.customRange;
    notifyListeners();
  }

  /// `CalendarDatePicker2` (`CalendarDatePicker2Type.range`) callback adaptörü: Belirli Tarihler
  void applySpecificCalendarDates(List<DateTime?> dates) {
    final normalized = dates
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .where((d) => !d.isBefore(_today))
        .toList(growable: false)
      ..sort();

    if (normalized.isEmpty) {
      clearSpecificDateRange();
      return;
    }

    _dateMode = RouteDateMode.customRange;
    if (normalized.length == 1) {
      final d = normalized.first;
      _specificPendingStartDate = d;
      _customDateRange = DateTimeRange(start: d, end: d);
      notifyListeners();
      return;
    }

    _customDateRange = DateTimeRange(
      start: normalized.first,
      end: normalized.last,
    );
    _specificPendingStartDate = null;
    notifyListeners();
  }

  DateTimeRange specificWeekendRange() {
    final t = _today;
    if (t.weekday == DateTime.sunday) {
      return DateTimeRange(start: t, end: t);
    }
    final saturday = t.add(Duration(days: DateTime.saturday - t.weekday));
    final sunday = saturday.add(const Duration(days: 1));
    return DateTimeRange(start: saturday, end: sunday);
  }

  DateTimeRange specificDurationRange(int days) {
    final count = days < 1 ? 1 : days;
    return DateTimeRange(
      start: _today,
      end: _today.add(Duration(days: count - 1)),
    );
  }

  void applySpecificWeekendShortcut() {
    setCustomDateRange(specificWeekendRange());
  }

  void applySpecificDurationShortcut(int days) {
    setCustomDateRange(specificDurationRange(days));
  }

  static String formatDayMonthYearShort(DateTime date) {
    return '${date.day} ${turkishShortMonthNames[date.month - 1]} ${date.year}';
  }

  static String formatShortDateRange(DateTimeRange range) {
    final s = DateTime(range.start.year, range.start.month, range.start.day);
    final e = DateTime(range.end.year, range.end.month, range.end.day);
    final days = e.difference(s).inDays + 1;
    if (s == e) {
      return '${s.day} ${turkishMonthNames[s.month - 1]} ${s.year}';
    }
    if (s.year == e.year && s.month == e.month) {
      return '${s.day} - ${e.day} ${turkishMonthNames[e.month - 1]} ($days Gün)';
    }
    if (s.year == e.year) {
      return '${s.day} ${turkishShortMonthNames[s.month - 1]} - '
          '${e.day} ${turkishShortMonthNames[e.month - 1]} ($days Gün)';
    }
    return '${s.day} ${turkishShortMonthNames[s.month - 1]} ${s.year} - '
        '${e.day} ${turkishShortMonthNames[e.month - 1]} ${e.year} ($days Gün)';
  }

  String get formattedDateSummary {
    switch (_dateMode) {
      case RouteDateMode.flexible:
        if (_flexibleStartMonth == null) return 'Tarih Esnek';
        return formattedFlexiblePeriod;
      case RouteDateMode.instantTrip:
        if (_instantTripRange == null) return 'Anlık Gezi';
        return formatShortDateRange(_instantTripRange!);
      case RouteDateMode.seasons:
        if (_selectedSeasons.isEmpty) return 'Mevsimler';
        return formattedSelectedSeasonsTitle;
      case RouteDateMode.customRange:
        if (_customDateRange == null) return 'Belirli Tarihler';
        return formatShortDateRange(_customDateRange!);
    }
  }

  /// Backend API ile uyumlu tarih payload'ı üretir
  RouteDateSelectionPayload get datePayload => buildDatePayload();

  RouteDateSelectionPayload buildDatePayload() {
    final label = _truncate(formattedDateSummary, 140);
    switch (_dateMode) {
      case RouteDateMode.flexible:
        final period = formattedFlexiblePeriod;
        return RouteDateSelectionPayload(
          dateMode: _dateMode.apiValue,
          flexiblePeriod: period.isEmpty ? null : _truncate(period, 120),
          dateRangeLabel: label,
        );
      case RouteDateMode.seasons:
        final title = formattedSelectedSeasonsTitle;
        final ranges = formattedSelectedSeasonRanges;
        final rawPeriod = title.isEmpty
            ? ''
            : '${_selectedHemisphere.labelTr}: $title ($ranges)';
        return RouteDateSelectionPayload(
          dateMode: _dateMode.apiValue,
          flexiblePeriod: rawPeriod.isEmpty ? null : _truncate(rawPeriod, 120),
          dateRangeLabel: label,
        );
      case RouteDateMode.instantTrip:
        final r = _instantTripRange;
        return RouteDateSelectionPayload(
          dateMode: _dateMode.apiValue,
          startDate: r == null ? null : formatIsoDate(r.start),
          endDate: r == null ? null : formatIsoDate(r.end),
          dateRangeLabel: label,
        );
      case RouteDateMode.customRange:
        final r = _customDateRange;
        return RouteDateSelectionPayload(
          dateMode: _dateMode.apiValue,
          startDate: r == null ? null : formatIsoDate(r.start),
          endDate: r == null ? null : formatIsoDate(r.end),
          dateRangeLabel: label,
        );
    }
  }

  static const Map<String, String> _popularCurrencyFlags = <String, String>{
    'TRY': '🇹🇷',
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'GBP': '🇬🇧',
    'THB': '🇹🇭',
    'JPY': '🇯🇵',
    'CHF': '🇨🇭',
    'AED': '🇦🇪',
    'SAR': '🇸🇦',
    'CAD': '🇨🇦',
    'AUD': '🇦🇺',
    'KRW': '🇰🇷',
    'IDR': '🇮🇩',
    'GEL': '🇬🇪',
    'AZN': '🇦🇿',
    'RSD': '🇷🇸',
    'BAM': '🇧🇦',
    'BGN': '🇧🇬',
    'PLN': '🇵🇱',
    'CZK': '🇨🇿',
    'HUF': '🇭🇺',
    'NOK': '🇳🇴',
    'SEK': '🇸🇪',
    'DKK': '🇩🇰',
    'CNY': '🇨🇳',
    'INR': '🇮🇳',
    'SGD': '🇸🇬',
    'MYR': '🇲🇾',
    'EGP': '🇪🇬',
    'MAD': '🇲🇦',
    'BRL': '🇧🇷',
    'MXN': '🇲🇽',
  };

  static const List<String> _popularCurrencyOrder = <String>[
    'EUR',
    'GBP',
    'THB',
    'JPY',
    'CHF',
    'AED',
    'SAR',
    'CAD',
    'AUD',
    'KRW',
    'IDR',
    'GEL',
    'AZN',
    'RSD',
    'BAM',
    'BGN',
    'PLN',
    'CZK',
    'HUF',
    'NOK',
    'SEK',
    'DKK',
    'CNY',
    'INR',
    'SGD',
    'EGP',
    'MAD',
    'BRL',
    'MXN',
  ];

  void setBudgetEnabled(bool enabled) {
    if (_isBudgetEnabled == enabled) return;
    _isBudgetEnabled = enabled;
    notifyListeners();
  }

  void toggleBudgetEnabled() {
    setBudgetEnabled(!_isBudgetEnabled);
  }

  void setUserCurrencyCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || normalized == _userCurrencyCode) return;
    if (exchangeRateFor(normalized) == null) return;
    final previousCode = _userCurrencyCode;
    _minBudget = _minBudget <= 0
        ? 0.0
        : convertCurrencyAmount(
            _minBudget,
            fromCode: previousCode,
            toCode: normalized,
          );
    _maxBudget = _maxBudget == null
        ? null
        : convertCurrencyAmount(
            _maxBudget!,
            fromCode: previousCode,
            toCode: normalized,
          );
    _userCurrencyCode = normalized;
    _addedCountryCurrencyCodes.remove(normalized);
    notifyListeners();
  }

  void setBudgetCurrency(RouteBudgetCurrency newCurrency) {
    setUserCurrencyCode(newCurrency.code);
  }

  GeographyExchangeRate? exchangeRateFor(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    final storeRate = _geographyStore?.rateFor(normalized);
    if (storeRate != null && storeRate.ratePerUsd > 0) {
      return storeRate;
    }
    return resolveBaselineExchangeRate(normalized);
  }

  double convertCurrencyAmount(
    double amount, {
    required String fromCode,
    required String toCode,
  }) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    if (from.isEmpty || to.isEmpty || from == to) {
      return amount;
    }
    if (_geographyStore != null) {
      return _geographyStore.convertAmount(
        amount,
        fromCode: from,
        toCode: to,
      );
    }
    final fromRate = resolveBaselineExchangeRate(from)?.ratePerUsd;
    final toRate = resolveBaselineExchangeRate(to)?.ratePerUsd;
    if (fromRate == null || fromRate <= 0 || toRate == null || toRate <= 0) {
      return amount;
    }
    return (amount / fromRate) * toRate;
  }

  String currencySymbolFor(String code) {
    final normalized = code.trim().toUpperCase();
    final rate = exchangeRateFor(normalized);
    if (rate != null && rate.symbol.trim().isNotEmpty) {
      return rate.symbol;
    }
    for (final continent in activeContinentsCatalog) {
      for (final country in continent.allCountries) {
        if (country.currencyCode == normalized &&
            country.currencySymbol.isNotEmpty) {
          return country.currencySymbol;
        }
      }
    }
    return normalized;
  }

  String currencyNameTrFor(String code) {
    final normalized = code.trim().toUpperCase();
    final rate = exchangeRateFor(normalized);
    if (rate != null && rate.nameTr.trim().isNotEmpty) {
      return rate.nameTr;
    }
    for (final continent in activeContinentsCatalog) {
      for (final country in continent.allCountries) {
        if (country.currencyCode == normalized &&
            country.currencyNameTr.isNotEmpty) {
          return country.currencyNameTr;
        }
      }
    }
    return normalized;
  }

  String currencyFlagFor(String code) {
    final normalized = code.trim().toUpperCase();
    return _popularCurrencyFlags[normalized] ?? '💱';
  }

  BuilderCountryCatalogItem? _findBuilderCountryByCode(String countryCode) {
    final upper = countryCode.trim().toUpperCase();
    if (upper.isEmpty) return null;
    for (final continent in activeContinentsCatalog) {
      for (final country in continent.allCountries) {
        if (country.code.toUpperCase() == upper) {
          return country;
        }
      }
    }
    final storeNode = _geographyStore?.findCountry(upper);
    if (storeNode != null) {
      return _mapCountryNodeToBuilder(storeNode, _geographyStore?.lang ?? 'tr');
    }
    return null;
  }

  /// Seçili ülkelerin (`selectedCountryCodes` + seçili şehirlerin ülkeleri)
  /// `userCurrencyCode` ve `secondaryCurrencyCode` dışındaki tekilleştirilmiş para birimleri.
  List<BuilderCountryCurrencyOption> get availableSelectedCountryCurrencies {
    final excludedCodes = <String>{_userCurrencyCode, secondaryCurrencyCode};
    final grouped = <String, _MutableCurrencyGroup>{};

    for (final countryCode in selectedDestinationCountryCodes) {
      final upperCountry = countryCode.trim().toUpperCase();
      if (upperCountry.isEmpty) continue;

      final builderCountry = _findBuilderCountryByCode(upperCountry);
      final fallback = resolveCountryCurrencyFallback(upperCountry);

      final currencyCode =
          (builderCountry?.currencyCode ?? fallback.code).trim().toUpperCase();
      if (currencyCode.isEmpty || excludedCodes.contains(currencyCode)) {
        continue;
      }

      final symbol = (builderCountry?.currencySymbol ?? '').isNotEmpty
          ? builderCountry!.currencySymbol
          : currencySymbolFor(currencyCode);
      final nameTr = (builderCountry?.currencyNameTr ?? '').isNotEmpty
          ? builderCountry!.currencyNameTr
          : currencyNameTrFor(currencyCode);
      final countryName = (builderCountry?.name ?? '').isNotEmpty
          ? builderCountry!.name
          : upperCountry;
      final flagEmoji = builderCountry?.flagEmoji ?? '';

      final group = grouped.putIfAbsent(
        currencyCode,
        () => _MutableCurrencyGroup(
          code: currencyCode,
          symbol: symbol,
          nameTr: nameTr,
        ),
      );
      if (countryName.isNotEmpty && !group.countryNames.contains(countryName)) {
        group.countryNames.add(countryName);
      }
      if (flagEmoji.isNotEmpty && !group.flagEmojis.contains(flagEmoji)) {
        group.flagEmojis.add(flagEmoji);
      }
    }

    return List<BuilderCountryCurrencyOption>.unmodifiable(
      grouped.values.map((g) => g.toOption()),
    );
  }

  /// Seçili ülke para birimleri dışında eklenebilecek popüler dünya para birimleri
  List<BuilderCountryCurrencyOption> get popularExtraCurrencies {
    final excluded = <String>{
      _userCurrencyCode,
      secondaryCurrencyCode,
      for (final opt in availableSelectedCountryCurrencies) opt.code,
    };

    final options = <BuilderCountryCurrencyOption>[];
    for (final code in _popularCurrencyOrder) {
      if (excluded.contains(code)) continue;
      final rate = exchangeRateFor(code);
      if (rate == null) continue;
      final flag = _popularCurrencyFlags[code];
      options.add(
        BuilderCountryCurrencyOption(
          code: code,
          symbol: rate.symbol.isNotEmpty ? rate.symbol : code,
          nameTr: rate.nameTr.isNotEmpty ? rate.nameTr : code,
          countryNames: const <String>[],
          flagEmojis: flag != null ? <String>[flag] : const <String>[],
        ),
      );
    }
    return List<BuilderCountryCurrencyOption>.unmodifiable(options);
  }

  /// Kullanıcının açıkça eklediği ülke para birimleri (varsayılan olarak boştur)
  List<BuilderCountryCurrencyOption> get addedCountryCurrencies {
    final selectedMap = <String, BuilderCountryCurrencyOption>{
      for (final opt in availableSelectedCountryCurrencies) opt.code: opt,
    };

    final result = <BuilderCountryCurrencyOption>[];
    for (final code in _addedCountryCurrencyCodes) {
      final fromSelected = selectedMap[code];
      if (fromSelected != null) {
        result.add(fromSelected);
        continue;
      }
      final rate = exchangeRateFor(code);
      final flag = _popularCurrencyFlags[code];
      result.add(
        BuilderCountryCurrencyOption(
          code: code,
          symbol: rate?.symbol ?? currencySymbolFor(code),
          nameTr: rate?.nameTr ?? currencyNameTrFor(code),
          countryNames: const <String>[],
          flagEmojis: flag != null ? <String>[flag] : const <String>[],
        ),
      );
    }
    return List<BuilderCountryCurrencyOption>.unmodifiable(result);
  }

  bool isCountryCurrencyAdded(String code) {
    final normalized = code.trim().toUpperCase();
    return _addedCountryCurrencyCodes.contains(normalized);
  }

  void addCountryCurrency(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty ||
        normalized == _userCurrencyCode ||
        normalized == secondaryCurrencyCode) {
      return;
    }
    if (exchangeRateFor(normalized) == null) return;
    if (_addedCountryCurrencyCodes.contains(normalized)) return;
    _addedCountryCurrencyCodes.add(normalized);
    notifyListeners();
  }

  void removeCountryCurrency(String code) {
    final normalized = code.trim().toUpperCase();
    if (_addedCountryCurrencyCodes.remove(normalized)) {
      notifyListeners();
    }
  }

  void toggleCountryCurrency(String code) {
    if (isCountryCurrencyAdded(code)) {
      removeCountryCurrency(code);
    } else {
      addCountryCurrency(code);
    }
  }

  void clearAddedCountryCurrencies() {
    if (_addedCountryCurrencyCodes.isEmpty) return;
    _addedCountryCurrencyCodes.clear();
    notifyListeners();
  }

  void updateBudgetRangeForCurrency({
    required String currencyCode,
    double? minAmount,
    double? maxAmount,
    bool clearMaxAmount = false,
  }) {
    if (minAmount == null && maxAmount == null && !clearMaxAmount) return;
    final normalized = currencyCode.trim().toUpperCase();
    final effectiveCode = normalized.isEmpty ? _userCurrencyCode : normalized;

    double toUserCurrency(double value) {
      final nonNegative = value.isNaN || value.isInfinite || value < 0
          ? 0.0
          : value;
      if (effectiveCode == _userCurrencyCode) {
        return nonNegative;
      }
      return convertCurrencyAmount(
        nonNegative,
        fromCode: effectiveCode,
        toCode: _userCurrencyCode,
      );
    }

    if (!_isBudgetEnabled) {
      _isBudgetEnabled = true;
    }

    if (clearMaxAmount) {
      if (minAmount != null) {
        _minBudget = toUserCurrency(minAmount);
      }
      _maxBudget = null;
    } else if (minAmount != null && maxAmount != null) {
      final convertedMin = toUserCurrency(minAmount);
      final convertedMax = toUserCurrency(maxAmount);
      _minBudget = math.min(convertedMin, convertedMax);
      _maxBudget = math.max(convertedMin, convertedMax);
    } else if (minAmount != null) {
      final convertedMin = toUserCurrency(minAmount);
      _minBudget = convertedMin;
      if (_maxBudget != null && _minBudget > _maxBudget!) {
        _maxBudget = _minBudget;
      }
    } else if (maxAmount != null) {
      final convertedMax = toUserCurrency(maxAmount);
      _maxBudget = convertedMax;
      if (_maxBudget! < _minBudget) {
        _minBudget = _maxBudget!;
      }
    }

    notifyListeners();
  }

  void updateRouteBudgetRange(double minVal, double? maxVal) {
    updateBudgetRangeForCurrency(
      currencyCode: _userCurrencyCode,
      minAmount: minVal,
      maxAmount: maxVal,
      clearMaxAmount: maxVal == null,
    );
  }

  ({double min, double? max}) budgetAmountForCurrency(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || normalized == _userCurrencyCode) {
      return (min: _minBudget, max: _maxBudget);
    }
    return (
      min: convertCurrencyAmount(
        _minBudget,
        fromCode: _userCurrencyCode,
        toCode: normalized,
      ),
      max: _maxBudget == null
          ? null
          : convertCurrencyAmount(
              _maxBudget!,
              fromCode: _userCurrencyCode,
              toCode: normalized,
            ),
    );
  }

  static String formatGroupedInteger(double value) {
    final safeValue = value.isNaN || value.isInfinite || value < 0 ? 0.0 : value;
    final rounded = safeValue.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  static double? parseBudgetAmountInput(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return null;

    final digitsAndSeps = cleaned.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (digitsAndSeps.isEmpty) return null;

    String normalized;
    final hasDot = digitsAndSeps.contains('.');
    final hasComma = digitsAndSeps.contains(',');
    if (hasDot && hasComma) {
      if (digitsAndSeps.lastIndexOf(',') > digitsAndSeps.lastIndexOf('.')) {
        normalized = digitsAndSeps.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = digitsAndSeps.replaceAll(',', '');
      }
    } else if (hasDot) {
      if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(digitsAndSeps)) {
        normalized = digitsAndSeps.replaceAll('.', '');
      } else {
        normalized = digitsAndSeps;
      }
    } else if (hasComma) {
      if (RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(digitsAndSeps)) {
        normalized = digitsAndSeps.replaceAll(',', '');
      } else {
        normalized = digitsAndSeps.replaceAll(',', '.');
      }
    } else {
      normalized = digitsAndSeps;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed < 0) {
      return null;
    }
    return parsed;
  }

  String formatAmountForCurrency(double value, String code) {
    final normalized = code.trim().toUpperCase();
    final grouped = formatGroupedInteger(value);
    final symbol = currencySymbolFor(normalized);
    final needsSpace =
        symbol.length >= 3 && RegExp(r'^[A-Za-z.]+$').hasMatch(symbol);
    return needsSpace ? '$symbol $grouped' : '$symbol$grouped';
  }

  String formatCurrencyAmount(double value) =>
      formatAmountForCurrency(value, _userCurrencyCode);

  static String _formatExchangeRateValue(double value) {
    if (value >= 100) {
      return formatGroupedInteger(value);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String exchangeRateSummary(String fromCode, String toCode) {
    final from = fromCode.trim().toUpperCase();
    final to = toCode.trim().toUpperCase();
    final fromSymbol = currencySymbolFor(from);
    final toSymbol = currencySymbolFor(to);
    if (from.isEmpty || to.isEmpty || from == to) {
      return '1 $fromSymbol = 1 $toSymbol';
    }
    final unitRate = convertCurrencyAmount(1, fromCode: from, toCode: to);
    if (unitRate < 0.1) {
      final perThousand = convertCurrencyAmount(
        1000,
        fromCode: from,
        toCode: to,
      );
      return '1.000 $fromSymbol ≈ ${_formatExchangeRateValue(perThousand)} $toSymbol';
    }
    return '1 $fromSymbol ≈ ${_formatExchangeRateValue(unitRate)} $toSymbol';
  }

  String get formattedBudgetSummary {
    if (!_isBudgetEnabled) return 'Bütçe Sınırı Yok';
    final maxVal = _maxBudget;
    if (maxVal == null) {
      if (_minBudget <= 0) {
        return '${formatAmountForCurrency(0, _userCurrencyCode)} – Sınırsız';
      }
      final primaryPlus =
          '${formatAmountForCurrency(_minBudget, _userCurrencyCode)}+';
      if (_userCurrencyCode == secondaryCurrencyCode) {
        return primaryPlus;
      }
      final secondaryRange = budgetAmountForCurrency(secondaryCurrencyCode);
      final secondaryPlus =
          '${formatAmountForCurrency(secondaryRange.min, secondaryCurrencyCode)}+';
      return '$primaryPlus ($secondaryPlus)';
    }

    final primaryText =
        '${formatAmountForCurrency(_minBudget, _userCurrencyCode)} – ${formatAmountForCurrency(maxVal, _userCurrencyCode)}';
    if (_userCurrencyCode == secondaryCurrencyCode) {
      return primaryText;
    }
    final secondaryRange = budgetAmountForCurrency(secondaryCurrencyCode);
    final secondaryText =
        '${formatAmountForCurrency(secondaryRange.min, secondaryCurrencyCode)} – ${formatAmountForCurrency(secondaryRange.max!, secondaryCurrencyCode)}';
    return '$primaryText ($secondaryText)';
  }

  void updateAdultsCount(int delta) {
    final next = (_adultsCount + delta).clamp(1, 16);
    if (next == _adultsCount) return;
    _adultsCount = next;
    notifyListeners();
  }

  void updateChildrenCount(int delta) {
    final next = (_childrenCount + delta).clamp(0, 12);
    if (next == _childrenCount) return;
    _childrenCount = next;
    notifyListeners();
  }
}

class _MutableCurrencyGroup {
  _MutableCurrencyGroup({
    required this.code,
    required this.symbol,
    required this.nameTr,
  });

  final String code;
  final String symbol;
  final String nameTr;
  final List<String> countryNames = <String>[];
  final List<String> flagEmojis = <String>[];

  BuilderCountryCurrencyOption toOption() {
    return BuilderCountryCurrencyOption(
      code: code,
      symbol: symbol,
      nameTr: nameTr,
      countryNames: List<String>.unmodifiable(countryNames),
      flagEmojis: List<String>.unmodifiable(flagEmojis),
    );
  }
}
