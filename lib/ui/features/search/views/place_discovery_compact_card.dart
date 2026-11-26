import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/place_discovery_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';

/// Akış içi kart kutusu olmayan, üstte yatay kaydırılabilir fotoğraf slider'ı,
/// soltta çeken gezgin atıfı, altta mekan bilgisi/puanı ve sağda yalnızca
/// kompakt ikon aksiyonları sunan modern mekan keşif öğesi.
class PlaceDiscoveryCompactCard extends StatefulWidget {
  const PlaceDiscoveryCompactCard({
    super.key,
    required this.place,
    this.savedLists = const <UserFavoritePlaceList>[],
    this.addedUserRoutes = const <UserEditableRouteOption>[],
    this.relatedRoutes = const <PublishedRouteFeedItem>[],
    this.showDistanceBadge = false,
    required this.onTapFlagButton,
    required this.onTapAddToRouteButton,
    this.onTapRelatedRoutesButton,
    this.onTapDetailButton,
  });

  final PlaceDiscoveryItem place;
  final List<UserFavoritePlaceList> savedLists;
  final List<UserEditableRouteOption> addedUserRoutes;
  final List<PublishedRouteFeedItem> relatedRoutes;
  final bool showDistanceBadge;
  final VoidCallback onTapFlagButton;
  final VoidCallback onTapAddToRouteButton;
  final VoidCallback? onTapRelatedRoutesButton;
  final VoidCallback? onTapDetailButton;

  @override
  State<PlaceDiscoveryCompactCard> createState() =>
      _PlaceDiscoveryCompactCardState();
}

