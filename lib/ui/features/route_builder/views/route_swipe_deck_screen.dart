import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/been_here_theme.dart';
import '../view_models/route_builder_view_model.dart';

/// 4. Adımda ("Rotayı Oluşturmaya Başla") sonrasında devreye giren:
/// 1) Wireframe 1: 3'lü Rota Kurgulama Modu Seçim Ekranı (Özgün Rota, Gezgin Rotaları, Özel Turlar)
/// 2) Wireframe 2: İnteraktif Swipe & Pick (Mekan Kaydırma) Ekranı
/// 3) Wireframe 2 İstisna Kuralı: Özel Turlar (Tur Şirketleri) Özel Yönlendirme Ekranı
class RouteSwipeDeckScreen extends StatelessWidget {
  const RouteSwipeDeckScreen({
    super.key,
    required this.viewModel,
    this.onBackToParameters,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback? onBackToParameters;

  void _handleBackToParameters(BuildContext context) {
    HapticFeedback.lightImpact();
    if (onBackToParameters != null) {
      onBackToParameters!();
      return;
    }
    if (viewModel.isRouteCreationFlowActive) {
      viewModel.exitRouteCreationFlow();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return ColoredBox(
          color: BeenHereColors.background,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: switch (viewModel.creationStage) {
              RouteCreationStage.modeSelection => _RouteModeSelectionStageView(
                  key: const ValueKey<String>('route-mode-selection-view'),
                  viewModel: viewModel,
                  onBackToParameters: () => _handleBackToParameters(context),
                ),
              RouteCreationStage.swipeDeck => _RouteSwipeDeckStageView(
                  key: const ValueKey<String>('swipe-deck-stage-view'),
                  viewModel: viewModel,
                ),
              RouteCreationStage.privateToursRedirect =>
                _PrivateToursRedirectStageView(
                  key: const ValueKey<String>('private-tours-redirect-view'),
                  viewModel: viewModel,
                ),
            },
          ),
        );
      },
    );
  }
}

