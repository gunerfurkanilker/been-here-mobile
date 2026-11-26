import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/theme/been_here_theme.dart';
import '../view_models/route_builder_view_model.dart';

/// Rota Oluşturma Sihirbazı Adım 3: Kompakt ve Sade Bütçe Seçimi
///
/// 1. Tek Bütünleşik Kart:
///    - Kullanıcı Para Birimi (`TRY ₺`) + sağ üst köşede kompakt `Bütçe Yok` toggle hapı
///      + kompakt Min — Maks (`0` — `Sınırsız`) kutuları
///    - Sabit Küresel Karşılık (`USD $`) + sade kur metni + Min — Maks kutuları
///    - Kullanıcı eklediyse ekstra ülke para birimleri (ince yatay çizgiyle ayrılmış)
///    - Bütçe kapalıyken aynı sağ üst köşede aktif `Bütçe Yok ✓` hapı bulunan kompakt kart
/// 2. Hafif alt aksiyon: `+ Ülke Para Birimi Ekle`
class RouteBudgetSelectorStep extends StatelessWidget {
  const RouteBudgetSelectorStep({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final userCode = viewModel.userCurrencyCode;
    final secondaryCode = viewModel.secondaryCurrencyCode;
    final addedCurrencies = viewModel.addedCountryCurrencies;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      clipBehavior: Clip.hardEdge,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        if (!viewModel.isBudgetEnabled)
          _BudgetDisabledCompactCard(viewModel: viewModel)
        else ...[
          Container(
            key: const ValueKey<String>('budget-unified-card'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: BeenHereColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BeenHereColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PrimaryCurrencySection(
                  key: ValueKey<String>('budget-card-$userCode'),
                  viewModel: viewModel,
                ),
                if (userCode != secondaryCode) ...[
                  const _BudgetSectionDivider(),
                  _SecondaryCurrencySection(
                    key: ValueKey<String>('budget-card-$secondaryCode'),
                    viewModel: viewModel,
                    currencyCode: secondaryCode,
                  ),
                ],
                for (final option in addedCurrencies) ...[
                  const _BudgetSectionDivider(),
                  _AddedCountryCurrencySection(
                    key: ValueKey<String>('budget-card-${option.code}'),
                    viewModel: viewModel,
                    option: option,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _AddCountryCurrencyActionButton(
            viewModel: viewModel,
            onTap: () => _showCountryCurrencyPickerSheet(context),
          ),
        ],
      ],
    );
  }

  Future<void> _showCountryCurrencyPickerSheet(BuildContext context) async {
    HapticFeedback.lightImpact();
    FocusManager.instance.primaryFocus?.unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _CountryCurrencyPickerSheet(viewModel: viewModel);
      },
    );
  }
}

// =============================================================================
// KOMPAKT "BÜTÇE YOK" TOGGLE HAPI & KAPALI DURUM KARTI
// =============================================================================
class _BudgetNoLimitTogglePill extends StatelessWidget {
  const _BudgetNoLimitTogglePill({required this.viewModel});

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isEnabled = viewModel.isBudgetEnabled;
    final isDark = BeenHereThemeController.instance.isDark;

