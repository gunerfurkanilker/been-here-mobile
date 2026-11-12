enum ContinentFilter {
  global('GLOBAL', '🌍 Global'),
  europe('EUROPE', '🇪🇺 Avrupa'),
  asia('ASIA', '🌏 Asya'),
  northAmerica('NORTH_AMERICA', '🌎 Kuzey Amerika'),
  southAmerica('SOUTH_AMERICA', '🌎 Güney Amerika');

  const ContinentFilter(this.code, this.label);
  final String code;
  final String label;
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
  });

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

  int get travelersCount => adultsCount + childrenCount;

  List<String> get cappedFeaturedMedia =>
      featuredMediaUrls.take(5).toList(growable: false);

  List<String> get cappedPreviewPlaces =>
      previewPlaceNames.take(7).toList(growable: false);
}
