import 'package:flutter/foundation.dart';
import '../../../domain/models/route_feed_models.dart';

/// Ortak arama çubuğu (`GeographyTreeFilterBar`), tam ekran arama & kıta/bölge
/// keşif paneli (`BeenHereSearchPanel`) ve toggle/kaldırılabilir filtre hapları
/// için paylaşılan ViewModel/Controller sözleşmesi.
abstract interface class BeenHereSearchFilterController implements Listenable {
  List<RouteFeedFilterPill> get filterPills;
  bool get hasFilterPills;
  int get enabledFilterPillsCount;
  int get activeFilterCount;

  List<RouteContinentCatalogItem> get searchContinentsCatalog;
  List<RouteSearchSuggestion> buildSearchSuggestions(String query);
  Future<void> triggerRemoteGeographySearch(String query);
  int countItemsForContinent(ContinentFilter continent);
  int countItemsForRegion(RouteRegionCatalogItem region);
  String get itemCountUnitLabel;

  void applyFilterPills(List<RouteFeedFilterPill> pills);
  void toggleFilterPill(String pillId);
  void removeFilterPill(String pillId);
  void clearAllFilterPills();

  // Anlık Konum & Bütçe Aralığı desteği (tüm tüketiciler için opsiyonel aktif edilir)
  bool get isNearbyMode;
  String get detectedLocationLabel;
  void toggleNearbySearch();

  double get selectedMinBudgetTl;
  double get selectedMaxBudgetTl;
  bool get isBudgetFilterActive;
  String get budgetFilterCompactLabel;
  void updateBudgetRange(double minTl, double maxTl);
  void resetBudgetFilter();
}
