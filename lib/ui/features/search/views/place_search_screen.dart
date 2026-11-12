import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/models/place_discovery_models.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';
import '../../../core/widgets/geography_tree_filter_bar.dart';
import '../../home/view_models/home_feed_view_model.dart';
import '../../home/views/route_detail_screen.dart';
import '../view_models/place_search_view_model.dart';
import 'place_discovery_card.dart';

class PlaceSearchScreen extends StatefulWidget {
  const PlaceSearchScreen({
    super.key,
    required this.viewModel,
    required this.homeFeedViewModel,
  });

  final PlaceSearchViewModel viewModel;
  final HomeFeedViewModel homeFeedViewModel;

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  void _handleGoogleFallbackTap(BuildContext context) {
    final query = widget.viewModel.draftSearchInput.trim().isNotEmpty
        ? widget.viewModel.draftSearchInput.trim()
        : widget.viewModel.placeSearchQuery.trim();

    if (widget.viewModel.searchMode == PlaceSearchMode.globalSearch &&
        query.length < 3) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '⚠️ Google Haritalar araması için lütfen en az 3 karakter girin.',
          ),
        ),
      );
      return;
    }

    final created = widget.viewModel.fetchFromGoogleMapsFallback();
    if (created != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🗺️ "${created.name}" Google Haritalar\'dan çekilerek listeye eklendi!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final places = vm.displayedPlaces;
        final isNearbyMode = vm.searchMode == PlaceSearchMode.nearby;
        final showEndFallbackCard = vm.shouldShowNotFoundBannerAtEnd;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. BİRLEŞTİRİLMİŞ ÜST ARAMA & KONUM & DÜNYA FİLTRESİ ÇUBUĞU (Ortak Component)
            // =================================================================
            GeographyTreeFilterBar(
              filterModel: vm,
              resultCountLabelBuilder: () =>
                  '${vm.geographyFilteredPlacesCount} Mekan',
              showNearbyButton: true,
              showTreeDrawerButton: true,
            ),

            const SizedBox(height: 10),

            // =================================================================
            // 3. MEKAN KARTLARI LİSTESİ + LİSTE SONU "ARADIĞINIZ MEKANI BULAMADINIZ MI?" AKIŞI
            // =================================================================
            Expanded(
              child: places.isEmpty && !showEndFallbackCard
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore_off_outlined,
                              size: 46,
                              color: BeenHereColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Seçilen bölge/şehir filtresinde henüz keşif noktası bulunmuyor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: vm.resetToGlobal,
                              icon: const Icon(Icons.public_rounded, size: 17),
                              label: const Text('Tüm Dünya Mekanlarını Göster'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                key: const PageStorageKey<String>('place-search-list'),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 105),
                itemCount: places.length + (showEndFallbackCard ? 1 : 0),
                itemBuilder: (context, index) {
                  // Listenin sonuna gelindiğinde "Aradığınız mekanı bulamadınız mı?" kartı
                  if (index == places.length) {
                    return _NotFoundGoogleFallbackCard(
                      searchQuery: vm.draftSearchInput.trim().isNotEmpty
                          ? vm.draftSearchInput
                          : vm.placeSearchQuery,
                      searchMode: vm.searchMode,
                      hasAnyResults: places.isNotEmpty,
                      onTapGoogleSearch: () => _handleGoogleFallbackTap(context),
                    );
                  }

                  final place = places[index];
                  final savedLists = vm.getListsContainingPlace(place.id);
                  final addedUserRoutes =
                      vm.getUserRoutesContainingPlace(place.id);
                  final relatedRoutes = vm.getRelatedRoutesForPlace(place);
                  final similarPlaces = vm.getSimilarPlacesForPlace(place);

                  return PlaceDiscoveryCard(
                    key: ValueKey<String>('place-card-${place.id}'),
                    place: place,
                    savedLists: savedLists,
                    addedUserRoutes: addedUserRoutes,
                    relatedRoutes: relatedRoutes,
                    similarPlaces: similarPlaces,
                    showDistanceBadge: isNearbyMode,
                    onTapFlagButton: () =>
                        _showSahibindenFlagModal(context, place),
                    onTapAddToRouteButton: () =>
                        _showAddToRouteModal(context, place),
                    onTapRelatedRoutesButton: () =>
                        _showRelatedRoutesDrawer(context, place, relatedRoutes),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Taslak veya Anı Rotasına Ekleme Modalı
  void _showAddToRouteModal(
    BuildContext context,
    PlaceDiscoveryItem place,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final userRoutes = widget.viewModel.userEditableRoutes;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: BeenHereColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: BeenHereColors.borderSubtle,
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            BeenHereColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BeenHereColors.primaryCompass
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: PhosphorIcon(
                          PhosphorIcons.backpack(PhosphorIconsStyle.duotone),
                          color: BeenHereColors.primaryCompass,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Taslak veya Anı Rotana Ekle',
                              style: TextStyle(
                                fontSize: 12,
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final routeOpt in userRoutes) ...[
                    Builder(
                      builder: (context) {
                        final isSelected = routeOpt.containsPlace(place.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              widget.viewModel.togglePlaceInUserRoute(
                                routeId: routeOpt.id,
                                placeId: place.id,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BeenHereColors.verifiedEmerald
                                        .withValues(alpha: 0.14)
                                    : BeenHereColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? BeenHereColors.verifiedEmerald
                                      : BeenHereColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  PhosphorIcon(
                                    routeOpt.isDraft
                                        ? PhosphorIcons.compass(
                                            PhosphorIconsStyle.duotone,
                                          )
                                        : PhosphorIcons.bookBookmark(
                                            PhosphorIconsStyle.duotone,
                                          ),
                                    size: 20,
                                    color: routeOpt.isDraft
                                        ? BeenHereColors.primaryCompass
                                        : BeenHereColors.goldLeague,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          routeOpt.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: BeenHereColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${routeOpt.routeTypeLabel} • ${routeOpt.placeIds.length} durak',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: BeenHereColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PhosphorIcon(
                                    isSelected
                                        ? PhosphorIcons.checkCircle(
                                            PhosphorIconsStyle.fill,
                                          )
                                        : PhosphorIcons.plusCircle(
                                            PhosphorIconsStyle.regular,
                                          ),
                                    color: isSelected
                                        ? BeenHereColors.verifiedEmerald
                                        : BeenHereColors.textSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Sahibinden.com tarzı Özel Favori Listesine Kaydetme (Flag'leme) Modalı
  void _showSahibindenFlagModal(
    BuildContext context,
    PlaceDiscoveryItem place,
  ) {
    final newListController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final lists = widget.viewModel.favoriteLists;
            final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

            return Container(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottomInset),
              decoration: BoxDecoration(
                color: BeenHereColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: BeenHereColors.borderSubtle,
                    width: 1.2,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            BeenHereColors.textSecondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BeenHereColors.goldLeague
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.flag_rounded,
                          color: BeenHereColors.goldLeague,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Özel Mekan Listenize Kaydedin (Flag)',
                              style: TextStyle(
                                fontSize: 12,
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mevcut Özel Listeler
                  for (final list in lists) ...[
                    Builder(
                      builder: (context) {
                        final isSelected = list.containsPlace(place.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              widget.viewModel.togglePlaceInList(
                                listId: list.id,
                                placeId: place.id,
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BeenHereColors.goldLeague
                                        .withValues(alpha: 0.14)
                                    : BeenHereColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? BeenHereColors.goldLeague
                                      : BeenHereColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    list.iconEmoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          list.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: BeenHereColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${list.placeIds.length} mekan kayıtlı',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: BeenHereColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.add_circle_outline_rounded,
                                    color: isSelected
                                        ? BeenHereColors.goldLeague
                                        : BeenHereColors.textSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 8),
                  Divider(color: BeenHereColors.borderSubtle),
                  const SizedBox(height: 8),

                  // + Yeni Özel Liste Oluştur
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newListController,
                          decoration: InputDecoration(
                            hintText: '+ Yeni liste adı (Örn: Sonbahar Planı)',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: BeenHereColors.textSecondary,
                            ),
                            isDense: true,
                            filled: true,
                            fillColor: BeenHereColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: BeenHereColors.borderSubtle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          final created = widget.viewModel
                              .createNewFavoriteListAndAddPlace(
                            listTitle: newListController.text,
                            placeId: place.id,
                          );
                          if (created != null) {
                            newListController.clear();
                          }
                        },
                        child: const Text('Oluştur'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Mekanın İlintili Olduğu Rotalar Çekmecesi (Bottom Sheet)
  void _showRelatedRoutesDrawer(
    BuildContext context,
    PlaceDiscoveryItem place,
    List<PublishedRouteFeedItem> relatedRoutes,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BeenHereColors.primaryCompass
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.route_rounded,
                      color: BeenHereColors.primaryCompass,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Bu mekanın yer aldığı ${relatedRoutes.length} yayınlanmış gezgin rotası',
                          style: TextStyle(
                            fontSize: 12,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (relatedRoutes.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Bu mekan henüz yayınlanmış bir rotaya eklenmemiş.',
                    style: TextStyle(color: BeenHereColors.textSecondary),
                  ),
                )
              else
                for (final route in relatedRoutes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => RouteDetailScreen(
                              route: route,
                              viewModel: widget.homeFeedViewModel,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BeenHereColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BeenHereColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rota Kapak Görseli
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: route.featuredMediaUrls.isNotEmpty
                                    ? Image.network(
                                        route.featuredMediaUrls.first,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: BeenHereColors.surface,
                                          child: Icon(
                                            Icons.map_rounded,
                                            color:
                                                BeenHereColors.primaryCompass,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: BeenHereColors.surface,
                                        child: Icon(
                                          Icons.map_rounded,
                                          color: BeenHereColors.primaryCompass,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Rota Bilgileri
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    route.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: BeenHereColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${route.authorDisplayName} (@${route.authorUsername})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: BeenHereColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${route.durationDays} Gün',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: BeenHereColors.goldLeague,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• \$${route.estimatedBudgetUsd.round()}',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: BeenHereColors.verifiedEmerald,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${route.stops.length} Durak',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: BeenHereColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 15,
                              color: BeenHereColors.primaryCompass,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Listenin sonunda görünen "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara" kartı
class _NotFoundGoogleFallbackCard extends StatelessWidget {
  const _NotFoundGoogleFallbackCard({
    required this.searchQuery,
    required this.searchMode,
    required this.hasAnyResults,
    required this.onTapGoogleSearch,
  });

  final String searchQuery;
  final PlaceSearchMode searchMode;
  final bool hasAnyResults;
  final VoidCallback onTapGoogleSearch;

  @override
  Widget build(BuildContext context) {
    final isNearby = searchMode == PlaceSearchMode.nearby;
    final cleanQuery = searchQuery.trim();

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BeenHereColors.primaryCompass.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: BeenHereColors.primaryCompass.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_location_alt_rounded,
                  color: BeenHereColors.primaryCompass,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aradığınız mekanı bulamadınız mı?',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isNearby
                          ? 'Yakın çevrenizde henüz listelenmemiş noktaları Google Haritalar üzerinden anında çekebilirsiniz.'
                          : cleanQuery.isEmpty
                              ? 'Aradığınız mekan yerel listede yoksa en az 3 harf yazarak Google Haritalar\'da arayabilirsiniz.'
                              : '"$cleanQuery" için Google Haritalar (Places API) veritabanını sorgulayabilirsiniz.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: BeenHereColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onTapGoogleSearch,
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(
                cleanQuery.length >= 3
                    ? '"$cleanQuery" İçin Google Haritalar\'da Ara'
                    : 'Google Haritalar\'da Ara',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
