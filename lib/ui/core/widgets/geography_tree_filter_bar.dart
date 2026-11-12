import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/models/route_feed_models.dart';
import '../filters/been_here_search_filter_controller.dart';
import '../filters/geography_tree_filter_mixin.dart';
import '../theme/been_here_theme.dart';
import 'been_here_search_panel.dart';

/// Rotalar, Mekanlar ve Rota Oluşturma ekranlarının ortak kullandığı
/// Birleştirilmiş Üst Arama, Filtre & Hap Bileşeni:
/// - 52px büyük arama çubuğu (dokunulduğunda tam ekran `BeenHereSearchPanel` açılır)
/// - İsteğe bağlı sağ aksiyon butonları: Anlık Konum (`showNearbyButton`),
///   Coğrafya Ağacı Çekmecesi (`showTreeDrawerButton`), Bütçe Aralığı (`showBudgetFilter`)
/// - Hemen altında toggle edilebilir / kaldırılabilir filtre hapları (`Wrap`)
class GeographyTreeFilterBar extends StatefulWidget {
  const GeographyTreeFilterBar({
    super.key,
    required this.filterModel,
    this.resultCountLabelBuilder,
    this.searchHintText = 'Ülke, konum veya şehir ismi ile ara...',
    this.showNearbyButton = false,
    this.showBudgetFilter = false,
    this.showTreeDrawerButton = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.searchBarKey,
    this.budgetButtonKey,
  });

  final BeenHereSearchFilterController filterModel;

  /// Çekmece veya bütçe penceresindeki "Uygula (...)" butonunda canlı gösterilecek sayaç etiketi
  /// Örn: () => '${viewModel.geographyFilteredRoutesCount} Rota' veya () => '${vm.geographyFilteredPlacesCount} Mekan'
  final String Function()? resultCountLabelBuilder;

  final String searchHintText;

  /// Yakınımdaki Konumlar (Anlık Konum) butonu gösterilsin mi?
  /// (Rotalar akışında false, Mekanlar aramasında true)
  final bool showNearbyButton;

  /// Rotalar için Çift Taraflı Bütçe Aralığı (RangeSlider) filtresi gösterilsin mi?
  /// (Rotalar akışında true, Mekanlar aramasında false)
  final bool showBudgetFilter;

  /// Klasik Kıta > Ülke > Şehir çekmecesi ikonu ve durum çipi gösterilsin mi?
  final bool showTreeDrawerButton;

  final EdgeInsetsGeometry padding;
  final Key? searchBarKey;
  final Key? budgetButtonKey;

  /// Alttan Yükselen Hiyerarşik Coğrafya Ağacı Çekmecesini (Kıta > Ülke > Şehir) açar.
  static void showFilterDrawer(
    BuildContext context, {
    required GeographyTreeFilterMixin filterModel,
    String Function()? resultCountLabelBuilder,
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
  void _openSearchPanel(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BeenHereSearchPanel(
          controller: widget.filterModel,
          searchHintText: widget.searchHintText,
        ),
      ),
    );
  }

  void _openDrawer(GeographyTreeFilterMixin treeMixin) {
    GeographyTreeFilterBar.showFilterDrawer(
      context,
      filterModel: treeMixin,
      resultCountLabelBuilder: widget.resultCountLabelBuilder,
    );
  }

