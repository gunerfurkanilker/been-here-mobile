import 'json_parsing_utils.dart';

enum ContinentFilter {
  global('GLOBAL', '🌍 Global'),
  europe('EUROPE', '🇪🇺 Avrupa'),
  asia('ASIA', '🌏 Asya'),
  northAmerica('NORTH_AMERICA', '🌎 Kuzey Amerika'),
  southAmerica('SOUTH_AMERICA', '🌎 Güney Amerika'),
  africa('AFRICA', '🌍 Afrika'),
  oceania('OCEANIA', '🌏 Okyanusya');

  const ContinentFilter(this.code, this.label);
  final String code;
  final String label;

  /// Backend kıta kodundan (`EUROPE`, `ASIA`, `NORTH_AMERICA` vb.) enum döndürür.
  static ContinentFilter fromCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) {
      return ContinentFilter.global;
    }
    for (final value in ContinentFilter.values) {
      if (value.code == normalized) {
        return value;
      }
    }
    return ContinentFilter.global;
  }
}

class CountryFilterOption {
  const CountryFilterOption({
    required this.code,
    required this.nameTr,
    required this.flagEmoji,
    required this.continent,
    required this.publishedRouteCount,
  });

  final String code;
  final String nameTr;
  final String flagEmoji;
  final ContinentFilter continent;
  final int publishedRouteCount;
}

class RouteStopDetailItem {
  const RouteStopDetailItem({
    required this.id,
    required this.orderIndex,
    required this.dayNumber,
    required this.placeName,
    required this.city,
    required this.uiCategory,
    required this.verificationType,
    required this.rating,
    required this.comment,
    required this.vibes,
    required this.warnings,
    required this.photoUrls,
  });

  final String id;
  final int orderIndex;
  final int dayNumber;
  final String placeName;
  final String city;
  final String uiCategory;
  final String verificationType; // GEO_VERIFIED | PHOTO_VERIFIED | MANUAL
  final int rating;
  final String comment;
  final List<String> vibes;
  final List<String> warnings;
  final List<String> photoUrls;
}

class RouteStayDetailItem {
  const RouteStayDetailItem({
    required this.stayTypeLabel,
    required this.regionOrHotelName,
    required this.nightsCount,
  });

  final String stayTypeLabel;
  final String regionOrHotelName;
  final int nightsCount;
}

class RouteQuestionItem {
  const RouteQuestionItem({
    required this.id,
    required this.askerUsername,
    required this.questionText,
    required this.createdAtLabel,
    this.answerText,
  });

  final String id;
  final String askerUsername;
  final String questionText;
  final String createdAtLabel;
  final String? answerText;
}

