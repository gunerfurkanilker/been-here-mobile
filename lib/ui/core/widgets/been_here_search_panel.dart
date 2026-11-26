import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../domain/models/route_feed_models.dart';
import '../filters/been_here_search_filter_controller.dart';
import '../filters/geography_tree_filter_mixin.dart';
import '../theme/been_here_theme.dart';

/// Rotalar, Mekanlar ve Rota Oluşturma ekranlarının ortak kullandığı
/// tam ekran Arama & Kıta/Bölge Keşif Paneli.
class BeenHereSearchPanel extends StatefulWidget {
  const BeenHereSearchPanel({
    super.key,
    required this.controller,
    this.searchHintText = 'Ülke, konum veya şehir ismi ile ara...',
  });

  final BeenHereSearchFilterController controller;
  final String searchHintText;

  @override
  State<BeenHereSearchPanel> createState() => _BeenHereSearchPanelState();
}

class _BeenHereSearchPanelState extends State<BeenHereSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late List<RouteFeedFilterPill> _pendingPills;
  bool _tappedSuggestionForCurrentText = false;
  late final ScrollController _suggestionsScrollController;

  @override
  void initState() {
    super.initState();
    _suggestionsScrollController = ScrollController();
    _pendingPills =
        List<RouteFeedFilterPill>.from(widget.controller.filterPills);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onFocusChanged);
    _suggestionsScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isPillSelected(String pillId) {
    return _pendingPills.any((p) => p.id == pillId);
  }

  void _togglePendingPill(
    RouteFeedFilterPill pill, {
    bool fromSuggestion = false,
  }) {
    setState(() {
      if (fromSuggestion) {
        _tappedSuggestionForCurrentText = true;
      }
      final existingIndex = _pendingPills.indexWhere((p) => p.id == pill.id);
      if (existingIndex != -1) {
        _pendingPills.removeAt(existingIndex);
      } else {
        if (pill.type == RouteFilterPillType.keyword) {
          _pendingPills.removeWhere(
            (p) => p.type == RouteFilterPillType.keyword,
          );
        }
        _pendingPills.add(pill.copyWith(isEnabled: true));
      }
    });
  }

  void _clearAllPending() {
    setState(() {
      _pendingPills.clear();
      _searchController.clear();
      _tappedSuggestionForCurrentText = false;
    });
  }

  void _commitAndClose() {
    final trimmed = _searchController.text.trim();
    if (trimmed.isNotEmpty && !_tappedSuggestionForCurrentText) {
      final normalized = GeographyTreeFilterMixin.normalizeTr(trimmed);
      final keywordPill = RouteFeedFilterPill(
        id: 'keyword:$normalized',
        type: RouteFilterPillType.keyword,
        label: '"$trimmed"',
        keyword: trimmed,
      );
      if (!_isPillSelected(keywordPill.id)) {
        _pendingPills.removeWhere(
          (p) => p.type == RouteFilterPillType.keyword,
        );
        _pendingPills.add(keywordPill);
      }
    }

    widget.controller.applyFilterPills(_pendingPills);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeenHereColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÜST BAŞLIK & ARAMA KUTUSU
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Geri',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      color: BeenHereColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: BeenHereColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _searchFocusNode.hasFocus
                              ? BeenHereColors.primaryCompass
                              : BeenHereColors.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          PhosphorIcon(
                            PhosphorIconsRegular.magnifyingGlass,
                            size: 19,
                            color: BeenHereColors.primaryCompass,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onChanged: (_) {
                                setState(() {
                                  _tappedSuggestionForCurrentText = false;
                                });
                              },
                              onSubmitted: (_) => _commitAndClose(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: BeenHereColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.searchHintText,
                                hintStyle: TextStyle(
                                  fontSize: 13.5,
                                  color: BeenHereColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Aramayı Temizle',
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _tappedSuggestionForCurrentText = false;
                                });
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                size: 19,
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. KAYDIRILABİLİR İÇERİK: ARAMA SONUÇLARI & KITALAR
            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final suggestions = widget.controller.buildSearchSuggestions(
                    _searchController.text,
                  );
                  final continents = widget.controller.searchContinentsCatalog;
                  final hasQuery = _searchController.text.trim().isNotEmpty;

                  return SingleChildScrollView(
                    key: const ValueKey<String>('been_here_search_panel_scroll'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // "Arama Sonuçları" Bölümü
                        _buildSearchResultsCard(
                          suggestions: suggestions,
                          hasQuery: hasQuery,
                        ),

                        const SizedBox(height: 22),

                        // "Kıtalar" Bölümü Başlığı
                        Row(
                          children: [
                            PhosphorIcon(
                              PhosphorIconsDuotone.globeHemisphereWest,
                              size: 20,
                              color: BeenHereColors.primaryCompass,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kıtalar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Kıta Kartı + Altındaki Yatay Bölge Slider'ı
                        for (final continent in continents) ...[
                          _buildContinentSection(continent),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // 3. SABİT ALT AKSİYON ÇUBUĞU ("Tümünü Temizle" & "Arama")
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: BeenHereColors.surface,
                border: Border(
                  top: BorderSide(
                    color: BeenHereColors.borderSubtle,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: _clearAllPending,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BeenHereColors.textPrimary,
                      side: BorderSide(
                        color: BeenHereColors.borderSubtle,
                        width: 1.1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tümünü Temizle',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _commitAndClose,
                      style: FilledButton.styleFrom(
                        backgroundColor: BeenHereColors.primaryCompass,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _pendingPills.isEmpty
                            ? 'Arama'
                            : 'Arama (${_pendingPills.length})',
                        style: const TextStyle(
                          fontSize: 14.5,
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
      ),
    );
  }

  Widget _buildSearchResultsCard({
    required List<RouteSearchSuggestion> suggestions,
    required bool hasQuery,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BeenHereColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Arama Sonuçları',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: BeenHereColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!hasQuery)
                Text(
                  'Popüler Öneriler',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: BeenHereColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: hasQuery ? 320 : 256),
            child: Scrollbar(
              controller: _suggestionsScrollController,
              thumbVisibility: suggestions.length > 4,
              child: SingleChildScrollView(
                key: const ValueKey<String>(
                  'been_here_search_suggestions_scroll',
                ),
                controller: _suggestionsScrollController,
                primary: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < suggestions.length; i++) ...[
                      _buildSuggestionTile(suggestions[i]),
                      if (i != suggestions.length - 1)
                        const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(RouteSearchSuggestion suggestion) {
    final isSelected = _isPillSelected(suggestion.pill.id);

    final PhosphorIconData leadingIcon = switch (suggestion.type) {
      RouteSearchSuggestionType.keyword => PhosphorIconsRegular.magnifyingGlass,
      RouteSearchSuggestionType.district => PhosphorIconsDuotone.mapPinLine,
      RouteSearchSuggestionType.city => PhosphorIconsDuotone.mapPin,
      RouteSearchSuggestionType.country => PhosphorIconsDuotone.flag,
      RouteSearchSuggestionType.region => PhosphorIconsDuotone.compass,
      RouteSearchSuggestionType.continent =>
        PhosphorIconsDuotone.globeHemisphereWest,
    };

    return Material(
      color: isSelected
          ? BeenHereColors.primaryCompass.withValues(alpha: 0.14)
          : BeenHereColors.surfaceElevated.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _togglePendingPill(suggestion.pill, fromSuggestion: true),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? BeenHereColors.primaryCompass
                  : BeenHereColors.borderSubtle.withValues(alpha: 0.55),
              width: isSelected ? 1.3 : 1,
            ),
          ),
          child: Row(
            children: [
              PhosphorIcon(
                leadingIcon,
                size: 18,
                color: isSelected
                    ? BeenHereColors.primaryCompass
                    : BeenHereColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: BeenHereColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
                color: isSelected
                    ? BeenHereColors.primaryCompass
                    : BeenHereColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinentSection(RouteContinentCatalogItem continent) {
    final continentPill = RouteFeedFilterPill(
      id: 'continent:${continent.continent.code}',
      type: RouteFilterPillType.continent,
      label: continent.name,
      continent: continent.continent,
    );
    final isContinentSelected = _isPillSelected(continentPill.id);
    final itemCount =
        widget.controller.countItemsForContinent(continent.continent);
    final unitLabel = widget.controller.itemCountUnitLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tam genişlikli Kıta Görsel Kartı
        GestureDetector(
          onTap: () => _togglePendingPill(continentPill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 106,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isContinentSelected
                    ? BeenHereColors.primaryCompass
                    : BeenHereColors.borderSubtle,
                width: isContinentSelected ? 2.2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  continent.imageUrl,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BeenHereColors.surfaceElevated,
                          BeenHereColors.surface,
                        ],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.black.withValues(
                          alpha: isContinentSelected ? 0.72 : 0.65,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isContinentSelected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.primaryCompass,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Seçili',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          continent.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$itemCount $unitLabel',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Kıta Kartının Hemen Altında Yatay Kaydırılabilir Bölge Kartları
        SizedBox(
          height: 106,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: continent.regions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final region = continent.regions[index];
              return _buildRegionCard(region);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRegionCard(RouteRegionCatalogItem region) {
    final regionPill = RouteFeedFilterPill(
      id: 'region:${region.id}',
      type: RouteFilterPillType.region,
      label: region.name,
      regionId: region.id,
      continent: region.continent,
    );
    final isSelected = _isPillSelected(regionPill.id);
    final itemCount = widget.controller.countItemsForRegion(region);
    final unitLabel = widget.controller.itemCountUnitLabel;

    return GestureDetector(
      onTap: () => _togglePendingPill(regionPill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 188,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? BeenHereColors.primaryCompass
                : BeenHereColors.borderSubtle,
            width: isSelected ? 2.2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              region.imageUrl,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BeenHereColors.surface,
                      BeenHereColors.surfaceElevated,
                    ],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: isSelected ? 0.78 : 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$itemCount $unitLabel',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: BeenHereColors.primaryCompass,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    region.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    region.countryTags.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
