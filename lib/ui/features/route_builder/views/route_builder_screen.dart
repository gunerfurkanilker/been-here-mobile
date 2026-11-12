import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/been_here_theme.dart';
import '../../../core/widgets/geography_tree_filter_bar.dart';
import '../view_models/route_builder_view_model.dart';

class RouteBuilderScreen extends StatefulWidget {
  const RouteBuilderScreen({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  State<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends State<RouteBuilderScreen>
    with SingleTickerProviderStateMixin {
  bool _isProgressTreeVisible = true;
  double _verticalScrollDelta = 0.0;
  RouteWizardStep? _lastStep;
  String? _lastFilterSignature;
  late final AnimationController _progressTreeController;
  late final CurvedAnimation _progressTreeAnimation;

  String _computeFilterSignature(RouteBuilderViewModel vm) {
    final pillsSig =
        vm.filterPills.map((p) => '${p.id}:${p.isEnabled}').join(',');
    return '${vm.searchFilterQuery}|$pillsSig';
  }

  @override
  void initState() {
    super.initState();
    _progressTreeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _progressTreeAnimation = CurvedAnimation(
      parent: _progressTreeController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _lastStep = widget.viewModel.currentStep;
    _lastFilterSignature = _computeFilterSignature(widget.viewModel);
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(covariant RouteBuilderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
      _lastStep = widget.viewModel.currentStep;
      _lastFilterSignature = _computeFilterSignature(widget.viewModel);
    }
  }

  @override
  void dispose() {
    _progressTreeAnimation.dispose();
    _progressTreeController.dispose();
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _setProgressTreeVisible(bool visible) {
    if (_isProgressTreeVisible == visible || !mounted) {
      return;
    }
    setState(() {
      _isProgressTreeVisible = visible;
    });
    if (visible) {
      _progressTreeController.forward();
    } else {
      _progressTreeController.reverse();
    }
  }

  void _onViewModelChanged() {
    bool shouldMakeVisible = false;
    if (_lastStep != widget.viewModel.currentStep) {
      _lastStep = widget.viewModel.currentStep;
      shouldMakeVisible = true;
    }
    final currentFilterSignature = _computeFilterSignature(widget.viewModel);
    if (_lastFilterSignature != currentFilterSignature) {
      _lastFilterSignature = currentFilterSignature;
      shouldMakeVisible = true;
    }

    if (shouldMakeVisible) {
      _verticalScrollDelta = 0.0;
      _setProgressTreeVisible(true);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Sadece dikey kaydırmalar kontrol edilir (yatay şehir slider'ı kaydırılırken tetiklenmez)
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }

    if (notification.metrics.pixels <= 2.0) {
      // Listenin en tepesine ulaşıldığında biriken deltayı sıfırla ve görünür yap
      _verticalScrollDelta = 0.0;
      _setProgressTreeVisible(true);
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          notification.metrics.pixels > 16.0) {
        // Aşağı kaydırma -> Gizle
        _verticalScrollDelta = 0.0;
        _setProgressTreeVisible(false);
      } else if (notification.direction == ScrollDirection.forward) {
        // Yukarı kaydırma -> Göster
        _verticalScrollDelta = 0.0;
        _setProgressTreeVisible(true);
      }
    } else if (notification is ScrollUpdateNotification) {
      // Mouse wheel / trackpad PointerScrollEvent, momentum ve kart üzeri kaydırmalar için
      if (!notification.metrics.outOfRange &&
          notification.metrics.maxScrollExtent > 0) {
        final delta = notification.scrollDelta ?? 0.0;
        if (delta > 0) {
          _verticalScrollDelta = _verticalScrollDelta > 0
              ? _verticalScrollDelta + delta
              : delta;
          if (_verticalScrollDelta >= 16.0 &&
              notification.metrics.pixels > 16.0) {
            _verticalScrollDelta = 0.0;
            _setProgressTreeVisible(false);
          }
        } else if (delta < 0) {
          _verticalScrollDelta = _verticalScrollDelta < 0
              ? _verticalScrollDelta + delta
              : delta;
          if (_verticalScrollDelta <= -12.0) {
            _verticalScrollDelta = 0.0;
            _setProgressTreeVisible(true);
          }
        }
      }
    }

    return false;
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = widget.viewModel.customDateRange ??
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
            colorScheme: ColorScheme.dark(
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
      widget.viewModel.setCustomDateRange(picked);
    }
  }

  void _handleBottomPrimaryAction(BuildContext context) {
    if (widget.viewModel.currentStep == RouteWizardStep.locations) {
      if (!widget.viewModel.hasAnyDestinationSelected) {
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
      widget.viewModel.goToNextStep();
      return;
    }

    if (widget.viewModel.currentStep != RouteWizardStep.travelers) {
      widget.viewModel.goToNextStep();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BeenHereColors.surfaceElevated,
        content: Text(
          '🧭 ${widget.viewModel.totalSelectedCountryCount} Ülke, ${widget.viewModel.totalSelectedCityCount} Şehir • ${widget.viewModel.totalTravelersCount} Gezgin için rota destesi hazırlanıyor...',
          style: TextStyle(color: BeenHereColors.textPrimary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Alttaki menü barına tam yaslanması için gereksiz boşluğu kaldırıyoruz
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = bottomSafe > 0 ? bottomSafe + 4.0 : 8.0;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================================
              // 1. ÜSTTEKİ İLERLEME AĞACI (Scroll-down gizlenme / Scroll-up geri gelme)
              // =================================================================
              ColoredBox(
                key: const ValueKey<String>('wizard-top-progress-tree-section'),
                color: BeenHereColors.background,
                child: AnimatedBuilder(
                  animation: _progressTreeAnimation,
                  builder: (context, child) {
                    if (!_isProgressTreeVisible &&
                        _progressTreeController.value == 0.0) {
                      return const SizedBox.shrink();
                    }
                    final animValue =
                        _progressTreeAnimation.value.clamp(0.0, 1.0);
                    return ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: animValue,
                        child: Transform.translate(
                          offset: Offset(0, -(1.0 - animValue) * 12.0),
                          child: Opacity(
                            opacity: Curves.easeOut
                                .transform(animValue)
                                .clamp(0.0, 1.0),
                            child: IgnorePointer(
                              ignoring: !_isProgressTreeVisible,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: _WizardTopProgressTree(
                      viewModel: widget.viewModel,
                    ),
                  ),
                ),
              ),

              // =================================================================
              // 2. AKTİF ADIM GÖVDESİ (1.1 Seçili Konumlar, 1.2 Tarih, ...)
              // =================================================================
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: const {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: ClipRect(
                    key: const ValueKey<String>('wizard-step-body-clip'),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildActiveStepBody(context),
                    ),
                  ),
                ),
              ),

              // =================================================================
              // 3. ALT İLERLEME BARI: [ ← (Geri) ]   [ X Ülke, X Şehir Seçildi ]
              // (Aşağıya tam yaslı, gereksiz alt boşluk kaldırıldı)
              // =================================================================
              Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding),
                child: _WizardBottomNavigationBar(
                  viewModel: widget.viewModel,
                  onTapPrevious: widget.viewModel.goToPreviousStep,
                  onTapNext: () => _handleBottomPrimaryAction(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveStepBody(BuildContext context) {
    switch (widget.viewModel.currentStep) {
      case RouteWizardStep.locations:
        return _StepOneLocationsExactLayout(
          key: const ValueKey<String>('wizard-step-locations'),
          viewModel: widget.viewModel,
        );
      case RouteWizardStep.dates:
        return _StepTwoDatesPlaceholderBody(
          key: const ValueKey<String>('wizard-step-dates'),
          viewModel: widget.viewModel,
          onPickCustomRange: () => _pickCustomDateRange(context),
        );
      case RouteWizardStep.budget:
        return _StepThreeBudgetPlaceholderBody(
          key: const ValueKey<String>('wizard-step-budget'),
          viewModel: widget.viewModel,
        );
      case RouteWizardStep.travelers:
        return _StepFourTravelersPlaceholderBody(
          key: const ValueKey<String>('wizard-step-travelers'),
          viewModel: widget.viewModel,
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
// 2. ADIM 1 LOKASYON SEÇİM DÜZENİ:
// 1. Satır: Ortak `GeographyTreeFilterBar` (Büyük arama çubuğu + Panel + Filtre Hapları)
// 2. Gövde: Doğrudan Ülke 1, Ülke 2... (| Bayrak | Ülke Adı |) ve Yatay Şehir Slider'ı
// =============================================================================
class _StepOneLocationsExactLayout extends StatelessWidget {
  const _StepOneLocationsExactLayout({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final countries = vm.displayedCountries;

    const double countryBannerHeight = 90.0;
    const double cityCardWidth = 220.0;
    const double cityCardHeight = 156.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      clipBehavior: Clip.hardEdge,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        // ---------------------------------------------------------------------
        // 1. ORTAK ÜLKE VE ŞEHİR ARAMA & FİLTRE ÇUBUĞU (GeographyTreeFilterBar)
        // ---------------------------------------------------------------------
        GeographyTreeFilterBar(
          filterModel: vm,
          resultCountLabelBuilder: () => '${vm.displayedCountries.length} Ülke',
          searchHintText: 'Ülke veya şehir ismi ile ara...',
          showNearbyButton: false,
          showBudgetFilter: false,
          showTreeDrawerButton: false,
          searchBarKey: const ValueKey<String>('route_builder_search_bar_tap'),
        ),

        const SizedBox(height: 12),

        // ---------------------------------------------------------------------
        // 2. GÖVDE ALANI: DOĞRUDAN ÜLKE BANNERLARI VE ŞEHİR SLIDER'LARI
        // ---------------------------------------------------------------------
        if (countries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BeenHereColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BeenHereColors.borderSubtle.withValues(alpha: 0.6),
                ),
              ),
              child: Center(
                child: Text(
                  'Aradığınız filtreye uygun ülke veya şehir bulunamadı.',
                  style: TextStyle(
                    fontSize: 12,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < countries.length; i++) ...[
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
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: BeenHereColors.textPrimary,
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
    final areAllCitiesSelected =
        viewModel.areAllCitiesInCountrySelected(country);
    final cities = viewModel.getDisplayedCitiesForCountry(country);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. ÜLKE KARTI: Satırın tamamına yayılan estetik Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _CountryBannerCard(
            country: country,
            height: countryBannerHeight,
            isSelected: isCountrySelected,
            areAllCitiesSelected: areAllCitiesSelected,
            selectedCityNames: viewModel.getSelectedCityNamesForCountry(country),
            onTap: () {
              HapticFeedback.selectionClick();
              viewModel.toggleCountrySelection(country);
            },
            onLongPress: onCountryLongPress,
          ),
        ),

        // 2. HEMEN ALTINDA: O ÜLKENİN ŞEHİRLERİ (Yatay Slider)
        if (cities.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: cityCardHeight + 16,
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
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: cities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final city = cities[idx];
                  final isCitySelected = viewModel.isCitySelected(city);

                  return SizedBox(
                    width: cityCardWidth,
                    child: _LocationPhotoCard(
                      title: city.name,
                      imageUrl: city.imageUrl,
                      isSelected: isCitySelected,
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

/// Satırın tamamına yayılan geniş Ülke Banner Kartı:
/// Sol tarafta özel dikey Bayrak Bölmesi (Flag Strip) | Sağ tarafta fotoğraflı Ülke Banner'ı
class _CountryBannerCard extends StatelessWidget {
  const _CountryBannerCard({
    required this.country,
    required this.height,
    required this.isSelected,
    required this.areAllCitiesSelected,
    required this.selectedCityNames,
    required this.onTap,
    required this.onLongPress,
  });

  final BuilderCountryCatalogItem country;
  final double height;
  final bool isSelected;
  final bool areAllCitiesSelected;
  final List<String> selectedCityNames;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final flagBorderColor = Colors.white.withValues(alpha: 0.16);
    const double flagBorderWidth = 0.9;

    final bannerBorderColor = Colors.white.withValues(alpha: 0.16);
    const double bannerBorderWidth = 0.9;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 4),
        transform: isSelected
            ? Matrix4.translationValues(0, -4.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: BeenHereColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.38),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. SOL: DİKEY BÖLME — BAYRAK ALANI (90° Sola Döndürülmüş Dikey Bayrak)
            // =================================================================
            Container(
              width: 50,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: areAllCitiesSelected
                    ? const Color(0xFF06291E).withValues(alpha: 0.92)
                    : const Color(0xFF0F1B2B).withValues(alpha: 0.95),
                border: Border(
                  left: BorderSide(
                    color: flagBorderColor,
                    width: flagBorderWidth,
                  ),
                  top: BorderSide(
                    color: flagBorderColor,
                    width: flagBorderWidth,
                  ),
                  bottom: BorderSide(
                    color: flagBorderColor,
                    width: flagBorderWidth,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.14),
                    width: 1.0,
                  ),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RotatedBox(
                    quarterTurns: 3,
                    child: Image.network(
                      'https://flagcdn.com/w160/${country.code.toLowerCase()}.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          country.flagEmoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),

                  // Bayrak üzeri gölge & tint katmanı (aşırı çiğ parlamayı önler, derinlik katar)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          areAllCitiesSelected
                              ? const Color(0x6006291E)
                              : const Color(0x55000000),
                          areAllCitiesSelected
                              ? const Color(0x3506291E)
                              : const Color(0x30000000),
                          areAllCitiesSelected
                              ? const Color(0x7006291E)
                              : const Color(0x65000000),
                        ],
                      ),
                    ),
                  ),

                  // Sağ sınır boyunca yumuşak iç gölge (Banner geçiş derinliği için)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =================================================================
            // 2. SAĞ: FOTOĞRAFLI BANNER (Ülke Fotoğrafı, Degrade, İsim & Rozet)
            // =================================================================
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: bannerBorderColor,
                      width: bannerBorderWidth,
                    ),
                    bottom: BorderSide(
                      color: bannerBorderColor,
                      width: bannerBorderWidth,
                    ),
                    right: BorderSide(
                      color: bannerBorderColor,
                      width: bannerBorderWidth,
                    ),
                  ),
                ),
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
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.45, 1.0],
                        colors: [
                          isSelected
                              ? const Color(0xB806291E)
                              : const Color(0xB0060B13),
                          isSelected
                              ? const Color(0x6006291E)
                              : const Color(0x45060B13),
                          isSelected
                              ? const Color(0x7506291E)
                              : const Color(0x75060B13),
                        ],
                      ),
                    ),
                  ),

                  // Üst Sağ: Şehir Sayısı Rozeti
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        '${country.cities.length} Şehir',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),

                  // Sol Alt: Ülke İsmi & Altında Seçilen Şehirler Listesi
                  Positioned(
                    left: 12,
                    bottom: 8,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black87,
                                offset: Offset(0, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (selectedCityNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedCityNames.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: BeenHereColors.verifiedEmerald,
                              letterSpacing: -0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
}

/// Taslaktaki Fotoğraflı Lokasyon Kartı (Kıta ve Şehirler İçin)
class _LocationPhotoCard extends StatelessWidget {
  const _LocationPhotoCard({
    required this.title,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: isSelected
            ? Matrix4.translationValues(0, -4.0, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: 0.9,
          ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.38),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.18),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: 640,
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
                  stops: const [0.0, 0.40, 1.0],
                  colors: [
                    isSelected
                        ? const Color(0x6506291E)
                        : const Color(0x35060B13),
                    isSelected
                        ? const Color(0x3506291E)
                        : const Color(0x10060B13),
                    isSelected
                        ? const Color(0xEB06291E)
                        : const Color(0xDE060B13),
                  ],
                ),
              ),
            ),

            // Sol Alt: İsim (Sevilla, Cadiz, Madrid...)
            Positioned(
              left: 10,
              right: 10,
              bottom: 8,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black87,
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
    final bool canClear = viewModel.hasAnyDestinationSelected;

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
              width: 48,
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
                  size: 18,
                  color: canGoBack
                      ? BeenHereColors.textPrimary
                      : BeenHereColors.textSecondary.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Orta: Seçimleri Temizle Butonu
        Tooltip(
          message: 'Seçimleri Temizle',
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: canClear ? 1.0 : 0.4,
            child: Material(
              key: const ValueKey<String>('wizard-clear-selections-button'),
              color: BeenHereColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: canClear
                    ? () {
                        HapticFeedback.lightImpact();
                        viewModel.clearAllDestinationSelections();
                        if (viewModel.currentStep != RouteWizardStep.locations) {
                          viewModel.goToStep(RouteWizardStep.locations);
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: canClear
                          ? BeenHereColors.borderSubtle
                          : BeenHereColors.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIcons.arrowCounterClockwise(
                          PhosphorIconsStyle.bold,
                        ),
                        size: 16,
                        color: canClear
                            ? BeenHereColors.textPrimary
                            : BeenHereColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Temizle',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: canClear
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
        ),

        const SizedBox(width: 8),

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
              Text(
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
                  Text(
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
                style: TextStyle(
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
              Text(
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