class PublishedRouteFeedItem {
  const PublishedRouteFeedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.authorUsername,
    required this.authorDisplayName,
    required this.authorRankLabel,
    required this.continent,
    required this.countryCodes,
    required this.countryNames,
    required this.cities,
    required this.featuredMediaUrls,
    required this.previewPlaceNames,
    required this.dateRangeText,
    required this.adultsCount,
    required this.childrenCount,
    required this.durationDays,
    required this.estimatedBudgetUsd,
    required this.estimatedBudgetLocal,
    required this.localCurrencySymbol,
    required this.budgetBreakdown,
    required this.forkCount,
    required this.isBoosted,
    required this.isQaEnabled,
    required this.stops,
    required this.stays,
    required this.questions,
    this.totalStopsCount,
  });

  /// Backend (`GET /places/:id/routes` vb.) JSON yanıtından güvenli şekilde model üretir.
  factory PublishedRouteFeedItem.fromJson(Map<String, dynamic> json) {
    final authorMap = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : (json['creator'] is Map<String, dynamic>
            ? json['creator'] as Map<String, dynamic>
            : null);

    final rawCountryCodes = parseJsonStringList(
      json['country_codes'] ?? json['countries'],
    );
    final rawCountryNames = parseJsonStringList(json['country_names']);
    final resolvedCountryNames =
        rawCountryNames.isNotEmpty ? rawCountryNames : rawCountryCodes;

    final rawStops = json['stops'];
    final parsedStops = rawStops is List
        ? rawStops
            .whereType<Map<String, dynamic>>()
            .map(_routeStopFromJson)
            .toList(growable: false)
        : const <RouteStopDetailItem>[];

    final rawStays = json['stays'];
    final parsedStays = rawStays is List
        ? rawStays
            .whereType<Map<String, dynamic>>()
            .map(_routeStayFromJson)
            .toList(growable: false)
        : const <RouteStayDetailItem>[];

    final rawQuestions = json['questions'];
    final parsedQuestions = rawQuestions is List
        ? rawQuestions
            .whereType<Map<String, dynamic>>()
            .map(_routeQuestionFromJson)
            .toList(growable: false)
        : const <RouteQuestionItem>[];

    final totalStops = json.containsKey('total_stops_count') &&
            json['total_stops_count'] != null
        ? parseJsonInt(json['total_stops_count'])
        : null;

    final rawAuthorUsername =
        json['author_username']?.toString() ??
        authorMap?['username']?.toString() ??
        '';
    final rawAuthorDisplayName =
        json['author_display_name']?.toString() ??
        authorMap?['display_name']?.toString() ??
        '';
    final rawAuthorRank =
        json['author_rank_label']?.toString() ??
        authorMap?['rank_label']?.toString() ??
        '';

    final rawDateRange =
        json['date_range_text']?.toString() ??
        json['date_range_label']?.toString() ??
        json['flexible_period']?.toString() ??
        '';

    return PublishedRouteFeedItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      authorUsername:
          rawAuthorUsername.trim().isNotEmpty ? rawAuthorUsername : 'gezgin',
      authorDisplayName: rawAuthorDisplayName.trim().isNotEmpty
          ? rawAuthorDisplayName
          : 'Been Here Gezgini',
      authorRankLabel:
          rawAuthorRank.trim().isNotEmpty ? rawAuthorRank : 'Gezgin',
      continent: ContinentFilter.fromCode(json['continent']?.toString()),
      countryCodes: rawCountryCodes,
      countryNames: resolvedCountryNames,
      cities: parseJsonStringList(json['cities']),
      featuredMediaUrls: parseJsonStringList(json['featured_media_urls']),
      previewPlaceNames: parseJsonStringList(json['preview_place_names']),
      dateRangeText:
          rawDateRange.trim().isNotEmpty ? rawDateRange : 'Esnek Tarih',
      adultsCount: parseJsonInt(json['adults_count'], fallback: 1),
      childrenCount: parseJsonInt(json['children_count']),
      durationDays: parseJsonInt(json['duration_days'], fallback: 1),
      estimatedBudgetUsd: parseJsonDouble(
        json['estimated_total_budget_usd'] ?? json['estimated_budget_usd'],
      ),
      estimatedBudgetLocal: parseJsonDouble(
        json['estimated_total_budget'] ?? json['estimated_budget_local'],
      ),
      localCurrencySymbol: _resolveCurrencySymbol(
        json['local_currency_symbol']?.toString() ??
            json['currency']?.toString(),
      ),
      budgetBreakdown: parseJsonDoubleMap(json['budget_breakdown']),
      forkCount: parseJsonInt(json['fork_count']),
      isBoosted: parseJsonBool(json['is_boosted']),
      isQaEnabled: parseJsonBool(json['is_qa_enabled'], fallback: true),
      stops: parsedStops,
      stays: parsedStays,
      questions: parsedQuestions,
      totalStopsCount: totalStops,
    );
  }

  static RouteStopDetailItem _routeStopFromJson(Map<String, dynamic> json) {
    return RouteStopDetailItem(
      id: json['id']?.toString() ?? '',
      orderIndex: parseJsonInt(json['order_index']),
      dayNumber: parseJsonInt(json['day_number'], fallback: 1),
      placeName: json['place_name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      uiCategory: json['ui_category']?.toString() ?? 'DESTINATION',
      verificationType: json['verification_type']?.toString() ?? 'MANUAL',
      rating: parseJsonInt(json['rating'], fallback: 5),
      comment: json['comment']?.toString() ?? '',
      vibes: parseJsonStringList(json['vibes']),
      warnings: parseJsonStringList(json['warnings']),
      photoUrls: parseJsonStringList(json['photo_urls']),
    );
  }

  static RouteStayDetailItem _routeStayFromJson(Map<String, dynamic> json) {
    return RouteStayDetailItem(
      stayTypeLabel:
          json['stay_type_label']?.toString() ??
          json['stay_type']?.toString() ??
          'Konaklama',
      regionOrHotelName:
          json['region_or_hotel_name']?.toString() ??
          json['name']?.toString() ??
          '',
      nightsCount: parseJsonInt(json['nights_count'], fallback: 1),
    );
  }

  static RouteQuestionItem _routeQuestionFromJson(Map<String, dynamic> json) {
    return RouteQuestionItem(
      id: json['id']?.toString() ?? '',
      askerUsername: json['asker_username']?.toString() ?? 'gezgin',
      questionText: json['question_text']?.toString() ?? '',
      createdAtLabel:
          json['created_at_label']?.toString() ??
          json['created_at']?.toString() ??
          '',
      answerText: json['answer_text']?.toString(),
    );
  }

  static String _resolveCurrencySymbol(String? rawCurrency) {
    final code = rawCurrency?.trim().toUpperCase();
    switch (code) {
      case null:
      case '':
      case 'TRY':
        return '₺';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'CHF':
        return 'CHF';
      default:
        return rawCurrency!.trim();
    }
  }

  final String id;
  final String title;
  final String description;
  final String authorUsername;
  final String authorDisplayName;
  final String authorRankLabel;
  final ContinentFilter continent;
  final List<String> countryCodes;
  final List<String> countryNames;
  final List<String> cities;

  /// Anasayfa kartında üstteki slider için öne çıkarılan maksimum 5 görsel
  final List<String> featuredMediaUrls;

  /// Başlığın hemen altında Tag (Chip) olarak dizilen maksimum 7 mekan ismi
  final List<String> previewPlaceNames;

  final String dateRangeText;
  final int adultsCount;
  final int childrenCount;
  final int durationDays;
  final double estimatedBudgetUsd;
  final double estimatedBudgetLocal;
  final String localCurrencySymbol;
  final Map<String, double> budgetBreakdown;
  final int forkCount;
  final bool isBoosted;
  final bool isQaEnabled;
  final List<RouteStopDetailItem> stops;
  final List<RouteStayDetailItem> stays;
  final List<RouteQuestionItem> questions;
  final int? totalStopsCount;

  int get travelersCount => adultsCount + childrenCount;

  int get effectiveStopsCount => totalStopsCount ?? stops.length;

  List<String> get cappedFeaturedMedia =>
      featuredMediaUrls.take(5).toList(growable: false);

  List<String> get cappedPreviewPlaces =>
      previewPlaceNames.take(7).toList(growable: false);
}

