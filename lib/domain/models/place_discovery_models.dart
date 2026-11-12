import 'route_feed_models.dart';

/// Arama ekranındaki aktif keşif/arama modu
enum PlaceSearchMode {
  /// İlk açılış vitrini: Tercih öncelikli + rastgele mekanlar
  showcase,

  /// Yakınımdaki Mekanları Ara (Konum bazlı ST_DWithin simülasyonu)
  nearby,

  /// Konum Bağımsız Genel Arama (Text & filtre bazlı)
  globalSearch,
}

/// Kullanıcının Sahibinden.com tarzı özel favori mekan listesi
class UserFavoritePlaceList {
  const UserFavoritePlaceList({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.placeIds,
  });

  final String id;
  final String title;
  final String iconEmoji;
  final List<String> placeIds;

  bool containsPlace(String placeId) => placeIds.contains(placeId);

  UserFavoritePlaceList copyWith({
    String? id,
    String? title,
    String? iconEmoji,
    List<String>? placeIds,
  }) {
    return UserFavoritePlaceList(
      id: id ?? this.id,
      title: title ?? this.title,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      placeIds: placeIds ?? this.placeIds,
    );
  }
}

/// Kullanıcının mekan ekleyebileceği Taslak (DRAFT) veya Anı (MEMORY) rotası
class UserEditableRouteOption {
  const UserEditableRouteOption({
    required this.id,
    required this.title,
    required this.routeTypeLabel,
    required this.isDraft,
    required this.placeIds,
  });

  final String id;
  final String title;
  final String routeTypeLabel; // "Taslak Rota" | "Anı Rotası"
  final bool isDraft;
  final List<String> placeIds;

  bool containsPlace(String placeId) => placeIds.contains(placeId);

  UserEditableRouteOption copyWith({
    String? id,
    String? title,
    String? routeTypeLabel,
    bool? isDraft,
    List<String>? placeIds,
  }) {
    return UserEditableRouteOption(
      id: id ?? this.id,
      title: title ?? this.title,
      routeTypeLabel: routeTypeLabel ?? this.routeTypeLabel,
      isDraft: isDraft ?? this.isDraft,
      placeIds: placeIds ?? this.placeIds,
    );
  }
}

/// Arama ve keşif vitrininde gösterilen Mekan (Place) modeli
class PlaceDiscoveryItem {
  const PlaceDiscoveryItem({
    required this.id,
    required this.name,
    required this.shortSummary,
    required this.continent,
    required this.countryCode,
    required this.countryName,
    required this.city,
    required this.uiCategory,
    required this.categoryLabel,
    required this.averageRating,
    required this.verifiedVisitCount,
    required this.distanceKmFromUser,
    required this.photoUrls,
    required this.communityVibes,
    required this.warnings,
    required this.relatedRouteIds,
    this.isFromGoogleFallback = false,
  });

  final String id;
  final String name;
  final String shortSummary;
  final ContinentFilter continent;
  final String countryCode;
  final String countryName;
  final String city;
  final String uiCategory; // DESTINATION | FOOD | STAY | ACTIVITY
  final String categoryLabel;
  final double averageRating;
  final int verifiedVisitCount;
  final double distanceKmFromUser;
  final List<String> photoUrls;
  final List<String> communityVibes;
  final List<String> warnings;

  /// Bu mekanın geçtiği yayınlanmış (`PUBLISHED`) rotaların ID listesi
  final List<String> relatedRouteIds;

  /// Google Haritalar fallback ile anlık eklendiyse true
  final bool isFromGoogleFallback;

  /// Mekan kartında maksimum 3 fotoğraf gösterilir
  List<String> get cappedPhotos =>
      photoUrls.take(3).toList(growable: false);

  static const List<String> _defaultTravelerAuthors = [
    'Selin Kaya (@selin_yolda)',
    'Kaan Demir (@kaan_geziyor)',
    'Zeynep Arslan (@zeynep_kesifte)',
    'Mert Aydın (@mert_ege)',
    'Elif Yılmaz (@elif_rotada)',
    'Can Özkan (@can_uzakdogu)',
  ];

  /// İlgili fotoğraf indeksinin hangi gezgine ait olduğunu döndürür
  String photoAuthorForIndex(int photoIndex) {
    final seed = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final idx = (seed + photoIndex) % _defaultTravelerAuthors.length;
    return _defaultTravelerAuthors[idx];
  }
}
