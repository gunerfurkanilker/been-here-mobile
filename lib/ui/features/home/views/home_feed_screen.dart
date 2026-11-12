import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/been_here_theme.dart';
import '../../../core/widgets/geography_tree_filter_bar.dart';
import '../view_models/home_feed_view_model.dart';
import 'fullscreen_swipe_route_card.dart';
import 'route_detail_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({
    super.key,
    required this.viewModel,
  });

  final HomeFeedViewModel viewModel;

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  /// Dokunma hareketi doğrudan listenin en altındayken mi başladı?
  /// (En alta inerken devam eden kaydırma hareketinin yanlışlıkla knob'u tetiklemesini önler)
  bool _gestureStartedAtBottom = false;

  /// En alttayken yukarı doğru sürükleme mesafesi ve %0-%100 knob ilerlemesi
  double _upwardPullPixels = 0.0;
  double _knobProgress = 0.0;
  bool _isPullingUpAtEnd = false;
  bool _hasTriggeredUnlock = false;
  Timer? _holdFillTimer;

  /// Knob'un görünmeye başlaması için gereken minimum yukarı çekme eşiği (px)
  static const double _pullDeadZonePx = 21.0;

  /// Sadece sürükleyerek %100'e ulaşmak için gereken mesafe (orta zorluk)
  static const double _fullPullDistancePx = 190.0;

  @override
  void dispose() {
    _holdFillTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isAtBottomOfScroll() {
    if (!_scrollController.hasClients) return false;
    final pos = _scrollController.position;
    return pos.pixels >= (pos.maxScrollExtent - 10.0);
  }

  /// Kullanıcı listenin en sonunda yukarı çekip parmağını basılı tuttuğunda
  /// kontrollü şekilde (~1.4 saniyede) %100'e tamamlar.
  void _startHoldFillTimer(int currentRouteCount) {
    if (_holdFillTimer != null && _holdFillTimer!.isActive) return;

    _holdFillTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted || !_isPullingUpAtEnd || _hasTriggeredUnlock) {
        timer.cancel();
        return;
      }
      // Yalnızca kullanıcı kartı yukarıda tutuyorsa ilerlet
      if (_upwardPullPixels < 48.0) {
        return;
      }
      setState(() {
        _knobProgress = (_knobProgress + 0.030).clamp(0.0, 1.0);
      });
      if (_knobProgress >= 1.0) {
        timer.cancel();
        _completeKnobAndLoadNextRoutes(currentRouteCount);
      }
    });
  }

  void _completeKnobAndLoadNextRoutes(int previousRouteCount) {
    if (_hasTriggeredUnlock) return;
    _hasTriggeredUnlock = true;
    _holdFillTimer?.cancel();

    setState(() {
      _knobProgress = 1.0;
    });

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      widget.viewModel.unlockNextRoutesBatch();

      setState(() {
        _isPullingUpAtEnd = false;
        _knobProgress = 0.0;
        _upwardPullPixels = 0.0;
        _gestureStartedAtBottom = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;
        final targetOffset = (_scrollController.offset + 340.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  void _handlePointerDown(PointerDownEvent event, int totalRoutes) {
    _upwardPullPixels = 0.0;
    _hasTriggeredUnlock = false;
    _gestureStartedAtBottom = totalRoutes > 0 && _isAtBottomOfScroll();
  }

  void _handlePointerMove(PointerMoveEvent event, int totalRoutes) {
    if (totalRoutes == 0 || _hasTriggeredUnlock || !_gestureStartedAtBottom) {
      return;
    }

    if (!_isAtBottomOfScroll()) {
      if (_isPullingUpAtEnd) {
        _resetPullKnob();
      }
      return;
    }

    // Yatay mekan slider'ı kaydırılıyorsa dikey knob'u tetikleme
    if (event.delta.dx.abs() > event.delta.dy.abs() * 1.15 &&
        !_isPullingUpAtEnd) {
      return;
    }

    // Kullanıcı parmağını yukarı doğru sürüyorsa (delta.dy < 0)
    if (event.delta.dy < 0) {
      // Direnç katsayısı: parmak hareketinin %83'ü yansır (dengeli his)
      _upwardPullPixels += (-event.delta.dy) * 0.83;

      if (_upwardPullPixels > _pullDeadZonePx) {
        final effectivePull = _upwardPullPixels - _pullDeadZonePx;
        final dragProgress =
            (effectivePull / _fullPullDistancePx).clamp(0.0, 1.0);

        setState(() {
          _isPullingUpAtEnd = true;
          if (dragProgress > _knobProgress) {
            _knobProgress = dragProgress;
          }
        });

        // Yukarı çekip tutmaya devam ederse %100'e doldur
        if (_upwardPullPixels > 48.0) {
          _startHoldFillTimer(totalRoutes);
        }

        if (_knobProgress >= 1.0) {
          _completeKnobAndLoadNextRoutes(totalRoutes);
        }
      }
    } else if (event.delta.dy > 0 && _isPullingUpAtEnd) {
      // Parmağını aşağı indirirse ilerlemeyi düşür
      _upwardPullPixels =
          (_upwardPullPixels - event.delta.dy * 1.1).clamp(0.0, 500.0);
      final effectivePull =
          (_upwardPullPixels - _pullDeadZonePx).clamp(0.0, 500.0);
      final dragProgress =
          (effectivePull / _fullPullDistancePx).clamp(0.0, 1.0);
      setState(() {
        _knobProgress = dragProgress;
        if (_knobProgress <= 0.01) {
          _isPullingUpAtEnd = false;
        }
      });
    }
  }

  void _handlePointerEnd() {
    _holdFillTimer?.cancel();
    _gestureStartedAtBottom = false;
    if (!_hasTriggeredUnlock && _isPullingUpAtEnd) {
      _resetPullKnob();
    }
  }

  void _resetPullKnob() {
    _holdFillTimer?.cancel();
    setState(() {
      _isPullingUpAtEnd = false;
      _knobProgress = 0.0;
      _upwardPullPixels = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final routes = viewModel.feedRoutes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ORTAK ARAMA ÇUBUĞU, BÜTÇE FİLTRESİ & FİLTRE HAPLARI
            GeographyTreeFilterBar(
              filterModel: viewModel,
              resultCountLabelBuilder: () =>
                  '${viewModel.geographyFilteredRoutesCount} Rota',
              searchHintText: 'Ülke, konum veya şehir ismi ile ara...',
              showNearbyButton: false,
              showBudgetFilter: true,
              showTreeDrawerButton: false,
              searchBarKey: const ValueKey<String>('home_routes_search_bar_tap'),
              budgetButtonKey:
                  const ValueKey<String>('home_routes_budget_filter_btn'),
            ),

            const SizedBox(height: 8),

            // 2. NORMAL DİKEY SCROLL ROTA AKIŞI (Altta boşluk kalmaz, Liquid Glass menünün arkasından akar)
            Expanded(
              child: routes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: BeenHereColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Seçilen bölge/şehir filtresinde henüz yayınlanmış rota bulunmuyor.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BeenHereColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: viewModel.resetToGlobal,
                              icon: const Icon(Icons.public_rounded, size: 17),
                              label: const Text('Tüm Dünya Rotalarını Göster'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Listener(
                      onPointerDown: (e) =>
                          _handlePointerDown(e, routes.length),
                      onPointerMove: (e) =>
                          _handlePointerMove(e, routes.length),
                      onPointerUp: (_) => _handlePointerEnd(),
                      onPointerCancel: (_) => _handlePointerEnd(),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: const {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                          },
                        ),
                        child: ListView.builder(
                          key: const PageStorageKey<String>(
                            'home-feed-routes-list',
                          ),
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
                          itemCount: routes.length,
                          itemBuilder: (context, index) {
                            final route = routes[index];
                            final isLastItem = index == routes.length - 1;
                            final showKnobBelowCard = isLastItem &&
                                _isPullingUpAtEnd &&
                                _knobProgress > 0.01;

                            // Knob son kartın alt sınırından aşağıya doğru kayarak çıkar
                            final slideDownOffset =
                                -18.0 * (1.0 - _knobProgress) +
                                    (_knobProgress * 10.0);

                            return Column(
                              key: ValueKey<String>('feed-item-${route.id}'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Sabit yüksekliğe sahip rota kartı (Asla sıkışmaz, alttaki kart hemen peşinden gelir)
                                SizedBox(
                                  height: 510,
                                  child: FullscreenSwipeRouteCard(
                                    route: route,
                                    onTapCard: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => RouteDetailScreen(
                                            route: route,
                                            viewModel: viewModel,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                if (!isLastItem)
                                  const SizedBox(height: 16)
                                else
                                  // Listenin en sonundaki kartın hemen altında yer alan sabit alan:
                                  // Son kartı hiç sıkıştırmadan aşağıya doğru kayarak çıkan büyüteçli dairesel knob
                                  SizedBox(
                                    height: 92,
                                    child: ClipRect(
                                      child: Align(
                                        alignment: Alignment.topCenter,
                                        child: showKnobBelowCard
                                            ? Transform.translate(
                                                offset: Offset(
                                                  0,
                                                  slideDownOffset,
                                                ),
                                                child: Opacity(
                                                  opacity: (_knobProgress * 2.2)
                                                      .clamp(0.0, 1.0),
                                                  child: SizedBox(
                                                    width: 42,
                                                    height: 42,
                                                    child: Stack(
                                                      alignment:
                                                          Alignment.center,
                                                      children: [
                                                        CircularProgressIndicator(
                                                          value: _knobProgress,
                                                          strokeWidth: 3.2,
                                                          backgroundColor:
                                                              BeenHereColors
                                                                  .borderSubtle,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            _knobProgress >= 1.0
                                                                ? BeenHereColors
                                                                    .verifiedEmerald
                                                                : BeenHereColors
                                                                    .primaryCompass,
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons.search_rounded,
                                                          size: 20,
                                                          color: _knobProgress >=
                                                                  1.0
                                                              ? BeenHereColors
                                                                  .verifiedEmerald
                                                              : BeenHereColors
                                                                  .primaryCompass,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