  void _openBudgetFilterSheet(BuildContext context) {
    final controller = widget.filterModel;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: controller,
          builder: (sheetContext, _) {
            final minVal = controller.selectedMinBudgetTl;
            final maxVal = controller.selectedMaxBudgetTl;
            final countLabel = widget.resultCountLabelBuilder?.call();

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: BeenHereColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: BeenHereColors.borderSubtle),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        PhosphorIcon(
                          PhosphorIconsDuotone.currencyDollar,
                          size: 20,
                          color: BeenHereColors.primaryCompass,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bütçe Aralığı Filtresi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                        ),
                        if (controller.isBudgetFilterActive)
                          TextButton(
                            onPressed: controller.resetBudgetFilter,
                            child: const Text('Sıfırla'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      controller.budgetFilterCompactLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BeenHereColors.primaryCompass,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RangeSlider(
                      values: RangeValues(minVal, maxVal),
                      min: GeographyTreeFilterMixin.minBudgetLimitTl,
                      max: GeographyTreeFilterMixin.maxBudgetLimitTl,
                      divisions: 40,
                      activeColor: BeenHereColors.primaryCompass,
                      inactiveColor:
                          BeenHereColors.textSecondary.withValues(alpha: 0.25),
                      onChanged: (values) {
                        controller.updateBudgetRange(values.start, values.end);
                      },
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: BeenHereColors.primaryCompass,
                        foregroundColor:
                            Theme.of(sheetContext).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        countLabel != null ? 'Uygula ($countLabel)' : 'Uygula',
                        style: const TextStyle(fontWeight: FontWeight.w800),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.filterModel,
      builder: (context, _) {
        final vm = widget.filterModel;
        final treeMixin = vm is GeographyTreeFilterMixin ? vm : null;
        final isNearbyMode = widget.showNearbyButton && vm.isNearbyMode;
        final isBudgetActive = widget.showBudgetFilter && vm.isBudgetFilterActive;
        final activeCount = vm.activeFilterCount +
            (isNearbyMode ? 1 : 0) +
            (treeMixin != null && !treeMixin.isGlobalSelected ? 1 : 0);

        final showLegacyTreeChip = widget.showTreeDrawerButton &&
            treeMixin != null &&
            !isNearbyMode &&
            (!vm.hasFilterPills || !treeMixin.isGlobalSelected);

        final showPillsSection =
            vm.hasFilterPills || isNearbyMode || showLegacyTreeChip;

        return Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. BÜYÜK 52px ARAMA ÇUBUĞU & SAĞ AKSİYON BUTONLARI
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: BeenHereColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isNearbyMode
                        ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.55)
                        : (activeCount > 0
                            ? BeenHereColors.primaryCompass
                                .withValues(alpha: 0.6)
                            : BeenHereColors.borderSubtle),
                    width: 1.1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: InkWell(
                        key: widget.searchBarKey,
                        onTap: () => _openSearchPanel(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsRegular.magnifyingGlass,
                                size: 20,
                                color: activeCount > 0
                                    ? BeenHereColors.primaryCompass
                                    : BeenHereColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.searchHintText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: BeenHereColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (vm.enabledFilterPillsCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BeenHereColors.primaryCompass
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${vm.enabledFilterPillsCount}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.showNearbyButton) ...[
                      Container(
                        width: 1,
                        color:
                            BeenHereColors.borderSubtle.withValues(alpha: 0.8),
                      ),
                      Tooltip(
                        message: 'Yakınımdaki Konumlar (Anlık Konum)',
                        child: Material(
                          color: isNearbyMode
                              ? BeenHereColors.verifiedEmerald
                                  .withValues(alpha: 0.18)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: vm.toggleNearbySearch,
                            child: SizedBox(
                              width: 46,
                              child: Center(
                                child: Icon(
                                  Icons.my_location_rounded,
                                  size: 20,
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
                    if (widget.showTreeDrawerButton && treeMixin != null) ...[
                      Container(
                        width: 1,
                        color:
                            BeenHereColors.borderSubtle.withValues(alpha: 0.8),
                      ),
                      Tooltip(
                        message: 'Bölge, Ülke ve Şehir Filtresi',
                        child: Material(
                          color: !treeMixin.isGlobalSelected && !isNearbyMode
                              ? BeenHereColors.primaryCompass
                                  .withValues(alpha: 0.16)
                              : Colors.transparent,
                          child: InkWell(
                            onTap: () => _openDrawer(treeMixin),
                            child: SizedBox(
                              width: 46,
                              child: Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.public_rounded,
                                      size: 20,
                                      color: !treeMixin.isGlobalSelected
                                          ? (isNearbyMode
                                              ? BeenHereColors.primaryCompass
                                                  .withValues(alpha: 0.65)
                                              : BeenHereColors.primaryCompass)
                                          : BeenHereColors.textSecondary,
                                    ),
                                    if (!treeMixin.isGlobalSelected)
                                      Positioned(
                                        right: -3,
                                        top: -3,
                                        child: Container(
                                          width: 7,
                                          height: 7,
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
                    ],
                    if (widget.showBudgetFilter) ...[
                      Container(
                        width: 1,
                        color:
                            BeenHereColors.borderSubtle.withValues(alpha: 0.8),
                      ),
                      Tooltip(
                        message: 'Bütçe Aralığı Filtresi',
                        child: Material(
                          color: isBudgetActive
                              ? BeenHereColors.primaryCompass
                                  .withValues(alpha: 0.16)
                              : Colors.transparent,
                          child: InkWell(
                            key: widget.budgetButtonKey,
                            onTap: () => _openBudgetFilterSheet(context),
                            child: SizedBox(
                              width: 48,
                              child: Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    PhosphorIcon(
                                      PhosphorIconsDuotone.currencyDollar,
                                      size: 20,
                                      color: isBudgetActive
                                          ? BeenHereColors.primaryCompass
                                          : BeenHereColors.textSecondary,
                                    ),
                                    if (isBudgetActive)
                                      Positioned(
                                        right: -3,
                                        top: -3,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color:
                                                BeenHereColors.primaryCompass,
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
                  ],
                ),
              ),

              // 2. AKTİF / DURAKLATILABİLİR FİLTRE HAPLARI & KONUM ŞERİDİ
              if (showPillsSection)
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (isNearbyMode) _buildNearbyPill(vm),
                      if (showLegacyTreeChip) _buildLegacyTreeChip(treeMixin),
                      if (vm.hasFilterPills) ...[
                        for (final pill in vm.filterPills)
                          _buildFilterPill(vm, pill),
                        _buildClearAllChip(vm),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNearbyPill(BeenHereSearchFilterController vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.7),
          width: 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 14,
            color: BeenHereColors.verifiedEmerald,
          ),
          const SizedBox(width: 5),
          Text(
            vm.detectedLocationLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BeenHereColors.verifiedEmerald,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Anlık Konum',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: BeenHereColors.verifiedEmerald,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: vm.toggleNearbySearch,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: BeenHereColors.verifiedEmerald,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyTreeChip(GeographyTreeFilterMixin treeMixin) {
    final isGlobal = treeMixin.isGlobalSelected;
    return Container(
      decoration: BoxDecoration(
        color: isGlobal
            ? BeenHereColors.surface.withValues(alpha: 0.75)
            : BeenHereColors.primaryCompass.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGlobal
              ? BeenHereColors.borderSubtle
              : BeenHereColors.primaryCompass.withValues(alpha: 0.7),
          width: isGlobal ? 1 : 1.1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _openDrawer(treeMixin),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.fromLTRB(11, 6, isGlobal ? 11 : 6, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 14,
                    color: isGlobal
                        ? BeenHereColors.textSecondary
                        : BeenHereColors.primaryCompass,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    treeMixin.geographyFilterButtonTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isGlobal
                          ? BeenHereColors.textPrimary
                          : BeenHereColors.primaryCompass,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isGlobal)
            InkWell(
              onTap: treeMixin.resetToGlobal,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 6, 9, 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: BeenHereColors.primaryCompass,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClearAllChip(BeenHereSearchFilterController vm) {
    return InkWell(
      onTap: vm.clearAllFilterPills,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: BeenHereColors.surfaceElevated.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: BeenHereColors.borderSubtle,
          ),
        ),
        child: Text(
          'Tümünü Temizle',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: BeenHereColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    BeenHereSearchFilterController vm,
    RouteFeedFilterPill pill,
  ) {
    final isEnabled = pill.isEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: isEnabled
            ? BeenHereColors.primaryCompass.withValues(alpha: 0.18)
            : BeenHereColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEnabled
              ? BeenHereColors.primaryCompass
              : BeenHereColors.borderSubtle,
          width: isEnabled ? 1.2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => vm.toggleFilterPill(pill.id),
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 6, 6, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEnabled) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 13.5,
                      color: BeenHereColors.primaryCompass,
                    ),
                    const SizedBox(width: 5),
                  ] else ...[
                    Icon(
                      Icons.pause_circle_outline_rounded,
                      size: 13.5,
                      color: BeenHereColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    pill.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? BeenHereColors.textPrimary
                          : BeenHereColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Tooltip(
            message: '${pill.label} filtresini kaldır',
            child: InkWell(
              key: ValueKey<String>('remove_pill_${pill.id}'),
              onTap: () => vm.removeFilterPill(pill.id),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 9, 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isEnabled
                      ? BeenHereColors.primaryCompass
                      : BeenHereColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GeographyTreeFilterDrawerSheet extends StatefulWidget {
  const _GeographyTreeFilterDrawerSheet({
    required this.filterModel,
    this.resultCountLabelBuilder,
  });

  final GeographyTreeFilterMixin filterModel;
  final String Function()? resultCountLabelBuilder;

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
        final countLabel = widget.resultCountLabelBuilder?.call();

        return Container(
          height: screenHeight * 0.85,
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
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
                      child: Icon(
                        Icons.public_rounded,
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
                            'Bölge, Ülke ve Şehir Filtresi',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
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
                            style: TextStyle(
                              fontSize: 13.5,
                              color: BeenHereColors.textPrimary,
                            ),
                            decoration: InputDecoration(
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
                          icon: Icon(
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

              Divider(height: 1, color: BeenHereColors.borderSubtle),

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
                              Text(
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
                                  child: Text(
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
                            Icon(
                              Icons.travel_explore_rounded,
                              size: 38,
                              color: BeenHereColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '"${vm.treeSearchQuery}" ile eşleşen kıta, ülke veya şehir bulunamadı.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
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
                decoration: BoxDecoration(
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
                          countLabel != null
                              ? 'Uygula ($countLabel)'
                              : 'Uygula',
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
                      style: TextStyle(
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
                      child: Text(
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
                          style: TextStyle(
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
                        style: TextStyle(
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
            Divider(height: 1, color: BeenHereColors.borderSubtle),
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
                    style: TextStyle(
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
                      child: Text(
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
                          style: TextStyle(
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
                        style: TextStyle(
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
            Divider(height: 1, color: BeenHereColors.borderSubtle),
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