enum RouteFilterPillType {
  continent,
  region,
  country,
  city,
  district,
  keyword,
}

class RouteFeedFilterPill {
  const RouteFeedFilterPill({
    required this.id,
    required this.type,
    required this.label,
    this.isEnabled = true,
    this.continent,
    this.regionId,
    this.countryCode,
    this.cityName,
    this.districtName,
    this.keyword,
  });

  final String id;
  final RouteFilterPillType type;
  final String label;
  final bool isEnabled;
  final ContinentFilter? continent;
  final String? regionId;
  final String? countryCode;
  final String? cityName;
  final String? districtName;
  final String? keyword;

  RouteFeedFilterPill copyWith({
    bool? isEnabled,
  }) {
    return RouteFeedFilterPill(
      id: id,
      type: type,
      label: label,
      isEnabled: isEnabled ?? this.isEnabled,
      continent: continent,
      regionId: regionId,
      countryCode: countryCode,
      cityName: cityName,
      districtName: districtName,
      keyword: keyword,
    );
  }
}

class RouteRegionCatalogItem {
  const RouteRegionCatalogItem({
    required this.id,
    required this.name,
    required this.continent,
    required this.countryCodes,
    required this.countryTags,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final ContinentFilter continent;
  final List<String> countryCodes;
  final List<String> countryTags;
  final String imageUrl;
}

class RouteContinentCatalogItem {
  const RouteContinentCatalogItem({
    required this.continent,
    required this.name,
    required this.imageUrl,
    required this.regions,
  });

  final ContinentFilter continent;
  final String name;
  final String imageUrl;
  final List<RouteRegionCatalogItem> regions;
}

enum RouteSearchSuggestionType {
  keyword,
  district,
  city,
  country,
  region,
  continent,
}

class RouteSearchSuggestion {
  const RouteSearchSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.pill,
  });

  final String id;
  final RouteSearchSuggestionType type;
  final String title;
  final String subtitle;
  final RouteFeedFilterPill pill;
}
