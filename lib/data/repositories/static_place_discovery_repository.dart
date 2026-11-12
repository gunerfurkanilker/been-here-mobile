import '../../domain/models/place_discovery_models.dart';
import '../../domain/models/route_feed_models.dart';
import 'static_home_routes_repository.dart';

class StaticPlaceDiscoveryRepository {
  StaticPlaceDiscoveryRepository({StaticHomeRoutesRepository? routesRepository})
      : _routesRepository = routesRepository ?? StaticHomeRoutesRepository();

  final StaticHomeRoutesRepository _routesRepository;

  final List<PlaceDiscoveryItem> _places = [
    const PlaceDiscoveryItem(
      id: 'place-tr-amintas',
      name: 'Amintas Kaya Mezarları',
      shortSummary:
          'M.Ö. 4. yüzyıldan kalma Likya dönemi anıt mezarları. Gün batımında Fethiye Körfezi ve Şövalye Adası\'nı panoramik izlemek için en etkileyici nokta.',
      continent: ContinentFilter.europe,
      countryCode: 'TR',
      countryName: 'Türkiye',
      city: 'Fethiye',
      uiCategory: 'DESTINATION',
      categoryLabel: 'Tarihi & Manzara',
      averageRating: 4.9,
      verifiedVisitCount: 184,
      distanceKmFromUser: 3.2,
      photoUrls: [
        'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Antik Likya',
        'Panoramik Manzara',
        'Gün Batımı',
        'Fotoğraf Noktası',
        'Kültürel Miras',
      ],
      warnings: [
        'Merdivenli Çıkış - Su Yanınızda Olsun (22 oy)',
      ],
      relatedRouteIds: ['route-tr-marmaris-00'],
    ),
    const PlaceDiscoveryItem(
      id: 'place-tr-yuvarlakcay',
      name: 'Yuvarlakçay Doğa & Su Üstü Çardaklar',
      shortSummary:
          'Sandras Dağı\'nın kar sularıyla beslenen buz gibi akarsu üzerinde kurulu ahşap çardaklar, su üstü salıncaklar ve yerel alabalık restoranları.',
      continent: ContinentFilter.europe,
      countryCode: 'TR',
      countryName: 'Türkiye',
      city: 'Köyceğiz',
      uiCategory: 'FOOD',
      categoryLabel: 'Doğa & Lezzet Durağı',
      averageRating: 4.8,
      verifiedVisitCount: 142,
      distanceKmFromUser: 8.6,
      photoUrls: [
        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Buz Gibi Su',
        'Doğa İçinde',
        'Serinleme Noktası',
        'Aile Dostu',
      ],
      warnings: [
        'Hafta Sonu Öğleden Sonra Yoğun Olur (14 oy)',
      ],
      relatedRouteIds: ['route-tr-marmaris-00'],
    ),
    const PlaceDiscoveryItem(
      id: 'place-tr-od-urla',
      name: 'Od Urla & Urla Bağ Yolu',
      shortSummary:
          'Zeytinlikler ve üzüm bağları arasında tarladan sofraya gastronomi deneyimi sunan, odun ateşinde pişirilen Ege mutfağı durağı.',
      continent: ContinentFilter.europe,
      countryCode: 'TR',
      countryName: 'Türkiye',
      city: 'Urla',
      uiCategory: 'FOOD',
      categoryLabel: 'Gastronomi & Bağ Evi',
      averageRating: 4.9,
      verifiedVisitCount: 215,
      distanceKmFromUser: 14.5,
      photoUrls: [
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Gastronomi',
        'Bağ Evi',
        'Romantik Akşam',
        'Yerel Üretim',
      ],
      warnings: [
        'Haftalar Öncesinden Rezervasyon Gerekli (31 oy)',
      ],
      relatedRouteIds: ['route-tr-04', 'route-tr-marmaris-00'],
    ),
    const PlaceDiscoveryItem(
      id: 'place-de-brandenburg',
      name: 'Brandenburg Kapısı & Pariser Platz',
      shortSummary:
          'Berlin\'in simgesi olan 18. yüzyıl neoklasik anıt kapısı. Sabah erken saatlerde yürüyüş ve fotoğraf çekimi için Avrupa\'nın en ikonik meydanlarından biri.',
      continent: ContinentFilter.europe,
      countryCode: 'DE',
      countryName: 'Almanya',
      city: 'Berlin',
      uiCategory: 'DESTINATION',
      categoryLabel: 'Tarihi Simge',
      averageRating: 4.8,
      verifiedVisitCount: 310,
      distanceKmFromUser: 1840.0,
      photoUrls: [
        'https://images.unsplash.com/photo-1560969184-10fe8719e047?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1528728329032-2972f65dfb3f?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Tarihi',
        'Sabah Yürüyüşü',
        'Fotojenik',
        'Şehir Merkezi',
      ],
      warnings: [],
      relatedRouteIds: ['route-de-be-01'],
    ),
    const PlaceDiscoveryItem(
      id: 'place-it-bellagio',
      name: 'Bellagio & Villa del Balbianello',
      shortSummary:
          'Como Gölü\'nün iki kolunun birleştiği burunda yer alan masalsı İtalyan kasabası ve göl kıyısındaki tarihi teras bahçeleri.',
      continent: ContinentFilter.europe,
      countryCode: 'IT',
      countryName: 'İtalya',
      city: 'Como',
      uiCategory: 'DESTINATION',
      categoryLabel: 'Göl & Mimari',
      averageRating: 5.0,
      verifiedVisitCount: 276,
      distanceKmFromUser: 1620.0,
      photoUrls: [
        'https://images.unsplash.com/photo-1534445867742-43195f401b6c?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Romantik',
        'Göl Manzarası',
        'Tekne Turu',
        'Tarihi Villa',
      ],
      warnings: [
        'Villa Pazartesi ve Çarşamba Günleri Kapalıdır (18 oy)',
      ],
      relatedRouteIds: ['route-it-fr-02'],
    ),
    const PlaceDiscoveryItem(
      id: 'place-th-wat-arun',
      name: 'Wat Arun (Şafak Tapınağı)',
      shortSummary:
          'Chao Phraya Nehri kıyısında yükselen, renkli porselen mozaiklerle bezeli Bangkok\'un en görkemli Budist tapınağı.',
      continent: ContinentFilter.asia,
      countryCode: 'TH',
      countryName: 'Tayland',
      city: 'Bangkok',
      uiCategory: 'DESTINATION',
      categoryLabel: 'Tapınak & Kültür',
      averageRating: 4.9,
      verifiedVisitCount: 198,
      distanceKmFromUser: 7450.0,
      photoUrls: [
        'https://images.unsplash.com/photo-1508009603885-50cf7c579365?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1528181304800-259b08848526?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: [
        'Tapınak',
        'Gün Batımı',
        'Uzak Doğu Kültürü',
        'Nehir Kıyısı',
      ],
      warnings: [
        'Omuz ve Diz Kapalı Kıyafet Zorunlu (38 oy)',
      ],
      relatedRouteIds: ['route-th-03'],
    ),
  ];

