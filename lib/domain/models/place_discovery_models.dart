import 'json_parsing_utils.dart';
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

/// Mekan üzerindeki topluluk saha uyarısı rozeti (etiket + oy sayısı)
class PlaceWarningBadge {
  const PlaceWarningBadge({
    required this.label,
    required this.votes,
  });

  final String label;
  final int votes;

  factory PlaceWarningBadge.fromJson(Map<String, dynamic> json) {
    return PlaceWarningBadge(
      label: json['label']?.toString().trim() ?? '',
      votes: parseJsonInt(json['votes']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'label': label,
      'votes': votes,
    };
  }
}

/// Kullanıcının Sahibinden.com tarzı özel favori mekan listesi
class UserFavoritePlaceList {
  const UserFavoritePlaceList({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.placeIds,
    this.itemCount,
    this.maxPlacesPerList,
    this.createdAt,
  });

  final String id;
  final String title;
  final String iconEmoji;
  final List<String> placeIds;
  final int? itemCount;
  final int? maxPlacesPerList;
  final DateTime? createdAt;

  int get effectiveItemCount => itemCount ?? placeIds.length;

  bool containsPlace(String placeId) => placeIds.contains(placeId);

  factory UserFavoritePlaceList.fromJson(Map<String, dynamic> json) {
    final parsedPlaceIds = parseJsonStringList(json['place_ids']);
    final rawIcon = json['icon']?.toString().trim() ??
        json['icon_emoji']?.toString().trim();
    final parsedCount = json.containsKey('item_count') &&
            json['item_count'] != null
        ? parseJsonInt(json['item_count'])
        : parsedPlaceIds.length;

    return UserFavoritePlaceList(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Favori Listem',
      iconEmoji: (rawIcon != null && rawIcon.isNotEmpty) ? rawIcon : '🚩',
      placeIds: parsedPlaceIds,
      itemCount: parsedCount,
      maxPlacesPerList: json['max_places_per_list'] != null
          ? parseJsonInt(json['max_places_per_list'])
          : null,
      createdAt: parseJsonDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'icon': iconEmoji,
      'place_ids': placeIds,
      'item_count': effectiveItemCount,
      if (maxPlacesPerList != null) 'max_places_per_list': maxPlacesPerList,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  UserFavoritePlaceList copyWith({
    String? id,
    String? title,
    String? iconEmoji,
    List<String>? placeIds,
    int? itemCount,
    int? maxPlacesPerList,
    DateTime? createdAt,
  }) {
    return UserFavoritePlaceList(
      id: id ?? this.id,
      title: title ?? this.title,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      placeIds: placeIds ?? this.placeIds,
      itemCount: itemCount ?? this.itemCount,
      maxPlacesPerList: maxPlacesPerList ?? this.maxPlacesPerList,
      createdAt: createdAt ?? this.createdAt,
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
    this.district = '',
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
    this.photoAuthors = const <String>[],
    this.communityVibeCounts = const <String, int>{},
    this.isClosed = false,
    this.statusWarning,
    this.openingHoursWarning,
    this.communityWarningBadges = const <PlaceWarningBadge>[],
    this.isFlagged = false,
    this.flaggedInListIds = const <String>[],
  });

  final String id;
  final String name;
  final String shortSummary;
  final ContinentFilter continent;
  final String countryCode;
  final String countryName;
  final String city;
  final String district;
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

  /// Fotoğraflara karşılık gelen gezgin atıfları
  final List<String> photoAuthors;

  /// Topluluk vibe etiketlerinin oy sayıları
  final Map<String, int> communityVibeCounts;

  /// Mekanın kalıcı/geçici kapalı olup olmadığı
  final bool isClosed;

  /// Kalıcı veya geçici kapanma uyarısı
  final String? statusWarning;

  /// Kapalı günler / çalışma saati uyarısı
  final String? openingHoursWarning;

  /// Topluluk tarafından bildirilen saha uyarı rozetleri
  final List<PlaceWarningBadge> communityWarningBadges;

  /// Kullanıcının en az bir favori listesinde bayraklı olup olmadığı
  final bool isFlagged;

  /// Mekanın dahil olduğu kullanıcı favori liste ID'leri
  final List<String> flaggedInListIds;

  /// Konum mesafesi bilgisi mevcutsa true
  bool get hasDistance => distanceKmFromUser > 0;

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
    if (photoIndex >= 0 && photoIndex < photoAuthors.length) {
      final explicit = photoAuthors[photoIndex].trim();
      if (explicit.isNotEmpty) {
        return explicit;
      }
    }
    if (photoAuthors.isNotEmpty) {
      final wrapped =
          photoAuthors[photoIndex.abs() % photoAuthors.length].trim();
      if (wrapped.isNotEmpty) {
        return wrapped;
      }
    }
    final seed = id.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final idx = (seed + photoIndex) % _defaultTravelerAuthors.length;
    return _defaultTravelerAuthors[idx];
  }

  /// Backend enriched veya raw `Place` JSON yanıtından güvenli şekilde model üretir.
  factory PlaceDiscoveryItem.fromJson(Map<String, dynamic> json) {
    final resolvedName = _extractPlaceName(json);
    final resolvedCategory =
        (json['ui_category']?.toString().trim().toUpperCase() ?? '')
                .isNotEmpty
            ? json['ui_category'].toString().trim().toUpperCase()
            : 'DESTINATION';
    final rawCategoryLabel = json['category_label']?.toString().trim();
    final resolvedCategoryLabel =
        (rawCategoryLabel != null && rawCategoryLabel.isNotEmpty)
            ? rawCategoryLabel
            : _defaultCategoryLabel(resolvedCategory);

    final rawMediaGallery = json['media_gallery'];
    final galleryEntries = rawMediaGallery is List
        ? rawMediaGallery.whereType<Map<String, dynamic>>().toList(growable: false)
        : const <Map<String, dynamic>>[];

    final directPhotos = parseJsonStringList(json['photo_urls']);
    final resolvedPhotos = directPhotos.isNotEmpty
        ? directPhotos
        : galleryEntries
            .map((entry) => entry['url']?.toString().trim() ?? '')
            .where((url) => url.isNotEmpty)
            .toList(growable: false);

    final resolvedAuthors = _extractPhotoAuthors(
      rawPhotoAuthors: json['photo_authors'],
      galleryEntries: galleryEntries,
    );

    final vibeParsed = _parseCommunityVibes(
      rawVibes: json['community_vibes'],
      rawCounts: json['community_vibe_counts'],
    );

    final warningState = _parseWarningsState(
      json: json,
      placeName: resolvedName,
    );

    final parsedFlaggedListIds =
        parseJsonStringList(json['flagged_in_list_ids']);
    final parsedIsFlagged = json.containsKey('is_flagged')
        ? parseJsonBool(json['is_flagged'])
        : parsedFlaggedListIds.isNotEmpty;

    final rawCountryCode =
        json['country_code']?.toString().trim().toUpperCase() ?? '';
    final rawCountryName = json['country_name']?.toString().trim();

    return PlaceDiscoveryItem(
      id: json['id']?.toString() ?? '',
      name: resolvedName,
      shortSummary: json['short_summary']?.toString() ?? '',
      continent: ContinentFilter.fromCode(json['continent']?.toString()),
      countryCode: rawCountryCode,
      countryName: (rawCountryName != null && rawCountryName.isNotEmpty)
          ? rawCountryName
          : rawCountryCode,
      city: json['city']?.toString().trim() ?? '',
      district: json['district']?.toString().trim() ?? '',
      uiCategory: resolvedCategory,
      categoryLabel: resolvedCategoryLabel,
      averageRating: parseJsonDouble(json['average_rating']),
      verifiedVisitCount: parseJsonInt(json['verified_visit_count']),
      distanceKmFromUser: json['distance_km'] == null
          ? 0.0
          : parseJsonDouble(json['distance_km']),
      photoUrls: resolvedPhotos,
      communityVibes: vibeParsed.vibes,
      warnings: warningState.warnings,
      relatedRouteIds: parseJsonStringList(json['related_route_ids']),
      isFromGoogleFallback: parseJsonBool(json['is_from_google_fallback']),
      photoAuthors: resolvedAuthors,
      communityVibeCounts: vibeParsed.counts,
      isClosed: warningState.isClosed,
      statusWarning: warningState.statusWarning,
      openingHoursWarning: warningState.openingHoursWarning,
      communityWarningBadges: warningState.badges,
      isFlagged: parsedIsFlagged,
      flaggedInListIds: parsedFlaggedListIds,
    );
  }

  /// `POST /places/:id/vibes` veya `POST /places/:id/warnings` gibi raw `Place`
  /// dönen yanıtları mevcut zenginleştirilmiş kart alanlarını koruyarak birleştirir.
  PlaceDiscoveryItem mergeRawPlaceJson(Map<String, dynamic> rawPlaceJson) {
    final merged = <String, dynamic>{
      ...toJson(),
      ...rawPlaceJson,
    };

    // Raw Place dönen endpointler zenginleştirilmiş kıta/ülke/mesafe/bayrak
    // alanlarını içermiyorsa mevcut değerleri koru.
    if (!rawPlaceJson.containsKey('continent')) {
      merged['continent'] = continent.code;
    }
    if (!rawPlaceJson.containsKey('country_name')) {
      merged['country_name'] = countryName;
    }
    if (!rawPlaceJson.containsKey('district')) {
      merged['district'] = district;
    }
    if (!rawPlaceJson.containsKey('distance_km')) {
      merged['distance_km'] = distanceKmFromUser > 0 ? distanceKmFromUser : null;
    }
    if (!rawPlaceJson.containsKey('related_route_ids')) {
      merged['related_route_ids'] = relatedRouteIds;
    }
    if (!rawPlaceJson.containsKey('is_flagged')) {
      merged['is_flagged'] = isFlagged;
    }
    if (!rawPlaceJson.containsKey('flagged_in_list_ids')) {
      merged['flagged_in_list_ids'] = flaggedInListIds;
    }
    if (!rawPlaceJson.containsKey('category_label')) {
      merged['category_label'] = categoryLabel;
    }
    if (!rawPlaceJson.containsKey('photo_authors') &&
        !rawPlaceJson.containsKey('media_gallery')) {
      merged['photo_authors'] = photoAuthors;
    }
    // Raw yanıt güncel `status` / `opening_hours` / `community_warnings`
    // içeriyorsa eski `warnings` önbelleğinin üzerine yazmasını engelle.
    if (!rawPlaceJson.containsKey('warnings') &&
        (rawPlaceJson.containsKey('community_warnings') ||
            rawPlaceJson.containsKey('status') ||
            rawPlaceJson.containsKey('opening_hours'))) {
      merged.remove('warnings');
      merged.remove('community_warning_badges');
      merged.remove('status_warning');
      merged.remove('opening_hours_warning');
      merged.remove('is_closed');
    }
    if (!rawPlaceJson.containsKey('community_vibe_counts') &&
        rawPlaceJson['community_vibes'] is Map) {
      merged.remove('community_vibe_counts');
    }

    return PlaceDiscoveryItem.fromJson(merged).copyWith(
      isFromGoogleFallback: isFromGoogleFallback,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'short_summary': shortSummary,
      'continent': continent.code,
      'country_code': countryCode,
      'country_name': countryName,
      'city': city,
      'district': district,
      'ui_category': uiCategory,
      'category_label': categoryLabel,
      'average_rating': averageRating,
      'verified_visit_count': verifiedVisitCount,
      'distance_km': distanceKmFromUser > 0 ? distanceKmFromUser : null,
      'photo_urls': photoUrls,
      'photo_authors': photoAuthors,
      'community_vibes': communityVibeCounts.isNotEmpty
          ? communityVibeCounts
          : communityVibes,
      if (communityVibeCounts.isNotEmpty)
        'community_vibe_counts': communityVibeCounts,
      'warnings': warnings,
      'is_closed': isClosed,
      if (statusWarning != null) 'status_warning': statusWarning,
      if (openingHoursWarning != null)
        'opening_hours_warning': openingHoursWarning,
      'community_warning_badges':
          communityWarningBadges.map((b) => b.toJson()).toList(growable: false),
      'related_route_ids': relatedRouteIds,
      'is_flagged': isFlagged,
      'flagged_in_list_ids': flaggedInListIds,
      'is_from_google_fallback': isFromGoogleFallback,
    };
  }

  PlaceDiscoveryItem copyWith({
    String? id,
    String? name,
    String? shortSummary,
    ContinentFilter? continent,
    String? countryCode,
    String? countryName,
    String? city,
    String? district,
    String? uiCategory,
    String? categoryLabel,
    double? averageRating,
    int? verifiedVisitCount,
    double? distanceKmFromUser,
    List<String>? photoUrls,
    List<String>? communityVibes,
    List<String>? warnings,
    List<String>? relatedRouteIds,
    bool? isFromGoogleFallback,
    List<String>? photoAuthors,
    Map<String, int>? communityVibeCounts,
    bool? isClosed,
    String? statusWarning,
    String? openingHoursWarning,
    List<PlaceWarningBadge>? communityWarningBadges,
    bool? isFlagged,
    List<String>? flaggedInListIds,
  }) {
    return PlaceDiscoveryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      shortSummary: shortSummary ?? this.shortSummary,
      continent: continent ?? this.continent,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      city: city ?? this.city,
      district: district ?? this.district,
      uiCategory: uiCategory ?? this.uiCategory,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      averageRating: averageRating ?? this.averageRating,
      verifiedVisitCount: verifiedVisitCount ?? this.verifiedVisitCount,
      distanceKmFromUser: distanceKmFromUser ?? this.distanceKmFromUser,
      photoUrls: photoUrls ?? this.photoUrls,
      communityVibes: communityVibes ?? this.communityVibes,
      warnings: warnings ?? this.warnings,
      relatedRouteIds: relatedRouteIds ?? this.relatedRouteIds,
      isFromGoogleFallback: isFromGoogleFallback ?? this.isFromGoogleFallback,
      photoAuthors: photoAuthors ?? this.photoAuthors,
      communityVibeCounts: communityVibeCounts ?? this.communityVibeCounts,
      isClosed: isClosed ?? this.isClosed,
      statusWarning: statusWarning ?? this.statusWarning,
      openingHoursWarning: openingHoursWarning ?? this.openingHoursWarning,
      communityWarningBadges:
          communityWarningBadges ?? this.communityWarningBadges,
      isFlagged: isFlagged ?? this.isFlagged,
      flaggedInListIds: flaggedInListIds ?? this.flaggedInListIds,
    );
  }