// =============================================================================
// AŞAMA 1 (WIREFRAME 1): 3'LÜ ROTA KURGULAMA MODU SEÇİM EKRANI
// =============================================================================
class _RouteModeSelectionStageView extends StatelessWidget {
  const _RouteModeSelectionStageView({
    super.key,
    required this.viewModel,
    required this.onBackToParameters,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onBackToParameters;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final bottomPad = bottomSafe > 0 ? bottomSafe + 8.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst Bilgi ve Parametrelere Dönüş Çubuğu
          Row(
            children: [
              Material(
                color: BeenHereColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey<String>(
                    'swipe-deck-back-to-params-button',
                  ),
                  onTap: onBackToParameters,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BeenHereColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                          size: 15,
                          color: BeenHereColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Parametreler',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: BeenHereColors.surface.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BeenHereColors.borderSubtle.withValues(alpha: 0.8),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${viewModel.totalSelectedCountryCount} Ülke, ${viewModel.totalSelectedCityCount} Şehir • ${viewModel.totalTravelersCount} Kişi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: BeenHereColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Wireframe 1: Alt alta 3 büyük yuvarlatılmış seçim kartı
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cards = <Widget>[
                  _ModeSelectionBannerCard(
                    cardKey: const ValueKey<String>('route-mode-card-original'),
                    title: 'Özgün Rota',
                    subtitle: 'Bağımsız olarak kendi rotanızı oluşturun',
                    icon: PhosphorIcons.compass(PhosphorIconsStyle.duotone),
                    accentColor: BeenHereColors.verifiedEmerald,
                    gradientColors: const <Color>[
                      Color(0xFF0A2E24),
                      Color(0xFF091722),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      viewModel.openOriginalRouteSwipeDeck();
                    },
                  ),
                  _ModeSelectionBannerCard(
                    cardKey: const ValueKey<String>('route-mode-card-traveler'),
                    title: 'Gezgin Rotaları',
                    subtitle:
                        'Yerli ve global gezginlerin deneyimlerinden faydalanın',
                    icon: PhosphorIcons.footprints(PhosphorIconsStyle.duotone),
                    accentColor: BeenHereColors.primaryCompass,
                    gradientColors: const <Color>[
                      Color(0xFF2B161E),
                      Color(0xFF101826),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      viewModel.openTravelerRoutesSwipeDeck();
                    },
                  ),
                  _ModeSelectionBannerCard(
                    cardKey: const ValueKey<String>(
                      'route-mode-card-private-tours',
                    ),
                    title: 'Özel Turlar',
                    subtitle:
                        'Tur şirketlerinin düzenlediği seyahat rotalarını keşfedin',
                    icon: PhosphorIcons.suitcaseRolling(
                      PhosphorIconsStyle.duotone,
                    ),
                    accentColor: BeenHereColors.goldLeague,
                    gradientColors: const <Color>[
                      Color(0xFF282110),
                      Color(0xFF0E1622),
                    ],
                    onTap: () {
                      HapticFeedback.selectionClick();
                      viewModel.openPrivateToursRedirect();
                    },
                  ),
                ];

                if (constraints.maxHeight < 380) {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => SizedBox(
                      height: 125,
                      child: cards[index],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(height: 14),
                    Expanded(child: cards[1]),
                    const SizedBox(height: 14),
                    Expanded(child: cards[2]),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelectionBannerCard extends StatelessWidget {
  const _ModeSelectionBannerCard({
    required this.cardKey,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.gradientColors,
    required this.onTap,
  });

  final Key cardKey;
  final String title;
  final String subtitle;
  final PhosphorIconData icon;
  final Color accentColor;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: cardKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.24),
              width: 1.15,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.26),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Sağ üst dekoratif pusula/mod ikonu
              Positioned(
                top: 16,
                right: 18,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      icon,
                      size: 22,
                      color: accentColor,
                    ),
                  ),
                ),
              ),

              // Wireframe 1 ile birebir: Sol alt hizalı Başlık + Alt Başlık
              Positioned(
                left: 20,
                right: 20,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.84),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// İSTİSNA EKRANI: ÖZEL TURLAR (TUR ŞİRKETLERİ) ÖZEL YÖNLENDİRME GÖRÜNÜMÜ
// =============================================================================
class _PrivateToursRedirectStageView extends StatelessWidget {
  const _PrivateToursRedirectStageView({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final bottomPad = bottomSafe > 0 ? bottomSafe + 8.0 : 14.0;
    final packages = RouteBuilderViewModel.corporateTourPackagesCatalog;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Üst Bar
          Row(
            children: [
              Material(
                color: BeenHereColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  key: const ValueKey<String>(
                    'private-tours-back-to-modes-button',
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    viewModel.backToCreationModeSelection();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: BeenHereColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIcons.arrowLeft(PhosphorIconsStyle.bold),
                          size: 15,
                          color: BeenHereColors.textPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mod Seçimine Dön',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Özel Turlar & Tur Şirketleri',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BeenHereColors.goldLeague,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bilgilendirme Banner'ı (Wireframe 2 İstisna Kuralı)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: BeenHereColors.goldLeague.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BeenHereColors.goldLeague.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhosphorIcon(
                  PhosphorIcons.suitcaseRolling(PhosphorIconsStyle.duotone),
                  size: 22,
                  color: BeenHereColors.goldLeague,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kurumsal Tur Şirketleri Özel Yönlendirmesi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: BeenHereColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tur şirketlerinin hazır paket rotaları bağımsız mekan kaydırma destesinden ayrı olarak kurumsal tur kataloğunda sunulur.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Örnek Kurumsal Tur Paketleri Listesi
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: packages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pkg = packages[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BeenHereColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BeenHereColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pkg.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: BeenHereColors.goldLeague
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pkg.priceLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.goldLeague,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pkg.operatorName} • ${pkg.durationLabel} • ${pkg.locationSummary}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final item in pkg.highlights)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 13,
                                color: BeenHereColors.verifiedEmerald,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: BeenHereColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Özgün Rota / Gezgin Rotaları Swipe Destesine Geçiş Butonu
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              key: const ValueKey<String>(
                'private-tours-switch-to-swipe-button',
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                viewModel.switchFromPrivateToursToSwipeDeck();
              },
              style: FilledButton.styleFrom(
                backgroundColor: BeenHereColors.primaryCompass,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: PhosphorIcon(
                PhosphorIcons.cards(PhosphorIconsStyle.bold),
                size: 17,
              ),
              label: const Text(
                'Özgün Rota & Gezgin Rotalarına Geç',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AŞAMA 2 (WIREFRAME 2): İNTERAKTİF SWIPE & PICK (MEKAN KAYDIRMA) EKRANI
// =============================================================================
class _RouteSwipeDeckStageView extends StatefulWidget {
  const _RouteSwipeDeckStageView({
    super.key,
    required this.viewModel,
  });

  final RouteBuilderViewModel viewModel;

  @override
  State<_RouteSwipeDeckStageView> createState() =>
      _RouteSwipeDeckStageViewState();
}

class _RouteSwipeDeckStageViewState extends State<_RouteSwipeDeckStageView>
    with TickerProviderStateMixin {
  /// Tinder tarzı tutup çekme (grab & pull) hareketinde hafif doğal salınım açısı (±6°).
  static const double maxSwipeTiltAngleRadians = 6.0 * math.pi / 180.0;

  /// Kartın tam çekim ilerlemesine ulaştığı yatay sürükleme mesafesi (px).
  static const double maxSwipeDragDistance = 160.0;

  /// Kaydırma kararının tetiklenmesi için gereken minimum yatay eşik (px).
  static const double swipeTriggerThreshold = 60.0;

  /// Sola kaydırma (Geçildi) kırmızı gölge ve vurgu rengi.
  static const Color swipeLeftShadowColor = Color(0xFFE53935);

  double _dragOffsetDx = 0.0;
  bool _isAnimatingSwipeOut = false;
  int _swipeOutDirection = 0; // +1: sağa (seçildi), -1: sola (geçildi)
  double _swipeOutStartDx = 0.0;
  double _swipeOutTargetDx = 0.0;
  String? _lastRenderedPlaceId;

  late final AnimationController _swipeOutController;
  late final AnimationController _incomingCardOpacityController;
  late final Animation<double> _incomingCardOpacity;
  late final AnimationController _iconPingController;

  @override
  void initState() {
    super.initState();
    _lastRenderedPlaceId = widget.viewModel.currentDeckPlace?.id;

    _swipeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..addListener(_onSwipeOutTick)
     ..addStatusListener(_onSwipeOutStatusChanged);

    // İlk açılışta kart doğrudan 1.0 opasitede görünür;
    // sonraki mekana geçişlerde 0.0 -> 1.0 animasyonu çalışır.
    _incomingCardOpacityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _incomingCardOpacity = CurvedAnimation(
      parent: _incomingCardOpacityController,
      curve: Curves.easeOutCubic,
    );

    // Tailwind animate-ping tarzı sonsuz (infinite) ikon yankı animasyonu
    _iconPingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(covariant _RouteSwipeDeckStageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
      _onViewModelChanged();
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    _swipeOutController.dispose();
    _incomingCardOpacityController.dispose();
    _iconPingController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final nextId = widget.viewModel.currentDeckPlace?.id;
    if (nextId != _lastRenderedPlaceId) {
      _lastRenderedPlaceId = nextId;
      if (nextId != null) {
        _incomingCardOpacityController.forward(from: 0.0);
      } else {
        _incomingCardOpacityController.value = 1.0;
      }
    }
  }

  void _onSwipeOutTick() {
    if (!mounted || !_isAnimatingSwipeOut) return;
    final t = Curves.easeOutCubic.transform(_swipeOutController.value);
    setState(() {
      _dragOffsetDx =
          _swipeOutStartDx + (_swipeOutTargetDx - _swipeOutStartDx) * t;
    });
  }

  void _onSwipeOutStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final int direction = _swipeOutDirection;
    setState(() {
      _isAnimatingSwipeOut = false;
      _swipeOutDirection = 0;
      _dragOffsetDx = 0.0;
    });

    if (direction > 0) {
      widget.viewModel.swipeCurrentPlaceRight();
    } else if (direction < 0) {
      widget.viewModel.swipeCurrentPlaceLeft();
    }
  }

  void _startSwipeOutAnimation({required bool isRight}) {
    if (_iconPingController.isAnimating) {
      _iconPingController.stop();
    }
    _isAnimatingSwipeOut = true;
    _swipeOutDirection = isRight ? 1 : -1;
    _swipeOutStartDx = _dragOffsetDx;
    _swipeOutTargetDx = isRight
        ? math.max(_dragOffsetDx, maxSwipeDragDistance * 1.45)
        : math.min(_dragOffsetDx, -maxSwipeDragDistance * 1.45);
    _swipeOutController.forward(from: 0.0);
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isAnimatingSwipeOut || widget.viewModel.currentDeckPlace == null) {
      return;
    }
    setState(() {
      _dragOffsetDx += details.delta.dx;
    });
    if (_dragOffsetDx.abs() > 2.0) {
      if (!_iconPingController.isAnimating) {
        _iconPingController.repeat();
      }
    } else if (_iconPingController.isAnimating) {
      _iconPingController.stop();
      _iconPingController.value = 0.0;
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_iconPingController.isAnimating) {
      _iconPingController.stop();
    }
    if (_isAnimatingSwipeOut) return;
    if (widget.viewModel.currentDeckPlace == null) {
      if (_dragOffsetDx != 0.0) {
        setState(() => _dragOffsetDx = 0.0);
      }
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
    if (_dragOffsetDx >= swipeTriggerThreshold || velocity > 420.0) {
      HapticFeedback.mediumImpact();
      _startSwipeOutAnimation(isRight: true);
    } else if (_dragOffsetDx <= -swipeTriggerThreshold || velocity < -420.0) {
      HapticFeedback.lightImpact();
      _startSwipeOutAnimation(isRight: false);
    } else {
      setState(() => _dragOffsetDx = 0.0);
    }
  }

  void _handleCardTap() {
    if (_isAnimatingSwipeOut || widget.viewModel.currentDeckPlace == null) {
      return;
    }
    HapticFeedback.selectionClick();
    widget.viewModel.cycleCurrentPlacePhoto();
  }

  Color _buildCardBorderColor(double normalizedDrag) {
    if (normalizedDrag > 0.01) {
      return Color.lerp(
        Colors.white.withValues(alpha: 0.30),
        BeenHereColors.verifiedEmerald,
        (normalizedDrag * 1.4).clamp(0.0, 1.0),
      )!;
    }
    if (normalizedDrag < -0.01) {
      return Color.lerp(
        Colors.white.withValues(alpha: 0.30),
        swipeLeftShadowColor,
        ((-normalizedDrag) * 1.4).clamp(0.0, 1.0),
      )!;
    }
    return Colors.white.withValues(alpha: 0.30);
  }

  List<BoxShadow> _buildCardBoxShadows(
    double normalizedDrag,
    double dragProgress,
  ) {
    if (normalizedDrag.abs() > 0.01) {
      final Color directionalColor = normalizedDrag > 0
          ? BeenHereColors.verifiedEmerald
          : swipeLeftShadowColor;
      final double alpha = (0.28 + 0.47 * dragProgress).clamp(0.0, 0.78);
      final double blurRadius = 24.0 + 28.0 * dragProgress;
      final double spreadRadius = 2.0 + 8.0 * dragProgress;

      return <BoxShadow>[
        BoxShadow(
          color: directionalColor.withValues(alpha: alpha),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.32),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];
    }

    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.35),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  void _showMultiSelectFilterSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeenHereColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (ctx, _) {
            final vm = widget.viewModel;
            return SafeArea(
              key: const ValueKey<String>('swipe-deck-filter-sheet'),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Kategori, Gezgin, Tur Şirketi Seçimi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            key: const ValueKey<String>(
                              'swipe-deck-back-to-modes-button',
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              vm.backToCreationModeSelection();
                            },
                            child: const Text('Mod Seçimi'),
                          ),
                          TextButton(
                            key: const ValueKey<String>(
                              'filter-sheet-reset-button',
                            ),
                            onPressed: vm.resetDeckFilters,
                            child: const Text('Sıfırla'),
                          ),
                        ],
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Filtreler çoklu şekilde seçilebilir. İstisna olarak tur şirketleri seçilirse özel yönlendirme ekranına geçilir.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BeenHereColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 1. Rota Kaynak Modları (Çoklu Seçim + Özel Turlar İstisnası)
                              Text(
                                'Rota Kaynakları & Tur Şirketleri',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FilterToggleChip(
                                    chipKey: const ValueKey<String>(
                                      'filter-source-original',
                                    ),
                                    label: 'Özgün Rota',
                                    isSelected:
                                        vm.activeDeckSourceModes.contains(
                                      RouteDeckSourceMode.originalRoute,
                                    ),
                                    accentColor: BeenHereColors.verifiedEmerald,
                                    onTap: () => vm.toggleDeckSourceMode(
                                      RouteDeckSourceMode.originalRoute,
                                    ),
                                  ),
                                  _FilterToggleChip(
                                    chipKey: const ValueKey<String>(
                                      'filter-source-traveler',
                                    ),
                                    label: 'Gezgin Rotaları',
                                    isSelected:
                                        vm.activeDeckSourceModes.contains(
                                      RouteDeckSourceMode.travelerRoutes,
                                    ),
                                    accentColor: BeenHereColors.primaryCompass,
                                    onTap: () => vm.toggleDeckSourceMode(
                                      RouteDeckSourceMode.travelerRoutes,
                                    ),
                                  ),
                                  _FilterToggleChip(
                                    chipKey: const ValueKey<String>(
                                      'filter-source-private-tours',
                                    ),
                                    label: 'Özel Turlar (Tur Şirketleri) ↗',
                                    isSelected: false,
                                    accentColor: BeenHereColors.goldLeague,
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      vm.openPrivateToursRedirect();
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 2. Kategoriler (Çoklu Seçim)
                              Text(
                                'Kategoriler (Çoklu Seçim)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final category in RouteBuilderViewModel
                                      .availableDeckCategories)
                                    _FilterToggleChip(
                                      chipKey: ValueKey<String>(
                                        'filter-category-$category',
                                      ),
                                      label: category,
                                      isSelected: vm.activeDeckCategories
                                          .contains(category),
                                      accentColor:
                                          BeenHereColors.verifiedEmerald,
                                      onTap: () => vm.toggleDeckCategoryFilter(
                                        category,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 3. Gezginler (Çoklu Seçim)
                              Text(
                                'Gezginler (Çoklu Seçim)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final traveler in RouteBuilderViewModel
                                      .availableDeckTravelers)
                                    _FilterToggleChip(
                                      chipKey: ValueKey<String>(
                                        'filter-traveler-$traveler',
                                      ),
                                      label: traveler,
                                      isSelected: vm.activeDeckTravelers
                                          .contains(traveler),
                                      accentColor:
                                          BeenHereColors.primaryCompass,
                                      onTap: () => vm.toggleDeckTravelerFilter(
                                        traveler,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: FilledButton(
                          key: const ValueKey<String>(
                            'filter-sheet-apply-button',
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: BeenHereColors.primaryCompass,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Filtreleri Uygula (${vm.remainingDeckPlaces.length} Mekan)',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showManualPlaceSearchSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    String searchQuery = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeenHereColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ListenableBuilder(
              listenable: widget.viewModel,
              builder: (_, _) {
                final vm = widget.viewModel;
                final results = vm.searchCatalogPlaces(searchQuery);
                final selectedIds =
                    vm.selectedDeckPlaces.map((p) => p.id).toSet();

                return SafeArea(
                  key: const ValueKey<String>('swipe-deck-manual-search-sheet'),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.80,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        16,
                        18,
                        MediaQuery.viewInsetsOf(ctx).bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Elle Mekan Arama',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: BeenHereColors.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: BeenHereColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey<String>(
                              'manual-place-search-input',
                            ),
                            onChanged: (val) {
                              setModalState(() => searchQuery = val);
                            },
                            style: TextStyle(
                              fontSize: 13.5,
                              color: BeenHereColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mekan, şehir veya kategori ara...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: BeenHereColors.textSecondary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: BeenHereColors.textSecondary,
                              ),
                              filled: true,
                              fillColor: BeenHereColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: BeenHereColors.borderSubtle,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: BeenHereColors.borderSubtle,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: results.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, idx) {
                                final place = results[idx];
                                final isAdded = selectedIds.contains(place.id);

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BeenHereColors.background,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isAdded
                                          ? BeenHereColors.verifiedEmerald
                                          : BeenHereColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    BeenHereColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${place.formattedLocation} • ${place.formattedCategories}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: BeenHereColors
                                                    .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.tonal(
                                        key: ValueKey<String>(
                                          'manual-search-add-${place.id}',
                                        ),
                                        onPressed: isAdded
                                            ? null
                                            : () {
                                                HapticFeedback.selectionClick();
                                                vm.addPlaceToSelectedManually(
                                                  place,
                                                );
                                              },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: isAdded
                                              ? BeenHereColors.verifiedEmerald
                                                  .withValues(alpha: 0.16)
                                              : BeenHereColors.primaryCompass,
                                          foregroundColor: isAdded
                                              ? BeenHereColors.verifiedEmerald
                                              : Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                        ),
                                        child: Text(
                                          isAdded ? 'Seçildi ✓' : '+ Ekle',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDismissedPlacesSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BeenHereColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (ctx, _) {
            final vm = widget.viewModel;
            final dismissed = vm.dismissedDeckPlaces;

            return SafeArea(
              key: const ValueKey<String>('swipe-deck-dismissed-sheet'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seçilmemiş Mekanlar (Sola Kaydırılmış) (${dismissed.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (dismissed.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Henüz sola kaydırılmış mekan bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: dismissed.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, idx) {
                            final place = dismissed[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: BeenHereColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: BeenHereColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: BeenHereColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          place.formattedLocation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: BeenHereColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    key: ValueKey<String>(
                                      'dismissed-to-selected-${place.id}',
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      vm.moveDismissedPlaceToSelected(place);
                                    },
                                    child: const Text('Seçili Listeye Al'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSelectedPlacesSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: BeenHereColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (ctx, _) {
            final vm = widget.viewModel;
            final selected = vm.selectedDeckPlaces;

            return SafeArea(
              key: const ValueKey<String>('swipe-deck-selected-sheet'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seçili Mekanlar (Sağa Kaydırılanlar) (${selected.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (selected.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Henüz sağa kaydırılan veya seçilen mekan bulunmuyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: selected.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, idx) {
                            final place = selected[idx];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: BeenHereColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: BeenHereColors.verifiedEmerald
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: BeenHereColors.verifiedEmerald
                                          .withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${idx + 1}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: BeenHereColors.verifiedEmerald,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: BeenHereColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          place.formattedLocation,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: BeenHereColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey<String>(
                                      'selected-remove-${place.id}',
                                    ),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      vm.removeSelectedDeckPlace(place);
                                    },
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 19,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRoutePreviewSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BeenHereColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.viewModel,
          builder: (ctx, _) {
            final vm = widget.viewModel;
            final selected = vm.selectedDeckPlaces;

            return SafeArea(
              key: const ValueKey<String>('swipe-deck-route-preview-sheet'),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Rota Önizlemesi (Sonraki Adım)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: BeenHereColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: BeenHereColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BeenHereColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: BeenHereColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          '${vm.totalSelectedCountryCount} Ülke, ${vm.totalSelectedCityCount} Şehir • ${vm.formattedDateSummary} • ${vm.formattedBudgetSummary} • ${vm.totalTravelersCount} Gezgin',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rotadaki Seçili Duraklar (${selected.length})',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: BeenHereColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selected.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Henüz mekan seçmediniz. Kartları sağa kaydırarak veya elle arama yaparak rotanıza durak ekleyebilirsiniz.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: BeenHereColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: selected.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, idx) {
                              final place = selected[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: BeenHereColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: BeenHereColors.borderSubtle,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BeenHereColors.verifiedEmerald
                                            .withValues(alpha: 0.16),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Durak ${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: BeenHereColors.verifiedEmerald,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: BeenHereColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            '${place.formattedLocation} • ${place.formattedCategories}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color:
                                                  BeenHereColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 46,
                        child: FilledButton(
                          key: const ValueKey<String>(
                            'route-preview-confirm-button',
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: BeenHereColors.verifiedEmerald,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Rota Taslağını Onayla',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final remaining = vm.remainingDeckPlaces;
    final currentPlace = remaining.isEmpty ? null : remaining.first;
    final nextPlace = remaining.length > 1 ? remaining[1] : null;

    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final double bottomMenuBaseHeight = bottomSafe > 0 ? bottomSafe : 68.0;
    final double bottomContentOffset = bottomMenuBaseHeight + 22.0;

    final double normalizedDrag =
        (_dragOffsetDx / maxSwipeDragDistance).clamp(-1.0, 1.0);
    final double dragProgress = normalizedDrag.abs();
    final double tiltAngleRadians = normalizedDrag * maxSwipeTiltAngleRadians;
    final bool isSwiping = _dragOffsetDx.abs() > 2.0 || _isAnimatingSwipeOut;

    final double rightProgress = normalizedDrag > 0 ? normalizedDrag : 0.0;
    final double leftProgress = normalizedDrag < 0 ? -normalizedDrag : 0.0;

    // Kart alanı yanlardan, üstten ve alttan sıfır boşlukla tam ekran genişler
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // ===================================================================
          // KATMAN 0 (EN ALT): SIRADAKİ MEKAN ÖNİZLEME KARTI
          // Üstteki kart sağa/sola çekilirken alttan hangi mekanın geleceği gözükür.
          // ===================================================================
          if (nextPlace != null && isSwiping)
            IgnorePointer(
              child: Opacity(
                key: const ValueKey<String>('swipe-deck-next-card-opacity'),
                opacity: (0.35 + 0.65 * dragProgress).clamp(0.0, 1.0),
                child: Transform.scale(
                  key: const ValueKey<String>('swipe-deck-next-card-scale'),
                  scale: 0.96 + (0.04 * dragProgress),
                  child: Container(
                    key: const ValueKey<String>('swipe-deck-next-card'),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1520),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _PlaceGalleryBackdrop(
                          place: nextPlace,
                          photoIndex: 0,
                        ),
                        Positioned(
                          top: 8,
                          left: 16,
                          right: 16,
                          child: Row(
                            children: [
                              for (int i = 0;
                                  i < nextPlace.photoUrls.length;
                                  i++) ...[
                                Expanded(
                                  child: Container(
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: i == 0
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.30,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                if (i < nextPlace.photoUrls.length - 1)
                                  const SizedBox(width: 5),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          left: 72,
                          right: 72,
                          bottom: bottomContentOffset,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                nextPlace.name,
                                key: const ValueKey<String>(
                                  'swipe-next-card-place-title',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 2),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                nextPlace.formattedLocation,
                                key: const ValueKey<String>(
                                  'swipe-next-card-place-location',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                nextPlace.formattedCategories,
                                key: const ValueKey<String>(
                                  'swipe-next-card-place-categories',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ===================================================================
          // KATMAN 1 (ORTA): TİNDER TARZI TUTUP ÇEKİLEN AKTİF MEKAN KARTI
          // ===================================================================
          FadeTransition(
            key: const ValueKey<String>('swipe-deck-card-fade'),
            opacity: _incomingCardOpacity,
            child: GestureDetector(
              key: const ValueKey<String>('swipe-deck-stage-card'),
              behavior: HitTestBehavior.opaque,
              onTap: _handleCardTap,
              onHorizontalDragUpdate: _handleHorizontalDragUpdate,
              onHorizontalDragEnd: _handleHorizontalDragEnd,
              child: Transform.translate(
                key: const ValueKey<String>('swipe-deck-card-translate'),
                offset: Offset(_dragOffsetDx, 0.0),
                child: Transform.rotate(
                  key: const ValueKey<String>('swipe-deck-card-rotation'),
                  angle: tiltAngleRadians,
                  alignment: Alignment.center,
                  child: Container(
                    key: const ValueKey<String>(
                      'swipe-deck-card-surface',
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1520),
                      borderRadius: isSwiping
                          ? BorderRadius.circular(24)
                          : BorderRadius.zero,
                      border: isSwiping
                          ? Border.all(
                              color: _buildCardBorderColor(normalizedDrag),
                              width: 1.6,
                            )
                          : null,
                      boxShadow: _buildCardBoxShadows(
                        normalizedDrag,
                        dragProgress,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 1. ARKA PLAN: MEKAN FOTOĞRAF GALERİSİ & GEÇİŞLİ BUZLANMA
                        if (currentPlace != null)
                          _PlaceGalleryBackdrop(
                            place: currentPlace,
                            photoIndex: vm.currentPhotoIndex,
                            isPrimaryCard: true,
                          )
                        else
                          _EmptyDeckStateBody(
                            viewModel: vm,
                            onOpenFilters: () =>
                                _showMultiSelectFilterSheet(context),
                          ),

                        // Ortadaki dokunma alanı (Fotoğraf geçişi için)
                        if (currentPlace != null)
                          const Positioned.fill(
                            key: ValueKey<String>(
                              'swipe-card-photo-tap-area',
                            ),
                            child: ColoredBox(color: Colors.transparent),
                          ),

                        // 2. ÜST FOTOĞRAF SEGMENT GÖSTERGESİ
                        if (currentPlace != null)
                          Positioned(
                            top: 8,
                            left: 16,
                            right: 16,
                            child: Row(
                              children: [
                                for (int i = 0;
                                    i < currentPlace.photoUrls.length;
                                    i++) ...[
                                  Expanded(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      height: 3.5,
                                      decoration: BoxDecoration(
                                        color: i == vm.currentPhotoIndex
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.30,
                                              ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  if (i < currentPlace.photoUrls.length - 1)
                                    const SizedBox(width: 5),
                                ],
                              ],
                            ),
                          ),

                        // 3. SAĞA ÇEKİLİRKEN KARTIN SOL ÜSTÜNDE BÜYÜK YEŞİL TİK İKONU (Arka plansız & Tailwind Ping animasyonlu)
                        if (_dragOffsetDx > 2.0 && currentPlace != null)
                          Positioned(
                            top: 22,
                            left: 20,
                            child: _SwipePingActionIcon(
                              key: const ValueKey<String>(
                                'swipe-card-right-check-icon',
                              ),
                              icon: PhosphorIcons.check(
                                PhosphorIconsStyle.bold,
                              ),
                              color: BeenHereColors.verifiedEmerald,
                              progress: rightProgress,
                              pingAnimation: _iconPingController,
                            ),
                          ),

                        // 4. SOLA ÇEKİLİRKEN KARTIN SAĞ ÜSTÜNDE BÜYÜK KIRMIZI X İKONU (Arka plansız & Tailwind Ping animasyonlu)
                        if (_dragOffsetDx < -2.0 && currentPlace != null)
                          Positioned(
                            top: 22,
                            right: 20,
                            child: _SwipePingActionIcon(
                              key: const ValueKey<String>(
                                'swipe-card-left-x-icon',
                              ),
                              icon: PhosphorIcons.x(
                                PhosphorIconsStyle.bold,
                              ),
                              color: swipeLeftShadowColor,
                              progress: leftProgress,
                              pingAnimation: _iconPingController,
                            ),
                          ),

                        // 5. ALT ORTA: Ortalanmış 3 Satırlı Mekan Kimliği
                        // (Buzlu alt menü şeridinin hemen üstünde konumlanır)
                        if (currentPlace != null)
                          Positioned(
                            left: 72,
                            right: 72,
                            bottom: bottomContentOffset,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  key: const ValueKey<String>(
                                    'swipe-card-photo-indicator',
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Text(
                                    'Fotoğraf ${vm.currentPhotoIndex + 1}/${currentPlace.photoUrls.length} • ${currentPlace.photoCaptions[vm.currentPhotoIndex % currentPlace.photoCaptions.length]}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 1. Satır: Mekan Adı (Örn: Big Ben)
                                Text(
                                  currentPlace.name,
                                  key: const ValueKey<String>(
                                    'swipe-card-place-title',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.4,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        offset: Offset(0, 2),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // 2. Satır: Ülke, Şehir (Örn: İngiltere, Londra)
                                Text(
                                  currentPlace.formattedLocation,
                                  key: const ValueKey<String>(
                                    'swipe-card-place-location',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        offset: Offset(0, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                // 3. Satır: Kategoriler (Örn: Tarihi Yapı, Simge Yapı)
                                Text(
                                  currentPlace.formattedCategories,
                                  key: const ValueKey<String>(
                                    'swipe-card-place-categories',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // KATMAN 2 (ÜST): SABİT ÇEVRE KONTROL BUTONLARI
          // Çekim yapıldığında (isSwiping) Seçilenler ve Geçilenler dahil tamamı gizlenir.
          // ===================================================================

          // 3. SOL ÜST & SAĞ ÜST BUTONLAR
          Positioned(
            top: 20,
            left: 14,
            right: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Sol Üst: Kategori, Gezgin, Tur Şirketi Seçimi + Başlık
                Expanded(
                  child: IgnorePointer(
                    ignoring: isSwiping,
                    child: AnimatedOpacity(
                      key: const ValueKey<String>(
                        'swipe-deck-filter-controls-opacity',
                      ),
                      duration: const Duration(milliseconds: 140),
                      opacity: isSwiping ? 0.0 : 1.0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _GlassSquareControlButton(
                            buttonKey: const ValueKey<String>(
                              'swipe-deck-filter-button',
                            ),
                            tooltip: 'Kategori, Gezgin, Tur Şirketi Seçimi',
                            icon: PhosphorIcons.slidersHorizontal(
                              PhosphorIconsStyle.bold,
                            ),
                            onTap: () => _showMultiSelectFilterSheet(context),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showMultiSelectFilterSheet(context),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Kategoriler, Gezginler, Tur şirketleri',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    vm.activeDeckFilterSummaryLabel,
                                    key: const ValueKey<String>(
                                      'swipe-deck-active-filter-summary',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: BeenHereColors.verifiedEmerald,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Sağ Üst: Elle Mekan Arama Butonu
                IgnorePointer(
                  ignoring: isSwiping,
                  child: AnimatedOpacity(
                    key: const ValueKey<String>(
                      'swipe-deck-search-button-opacity',
                    ),
                    duration: const Duration(milliseconds: 140),
                    opacity: isSwiping ? 0.0 : 1.0,
                    child: _GlassSquareControlButton(
                      buttonKey: const ValueKey<String>(
                        'swipe-deck-manual-search-button',
                      ),
                      tooltip: 'Elle Mekan Arama Butonu',
                      icon: PhosphorIcons.magnifyingGlassPlus(
                        PhosphorIconsStyle.bold,
                      ),
                      onTap: () => _showManualPlaceSearchSheet(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. SOL ORTA KENAR: Geçilenler (Sadece birbirinin üstüne binen maks. 5 küçük mekan resmi)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: IgnorePointer(
                ignoring: isSwiping,
                child: AnimatedOpacity(
                  key: const ValueKey<String>(
                    'swipe-deck-dismissed-button-opacity',
                  ),
                  duration: const Duration(milliseconds: 140),
                  opacity: isSwiping ? 0.0 : 1.0,
                  child: _SideEdgeCounterButton(
                    buttonKey: const ValueKey<String>(
                      'swipe-deck-dismissed-button',
                    ),
                    sideKey: 'dismissed',
                    tooltip: 'Seçilmemiş Mekanlar (Sola Kaydırılmış)',
                    places: vm.dismissedDeckPlaces,
                    onTap: () => _showDismissedPlacesSheet(context),
                  ),
                ),
              ),
            ),
          ),

          // 5. SAĞ ORTA KENAR: Seçilenler (Sadece birbirinin üstüne binen maks. 5 küçük mekan resmi)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IgnorePointer(
                ignoring: isSwiping,
                child: AnimatedOpacity(
                  key: const ValueKey<String>(
                    'swipe-deck-selected-button-opacity',
                  ),
                  duration: const Duration(milliseconds: 140),
                  opacity: isSwiping ? 0.0 : 1.0,
                  child: _SideEdgeCounterButton(
                    buttonKey: const ValueKey<String>(
                      'swipe-deck-selected-button',
                    ),
                    sideKey: 'selected',
                    tooltip: 'Seçili Mekanlar (Sağa Kaydırılanlar)',
                    places: vm.selectedDeckPlaces,
                    onTap: () => _showSelectedPlacesSheet(context),
                  ),
                ),
              ),
            ),
          ),

          // 6. SOL ALT: Önceki İşlemi Geri Al (Buzlu alt menünün hemen üstünde, çekimde gizlenir)
          Positioned(
            left: 14,
            bottom: bottomContentOffset,
            child: IgnorePointer(
              ignoring: isSwiping,
              child: AnimatedOpacity(
                key: const ValueKey<String>(
                  'swipe-deck-undo-button-opacity',
                ),
                duration: const Duration(milliseconds: 140),
                opacity: isSwiping ? 0.0 : 1.0,
                child: _CircularCornerButton(
                  buttonKey: const ValueKey<String>(
                    'swipe-deck-undo-button',
                  ),
                  tooltip: 'Önceki işlemi geri al',
                  icon: PhosphorIcons.arrowCounterClockwise(
                    PhosphorIconsStyle.bold,
                  ),
                  isEnabled: vm.canUndoSwipe,
                  accentColor: Colors.white,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    vm.undoLastSwipe();
                  },
                ),
              ),
            ),
          ),

          // 7. SAĞ ALT: Rota Önizlemesi / İleri (Buzlu alt menünün hemen üstünde, çekimde gizlenir)
          Positioned(
            right: 14,
            bottom: bottomContentOffset,
            child: IgnorePointer(
              ignoring: isSwiping,
              child: AnimatedOpacity(
                key: const ValueKey<String>(
                  'swipe-deck-preview-button-opacity',
                ),
                duration: const Duration(milliseconds: 140),
                opacity: isSwiping ? 0.0 : 1.0,
                child: _CircularCornerButton(
                  buttonKey: const ValueKey<String>(
                    'swipe-deck-preview-button',
                  ),
                  tooltip: 'Rota Önizlemesi (Sonraki Adım)',
                  icon: PhosphorIcons.arrowRight(
                    PhosphorIconsStyle.bold,
                  ),
                  isEnabled: true,
                  accentColor: BeenHereColors.verifiedEmerald,
                  onTap: () => _showRoutePreviewSheet(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sağa/sola çekim esnasında kartın sol üst / sağ üst köşesinde çıkan;
/// arka plansız, bordersız, büyük boyutlu ve Tailwind CSS `animate-ping`
/// tarzı sonsuz (infinite) dalga/yankı animasyonlu aksiyon ikonu.
class _SwipePingActionIcon extends StatelessWidget {
  const _SwipePingActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.progress,
    required this.pingAnimation,
  });

  final PhosphorIconData icon;
  final Color color;
  final double progress;
  final Animation<double> pingAnimation;

  static const Cubic _tailwindPingCurve = Cubic(0.0, 0.0, 0.2, 1.0);

  @override
  Widget build(BuildContext context) {
    final double baseOpacity = (0.45 + 0.55 * progress).clamp(0.0, 1.0);
    final double baseScale = 0.88 + (0.20 * progress);

    return Opacity(
      opacity: baseOpacity,
      child: Transform.scale(
        scale: baseScale,
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Tailwind animate-ping tarzı sonsuz büyüyüp sönümlenen yankı ikonu
              AnimatedBuilder(
                animation: pingAnimation,
                builder: (context, child) {
                  final double rawT = pingAnimation.value.clamp(0.0, 1.0);
                  final double normalizedT = (rawT / 0.78).clamp(0.0, 1.0);
                  final double curvedT =
                      _tailwindPingCurve.transform(normalizedT);
                  final double pingScale = 1.0 + (0.95 * curvedT);
                  final double pingOpacity =
                      (0.75 * (1.0 - curvedT)).clamp(0.0, 0.75);

                  return Opacity(
                    key: const ValueKey<String>(
                      'swipe-card-ping-echo-opacity',
                    ),
                    opacity: pingOpacity,
                    child: Transform.scale(
                      key: const ValueKey<String>('swipe-card-ping-echo'),
                      scale: pingScale,
                      child: child,
                    ),
                  );
                },
                child: PhosphorIcon(
                  icon,
                  size: 56,
                  color: color,
                ),
              ),

              // Ana ön ikon (arka plan ve border yok, sadece büyük ikon)
              PhosphorIcon(
                key: const ValueKey<String>('swipe-card-primary-action-icon'),
                icon,
                size: 56,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceGalleryBackdrop extends StatelessWidget {
  const _PlaceGalleryBackdrop({
    required this.place,
    required this.photoIndex,
    this.isPrimaryCard = false,
  });

  final SwipeDeckPlaceItem place;
  final int photoIndex;
  final bool isPrimaryCard;

  Widget _buildPhotoImage(
    String url,
    int safeIdx, {
    required bool includeKey,
  }) {
    if (url.isNotEmpty) {
      return Image.network(
        url,
        key: includeKey
            ? ValueKey<String>('place-photo-${place.id}-$safeIdx')
            : null,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Image.asset(
          RouteBuilderViewModel.cityPlaceholderAsset,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      RouteBuilderViewModel.cityPlaceholderAsset,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeIdx = place.photoUrls.isEmpty
        ? 0
        : photoIndex.clamp(0, place.photoUrls.length - 1);
    final url = place.photoUrls.isEmpty ? '' : place.photoUrls[safeIdx];

    final List<List<Color>> tintPalettes = <List<Color>>[
      const <Color>[
        Color(0x3806101E),
        Color(0x0506101E),
        Color(0x2E050A12),
        Color(0x48050A12),
      ],
      const <Color>[
        Color(0x381A1026),
        Color(0x051A1026),
        Color(0x2E070B14),
        Color(0x48070B14),
      ],
      const <Color>[
        Color(0x3808241E),
        Color(0x0508241E),
        Color(0x2E060C14),
        Color(0x48060C14),
      ],
    ];
    final palette = tintPalettes[safeIdx % tintPalettes.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Net ana fotoğraf
        _buildPhotoImage(url, safeIdx, includeKey: true),

        // 2. Keskin sınır/çizgi olmadan yukarıdan aşağıya piksel bazında
        //    ShaderMask (BlendMode.dstIn) ile kademeli artan buzlu fotoğraf katmanı
        Positioned.fill(
          key: isPrimaryCard
              ? const ValueKey<String>('swipe-deck-bottom-menu-frost')
              : null,
          child: IgnorePointer(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: <double>[0.0, 0.66, 0.76, 0.86, 0.94, 1.0],
                  colors: <Color>[
                    Color(0x00FFFFFF), // %0..%66 tamamen net (%0 blur)
                    Color(0x00FFFFFF), // %66'da hala %0 (sıfır sınır çizgisi)
                    Color(0x33FFFFFF), // %76'da %20 buzlu
                    Color(0x8CFFFFFF), // %86'da %55 buzlu
                    Color(0xD9FFFFFF), // %94'te %85 buzlu
                    Color(0xFFFFFFFF), // %100'de %100 buzlu
                  ],
                ).createShader(bounds);
              },
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 20,
                  sigmaY: 20,
                  tileMode: TileMode.clamp,
                ),
                child: _buildPhotoImage(url, safeIdx, includeKey: false),
              ),
            ),
          ),
        ),

        // 3. Yumuşak atmosferik renk gradyanı
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const <double>[0.0, 0.40, 0.75, 1.0],
              colors: palette,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyDeckStateBody extends StatelessWidget {
  const _EmptyDeckStateBody({
    required this.viewModel,
    required this.onOpenFilters,
  });

  final RouteBuilderViewModel viewModel;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 68),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.sparkle(PhosphorIconsStyle.duotone),
              size: 38,
              color: BeenHereColors.verifiedEmerald,
            ),
            const SizedBox(height: 10),
            const Text(
              'Destedeki Tüm Mekanları İncelediniz',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sol alttan son işlemi geri alabilir, filtreleri genişletebilir veya sağ alttan Rota Önizlemesine geçebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onOpenFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Text('Filtreleri Düzenle'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wireframe 2 Sol Üst & Sağ Üst Yuvarlatılmış Kare Kontrol Butonu
class _GlassSquareControlButton extends StatelessWidget {
  const _GlassSquareControlButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final Key buttonKey;
  final String tooltip;
  final PhosphorIconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.1,
              ),
            ),
            child: Center(
              child: PhosphorIcon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wireframe 2 Sol Orta & Sağ Orta Kenar:
/// Yukarıdan aşağıya birbirinin üstüne binecek şekilde (overlapping stack)
/// yalnızca maksimum 5 adet bordersız küçük mekan resim kartı gösteren dikey bileşen.
class _SideEdgeCounterButton extends StatelessWidget {
  const _SideEdgeCounterButton({
    required this.buttonKey,
    required this.sideKey,
    required this.tooltip,
    required this.places,
    required this.onTap,
  });

  static const int maxVisibleMiniCards = 5;
  static const double miniCardSize = 42.0;
  static const double verticalOverlapStep = 22.0;

  final Key buttonKey;
  final String sideKey;
  final String tooltip;
  final List<SwipeDeckPlaceItem> places;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int count = places.length;
    if (count == 0) {
      return SizedBox.shrink(key: buttonKey);
    }

    final List<SwipeDeckPlaceItem> visiblePlaces = count > maxVisibleMiniCards
        ? places.sublist(count - maxVisibleMiniCards)
        : places;
    final double stackHeight =
        miniCardSize + (visiblePlaces.length - 1) * verticalOverlapStep;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: miniCardSize,
            height: stackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < visiblePlaces.length; i++)
                  Positioned(
                    top: i * verticalOverlapStep,
                    left: 0,
                    right: 0,
                    child: Container(
                      key: ValueKey<String>(
                        'swipe-side-mini-card-$sideKey-${visiblePlaces[i].id}',
                      ),
                      width: miniCardSize,
                      height: miniCardSize,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E1520),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: visiblePlaces[i].photoUrls.isNotEmpty
                          ? Image.network(
                              visiblePlaces[i].photoUrls.first,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) => Image.asset(
                                RouteBuilderViewModel.cityPlaceholderAsset,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              RouteBuilderViewModel.cityPlaceholderAsset,
                              fit: BoxFit.cover,
                            ),
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

/// Wireframe 2 Sol Alt & Sağ Alt Yuvarlak Köşe Butonu
class _CircularCornerButton extends StatelessWidget {
  const _CircularCornerButton({
    required this.buttonKey,
    required this.tooltip,
    required this.icon,
    required this.isEnabled,
    required this.accentColor,
    required this.onTap,
  });

  final Key buttonKey;
  final String tooltip;
  final PhosphorIconData icon;
  final bool isEnabled;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.45,
        child: Material(
          color: Colors.black.withValues(alpha: 0.58),
          shape: const CircleBorder(),
          child: InkWell(
            key: buttonKey,
            onTap: isEnabled ? onTap : null,
            customBorder: const CircleBorder(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEnabled
                      ? accentColor.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.30),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: PhosphorIcon(
                  icon,
                  size: 20,
                  color: isEnabled ? accentColor : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  const _FilterToggleChip({
    required this.chipKey,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final Key chipKey;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: 0.18)
          : BeenHereColors.background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        key: chipKey,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isSelected ? accentColor : BeenHereColors.borderSubtle,
              width: isSelected ? 1.2 : 0.9,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: accentColor,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? accentColor : BeenHereColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
