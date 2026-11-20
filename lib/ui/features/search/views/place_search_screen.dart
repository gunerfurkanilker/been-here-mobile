import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain/models/place_discovery_models.dart';
import '../../../core/theme/been_here_theme.dart';
import '../../../core/widgets/geography_tree_filter_bar.dart';
import '../../home/view_models/home_feed_view_model.dart';
import '../../home/views/route_detail_screen.dart';
import '../view_models/place_search_view_model.dart';
import 'place_discovery_compact_card.dart';

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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onListScroll);
    _scheduleInitialPlacesLoad();
  }

  @override
  void didUpdateWidget(covariant PlaceSearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      _scheduleInitialPlacesLoad();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onListScroll)
      ..dispose();
    super.dispose();
  }

  void _scheduleInitialPlacesLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _maybeLoadInitialPlaces();
      }
    });
  }

  void _maybeLoadInitialPlaces() {
    final vm = widget.viewModel;
    final store = vm.placesStore;
    if (vm.isLiveBackendConfigured &&
        !vm.isUsingOfflineDemoFallback &&
        store != null &&
        !store.hasCompletedInitialLoad &&
        !store.isLoading &&
        store.errorMessage == null &&
        store.activePlaces.isEmpty) {
      unawaited(vm.initializePlaces());
    }
  }

  void _onListScroll() {
    if (!_scrollController.hasClients) return;
    final vm = widget.viewModel;
    if (!vm.hasMoreFeed || vm.isLoading || vm.isLoadingMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      unawaited(vm.loadMoreFeed());
    }
  }

  Future<void> _handleGoogleFallbackTap(BuildContext context) async {
    final vm = widget.viewModel;
    final messenger = ScaffoldMessenger.of(context);
    final query = vm.effectiveGoogleFallbackQuery;

    if ((vm.isUsingRemoteData || vm.searchMode == PlaceSearchMode.globalSearch) &&
        query.length < 3) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '⚠️ Google Haritalar araması için lütfen en az 3 karakter girin.',
          ),
        ),
      );
      return;
    }

    if (vm.isUsingRemoteData) {
      final fetched = await vm.fetchFromGoogleMapsFallbackAsync(
        customQuery: query,
      );
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      final mutationError = vm.mutationErrorMessage;
      if (mutationError != null && mutationError.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('⚠️ $mutationError'),
          ),
        );
        return;
      }
      if (fetched.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              '🗺️ "${fetched.first.name}" Google Haritalar\'dan çekilerek listeye eklendi!',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Google Haritalar üzerinde bu aramayla eşleşen yeni mekan bulunamadı.',
            ),
          ),
        );
      }
      return;
    }

    final created = vm.fetchFromGoogleMapsFallback();
    if (created != null) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
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

            // =================================================================
            // 2. YATAY KAYDIRILABİLİR UI KATEGORİ FİLTRE BARI
            // =================================================================
            _buildUiCategoryBar(vm),

            if (vm.isUsingOfflineDemoFallback)
              _buildStatusNoticeBanner(
                icon: PhosphorIcons.cloudSlash(PhosphorIconsStyle.duotone),
                message: 'Çevrimdışı örnek veriler görüntüleniyor.',
                actionLabel: 'Canlı Veriye Dön',
                onPressed: () => unawaited(vm.initializePlaces()),
              )
            else if (vm.errorMessage != null && places.isNotEmpty)
              _buildStatusNoticeBanner(
                icon: PhosphorIcons.warningCircle(PhosphorIconsStyle.duotone),
                message: vm.errorMessage!,
                actionLabel: 'Tekrar Dene',
                onPressed: () => unawaited(vm.refreshPlaces()),
              ),

            const SizedBox(height: 10),

            // =================================================================
            // 3. MEKAN KARTLARI LİSTESİ + LİSTE SONU "ARADIĞINIZ MEKANI BULAMADINIZ MI?" AKIŞI
            // =================================================================
            Expanded(
              child: _buildPlacesBody(
                context: context,
                vm: vm,
                places: places,
                isNearbyMode: isNearbyMode,
                showEndFallbackCard: showEndFallbackCard,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUiCategoryBar(PlaceSearchViewModel vm) {
    final selected = vm.selectedUiCategory;
    final options = <({
      String? code,
      String label,
      PhosphorIconData Function(PhosphorIconsStyle) iconBuilder,
    })>[
      (
        code: null,
        label: 'Tümü',
        iconBuilder: PhosphorIcons.squaresFour,
      ),
      (
        code: 'DESTINATION',
        label: 'Tarihi & Keşif',
        iconBuilder: PhosphorIcons.compass,
      ),
      (
        code: 'FOOD',
        label: 'Yeme & İçme',
        iconBuilder: PhosphorIcons.forkKnife,
      ),
      (
        code: 'ACCOMMODATION',
        label: 'Konaklama',
        iconBuilder: PhosphorIcons.bed,
      ),
      (
        code: 'ACTIVITY',
        label: 'Aktivite',
        iconBuilder: PhosphorIcons.mountains,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _buildUiCategoryChip(
                code: options[i].code,
                label: options[i].label,
                iconBuilder: options[i].iconBuilder,
                isSelected: options[i].code == null
                    ? (selected == null || selected.isEmpty)
                    : selected == options[i].code,
                onTap: () => unawaited(vm.setUiCategory(options[i].code)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUiCategoryChip({
    required String? code,
    required String label,
    required PhosphorIconData Function(PhosphorIconsStyle) iconBuilder,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey<String>('place_category_chip_${code ?? 'ALL'}'),
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? BeenHereColors.primaryCompass.withValues(alpha: 0.22)
                    : BeenHereColors.surface.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? BeenHereColors.primaryCompass
                      : BeenHereColors.borderSubtle.withValues(alpha: 0.85),
                  width: isSelected ? 1.25 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    iconBuilder(
                      isSelected
                          ? PhosphorIconsStyle.duotone
                          : PhosphorIconsStyle.regular,
                    ),
                    size: 15,
                    color: isSelected
                        ? BeenHereColors.primaryCompass
                        : BeenHereColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? BeenHereColors.textPrimary
                          : BeenHereColors.textSecondary,
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

  Widget _buildStatusNoticeBanner({
    required PhosphorIconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BeenHereColors.primaryCompass.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            icon,
            size: 16,
            color: BeenHereColors.primaryCompass,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: BeenHereColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesBody({
    required BuildContext context,
    required PlaceSearchViewModel vm,
    required List<PlaceDiscoveryItem> places,
    required bool isNearbyMode,
    required bool showEndFallbackCard,
  }) {
    if (vm.isLoading && places.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: BeenHereColors.primaryCompass),
            const SizedBox(height: 12),
            Text(
              'Mekanlar yükleniyor...',
              style: TextStyle(color: BeenHereColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (vm.errorMessage != null && places.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BeenHereColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BeenHereColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIcons.wifiSlash(PhosphorIconsStyle.duotone),
                  size: 42,
                  color: BeenHereColors.primaryCompass,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mekanlar Yüklenemedi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: BeenHereColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vm.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: () => unawaited(vm.refreshPlaces()),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tekrar Dene'),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.enableOfflineDemoFallback,
                      icon: const Icon(Icons.offline_pin_outlined, size: 18),
                      label: const Text('Örnek Verilerle Önizle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (places.isEmpty && !showEndFallbackCard) {
      return Center(
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
      );
    }

    final footerCount = (showEndFallbackCard ? 1 : 0) + (vm.isLoadingMore ? 1 : 0);
    final listView = ListView.builder(
      key: const PageStorageKey<String>('place-search-list'),
      controller: _scrollController,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 105),
      itemCount: places.length + footerCount,
      itemBuilder: (context, index) {
        if (vm.isLoadingMore && index == places.length + (showEndFallbackCard ? 1 : 0)) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }

        // Listenin sonuna gelindiğinde "Aradığınız mekanı bulamadınız mı?" kartı
        if (showEndFallbackCard && index == places.length) {
          return _NotFoundGoogleFallbackCard(
            searchQuery: vm.effectiveGoogleFallbackQuery,
            searchMode: vm.searchMode,
            hasAnyResults: places.isNotEmpty,
            promptText: vm.googleFetchPrompt,
            isLoading: vm.isMutating,
            onTapGoogleSearch: () => unawaited(_handleGoogleFallbackTap(context)),
          );
        }

        final place = places[index];
        final savedLists = vm.getListsContainingPlace(place.id);
        final addedUserRoutes = vm.getUserRoutesContainingPlace(place.id);
        final relatedRoutes = vm.getRelatedRoutesForPlace(place);

        return PlaceDiscoveryCompactCard(
          key: ValueKey<String>('place-card-${place.id}'),
          place: place,
          savedLists: savedLists,
          addedUserRoutes: addedUserRoutes,
          relatedRoutes: relatedRoutes,
          showDistanceBadge: isNearbyMode || place.hasDistance,
          onTapDetailButton: () =>
              _showPlaceDetailAndContributionModal(context, place),
          onTapFlagButton: () => _showSahibindenFlagModal(context, place),
          onTapAddToRouteButton: () => _showAddToRouteModal(context, place),
          onTapRelatedRoutesButton: () =>
              _showRelatedRoutesDrawer(context, place),
        );
      },
    );

    if (!vm.isLiveBackendConfigured) {
      return listView;
    }

    return RefreshIndicator(
      onRefresh: vm.refreshPlaces,
      child: listView,
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
    final parentMessenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _SahibindenFlagModalSheet(
          viewModel: widget.viewModel,
          place: place,
          parentMessenger: parentMessenger,
        );
      },
    );
  }

  /// Mekan Detayı & Topluluk Katkısı (Vibe Oylama & Saha Uyarısı Bildirme) Modalı
  void _showPlaceDetailAndContributionModal(
    BuildContext context,
    PlaceDiscoveryItem place,
  ) {
    final parentMessenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PlaceDetailContributionSheet(
          viewModel: widget.viewModel,
          initialPlace: place,
          parentMessenger: parentMessenger,
        );
      },
    );
  }

  /// Mekanın İlintili Olduğu Rotalar Çekmecesi (Bottom Sheet)
  void _showRelatedRoutesDrawer(
    BuildContext context,
    PlaceDiscoveryItem place,
  ) {
    if (widget.viewModel.isUsingRemoteData &&
        !widget.viewModel.hasLoadedRelatedRoutes(place.id)) {
      unawaited(widget.viewModel.loadRelatedRoutes(place.id));
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (sheetContext, _) {
            final vm = widget.viewModel;
            final relatedRoutes = vm.getRelatedRoutesForPlace(place);
            final isLoading = vm.isRelatedRoutesLoading(place.id);
            final headerCount = relatedRoutes.isNotEmpty
                ? relatedRoutes.length
                : place.relatedRouteIds.length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              decoration: BoxDecoration(
                color: BeenHereColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: BeenHereColors.textSecondary
                              .withValues(alpha: 0.4),
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
                                'Bu mekanın yer aldığı $headerCount yayınlanmış gezgin rotası',
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
                    if (isLoading && relatedRoutes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 10),
                              Text('İlintili rotalar yükleniyor...'),
                            ],
                          ),
                        ),
                      )
                    else if (relatedRoutes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: route.featuredMediaUrls.isNotEmpty
                                          ? Image.network(
                                              route.featuredMediaUrls.first,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Container(
                                                color: BeenHereColors.surface,
                                                child: Icon(
                                                  Icons.map_rounded,
                                                  color: BeenHereColors
                                                      .primaryCompass,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: BeenHereColors.surface,
                                              child: Icon(
                                                Icons.map_rounded,
                                                color: BeenHereColors
                                                    .primaryCompass,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                color:
                                                    BeenHereColors.goldLeague,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• \$${route.estimatedBudgetUsd.round()}',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: BeenHereColors
                                                    .verifiedEmerald,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• ${route.effectiveStopsCount} Durak',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: BeenHereColors
                                                    .textSecondary,
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
              ),
            );
          },
        );
      },
    );
  }
}

class _SahibindenFlagModalSheet extends StatefulWidget {
  const _SahibindenFlagModalSheet({
    required this.viewModel,
    required this.place,
    required this.parentMessenger,
  });

  final PlaceSearchViewModel viewModel;
  final PlaceDiscoveryItem place;
  final ScaffoldMessengerState parentMessenger;

  @override
  State<_SahibindenFlagModalSheet> createState() =>
      _SahibindenFlagModalSheetState();
}

class _SahibindenFlagModalSheetState extends State<_SahibindenFlagModalSheet> {
  final TextEditingController _newListController = TextEditingController();
  String? _expandedPreviewListId;
  String? _localErrorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel.isUsingRemoteData &&
        widget.viewModel.favoriteLists.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.viewModel.isUsingRemoteData &&
            widget.viewModel.favoriteLists.isEmpty) {
          unawaited(widget.viewModel.loadMyPlaceLists());
        }
      });
    }
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  void _showMutationError(String message) {
    if (!mounted) return;
    setState(() {
      _localErrorMessage = message;
    });
    widget.parentMessenger.hideCurrentSnackBar();
    widget.parentMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('⚠️ $message'),
      ),
    );
  }

  Future<void> _handleToggleList(String listId) async {
    setState(() {
      _localErrorMessage = null;
    });
    final ok = await widget.viewModel.togglePlaceInListAsync(
      listId: listId,
      placeId: widget.place.id,
    );
    if (!ok) {
      final err = widget.viewModel.mutationErrorMessage ??
          'Liste güncellenirken bir hata oluştu.';
      _showMutationError(err);
    }
  }

  Future<void> _handleCreateList() async {
    setState(() {
      _localErrorMessage = null;
    });
    final created = await widget.viewModel.createNewFavoriteListAndAddPlaceAsync(
      listTitle: _newListController.text,
      placeId: widget.place.id,
    );
    if (!mounted) return;
    final err = widget.viewModel.mutationErrorMessage;
    if (created != null) {
      _newListController.clear();
    }
    if (err != null && err.isNotEmpty) {
      _showMutationError(err);
    } else if (created == null) {
      _showMutationError('Liste oluşturulamadı.');
    }
  }

  Future<void> _handleDeleteList(String listId) async {
    setState(() {
      _localErrorMessage = null;
    });
    final deleted = await widget.viewModel.deleteFavoriteListAsync(listId);
    if (!mounted) return;
    if (!deleted) {
      _showMutationError(
        widget.viewModel.mutationErrorMessage ?? 'Liste silinemedi.',
      );
    } else if (_expandedPreviewListId == listId) {
      setState(() {
        _expandedPreviewListId = null;
      });
    }
  }

  void _togglePreviewList(String listId) {
    final nextId = _expandedPreviewListId == listId ? null : listId;
    setState(() {
      _expandedPreviewListId = nextId;
    });
    if (nextId != null && widget.viewModel.isUsingRemoteData) {
      unawaited(widget.viewModel.loadPlaceListDetails(nextId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final lists = vm.favoriteLists;
        final quota = vm.listsQuota;
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

        String quotaSubtitle = 'Özel Mekan Listenize Kaydedin (Flag)';
        if (quota != null) {
          quotaSubtitle = quota.isPremium
              ? 'Premium: Sınırsız Liste & Mekan'
              : 'Free Plan: ${lists.length}/${quota.maxLists ?? 3} Liste • Maks. ${quota.maxPlacesPerList ?? 10} mekan/liste';
        }

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottomInset),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: BeenHereColors.borderSubtle,
                width: 1.2,
              ),
            ),
          ),
          child: SingleChildScrollView(
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
                            widget.place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                          Text(
                            quotaSubtitle,
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
                if (_localErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localErrorMessage!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Mevcut Özel Listeler
                for (final list in lists) ...[
                  Builder(
                    builder: (context) {
                      final isSelected = list.containsPlace(widget.place.id);
                      final isExpanded = _expandedPreviewListId == list.id;
                      final detail = vm.getListDetails(list.id);
                      final isDetailLoading = vm.isListDetailLoading(list.id);
                      final countLabel = list.maxPlacesPerList != null
                          ? '${list.effectiveItemCount}/${list.maxPlacesPerList} mekan kayıtlı'
                          : '${list.effectiveItemCount} mekan kayıtlı';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            InkWell(
                              onTap: vm.isMutating
                                  ? null
                                  : () => unawaited(_handleToggleList(list.id)),
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
                                            countLabel,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color:
                                                  BeenHereColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (vm.isUsingRemoteData) ...[
                                      IconButton(
                                        tooltip: 'Liste İçeriğini Gör',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () =>
                                            _togglePreviewList(list.id),
                                        icon: PhosphorIcon(
                                          isExpanded
                                              ? PhosphorIcons.eyeSlash(
                                                  PhosphorIconsStyle.duotone,
                                                )
                                              : PhosphorIcons.eye(
                                                  PhosphorIconsStyle.duotone,
                                                ),
                                          size: 18,
                                          color: BeenHereColors.textSecondary,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Listeyi Sil',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: vm.isMutating
                                            ? null
                                            : () => unawaited(
                                                  _handleDeleteList(list.id),
                                                ),
                                        icon: PhosphorIcon(
                                          PhosphorIcons.trash(
                                            PhosphorIconsStyle.duotone,
                                          ),
                                          size: 18,
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.85),
                                        ),
                                      ),
                                    ],
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
                            if (isExpanded)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: BeenHereColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: BeenHereColors.borderSubtle,
                                  ),
                                ),
                                child: isDetailLoading
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 8),
                                        child: Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                      )
                                    : (detail == null || detail.items.isEmpty)
                                        ? Text(
                                            'Bu listede henüz kayıtlı mekan yok.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  BeenHereColors.textSecondary,
                                            ),
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (final item in detail.items)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    bottom: 4,
                                                  ),
                                                  child: Text(
                                                    '• ${item.place?.name ?? item.placeId}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: BeenHereColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                              ),
                          ],
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
                        controller: _newListController,
                        decoration: InputDecoration(
                          hintText: vm.isUsingRemoteData
                              ? '+ Yeni liste (Boş: ${vm.suggestedNextListTitle})'
                              : '+ Yeni liste adı (Örn: Sonbahar Planı)',
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
                      onPressed:
                          vm.isMutating ? null : () => unawaited(_handleCreateList()),
                      child: vm.isMutating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Oluştur'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlaceDetailContributionSheet extends StatefulWidget {
  const _PlaceDetailContributionSheet({
    required this.viewModel,
    required this.initialPlace,
    required this.parentMessenger,
  });

  final PlaceSearchViewModel viewModel;
  final PlaceDiscoveryItem initialPlace;
  final ScaffoldMessengerState parentMessenger;

  @override
  State<_PlaceDetailContributionSheet> createState() =>
      _PlaceDetailContributionSheetState();
}

class _PlaceDetailContributionSheetState
    extends State<_PlaceDetailContributionSheet> {
  static const List<String> _presetVibes = <String>[
    'Gün Batımı',
    'Fotoğraflık',
    'Sakin',
    'Romantik',
    'Lokal Lezzet',
    'Manzaralı',
  ];

  static const List<String> _presetWarnings = <String>[
    'Bilet Kuyruğu Uzun',
    'Nakit Gerekli',
    'Rezervasyon Şart',
    'Erken Kapanıyor',
    'Park Yeri Kısıtlı',
  ];

  final Set<String> _selectedVibes = <String>{};
  final Set<String> _selectedWarnings = <String>{};
  final TextEditingController _customVibeController = TextEditingController();
  final TextEditingController _customWarningController =
      TextEditingController();
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel.isUsingRemoteData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.viewModel.isUsingRemoteData) {
          unawaited(widget.viewModel.loadPlaceDetails(widget.initialPlace.id));
        }
      });
    }
  }

  @override
  void dispose() {
    _customVibeController.dispose();
    _customWarningController.dispose();
    super.dispose();
  }

  Future<void> _submitVibes() async {
    final vibes = <String>{
      ..._selectedVibes,
      if (_customVibeController.text.trim().isNotEmpty)
        _customVibeController.text.trim(),
    }.toList(growable: false);

    if (vibes.isEmpty) {
      _setFeedback('Lütfen en az bir vibe etiketi seçin veya yazın.', true);
      return;
    }

    final updated = await widget.viewModel.voteVibes(
      widget.initialPlace.id,
      vibes,
    );
    if (!mounted) return;
    if (updated != null) {
      _selectedVibes.clear();
      _customVibeController.clear();
      _setFeedback('Vibe oylamanız kaydedildi!', false);
    } else {
      _setFeedback(
        widget.viewModel.mutationErrorMessage ?? 'Vibe oylaması gönderilemedi.',
        true,
      );
    }
  }

  Future<void> _submitWarnings() async {
    final warnings = <String>{
      ..._selectedWarnings,
      if (_customWarningController.text.trim().isNotEmpty)
        _customWarningController.text.trim(),
    }.toList(growable: false);

    if (warnings.isEmpty) {
      _setFeedback('Lütfen en az bir saha uyarısı seçin veya yazın.', true);
      return;
    }

    final updated = await widget.viewModel.reportWarnings(
      widget.initialPlace.id,
      warnings,
    );
    if (!mounted) return;
    if (updated != null) {
      _selectedWarnings.clear();
      _customWarningController.clear();
      _setFeedback('Saha uyarınız toplulukla paylaşıldı!', false);
    } else {
      _setFeedback(
        widget.viewModel.mutationErrorMessage ?? 'Saha uyarısı gönderilemedi.',
        true,
      );
    }
  }

  void _setFeedback(String message, bool isError) {
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    widget.parentMessenger.hideCurrentSnackBar();
    widget.parentMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(isError ? '⚠️ $message' : '✅ $message'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final vm = widget.viewModel;
        final place = vm.getPlaceDetails(widget.initialPlace.id) ??
            widget.initialPlace;
        final isDetailLoading = vm.isPlaceDetailLoading(place.id);
        final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
        final availableVibes = <String>{
          ..._presetVibes,
          ...place.communityVibes,
        }.toList(growable: false);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottomInset),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${place.categoryLabel} • ${place.countryName}, ${place.city} • ★ ${place.averageRating.toStringAsFixed(1)} (${place.verifiedVisitCount} ziyaret)',
                            style: TextStyle(
                              fontSize: 12,
                              color: BeenHereColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isDetailLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                if (place.shortSummary.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    place.shortSummary,
                    style: TextStyle(
                      fontSize: 13,
                      color: BeenHereColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                if (_feedbackMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_feedbackIsError
                              ? Colors.redAccent
                              : BeenHereColors.verifiedEmerald)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_feedbackIsError
                                ? Colors.redAccent
                                : BeenHereColors.verifiedEmerald)
                            .withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _feedbackIsError
                            ? Colors.redAccent
                            : BeenHereColors.verifiedEmerald,
                      ),
                    ),
                  ),
                ],
                if (place.statusWarning != null ||
                    place.openingHoursWarning != null ||
                    place.communityWarningBadges.isNotEmpty ||
                    place.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Saha & Çalışma Uyarıları',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (place.statusWarning != null)
                    _buildWarningBannerLine(place.statusWarning!, isSevere: true),
                  if (place.openingHoursWarning != null)
                    _buildWarningBannerLine(place.openingHoursWarning!),
                  if (place.communityWarningBadges.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final badge in place.communityWarningBadges)
                          Chip(
                            label: Text('${badge.label} (${badge.votes} oy)'),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    )
                  else
                    for (final warning in place.warnings)
                      _buildWarningBannerLine(warning),
                ],
                const SizedBox(height: 14),
                Text(
                  'Topluluk Vibe Etiketleri',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: BeenHereColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (place.communityVibes.isEmpty)
                  Text(
                    'Henüz vibe etiketi eklenmemiş.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BeenHereColors.textSecondary,
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final vibe in place.communityVibes)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            place.communityVibeCounts.containsKey(vibe)
                                ? '#$vibe (${place.communityVibeCounts[vibe]})'
                                : '#$vibe',
                          ),
                        ),
                    ],
                  ),
                if (vm.isUsingRemoteData) ...[
                  const SizedBox(height: 14),
                  Divider(color: BeenHereColors.borderSubtle),
                  const SizedBox(height: 10),
                  Text(
                    'Vibe Oyla',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final vibe in availableVibes)
                        FilterChip(
                          label: Text(vibe),
                          selected: _selectedVibes.contains(vibe),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedVibes.add(vibe);
                              } else {
                                _selectedVibes.remove(vibe);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customVibeController,
                          decoration: const InputDecoration(
                            hintText: 'Özel vibe ekle...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed:
                            vm.isMutating ? null : () => unawaited(_submitVibes()),
                        child: const Text('Vibe Oyla'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Saha Uyarısı Bildir',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final warning in _presetWarnings)
                        FilterChip(
                          label: Text(warning),
                          selected: _selectedWarnings.contains(warning),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedWarnings.add(warning);
                              } else {
                                _selectedWarnings.remove(warning);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customWarningController,
                          decoration: const InputDecoration(
                            hintText: 'Özel saha uyarısı yaz...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: vm.isMutating
                            ? null
                            : () => unawaited(_submitWarnings()),
                        child: const Text('Uyarı Bildir'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningBannerLine(String text, {bool isSevere = false}) {
    final accent = isSevere ? Colors.redAccent : BeenHereColors.goldLeague;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIcons.warning(PhosphorIconsStyle.fill),
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BeenHereColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
    this.promptText = "Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara",
    this.isLoading = false,
  });

  final String searchQuery;
  final PlaceSearchMode searchMode;
  final bool hasAnyResults;
  final String promptText;
  final bool isLoading;
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
                              ? promptText
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
              onPressed: isLoading ? null : onTapGoogleSearch,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(
                isLoading
                    ? 'Google Haritalar\'da Aranıyor...'
                    : (cleanQuery.length >= 3
                        ? '"$cleanQuery" İçin Google Haritalar\'da Ara'
                        : 'Google Haritalar\'da Ara'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
