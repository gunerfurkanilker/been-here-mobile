import 'package:flutter/material.dart';

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
  });

  final String code;
  final String name;
  final String flagEmoji;
  final String imageUrl;
  final List<BuilderCityCatalogItem> cities;
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
  flexible,
  currentOrPastTrip,
  upcomingWeekend,
  customRange,
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

class RouteBuilderViewModel extends ChangeNotifier {
  RouteBuilderViewModel();

  RouteWizardStep _currentStep = RouteWizardStep.locations;
  RouteWizardStep get currentStep => _currentStep;

  /// 1. Satır: Aktif Seçili Kıta (Varsayılan: Avrupa)
  /// Null olduğunda tüm kıtalar / dünya çapında listeleme yapılır.
  String? _activeContinentId = 'europe';
  String? get activeContinentId => _activeContinentId;

  /// 2. Satır: Aktif Seçili Alt Bölge (Varsayılan: Batı Avrupa — taslaktaki gibi)
  /// Tekrar tıklanırsa (toggle) null olur ve kıtadaki tüm alt bölgelerin ülkeleri listelenir.
  String? _activeSubRegionId = 'western_europe';
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

  DateTimeRange? _customDateRange;
  DateTimeRange? get customDateRange => _customDateRange;

  bool _isBudgetEnabled = false;
  bool get isBudgetEnabled => _isBudgetEnabled;

  RouteBudgetCurrency _currency = RouteBudgetCurrency.tryCurrency;
  RouteBudgetCurrency get currency => _currency;

  double _minBudget = 0;
  double _maxBudget = 35000;
  double get minBudget => _minBudget;
  double get maxBudget => _maxBudget;