    return Material(
      color: !isEnabled
          ? BeenHereColors.primaryCompass.withValues(
              alpha: isDark ? 0.22 : 0.28,
            )
          : BeenHereColors.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        key: const ValueKey<String>('budget-no-limit-pill'),
        onTap: () {
          HapticFeedback.selectionClick();
          FocusManager.instance.primaryFocus?.unfocus();
          viewModel.toggleBudgetEnabled();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: !isEnabled
                  ? BeenHereColors.primaryCompass
                  : BeenHereColors.borderSubtle.withValues(alpha: 0.75),
            ),
          ),
          child: Text(
            !isEnabled ? 'Bütçe Yok ✓' : 'Bütçe Yok',
            maxLines: 1,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: !isEnabled
                  ? BeenHereColors.textPrimary
                  : BeenHereColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetDisabledCompactCard extends StatelessWidget {
  const _BudgetDisabledCompactCard({required this.viewModel});

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('budget-disabled-state-card'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BeenHereColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              'Bütçe sınırı belirtilmedi',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: BeenHereColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _BudgetNoLimitTogglePill(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _BudgetSectionDivider extends StatelessWidget {
  const _BudgetSectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: BeenHereColors.borderSubtle.withValues(alpha: 0.55),
    );
  }
}

// =============================================================================
// BLOK 1: KULLANICI PARA BİRİMİ (TRY ₺)
// =============================================================================
class _PrimaryCurrencySection extends StatelessWidget {
  const _PrimaryCurrencySection({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final code = viewModel.userCurrencyCode;
    final symbol = viewModel.currencySymbolFor(code);
    final flag = viewModel.currencyFlagFor(code);
    final range = viewModel.budgetAmountForCurrency(code);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '$flag $code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.1,
                    color: BeenHereColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BudgetNoLimitTogglePill(viewModel: viewModel),
            ],
          ),
          const SizedBox(height: 8),
          _MinMaxCurrencyInputRow(
            currencyCode: code,
            symbol: symbol,
            minAmount: range.min,
            maxAmount: range.max,
            onMinChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: code,
              minAmount: val,
            ),
            onMaxChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: code,
              maxAmount: val,
            ),
            onMaxCleared: () => viewModel.updateBudgetRangeForCurrency(
              currencyCode: code,
              clearMaxAmount: true,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BLOK 2: SABİT KÜRESEL KARŞILIK (USD $)
// =============================================================================
class _SecondaryCurrencySection extends StatelessWidget {
  const _SecondaryCurrencySection({
    super.key,
    required this.viewModel,
    required this.currencyCode,
  });

  final RouteBuilderViewModel viewModel;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final symbol = viewModel.currencySymbolFor(currencyCode);
    final flag = viewModel.currencyFlagFor(currencyCode);
    final range = viewModel.budgetAmountForCurrency(currencyCode);
    final rateText = viewModel.exchangeRateSummary(
      currencyCode,
      viewModel.userCurrencyCode,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$flag $currencyCode',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rateText,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MinMaxCurrencyInputRow(
            currencyCode: currencyCode,
            symbol: symbol,
            minAmount: range.min,
            maxAmount: range.max,
            onMinChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: currencyCode,
              minAmount: val,
            ),
            onMaxChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: currencyCode,
              maxAmount: val,
            ),
            onMaxCleared: () => viewModel.updateBudgetRangeForCurrency(
              currencyCode: currencyCode,
              clearMaxAmount: true,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BLOK 3+: KULLANICININ EKLEDİĞİ ÜLKE PARA BİRİMLERİ (ÖR. THB, EUR)
// =============================================================================
class _AddedCountryCurrencySection extends StatelessWidget {
  const _AddedCountryCurrencySection({
    super.key,
    required this.viewModel,
    required this.option,
  });

  final RouteBuilderViewModel viewModel;
  final BuilderCountryCurrencyOption option;

  @override
  Widget build(BuildContext context) {
    final range = viewModel.budgetAmountForCurrency(option.code);
    final rateText = viewModel.exchangeRateSummary(
      viewModel.userCurrencyCode,
      option.code,
    );
    final flagLabel = option.flagsText.isNotEmpty
        ? option.flagsText
        : viewModel.currencyFlagFor(option.code);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      flex: 0,
                      child: Text(
                        '$flagLabel ${option.code}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                          color: BeenHereColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        rateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                key: ValueKey<String>('budget-remove-currency-${option.code}'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  FocusManager.instance.primaryFocus?.unfocus();
                  viewModel.removeCountryCurrency(option.code);
                },
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIcons.x(PhosphorIconsStyle.bold),
                      size: 14,
                      color: BeenHereColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _MinMaxCurrencyInputRow(
            currencyCode: option.code,
            symbol: option.symbol,
            minAmount: range.min,
            maxAmount: range.max,
            onMinChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: option.code,
              minAmount: val,
            ),
            onMaxChanged: (val) => viewModel.updateBudgetRangeForCurrency(
              currencyCode: option.code,
              maxAmount: val,
            ),
            onMaxCleared: () => viewModel.updateBudgetRangeForCurrency(
              currencyCode: option.code,
              clearMaxAmount: true,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HAFİF "+ Ülke Para Birimi Ekle" AKSİYONU & SADE BOTTOM SHEET SEÇİCİSİ
// =============================================================================
class _AddCountryCurrencyActionButton extends StatelessWidget {
  const _AddCountryCurrencyActionButton({
    required this.viewModel,
    required this.onTap,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unaddedSelected = viewModel.availableSelectedCountryCurrencies
        .where((opt) => !viewModel.isCountryCurrencyAdded(opt.code))
        .toList(growable: false);
    final previewCodes = unaddedSelected.map((e) => e.code).take(3).join(', ');

    return Material(
      color: BeenHereColors.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        key: const ValueKey<String>('budget-add-currency-button'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: BeenHereColors.borderSubtle.withValues(alpha: 0.85),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '+ Ülke Para Birimi Ekle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BeenHereColors.textPrimary,
                  ),
                ),
              ),
              if (previewCodes.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  flex: 0,
                  child: Text(
                    previewCodes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: BeenHereColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryCurrencyPickerSheet extends StatefulWidget {
  const _CountryCurrencyPickerSheet({required this.viewModel});

  final RouteBuilderViewModel viewModel;

  @override
  State<_CountryCurrencyPickerSheet> createState() =>
      _CountryCurrencyPickerSheetState();
}

class _CountryCurrencyPickerSheetState
    extends State<_CountryCurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesOption(BuilderCountryCurrencyOption option, String q) {
    if (q.isEmpty) return true;
    final lowerQ = q.trim().toLowerCase();
    return option.code.toLowerCase().contains(lowerQ) ||
        option.nameTr.toLowerCase().contains(lowerQ) ||
        option.countriesSummary.toLowerCase().contains(lowerQ);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        key: const ValueKey<String>('budget-currency-picker-sheet'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: BeenHereColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: BeenHereColors.borderSubtle),
        ),
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            final selectedOptions = widget
                .viewModel
                .availableSelectedCountryCurrencies
                .where((opt) => _matchesOption(opt, _query))
                .toList(growable: false);
            final popularOptions = widget.viewModel.popularExtraCurrencies
                .where((opt) => _matchesOption(opt, _query))
                .toList(growable: false);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ülke Para Birimi Ekle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: PhosphorIcon(
                          PhosphorIcons.x(PhosphorIconsStyle.bold),
                          size: 17,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: TextField(
                    key: const ValueKey<String>('budget-currency-search-input'),
                    controller: _searchController,
                    onChanged: (val) => setState(() => _query = val),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: BeenHereColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Para birimi veya ülke ara (EUR, THB...)',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: BeenHereColors.textSecondary,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 11, right: 7),
                        child: PhosphorIcon(
                          PhosphorIcons.magnifyingGlass(
                            PhosphorIconsStyle.regular,
                          ),
                          size: 16,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      filled: true,
                      fillColor: BeenHereColors.surfaceElevated,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                          color: BeenHereColors.borderSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                          color: BeenHereColors.borderSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide(
                          color: BeenHereColors.primaryCompass,
                        ),
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      2,
                      16,
                      (bottomSafe > 0 ? bottomSafe : 12) + 8,
                    ),
                    children: [
                      if (widget
                          .viewModel
                          .availableSelectedCountryCurrencies
                          .isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Seçili ülkelerin zaten ${widget.viewModel.userCurrencyCode} / ${widget.viewModel.secondaryCurrencyCode} kullanıyor. Dilersen aşağıdan diğer popüler para birimlerini ekleyebilirsin.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                              color: BeenHereColors.textSecondary,
                            ),
                          ),
                        )
                      else if (selectedOptions.isNotEmpty) ...[
                        const _SheetSectionTitle(title: 'Seçili Ülkeler'),
                        const SizedBox(height: 6),
                        for (final option in selectedOptions)
                          _CurrencyPickerOptionTile(
                            option: option,
                            rateText: widget.viewModel.exchangeRateSummary(
                              widget.viewModel.userCurrencyCode,
                              option.code,
                            ),
                            isAdded: widget.viewModel.isCountryCurrencyAdded(
                              option.code,
                            ),
                            onTap: () => _handleSelectOption(context, option),
                          ),
                        const SizedBox(height: 8),
                      ],
                      if (popularOptions.isNotEmpty) ...[
                        const _SheetSectionTitle(
                          title: 'Diğer Popüler Para Birimleri',
                        ),
                        const SizedBox(height: 6),
                        for (final option in popularOptions)
                          _CurrencyPickerOptionTile(
                            option: option,
                            rateText: widget.viewModel.exchangeRateSummary(
                              widget.viewModel.userCurrencyCode,
                              option.code,
                            ),
                            isAdded: widget.viewModel.isCountryCurrencyAdded(
                              option.code,
                            ),
                            onTap: () => _handleSelectOption(context, option),
                          ),
                      ],
                      if (selectedOptions.isEmpty && popularOptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: Text(
                              'Aramana uygun para birimi bulunamadı.',
                              style: TextStyle(
                                fontSize: 13,
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleSelectOption(
    BuildContext sheetContext,
    BuilderCountryCurrencyOption option,
  ) {
    HapticFeedback.selectionClick();
    final alreadyAdded = widget.viewModel.isCountryCurrencyAdded(option.code);
    if (alreadyAdded) {
      widget.viewModel.removeCountryCurrency(option.code);
    } else {
      widget.viewModel.addCountryCurrency(option.code);
      Navigator.of(sheetContext).pop();
    }
  }
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: BeenHereColors.textSecondary,
      ),
    );
  }
}

class _CurrencyPickerOptionTile extends StatelessWidget {
  const _CurrencyPickerOptionTile({
    required this.option,
    required this.rateText,
    required this.isAdded,
    required this.onTap,
  });

  final BuilderCountryCurrencyOption option;
  final String rateText;
  final bool isAdded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = BeenHereThemeController.instance.isDark;
    final flagLabel = option.flagsText.isNotEmpty ? option.flagsText : '💱';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isAdded
            ? BeenHereColors.primaryCompass.withValues(
                alpha: isDark ? 0.18 : 0.24,
              )
            : BeenHereColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: ValueKey<String>('budget-currency-option-${option.code}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAdded
                    ? BeenHereColors.primaryCompass
                    : BeenHereColors.borderSubtle.withValues(alpha: 0.75),
              ),
            ),
            child: Row(
              children: [
                Text(flagLabel, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${option.nameTr} (${option.code} ${option.symbol})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BeenHereColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        option.countriesSummary.isNotEmpty
                            ? '${option.countriesSummary} • $rateText'
                            : rateText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAdded ? 'Eklendi' : 'Ekle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isAdded
                        ? BeenHereColors.secondaryAmber
                        : BeenHereColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// KOMPAKT TEK SATIR MİN — MAKS GİRİŞ KUTULARI
// =============================================================================
class _MinMaxCurrencyInputRow extends StatelessWidget {
  const _MinMaxCurrencyInputRow({
    required this.currencyCode,
    required this.symbol,
    required this.minAmount,
    required this.maxAmount,
    required this.onMinChanged,
    required this.onMaxChanged,
    required this.onMaxCleared,
  });

  final String currencyCode;
  final String symbol;
  final double minAmount;
  final double? maxAmount;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;
  final VoidCallback onMaxCleared;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CurrencyAmountInputBox(
            key: ValueKey<String>('budget-input-box-$currencyCode-min'),
            fieldKey: ValueKey<String>('budget-input-$currencyCode-min'),
            label: 'Min',
            symbol: symbol,
            amount: minAmount,
            onAmountChanged: onMinChanged,
            onCleared: () => onMinChanged(0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BeenHereColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: _CurrencyAmountInputBox(
            key: ValueKey<String>('budget-input-box-$currencyCode-max'),
            fieldKey: ValueKey<String>('budget-input-$currencyCode-max'),
            label: 'Maks',
            symbol: symbol,
            amount: maxAmount,
            placeholder: 'Sınırsız',
            onAmountChanged: onMaxChanged,
            onCleared: onMaxCleared,
          ),
        ),
      ],
    );
  }
}

class _CurrencyAmountInputBox extends StatefulWidget {
  const _CurrencyAmountInputBox({
    super.key,
    required this.fieldKey,
    required this.label,
    required this.symbol,
    required this.amount,
    required this.onAmountChanged,
    this.placeholder,
    this.onCleared,
  });

  final Key fieldKey;
  final String label;
  final String symbol;
  final double? amount;
  final String? placeholder;
  final ValueChanged<double> onAmountChanged;
  final VoidCallback? onCleared;

  @override
  State<_CurrencyAmountInputBox> createState() =>
      _CurrencyAmountInputBoxState();
}

class _CurrencyAmountInputBoxState extends State<_CurrencyAmountInputBox> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  static String _formatAmountText(double? value) {
    if (value == null) return '';
    return RouteBuilderViewModel.formatGroupedInteger(value);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _formatAmountText(widget.amount),
    );
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _CurrencyAmountInputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final formatted = _formatAmountText(widget.amount);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_focusNode.hasFocus) {
      final formatted = _formatAmountText(widget.amount);
      if (_controller.text != formatted) {
        _controller.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    final isOpenEnded = widget.amount == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: BeenHereColors.surfaceElevated,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isFocused
                ? BeenHereColors.primaryCompass
                : BeenHereColors.borderSubtle.withValues(alpha: 0.75),
            width: isFocused ? 1.3 : 0.9,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: BeenHereColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.symbol,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isOpenEnded
                    ? BeenHereColors.textSecondary.withValues(alpha: 0.65)
                    : BeenHereColors.secondaryAmber,
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: TextField(
                key: widget.fieldKey,
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.placeholder,
                  hintMaxLines: 1,
                  hintStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.72),
                  ),
                ),
                onChanged: (raw) {
                  if (raw.trim().isEmpty) {
                    if (widget.onCleared != null) {
                      widget.onCleared!();
                    } else {
                      widget.onAmountChanged(0);
                    }
                    return;
                  }
                  final parsed =
                      RouteBuilderViewModel.parseBudgetAmountInput(raw);
                  if (parsed != null) {
                    widget.onAmountChanged(parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
