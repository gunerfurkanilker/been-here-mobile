import 'package:flutter/foundation.dart';
import '../../../../data/repositories/static_home_routes_repository.dart';
import '../../../../data/stores/geography_store.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/filters/geography_tree_filter_mixin.dart';

class HomeFeedViewModel extends ChangeNotifier with GeographyTreeFilterMixin {
  HomeFeedViewModel({
    StaticHomeRoutesRepository? repository,
    this._geographyStore,
  }) : _repository = repository ?? StaticHomeRoutesRepository() {
    _geographyStore?.addListener(_handleGeographyStoreChanged);
  }

  final StaticHomeRoutesRepository _repository;
  final GeographyStore? _geographyStore;

  void _handleGeographyStoreChanged() {
    notifyListeners();
  }

  @override
  GeographyStore? get geographyStore => _geographyStore;

  /// Kullanıcının detay ekranında sorduğu yeni soruları statik oturumda tutar
  final Map<String, List<RouteQuestionItem>> _sessionQuestionsByRoute = {};

  /// Kullanıcının liste sonunda knob'u %100 doldurarak açtığı ek rota paketi sayısı
  int _unlockedBatchesCount = 0;
  String _lastFilterSignature = '';

  @override
  int get activeFilterCount =>
      enabledFilterPillsCount + (isBudgetFilterActive ? 1 : 0);

  @override
  List<RouteContinentCatalogItem> get searchContinentsCatalog {
    final store = _geographyStore;
    if (store != null &&
        store.hasLoaded &&
        store.continentsCatalog.isNotEmpty) {
      return store.continentsCatalog;
    }
    return StaticHomeRoutesRepository.continentsCatalog;
  }

  @override
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      final dbSuggestions = store.buildSearchSuggestions(
        query,
        lang: store.lang,
      );
      if (dbSuggestions.isNotEmpty) {
        return dbSuggestions;
      }
    }
    return _repository.buildSearchSuggestions(query);
  }

  @override
  int countItemsForContinent(ContinentFilter continent) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      return store.countRoutesForContinent(continent);
    }
    return _repository.countRoutesForContinent(continent);
  }

  @override
  int countItemsForRegion(RouteRegionCatalogItem region) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      return store.countRoutesForRegion(region.id);
    }
    return _repository.countRoutesForRegion(region);
  }

  @override
  String get itemCountUnitLabel => 'Rota';

  @override
  void resetToGlobal() {
    if (isBudgetFilterActive) {
      resetBudgetFilter();
    }
    super.resetToGlobal();
  }

  String _computeFilterSignature() {
    final pillsSig =
        filterPills.map((p) => '${p.id}:${p.isEnabled}').join(',');
    return '$pillsSig|$selectedMinBudgetTl|$selectedMaxBudgetTl';
  }

  @override
  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent,
  ) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      return store.getCountriesForContinent(continent, useRoutesCount: true);
    }
    return _repository.getCountriesForContinent(continent);
  }

  @override
  List<String> getCitiesForCountry(String countryCode) {
    final store = _geographyStore;
    if (store != null && store.hasLoaded) {
      return store.getCitiesForCountry(countryCode);
    }
    return _repository.getCitiesForCountry(countryCode);
  }

  List<PublishedRouteFeedItem> get feedRoutes {
    final currentSig = _computeFilterSignature();
    if (_lastFilterSignature != currentSig) {
      _lastFilterSignature = currentSig;
      _unlockedBatchesCount = 0;
    }

    final baseRoutes = _repository.getFilteredFeedRoutesByPills(
      activePills: filterPills,
      minBudgetTl: selectedMinBudgetTl,
      maxBudgetTl: selectedMaxBudgetTl,
    );

    if (baseRoutes.isEmpty || _unlockedBatchesCount == 0) {
      return baseRoutes;
    }

    final combined = List<PublishedRouteFeedItem>.from(baseRoutes);
    for (int b = 1; b <= _unlockedBatchesCount; b++) {
      combined.addAll(
        _repository.getNextBatchRoutes(
          batchIndex: b,
          baseFilteredRoutes: baseRoutes,
        ),
      );
    }
    return combined;
  }

  /// Liste sonunda kullanıcı parmağını yukarı sürüp knob'u %100 yaptığında yeni rotaları yükler
  void unlockNextRoutesBatch() {
    _unlockedBatchesCount++;
    notifyListeners();
  }

  /// Aktif filtre hapları ve bütçe aralığına göre eşleşen rota sayısını döndürür.
  int get geographyFilteredRoutesCount {
    return _repository
        .getFilteredFeedRoutesByPills(
          activePills: filterPills,
          minBudgetTl: selectedMinBudgetTl,
          maxBudgetTl: selectedMaxBudgetTl,
        )
        .length;
  }

  List<RouteQuestionItem> getQuestionsForRoute(PublishedRouteFeedItem route) {
    final extra = _sessionQuestionsByRoute[route.id] ?? const [];
    return [...extra, ...route.questions];
  }

  void addQuestionToRoute(String routeId, String questionText) {
    final trimmed = questionText.trim();
    if (trimmed.isEmpty) return;

    final existing = List<RouteQuestionItem>.from(
      _sessionQuestionsByRoute[routeId] ?? const [],
    );
    existing.insert(
      0,
      RouteQuestionItem(
        id: 'q-local-${DateTime.now().millisecondsSinceEpoch}',
        askerUsername: 'sen_gezgin',
        questionText: trimmed,
        createdAtLabel: 'Az önce',
      ),
    );
    _sessionQuestionsByRoute[routeId] = existing;
    notifyListeners();
  }

  @override
  void dispose() {
    _geographyStore?.removeListener(_handleGeographyStoreChanged);
    disposeSearchDebounce();
    super.dispose();
  }
}
