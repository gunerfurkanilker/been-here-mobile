import 'package:flutter/foundation.dart';

enum BeenHereNavTab {
  home,
  leaderboards,
  compassRouteBuilder,
  placeSearch,
  profile,
}

class NavigationShellViewModel extends ChangeNotifier {
  BeenHereNavTab _currentTab = BeenHereNavTab.home;
  bool _isLiveGeofenceActive = false;
  bool _isPremiumUser = true;
  double _compassHeadingDegrees = 18.0;

  BeenHereNavTab get currentTab => _currentTab;
  bool get isLiveGeofenceActive => _isLiveGeofenceActive;
  bool get isPremiumUser => _isPremiumUser;
  double get compassHeadingDegrees => _compassHeadingDegrees;

  void selectTab(BeenHereNavTab tab) {
    if (_currentTab == tab && tab != BeenHereNavTab.compassRouteBuilder) {
      return;
    }
    _currentTab = tab;
    // Pusula ibresine her sekme geçişinde doğal bir sapma/yaylanma açısı ver
    _compassHeadingDegrees = (_compassHeadingDegrees + 42.0) % 360.0;
    notifyListeners();
  }

  void toggleLiveGeofenceTracker() {
    _isLiveGeofenceActive = !_isLiveGeofenceActive;
    notifyListeners();
  }

  void toggleSubscriptionTierForPreview() {
    _isPremiumUser = !_isPremiumUser;
    if (!_isPremiumUser) {
      _isLiveGeofenceActive = false;
    }
    notifyListeners();
  }
}
