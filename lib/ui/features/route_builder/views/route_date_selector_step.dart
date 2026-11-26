import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// `calendar_date_picker2` 4.0.0 dahili olarak `material_ui` kullandığı için
// `Material` / `MaterialLocalizations` / `Theme` köprüsünü sağlar.
// ignore: depend_on_referenced_packages
import 'package:material_ui/material_ui.dart' as mui;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../domain/models/geography_models.dart';
import '../../../core/theme/been_here_theme.dart';
import '../view_models/route_builder_view_model.dart';

/// Rota Oluşturma Sihirbazı Adım 2: Tarih Aralığı Seçimi (4 Modlu Akış)
///
/// 1. Ana Ekran (`hub`): 2x2 Mod Kartları (Esnek Tarihler, Anlık Gezi, Mevsimler, Belirli Tarihler)
/// 2. Mod 1 (`flexibleMonths`): 3 sütunlu modernize edilmiş ay aralığı seçici
/// 3. Mod 2 (`instantCalendar`): `CalendarDatePicker2` tabanlı bugünü kapsama zorunlu takvim
/// 4. Mod 3 (`seasons`): Yarım küre algılamalı + çoklu mevsim seçici
/// 5. Mod 4 (`specificCalendar`): `CalendarDatePicker2` tabanlı ileri tarih aralığı takvimi
class RouteDateSelectorStep extends StatelessWidget {
  const RouteDateSelectorStep({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      clipBehavior: Clip.hardEdge,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildActiveSubView(context),
        ),
      ],
    );
  }

  Widget _buildActiveSubView(BuildContext context) {
    switch (viewModel.dateSubView) {
      case RouteDateSubView.hub:
        return _DateModeHubView(
          key: const ValueKey<String>('date-subview-hub'),
          viewModel: viewModel,
        );
      case RouteDateSubView.flexibleMonths:
        return _FlexibleMonthsView(
          key: const ValueKey<String>('date-subview-flexible'),
          viewModel: viewModel,
        );
      case RouteDateSubView.instantCalendar:
        return _ModernRangeCalendarView(
          key: const ValueKey<String>('date-subview-instant'),
          requireTodayInclusion: true,
          today: viewModel.todayDate,
          selectedRange: viewModel.instantTripRange,
          pendingDate: viewModel.instantTripPendingDate,
          validationError: viewModel.instantTripValidationError,
          summaryText: viewModel.instantTripRange != null
              ? viewModel.formattedDateSummary
              : null,
          shortcuts: [
            _CalendarQuickShortcut(
              key: const ValueKey<String>('instant-shortcut-today'),
              label: 'Bugün',
              range: viewModel.instantTodayRange(),
              onTap: viewModel.applyInstantTodayShortcut,
            ),
            _CalendarQuickShortcut(
              key: const ValueKey<String>('instant-shortcut-last-3-days'),
              label: 'Son 3 Gün',
              range: viewModel.instantLastDaysRange(3),
              onTap: () => viewModel.applyInstantLastDaysShortcut(3),
            ),
            _CalendarQuickShortcut(
              key: const ValueKey<String>('instant-shortcut-this-week'),
              label: 'Bu Hafta',
              range: viewModel.instantThisWeekRange(),
              onTap: viewModel.applyInstantThisWeekShortcut,
            ),
          ],
          onValueChanged: (dates) {
            HapticFeedback.selectionClick();
            viewModel.applyInstantTripCalendarDates(dates);
          },
          onClear: () {
            HapticFeedback.lightImpact();
            viewModel.clearInstantTripRange();
          },
          onBack: () {
            HapticFeedback.lightImpact();
            viewModel.returnToDateHub();
          },
        );
      case RouteDateSubView.seasons:
        return _SeasonsSelectorView(
          key: const ValueKey<String>('date-subview-seasons'),
          viewModel: viewModel,
        );
      case RouteDateSubView.specificCalendar:
        return _ModernRangeCalendarView(
          key: const ValueKey<String>('date-subview-specific'),
          requireTodayInclusion: false,
          today: viewModel.todayDate,
          selectedRange: viewModel.specificDateRange,
          pendingDate: viewModel.specificPendingStartDate,
          validationError: null,
          summaryText: viewModel.specificDateRange != null
              ? viewModel.formattedDateSummary
              : null,
          shortcuts: [
            _CalendarQuickShortcut(
              key: const ValueKey<String>('specific-shortcut-weekend'),
              label: 'Bu Hafta Sonu',
              range: viewModel.specificWeekendRange(),
              onTap: viewModel.applySpecificWeekendShortcut,
            ),
            _CalendarQuickShortcut(
              key: const ValueKey<String>('specific-shortcut-3-days'),
              label: '3 Gün',
              range: viewModel.specificDurationRange(3),
              onTap: () => viewModel.applySpecificDurationShortcut(3),
            ),
            _CalendarQuickShortcut(
              key: const ValueKey<String>('specific-shortcut-1-week'),
              label: '1 Hafta',
              range: viewModel.specificDurationRange(7),
              onTap: () => viewModel.applySpecificDurationShortcut(7),
            ),
            _CalendarQuickShortcut(
              key: const ValueKey<String>('specific-shortcut-2-weeks'),
              label: '2 Hafta',
              range: viewModel.specificDurationRange(14),
              onTap: () => viewModel.applySpecificDurationShortcut(14),
            ),
          ],
          onValueChanged: (dates) {
            HapticFeedback.selectionClick();
            viewModel.applySpecificCalendarDates(dates);
          },
          onClear: () {
            HapticFeedback.lightImpact();
            viewModel.clearSpecificDateRange();
          },
          onBack: () {
            HapticFeedback.lightImpact();
            viewModel.returnToDateHub();
          },
        );
    }
  }
}

