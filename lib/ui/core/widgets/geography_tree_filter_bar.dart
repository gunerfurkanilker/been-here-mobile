import 'package:flutter/material.dart';
import '../../../domain/models/route_feed_models.dart';
import '../filters/geography_tree_filter_mixin.dart';
import '../theme/been_here_theme.dart';

/// Anasayfa ve Arama ekranlarının ortak kullandığı Birleştirilmiş Üst Filtre & Arama Bileşeni:
/// - [Yakınımdaki Konumlar (🎯)] + [Dünya/Bölge Ağacı Filtresi (🌍)] + [Metin Arama Kutusu] + [5sn Knob'lu Ara (🔍)]
/// - Hemen altında aktif Anlık Konum (öncelikli) veya Seçili Ülke/Şehir durum şeridi
/// - Tıklandığında alttan açılan Akıllı Aramalı Hiyerarşik Coğrafya Ağacı Çekmecesi.
enum _FilterBarPanelMode {
  summary,
  search,
  budgetRange,
}

class GeographyTreeFilterBar extends StatefulWidget {
  const GeographyTreeFilterBar({
    super.key,
    required this.filterModel,
    required this.resultCountLabelBuilder,
    this.searchHintText = 'Mekan, şehir veya etiket ara...',
    this.showNearbyButton = true,
    this.showBudgetFilter = false,
  });

  final GeographyTreeFilterMixin filterModel;

  /// Çekmecenin en altındaki "Uygula (...)" butonunda canlı gösterilecek sayaç etiketi
  /// Örn: () => '${viewModel.feedRoutes.length} Rota' veya () => '${vm.geographyFilteredPlacesCount} Mekan'
  final String Function() resultCountLabelBuilder;

  final String searchHintText;

  /// Yakınımdaki Konumlar (Anlık Konum) butonu gösterilsin mi?
  /// (Rotalar akışında false, Mekanlar aramasında true)
  final bool showNearbyButton;

  /// Rotalar için Çift Taraflı Bütçe Aralığı (RangeSlider) filtresi gösterilsin mi?
  /// (Rotalar akışında true, Mekanlar aramasında false)
  final bool showBudgetFilter;

  /// Alttan Yükselen Hiyerarşik Coğrafya Ağacı Çekmecesini (Kıta > Ülke > Şehir) açar.
  static void showFilterDrawer(
    BuildContext context, {
    required GeographyTreeFilterMixin filterModel,
    required String Function() resultCountLabelBuilder,
  }) {
    filterModel.clearTreeSearchQuery();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GeographyTreeFilterDrawerSheet(
        filterModel: filterModel,
        resultCountLabelBuilder: resultCountLabelBuilder,
      ),
    );
  }

  @override
  State<GeographyTreeFilterBar> createState() => _GeographyTreeFilterBarState();
}

