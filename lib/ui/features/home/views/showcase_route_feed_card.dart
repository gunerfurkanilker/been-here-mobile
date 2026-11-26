import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';

/// Vitrin (Showcase) Rota Akışı Kartı:
/// - Tek bütünleşik kart yüzeyi ve aşağı doğru kavisli (bombeli) alt kenar:
///   - Sol üstte Bütçe (`$680` / `$3000`), sağ üstte Gün sayısı (`5 Gün` / `10 Gün`)
///   - Ortada simetrik 3'lü mekan fotoğrafı sahnesi (`[ Sol Önizleme ] [ Orta Büyük Fotoğraf ] [ Sağ Önizleme ]`)
///   - Fotoğrafın hemen altında ortalanmış aktif `Mekan Adı` ve `Ülke, Şehir`
///   - Onun hemen altında, kartın aşağı doğru bombelenen kavisli alt sınırının
///     içerisinde ortalanmış `Gezi Başlık` ve `Gezgin Adı`
///
/// Not: Eski `FullscreenSwipeRouteCard` ve `PublishedRouteCard` bileşenleri
/// silinmeden kendi dosyalarında korunmaktadır.
class ShowcaseRouteFeedCard extends StatefulWidget {
  const ShowcaseRouteFeedCard({
    super.key,
    required this.route,
    required this.onTapCard,
  });

  final PublishedRouteFeedItem route;
  final VoidCallback onTapCard;

  @override
  State<ShowcaseRouteFeedCard> createState() => _ShowcaseRouteFeedCardState();
}