  static String _extractPlaceName(Map<String, dynamic> json) {
    final direct = json['name']?.toString().trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final translations = json['name_translations'];
    if (translations is Map) {
      final tr = translations['tr']?.toString().trim();
      if (tr != null && tr.isNotEmpty) return tr;
      final en = translations['en']?.toString().trim();
      if (en != null && en.isNotEmpty) return en;
      for (final value in translations.values) {
        final candidate = value?.toString().trim();
        if (candidate != null && candidate.isNotEmpty) return candidate;
      }
    }
    return json['default_name']?.toString().trim() ?? '';
  }

  static String _defaultCategoryLabel(String uiCategory) {
    switch (uiCategory) {
      case 'FOOD':
        return 'Yeme & İçme';
      case 'STAY':
      case 'ACCOMMODATION':
        return 'Konaklama';
      case 'ACTIVITY':
        return 'Aktivite & Deneyim';
      default:
        return 'Gezilecek Yer';
    }
  }

  static String _formatGalleryAuthor(Map<String, dynamic> item) {
    final displayName = item['author_display_name']?.toString().trim();
    final username = item['author_username']?.toString().trim();
    final hasDisplay = displayName != null && displayName.isNotEmpty;
    final hasUsername = username != null && username.isNotEmpty;
    if (hasDisplay && hasUsername) {
      return '$displayName (@$username)';
    }
    if (hasDisplay) return displayName;
    if (hasUsername) return '@$username';
    return '';
  }