// =============================================================================
// ORTAK ALT EKRAN BAŞLIĞI (Geri Oku + Başlık + Alt Başlık + Opsiyonel Temizle)
// =============================================================================
class _SubViewHeader extends StatelessWidget {
  const _SubViewHeader({
    required this.title,
    this.subtitle,
    required this.onBack,
    this.trailingAction,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: BeenHereColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: const ValueKey<String>('date-subview-back-button'),
            onTap: onBack,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BeenHereColors.borderSubtle),
              ),
              child: Center(
                child: PhosphorIcon(
                  PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                  size: 18,
                  color: BeenHereColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: BeenHereColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailingAction != null) ...[
          const SizedBox(width: 8),
          trailingAction!,
        ],
      ],
    );
  }
}

class _ClearPillButton extends StatelessWidget {
  const _ClearPillButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BeenHereColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Text(
            'Temizle',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: BeenHereColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 1. ANA HUB: 2x2 Tarih Aralığı Seçimi Kartları
// =============================================================================
class _DateModeHubView extends StatelessWidget {
  const _DateModeHubView({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final hasSelection = viewModel.hasSelectedDateValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tarih Aralığı Seçimi',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: BeenHereColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Seyahatine en uygun planlama yöntemini seç.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: BeenHereColors.textSecondary,
          ),
        ),
        if (hasSelection) ...[
          const SizedBox(height: 12),
          Container(
            key: const ValueKey<String>('date-hub-active-summary'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: BeenHereColors.primaryCompass.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: BeenHereColors.primaryCompass.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.checkCircle(PhosphorIconsStyle.duotone),
                  size: 18,
                  color: BeenHereColors.secondaryAmber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        viewModel.dateMode.labelTr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                      Text(
                        viewModel.formattedDateSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: BeenHereColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ClearPillButton(
                  key: const ValueKey<String>('date-hub-clear-button'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.clearDateSelection();
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DateHubModeCard(
                  key: const ValueKey<String>('date-mode-card-flexible'),
                  icon: PhosphorIcons.calendarBlank(PhosphorIconsStyle.duotone),
                  title: 'Esnek Tarihler',
                  subtitle: viewModel.flexibleStartMonth != null
                      ? viewModel.formattedFlexiblePeriod
                      : 'Başlangıç ve bitiş ayı seç',
                  isSelected: viewModel.dateMode == RouteDateMode.flexible &&
                      viewModel.flexibleStartMonth != null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.openDateModeSubView(RouteDateMode.flexible);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateHubModeCard(
                  key: const ValueKey<String>('date-mode-card-instant'),
                  icon: PhosphorIcons.backpack(PhosphorIconsStyle.duotone),
                  title: 'Anlık Gezi',
                  subtitle: viewModel.instantTripRange != null
                      ? RouteBuilderViewModel.formatShortDateRange(
                          viewModel.instantTripRange!,
                        )
                      : 'Bugünü kapsayan gezi',
                  isSelected: viewModel.dateMode == RouteDateMode.instantTrip &&
                      viewModel.instantTripRange != null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.openDateModeSubView(RouteDateMode.instantTrip);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _DateHubModeCard(
                  key: const ValueKey<String>('date-mode-card-seasons'),
                  icon: PhosphorIcons.cloudSun(PhosphorIconsStyle.duotone),
                  title: 'Mevsimler',
                  subtitle: viewModel.selectedSeasons.isNotEmpty
                      ? viewModel.formattedSelectedSeasonsTitle
                      : 'Yarım küreye göre mevsim seç',
                  isSelected: viewModel.dateMode == RouteDateMode.seasons &&
                      viewModel.selectedSeasons.isNotEmpty,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.openDateModeSubView(RouteDateMode.seasons);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateHubModeCard(
                  key: const ValueKey<String>('date-mode-card-custom'),
                  icon: PhosphorIcons.calendarCheck(PhosphorIconsStyle.duotone),
                  title: 'Belirli Tarihler',
                  subtitle: viewModel.specificDateRange != null
                      ? RouteBuilderViewModel.formatShortDateRange(
                          viewModel.specificDateRange!,
                        )
                      : 'Takvimden net gün seç',
                  isSelected: viewModel.dateMode == RouteDateMode.customRange &&
                      viewModel.specificDateRange != null,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.openDateModeSubView(RouteDateMode.customRange);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateHubModeCard extends StatelessWidget {
  const _DateHubModeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent =
        isSelected ? BeenHereColors.secondaryAmber : BeenHereColors.textPrimary;

    return Material(
      color: isSelected
          ? BeenHereColors.primaryCompass.withValues(alpha: 0.14)
          : BeenHereColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 146),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? BeenHereColors.primaryCompass
                  : BeenHereColors.borderSubtle,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BeenHereColors.primaryCompass.withValues(alpha: 0.25)
                          : BeenHereColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? BeenHereColors.primaryCompass.withValues(alpha: 0.6)
                            : BeenHereColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        icon,
                        size: 22,
                        color: isSelected
                            ? BeenHereColors.secondaryAmber
                            : BeenHereColors.primaryCompass,
                      ),
                    ),
                  ),
                  if (isSelected)
                    PhosphorIcon(
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      size: 18,
                      color: BeenHereColors.primaryCompass,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BeenHereColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. MOD 1: ESNEK TARİHLER (Modern Dönem Kartları & 3 Sütunlu Ay Seçici)
// =============================================================================
class _FlexibleMonthsView extends StatelessWidget {
  const _FlexibleMonthsView({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final months = viewModel.flexibleMonthOptions;
    final start = viewModel.flexibleStartMonth;
    final end = viewModel.flexibleEndMonth;
    final hasSelection = start != null;
    final headerTitle = hasSelection
        ? viewModel.formattedFlexiblePeriod
        : 'Esnek Tarihler';
    final headerSubtitle = start != null && end == null
        ? 'Tek ay seçildi. İstersen bitiş ayı seçerek aralık oluştur.'
        : 'Başlangıç ve bitiş ayı seçerek esnek dönem belirle.';

    final int selectedSpanMonths;
    if (start == null) {
      selectedSpanMonths = 0;
    } else if (end == null || end == start) {
      selectedSpanMonths = 1;
    } else {
      selectedSpanMonths =
          (end.year - start.year) * 12 + (end.month - start.month) + 1;
    }

    final rows = <List<DateTime>>[];
    for (int i = 0; i < months.length; i += 3) {
      rows.add(months.sublist(i, (i + 3).clamp(0, months.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: headerTitle,
          subtitle: headerSubtitle,
          onBack: () {
            HapticFeedback.lightImpact();
            viewModel.returnToDateHub();
          },
          trailingAction: hasSelection
              ? _ClearPillButton(
                  key: const ValueKey<String>('flexible-clear-button'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.clearFlexibleMonths();
                  },
                )
              : null,
        ),
        const SizedBox(height: 14),
        // Hızlı Dönem Kısayol Hapları
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickShortcutChip(
              key: const ValueKey<String>('flexible-shortcut-1-month'),
              label: 'Tek Ay',
              isSelected: selectedSpanMonths == 1,
              onTap: () {
                HapticFeedback.selectionClick();
                viewModel.applyFlexibleDurationShortcut(1);
              },
            ),
            _QuickShortcutChip(
              key: const ValueKey<String>('flexible-shortcut-2-months'),
              label: '2 Aylık Dönem',
              isSelected: selectedSpanMonths == 2,
              onTap: () {
                HapticFeedback.selectionClick();
                viewModel.applyFlexibleDurationShortcut(2);
              },
            ),
            _QuickShortcutChip(
              key: const ValueKey<String>('flexible-shortcut-3-months'),
              label: '3 Aylık Dönem',
              isSelected: selectedSpanMonths == 3,
              onTap: () {
                HapticFeedback.selectionClick();
                viewModel.applyFlexibleDurationShortcut(3);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (int r = 0; r < rows.length; r++) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int c = 0; c < 3; c++) ...[
                  if (c < rows[r].length)
                    Expanded(
                      child: _FlexibleMonthCard(
                        month: rows[r][c],
                        isStart: start != null && rows[r][c] == start,
                        isEnd: end != null && rows[r][c] == end,
                        isInRange: start != null &&
                            end != null &&
                            !rows[r][c].isBefore(start) &&
                            !rows[r][c].isAfter(end),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          viewModel.selectFlexibleMonth(rows[r][c]);
                        },
                      ),
                    )
                  else
                    const Expanded(child: SizedBox.shrink()),
                  if (c < 2) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          if (r < rows.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _FlexibleMonthCard extends StatelessWidget {
  const _FlexibleMonthCard({
    required this.month,
    required this.isStart,
    required this.isEnd,
    required this.isInRange,
    required this.onTap,
  });

  final DateTime month;
  final bool isStart;
  final bool isEnd;
  final bool isInRange;
  final VoidCallback onTap;

  PhosphorIconData _seasonIconForMonth(int monthNumber) {
    switch (monthNumber) {
      case 12:
      case 1:
      case 2:
        return PhosphorIcons.snowflake(PhosphorIconsStyle.duotone);
      case 3:
      case 4:
      case 5:
        return PhosphorIcons.flower(PhosphorIconsStyle.duotone);
      case 6:
      case 7:
      case 8:
        return PhosphorIcons.sun(PhosphorIconsStyle.duotone);
      default:
        return PhosphorIcons.leaf(PhosphorIconsStyle.duotone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final monthName = RouteBuilderViewModel.turkishMonthNames[month.month - 1];
    final isEndpoint = isStart || isEnd;

    final Color bgColor;
    final Color borderColor;
    final Color monthColor;
    final Color yearColor;
    final Color iconColor;

    if (isEndpoint) {
      bgColor = BeenHereColors.primaryCompass;
      borderColor = BeenHereColors.primaryCompass;
      monthColor = onPrimary;
      yearColor = onPrimary.withValues(alpha: 0.85);
      iconColor = onPrimary;
    } else if (isInRange) {
      bgColor = BeenHereColors.primaryCompass.withValues(alpha: 0.16);
      borderColor = BeenHereColors.primaryCompass.withValues(alpha: 0.50);
      monthColor = BeenHereColors.textPrimary;
      yearColor = BeenHereColors.textSecondary;
      iconColor = BeenHereColors.secondaryAmber;
    } else {
      bgColor = BeenHereColors.surface;
      borderColor = BeenHereColors.borderSubtle;
      monthColor = BeenHereColors.textPrimary;
      yearColor = BeenHereColors.textSecondary;
      iconColor = BeenHereColors.primaryCompass;
    }

    String? roleBadge;
    if (isStart && isEnd) {
      roleBadge = 'Seçili';
    } else if (isStart) {
      roleBadge = 'Başlangıç';
    } else if (isEnd) {
      roleBadge = 'Bitiş';
    }

    return Material(
      key: ValueKey<String>('flexible-month-${month.year}-${month.month}'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: isEndpoint ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isEndpoint
                          ? onPrimary.withValues(alpha: 0.16)
                          : BeenHereColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        _seasonIconForMonth(month.month),
                        size: 16,
                        color: iconColor,
                      ),
                    ),
                  ),
                  if (roleBadge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        roleBadge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isEndpoint ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: -0.2,
                      color: monthColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${month.year}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: yearColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. MOD 2 & MOD 4: MODERN TAKVİM (CalendarDatePicker2 — Anlık & Belirli)
// =============================================================================
class _CalendarQuickShortcut {
  const _CalendarQuickShortcut({
    required this.key,
    required this.label,
    required this.range,
    required this.onTap,
  });

  final Key key;
  final String label;
  final DateTimeRange range;
  final VoidCallback onTap;
}

class _QuickShortcutChip extends StatelessWidget {
  const _QuickShortcutChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? BeenHereColors.primaryCompass
                : BeenHereColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? BeenHereColors.primaryCompass
                  : BeenHereColors.borderSubtle,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? onPrimary : BeenHereColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernRangeCalendarView extends StatefulWidget {
  const _ModernRangeCalendarView({
    super.key,
    required this.requireTodayInclusion,
    required this.today,
    required this.selectedRange,
    required this.pendingDate,
    required this.validationError,
    required this.summaryText,
    required this.shortcuts,
    required this.onValueChanged,
    required this.onClear,
    required this.onBack,
  });

  final bool requireTodayInclusion;
  final DateTime today;
  final DateTimeRange? selectedRange;
  final DateTime? pendingDate;
  final String? validationError;
  final String? summaryText;
  final List<_CalendarQuickShortcut> shortcuts;
  final ValueChanged<List<DateTime?>> onValueChanged;
  final VoidCallback onClear;
  final VoidCallback onBack;

  @override
  State<_ModernRangeCalendarView> createState() =>
      _ModernRangeCalendarViewState();
}

class _ModernRangeCalendarViewState extends State<_ModernRangeCalendarView> {
  static const List<String> _turkishWeekdayLabelsSunFirst = <String>[
    'Paz',
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
  ];

  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedRange?.start ??
        widget.pendingDate ??
        widget.today;
    _displayedMonth = DateTime(initial.year, initial.month);
  }

  String _subtitleText() {
    if (widget.summaryText != null && widget.summaryText!.isNotEmpty) {
      return widget.summaryText!;
    }
    if (widget.requireTodayInclusion) {
      if (widget.pendingDate != null) {
        final m = RouteBuilderViewModel
            .turkishMonthNames[widget.pendingDate!.month - 1];
        return '${widget.pendingDate!.day} $m seçildi • Bugünü kapsayacak günü seçin';
      }
      final tm =
          RouteBuilderViewModel.turkishMonthNames[widget.today.month - 1];
      return 'Bugünü (${widget.today.day} $tm) kapsayan tarih aralığı seçin';
    }
    if (widget.pendingDate != null) {
      final m =
          RouteBuilderViewModel.turkishMonthNames[widget.pendingDate!.month - 1];
      return '${widget.pendingDate!.day} $m seçildi • Bitiş gününü seçin';
    }
    return 'Bugün ve sonrası için başlangıç ve bitiş günü seçin';
  }

  List<DateTime?> _calendarPickerValue() {
    if (widget.pendingDate != null) {
      return <DateTime?>[widget.pendingDate!];
    }
    if (widget.selectedRange != null) {
      return <DateTime?>[
        widget.selectedRange!.start,
        widget.selectedRange!.end,
      ];
    }
    return const <DateTime?>[];
  }

  bool _isSameDateRange(DateTimeRange a, DateTimeRange b) {
    return DateUtils.isSameDay(a.start, b.start) &&
        DateUtils.isSameDay(a.end, b.end);
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyState =
        widget.selectedRange != null || widget.pendingDate != null;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final DateTime? capsuleStart;
    final DateTime? capsuleEnd;
    final int? daysCount;
    if (widget.pendingDate != null) {
      capsuleStart = widget.pendingDate;
      capsuleEnd = null;
      daysCount = null;
    } else if (widget.selectedRange != null) {
      capsuleStart = widget.selectedRange!.start;
      capsuleEnd = widget.selectedRange!.end;
      daysCount = DateUtils.dateOnly(capsuleEnd)
              .difference(DateUtils.dateOnly(capsuleStart))
              .inDays +
          1;
    } else {
      capsuleStart = null;
      capsuleEnd = null;
      daysCount = null;
    }

    final firstDate = widget.requireTodayInclusion
        ? DateTime(widget.today.year, widget.today.month - 1, 1)
        : DateTime(widget.today.year, widget.today.month, 1);
    final lastDate = widget.requireTodayInclusion
        ? DateTime(widget.today.year, widget.today.month + 7, 0)
        : DateTime(widget.today.year + 2, 12, 31);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Seçilen Tarih Aralığı',
          subtitle: _subtitleText(),
          onBack: widget.onBack,
          trailingAction: hasAnyState
              ? _ClearPillButton(
                  key: const ValueKey<String>('calendar-clear-button'),
                  onTap: widget.onClear,
                )
              : null,
        ),
        const SizedBox(height: 12),
        // Booking / Airbnb Tarzı Üst Başlangıç & Bitiş Özet Kapsülleri
        _CalendarRangeSummaryCapsules(
          key: const ValueKey<String>('calendar-range-summary-cards'),
          startDate: capsuleStart,
          endDate: capsuleEnd,
          daysCount: daysCount,
          isSelectingEnd: widget.pendingDate != null,
        ),
        const SizedBox(height: 10),
        // Hızlı Tarih Kısayol Hapları
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final shortcut in widget.shortcuts)
              _QuickShortcutChip(
                key: shortcut.key,
                label: shortcut.label,
                isSelected: widget.pendingDate == null &&
                    widget.selectedRange != null &&
                    _isSameDateRange(widget.selectedRange!, shortcut.range),
                onTap: () {
                  HapticFeedback.selectionClick();
                  shortcut.onTap();
                  setState(() {
                    _displayedMonth = DateTime(
                      shortcut.range.start.year,
                      shortcut.range.start.month,
                    );
                  });
                },
              ),
          ],
        ),
        if (widget.requireTodayInclusion && widget.validationError == null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: BeenHereColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BeenHereColors.borderSubtle),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.info(PhosphorIconsStyle.duotone),
                  size: 16,
                  color: BeenHereColors.primaryCompass,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anlık gezide seçilen aralık bugünü mutlaka kapsamalıdır.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BeenHereColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.validationError != null) ...[
          const SizedBox(height: 10),
          Container(
            key: const ValueKey<String>('instant-trip-validation-error'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFE05252).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE05252).withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsRegular.warningCircle,
                  size: 18,
                  color: Color(0xFFE05252),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.validationError!,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: BeenHereColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Tek Modern Takvim Yüzeyi (CalendarDatePicker2)
        Container(
          key: const ValueKey<String>('modern-calendar-container'),
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Localizations.override(
            context: context,
            delegates: const <LocalizationsDelegate<dynamic>>[
              mui.DefaultMaterialLocalizations.delegate,
            ],
            child: mui.Theme(
              data: mui.ThemeData(
                brightness: BeenHereThemeController.instance.isDark
                    ? mui.Brightness.dark
                    : mui.Brightness.light,
                colorScheme: BeenHereThemeController.instance.isDark
                    ? mui.ColorScheme.dark(
                        primary: BeenHereColors.primaryCompass,
                        onPrimary: BeenHereDarkColors.background,
                        surface: BeenHereColors.surface,
                        onSurface: BeenHereColors.textPrimary,
                      )
                    : mui.ColorScheme.light(
                        primary: BeenHereColors.primaryCompass,
                        onPrimary: BeenHereLightColors.textPrimary,
                        surface: BeenHereColors.surface,
                        onSurface: BeenHereColors.textPrimary,
                      ),
              ),
              child: mui.Material(
                type: mui.MaterialType.transparency,
                child: CalendarDatePicker2(
            config: CalendarDatePicker2Config(
              calendarType: CalendarDatePicker2Type.range,
              rangeBidirectional: true,
              firstDayOfWeek: 1,
              weekdayLabels: _turkishWeekdayLabelsSunFirst,
              firstDate: firstDate,
              lastDate: lastDate,
              currentDate: widget.today,
              animateToDisplayedMonthDate: true,
              dynamicCalendarRows: true,
              dayMaxWidth: 36,
              controlsHeight: 42,
              hideMonthPickerDividers: true,
              hideYearPickerDividers: true,
              selectableDayPredicate: widget.requireTodayInclusion
                  ? null
                  : (day) => !DateUtils.dateOnly(day).isBefore(widget.today),
              selectedDayHighlightColor: BeenHereColors.primaryCompass,
              selectedRangeHighlightColor:
                  BeenHereColors.primaryCompass.withValues(alpha: 0.18),
              weekdayLabelTextStyle: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: BeenHereColors.textSecondary,
              ),
              dayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BeenHereColors.textPrimary,
              ),
              selectedDayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: onPrimary,
              ),
              selectedRangeDayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BeenHereColors.textPrimary,
              ),
              disabledDayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: BeenHereColors.textSecondary.withValues(alpha: 0.30),
              ),
              todayTextStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: BeenHereColors.secondaryAmber,
              ),
              yearTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: BeenHereColors.textPrimary,
              ),
              selectedYearTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: onPrimary,
              ),
              disabledYearTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: BeenHereColors.textSecondary.withValues(alpha: 0.30),
              ),
              monthTextStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: BeenHereColors.textPrimary,
              ),
              selectedMonthTextStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: onPrimary,
              ),
              disabledMonthTextStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: BeenHereColors.textSecondary.withValues(alpha: 0.30),
              ),
              lastMonthIcon: PhosphorIcon(
                PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                size: 16,
                color: BeenHereColors.textPrimary,
              ),
              nextMonthIcon: PhosphorIcon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 16,
                color: BeenHereColors.textPrimary,
              ),
              modePickerBuilder: ({
                required CalendarDatePicker2Mode viewMode,
                required DateTime monthDate,
                bool? isMonthPicker,
              }) {
                final isMonthBtn = isMonthPicker == true;
                final isActive = isMonthBtn
                    ? viewMode == CalendarDatePicker2Mode.month
                    : viewMode == CalendarDatePicker2Mode.year;
                final label = isMonthBtn
                    ? RouteBuilderViewModel.turkishMonthNames[monthDate.month - 1]
                    : '${monthDate.year}';

                return Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? BeenHereColors.primaryCompass.withValues(alpha: 0.20)
                          : BeenHereColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? BeenHereColors.primaryCompass
                            : BeenHereColors.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isActive
                                ? BeenHereColors.secondaryAmber
                                : BeenHereColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        PhosphorIcon(
                          isActive
                              ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                              : PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                          size: 11,
                          color: isActive
                              ? BeenHereColors.secondaryAmber
                              : BeenHereColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                );
              },
              monthBuilder: ({
                required int month,
                TextStyle? textStyle,
                BoxDecoration? decoration,
                bool? isSelected,
                bool? isDisabled,
                bool? isCurrentMonth,
              }) {
                final shortName =
                    RouteBuilderViewModel.turkishShortMonthNames[month - 1];
                return Center(
                  child: Container(
                    height: 36,
                    width: 72,
                    decoration: decoration,
                    child: Center(
                      child: Text(
                        shortName,
                        style: textStyle,
                      ),
                    ),
                  ),
                );
              },
              dayBuilder: ({
                required DateTime date,
                TextStyle? textStyle,
                BoxDecoration? decoration,
                bool? isSelected,
                bool? isDisabled,
                bool? isToday,
              }) {
                final selected = isSelected == true;
                final disabled = isDisabled == true;
                final todayFlag = isToday == true;

                BoxDecoration? effectiveDecoration = decoration;
                TextStyle? effectiveTextStyle = textStyle;

                if (todayFlag && !selected && !disabled) {
                  effectiveDecoration = BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        BeenHereColors.secondaryAmber.withValues(alpha: 0.12),
                    border: Border.all(
                      color: BeenHereColors.secondaryAmber,
                      width: 1.5,
                    ),
                  );
                  effectiveTextStyle = TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BeenHereColors.secondaryAmber,
                  );
                }

                return KeyedSubtree(
                  key: ValueKey<String>(
                    'calendar-day-${RouteBuilderViewModel.formatIsoDate(date)}',
                  ),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: effectiveDecoration,
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: effectiveTextStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            value: _calendarPickerValue(),
            displayedMonthDate: _displayedMonth,
            onDisplayedMonthChanged: (month) {
              setState(() {
                _displayedMonth = DateTime(month.year, month.month);
              });
            },
            onValueChanged: widget.onValueChanged,
          ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarRangeSummaryCapsules extends StatelessWidget {
  const _CalendarRangeSummaryCapsules({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.isSelectingEnd,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final int? daysCount;
  final bool isSelectingEnd;

  @override
  Widget build(BuildContext context) {
    final startValue = startDate != null
        ? RouteBuilderViewModel.formatDayMonthYearShort(startDate!)
        : 'Seçiniz';
    final endValue = endDate != null
        ? RouteBuilderViewModel.formatDayMonthYearShort(endDate!)
        : 'Seçiniz';

    return Row(
      children: [
        Expanded(
          child: _SummaryDateCapsule(
            key: const ValueKey<String>('calendar-summary-start-capsule'),
            label: 'Başlangıç',
            value: startValue,
            isFilled: startDate != null,
            isActive: startDate == null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: daysCount != null
                  ? BeenHereColors.primaryCompass.withValues(alpha: 0.18)
                  : BeenHereColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: daysCount != null
                    ? BeenHereColors.primaryCompass.withValues(alpha: 0.55)
                    : BeenHereColors.borderSubtle,
              ),
            ),
            child: daysCount != null
                ? Text(
                    '$daysCount Gün',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.secondaryAmber,
                    ),
                  )
                : PhosphorIcon(
                    PhosphorIcons.arrowsLeftRight(PhosphorIconsStyle.bold),
                    size: 14,
                    color: BeenHereColors.textSecondary,
                  ),
          ),
        ),
        Expanded(
          child: _SummaryDateCapsule(
            key: const ValueKey<String>('calendar-summary-end-capsule'),
            label: 'Bitiş',
            value: endValue,
            isFilled: endDate != null,
            isActive: isSelectingEnd,
          ),
        ),
      ],
    );
  }
}

class _SummaryDateCapsule extends StatelessWidget {
  const _SummaryDateCapsule({
    super.key,
    required this.label,
    required this.value,
    required this.isFilled,
    required this.isActive,
  });

  final String label;
  final String value;
  final bool isFilled;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isFilled
            ? BeenHereColors.primaryCompass.withValues(alpha: 0.12)
            : BeenHereColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive || isFilled
              ? BeenHereColors.primaryCompass.withValues(alpha: 0.65)
              : BeenHereColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: BeenHereColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isFilled ? FontWeight.w800 : FontWeight.w600,
              color: isFilled
                  ? BeenHereColors.textPrimary
                  : BeenHereColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 4. MOD 3: MEVSİMLER (Yarım Küre Toggle + Dinamik Aralık + 2x2 Mevsim Kartları)
// =============================================================================
class _SeasonsSelectorView extends StatelessWidget {
  const _SeasonsSelectorView({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  PhosphorIconData _iconForSeason(RouteSeason season, PhosphorIconsStyle style) {
    switch (season) {
      case RouteSeason.summer:
        return PhosphorIcons.sun(style);
      case RouteSeason.spring:
        return PhosphorIcons.flower(style);
      case RouteSeason.autumn:
        return PhosphorIcons.leaf(style);
      case RouteSeason.winter:
        return PhosphorIcons.snowflake(style);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeHemi = viewModel.selectedHemisphere;
    final seasonsTitle = viewModel.formattedSelectedSeasonsTitle;
    final seasonRanges = viewModel.formattedSelectedSeasonRanges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SubViewHeader(
          title: 'Mevsimler',
          onBack: () {
            HapticFeedback.lightImpact();
            viewModel.returnToDateHub();
          },
        ),
        const SizedBox(height: 14),
        // Kuzey / Güney Yarım Küre Segmented Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: _HemisphereSegmentButton(
                  key: const ValueKey<String>('hemisphere-toggle-northern'),
                  label: GeographyHemisphere.northern.labelTr,
                  isSelected: activeHemi == GeographyHemisphere.northern,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.setHemisphere(GeographyHemisphere.northern);
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _HemisphereSegmentButton(
                  key: const ValueKey<String>('hemisphere-toggle-southern'),
                  label: GeographyHemisphere.southern.labelTr,
                  isSelected: activeHemi == GeographyHemisphere.southern,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.setHemisphere(GeographyHemisphere.southern);
                  },
                ),
              ),
            ],
          ),
        ),
        if (viewModel.hasAnyDestinationSelected &&
            !viewModel.hasManualHemisphereOverride) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              PhosphorIcon(
                PhosphorIcons.compass(PhosphorIconsStyle.duotone),
                size: 14,
                color: BeenHereColors.secondaryAmber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Seçtiğin destinasyonlara göre otomatik önerildi',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        // Dinamik Seçili Mevsim Başlığı ve Ay-Yıl Aralıkları
        Container(
          key: const ValueKey<String>('seasons-dynamic-summary'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seasonsTitle.isNotEmpty
                  ? BeenHereColors.primaryCompass.withValues(alpha: 0.65)
                  : BeenHereColors.borderSubtle,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seasonsTitle.isNotEmpty ? seasonsTitle : 'Mevsim Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                seasonRanges.isNotEmpty
                    ? seasonRanges
                    : 'Aşağıdan bir veya birden fazla mevsim seçebilirsin.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: seasonRanges.isNotEmpty
                      ? BeenHereColors.secondaryAmber
                      : BeenHereColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 2x2 Mevsim Kartları: Üst [Yaz | İlkbahar], Alt [Sonbahar | Kış]
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SeasonCard(
                  key: const ValueKey<String>('season-card-summer'),
                  season: RouteSeason.summer,
                  icon: _iconForSeason(
                    RouteSeason.summer,
                    PhosphorIconsStyle.duotone,
                  ),
                  dateRangeSubtitle: viewModel.formatSeasonMonthRange(
                    RouteSeason.summer,
                  ),
                  isSelected:
                      viewModel.selectedSeasons.contains(RouteSeason.summer),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.toggleSeason(RouteSeason.summer);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeasonCard(
                  key: const ValueKey<String>('season-card-spring'),
                  season: RouteSeason.spring,
                  icon: _iconForSeason(
                    RouteSeason.spring,
                    PhosphorIconsStyle.duotone,
                  ),
                  dateRangeSubtitle: viewModel.formatSeasonMonthRange(
                    RouteSeason.spring,
                  ),
                  isSelected:
                      viewModel.selectedSeasons.contains(RouteSeason.spring),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.toggleSeason(RouteSeason.spring);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SeasonCard(
                  key: const ValueKey<String>('season-card-autumn'),
                  season: RouteSeason.autumn,
                  icon: _iconForSeason(
                    RouteSeason.autumn,
                    PhosphorIconsStyle.duotone,
                  ),
                  dateRangeSubtitle: viewModel.formatSeasonMonthRange(
                    RouteSeason.autumn,
                  ),
                  isSelected:
                      viewModel.selectedSeasons.contains(RouteSeason.autumn),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.toggleSeason(RouteSeason.autumn);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SeasonCard(
                  key: const ValueKey<String>('season-card-winter'),
                  season: RouteSeason.winter,
                  icon: _iconForSeason(
                    RouteSeason.winter,
                    PhosphorIconsStyle.duotone,
                  ),
                  dateRangeSubtitle: viewModel.formatSeasonMonthRange(
                    RouteSeason.winter,
                  ),
                  isSelected:
                      viewModel.selectedSeasons.contains(RouteSeason.winter),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    viewModel.toggleSeason(RouteSeason.winter);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HemisphereSegmentButton extends StatelessWidget {
  const _HemisphereSegmentButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: isSelected ? BeenHereColors.primaryCompass : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? onPrimary : BeenHereColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  const _SeasonCard({
    super.key,
    required this.season,
    required this.icon,
    required this.dateRangeSubtitle,
    required this.isSelected,
    required this.onTap,
  });

  final RouteSeason season;
  final PhosphorIconData icon;
  final String dateRangeSubtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? BeenHereColors.primaryCompass.withValues(alpha: 0.14)
          : BeenHereColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 122),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? BeenHereColors.primaryCompass
                  : BeenHereColors.borderSubtle,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? BeenHereColors.primaryCompass.withValues(alpha: 0.25)
                          : BeenHereColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? BeenHereColors.primaryCompass.withValues(alpha: 0.6)
                            : BeenHereColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? BeenHereColors.secondaryAmber
                            : BeenHereColors.primaryCompass,
                      ),
                    ),
                  ),
                  if (isSelected)
                    PhosphorIcon(
                      PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                      size: 18,
                      color: BeenHereColors.primaryCompass,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    season.labelTr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? BeenHereColors.secondaryAmber
                          : BeenHereColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateRangeSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: BeenHereColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
