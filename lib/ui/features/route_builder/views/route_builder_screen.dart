import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/been_here_theme.dart';
import '../view_models/route_builder_view_model.dart';

class RouteBuilderScreen extends StatelessWidget {
  const RouteBuilderScreen({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = viewModel.customDateRange ??
        DateTimeRange(
          start: now.add(const Duration(days: 7)),
          end: now.add(const Duration(days: 11)),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      initialDateRange: initialRange,
      helpText: 'Seyahat Tarih Aralığını Seç',
      saveText: 'Seç',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BeenHereColors.primaryCompass,
              onPrimary: Colors.white,
              surface: BeenHereColors.surface,
              onSurface: BeenHereColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      viewModel.setCustomDateRange(picked);
    }
  }

  void _handleBottomPrimaryAction(BuildContext context) {
    if (viewModel.currentStep == RouteWizardStep.locations) {
      if (!viewModel.hasAnyDestinationSelected) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              '📍 Tarih seçimine geçmeden önce lütfen en az bir ülke veya şehir seçin.',
            ),
          ),
        );
        return;
      }
      viewModel.goToNextStep();
      return;
    }

    if (viewModel.currentStep != RouteWizardStep.travelers) {
      viewModel.goToNextStep();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BeenHereColors.surfaceElevated,
        content: Text(
          '🧭 ${viewModel.totalSelectedCountryCount} Ülke, ${viewModel.totalSelectedCityCount} Şehir • ${viewModel.totalTravelersCount} Gezgin için rota destesi hazırlanıyor...',
          style: const TextStyle(color: BeenHereColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Alttaki menü barına tam yaslanması için gereksiz boşluğu kaldırıyoruz
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomSafe > 0 ? bottomSafe + 4.0 : 8.0;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. ÜSTTEKİ İLERLEME AĞACI
            // =================================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _WizardTopProgressTree(
                viewModel: viewModel,
              ),
            ),

            // =================================================================
            // 2. AKTİF ADIM GÖVDESİ (1.1 Seçili Konumlar, 1.2 Tarih, ...)
            // =================================================================
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildActiveStepBody(context),
              ),
            ),

            // =================================================================
            // 3. ALT İLERLEME BARI: [ ← (Geri) ]   [ X Ülke, X Şehir Seçildi ]
            // (Aşağıya tam yaslı, gereksiz alt boşluk kaldırıldı)
            // =================================================================
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
              child: _WizardBottomNavigationBar(
                viewModel: viewModel,
                onTapPrevious: viewModel.goToPreviousStep,
                onTapNext: () => _handleBottomPrimaryAction(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveStepBody(BuildContext context) {
    switch (viewModel.currentStep) {
      case RouteWizardStep.locations:
        return _StepOneLocationsExactLayout(
          key: const ValueKey<String>('wizard-step-locations'),
          viewModel: viewModel,
        );
      case RouteWizardStep.dates:
        return _StepTwoDatesPlaceholderBody(
          key: const ValueKey<String>('wizard-step-dates'),
          viewModel: viewModel,
          onPickCustomRange: () => _pickCustomDateRange(context),
        );
      case RouteWizardStep.budget:
        return _StepThreeBudgetPlaceholderBody(
          key: const ValueKey<String>('wizard-step-budget'),
          viewModel: viewModel,
        );
      case RouteWizardStep.travelers:
        return _StepFourTravelersPlaceholderBody(
          key: const ValueKey<String>('wizard-step-travelers'),
          viewModel: viewModel,
        );
    }
  }
}

// =============================================================================
// 1. ÜSTTEKİ İLERLEME AĞACI (Ultra Kompakt, Yalnızca İkonlar)
// =============================================================================
class _WizardTopProgressTree extends StatelessWidget {
  const _WizardTopProgressTree({required this.viewModel});

  final RouteBuilderViewModel viewModel;

  PhosphorIconData _iconForStep(
    RouteWizardStep step,
    PhosphorIconsStyle style,
  ) {
    switch (step) {
      case RouteWizardStep.locations:
        return PhosphorIcons.mapPinArea(style);
      case RouteWizardStep.dates:
        return PhosphorIcons.calendarBlank(style);
      case RouteWizardStep.budget:
        return PhosphorIcons.coins(style);
      case RouteWizardStep.travelers:
        return PhosphorIcons.usersThree(style);
    }
  }

  @override
  Widget build(BuildContext context) {
    const steps = RouteWizardStep.values;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BeenHereColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BeenHereColors.borderSubtle.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: _WizardCompactStepIconItem(
                step: steps[i],
                icon: _iconForStep(
                  steps[i],
                  viewModel.currentStep == steps[i]
                      ? PhosphorIconsStyle.duotone
                      : PhosphorIconsStyle.regular,
                ),
                isActive: viewModel.currentStep == steps[i],
                isCompleted:
                    steps[i].stepIndex < viewModel.currentStep.stepIndex,
                onTap: () {
                  if (steps[i] == RouteWizardStep.locations ||
                      viewModel.hasAnyDestinationSelected) {
                    viewModel.goToStep(steps[i]);
                  }
                },
              ),
            ),
            if (i < steps.length - 1)
              Container(
                width: 14,
                height: 1.5,
                color: steps[i].stepIndex < viewModel.currentStep.stepIndex
                    ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.7)
                    : BeenHereColors.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

class _WizardCompactStepIconItem extends StatelessWidget {
  const _WizardCompactStepIconItem({
    required this.step,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  final RouteWizardStep step;
  final PhosphorIconData icon;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isActive
        ? BeenHereColors.primaryCompass
        : (isCompleted
            ? BeenHereColors.verifiedEmerald
            : BeenHereColors.textSecondary);

    return Tooltip(
      message: step.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? BeenHereColors.primaryCompass.withValues(alpha: 0.20)
                  : (isCompleted
                      ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.16)
                      : BeenHereColors.background.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isActive
                    ? BeenHereColors.primaryCompass
                    : (isCompleted
                        ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.65)
                        : BeenHereColors.borderSubtle),
                width: isActive ? 1.4 : 0.9,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color:
                            BeenHereColors.primaryCompass.withValues(alpha: 0.25),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: PhosphorIcon(
                icon,
                size: 17,
                color: accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. YENİ AIRBNB MODELİ DÜZENİ:
// 1. Satır: [ Ülke veya Şehir Ara... ] (Airbnb Arama Çubuğu + Filtre Slider + Tümünü Seç)
// 2. Satır (Açılır Panel): Liquid Glass Kıta ve Alt Bölge Çipleri
// 3. Satır (Aktif Filtreler): [Avrupa ✕] [Batı Avrupa ✕] [Dismissible Chips]
// 4. Gövde: [İspanya Banner] -> [Sevilla] [Cadiz] [Madrid] Slider'ı
// 5. Gövde: [Türkiye Banner] -> [İstanbul] [İzmir] [Ankara] Slider'ı
// =============================================================================
class _StepOneLocationsExactLayout extends StatefulWidget {
  const _StepOneLocationsExactLayout({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  State<_StepOneLocationsExactLayout> createState() =>
      _StepOneLocationsExactLayoutState();
}

class _StepOneLocationsExactLayoutState
    extends State<_StepOneLocationsExactLayout> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isFilterPanelOpen = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.viewModel.searchFilterQuery,
    );
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && !_isFilterPanelOpen) {
        setState(() => _isFilterPanelOpen = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final continents = RouteBuilderViewModel.continentsCatalog;
    final subRegions = vm.currentSubRegions;
    final countries = vm.displayedCountries;

    const double countryBannerHeight = 92.0;
    const double cityCardWidth = 98.0;
    const double cityCardHeight = 104.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        // ---------------------------------------------------------------------
        // 1. AIRBNB MODELİ ARAMA ÇUBUĞU (Stepper'ın hemen altında)
        // ---------------------------------------------------------------------
        _AirbnbLocationSearchBar(
          controller: _searchController,
          focusNode: _searchFocusNode,
          viewModel: vm,
          isFilterPanelOpen: _isFilterPanelOpen,
          onToggleFilterPanel: () {
            HapticFeedback.lightImpact();
            setState(() => _isFilterPanelOpen = !_isFilterPanelOpen);
          },
          onClearQuery: () {
            _searchController.clear();
            vm.clearSearchFilter();
          },
        ),

        // ---------------------------------------------------------------------
        // 2. ARAMA YA DA BUTONA BASILDIĞINDA AÇILAN KITA & BÖLGE ÇİPLERİ PANELİ
        // (Liquid Glass Çipler)
        // ---------------------------------------------------------------------
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          child: _isFilterPanelOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _FilterChipsPickerPanel(
                    viewModel: vm,
                    continents: continents,
                    subRegions: subRegions,
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ---------------------------------------------------------------------
        // 3. AKTİF FİLTRE ÇİPLERİ VE HIZLI KALDIRMA (Dismissible Chips)
        // (Kıta, bölge veya arama aktif olduğunda arama kutusunun altında belirir)
        // ---------------------------------------------------------------------
        if (vm.hasActiveFilter) ...[
          const SizedBox(height: 8),
          _ActiveFilterChipsRow(
            viewModel: vm,
            onClearSearch: () {
              _searchController.clear();
              vm.clearSearchFilter();
            },
            onClearAll: () {
              _searchController.clear();
              vm.clearAllFilters();
            },
          ),
        ],

        const SizedBox(height: 12),

        // ---------------------------------------------------------------------
        // 4. GÖVDE ALANI: ÜLKE BANNERLARI VE ŞEHİR SLIDER'LARI
        // ---------------------------------------------------------------------
        if (countries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BeenHereColors.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BeenHereColors.borderSubtle.withValues(alpha: 0.6),
              ),
            ),
            child: const Center(
              child: Text(
                'Aradığınız filtreye uygun ülke veya şehir bulunamadı.',
                style: TextStyle(
                  fontSize: 12,
                  color: BeenHereColors.textSecondary,
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < countries.length; i++) ...[
                // Ülke Satırı Başlığı ve Seçim Özeti (Sadece seçim yapıldığında açılır)
                _CountrySelectionHeaderBadge(
                  country: countries[i],
                  viewModel: vm,
                ),
                _CountryAndCitiesSection(
                  country: countries[i],
                  viewModel: vm,
                  countryBannerHeight: countryBannerHeight,
                  cityCardWidth: cityCardWidth,
                  cityCardHeight: cityCardHeight,
                  onCountryLongPress: () {
                    HapticFeedback.mediumImpact();
                    vm.toggleSelectAllCitiesOfCountry(countries[i]);
                    _showFeedback(
                      context,
                      '✨ ${countries[i].name} ve tüm şehirleri seçildi/temizlendi.',
                    );
                  },
                ),
                // Ülkeler arasında ferah boşluk
                if (i < countries.length - 1) const SizedBox(height: 18),
              ],
            ],
          ),
      ],
    );
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        backgroundColor: BeenHereColors.surfaceElevated,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: BeenHereColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// YENİ WIDGETLAR: AIRBNB ARAMA ÇUBUĞU, ÇİP PANELİ VE AKTİF ÇİPLER
// =============================================================================
class _AirbnbLocationSearchBar extends StatelessWidget {
  const _AirbnbLocationSearchBar({
    required this.controller,
    required this.focusNode,
    required this.viewModel,
    required this.isFilterPanelOpen,
    required this.onToggleFilterPanel,
    required this.onClearQuery,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final RouteBuilderViewModel viewModel;
  final bool isFilterPanelOpen;
  final VoidCallback onToggleFilterPanel;
  final VoidCallback onClearQuery;

  @override
  Widget build(BuildContext context) {
    final bool hasFocus = focusNode.hasFocus;
    final bool hasFilterActive = viewModel.hasActiveFilter;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (hasFocus || isFilterPanelOpen)
              ? BeenHereColors.primaryCompass.withValues(alpha: 0.85)
              : (hasFilterActive
                  ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.6)
                  : BeenHereColors.borderSubtle.withValues(alpha: 0.9)),
          width: (hasFocus || isFilterPanelOpen) ? 1.2 : 0.9,
        ),
        boxShadow: (hasFocus || isFilterPanelOpen)
            ? [
                BoxShadow(
                  color: BeenHereColors.primaryCompass.withValues(alpha: 0.14),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Sol Arama İkonu
          PhosphorIcon(
            PhosphorIcons.magnifyingGlass(
              hasFocus || controller.text.isNotEmpty
                  ? PhosphorIconsStyle.bold
                  : PhosphorIconsStyle.regular,
            ),
            size: 16,
            color: hasFocus || controller.text.isNotEmpty
                ? BeenHereColors.primaryCompass
                : BeenHereColors.textSecondary,
          ),
          const SizedBox(width: 8),

          // Orta Arama Inputu
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onTap: () {
                if (!isFilterPanelOpen) {
                  onToggleFilterPanel();
                }
              },
              onChanged: viewModel.updateSearchFilterQuery,
              style: const TextStyle(
                fontSize: 12.5,
                color: BeenHereColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Ülke veya şehir ara...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: BeenHereColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Arama Temizleme Butonu (✕)
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClearQuery,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PhosphorIcon(
                  PhosphorIcons.xCircle(PhosphorIconsStyle.fill),
                  size: 16,
                  color: BeenHereColors.textSecondary,
                ),
              ),
            ),

          // Ayırıcı Çizgi
          Container(
            width: 1,
            height: 18,
            color: BeenHereColors.borderSubtle,
          ),
          const SizedBox(width: 6),

          // Filtre İkonu (Kıta ve Bölge Panelini Aç / Kapa)
          Tooltip(
            message: isFilterPanelOpen
                ? 'Filtreleri Gizle'
                : 'Kıta ve Bölge Filtreleri',
            child: InkWell(
              onTap: onToggleFilterPanel,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isFilterPanelOpen || viewModel.activeContinentId != null
                      ? BeenHereColors.primaryCompass.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(
                  PhosphorIcons.slidersHorizontal(
                    isFilterPanelOpen
                        ? PhosphorIconsStyle.fill
                        : PhosphorIconsStyle.regular,
                  ),
                  size: 16,
                  color: isFilterPanelOpen || viewModel.activeContinentId != null
                      ? BeenHereColors.primaryCompass
                      : BeenHereColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Sağda hızlı Tümünü Seç / Temizle Butonu
          Tooltip(
            message: viewModel.areAllCurrentLocationsSelected
                ? 'Tüm Seçimleri Temizle'
                : 'Görünenlerin Tümünü Seç',
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                viewModel.toggleSelectAllInCurrentView();
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: PhosphorIcon(
                  viewModel.areAllCurrentLocationsSelected
                      ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                      : PhosphorIcons.square(PhosphorIconsStyle.regular),
                  size: 15,
                  color: viewModel.areAllCurrentLocationsSelected
                      ? BeenHereColors.verifiedEmerald
                      : BeenHereColors.primaryCompass,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipsPickerPanel extends StatelessWidget {
  const _FilterChipsPickerPanel({
    required this.viewModel,
    required this.continents,
    required this.subRegions,
  });

  final RouteBuilderViewModel viewModel;
  final List<BuilderContinentCatalogItem> continents;
  final List<BuilderSubRegionCatalogItem> subRegions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BeenHereColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BeenHereColors.borderSubtle.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. SATIR: KITA ÇİPLERİ (Dünya / Tümü, Avrupa, Asya, Afrika...)
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _LiquidGlassChip(
                  label: 'Tüm Kıtalar',
                  icon: PhosphorIcons.globeHemisphereWest(
                    viewModel.activeContinentId == null
                        ? PhosphorIconsStyle.fill
                        : PhosphorIconsStyle.regular,
                  ),
                  isSelected: viewModel.activeContinentId == null,
                  activeColor: BeenHereColors.verifiedEmerald,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.clearContinentFilter();
                  },
                ),
                const SizedBox(width: 6),
                for (final c in continents) ...[
                  _LiquidGlassChip(
                    label: c.name,
                    isSelected: viewModel.activeContinentId == c.id,
                    activeColor: BeenHereColors.verifiedEmerald,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      viewModel.selectContinent(c.id);
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),

          // 2. SATIR: ALT BÖLGE ÇİPLERİ (Eğer seçili bir kıta varsa)
          if (viewModel.activeContinent != null && subRegions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: BeenHereColors.borderSubtle.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _LiquidGlassChip(
                    label: 'Tüm ${viewModel.activeContinent!.name}',
                    icon: PhosphorIcons.mapPin(
                      viewModel.activeSubRegionId == null
                          ? PhosphorIconsStyle.fill
                          : PhosphorIconsStyle.regular,
                    ),
                    isSelected: viewModel.activeSubRegionId == null,
                    activeColor: BeenHereColors.primaryCompass,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      viewModel.clearSubRegionFilter();
                    },
                  ),
                  const SizedBox(width: 6),
                  for (final sr in subRegions) ...[
                    _LiquidGlassChip(
                      label: sr.name,
                      isSelected: viewModel.activeSubRegionId == sr.id,
                      activeColor: BeenHereColors.primaryCompass,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        viewModel.selectSubRegion(sr.id);
                      },
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiquidGlassChip extends StatelessWidget {
  const _LiquidGlassChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.activeColor = BeenHereColors.verifiedEmerald,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final PhosphorIconData? icon;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.18)
              : BeenHereColors.surfaceElevated.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? activeColor
                : BeenHereColors.borderSubtle.withValues(alpha: 0.75),
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.22),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              PhosphorIcon(
                icon!,
                size: 13,
                color: isSelected ? activeColor : BeenHereColors.textSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : BeenHereColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChipsRow extends StatelessWidget {
  const _ActiveFilterChipsRow({
    required this.viewModel,
    required this.onClearSearch,
    required this.onClearAll,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onClearSearch;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    int activeCount = 0;
    if (viewModel.activeContinent != null) activeCount++;
    if (viewModel.activeSubRegion != null) activeCount++;
    if (viewModel.searchFilterQuery.isNotEmpty) activeCount++;

    return SizedBox(
      height: 28,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Kıta Filtresi Çipi
          if (viewModel.activeContinent != null) ...[
            _DismissibleActiveFilterChip(
              label: viewModel.activeContinent!.name,
              icon: PhosphorIcons.globeHemisphereWest(PhosphorIconsStyle.fill),
              color: BeenHereColors.verifiedEmerald,
              onDismiss: () {
                HapticFeedback.lightImpact();
                viewModel.clearContinentFilter();
              },
            ),
            const SizedBox(width: 6),
          ],

          // 2. Alt Bölge Filtresi Çipi
          if (viewModel.activeSubRegion != null) ...[
            _DismissibleActiveFilterChip(
              label: viewModel.activeSubRegion!.name,
              icon: PhosphorIcons.mapPin(PhosphorIconsStyle.fill),
              color: BeenHereColors.primaryCompass,
              onDismiss: () {
                HapticFeedback.lightImpact();
                viewModel.clearSubRegionFilter();
              },
            ),
            const SizedBox(width: 6),
          ],

          // 3. Arama Metni Çipi
          if (viewModel.searchFilterQuery.isNotEmpty) ...[
            _DismissibleActiveFilterChip(
              label: '"${viewModel.searchFilterQuery}"',
              icon: PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
              color: BeenHereColors.goldLeague,
              onDismiss: () {
                HapticFeedback.lightImpact();
                onClearSearch();
              },
            ),
            const SizedBox(width: 6),
          ],

          // 4. Tümünü Temizle Butonu (2 veya daha fazla filtre varsa)
          if (activeCount >= 2) ...[
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onClearAll();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: BeenHereColors.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BeenHereColors.borderSubtle.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Sıfırla',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: BeenHereColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DismissibleActiveFilterChip extends StatelessWidget {
  const _DismissibleActiveFilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  final String label;
  final PhosphorIconData icon;
  final Color color;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.55),
            width: 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 12,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            PhosphorIcon(
              PhosphorIcons.x(PhosphorIconsStyle.bold),
              size: 11,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ülke satırının hemen üstünde yer alan ve seçilen şehirleri gösteren özet başlık:
/// Sadece seçim yapıldığında görünür (Örn: "Türkiye -> Tümü" veya "Türkiye -> İzmir, Ankara")
class _CountrySelectionHeaderBadge extends StatelessWidget {
  const _CountrySelectionHeaderBadge({
    required this.country,
    required this.viewModel,
  });

  final BuilderCountryCatalogItem country;
  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.isCountryOrAnyCitySelected(country);
    if (!isSelected) {
      return const SizedBox.shrink();
    }

    final summaryText = viewModel.getCountrySelectionSummaryText(country);

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.55),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                size: 13,
                color: BeenHereColors.verifiedEmerald,
              ),
              const SizedBox(width: 5),
              Text(
                summaryText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.verifiedEmerald,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Taslaktaki ÜLKE (Tüm Satır) + ALTINDA ŞEHİRLER (Yatay Slider) Bloğu:
/// Ülke satırın tamamına yayılır (Banner), hemen altında o ülkenin şehirleri slider şeklinde dizilir.
class _CountryAndCitiesSection extends StatelessWidget {
  const _CountryAndCitiesSection({
    required this.country,
    required this.viewModel,
    required this.countryBannerHeight,
    required this.cityCardWidth,
    required this.cityCardHeight,
    required this.onCountryLongPress,
  });

  final BuilderCountryCatalogItem country;
  final RouteBuilderViewModel viewModel;
  final double countryBannerHeight;
  final double cityCardWidth;
  final double cityCardHeight;
  final VoidCallback onCountryLongPress;

  @override
  Widget build(BuildContext context) {
    final isCountrySelected = viewModel.isCountrySelected(country.code);
    final cities = viewModel.getDisplayedCitiesForCountry(country);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. ÜLKE KARTI: Satırın tamamına yayılan estetik Banner
        _CountryBannerCard(
          country: country,
          height: countryBannerHeight,
          isSelected: isCountrySelected,
          onTap: () {
            HapticFeedback.selectionClick();
            viewModel.toggleCountrySelection(country);
          },
          onLongPress: onCountryLongPress,
        ),

        // 2. HEMEN ALTINDA: O ÜLKENİN ŞEHİRLERİ (Yatay Slider)
        if (cities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: cityCardHeight,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: const {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: ListView.separated(
                key: PageStorageKey<String>('cities-row-${country.code}'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: cities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final city = cities[idx];
                  final isCitySelected = viewModel.isCitySelected(city);

                  return SizedBox(
                    width: cityCardWidth,
                    child: _LocationPhotoCard(
                      title: city.name,
                      imageUrl: city.imageUrl,
                      isSelected: isCitySelected,
                      selectedTopBadge:
                          isCitySelected ? '${city.name} Seçili' : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        viewModel.toggleCitySelection(city);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Satırın tamamına yayılan geniş Ülke Banner Kartı
class _CountryBannerCard extends StatelessWidget {
  const _CountryBannerCard({
    required this.country,
    required this.height,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  final BuilderCountryCatalogItem country;
  final double height;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? BeenHereColors.verifiedEmerald
                : Colors.white.withValues(alpha: 0.16),
            width: isSelected ? 2.0 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              country.imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 640,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF16273D),
              ),
            ),

            // Karartma ve Degrade Katmanı
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    isSelected
                        ? const Color(0x6A06291E)
                        : const Color(0x32060B13),
                    isSelected
                        ? const Color(0x4A06291E)
                        : const Color(0x18060B13),
                    const Color(0xD8060B13),
                  ],
                ),
              ),
            ),

            // Üst Sol: Seçili Rozeti (Taslaktaki gibi: "İspanya Seçili")
            if (isSelected)
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        BeenHereColors.verifiedEmerald.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${country.name} Seçili',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Üst Sağ: Bayrak ve Basılı Tutma İpucu Rozeti
            Positioned(
              top: 8,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.flag(PhosphorIconsStyle.regular),
                      size: 10,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      country.flagEmoji,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ),

            // Sol Alt: Ülke İsmi (Taslaktaki gibi ferah ve net: "İspanya")
            Positioned(
              left: 12,
              bottom: 9,
              right: 12,
              child: Text(
                country.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 4,
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
}

/// Taslaktaki Fotoğraflı Lokasyon Kartı (Kıta ve Şehirler İçin)
class _LocationPhotoCard extends StatelessWidget {
  const _LocationPhotoCard({
    required this.title,
    required this.imageUrl,
    required this.isSelected,
    this.selectedTopBadge,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final bool isSelected;
  final String? selectedTopBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? BeenHereColors.verifiedEmerald
                : Colors.white.withValues(alpha: 0.16),
            width: isSelected ? 2.0 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.24),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 320,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFF16273D),
              ),
            ),

            // Karartma Katmanı
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    isSelected
                        ? const Color(0x6A06291E)
                        : const Color(0x32060B13),
                    isSelected
                        ? const Color(0x4A06291E)
                        : const Color(0x18060B13),
                    const Color(0xD8060B13),
                  ],
                ),
              ),
            ),

            // Üstteki Seçili İbaresi (Taslaktaki gibi: "Avrupa seçili iken", "Madrid Seçili" vb.)
            if (isSelected && selectedTopBadge != null)
              Positioned(
                top: 5,
                left: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: 9.5,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          selectedTopBadge!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Sol Alt: İsim (Avrupa, Sevilla, Cadiz, Madrid...)
            Positioned(
              left: 7,
              right: 7,
              bottom: 6,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// =============================================================================
// 3. ALT İLERLEME BARI: [ ← ]  [ X Ülke, X Şehir Seçildi ]
// =============================================================================
class _WizardBottomNavigationBar extends StatelessWidget {
  const _WizardBottomNavigationBar({
    required this.viewModel,
    required this.onTapPrevious,
    required this.onTapNext,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onTapPrevious;
  final VoidCallback onTapNext;

  String _primaryButtonLabel() {
    switch (viewModel.currentStep) {
      case RouteWizardStep.locations:
        return viewModel.bottomButtonLabel;
      case RouteWizardStep.dates:
        return 'Bütçe Seçimi (${viewModel.formattedDateSummary})';
      case RouteWizardStep.budget:
        return 'Ziyaretçi Seçimi (${viewModel.formattedBudgetSummary})';
      case RouteWizardStep.travelers:
        return 'Rotayı Oluşturmaya Başla (${viewModel.totalTravelersCount} Kişi)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = viewModel.currentStep != RouteWizardStep.locations;

    return Row(
      children: [
        // Sol: Geri Oku (←)
        Material(
          color: BeenHereColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: canGoBack ? onTapPrevious : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 52,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: canGoBack
                      ? BeenHereColors.borderSubtle
                      : BeenHereColors.borderSubtle.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                  size: 19,
                  color: canGoBack
                      ? BeenHereColors.textPrimary
                      : BeenHereColors.textSecondary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Sağ: Geniş Aksiyon / Seçim Özeti Butonu ("X Ülke, X Şehir Seçildi")
        Expanded(
          child: SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: onTapNext,
              style: FilledButton.styleFrom(
                backgroundColor: viewModel.hasAnyDestinationSelected
                    ? BeenHereColors.primaryCompass
                    : BeenHereColors.surfaceElevated,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: viewModel.hasAnyDestinationSelected
                        ? BeenHereColors.primaryCompass
                        : BeenHereColors.borderSubtle,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _primaryButtonLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: viewModel.hasAnyDestinationSelected
                            ? Colors.white
                            : BeenHereColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PhosphorIcon(
                    PhosphorIcons.arrowRight(PhosphorIconsStyle.bold),
                    size: 15,
                    color: viewModel.hasAnyDestinationSelected
                        ? Colors.white
                        : BeenHereColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DİĞER ADIMLAR (1.2 Tarih, 1.3 Bütçe, 1.4 Ziyaretçi)
// =============================================================================
class _StepTwoDatesPlaceholderBody extends StatelessWidget {
  const _StepTwoDatesPlaceholderBody({
    super.key,
    required this.viewModel,
    required this.onPickCustomRange,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onPickCustomRange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seçili Tarih Adımı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Esnek / Belirsiz'),
                    selected: viewModel.dateMode == RouteDateMode.flexible,
                    onSelected: (_) =>
                        viewModel.setDateMode(RouteDateMode.flexible),
                  ),
                  ChoiceChip(
                    label: const Text('Şu An / Geçmiş Gezi 📸'),
                    selected:
                        viewModel.dateMode == RouteDateMode.currentOrPastTrip,
                    onSelected: (_) =>
                        viewModel.setDateMode(RouteDateMode.currentOrPastTrip),
                  ),
                  ChoiceChip(
                    label: const Text('Bu Hafta Sonu'),
                    selected:
                        viewModel.dateMode == RouteDateMode.upcomingWeekend,
                    onSelected: (_) =>
                        viewModel.setDateMode(RouteDateMode.upcomingWeekend),
                  ),
                  ActionChip(
                    label: Text(
                      viewModel.dateMode == RouteDateMode.customRange
                          ? viewModel.formattedDateSummary
                          : 'Takvimden Tarih Seç...',
                    ),
                    onPressed: onPickCustomRange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepThreeBudgetPlaceholderBody extends StatelessWidget {
  const _StepThreeBudgetPlaceholderBody({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seçili Bütçe Adımı',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                  Switch.adaptive(
                    value: viewModel.isBudgetEnabled,
                    activeTrackColor: BeenHereColors.primaryCompass,
                    onChanged: (_) => viewModel.toggleBudgetEnabled(),
                  ),
                ],
              ),
              Text(
                viewModel.formattedBudgetSummary,
                style: const TextStyle(
                  fontSize: 13,
                  color: BeenHereColors.primaryCompass,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (viewModel.isBudgetEnabled)
                RangeSlider(
                  values: RangeValues(
                    viewModel.minBudget,
                    viewModel.maxBudget,
                  ),
                  min: 0,
                  max: viewModel.currency.maxLimit,
                  divisions: 50,
                  onChanged: (v) =>
                      viewModel.updateRouteBudgetRange(v.start, v.end),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepFourTravelersPlaceholderBody extends StatelessWidget {
  const _StepFourTravelersPlaceholderBody({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Seçili Ziyaretçi Adımı',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yetişkin: ${viewModel.adultsCount}'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => viewModel.updateAdultsCount(-1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        onPressed: () => viewModel.updateAdultsCount(1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Çocuk: ${viewModel.childrenCount}'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => viewModel.updateChildrenCount(-1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      IconButton(
                        onPressed: () => viewModel.updateChildrenCount(1),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
