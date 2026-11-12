import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/been_here_theme.dart';
import '../view_models/navigation_shell_view_model.dart';
import 'glowing_live_tracker_button.dart';

class BeenHereShellScaffold extends StatefulWidget {
  const BeenHereShellScaffold({
    super.key,
    required this.viewModel,
    required this.tabBodies,
  });

  final NavigationShellViewModel viewModel;
  final Map<BeenHereNavTab, Widget> tabBodies;

  @override
  State<BeenHereShellScaffold> createState() => _BeenHereShellScaffoldState();
}

class _BeenHereShellScaffoldState extends State<BeenHereShellScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barsAnimationController;
  late final Animation<double> _barsAnimation;

  bool _isAppBarVisible = true;
  double _verticalScrollDelta = 0.0;
  BeenHereNavTab? _previousTab;

  @override
  void initState() {
    super.initState();
    _previousTab = widget.viewModel.currentTab;
    widget.viewModel.addListener(_onTabChanged);

    _barsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
      value: 1.0,
    );
    _barsAnimation = CurvedAnimation(
      parent: _barsAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _barsAnimationController.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant BeenHereShellScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onTabChanged);
      widget.viewModel.addListener(_onTabChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onTabChanged);
    _barsAnimationController.removeListener(_onAnimationTick);
    _barsAnimationController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_previousTab != widget.viewModel.currentTab) {
      _previousTab = widget.viewModel.currentTab;
      _verticalScrollDelta = 0.0;
      _setBarsVisible(true);
    }
  }

  void _setBarsVisible(bool visible) {
    if (_isAppBarVisible == visible) return;
    _isAppBarVisible = visible;
    if (visible) {
      _barsAnimationController.forward();
    } else {
      _barsAnimationController.reverse();
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification.metrics.pixels <= 2.0) {
      _verticalScrollDelta = 0.0;
      _setBarsVisible(true);
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse) {
        if (notification.metrics.pixels > 16.0) {
          _verticalScrollDelta = 0.0;
          _setBarsVisible(false);
        }
      } else if (notification.direction == ScrollDirection.forward) {
        _verticalScrollDelta = 0.0;
        _setBarsVisible(true);
      }
    } else if (notification is ScrollUpdateNotification) {
      if (!notification.metrics.outOfRange &&
          notification.metrics.maxScrollExtent > 0) {
        final delta = notification.scrollDelta ?? 0.0;
        if (delta > 0) {
          _verticalScrollDelta =
              _verticalScrollDelta > 0 ? _verticalScrollDelta + delta : delta;
          if (_verticalScrollDelta >= 16.0 &&
              notification.metrics.pixels > 16.0) {
            _setBarsVisible(false);
            _verticalScrollDelta = 0.0;
          }
        } else if (delta < 0) {
          _verticalScrollDelta =
              _verticalScrollDelta < 0 ? _verticalScrollDelta + delta : delta;
          if (_verticalScrollDelta <= -12.0) {
            _setBarsVisible(true);
            _verticalScrollDelta = 0.0;
          }
        }
      }
    }

    return false;
  }

  void _handleLiveTrackerTap(BuildContext context) {
    if (!widget.viewModel.isPremiumUser) {
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
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: BeenHereColors.goldLeague,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
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
              Text(
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
                    widget.viewModel.toggleSubscriptionTierForPreview();
                    widget.viewModel.toggleLiveGeofenceTracker();
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

    widget.viewModel.toggleLiveGeofenceTracker();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BeenHereColors.surfaceElevated,
        content: Text(
          widget.viewModel.isLiveGeofenceActive
              ? '📡 Canlı Seyahat Yakalayıcı (Geofence & EXIF) aktif! Gezdiğin duraklar otomatik yakalanıyor.'
              : 'Canlı Seyahat Yakalayıcı duraklatıldı.',
          style: TextStyle(color: BeenHereColors.textPrimary),
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
      listenable: widget.viewModel,
      builder: (context, _) {
        final activeTab = widget.viewModel.currentTab;
        final rawTopPadding = MediaQuery.paddingOf(context).top;
        final totalToolbarHeight = kToolbarHeight + rawTopPadding;
        final effectiveToolbarHeight =
            totalToolbarHeight * _barsAnimation.value;
        // Topbar gizlenirken veya gizlendiğinde çentikli cihazlarda body'nin
        // durum çubuğu alanına taşmaması için kalan üst güvenli alan korunur.
        final remainingTopSafePadding =
            (rawTopPadding - effectiveToolbarHeight).clamp(0.0, rawTopPadding);

        return Scaffold(
          extendBody: true,
          appBar: _AutoHideAppBar(
            heightFactor: _barsAnimation.value,
            totalToolbarHeight: totalToolbarHeight,
            isInteractive: _isAppBarVisible,
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
                      color: BeenHereThemeController.instance.isDark
                          ? BeenHereColors.primaryCompass
                              .withValues(alpha: 0.16)
                          : BeenHereLightColors.softSky
                              .withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PhosphorIcon(
                      _iconForTab(activeTab, PhosphorIconsStyle.duotone),
                      color: BeenHereThemeController.instance.isDark
                          ? BeenHereColors.primaryCompass
                          : BeenHereColors.secondaryAmber,
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
                const _ThemeToggleGlassButton(),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GlowingLiveTrackerButton(
                    isActive: widget.viewModel.isLiveGeofenceActive,
                    isPremiumUser: widget.viewModel.isPremiumUser,
                    onPressed: () => _handleLiveTrackerTap(context),
                  ),
                ),
              ],
            ),
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: Padding(
              padding: EdgeInsets.only(top: remainingTopSafePadding),
              child: ClipRect(
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey<BeenHereNavTab>(activeTab),
                      child:
                          widget.tabBodies[activeTab] ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: _LiquidGlassBottomNavBar(
            activeTab: activeTab,
            onSelectTab: widget.viewModel.selectTab,
          ),
        );
      },
    );
  }
}

class _AutoHideAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AutoHideAppBar({
    required this.heightFactor,
    required this.totalToolbarHeight,
    required this.isInteractive,
    required this.child,
  });

  final double heightFactor;
  final double totalToolbarHeight;
  final bool isInteractive;
  final Widget child;

  @override
  Size get preferredSize =>
      Size.fromHeight(totalToolbarHeight * heightFactor.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final clampedFactor = heightFactor.clamp(0.0, 1.0);
    final effectiveHeight = totalToolbarHeight * clampedFactor;
    final smoothOpacity = Curves.easeOutCubic.transform(clampedFactor);

    return SizedBox(
      height: effectiveHeight,
      child: ColoredBox(
        color: BeenHereColors.background,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: totalToolbarHeight,
            child: Transform.translate(
              offset: Offset(
                0,
                -(1.0 - clampedFactor) * totalToolbarHeight * 0.75,
              ),
              child: Opacity(
                opacity: smoothOpacity,
                child: IgnorePointer(
                  ignoring: !isInteractive,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
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
    final isDark = BeenHereThemeController.instance.isDark;

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
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.10),
                          BeenHereColors.surface.withValues(alpha: 0.22),
                        ]
                      : [
                          BeenHereColors.surface.withValues(alpha: 0.82),
                          BeenHereLightColors.softSky.withValues(alpha: 0.42),
                        ],
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : BeenHereColors.borderSubtle.withValues(alpha: 0.90),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.18)
                        : BeenHereColors.textPrimary.withValues(alpha: 0.12),
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
    final isDark = BeenHereThemeController.instance.isDark;
    final double iconSize = isCenterProminent ? 26.5 : 21.5;
    final Color iconColor = isSelected
        ? (isDark
            ? BeenHereColors.primaryCompass
            : BeenHereColors.secondaryAmber)
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
                ? BeenHereColors.primaryCompass
                    .withValues(alpha: isDark ? 0.18 : 0.28)
                : (isCenterProminent
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : BeenHereColors.borderSubtle.withValues(alpha: 0.35))
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

class _ThemeToggleGlassButton extends StatelessWidget {
  const _ThemeToggleGlassButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BeenHereThemeController.instance,
      builder: (context, _) {
        final isDark = BeenHereThemeController.instance.isDark;

        return Tooltip(
          message: isDark ? 'Aydınlık Temaya Geç' : 'Karanlık Temaya Geç',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                BeenHereThemeController.instance.toggleTheme();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? BeenHereColors.surface.withValues(alpha: 0.8)
                      : BeenHereColors.surfaceElevated,
                  border: Border.all(
                    color: isDark
                        ? BeenHereColors.goldLeague.withValues(alpha: 0.35)
                        : BeenHereColors.borderSubtle,
                    width: 1,
                  ),
                  boxShadow: [
                    if (isDark)
                      BoxShadow(
                        color: BeenHereColors.goldLeague.withValues(alpha: 0.18),
                        blurRadius: 10,
                        spreadRadius: 0.5,
                      ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isDark
                        ? PhosphorIcon(
                            PhosphorIcons.sun(PhosphorIconsStyle.bold),
                            key: const ValueKey('sun_icon'),
                            color: BeenHereColors.goldLeague,
                            size: 20,
                          )
                        : PhosphorIcon(
                            PhosphorIcons.moonStars(PhosphorIconsStyle.bold),
                            key: const ValueKey('moon_icon'),
                            color: BeenHereColors.textPrimary,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