class _ShowcaseRouteFeedCardState extends State<ShowcaseRouteFeedCard>
    with AutomaticKeepAliveClientMixin {
  static const int _kLoopCycles = 20;

  /// IEEE-754 ikili tabanda tam bölünen kesir (11 / 16 = 0.6875).
  /// Ortada %68.75 genişlikte ana fotoğraf, solda ve sağda ~%15.6 yan önizleme
  /// çubukları oluşturur ve kaydırma sırasında `precisionErrorTolerance` sapmasını önler.
  static const double _kMultiStopViewportFraction = 0.6875;
  static const double _kSingleStopViewportFraction = 0.75;

  late PageController _stopsPageController;
  late List<_ShowcaseStopItemData> _cachedStopItems;
  late int _currentRawPage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cachedStopItems = _buildStopPreviewItems(widget.route);
    _currentRawPage = _initialPageFor(_cachedStopItems.length);
    _stopsPageController = PageController(
      viewportFraction: _viewportFractionFor(_cachedStopItems.length),
      initialPage: _currentRawPage,
    );
  }

  @override
  void didUpdateWidget(covariant ShowcaseRouteFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route.id != widget.route.id) {
      final oldLength = _cachedStopItems.length;
      _cachedStopItems = _buildStopPreviewItems(widget.route);
      _currentRawPage = _initialPageFor(_cachedStopItems.length);
      if (oldLength != _cachedStopItems.length) {
        _stopsPageController.dispose();
        _stopsPageController = PageController(
          viewportFraction: _viewportFractionFor(_cachedStopItems.length),
          initialPage: _currentRawPage,
        );
      } else if (_stopsPageController.hasClients) {
        _stopsPageController.jumpToPage(_currentRawPage);
      }
    }
  }

  int _initialPageFor(int stopCount) {
    if (stopCount <= 1) return 0;
    return stopCount * (_kLoopCycles ~/ 2);
  }

  double _viewportFractionFor(int stopCount) {
    return stopCount > 1
        ? _kMultiStopViewportFraction
        : _kSingleStopViewportFraction;
  }

  @override
  void dispose() {
    _stopsPageController.dispose();
    super.dispose();
  }

  String _formatBudgetUsd(double budgetUsd) {
    return '\$${budgetUsd.round()}';
  }

  /// Taslaktaki gibi "Ülke, Şehir" (Örn: "Türkiye, Fethiye" veya "Almanya, Berlin") döndürür.
  String _resolveCountryAndCityLabel({
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
    return '$country, $city';
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

  List<_ShowcaseStopItemData> _buildStopPreviewItems(
    PublishedRouteFeedItem route,
  ) {
    final media = route.cappedFeaturedMedia;
    final coverPhotoUrl = media.isNotEmpty ? media.first : '';
    final items = <_ShowcaseStopItemData>[];
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
        _ShowcaseStopItemData(
          placeName: stop.placeName,
          locationSubtitle: _resolveCountryAndCityLabel(
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
        _ShowcaseStopItemData(
          placeName: name,
          locationSubtitle: _resolveCountryAndCityLabel(
            route: route,
            placeName: name,
            fallbackIndex: items.length,
          ),
          imageUrl: photoUrl,
        ),
      );
      addedNames.add(name);
    }

    if (items.isEmpty) {
      items.add(
        _ShowcaseStopItemData(
          placeName: route.title,
          locationSubtitle: _resolveCountryAndCityLabel(
            route: route,
            placeName: route.title,
            fallbackIndex: 0,
          ),
          imageUrl: coverPhotoUrl,
        ),
      );
    }

    return items;
  }

  LinearGradient _buildCardBackgroundGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
        colors: [
          Color.lerp(
            BeenHereDarkColors.surfaceElevated,
            BeenHereDarkColors.surface,
            0.35,
          )!,
          BeenHereDarkColors.surface,
          Color.lerp(
            BeenHereDarkColors.background,
            BeenHereDarkColors.primaryCompass,
            0.05,
          )!,
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
      colors: [
        Color.lerp(
          BeenHereLightColors.background,
          BeenHereLightColors.surface,
          0.35,
        )!,
        BeenHereLightColors.surface,
        Color.lerp(
          BeenHereLightColors.surface,
          BeenHereLightColors.softSky,
          0.18,
        )!,
      ],
    );
  }

  LinearGradient _buildCardBorderGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
        colors: [
          BeenHereDarkColors.primaryCompass.withValues(alpha: 0.22),
          BeenHereDarkColors.borderSubtle.withValues(alpha: 0.55),
          BeenHereDarkColors.secondaryAmber.withValues(alpha: 0.14),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
      colors: [
        BeenHereLightColors.primaryCompass.withValues(alpha: 0.28),
        BeenHereLightColors.borderSubtle.withValues(alpha: 0.65),
        BeenHereLightColors.softSky.withValues(alpha: 0.35),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final route = widget.route;
    final stopItems = _cachedStopItems;
    final activeStopIndex =
        stopItems.isEmpty ? 0 : (_currentRawPage % stopItems.length);
    final activeStop = stopItems[activeStopIndex];
    final totalItemCount =
        stopItems.length > 1 ? stopItems.length * _kLoopCycles : 1;
    final isDark = BeenHereThemeController.instance.isDark;

    const cardShape = CurvedBottomShowcaseCardBorder(
      topRadius: 28,
      bottomBulge: 38,
      shoulderCornerRadius: 24,
      shoulderCornerWidth: 26,
      side: BorderSide(
        color: Color(0x00000000), // Kenarlık dinamik tema rengiyle aşağıda verilir
      ),
    );
    final themedCardShape = cardShape.copyWith(
      side: BorderSide(
        color: BeenHereColors.borderSubtle,
        width: 1.2,
      ),
      borderGradient: _buildCardBorderGradient(isDark),
    );

    return RepaintBoundary(
      child: Container(
        key: ValueKey<String>('showcase-card-shell-${route.id}'),
        decoration: ShapeDecoration(
          gradient: _buildCardBackgroundGradient(isDark),
          shape: themedCardShape,
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. ÜST SATIR: Sol Üst Bütçe ($680) — Sağ Üst Gün (5 Gün)
            // =================================================================
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTapCard,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatBudgetUsd(route.estimatedBudgetUsd),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${route.durationDays} Gün',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // 2. ORTA SAHNE: [ Sol Önizleme ] [ Orta Büyük Fotoğraf ] [ Sağ Önizleme ]
            // =================================================================
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: PageView.builder(
                  key: ValueKey<String>(
                    'showcase-stops-pageview-${route.id}',
                  ),
                  controller: _stopsPageController,
                  padEnds: true,
                  itemCount: totalItemCount,
                  onPageChanged: (rawPage) {
                    if (_currentRawPage != rawPage) {
                      setState(() {
                        _currentRawPage = rawPage;
                      });
                    }
                  },
                  itemBuilder: (context, rawIndex) {
                    final actualIndex = rawIndex % stopItems.length;
                    final stop = stopItems[actualIndex];
                    final isCenter = rawIndex == _currentRawPage;

                    final photoCard = Container(
                      decoration: BoxDecoration(
                        color: BeenHereColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(
                          isCenter ? 22 : 14,
                        ),
                        border: Border.all(
                          color: isCenter
                              ? BeenHereColors.borderSubtle
                                  .withValues(alpha: 0.85)
                              : BeenHereColors.borderSubtle
                                  .withValues(alpha: 0.45),
                          width: 1,
                        ),
                        boxShadow: isCenter
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildStopPhoto(stop.imageUrl),
                    );

                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: isCenter ? 0 : 34,
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: isCenter ? 1.0 : 0.78,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (isCenter) {
                              widget.onTapCard();
                            } else {
                              _stopsPageController.animateToPage(
                                rawIndex,
                                duration: const Duration(
                                  milliseconds: 260,
                                ),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: isCenter
                              ? Hero(
                                  tag: 'route-hero-image-${route.id}',
                                  child: photoCard,
                                )
                              : photoCard,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // =================================================================
            // 3. AKTİF MEKAN BİLGİSİ: Mekan Adı & Ülke, Şehir
            // =================================================================
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTapCard,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeStop.placeName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeStop.locationSubtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: BeenHereColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Zarif görsel ayırıcı çizgi
            Center(
              child: Container(
                width: 112,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BeenHereColors.borderSubtle.withValues(alpha: 0.0),
                      BeenHereColors.borderSubtle.withValues(alpha: 0.75),
                      BeenHereColors.borderSubtle.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // =================================================================
            // 4. KAVİSLİ ALT BÖLÜM (KARTIN İÇİNDE, AŞAĞI DOĞRU BOMBELİ ALANDA):
            //    Gezi Başlık & Gezgin Adı
            // =================================================================
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTapCard,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(44, 8, 44, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      route.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                        height: 1.18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.authorDisplayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BeenHereColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopPhoto(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildPhotoFallback();
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 640,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, error, stackTrace) => _buildPhotoFallback(),
    );
  }

  Widget _buildPhotoFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BeenHereColors.surfaceElevated,
            BeenHereColors.surface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 42,
          color: BeenHereColors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ShowcaseStopItemData {
  const _ShowcaseStopItemData({
    required this.placeName,
    required this.locationSubtitle,
    required this.imageUrl,
  });

  final String placeName;
  final String locationSubtitle;
  final String imageUrl;
}

/// Üst köşeleri yuvarlatılmış, yan duvarlardan inip alt omuzlarda yumuşakça
/// dönerek alt kenar boyunca aşağı doğru bombeli (convex arc) kavis oluşturan
/// özel kart sınır şekli (`OutlinedBorder`).
class CurvedBottomShowcaseCardBorder extends OutlinedBorder {
  const CurvedBottomShowcaseCardBorder({
    super.side,
    this.topRadius = 28.0,
    this.bottomBulge = 38.0,
    this.shoulderCornerRadius = 24.0,
    this.shoulderCornerWidth = 26.0,
    this.borderGradient,
  });

  final double topRadius;
  final double bottomBulge;
  final double shoulderCornerRadius;
  final double shoulderCornerWidth;
  final Gradient? borderGradient;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  CurvedBottomShowcaseCardBorder scale(double t) {
    return CurvedBottomShowcaseCardBorder(
      side: side.scale(t),
      topRadius: topRadius * t,
      bottomBulge: bottomBulge * t,
      shoulderCornerRadius: shoulderCornerRadius * t,
      shoulderCornerWidth: shoulderCornerWidth * t,
      borderGradient: borderGradient?.scale(t),
    );
  }

  @override
  CurvedBottomShowcaseCardBorder copyWith({
    BorderSide? side,
    double? topRadius,
    double? bottomBulge,
    double? shoulderCornerRadius,
    double? shoulderCornerWidth,
    Gradient? borderGradient,
  }) {
    return CurvedBottomShowcaseCardBorder(
      side: side ?? this.side,
      topRadius: topRadius ?? this.topRadius,
      bottomBulge: bottomBulge ?? this.bottomBulge,
      shoulderCornerRadius: shoulderCornerRadius ?? this.shoulderCornerRadius,
      shoulderCornerWidth: shoulderCornerWidth ?? this.shoulderCornerWidth,
      borderGradient: borderGradient ?? this.borderGradient,
    );
  }

  Path _buildPath(Rect rect) {
    final tr = topRadius.clamp(0.0, rect.width * 0.45);
    final bulge = bottomBulge.clamp(0.0, rect.height * 0.25);
    final shoulderY = rect.bottom - bulge;
    final cRadius = shoulderCornerRadius.clamp(0.0, rect.height * 0.2);
    final cWidth = shoulderCornerWidth.clamp(0.0, rect.width * 0.25);

    final rightShoulderX = rect.right - cWidth;
    final leftShoulderX = rect.left + cWidth;
    final midX = rect.center.dx;
    final halfSpan = (rightShoulderX - midX).clamp(1.0, rect.width);

    // Omuz noktasındaki C1 teğet eğimi (sağ/sol omuz geçişiyle orta bombe arasında pürüzsüz süreklilik)
    final tangentSlope = bulge / (halfSpan * 0.85);
    final shoulderHandleX = cWidth * 0.46;

    return Path()
      // 1. Üst kenar (soldan sağa)
      ..moveTo(rect.left + tr, rect.top)
      ..lineTo(rect.right - tr, rect.top)
      // 2. Sağ üst yuvarlatılmış köşe
      ..arcToPoint(
        Offset(rect.right, rect.top + tr),
        radius: Radius.circular(tr),
        clockwise: true,
      )
      // 3. Sağ dikey kenar (aşağı doğru)
      ..lineTo(rect.right, shoulderY - cRadius)
      // 4. Sağ alt omuz dönüşü -> aşağı doğru bombe başlangıcı (C1 sürekli)
      ..cubicTo(
        rect.right,
        shoulderY - cRadius * 0.35,
        rightShoulderX + shoulderHandleX,
        shoulderY - shoulderHandleX * tangentSlope,
        rightShoulderX,
        shoulderY,
      )
      // 5. Alt bombenin sağ yarısı (sağ omuzdan alt orta zirveye)
      ..cubicTo(
        rightShoulderX - halfSpan * 0.38,
        shoulderY + halfSpan * 0.38 * tangentSlope,
        midX + halfSpan * 0.36,
        rect.bottom,
        midX,
        rect.bottom,
      )
      // 6. Alt bombenin sol yarısı (alt orta zirveden sol omuza)
      ..cubicTo(
        midX - halfSpan * 0.36,
        rect.bottom,
        leftShoulderX + halfSpan * 0.38,
        shoulderY + halfSpan * 0.38 * tangentSlope,
        leftShoulderX,
        shoulderY,
      )
      // 7. Sol alt omuz dönüşü -> sol dikey kenara bağlantı (C1 sürekli)
      ..cubicTo(
        leftShoulderX - shoulderHandleX,
        shoulderY - shoulderHandleX * tangentSlope,
        rect.left,
        shoulderY - cRadius * 0.35,
        rect.left,
        shoulderY - cRadius,
      )
      // 8. Sol dikey kenar (yukarı doğru)
      ..lineTo(rect.left, rect.top + tr)
      // 9. Sol üst yuvarlatılmış köşe
      ..arcToPoint(
        Offset(rect.left + tr, rect.top),
        radius: Radius.circular(tr),
        clockwise: true,
      )
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect.deflate(side.strokeInset));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _buildPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    final insetRect = rect.deflate(side.width / 2);
    final paint = side.toPaint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    if (borderGradient != null) {
      paint.shader = borderGradient!.createShader(
        insetRect,
        textDirection: textDirection,
      );
    }
    canvas.drawPath(_buildPath(insetRect), paint);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is CurvedBottomShowcaseCardBorder &&
        other.side == side &&
        other.topRadius == topRadius &&
        other.bottomBulge == bottomBulge &&
        other.shoulderCornerRadius == shoulderCornerRadius &&
        other.shoulderCornerWidth == shoulderCornerWidth &&
        other.borderGradient == borderGradient;
  }

  @override
  int get hashCode => Object.hash(
        side,
        topRadius,
        bottomBulge,
        shoulderCornerRadius,
        shoulderCornerWidth,
        borderGradient,
      );
}
