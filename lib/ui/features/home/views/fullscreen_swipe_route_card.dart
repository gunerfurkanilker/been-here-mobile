import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/route_feed_models.dart';

/// Alternatif 2: Tam Ekran Dikey Kaydırmalı (X / Reels Tarzı) Rota Kartı.
/// Mevcut `PublishedRouteCard` bileşeni korunurken bu bileşen yeni tam ekran akışta kullanılır.
class FullscreenSwipeRouteCard extends StatefulWidget {
  const FullscreenSwipeRouteCard({
    super.key,
    required this.route,
    required this.onTapCard,
  });

  final PublishedRouteFeedItem route;
  final VoidCallback onTapCard;

  @override
  State<FullscreenSwipeRouteCard> createState() =>
      _FullscreenSwipeRouteCardState();
}

class _FullscreenSwipeRouteCardState extends State<FullscreenSwipeRouteCard>
    with AutomaticKeepAliveClientMixin {
  late final PageController _stopsPageController;
  late List<_StopPreviewCardData> _cachedStopItems;

  @override
  bool get wantKeepAlive => true;

  static const Map<String, String> _flagByCountryCode = {
    'TR': '🇹🇷',
    'DE': '🇩🇪',
    'IT': '🇮🇹',
    'FR': '🇫🇷',
    'BE': '🇧🇪',
    'NL': '🇳🇱',
    'BG': '🇧🇬',
    'GR': '🇬🇷',
    'TH': '🇹🇭',
    'JP': '🇯🇵',
    'RU': '🇷🇺',
    'US': '🇺🇸',
    'CA': '🇨🇦',
    'BR': '🇧🇷',
    'AR': '🇦🇷',
  };

  @override
  void initState() {
    super.initState();
    // 1. sıradaki mekan kartı ~%74 genişlik kaplar, sıradaki kart sağdan ~%26 görünür
    _stopsPageController = PageController(viewportFraction: 0.74);
    _cachedStopItems = _buildStopPreviewItems(widget.route);
  }

  @override
  void didUpdateWidget(covariant FullscreenSwipeRouteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id) {
      _cachedStopItems = _buildStopPreviewItems(widget.route);
    }
  }

  @override
  void dispose() {
    _stopsPageController.dispose();
    super.dispose();
  }

  /// Şehir veya mekan adına göre "İl, Ülke" (Örn: "Fethiye, Türkiye" veya "Berlin, Almanya") döndürür.
  String _resolveCityAndCountryLabel({
    required PublishedRouteFeedItem route,
    String? rawCity,
    required String placeName,
    required int fallbackIndex,
  }) {
    final defaultCountry =
        route.countryNames.isNotEmpty ? route.countryNames.first : 'Türkiye';
    final defaultCity = route.cities.isNotEmpty
        ? route.cities[fallbackIndex % route.cities.length]
        : '';

    final city = (rawCity != null && rawCity.trim().isNotEmpty)
        ? rawCity.split('/').first.trim()
        : _inferCityFromPlaceName(placeName, route.cities, defaultCity);

    final country = _inferCountryFromCity(city, route, defaultCountry);
    if (city.isEmpty) return country;
    return '$city, $country';
  }

  String _inferCityFromPlaceName(
    String placeName,
    List<String> routeCities,
    String fallbackCity,
  ) {
    final lower = placeName.toLowerCase();
    for (final c in routeCities) {
      if (lower.contains(c.toLowerCase())) {
        return c;
      }
    }
    if (lower.contains('alaçatı')) return 'Çeşme';
    if (lower.contains('foça')) return 'Foça';
    if (lower.contains('urla')) return 'Urla';
    if (lower.contains('izmir')) return 'İzmir';
    if (lower.contains('marmaris') ||
        lower.contains('selimiye') ||
        lower.contains('bozburun') ||
        lower.contains('sedir')) {
      return 'Marmaris';
    }
    if (lower.contains('akyaka') || lower.contains('sakar')) return 'Muğla';
    if (lower.contains('köln')) return 'Köln';
    if (lower.contains('brüksel') ||
        lower.contains('grand place') ||
        lower.contains('dandoy')) {
      return 'Brüksel';
    }
    if (lower.contains('nice') || lower.contains('anglais')) return 'Nice';
    if (lower.contains('vernazza') || lower.contains('manarola')) {
      return 'Cinque Terre';
    }
    if (lower.contains('bellagio') || lower.contains('balbianello')) {
      return 'Como';
    }
    if (lower.contains('milano')) return 'Milano';
    if (lower.contains('chiang mai') || lower.contains('suthep')) {
      return 'Chiang Mai';
    }
    if (lower.contains('phuket') || lower.contains('phi phi')) return 'Phuket';
    return fallbackCity;
  }

  String _inferCountryFromCity(
    String city,
    PublishedRouteFeedItem route,
    String defaultCountry,
  ) {
    final lower = city.toLowerCase();
    if (lower.contains('brüksel') || lower.contains('brugge')) return 'Belçika';
    if (lower.contains('berlin') ||
        lower.contains('köln') ||
        lower.contains('münih')) {
      return 'Almanya';
    }
    if (lower.contains('nice') ||
        lower.contains('paris') ||
        lower.contains('lyon')) {
      return 'Fransa';
    }
    if (lower.contains('milano') ||
        lower.contains('como') ||
        lower.contains('cinque terre') ||
        lower.contains('roma')) {
      return 'İtalya';
    }
    if (lower.contains('bangkok') ||
        lower.contains('chiang mai') ||
        lower.contains('phuket')) {
      return 'Tayland';
    }
    return defaultCountry;
  }

  List<_StopPreviewCardData> _buildStopPreviewItems(
    PublishedRouteFeedItem route,
  ) {
    final media = route.cappedFeaturedMedia;
    final coverPhotoUrl = media.isNotEmpty ? media.first : '';
    final items = <_StopPreviewCardData>[];
    final addedNames = <String>{};

    for (var i = 0; i < route.stops.length; i++) {
      final stop = route.stops[i];
      String photoUrl = stop.photoUrls.isNotEmpty
          ? stop.photoUrls.first
          : (media.isNotEmpty ? media[(i + 1) % media.length] : '');
      if (photoUrl == coverPhotoUrl && media.length > 1) {
        photoUrl = media[(i + 1) % media.length];
      }
      items.add(
        _StopPreviewCardData(
          placeName: stop.placeName,
          locationSubtitle: _resolveCityAndCountryLabel(
            route: route,
            rawCity: stop.city,
            placeName: stop.placeName,
            fallbackIndex: i,
          ),
          imageUrl: photoUrl,
        ),
      );
      addedNames.add(stop.placeName);
    }

    for (var i = 0; i < route.cappedPreviewPlaces.length; i++) {
      final name = route.cappedPreviewPlaces[i];
      if (addedNames.contains(name)) continue;
      final photoUrl = media.length > 1
          ? media[1 + (items.length % (media.length - 1))]
          : (media.isNotEmpty ? media.first : '');
      items.add(
        _StopPreviewCardData(
          placeName: name,
          locationSubtitle: _resolveCityAndCountryLabel(
            route: route,
            placeName: name,
            fallbackIndex: items.length,
          ),
          imageUrl: photoUrl,
        ),
      );
      addedNames.add(name);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final route = widget.route;
    final stopItems = _cachedStopItems;
    final backgroundMedia = route.cappedFeaturedMedia;
    // Rotanın öne çıkarılan tek bir sabit kapak fotoğrafı vardır; alttaki mekan slider'ı bu resmi etkilemez
    final featuredCoverUrl = backgroundMedia.isNotEmpty
        ? backgroundMedia.first
        : (stopItems.isNotEmpty ? stopItems.first.imageUrl : '');

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTapCard,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ===============================================================
                // 1. ROTANIN ÖNE ÇIKARILAN SABİT KAPAK GÖRSELİ (Slider'dan etkilenmez)
                // ===============================================================
                Hero(
                  tag: 'route-hero-image-${route.id}',
                  child: SizedBox.expand(
                    child: Image.network(
                      featuredCoverUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 720,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1A2F49),
                                Color(0xFF0D1826),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              size: 56,
                              color: Colors.white38,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // ===============================================================
              // 2. ÜST VE ALT YUMUŞAK TINT / SHADE KATMANI
              // (Çok koyu değil, tamamen transparan da değil)
              // ===============================================================
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.14, 0.48, 0.70, 1.0],
                    colors: [
                      Color(0x70070D17), // Üst tint/shade
                      Color(0x00070D17), // Orta alan temiz
                      Color(0x00070D17),
                      Color(0x60070D17), // Alt başlangıç tint
                      Color(0xA2070D17), // Alt bitiş shade
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // 3. ÜST GEZGİN SATIRI: (◯) Gladius X   Elite Traveler (Kompakt Boyut)
              // ===============================================================
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        route.authorDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        route.authorRankLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // 4. ALT KISIM: Rota Başlığı + Ülkeler + %74/%26 Sonsuz Mekan Slider'ı
              // ===============================================================
              Positioned(
                left: 14,
                right: 0,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 4.1. Rota Başlığı (Küçültülmüş, zarif font)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        route.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.22,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 4.2. Ülkeler Satırı ([🇹🇷] Türkiye  [🇧🇬] Bulgaristan - Kompakt Boyut)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        children: [
                          for (int i = 0; i < route.countryNames.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    i < route.countryCodes.length
                                        ? (_flagByCountryCode[
                                                route.countryCodes[i]] ??
                                            '🌍')
                                        : '🌍',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  route.countryNames[i],
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 11),

                    // 4.3. Alttaki Mekan Slider'ı:
                    // - 1. sıradaki kart %74 genişlikte, sonraki kart sağdan %26 görünür
                    // - Sonsuz kaydırma (infinite scroll)
                    // - Mekan adının hemen altında "İl, Ülke" ("Fethiye, Türkiye" vb.) yazar
                    if (stopItems.isNotEmpty)
                      SizedBox(
                        height: 104,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: const {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: PageView.builder(
                            key: PageStorageKey<String>(
                              'stops-slider-${route.id}',
                            ),
                            controller: _stopsPageController,
                            padEnds: false,
                            itemBuilder: (context, rawIndex) {
                              final actualIndex = rawIndex % stopItems.length;
                              final stop = stopItems[actualIndex];

                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () {
                                    _stopsPageController.animateToPage(
                                      rawIndex,
                                      duration:
                                          const Duration(milliseconds: 260),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.32),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (stop.imageUrl.isNotEmpty)
                                          Image.network(
                                            stop.imageUrl,
                                            fit: BoxFit.cover,
                                            cacheWidth: 360,
                                            gaplessPlayback: true,
                                            filterQuality: FilterQuality.low,
                                            errorBuilder: (_, _, _) =>
                                                Container(
                                              color: Colors.black
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                        // Mekan kutucuğu içi yumuşak alt tint/shade
                                        const DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: [0.25, 1.0],
                                              colors: [
                                                Color(0x00000000),
                                                Color(0x99060B13),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 10,
                                          right: 10,
                                          bottom: 8,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                stop.placeName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                stop.locationSubtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _StopPreviewCardData {
  const _StopPreviewCardData({
    required this.placeName,
    required this.locationSubtitle,
    required this.imageUrl,
  });

  final String placeName;
  final String locationSubtitle;
  final String imageUrl;
}
