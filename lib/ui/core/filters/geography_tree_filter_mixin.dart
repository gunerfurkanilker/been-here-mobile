import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/models/route_feed_models.dart';

/// Anasayfa (Rota Akışı) ve Arama (Mekan Keşfi) ekranlarının ortak kullandığı:
/// 1) Hiyerarşik Coğrafya Ağacı (Kıta > Ülke > Şehir) ve Akıllı Ağaç Arama
/// 2) Anlık Konum (Yakınımdaki Konumlar - Konum Öncelikli)
/// 3) 3 Karakter + 5 Saniye Debounce'lu Metin Arama Mixin'i.
mixin GeographyTreeFilterMixin on ChangeNotifier {
  /// Kullanıcı yazmayı bıraktıktan sonra otomatik arama için beklenecek süre (5 sn)
  static const Duration searchDebounceDuration = Duration(seconds: 5);

  /// Arama ve debounce tetiklenmesi için zorunlu minimum karakter sayısı
  static const int minSearchChars = 3;

  final Set<ContinentFilter> _selectedFullContinents = <ContinentFilter>{};
  final Set<String> _selectedFullCountryCodes = <String>{};
  final Set<String> _selectedCities = <String>{};

  final Set<ContinentFilter> _expandedContinents = <ContinentFilter>{};
  final Set<String> _expandedCountryCodes = <String>{};

  /// Hiyerarşik bölge ağacı çekmecesinin en üstündeki akıllı filtre metni
  String _treeSearchQuery = '';

  /// Yakınımdaki Konumları Göster (Anlık Konum) modu aktif mi?
  bool _isNearbyMode = false;

  /// Yakınımdaki Konumlar aktifken gösterilen anlık konum doğrulama metni
  final String _detectedLocationLabel = 'Konak / İzmir / Türkiye';

  /// Kullanıcının arama kutucuğuna anlık yazdığı metin
  String _draftSearchInput = '';

  /// 5 sn sonunda veya "Ara" butonuna basıldığında aktifleşen arama metni
  String _committedSearchQuery = '';

  /// 5 saniyelik geri sayım (debounce) bekleniyor mu?
  bool _isWaitingForDebounce = false;
  int _debounceCycleId = 0;

  Timer? _searchDebounceTimer;

  /// Rotalar için Çift Taraflı Bütçe Aralığı (TL) Filtresi Sınırları
  static const double minBudgetLimitTl = 0.0;
  static const double maxBudgetLimitTl = 100000.0;

  double _selectedMinBudgetTl = minBudgetLimitTl;
  double _selectedMaxBudgetTl = maxBudgetLimitTl;

  /// Alt sınıfların sağlaması gereken ülke ve şehir veri kaynakları
  List<CountryFilterOption> getCountriesForContinent(ContinentFilter continent);
  List<String> getCitiesForCountry(String countryCode);

  /// Türkçe karakter duyarlı küçük harfe çevirme (İ->i, I->ı)
  static String normalizeTr(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  // --- Konum, Bütçe & Metin Arama Getter ve Aksiyonları ---

  bool get isNearbyMode => _isNearbyMode;
  String get detectedLocationLabel => _detectedLocationLabel;
  String get draftSearchInput => _draftSearchInput;
  String get committedSearchQuery => _committedSearchQuery;
  bool get isWaitingForDebounce => _isWaitingForDebounce;
  int get debounceCycleId => _debounceCycleId;

  double get selectedMinBudgetTl => _selectedMinBudgetTl;
  double get selectedMaxBudgetTl => _selectedMaxBudgetTl;
  bool get isBudgetFilterActive =>
      _selectedMinBudgetTl > minBudgetLimitTl ||
      _selectedMaxBudgetTl < maxBudgetLimitTl;

  static String formatTlCurrency(double amount) {
    final rounded = amount.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '₺$buffer';
  }

  String get budgetFilterCompactLabel =>
      '${formatTlCurrency(_selectedMinBudgetTl)} – ${formatTlCurrency(_selectedMaxBudgetTl)}';

  void updateBudgetRange(double minTl, double maxTl) {
    final clampedMin = minTl.clamp(minBudgetLimitTl, maxBudgetLimitTl);
    final clampedMax = maxTl.clamp(clampedMin, maxBudgetLimitTl);
    if (_selectedMinBudgetTl == clampedMin &&
        _selectedMaxBudgetTl == clampedMax) {
      return;
    }
    _selectedMinBudgetTl = clampedMin;
    _selectedMaxBudgetTl = clampedMax;
    notifyListeners();
  }

  void resetBudgetFilter() {
    if (!isBudgetFilterActive) return;
    _selectedMinBudgetTl = minBudgetLimitTl;
    _selectedMaxBudgetTl = maxBudgetLimitTl;
    notifyListeners();
  }

  void toggleNearbySearch() {
    _isNearbyMode = !_isNearbyMode;
    notifyListeners();
  }

  /// Kullanıcı her harfe bastığında API'ye istek atılmaz;
  /// yalnızca en az 3 karakter girildikten sonra 5 saniyelik debounce başlar.
  void onSearchInputChanged(String value) {
    _draftSearchInput = value;
    _searchDebounceTimer?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      _isWaitingForDebounce = false;
      _committedSearchQuery = '';
      notifyListeners();
      return;
    }

    if (trimmed.length < minSearchChars) {
      _isWaitingForDebounce = false;
      notifyListeners();
      return;
    }

    _isWaitingForDebounce = true;
    _debounceCycleId++;
    notifyListeners();

    _searchDebounceTimer = Timer(searchDebounceDuration, () {
      executeTextSearchNow();
    });
  }

  /// Manuel "Ara" butonuna basıldığında (debounce dolmadan) veya 5 sn dolduğunda
  /// 3 karakter kontrolü yaparak aramayı çalıştırır.
  bool executeTextSearchNow() {
    final trimmed = _draftSearchInput.trim();
    if (trimmed.length < minSearchChars) {
      return false;
    }

    _searchDebounceTimer?.cancel();
    _isWaitingForDebounce = false;
    _committedSearchQuery = trimmed;
    notifyListeners();
    return true;
  }

  void clearSearchInput() {
    _searchDebounceTimer?.cancel();
    _draftSearchInput = '';
    _committedSearchQuery = '';
    _isWaitingForDebounce = false;
    notifyListeners();
  }

  @protected
  void disposeSearchDebounce() {
    _searchDebounceTimer?.cancel();
  }

  // --- Coğrafi Ağaç Getter ve Aksiyonları ---

  String get treeSearchQuery => _treeSearchQuery;

  void updateTreeSearchQuery(String query) {
    _treeSearchQuery = query;
    notifyListeners();
  }

  void clearTreeSearchQuery() {
    if (_treeSearchQuery.isEmpty) return;
    _treeSearchQuery = '';
    notifyListeners();
  }

  List<ContinentFilter> get selectableContinents => ContinentFilter.values
      .where((c) => c != ContinentFilter.global)
      .toList(growable: false);

  /// Ağaç içi arama metnine göre eşleşen kıtaları döndürür
  List<ContinentFilter> get filteredContinentsForTree {
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty) return selectableContinents;

    return selectableContinents.where((continent) {
      if (normalizeTr(continent.label).contains(q)) return true;
      return getFilteredCountriesForTree(continent).isNotEmpty;
    }).toList(growable: false);
  }

  /// Ağaç içi arama metnine göre kıtanın altındaki eşleşen ülkeleri döndürür
  List<CountryFilterOption> getFilteredCountriesForTree(
    ContinentFilter continent,
  ) {
    final allCountries = getCountriesForContinent(continent);
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty || normalizeTr(continent.label).contains(q)) {
      return allCountries;
    }

    return allCountries.where((country) {
      if (normalizeTr(country.nameTr).contains(q) ||
          normalizeTr(country.code).contains(q)) {
        return true;
      }
      final cities = getCitiesForCountry(country.code);
      return cities.any((city) => normalizeTr(city).contains(q));
    }).toList(growable: false);
  }

  /// Ağaç içi arama metnine göre ülkenin altındaki eşleşen şehirleri döndürür
  List<String> getFilteredCitiesForTree(CountryFilterOption country) {
    final allCities = getCitiesForCountry(country.code);
    final q = normalizeTr(_treeSearchQuery);
    if (q.isEmpty ||
        normalizeTr(country.nameTr).contains(q) ||
        normalizeTr(country.code).contains(q)) {
      return allCities;
    }

    final matchingCities =
        allCities.where((c) => normalizeTr(c).contains(q)).toList();
    return matchingCities.isNotEmpty ? matchingCities : allCities;
  }

  bool get isGlobalSelected =>
      _selectedFullContinents.isEmpty &&
      _selectedFullCountryCodes.isEmpty &&
      _selectedCities.isEmpty;

  Set<ContinentFilter> get selectedFullContinents =>
      Set<ContinentFilter>.unmodifiable(_selectedFullContinents);
  Set<String> get selectedFullCountryCodes =>
      Set<String>.unmodifiable(_selectedFullCountryCodes);
  Set<String> get selectedCities => Set<String>.unmodifiable(_selectedCities);

  bool isContinentChecked(ContinentFilter continent) =>
      _selectedFullContinents.contains(continent);

  bool isContinentExpanded(ContinentFilter continent) {
    if (isContinentChecked(continent)) return false;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty) {
      return getFilteredCountriesForTree(continent).isNotEmpty;
    }
    return _expandedContinents.contains(continent);
  }

  bool isCountryChecked(String countryCode) =>
      _selectedFullCountryCodes.contains(countryCode);

  bool isCountryExpanded(String countryCode) {
    if (isCountryChecked(countryCode)) return false;
    final q = normalizeTr(_treeSearchQuery);
    if (q.isNotEmpty) {
      final cities = getCitiesForCountry(countryCode);
      if (cities.any((c) => normalizeTr(c).contains(q))) {
        return true;
      }
    }
    return _expandedCountryCodes.contains(countryCode);
  }

  bool isCityChecked(String city) => _selectedCities.contains(city);

  /// Kıta checkbox'ı işaretli DEĞİLKEN altındaki ülke/şehir seçim özetini döndürür
  String? getContinentPartialSelectionBadge(ContinentFilter continent) {
    if (isContinentChecked(continent)) return null;
    final countries = getCountriesForContinent(continent);
    int checkedCountryCount = 0;
    int checkedCityCount = 0;

    for (final c in countries) {
      if (_selectedFullCountryCodes.contains(c.code)) {
        checkedCountryCount++;
      } else {
        final cities = getCitiesForCountry(c.code);
        checkedCityCount += cities.where(_selectedCities.contains).length;
      }
    }

    if (checkedCountryCount > 0 && checkedCityCount > 0) {
      return '$checkedCountryCount ülke • $checkedCityCount şehir';
    } else if (checkedCountryCount > 0) {
      return '$checkedCountryCount ülke seçili';
    } else if (checkedCityCount > 0) {
      return '$checkedCityCount şehir seçili';
    }
    return null;
  }

  /// Ülke checkbox'ı işaretli DEĞİLKEN altındaki şehir seçim özetini döndürür
  String? getCountryPartialSelectionBadge(String countryCode) {
    if (isCountryChecked(countryCode)) return null;
    final cities = getCitiesForCountry(countryCode);
    final count = cities.where(_selectedCities.contains).length;
    if (count > 0) {
      return '$count şehir seçili';
    }
    return null;
  }

  /// Seçili kıta, ülke ve şehirleri okunaklı hiyerarşik özet metni olarak döndürür.
  /// Örn: "🇪🇺 Avrupa (Tümü)" veya "🇮🇹 İtalya: Como, Milano, Cinque Terre"
  String get geographyFilterButtonTitle {
    if (isGlobalSelected) {
      return 'Global (Tüm Dünya)';
    }
    final parts = <String>[];
    final handledCities = <String>{};

    for (final continent in _selectedFullContinents) {
      parts.add('${continent.label} (Tümü)');
    }

    for (final continent in selectableContinents) {
      if (_selectedFullContinents.contains(continent)) continue;
      for (final country in getCountriesForContinent(continent)) {
        if (_selectedFullCountryCodes.contains(country.code)) {
          parts.add('${country.flagEmoji} ${country.nameTr} (Tümü)');
        } else {
          final countryCities = getCitiesForCountry(country.code);
          final selectedInCountry =
              countryCities.where(_selectedCities.contains).toList();
          if (selectedInCountry.isNotEmpty) {
            handledCities.addAll(selectedInCountry);
            parts.add(
              '${country.flagEmoji} ${country.nameTr}: ${selectedInCountry.join(', ')}',
            );
          }
        }
      }
    }

    for (final city in _selectedCities) {
      if (!handledCities.contains(city)) {
        parts.add('📍 $city');
      }
    }

    return parts.join('  •  ');
  }

  // --- Hiyerarşik Coğrafya Ağacı Aksiyonları ---

  void resetToGlobal() {
    if (isGlobalSelected &&
        _expandedContinents.isEmpty &&
        _expandedCountryCodes.isEmpty) {
      return;
    }
    _selectedFullContinents.clear();
    _selectedFullCountryCodes.clear();
    _selectedCities.clear();
    _expandedContinents.clear();
    _expandedCountryCodes.clear();
    notifyListeners();
  }

  /// Kıta checkbox'ı işaretlendiğinde o kıtadaki ülkeleri görüntülemeye gerek kalmaz (alt ağaç kapanır).
  void toggleContinentCheckbox(ContinentFilter continent) {
    _isNearbyMode = false;
    if (_selectedFullContinents.contains(continent)) {
      _selectedFullContinents.remove(continent);
    } else {
      _selectedFullContinents.add(continent);
      _expandedContinents.remove(continent);

      for (final country in getCountriesForContinent(continent)) {
        _selectedFullCountryCodes.remove(country.code);
        _expandedCountryCodes.remove(country.code);
        for (final city in getCitiesForCountry(country.code)) {
          _selectedCities.remove(city);
        }
      }
    }
    notifyListeners();
  }

  /// Kıta checkbox'ı işaretli değilse altındaki ülkeleri açıp kapatır
  void toggleContinentExpanded(ContinentFilter continent) {
    if (_selectedFullContinents.contains(continent)) return;
    if (_expandedContinents.contains(continent)) {
      _expandedContinents.remove(continent);
    } else {
      _expandedContinents.add(continent);
    }
    notifyListeners();
  }

  /// Ülke checkbox'ı işaretlendiğinde o ülkeye ait şehirler otomatik dahil edilir ve şehir ağacı kapanır.
  void toggleCountryCheckbox(String countryCode) {
    _isNearbyMode = false;
    if (_selectedFullCountryCodes.contains(countryCode)) {
      _selectedFullCountryCodes.remove(countryCode);
    } else {
      _selectedFullCountryCodes.add(countryCode);
      _expandedCountryCodes.remove(countryCode);

      for (final city in getCitiesForCountry(countryCode)) {
        _selectedCities.remove(city);
      }
    }
    notifyListeners();
  }

  /// Ülke checkbox'ı işaretli değilse altındaki şehirleri açıp kapatır
  void toggleCountryExpanded(String countryCode) {
    if (_selectedFullCountryCodes.contains(countryCode)) return;
    if (_expandedCountryCodes.contains(countryCode)) {
      _expandedCountryCodes.remove(countryCode);
    } else {
      _expandedCountryCodes.add(countryCode);
    }
    notifyListeners();
  }

  /// Tekil şehir seçimi (Ülke checkbox'ı işaretli değilken çalışır)
  void toggleCityCheckbox(String city) {
    _isNearbyMode = false;
    if (_selectedCities.contains(city)) {
      _selectedCities.remove(city);
    } else {
      _selectedCities.add(city);
    }
    notifyListeners();
  }
}