  static List<String> _extractPhotoAuthors({
    required dynamic rawPhotoAuthors,
    required List<Map<String, dynamic>> galleryEntries,
  }) {
    final galleryAuthors = galleryEntries
        .map(_formatGalleryAuthor)
        .toList(growable: false);

    if (rawPhotoAuthors is List) {
      final combined = <String>[];
      var hasAnyAuthor = false;
      for (var i = 0; i < rawPhotoAuthors.length; i++) {
        final explicit = rawPhotoAuthors[i]?.toString().trim() ?? '';
        final fallbackFromGallery =
            i < galleryAuthors.length ? galleryAuthors[i] : '';
        final resolved = explicit.isNotEmpty ? explicit : fallbackFromGallery;
        if (resolved.isNotEmpty) {
          hasAnyAuthor = true;
        }
        combined.add(resolved);
      }
      if (hasAnyAuthor) {
        return List<String>.unmodifiable(combined);
      }
    }

    if (galleryAuthors.any((author) => author.isNotEmpty)) {
      return List<String>.unmodifiable(galleryAuthors);
    }
    return const <String>[];
  }

  static ({List<String> vibes, Map<String, int> counts}) _parseCommunityVibes({
    required dynamic rawVibes,
    required dynamic rawCounts,
  }) {
    if (rawVibes is Map) {
      final counts = parseJsonIntMap(rawVibes);
      final sortedEntries = counts.entries.toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));
      final vibes = sortedEntries
          .where((entry) => entry.value > 0 || sortedEntries.length <= 3)
          .map((entry) => entry.key)
          .toList(growable: false);
      return (
        vibes: List<String>.unmodifiable(vibes),
        counts: counts,
      );
    }

