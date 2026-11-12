import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/models/place_discovery_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';

class PlaceDiscoveryCard extends StatefulWidget {
  const PlaceDiscoveryCard({
    super.key,
    required this.place,
    required this.savedLists,
    required this.addedUserRoutes,
    required this.relatedRoutes,
    required this.similarPlaces,
    required this.showDistanceBadge,
    required this.onTapFlagButton,
    required this.onTapAddToRouteButton,
    required this.onTapRelatedRoutesButton,
  });

  final PlaceDiscoveryItem place;
  final List<UserFavoritePlaceList> savedLists;
  final List<UserEditableRouteOption> addedUserRoutes;
  final List<PublishedRouteFeedItem> relatedRoutes;
  final List<PlaceDiscoveryItem> similarPlaces;
  final bool showDistanceBadge;
  final VoidCallback onTapFlagButton;
  final VoidCallback onTapAddToRouteButton;
  final VoidCallback onTapRelatedRoutesButton;

  @override
  State<PlaceDiscoveryCard> createState() => _PlaceDiscoveryCardState();
}

class _PlaceDiscoveryCardState extends State<PlaceDiscoveryCard>
    with AutomaticKeepAliveClientMixin {
  late final PageController _photosPageController;
  late final PageController _similarPlacesController;

  // 300 sayısı 1, 2 ve 3'e tam bölündüğü için her zaman 0. fotoğraftan başlar
  // ve hem sağa hem sola sonsuz (infinite) kaydırmaya izin verir.
  static const int _initialInfinitePhotoPage = 300;

  int _currentPhotoIndex = _initialInfinitePhotoPage;
  bool _isSimilarLocationsExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _photosPageController = PageController(
      initialPage: _initialInfinitePhotoPage,
    );
    // Rota kartlarındaki gibi 1. sıradaki benzer lokasyon %74 genişlik kaplar, sıradaki sağdan %26 görünür
    _similarPlacesController = PageController(viewportFraction: 0.74);
  }

  @override
  void dispose() {
    _photosPageController.dispose();
    _similarPlacesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final place = widget.place;
    // Maksimum 3 fotoğraf (cappedPhotos = take(3))
    final photos = place.cappedPhotos;
    final safePhotoIndex =
        photos.isEmpty ? 0 : (_currentPhotoIndex % photos.length);
    final currentPhotoAuthor = place.photoAuthorForIndex(safePhotoIndex);

    final isFlagged = widget.savedLists.isNotEmpty;
    final similarPlaces = widget.similarPlaces;
    final topTags = place.communityVibes.take(3).toList(growable: false);

    return RepaintBoundary(
      child: Container(
        height: 510,
        margin: const EdgeInsets.only(bottom: 16),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ===============================================================
              // 1. MEKAN FOTOĞRAF SLIDER'I (Maksimum 3 Fotoğraf - Infinite Scroll)
              // ===============================================================
              ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: const {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: PageView.builder(
                  key: PageStorageKey<String>('place-photos-${place.id}'),
                  controller: _photosPageController,
                  itemCount: photos.length > 1 ? null : 1,
                  onPageChanged: (idx) {
                    setState(() {
                      _currentPhotoIndex = idx;
                    });
                  },
                  itemBuilder: (context, rawIndex) {
                    final actualIndex =
                        photos.isEmpty ? 0 : (rawIndex % photos.length);
                    final imageUrl =
                        photos.isNotEmpty ? photos[actualIndex] : '';
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
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
                              child: Center(
                                child: PhosphorIcon(
                                  PhosphorIcons.mountains(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 54,
                                  color: Colors.white38,
                                ),
                              ),
                            );
                          },
                        ),

                        // Üst ve Alt Yumuşak Tint / Shade Katmanı (Okunabilirlik için)
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0.0, 0.22, 0.48, 0.68, 1.0],
                                colors: [
                                  Color(0x80070D17), // Üst tint/shade
                                  Color(0x00070D17), // Orta alan temiz
                                  Color(0x00070D17),
                                  Color(0x68070D17), // Alt başlangıç tint
                                  Color(0xB4070D17), // Alt bitiş shade
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ===============================================================
              // 2. ÜST ALAN:
              // - Sol Üst: Puanlama ve Son 1 Ayda X Ziyaretçi
              // - Sağ Üst: 3'lü Fotoğraf Slider İndikatörleri
              // - Hemen Altında (Aynı Yerde): Fotoğrafın Hangi Gezgine Ait Olduğu
              // ===============================================================
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sol Üst: Puanlama ve Son 1 Ayda X Ziyaretçi (+ Yakınımda ise Mesafe)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  PhosphorIcons.star(PhosphorIconsStyle.fill),
                                  size: 13.5,
                                  color: BeenHereColors.goldLeague,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  place.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                PhosphorIcon(
                                  PhosphorIcons.footprints(
                                    PhosphorIconsStyle.duotone,
                                  ),
                                  size: 13.5,
                                  color: BeenHereColors.verifiedEmerald,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Son 1 ayda ${place.verifiedVisitCount} Ziyaretçi',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                ),
                                if (widget.showDistanceBadge) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    child: Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  PhosphorIcon(
                                    PhosphorIcons.navigationArrow(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    size: 11.5,
                                    color: BeenHereColors.primaryCompass,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${place.distanceKmFromUser.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Sağ Üst: Fotoğraf Slider İndikatörleri (Sağ köşeye tam yaslı)
                        if (photos.length > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(photos.length, (idx) {
                                final isSelected = idx == safePhotoIndex;
                                return GestureDetector(
                                  onTap: () {
                                    final delta = idx - safePhotoIndex;
                                    if (delta != 0) {
                                      _photosPageController.animateToPage(
                                        _currentPhotoIndex + delta,
                                        duration:
                                            const Duration(milliseconds: 240),
                                        curve: Curves.easeOutCubic,
                                      );
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                    ),
                                    width: isSelected ? 15 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? BeenHereColors.primaryCompass
                                          : Colors.white.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Aktif Fotoğrafın Hangi Gezgine Ait Olduğu (Aynı yerinde)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.camera(
                              PhosphorIconsStyle.duotone,
                            ),
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            currentPhotoAuthor,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // 3. ALT KISIM:
              // Sol: Mekan Adı + Ülke, Şehir + Yarı Saydam Tag Şeklinde #etiketler
              // Sağ: Listeye Kaydet (Yeşil Bayrak İkonu) & Rotaya Ekle (Sabit İkonlu Buton)
              // En Alt: Tıklanınca Açılan/Kapanan Benzer Lokasyonlar Butonu ve Slider'ı
              // ===============================================================
              Positioned(
                left: 14,
                right: 0,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 3.1. Orta-Alt Satır: Sol (Başlık + Konum + Yarı Saydam Tagler) & Sağ (Bayrak + Rotaya Ekle İkon Butonları)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Sol Sütun: Mekan Başlığı, Ülke/Şehir ve Yarı Saydam #etiket Tag'leri
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Mekan Başlığı
                                Text(
                                  place.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // Ülke, Şehir Satırı
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PhosphorIcon(
                                      PhosphorIcons.mapPin(
                                        PhosphorIconsStyle.duotone,
                                      ),
                                      size: 13.5,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${place.countryName}, ${place.city}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (topTags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  // Yarı saydam arka planlı Tag şeklinde topluluk etiketleri (#etiket1 #etiket2 #etiket3)
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        for (int i = 0;
                                            i < topTags.length;
                                            i++) ...[
                                          if (i > 0) const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.5,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.44),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.16),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              '#${topTags[i]}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white
                                                    .withValues(alpha: 0.94),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Sağ Sütun: Listeye Ekle (Yeşil Bayrak İkonu) + Rotaya Ekle (Sabit İkonlu Buton) + Geçtiği Rotalar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Listeye Kaydet (Yeşil Bayrak İkon Butonu — Listede ise dolu, değilse boş)
                                  Tooltip(
                                    message: isFlagged
                                        ? 'Listede (${widget.savedLists.length})'
                                        : 'Listeye Kaydet',
                                    child: Material(
                                      color: isFlagged
                                          ? BeenHereColors.verifiedEmerald
                                              .withValues(alpha: 0.24)
                                          : Colors.black
                                              .withValues(alpha: 0.42),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: widget.onTapFlagButton,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 38,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isFlagged
                                                  ? BeenHereColors
                                                      .verifiedEmerald
                                                      .withValues(alpha: 0.7)
                                                  : BeenHereColors
                                                      .verifiedEmerald
                                                      .withValues(alpha: 0.38),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Center(
                                            child: PhosphorIcon(
                                              PhosphorIcons.flag(
                                                isFlagged
                                                    ? PhosphorIconsStyle.fill
                                                    : PhosphorIconsStyle
                                                        .regular,
                                              ),
                                              size: 18,
                                              color: BeenHereColors
                                                  .verifiedEmerald,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // 2. Rotaya Ekle (İkonlu Buton — Herhangi bir rotada ekli olsa bile ikonda değişim olmaz)
                                  Tooltip(
                                    message: 'Rotaya Ekle',
                                    child: Material(
                                      color: Colors.black
                                          .withValues(alpha: 0.42),
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap: widget.onTapAddToRouteButton,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 38,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: BeenHereColors
                                                  .primaryCompass
                                                  .withValues(alpha: 0.45),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Center(
                                            child: PhosphorIcon(
                                              PhosphorIcons.path(
                                                PhosphorIconsStyle.duotone,
                                              ),
                                              size: 18,
                                              color: BeenHereColors
                                                  .primaryCompass,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.relatedRoutes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: widget.onTapRelatedRoutesButton,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PhosphorIcon(
                                        PhosphorIcons.path(
                                          PhosphorIconsStyle.duotone,
                                        ),
                                        size: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.82),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.relatedRoutes.length} Rotada Geçiyor',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3.2. Benzer Lokasyonlar Aç/Kapat Butonu ve Açılır Slider
                    if (similarPlaces.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _isSimilarLocationsExpanded =
                                    !_isSimilarLocationsExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PhosphorIcon(
                                    PhosphorIcons.compass(
                                      PhosphorIconsStyle.duotone,
                                    ),
                                    size: 14,
                                    color: BeenHereColors.primaryCompass,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isSimilarLocationsExpanded
                                        ? 'Benzer Lokasyonları Gizle'
                                        : 'Benzer Lokasyonlar (${similarPlaces.length})',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  PhosphorIcon(
                                    _isSimilarLocationsExpanded
                                        ? PhosphorIcons.caretDown(
                                            PhosphorIconsStyle.bold,
                                          )
                                        : PhosphorIcons.caretUp(
                                            PhosphorIconsStyle.bold,
                                          ),
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _isSimilarLocationsExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  height: 104,
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(context)
                                        .copyWith(
                                      dragDevices: const {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                        PointerDeviceKind.trackpad,
                                      },
                                    ),
                                    child: PageView.builder(
                                      key: PageStorageKey<String>(
                                        'similar-places-slider-${place.id}',
                                      ),
                                      controller: _similarPlacesController,
                                      padEnds: false,
                                      itemBuilder: (context, rawIndex) {
                                        final actualIndex =
                                            rawIndex % similarPlaces.length;
                                        final similar =
                                            similarPlaces[actualIndex];
                                        final similarPhoto =
                                            similar.cappedPhotos.isNotEmpty
                                                ? similar.cappedPhotos.first
                                                : '';

                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: GestureDetector(
                                            onTap: () {
                                              _similarPlacesController
                                                  .animateToPage(
                                                rawIndex,
                                                duration: const Duration(
                                                  milliseconds: 260,
                                                ),
                                                curve: Curves.easeOutCubic,
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black
                                                    .withValues(alpha: 0.36),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  if (similarPhoto.isNotEmpty)
                                                    Image.network(
                                                      similarPhoto,
                                                      fit: BoxFit.cover,
                                                      cacheWidth: 360,
                                                      gaplessPlayback: true,
                                                      filterQuality:
                                                          FilterQuality.low,
                                                      errorBuilder:
                                                          (_, _, _) =>
                                                              Container(
                                                        color: Colors.black
                                                            .withValues(
                                                          alpha: 0.35,
                                                        ),
                                                      ),
                                                    ),
                                                  const DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        stops: [0.22, 1.0],
                                                        colors: [
                                                          Color(0x00000000),
                                                          Color(0x9E060B13),
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
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          similar.name,
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Row(
                                                          children: [
                                                            PhosphorIcon(
                                                              PhosphorIcons
                                                                  .mapPin(
                                                                PhosphorIconsStyle
                                                                    .fill,
                                                              ),
                                                              size: 10.5,
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                alpha: 0.78,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 3,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                '${similar.city}, ${similar.countryName}',
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      10.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                    alpha: 0.82,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
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
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
