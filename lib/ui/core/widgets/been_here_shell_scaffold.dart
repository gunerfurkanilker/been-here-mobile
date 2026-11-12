import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/been_here_theme.dart';
import '../view_models/navigation_shell_view_model.dart';
import 'glowing_live_tracker_button.dart';

class BeenHereShellScaffold extends StatelessWidget {
  const BeenHereShellScaffold({
    super.key,
    required this.viewModel,
    required this.tabBodies,
  });

  final NavigationShellViewModel viewModel;
  final Map<BeenHereNavTab, Widget> tabBodies;

  void _handleLiveTrackerTap(BuildContext context) {
    if (!viewModel.isPremiumUser) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: BeenHereColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: BeenHereColors.goldLeague,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Canlı Geofence Kumbarası & Otomatik EXIF (Premium)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Seyahat esnasında gezdiğin mekanları 100-150m yakınından geçerken pil harcamadan otomatik yakalar (GEO_VERIFIED: +50 Puan) ve gün sonunda çektiğin fotoğrafları EXIF koordinatlarıyla rotana eşleştirir.',
                style: TextStyle(
                  color: BeenHereColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    viewModel.toggleSubscriptionTierForPreview();
                    viewModel.toggleLiveGeofenceTracker();
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Önizleme İçin Premium Modunu Aktifleştir'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    viewModel.toggleLiveGeofenceTracker();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BeenHereColors.surfaceElevated,
        content: Text(
          viewModel.isLiveGeofenceActive
              ? '📡 Canlı Seyahat Yakalayıcı (Geofence & EXIF) aktif! Gezdiğin duraklar otomatik yakalanıyor.'
              : 'Canlı Seyahat Yakalayıcı duraklatıldı.',
          style: const TextStyle(color: BeenHereColors.textPrimary),
        ),
      ),
    );
  }

  String _titleForTab(BeenHereNavTab tab) {
    switch (tab) {
      case BeenHereNavTab.home:
        return 'Rotalar';
      case BeenHereNavTab.leaderboards:
        return 'Gezgin Ligleri';
      case BeenHereNavTab.compassRouteBuilder:
        return 'Rota Oluştur';
      case BeenHereNavTab.placeSearch:
        return 'Mekanlar';
      case BeenHereNavTab.profile:
        return 'Anılarım';
    }
  }

  PhosphorIconData _iconForTab(
    BeenHereNavTab tab, [
    PhosphorIconsStyle style = PhosphorIconsStyle.duotone,
  ]) {
    switch (tab) {
      case BeenHereNavTab.home:
        return PhosphorIcons.path(style);
      case BeenHereNavTab.leaderboards:
        return PhosphorIcons.personSimpleHike(style);
      case BeenHereNavTab.compassRouteBuilder:
        return PhosphorIcons.backpack(style);
      case BeenHereNavTab.placeSearch:
        return PhosphorIcons.mapPinArea(style);
      case BeenHereNavTab.profile:
        return PhosphorIcons.bookBookmark(style);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final activeTab = viewModel.currentTab;
        final rawTopPadding = MediaQuery.paddingOf(context).top;
        // Safari Web / mobil tarayıcılarda üst çubuğun yapışmasını önleyen akıllı nefes payı
        final extraWebTopPadding = rawTopPadding > 0 ? 0.0 : 8.0;

        return Scaffold(
          extendBody: true,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight + extraWebTopPadding),
            child: Padding(
              padding: EdgeInsets.only(top: extraWebTopPadding),
              child: AppBar(
                titleSpacing: 16,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: BeenHereColors.background,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BeenHereColors.primaryCompass
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PhosphorIcon(
                        _iconForTab(activeTab, PhosphorIconsStyle.duotone),
                        color: BeenHereColors.primaryCompass,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        _titleForTab(activeTab),
                        key: ValueKey<BeenHereNavTab>(activeTab),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: GlowingLiveTrackerButton(
                      isActive: viewModel.isLiveGeofenceActive,
                      isPremiumUser: viewModel.isPremiumUser,
                      onPressed: () => _handleLiveTrackerTap(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey<BeenHereNavTab>(activeTab),
                child: tabBodies[activeTab] ?? const SizedBox.shrink(),
              ),
            ),
          ),
          bottomNavigationBar: _LiquidGlassBottomNavBar(
            activeTab: activeTab,
            onSelectTab: viewModel.selectTab,
          ),
        );
      },
    );
  }
}