    final vibeList = parseJsonStringList(rawVibes);
    final counts = parseJsonIntMap(rawCounts);
    return (
      vibes: List<String>.unmodifiable(vibeList),
      counts: counts,
    );
  }

  static ({
    bool isClosed,
    String? statusWarning,
    String? openingHoursWarning,
    List<PlaceWarningBadge> badges,
    List<String> warnings,
  }) _parseWarningsState({
    required Map<String, dynamic> json,
    required String placeName,
  }) {
    final rawBadges = json['community_warning_badges'];
    List<PlaceWarningBadge> badges;
    if (rawBadges is List) {
      badges = rawBadges
          .whereType<Map<String, dynamic>>()
          .map(PlaceWarningBadge.fromJson)
          .where((badge) => badge.label.isNotEmpty)
          .toList(growable: false);
    } else if (json['community_warnings'] is Map) {
      final map = parseJsonIntMap(json['community_warnings']);
      final entries = map.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      badges = entries
          .map((e) => PlaceWarningBadge(label: e.key, votes: e.value))
          .toList(growable: false);
    } else {
      badges = const <PlaceWarningBadge>[];
    }

    final statusStr = json['status']?.toString().trim().toUpperCase();
    final isClosed = json.containsKey('is_closed')
        ? parseJsonBool(json['is_closed'])
        : (statusStr == 'CLOSED_PERMANENTLY' ||
            statusStr == 'CLOSED_TEMPORARILY');

    String? statusWarning = json['status_warning']?.toString().trim();
    if (statusWarning == null || statusWarning.isEmpty) {
      if (statusStr == 'CLOSED_PERMANENTLY') {
        statusWarning = '$placeName kalıcı olarak kapanmıştır.';
      } else if (statusStr == 'CLOSED_TEMPORARILY') {
        statusWarning = '$placeName geçici olarak kapalıdır.';
      } else {
        statusWarning = null;
      }
    }

    String? openingHoursWarning =
        json['opening_hours_warning']?.toString().trim();
    if (openingHoursWarning == null || openingHoursWarning.isEmpty) {
      final openingHours = json['opening_hours'];
      if (openingHours is Map) {
        final closedDays = parseJsonStringList(openingHours['closed_days']);
        if (closedDays.isNotEmpty) {
          openingHoursWarning =
              '$placeName ${closedDays.join(', ')} günleri kapalıdır.';
        } else {
          openingHoursWarning = null;
        }
      } else {
        openingHoursWarning = null;
      }
    }

    List<String> warnings;
    if (json['warnings'] is List) {
      warnings = parseJsonStringList(json['warnings']);
    } else {
      final generated = <String>[
        ?statusWarning,
        ?openingHoursWarning,
        if (badges.isNotEmpty)
          'Gezgin Saha Uyarısı: ${badges.take(3).map((b) => '${b.label} (${b.votes} oy)').join(', ')}',
      ];
      warnings = List<String>.unmodifiable(generated);
    }

    return (
      isClosed: isClosed,
      statusWarning: statusWarning,
      openingHoursWarning: openingHoursWarning,
      badges: List<PlaceWarningBadge>.unmodifiable(badges),
      warnings: warnings,
    );
  }
}