class _GeographyTreeFilterBarState extends State<GeographyTreeFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  _FilterBarPanelMode _panelMode = _FilterBarPanelMode.summary;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.filterModel.draftSearchInput;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearchBox() {
    setState(() {
      _panelMode = _FilterBarPanelMode.search;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _openBudgetRangePanel() {
    _searchFocusNode.unfocus();
    setState(() {
      _panelMode = _FilterBarPanelMode.budgetRange;
    });
  }

  void _closeExpandedPanel() {
    _searchFocusNode.unfocus();
    setState(() {
      _panelMode = _FilterBarPanelMode.summary;
    });
  }

  void _triggerManualSearch() {
    final executed = widget.filterModel.executeTextSearchNow();
    if (!executed) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text(
            '⚠️ Arama yapabilmek için lütfen en az 3 karakter girin.',
          ),
        ),
      );
      _searchFocusNode.requestFocus();
      return;
    }
    _closeExpandedPanel();
  }

  void _openDrawer() {
    GeographyTreeFilterBar.showFilterDrawer(
      context,
      filterModel: widget.filterModel,
      resultCountLabelBuilder: widget.resultCountLabelBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.filterModel;
    final isNearbyMode = widget.showNearbyButton && vm.isNearbyMode;
    final isGlobal = vm.isGlobalSelected;
    final appliedQuery = vm.committedSearchQuery.trim();
    final isBudgetActive = widget.showBudgetFilter && vm.isBudgetFilterActive;
    final isSummaryMode = _panelMode == _FilterBarPanelMode.summary;

    // Dışarıdan clearSearchInput çağrıldığında controller senkronizasyonu
    if (vm.draftSearchInput.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: isSummaryMode ? 38 : 44,
        decoration: BoxDecoration(
          color: isNearbyMode && isSummaryMode
              ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.12)
              : ((!isGlobal || isBudgetActive) && isSummaryMode
                  ? BeenHereColors.primaryCompass.withValues(alpha: 0.10)
                  : BeenHereColors.surface.withValues(alpha: 0.85)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNearbyMode
                ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.45)
                : (!isGlobal ||
                        isBudgetActive ||
                        _panelMode == _FilterBarPanelMode.budgetRange)
                    ? BeenHereColors.primaryCompass.withValues(alpha: 0.5)
                    : BeenHereColors.borderSubtle,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: switch (_panelMode) {
          _FilterBarPanelMode.search => _buildExpandedSearchRow(vm),
          _FilterBarPanelMode.budgetRange => _buildExpandedBudgetRangeRow(vm),
          _FilterBarPanelMode.summary => _buildCompactFilterSummaryRow(
              vm: vm,
              isNearbyMode: isNearbyMode,
              isGlobal: isGlobal,
              appliedQuery: appliedQuery,
              isBudgetActive: isBudgetActive,
            ),
        },
      ),
    );
  }

  /// Normal mod: Sol tarafta aktif filtreyi (Anlık Konum veya Seçili Bölge/Ülke/Şehir + Bütçe & Arama Etiketi) gösterir,
  /// sağ tarafta ise kompakt [Anlık Konum], [Dünya Filtresi], [Bütçe Filtresi] ve [Büyüteç (Arama Aç)] ikon butonları yer alır.
  Widget _buildCompactFilterSummaryRow({
    required GeographyTreeFilterMixin vm,
    required bool isNearbyMode,
    required bool isGlobal,
    required String appliedQuery,
    required bool isBudgetActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SOL / ORTA: Aktif Filtre Özeti (Tıklanınca bölge çekmecesini açar)
        Expanded(
          child: InkWell(
            onTap: _openDrawer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              child: Row(
                children: [
                  Icon(
                    isNearbyMode
                        ? Icons.location_on_rounded
                        : Icons.filter_alt_outlined,
                    size: 15,
                    color: isNearbyMode
                        ? BeenHereColors.verifiedEmerald
                        : (isGlobal
                            ? BeenHereColors.textSecondary
                            : BeenHereColors.primaryCompass),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isNearbyMode
                          ? vm.detectedLocationLabel
                          : vm.geographyFilterButtonTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isNearbyMode
                            ? BeenHereColors.verifiedEmerald
                            : (isGlobal
                                ? BeenHereColors.textPrimary
                                : BeenHereColors.primaryCompass),
                      ),
                    ),
                  ),
                  if (isNearbyMode) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'Anlık Konum',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BeenHereColors.verifiedEmerald,
                      ),
                    ),
                  ] else if (!isGlobal) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: vm.resetToGlobal,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ),
                  ],

                  // Aktif bütçe aralığı varsa kompakt chip olarak göster
                  if (isBudgetActive) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _openBudgetRangePanel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: BeenHereColors.primaryCompass
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              vm.budgetFilterCompactLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: BeenHereColors.primaryCompass,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: vm.resetBudgetFilter,
                              child: const Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: BeenHereColors.primaryCompass,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Eğer aktif bir metin araması varsa kompakt chip olarak göster
                  if (appliedQuery.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.primaryCompass
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '"$appliedQuery"',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: BeenHereColors.primaryCompass,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              vm.clearSearchInput();
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: BeenHereColors.primaryCompass,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // SAĞ 1 (Sadece Mekanlar ekranında aktif): Anlık Konum İkon Butonu
        if (widget.showNearbyButton) ...[
          Container(
            width: 1,
            color: BeenHereColors.borderSubtle.withValues(alpha: 0.7),
          ),
          Tooltip(
            message: 'Yakınımdaki Konumlar (Anlık Konum)',
            child: Material(
              color: isNearbyMode
                  ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.22)
                  : Colors.transparent,
              child: InkWell(
                onTap: vm.toggleNearbySearch,
                child: SizedBox(
                  width: 38,
                  child: Center(
                    child: Icon(
                      Icons.my_location_rounded,
                      size: 17,
                      color: isNearbyMode
                          ? BeenHereColors.verifiedEmerald
                          : BeenHereColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        Container(
          width: 1,
          color: BeenHereColors.borderSubtle.withValues(alpha: 0.7),
        ),

        // SAĞ 2: Dünya / Coğrafya Ağacı Filtresi İkon Butonu
        Tooltip(
          message: 'Bölge, Ülke ve Şehir Filtresi',
          child: Material(
            color: !isGlobal && !isNearbyMode
                ? BeenHereColors.primaryCompass.withValues(alpha: 0.18)
                : Colors.transparent,
            child: InkWell(
              onTap: _openDrawer,
              child: SizedBox(
                width: 38,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 17,
                        color: !isGlobal
                            ? (isNearbyMode
                                ? BeenHereColors.primaryCompass
                                    .withValues(alpha: 0.65)
                                : BeenHereColors.primaryCompass)
                            : BeenHereColors.textSecondary,
                      ),
                      if (!isGlobal)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: BoxDecoration(
                              color: isNearbyMode
                                  ? BeenHereColors.goldLeague
                                  : BeenHereColors.primaryCompass,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // SAĞ 3 (Sadece Rotalar ekranında aktif): Bütçe Aralığı Filtresi İkon Butonu
        if (widget.showBudgetFilter) ...[
          Container(
            width: 1,
            color: BeenHereColors.borderSubtle.withValues(alpha: 0.7),
          ),
          Tooltip(
            message: 'Bütçe Aralığı Filtresi',
            child: Material(
              color: isBudgetActive
                  ? BeenHereColors.primaryCompass.withValues(alpha: 0.18)
                  : Colors.transparent,
              child: InkWell(
                onTap: _openBudgetRangePanel,
                child: SizedBox(
                  width: 38,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 17,
                          color: isBudgetActive
                              ? BeenHereColors.primaryCompass
                              : BeenHereColors.textSecondary,
                        ),
                        if (isBudgetActive)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: const BoxDecoration(
                                color: BeenHereColors.primaryCompass,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        Container(
          width: 1,
          color: BeenHereColors.borderSubtle.withValues(alpha: 0.7),
        ),

        // SAĞ 4: Büyüteç İkonu (Tıklanınca Arama Kutusunu Açar)
        Tooltip(
          message: 'Arama Kutusunu Aç',
          child: Material(
            color: appliedQuery.isNotEmpty || vm.isWaitingForDebounce
                ? BeenHereColors.primaryCompass.withValues(alpha: 0.16)
                : Colors.transparent,
            child: InkWell(
              onTap: _openSearchBox,
              child: SizedBox(
                width: 38,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (vm.isWaitingForDebounce)
                        TweenAnimationBuilder<double>(
                          key: ValueKey<int>(vm.debounceCycleId),
                          tween: Tween<double>(begin: 1.0, end: 0.0),
                          duration:
                              GeographyTreeFilterMixin.searchDebounceDuration,
                          builder: (context, progress, _) {
                            return SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.2,
                                backgroundColor: BeenHereColors.primaryCompass
                                    .withValues(alpha: 0.18),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  BeenHereColors.primaryCompass,
                                ),
                              ),
                            );
                          },
                        ),
                      Icon(
                        Icons.search_rounded,
                        size: 17,
                        color: appliedQuery.isNotEmpty || vm.isWaitingForDebounce
                            ? BeenHereColors.primaryCompass
                            : BeenHereColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Bütçe ikonuna basıldığında açılan Çift Taraflı RangeSlider satırı
  Widget _buildExpandedBudgetRangeRow(GeographyTreeFilterMixin vm) {
    final minVal = vm.selectedMinBudgetTl;
    final maxVal = vm.selectedMaxBudgetTl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SOL: Bütçe Filtresini Kapat (Kompakt Filtre Şeridine Dön)
        Tooltip(
          message: 'Bütçe Filtresini Kapat',
          child: InkWell(
            onTap: _closeExpandedPanel,
            child: const SizedBox(
              width: 36,
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: BeenHereColors.textSecondary,
                ),
              ),
            ),
          ),
        ),

        Container(
          width: 1,
          color: BeenHereColors.borderSubtle,
        ),

        // Alt Sınır Etiketi (Örn: ₺0)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Center(
            child: Text(
              GeographyTreeFilterMixin.formatTlCurrency(minVal),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BeenHereColors.textPrimary,
              ),
            ),
          ),
        ),

        // ORTA: Çift Taraflı Bütçe RangeSlider (Paylaşılan görseldeki dairesel halka thumb stiliyle)
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              activeTrackColor: BeenHereColors.primaryCompass,
              inactiveTrackColor:
                  BeenHereColors.textSecondary.withValues(alpha: 0.25),
              overlayColor:
                  BeenHereColors.primaryCompass.withValues(alpha: 0.14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              rangeThumbShape: const _HollowCircleRangeThumbShape(
                thumbRadius: 9.0,
                borderWidth: 2.2,
              ),
            ),
            child: RangeSlider(
              values: RangeValues(minVal, maxVal),
              min: GeographyTreeFilterMixin.minBudgetLimitTl,
              max: GeographyTreeFilterMixin.maxBudgetLimitTl,
              divisions: 40, // 2.500 ₺ adımlar
              onChanged: (values) {
                vm.updateBudgetRange(values.start, values.end);
              },
            ),
          ),
        ),

        // Üst Sınır Etiketi (Örn: ₺100.000)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Text(
              GeographyTreeFilterMixin.formatTlCurrency(maxVal),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: BeenHereColors.textPrimary,
              ),
            ),
          ),
        ),

        if (vm.isBudgetFilterActive) ...[
          Container(
            width: 1,
            color: BeenHereColors.borderSubtle,
          ),
          Tooltip(
            message: 'Bütçeyi Sıfırla',
            child: InkWell(
              onTap: vm.resetBudgetFilter,
              child: const SizedBox(
                width: 34,
                child: Center(
                  child: Icon(
                    Icons.restart_alt_rounded,
                    size: 16,
                    color: BeenHereColors.primaryCompass,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Büyütece basıldığında açılan metin arama satırı
  Widget _buildExpandedSearchRow(GeographyTreeFilterMixin vm) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SOL: Arama Kutusunu Kapat (Kompakt Filtre Şeridine Dön)
        Tooltip(
          message: 'Aramayı Kapat',
          child: InkWell(
            onTap: _closeExpandedPanel,
            child: const SizedBox(
              width: 38,
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: BeenHereColors.textSecondary,
                ),
              ),
            ),
          ),
        ),

        Container(
          width: 1,
          color: BeenHereColors.borderSubtle,
        ),

        // ORTA: Arama TextField
        Expanded(
          child: Center(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              textAlignVertical: TextAlignVertical.center,
              onChanged: vm.onSearchInputChanged,
              onSubmitted: (_) => _triggerManualSearch(),
              style: const TextStyle(
                fontSize: 13,
                color: BeenHereColors.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                hoverColor: Colors.transparent,
                hintText: widget.searchHintText,
                hintStyle: const TextStyle(
                  fontSize: 12.5,
                  color: BeenHereColors.textSecondary,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: vm.draftSearchInput.isNotEmpty
                    ? IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: BeenHereColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          vm.clearSearchInput();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),

        Container(
          width: 1,
          color: BeenHereColors.borderSubtle,
        ),

        // SAĞ: Ara Butonu + 5 Sn Dairesel Azalan Knob Halkası
        Tooltip(
          message: 'Ara',
          child: Material(
            color: BeenHereColors.primaryCompass.withValues(alpha: 0.16),
            child: InkWell(
              onTap: _triggerManualSearch,
              child: SizedBox(
                width: 44,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (vm.isWaitingForDebounce)
                        TweenAnimationBuilder<double>(
                          key: ValueKey<int>(vm.debounceCycleId),
                          tween: Tween<double>(
                            begin: 1.0,
                            end: 0.0,
                          ),
                          duration:
                              GeographyTreeFilterMixin.searchDebounceDuration,
                          builder: (context, progress, _) {
                            return SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.3,
                                backgroundColor: BeenHereColors.primaryCompass
                                    .withValues(alpha: 0.18),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  BeenHereColors.primaryCompass,
                                ),
                              ),
                            );
                          },
                        ),
                      const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: BeenHereColors.primaryCompass,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GeographyTreeFilterDrawerSheet extends StatefulWidget {
  const _GeographyTreeFilterDrawerSheet({
    required this.filterModel,
    required this.resultCountLabelBuilder,
  });

  final GeographyTreeFilterMixin filterModel;
  final String Function() resultCountLabelBuilder;

  @override
  State<_GeographyTreeFilterDrawerSheet> createState() =>
      _GeographyTreeFilterDrawerSheetState();
}

class _GeographyTreeFilterDrawerSheetState
    extends State<_GeographyTreeFilterDrawerSheet> {
  final TextEditingController _treeSearchController = TextEditingController();

  @override
  void dispose() {
    _treeSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return ListenableBuilder(
      listenable: widget.filterModel,
      builder: (context, _) {
        final vm = widget.filterModel;
        final isGlobal = vm.isGlobalSelected;
        final filteredContinents = vm.filteredContinentsForTree;
        final hasTreeQuery = vm.treeSearchQuery.trim().isNotEmpty;

        return Container(
          height: screenHeight * 0.85,
          decoration: const BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(
              top: BorderSide(
                color: BeenHereColors.borderSubtle,
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tutamaç (Drag Handle)
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Üst Başlık
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BeenHereColors.primaryCompass
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: BeenHereColors.primaryCompass,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bölge, Ülke ve Şehir Filtresi',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Kıta veya ülke kutusunu işaretlerseniz alt noktaların tamamı seçilir.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: BeenHereColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // AĞAÇ İÇİ AKILLI ARAMA KUTUSU (Kıta, Ülke veya Şehir Ara -> Otomatik Açılım)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: BeenHereColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: hasTreeQuery
                          ? BeenHereColors.primaryCompass.withValues(alpha: 0.7)
                          : BeenHereColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.filter_list_rounded,
                        size: 19,
                        color: hasTreeQuery
                            ? BeenHereColors.primaryCompass
                            : BeenHereColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Center(
                          child: TextField(
                            controller: _treeSearchController,
                            onChanged: vm.updateTreeSearchQuery,
                            textAlignVertical: TextAlignVertical.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: BeenHereColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Kıta, ülke veya şehir ara (Örn: İzmir, İtalya)...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: BeenHereColors.textSecondary,
                              ),
                              filled: false,
                              hoverColor: Colors.transparent,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      if (hasTreeQuery)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.cancel_rounded,
                            size: 18,
                            color: BeenHereColors.textSecondary,
                          ),
                          onPressed: () {
                            _treeSearchController.clear();
                            vm.clearTreeSearchQuery();
                          },
                        )
                      else
                        const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: BeenHereColors.borderSubtle),

              // Hiyerarşik Ağaç Listesi
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    // 0. GLOBAL (TÜM DÜNYA) SATIRI (Ağaç araması boşken gösterilir)
                    if (!hasTreeQuery) ...[
                      InkWell(
                        onTap: vm.resetToGlobal,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isGlobal
                                ? BeenHereColors.primaryCompass
                                    .withValues(alpha: 0.16)
                                : BeenHereColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isGlobal
                                  ? BeenHereColors.primaryCompass
                                  : BeenHereColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isGlobal
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: isGlobal
                                    ? BeenHereColors.primaryCompass
                                    : BeenHereColors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '🌍 Global (Tüm Dünya)',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (isGlobal)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BeenHereColors.primaryCompass
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Varsayılan',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 1. KITALAR DÖNGÜSÜ (Filtrelenmiş)
                    if (filteredContinents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.travel_explore_rounded,
                              size: 38,
                              color: BeenHereColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${vm.treeSearchQuery}" ile eşleşen kıta, ülke veya şehir bulunamadı.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final continent in filteredContinents)
                        _buildContinentTreeSection(vm, continent),
                  ],
                ),
              ),

              // Alt Sabit Aksiyon Çubuğu
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: const BoxDecoration(
                  color: BeenHereColors.surface,
                  border: Border(
                    top: BorderSide(color: BeenHereColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: isGlobal ? null : vm.resetToGlobal,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Global\'e Dön'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          'Uygula (${widget.resultCountLabelBuilder()})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
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
    );
  }

  /// Seviye 1: Kıta Ağaç Düğümü
  Widget _buildContinentTreeSection(
    GeographyTreeFilterMixin vm,
    ContinentFilter continent,
  ) {
    final isChecked = vm.isContinentChecked(continent);
    final isExpanded = vm.isContinentExpanded(continent);
    final partialBadge = vm.getContinentPartialSelectionBadge(continent);
    final countries = vm.getFilteredCountriesForTree(continent);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: BeenHereColors.surfaceElevated.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? BeenHereColors.verifiedEmerald
              : partialBadge != null
                  ? BeenHereColors.goldLeague.withValues(alpha: 0.65)
                  : BeenHereColors.borderSubtle,
          width: isChecked || partialBadge != null ? 1.3 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (isChecked) {
                vm.toggleContinentCheckbox(continent);
              } else {
                vm.toggleContinentExpanded(continent);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: BeenHereColors.verifiedEmerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (_) => vm.toggleContinentCheckbox(continent),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      continent.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isChecked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.verifiedEmerald
                            .withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tüm Kıta Dahil',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BeenHereColors.verifiedEmerald,
                        ),
                      ),
                    )
                  else ...[
                    if (partialBadge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: BeenHereColors.goldLeague
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          partialBadge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BeenHereColors.goldLeague,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Text(
                        '${countries.length} Ülke',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: BeenHereColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isChecked && isExpanded) ...[
            const Divider(height: 1, color: BeenHereColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 10),
              child: Column(
                children: [
                  for (final country in countries)
                    _buildCountryTreeNode(vm, country),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Seviye 2: Ülke Ağaç Düğümü
  Widget _buildCountryTreeNode(
    GeographyTreeFilterMixin vm,
    CountryFilterOption country,
  ) {
    final isCountryChecked = vm.isCountryChecked(country.code);
    final isCountryExpanded = vm.isCountryExpanded(country.code);
    final cityPartialBadge = vm.getCountryPartialSelectionBadge(country.code);
    final cities = vm.getFilteredCitiesForTree(country);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: BeenHereColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCountryChecked
              ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.6)
              : cityPartialBadge != null
                  ? BeenHereColors.goldLeague.withValues(alpha: 0.5)
                  : BeenHereColors.borderSubtle.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              if (isCountryChecked) {
                vm.toggleCountryCheckbox(country.code);
              } else {
                vm.toggleCountryExpanded(country.code);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: isCountryChecked,
                    activeColor: BeenHereColors.verifiedEmerald,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (_) => vm.toggleCountryCheckbox(country.code),
                  ),
                  Text(
                    '${country.flagEmoji} ${country.nameTr}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isCountryChecked)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.verifiedEmerald
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'Tüm Şehirler Dahil',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: BeenHereColors.verifiedEmerald,
                        ),
                      ),
                    )
                  else ...[
                    if (cityPartialBadge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: BeenHereColors.goldLeague
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          cityPartialBadge,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: BeenHereColors.goldLeague,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ] else ...[
                      Text(
                        '${cities.length} Şehir',
                        style: const TextStyle(
                          fontSize: 11,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      isCountryExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 19,
                      color: BeenHereColors.textSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isCountryChecked && isCountryExpanded && cities.isNotEmpty) ...[
            const Divider(height: 1, color: BeenHereColors.borderSubtle),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 12, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final city in cities)
                    Builder(
                      builder: (context) {
                        final isCitySelected = vm.isCityChecked(city);
                        return InkWell(
                          onTap: () => vm.toggleCityCheckbox(city),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isCitySelected
                                  ? BeenHereColors.verifiedEmerald
                                      .withValues(alpha: 0.22)
                                  : BeenHereColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCitySelected
                                    ? BeenHereColors.verifiedEmerald
                                    : BeenHereColors.borderSubtle,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCitySelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 16,
                                  color: isCitySelected
                                      ? BeenHereColors.verifiedEmerald
                                      : BeenHereColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCitySelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: BeenHereColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Paylaşılan taslaktaki gibi içi beyaz/açık dolgulu ve etrafı halkalı çift taraflı RangeSlider thumb şekli
class _HollowCircleRangeThumbShape extends RangeSliderThumbShape {
  const _HollowCircleRangeThumbShape({
    this.thumbRadius = 9.0,
    this.borderWidth = 2.2,
  });

  final double thumbRadius;
  final double borderWidth;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;

    // İç beyaz dolgu
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Dış halka çerçevesi
    final Paint borderPaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? BeenHereColors.primaryCompass
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, thumbRadius, fillPaint);
    canvas.drawCircle(center, thumbRadius - (borderWidth / 2), borderPaint);
  }
}