class _LiquidGlassBottomNavBar extends StatelessWidget {
  const _LiquidGlassBottomNavBar({
    required this.activeTab,
    required this.onSelectTab,
  });

  final BeenHereNavTab activeTab;
  final ValueChanged<BeenHereNavTab> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      // Alttan nefes payı ve yatayda tam ortalanmış (sol ve sağ boşluklar birebir eşit) kompakt kapsül
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomSafePadding > 0 ? bottomSafePadding + 10 : 14,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    BeenHereColors.surface.withValues(alpha: 0.22),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. En Sol: Rota İkonu (Rotalar)
                  _GlassNavIconButton(
                    tooltip: 'Rotalar',
                    icon: PhosphorIcons.path(PhosphorIconsStyle.regular),
                    activeIcon: PhosphorIcons.path(PhosphorIconsStyle.duotone),
                    isSelected: activeTab == BeenHereNavTab.home,
                    onTap: () => onSelectTab(BeenHereNavTab.home),
                  ),
                  const SizedBox(width: 6),

                  // 2. Sol-Orta: Sırt Çantalı Gezgin İkonu (Gezgin Ligleri)
                  _GlassNavIconButton(
                    tooltip: 'Gezgin Ligleri',
                    icon: PhosphorIcons.personSimpleHike(
                      PhosphorIconsStyle.regular,
                    ),
                    activeIcon: PhosphorIcons.personSimpleHike(
                      PhosphorIconsStyle.duotone,
                    ),
                    isSelected: activeTab == BeenHereNavTab.leaderboards,
                    onTap: () => onSelectTab(BeenHereNavTab.leaderboards),
                  ),
                  const SizedBox(width: 8),

                  // 3. Tam Orta: Çanta İkonu (Rota Oluşturma — Diğerlerinden biraz daha büyük)
                  _GlassNavIconButton(
                    tooltip: 'Rota Oluştur',
                    icon: PhosphorIcons.backpack(PhosphorIconsStyle.regular),
                    activeIcon:
                        PhosphorIcons.backpack(PhosphorIconsStyle.duotone),
                    isSelected: activeTab == BeenHereNavTab.compassRouteBuilder,
                    isCenterProminent: true,
                    onTap: () =>
                        onSelectTab(BeenHereNavTab.compassRouteBuilder),
                  ),
                  const SizedBox(width: 8),

                  // 4. Sağ-Orta: Mekan İkonu (Mekanlar)
                  _GlassNavIconButton(
                    tooltip: 'Mekanlar',
                    icon: PhosphorIcons.mapPinArea(PhosphorIconsStyle.regular),
                    activeIcon:
                        PhosphorIcons.mapPinArea(PhosphorIconsStyle.duotone),
                    isSelected: activeTab == BeenHereNavTab.placeSearch,
                    onTap: () => onSelectTab(BeenHereNavTab.placeSearch),
                  ),
                  const SizedBox(width: 6),

                  // 5. En Sağ: Anılar İkonu (Anılarım)
                  _GlassNavIconButton(
                    tooltip: 'Anılarım',
                    icon:
                        PhosphorIcons.bookBookmark(PhosphorIconsStyle.regular),
                    activeIcon:
                        PhosphorIcons.bookBookmark(PhosphorIconsStyle.duotone),
                    isSelected: activeTab == BeenHereNavTab.profile,
                    onTap: () => onSelectTab(BeenHereNavTab.profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavIconButton extends StatelessWidget {
  const _GlassNavIconButton({
    required this.tooltip,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
    this.isCenterProminent = false,
  });

  final String tooltip;
  final PhosphorIconData icon;
  final PhosphorIconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCenterProminent;

  @override
  Widget build(BuildContext context) {
    final double iconSize = isCenterProminent ? 26.5 : 21.5;
    final Color iconColor = isSelected
        ? BeenHereColors.primaryCompass
        : (isCenterProminent
            ? BeenHereColors.textPrimary
            : BeenHereColors.textSecondary.withValues(alpha: 0.92));

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: isCenterProminent ? 42 : 36,
          height: isCenterProminent ? 42 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? BeenHereColors.primaryCompass.withValues(alpha: 0.18)
                : (isCenterProminent
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent),
          ),
          child: Center(
            child: PhosphorIcon(
              isSelected ? activeIcon : icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