/// `GET /places/feed` yanıt modeli
class PlaceFeedResponse {
  const PlaceFeedResponse({
    required this.page,
    required this.limit,
    required this.seed,
    required this.hasMore,
    required this.prioritizedCategories,
    required this.items,
    required this.count,
    int? totalCount,
  }) : totalCount = totalCount ?? count;

  final int page;
  final int limit;
  final String seed;
  final bool hasMore;
  final List<String> prioritizedCategories;
  final List<PlaceDiscoveryItem> items;
  final int count;
  final int totalCount;

  factory PlaceFeedResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PlaceDiscoveryItem.fromJson)
            .toList(growable: false)
        : const <PlaceDiscoveryItem>[];

    return PlaceFeedResponse(
      page: parseJsonInt(json['page'], fallback: 1),
      limit: parseJsonInt(json['limit'], fallback: 20),
      seed: json['seed']?.toString() ?? '',
      hasMore: parseJsonBool(json['has_more']),
      prioritizedCategories:
          parseJsonStringList(json['prioritized_categories']),
      items: items,
      count: json.containsKey('count')
          ? parseJsonInt(json['count'])
          : items.length,
      totalCount: json.containsKey('total_count')
          ? parseJsonInt(json['total_count'])
          : (json.containsKey('count')
              ? parseJsonInt(json['count'])
              : items.length),
    );
  }
}