  int _adultsCount = 2;
  int _childrenCount = 0;
  int get adultsCount => _adultsCount;
  int get childrenCount => _childrenCount;
  int get totalTravelersCount => _adultsCount + _childrenCount;

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
              imageUrl:
                  'https://images.unsplash.com/photo-1543783207-ec64e4d95325?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Sevilla',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1558642084-fd07fae5282e?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Cadiz',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Madrid',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Barselona',
                  countryCode: 'ES',
                  countryName: 'İspanya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1583422409516-2895a77efded?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'TR',
              name: 'Türkiye',
              flagEmoji: '🇹🇷',
              imageUrl:
                  'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'İstanbul',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl:
                      'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'İzmir',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl:
                      'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Ankara',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl:
                      'https://images.unsplash.com/photo-1569383746724-6f1b882b8f46?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Fethiye',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl:
                      'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Marmaris',
                  countryCode: 'TR',
                  countryName: 'Türkiye',
                  imageUrl:
                      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'FR',
              name: 'Fransa',
              flagEmoji: '🇫🇷',
              imageUrl:
                  'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Paris',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl:
                      'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Lyon',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl:
                      'https://images.unsplash.com/photo-1524396309943-e03f5249f002?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Marsilya',
                  countryCode: 'FR',
                  countryName: 'Fransa',
                  imageUrl:
                      'https://images.unsplash.com/photo-1565019011521-b0575cbb57c9?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'GB',
              name: 'İngiltere',
              flagEmoji: '🇬🇧',
              imageUrl:
                  'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Londra',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl:
                      'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Manchester',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl:
                      'https://images.unsplash.com/photo-1515586838455-8f8f940d6853?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'York',
                  countryCode: 'GB',
                  countryName: 'İngiltere',
                  imageUrl:
                      'https://images.unsplash.com/photo-1580655653885-65763b2597d0?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'IT',
              name: 'İtalya',
              flagEmoji: '🇮🇹',
              imageUrl:
                  'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Roma',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Floransa',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1541370976299-4d24ebbc9077?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Venedik',
                  countryCode: 'IT',
                  countryName: 'İtalya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1514890547357-a9ee288728e0?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'BE',
              name: 'Belçika',
              flagEmoji: '🇧🇪',
              imageUrl:
                  'https://images.unsplash.com/photo-1491557345352-5929e343eb89?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Brugge',
                  countryCode: 'BE',
                  countryName: 'Belçika',
                  imageUrl:
                      'https://images.unsplash.com/photo-1491557345352-5929e343eb89?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Brüksel',
                  countryCode: 'BE',
                  countryName: 'Belçika',
                  imageUrl:
                      'https://images.unsplash.com/photo-1559113202-c916b8e44373?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'NL',
              name: 'Hollanda',
              flagEmoji: '🇳🇱',
              imageUrl:
                  'https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Amsterdam',
                  countryCode: 'NL',
                  countryName: 'Hollanda',
                  imageUrl:
                      'https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Rotterdam',
                  countryCode: 'NL',
                  countryName: 'Hollanda',
                  imageUrl:
                      'https://images.unsplash.com/photo-1543783207-ec64e4d95325?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1541849546-216549ae216d?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Prag',
                  countryCode: 'CZ',
                  countryName: 'Çekya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1541849546-216549ae216d?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Cesky Krumlov',
                  countryCode: 'CZ',
                  countryName: 'Çekya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'HU',
              name: 'Macaristan',
              flagEmoji: '🇭🇺',
              imageUrl:
                  'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Budapeşte',
                  countryCode: 'HU',
                  countryName: 'Macaristan',
                  imageUrl:
                      'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Estergon',
                  countryCode: 'HU',
                  countryName: 'Macaristan',
                  imageUrl:
                      'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'PL',
              name: 'Polonya',
              flagEmoji: '🇵🇱',
              imageUrl:
                  'https://images.unsplash.com/photo-1519197924294-4ba991a11128?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Krakov',
                  countryCode: 'PL',
                  countryName: 'Polonya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1519197924294-4ba991a11128?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Varşova',
                  countryCode: 'PL',
                  countryName: 'Polonya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1607427293702-036933bbf746?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Oslo',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl:
                      'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Bergen',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl:
                      'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Tromsø',
                  countryCode: 'NO',
                  countryName: 'Norveç',
                  imageUrl:
                      'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'SE',
              name: 'İsveç',
              flagEmoji: '🇸🇪',
              imageUrl:
                  'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Stockholm',
                  countryCode: 'SE',
                  countryName: 'İsveç',
                  imageUrl:
                      'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Göteborg',
                  countryCode: 'SE',
                  countryName: 'İsveç',
                  imageUrl:
                      'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Tokyo',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Kyoto',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Osaka',
                  countryCode: 'JP',
                  countryName: 'Japonya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1590559899731-a382839e5549?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'RU',
              name: 'Rusya',
              flagEmoji: '🇷🇺',
              imageUrl:
                  'https://images.unsplash.com/photo-1513326738677-b964603b136d?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Moskova',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1513326738677-b964603b136d?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'St. Petersburg',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1556610961-2fecc5927173?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Kazan',
                  countryCode: 'RU',
                  countryName: 'Rusya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1547448415-e9f5b28e570d?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Phuket',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl:
                      'https://images.unsplash.com/photo-1589394815804-964ed0be2eb5?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Bangkok',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl:
                      'https://images.unsplash.com/photo-1508009603885-50cf7c579365?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Chiang Mai',
                  countryCode: 'TH',
                  countryName: 'Tayland',
                  imageUrl:
                      'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Marakeş',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl:
                      'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Kazablanka',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl:
                      'https://images.unsplash.com/photo-1548013146-72479768bada?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Şafşavan',
                  countryCode: 'MA',
                  countryName: 'Fas',
                  imageUrl:
                      'https://images.unsplash.com/photo-1553899017-90b83090a15c?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Cape Town',
                  countryCode: 'ZA',
                  countryName: 'Güney Afrika',
                  imageUrl:
                      'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Johannesburg',
                  countryCode: 'ZA',
                  countryName: 'Güney Afrika',
                  imageUrl:
                      'https://images.unsplash.com/photo-1577948000111-9c970dfe3743?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'New York',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl:
                      'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'San Francisco',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl:
                      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Los Angeles',
                  countryCode: 'US',
                  countryName: 'ABD',
                  imageUrl:
                      'https://images.unsplash.com/photo-1534190760961-74e8c1c5c3da?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'CA',
              name: 'Kanada',
              flagEmoji: '🇨🇦',
              imageUrl:
                  'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Toronto',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl:
                      'https://images.unsplash.com/photo-1517090504586-fde19ea6066f?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Vancouver',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl:
                      'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Montreal',
                  countryCode: 'CA',
                  countryName: 'Kanada',
                  imageUrl:
                      'https://images.unsplash.com/photo-1519178614-68673b201f36?auto=format&fit=crop&w=600&q=80',
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
              imageUrl:
                  'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Sidney',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Melbourne',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1514395462725-fb4566210144?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Brisbane',
                  countryCode: 'AU',
                  countryName: 'Avustralya',
                  imageUrl:
                      'https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?auto=format&fit=crop&w=600&q=80',
                ),
              ],
            ),
            BuilderCountryCatalogItem(
              code: 'NZ',
              name: 'Yeni Zelanda',
              flagEmoji: '🇳🇿',
              imageUrl:
                  'https://images.unsplash.com/photo-1507699622108-4be3abd695ad?auto=format&fit=crop&w=700&q=80',
              cities: [
                BuilderCityCatalogItem(
                  name: 'Queenstown',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl:
                      'https://images.unsplash.com/photo-1507699622108-4be3abd695ad?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Auckland',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl:
                      'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=600&q=80',
                ),
                BuilderCityCatalogItem(
                  name: 'Wellington',
                  countryCode: 'NZ',
                  countryName: 'Yeni Zelanda',
                  imageUrl:
                      'https://images.unsplash.com/photo-1469521669194-babb45599def?auto=format&fit=crop&w=600&q=80',
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

  /// Aktif seçili kıta objesi (Null ise tüm dünyayı listeler)
  BuilderContinentCatalogItem? get activeContinent {
    if (_activeContinentId == null) return null;
    for (final c in continentsCatalog) {
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

  /// Tüm filtreleri sıfırlar
  void clearAllFilters() {
    _activeContinentId = null;
    _activeSubRegionId = null;
    _searchFilterQuery = '';
    notifyListeners();
  }

  /// Alt tarafta satır satır ([Ülke] -> [Şehir1] [Şehir2] [Şehir3]) listelenecek ülkeler
  List<BuilderCountryCatalogItem> get displayedCountries {
    List<BuilderCountryCatalogItem> source;

    if (_activeContinentId == null) {
      // 1. Kıta seçili değil: Tüm kıtalardaki ülkeler listelenir
      source = [
        for (final c in continentsCatalog) ...c.allCountries,
      ];
    } else if (_activeSubRegionId == null) {
      // 2. Kıta seçili ama alt bölge seçili değil: o kıtanın tüm ülkeleri
      final cont = activeContinent;
      source = cont != null
          ? cont.allCountries
          : [for (final c in continentsCatalog) ...c.allCountries];
    } else {
      // 3. Hem kıta hem alt bölge seçili: o alt bölgenin ülkeleri
      final cont = activeContinent;
      if (cont != null) {
        final sub = cont.subRegions.firstWhere(
          (sr) => sr.id == _activeSubRegionId,
          orElse: () => cont.subRegions.first,
        );
        source = sub.countries;
      } else {
        source = [for (final c in continentsCatalog) ...c.allCountries];
      }
    }

    if (_searchFilterQuery.isEmpty) return source;

    return source.where((c) {
      final countryMatch = _normalizeTr(c.name).contains(_searchFilterQuery);
      final cityMatch = c.cities.any(
        (city) => _normalizeTr(city.name).contains(_searchFilterQuery),
      );
      return countryMatch || cityMatch;
    }).toList();
  }

  /// Bir ülke satırının sağ tarafında gösterilecek şehirler
  /// (Arama filtresi varsa eşleşen şehirler, ülke adı eşleştiyse tüm şehirleri gelir)
  List<BuilderCityCatalogItem> getDisplayedCitiesForCountry(
    BuilderCountryCatalogItem country,
  ) {
    if (_searchFilterQuery.isEmpty ||
        _normalizeTr(country.name).contains(_searchFilterQuery)) {
      return country.cities;
    }
    return country.cities
        .where((city) => _normalizeTr(city.name).contains(_searchFilterQuery))
        .toList();
  }

  // --- Seçim İşlemleri (Tekil Seçim / Long Press / Sağ Üst Toggle) ---

  bool isCountrySelected(String countryCode) =>
      _selectedCountryCodes.contains(countryCode);

  bool isCitySelected(BuilderCityCatalogItem city) =>
      _selectedCityKeys.contains(cityKey(city.countryCode, city.name));

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
    notifyListeners();
  }

  int get totalSelectedCountryCount => _selectedCountryCodes.length;
  int get totalSelectedCityCount => _selectedCityKeys.length;
  bool get hasAnyDestinationSelected =>
      _selectedCountryCodes.isNotEmpty || _selectedCityKeys.isNotEmpty;

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

  void setDateMode(RouteDateMode mode) {
    _dateMode = mode;
    notifyListeners();
  }

  void setCustomDateRange(DateTimeRange range) {
    _customDateRange = range;
    _dateMode = RouteDateMode.customRange;
    notifyListeners();
  }

  String get formattedDateSummary {
    switch (_dateMode) {
      case RouteDateMode.flexible:
        return 'Tarih Esnek';
      case RouteDateMode.currentOrPastTrip:
        return 'Şu An / Geçmiş Gezi';
      case RouteDateMode.upcomingWeekend:
        return 'Bu Hafta Sonu';
      case RouteDateMode.customRange:
        if (_customDateRange == null) return 'Tarih Seçildi';
        final s = _customDateRange!.start;
        final e = _customDateRange!.end;
        final days = _customDateRange!.duration.inDays + 1;
        return '${s.day}.${s.month} - ${e.day}.${e.month} ($days Gün)';
    }
  }

  void toggleBudgetEnabled() {
    _isBudgetEnabled = !_isBudgetEnabled;
    notifyListeners();
  }

  void setBudgetCurrency(RouteBudgetCurrency newCurrency) {
    if (_currency == newCurrency) return;
    _currency = newCurrency;
    _minBudget = 0;
    _maxBudget = (newCurrency.maxLimit * 0.4).roundToDouble();
    notifyListeners();
  }

  void updateRouteBudgetRange(double minVal, double maxVal) {
    _minBudget = minVal.clamp(0, _currency.maxLimit);
    _maxBudget = maxVal.clamp(_minBudget, _currency.maxLimit);
    notifyListeners();
  }

  String formatCurrencyAmount(double value) {
    final rounded = value.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${_currency.symbol}$buffer';
  }

  String get formattedBudgetSummary {
    if (!_isBudgetEnabled) return 'Bütçe Sınırı Yok';
    return '${formatCurrencyAmount(_minBudget)} – ${formatCurrencyAmount(_maxBudget)}';
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