class _PlaceDiscoveryCompactCardState extends State<PlaceDiscoveryCompactCard>
    with AutomaticKeepAliveClientMixin {
  static const int _descriptionCharLimit = 110;

  late PageController _photosPageController;
  int _currentPhotoIndex = 0;
  bool _isDescriptionExpanded = false;

  @override
  bool get wantKeepAlive => true;

  PageController _createPhotosController(int photoCount) {
    return PageController(
      viewportFraction: photoCount > 1 ? 0.80 : 1.0,
    );
  }

  @override
  void initState() {
    super.initState();
    _photosPageController =
        _createPhotosController(widget.place.cappedPhotos.length);
  }

  @override
  void didUpdateWidget(covariant PlaceDiscoveryCompactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isDifferentPlace = oldWidget.place.id != widget.place.id;
    if (isDifferentPlace) {
      _isDescriptionExpanded = false;
    }
    final oldHasMulti = oldWidget.place.cappedPhotos.length > 1;
    final newPhotos = widget.place.cappedPhotos;
    final newHasMulti = newPhotos.length > 1;
    if (isDifferentPlace || oldHasMulti != newHasMulti) {
      _photosPageController.dispose();
      _photosPageController = _createPhotosController(newPhotos.length);
      _currentPhotoIndex = 0;
    } else if (newPhotos.isNotEmpty && _currentPhotoIndex >= newPhotos.length) {
      _currentPhotoIndex = 0;
    }
  }

  @override
  void dispose() {
    _photosPageController.dispose();
    super.dispose();
  }

  void _toggleDescription() {
    setState(() {
      _isDescriptionExpanded = !_isDescriptionExpanded;
    });
  }

  String _truncateAtWordBoundary(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    final slice = text.substring(0, maxChars);
    final lastSpace = slice.lastIndexOf(' ');
    if (lastSpace > maxChars ~/ 2) {
      return slice.substring(0, lastSpace).trimRight();
    }
    return slice.trimRight();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final place = widget.place;
    final photos = place.cappedPhotos;
    final isFlagged = widget.savedLists.isNotEmpty || place.isFlagged;
    final topTags = place.communityVibes.take(3).toList(growable: false);
    final relatedRouteCount = widget.relatedRoutes.isNotEmpty
        ? widget.relatedRoutes.length
        : place.relatedRouteIds.length;
    final summary = place.shortSummary.trim();

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =============================================================
                  // 1. ÜST FOTOĞRAF SLIDER'I
                  // =============================================================
                  _buildPhotoSlider(
                    context: context,
                    place: place,
                    photos: photos,
                  ),

                  const SizedBox(height: 11),

                  // =============================================================
                  // 2. ÜST BİLGİ (BAŞLIK + KONUM + PUAN) VE SAĞDA İKON AKSİYONLAR
                  // =============================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTitleAndLocationHeader(place: place),
                      ),
                      const SizedBox(width: 8),
                      _buildRightIconActions(
                        place: place,
                        isFlagged: isFlagged,
                      ),
                    ],
                  ),

                  // =============================================================
                  // 3. TAM GENİŞLİKLİ AÇIKLAMA ("Devamını Oku" / "Daha Az Göster")
                  // =============================================================
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildExpandableDescription(summary: summary),
                  ],

                  // =============================================================
                  // 4. TOPLULUK ETİKETLERİ (#etiket1 #etiket2 #etiket3)
                  // =============================================================
                  if (topTags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildCommunityTags(topTags: topTags),
                  ],

                  // =============================================================
                  // 5. İLİNTİLİ ROTA SAYISI
                  // =============================================================
                  if (relatedRouteCount > 0) ...[
                    const SizedBox(height: 8),
                    _buildRelatedRoutesLink(
                      relatedRouteCount: relatedRouteCount,
                    ),
                  ],
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: BeenHereColors.borderSubtle.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlider({
    required BuildContext context,
    required PlaceDiscoveryItem place,
    required List<String> photos,
  }) {
    final hasMultiple = photos.length > 1;
    final safeCurrentIndex =
        photos.isEmpty ? 0 : _currentPhotoIndex.clamp(0, photos.length - 1);

    return SizedBox(
      key: ValueKey<String>('compact-photo-slider-${place.id}'),
      height: 208,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: PageView.builder(
              key: PageStorageKey<String>('compact-place-photos-${place.id}'),
              controller: _photosPageController,
              padEnds: false,
              itemCount: hasMultiple ? photos.length : 1,
              onPageChanged: (idx) {
                if (_currentPhotoIndex != idx) {
                  setState(() {
                    _currentPhotoIndex = idx;
                  });
                }
              },
              itemBuilder: (context, index) {
                final imageUrl = photos.isNotEmpty ? photos[index] : '';
                final isActiveSlide = !hasMultiple || index == safeCurrentIndex;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    right: hasMultiple ? 8 : 0,
                    top: isActiveSlide ? 0 : 14,
                    bottom: isActiveSlide ? 0 : 14,
                  ),
                  child: _buildPhotoTile(
                    imageUrl: imageUrl,
                    authorLabel: place.photoAuthorForIndex(index),
                    showAuthorBadge: isActiveSlide,
                  ),
                );
              },
            ),
          ),

          // Üst Katman: 2+ fotoğraf varsa sağ üstte slider nokta indikatörleri
          if (hasMultiple)
            Positioned(
              top: 8,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.46),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(photos.length, (idx) {
                    final isSelected = idx == safeCurrentIndex;
                    return GestureDetector(
                      onTap: () {
                        if (idx != safeCurrentIndex) {
                          _photosPageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2.5,
                        ),
                        width: isSelected ? 14 : 6,
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
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile({
    required String imageUrl,
    required String authorLabel,
    required bool showAuthorBadge,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GestureDetector(
        onTap: widget.onTapDetailButton,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                cacheWidth: 720,
                gaplessPlayback: true,
                filterQuality: FilterQuality.low,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPhotoFallback();
                },
              )
            else
              _buildPhotoFallback(),

            // Alt kısımda okunabilirlik için hafif gradient tint
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.45, 1.0],
                    colors: [
                      Color(0x00000000),
                      Color(0x9E060B13),
                    ],
                  ),
                ),
              ),
            ),

            // Sol alt köşede yalnızca aktif ana slaytta fotoğrafı çeken gezgin atıfı
            Positioned(
              left: 8,
              bottom: 8,
              right: 8,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: showAuthorBadge
                      ? Container(
                          key: ValueKey<String>(
                            'compact-photo-author-$authorLabel',
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.56),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PhosphorIcon(
                                PhosphorIcons.camera(
                                  PhosphorIconsStyle.duotone,
                                ),
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  authorLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.94),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoFallback() {
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
          PhosphorIcons.mountains(PhosphorIconsStyle.duotone),
          size: 36,
          color: Colors.white38,
        ),
      ),
    );
  }

  Widget _buildTitleAndLocationHeader({
    required PlaceDiscoveryItem place,
  }) {
    final locationLabel = place.city.isNotEmpty
        ? '${place.countryName}, ${place.city}'
        : place.countryName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 210.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: widget.onTapDetailButton,
              child: Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.textPrimary,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxColWidth),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.mapPin(PhosphorIconsStyle.duotone),
                        size: 13,
                        color: BeenHereColors.primaryCompass,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.star(PhosphorIconsStyle.fill),
                      size: 13,
                      color: BeenHereColors.goldLeague,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      place.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (widget.showDistanceBadge && place.hasDistance)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxColWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.navigationArrow(
                            PhosphorIconsStyle.fill,
                          ),
                          size: 11,
                          color: BeenHereColors.primaryCompass,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            '${place.distanceKmFromUser.toStringAsFixed(1)} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: BeenHereColors.primaryCompass,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildExpandableDescription({required String summary}) {
    final descriptionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: BeenHereColors.textSecondary,
      height: 1.4,
    );

    if (summary.length <= _descriptionCharLimit) {
      return Text(
        summary,
        style: descriptionStyle,
      );
    }

    final truncated = _truncateAtWordBoundary(summary, _descriptionCharLimit);

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleDescription,
        child: _isDescriptionExpanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    summary,
                    style: descriptionStyle,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _toggleDescription,
                    child: _buildDescriptionToggleLabel(
                      label: 'Daha Az Göster',
                      icon: PhosphorIcons.caretUp(PhosphorIconsStyle.bold),
                    ),
                  ),
                ],
              )
            : Text.rich(
                TextSpan(
                  text: '$truncated... ',
                  style: descriptionStyle,
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: GestureDetector(
                        onTap: _toggleDescription,
                        child: _buildDescriptionToggleLabel(
                          label: 'Devamını Oku',
                          icon:
                              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDescriptionToggleLabel({
    required String label,
    required PhosphorIconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: BeenHereColors.primaryCompass,
              height: 1.3,
            ),
          ),
          const SizedBox(width: 3),
          PhosphorIcon(
            icon,
            size: 13,
            color: BeenHereColors.primaryCompass,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTags({required List<String> topTags}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 340.0;

        return Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final tag in topTags)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.5,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: BeenHereColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: BeenHereColors.borderSubtle,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '#$tag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRelatedRoutesLink({required int relatedRouteCount}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: widget.onTapRelatedRoutesButton,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.path(PhosphorIconsStyle.duotone),
                size: 13,
                color: BeenHereColors.primaryCompass,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$relatedRouteCount Rotada Geçiyor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightIconActions({
    required PlaceDiscoveryItem place,
    required bool isFlagged,
  }) {
    final hasWarning = place.isClosed || place.warnings.isNotEmpty;
    final warningText = hasWarning
        ? (place.statusWarning ??
            place.openingHoursWarning ??
            place.warnings.first)
        : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasWarning) ...[
          _buildInlineWarningBadge(
            place: place,
            warningText: warningText,
          ),
          const SizedBox(width: 6),
        ],
        _buildCompactIconButton(
          key: ValueKey<String>('compact-flag-button-${place.id}'),
          tooltip: isFlagged
              ? 'Listede (${widget.savedLists.length})'
              : 'Listeye Kaydet',
          icon: PhosphorIcon(
            PhosphorIcons.flag(
              isFlagged ? PhosphorIconsStyle.fill : PhosphorIconsStyle.regular,
            ),
            size: 13,
            color: BeenHereColors.verifiedEmerald,
          ),
          onTap: widget.onTapFlagButton,
        ),
        const SizedBox(width: 4),
        _buildCompactIconButton(
          key: ValueKey<String>('compact-add-to-route-button-${place.id}'),
          tooltip: 'Rotaya Ekle',
          icon: PhosphorIcon(
            PhosphorIcons.path(PhosphorIconsStyle.duotone),
            size: 13,
            color: BeenHereColors.primaryCompass,
          ),
          onTap: widget.onTapAddToRouteButton,
        ),
        if (widget.onTapDetailButton != null) ...[
          const SizedBox(width: 4),
          _buildCompactIconButton(
            key: ValueKey<String>('compact-detail-button-${place.id}'),
            tooltip: 'Detay / Katkı',
            icon: PhosphorIcon(
              PhosphorIcons.info(PhosphorIconsStyle.duotone),
              size: 13,
              color: BeenHereColors.primaryCompass,
            ),
            onTap: widget.onTapDetailButton!,
          ),
        ],
      ],
    );
  }

  Widget _buildInlineWarningBadge({
    required PlaceDiscoveryItem place,
    required String warningText,
  }) {
    final accentColor =
        place.isClosed ? Colors.redAccent : Colors.amberAccent;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: Tooltip(
        message: warningText,
        child: Material(
          color: accentColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: widget.onTapDetailButton,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.65),
                  width: 0.85,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.warning(PhosphorIconsStyle.fill),
                    size: 11,
                    color: accentColor,
                  ),
                  const SizedBox(width: 3.5),
                  Flexible(
                    child: Text(
                      warningText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton({
    required Key key,
    required String tooltip,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        key: key,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 27,
            height: 27,
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}