/// `GET /places/search` yanıt modeli
class PlaceSearchResponse {
  const PlaceSearchResponse({
    required this.searchMode,
    required this.items,
    required this.count,
    int? totalCount,
    required this.canFetchFromGoogle,
    required this.minGoogleQueryLength,
    required this.googleFetchPrompt,
  }) : totalCount = totalCount ?? count;

  final String searchMode;
  final List<PlaceDiscoveryItem> items;
  final int count;
  final int totalCount;
  final bool canFetchFromGoogle;
  final int minGoogleQueryLength;
  final String googleFetchPrompt;

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PlaceDiscoveryItem.fromJson)
            .toList(growable: false)
        : const <PlaceDiscoveryItem>[];

    final prompt = json['google_fetch_prompt']?.toString().trim();

    return PlaceSearchResponse(
      searchMode: json['search_mode']?.toString() ?? 'GLOBAL',
      items: items,
      count: json.containsKey('count')
          ? parseJsonInt(json['count'])
          : items.length,
      totalCount: json.containsKey('total_count')
          ? parseJsonInt(json['total_count'])
          : (json.containsKey('count')
              ? parseJsonInt(json['count'])
              : items.length),
      canFetchFromGoogle: parseJsonBool(json['can_fetch_from_google']),
      minGoogleQueryLength:
          parseJsonInt(json['min_google_query_length'], fallback: 3),
      googleFetchPrompt: (prompt != null && prompt.isNotEmpty)
          ? prompt
          : "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara",
    );
  }
}

/// `GET /places/:id/nearby` yanıt modeli
class PlaceNearbyResponse {
  const PlaceNearbyResponse({
    required this.basePlaceId,
    required this.uiCategory,
    required this.radiusMeters,
    required this.items,
    required this.count,
    required this.canFetchFromGoogle,
  });

  final String basePlaceId;
  final String uiCategory;
  final int radiusMeters;
  final List<PlaceDiscoveryItem> items;
  final int count;
  final bool canFetchFromGoogle;

  factory PlaceNearbyResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PlaceDiscoveryItem.fromJson)
            .toList(growable: false)
        : const <PlaceDiscoveryItem>[];

    return PlaceNearbyResponse(
      basePlaceId: json['base_place_id']?.toString() ?? '',
      uiCategory: json['ui_category']?.toString() ?? 'DESTINATION',
      radiusMeters: parseJsonInt(json['radius_meters'], fallback: 3000),
      items: items,
      count: json.containsKey('count')
          ? parseJsonInt(json['count'])
          : items.length,
      canFetchFromGoogle: parseJsonBool(json['can_fetch_from_google']),
    );
  }
}

/// `GET /places/:id/routes` yanıt modeli
class PlaceRelatedRoutesResponse {
  const PlaceRelatedRoutesResponse({
    required this.placeId,
    required this.page,
    required this.limit,
    required this.hasMore,
    required this.items,
    required this.count,
  });

  final String placeId;
  final int page;
  final int limit;
  final bool hasMore;
  final List<PublishedRouteFeedItem> items;
  final int count;

  factory PlaceRelatedRoutesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PublishedRouteFeedItem.fromJson)
            .toList(growable: false)
        : const <PublishedRouteFeedItem>[];

    return PlaceRelatedRoutesResponse(
      placeId: json['place_id']?.toString() ?? '',
      page: parseJsonInt(json['page'], fallback: 1),
      limit: parseJsonInt(json['limit'], fallback: 10),
      hasMore: parseJsonBool(json['has_more']),
      items: items,
      count: json.containsKey('count')
          ? parseJsonInt(json['count'])
          : items.length,
    );
  }
}