  static const Map<String, List<String>> _citiesByCountryCode = {
    'TR': ['Fethiye', 'Köyceğiz', 'Urla', 'Marmaris', 'İzmir'],
    'DE': ['Berlin', 'Köln', 'Münih'],
    'IT': ['Como', 'Milano', 'Cinque Terre', 'Roma'],
    'FR': ['Nice', 'Paris', 'Lyon'],
    'BE': ['Brüksel', 'Brugge'],
    'NL': ['Amsterdam', 'Rotterdam'],
    'TH': ['Bangkok', 'Chiang Mai', 'Phuket'],
    'JP': ['Tokyo', 'Kyoto', 'Osaka'],
    'RU': ['Moskova', 'St. Petersburg'],
    'US': ['New York', 'San Francisco', 'Los Angeles'],
    'CA': ['Toronto', 'Vancouver'],
    'BR': ['Rio de Janeiro', 'São Paulo'],
    'AR': ['Buenos Aires', 'Bariloche'],
  };

  List<PlaceDiscoveryItem> get allPlaces => List.unmodifiable(_places);

  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent, {
    String searchQuery = '',
  }) {
    return _routesRepository.getCountriesForContinent(
      continent,
      searchQuery: searchQuery,
    );
  }

  /// İlgili ülke koduna ait şehir listesini döndürür
  List<String> getCitiesForCountry(String countryCode) {
    final predefined = _citiesByCountryCode[countryCode] ?? const <String>[];
    final fromPlaces = _places
        .where((p) => p.countryCode == countryCode)
        .map((p) => p.city);
    return {...predefined, ...fromPlaces}.toList(growable: false);
  }

  /// Hiyerarşik ağaç seçimine (Tam Kıta / Tam Ülke / Tekil Şehir), arama moduna ve metne göre mekanları süzer.
  /// Not: `searchMode == PlaceSearchMode.nearby` (Anlık Konum) aktif olduğunda
  /// konum öncelikli çalışır ve hiyerarşik bölge filtresi arka planda bekler.
  List<PlaceDiscoveryItem> getFilteredPlaces({
    required Set<ContinentFilter> selectedFullContinents,
    required Set<String> selectedFullCountries,
    required Set<String> selectedCities,
    required PlaceSearchMode searchMode,
    required String searchQuery,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final isNearbyPriority = searchMode == PlaceSearchMode.nearby;
    final isGlobalSelected = selectedFullContinents.isEmpty &&
        selectedFullCountries.isEmpty &&
        selectedCities.isEmpty;

    final results = _places.where((place) {
      // 1. Hiyerarşik Coğrafya Ağacı Filtresi:
      // Yalnızca Anlık Konum KAPALIYKEN ve Global değilken uygulanır.
      // Anlık Konum açıkken bölge filtresi arka planda korunur, konum öncelikli olur.
      if (!isNearbyPriority && !isGlobalSelected) {
        final matchesFullContinent =
            selectedFullContinents.contains(place.continent);
        final matchesFullCountry =
            selectedFullCountries.contains(place.countryCode);
        final matchesSpecificCity = selectedCities.contains(place.city);

        if (!matchesFullContinent &&
            !matchesFullCountry &&
            !matchesSpecificCity) {
          return false;
        }
      }

      // 2. Text araması varsa isim, şehir, ülke veya vibe etiketlerinde ara
      if (normalizedQuery.isNotEmpty) {
        final matchesName = place.name.toLowerCase().contains(normalizedQuery);
        final matchesCity = place.city.toLowerCase().contains(normalizedQuery);
        final matchesCountry =
            place.countryName.toLowerCase().contains(normalizedQuery);
        final matchesVibe = place.communityVibes.any(
          (v) => v.toLowerCase().contains(normalizedQuery),
        );
        if (!matchesName && !matchesCity && !matchesCountry && !matchesVibe) {
          return false;
        }
      }
      return true;
    }).toList();

    // Eğer Yakınımdaki Mekanları Ara (NEARBY) aktifse mesafeye göre yakından uzağa sırala (Konum Öncelikli)
    if (isNearbyPriority) {
      results.sort(
        (a, b) => a.distanceKmFromUser.compareTo(b.distanceKmFromUser),
      );
    }

    return results;
  }

  /// Mekanın geçtiği yayınlanmış (`PUBLISHED`) rotaları getirir
  List<PublishedRouteFeedItem> getRelatedRoutesForPlace(
    PlaceDiscoveryItem place,
  ) {
    final allRoutes = _routesRepository.getFilteredFeedRoutes(
      continent: ContinentFilter.global,
      selectedCountryCodes: const {},
    );
    return allRoutes
        .where((route) => place.relatedRouteIds.contains(route.id))
        .toList();
  }

  /// Mekan kartının altındaki slider için benzer lokasyonları getirir
  /// (Önce aynı kategori veya ülkedeki mekanlar, ardından diğer popüler lokasyonlar)
  List<PlaceDiscoveryItem> getSimilarPlacesForPlace(PlaceDiscoveryItem place) {
    final others = _places.where((p) => p.id != place.id).toList();
    others.sort((a, b) {
      int score(PlaceDiscoveryItem candidate) {
        int s = 0;
        if (candidate.uiCategory == place.uiCategory) s -= 2;
        if (candidate.countryCode == place.countryCode) s -= 1;
        return s;
      }

      return score(a).compareTo(score(b));
    });
    return others;
  }

  /// Google Haritalar fallback (`POST /places/fetch-google`) simülasyonu
  PlaceDiscoveryItem createPlaceFromGoogleFallback({
    required String query,
    required ContinentFilter activeContinent,
  }) {
    final cleanName = query.trim();
    final continent = activeContinent == ContinentFilter.global
        ? ContinentFilter.europe
        : activeContinent;

    final newPlace = PlaceDiscoveryItem(
      id: 'place-google-${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      shortSummary:
          'Google Haritalar (Places API) üzerinden anlık olarak çekilip Been Here veritabanına çoklu dil desteğiyle kaydedilen yeni keşif noktası.',
      continent: continent,
      countryCode: 'TR',
      countryName: 'Türkiye',
      city: 'Keşif Noktası',
      uiCategory: 'DESTINATION',
      categoryLabel: 'Google Places Kaydı',
      averageRating: 4.7,
      verifiedVisitCount: 1,
      distanceKmFromUser: 4.5,
      photoUrls: const [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=900&q=80',
      ],
      communityVibes: const [
        'Yeni Keşif',
        'Google Places',
        'Gezgin Önerisi',
      ],
      warnings: const [],
      relatedRouteIds: const ['route-tr-marmaris-00'],
      isFromGoogleFallback: true,
    );

    _places.insert(0, newPlace);
    return newPlace;
  }
}
