import 'package:flutter/foundation.dart';
import '../../../../data/repositories/static_home_routes_repository.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/filters/geography_tree_filter_mixin.dart';

class HomeFeedViewModel extends ChangeNotifier with GeographyTreeFilterMixin {
  HomeFeedViewModel({StaticHomeRoutesRepository? repository})
      : _repository = repository ?? StaticHomeRoutesRepository();

  final StaticHomeRoutesRepository _repository;

  // Kullanıcının detay ekranında sorduğu yeni soruları statik oturumda tutar
  final Map<String, List<RouteQuestionItem>> _sessionQuestionsByRoute = {};

  /// Kullanıcının liste sonunda knob'u %100 doldurarak açtığı ek rota paketi sayısı
  int _unlockedBatchesCount = 0;
  String _lastFilterSignature = '';

  String _computeFilterSignature() {
    return '${selectedFullContinents.join(',')}|'
        '${selectedFullCountryCodes.join(',')}|'
        '${selectedCities.join(',')}|'
        '$isNearbyMode|$committedSearchQuery|'
        '$selectedMinBudgetTl|$selectedMaxBudgetTl';
  }

  @override
  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent,
  ) {
    return _repository.getCountriesForContinent(continent);
  }

  @override
  List<String> getCitiesForCountry(String countryCode) {
    return _repository.getCitiesForCountry(countryCode);
  }

  List<PublishedRouteFeedItem> get feedRoutes {
    final currentSig = _computeFilterSignature();
    if (_lastFilterSignature != currentSig) {
      _lastFilterSignature = currentSig;
      _unlockedBatchesCount = 0;
    }

    final baseRoutes = _repository.getFilteredFeedRoutesByHierarchy(
      selectedFullContinents: selectedFullContinents,
      selectedFullCountries: selectedFullCountryCodes,
      selectedCities: selectedCities,
      isNearbyPriority: isNearbyMode,
      searchQuery: committedSearchQuery,
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

  /// Çekmece içindeki "Uygula (X Rota)" butonunda
  /// seçilen ülke/şehir ağacına ve bütçeye ait rota sayısını göstermek için kullanılır.
  int get geographyFilteredRoutesCount {
    return _repository
        .getFilteredFeedRoutesByHierarchy(
          selectedFullContinents: selectedFullContinents,
          selectedFullCountries: selectedFullCountryCodes,
          selectedCities: selectedCities,
          isNearbyPriority: false,
          searchQuery: committedSearchQuery,
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
    disposeSearchDebounce();
    super.dispose();
  }
}