/// Kullanıcı favori liste kota bilgisi (`Free: 3 liste / 10 mekan`, `Premium: null`)
class PlaceListsQuota {
  const PlaceListsQuota({
    required this.isPremium,
    required this.maxLists,
    required this.maxPlacesPerList,
  });

  final bool isPremium;
  final int? maxLists;
  final int? maxPlacesPerList;

  factory PlaceListsQuota.fromJson(Map<String, dynamic> json) {
    return PlaceListsQuota(
      isPremium: parseJsonBool(json['is_premium']),
      maxLists:
          json['max_lists'] != null ? parseJsonInt(json['max_lists']) : null,
      maxPlacesPerList: json['max_places_per_list'] != null
          ? parseJsonInt(json['max_places_per_list'])
          : null,
    );
  }
}

/// `GET /places/lists/me` yanıt modeli
class PlaceListsResponse {
  const PlaceListsResponse({
    required this.items,
    required this.count,
    required this.suggestedNextTitle,
    required this.quota,
  });

  final List<UserFavoritePlaceList> items;
  final int count;
  final String suggestedNextTitle;
  final PlaceListsQuota quota;

  factory PlaceListsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(UserFavoritePlaceList.fromJson)
            .toList(growable: false)
        : const <UserFavoritePlaceList>[];

    final suggested = json['suggested_next_title']?.toString().trim();
    final quotaMap = json['quota'];

    return PlaceListsResponse(
      items: items,
      count: json.containsKey('count')
          ? parseJsonInt(json['count'])
          : items.length,
      suggestedNextTitle: (suggested != null && suggested.isNotEmpty)
          ? suggested
          : 'Favori Liste ${items.length + 1}',
      quota: quotaMap is Map<String, dynamic>
          ? PlaceListsQuota.fromJson(quotaMap)
          : const PlaceListsQuota(
              isPremium: false,
              maxLists: 3,
              maxPlacesPerList: 10,
            ),
    );
  }
}

/// `GET /places/lists/:listId` içindeki mekan öğesi
class PlaceListDetailItem {
  const PlaceListDetailItem({
    required this.id,
    required this.listId,
    required this.placeId,
    this.note,
    this.createdAt,
    this.place,
  });

  final String id;
  final String listId;
  final String placeId;
  final String? note;
  final DateTime? createdAt;
  final PlaceDiscoveryItem? place;

  factory PlaceListDetailItem.fromJson(Map<String, dynamic> json) {
    final rawPlace = json['place'];
    return PlaceListDetailItem(
      id: json['id']?.toString() ?? '',
      listId: json['list_id']?.toString() ?? '',
      placeId: json['place_id']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: parseJsonDateTime(json['created_at']),
      place: rawPlace is Map<String, dynamic>
          ? PlaceDiscoveryItem.fromJson(rawPlace)
          : null,
    );
  }
}

/// `GET /places/lists/:listId` yanıt modeli
class PlaceListDetailResponse {
  const PlaceListDetailResponse({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.items,
    required this.itemCount,
    this.createdAt,
  });

  final String id;
  final String title;
  final String iconEmoji;
  final List<PlaceListDetailItem> items;
  final int itemCount;
  final DateTime? createdAt;

  factory PlaceListDetailResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PlaceListDetailItem.fromJson)
            .toList(growable: false)
        : const <PlaceListDetailItem>[];
    final rawIcon = json['icon']?.toString().trim() ??
        json['icon_emoji']?.toString().trim();

    return PlaceListDetailResponse(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Favori Listem',
      iconEmoji: (rawIcon != null && rawIcon.isNotEmpty) ? rawIcon : '🚩',
      items: items,
      itemCount: json.containsKey('item_count')
          ? parseJsonInt(json['item_count'])
          : items.length,
      createdAt: parseJsonDateTime(json['created_at']),
    );
  }

  UserFavoritePlaceList toSummaryList({int? maxPlacesPerList}) {
    return UserFavoritePlaceList(
      id: id,
      title: title,
      iconEmoji: iconEmoji,
      placeIds: items.map((item) => item.placeId).toList(growable: false),
      itemCount: itemCount,
      maxPlacesPerList: maxPlacesPerList,
      createdAt: createdAt,
    );
  }
}
