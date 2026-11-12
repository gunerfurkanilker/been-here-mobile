import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';
import '../view_models/home_feed_view_model.dart';

/// Instagram / Airbnb Tarzı Hero Animasyonlu Tam Ekran Rota Detay Ekranı.
/// - Üstte sağa-sola kaydırılabilir temiz fotoğraf slider'ı (indikatörlerin üzerinde başlık karmaşası yok)
/// - Aşağı doğru kaydırıldığında devreye giren "Liquid Glass" (Frosted Glass / BackdropFilter blur) üst bar
/// - Sayfa içinde sonsuz döngülü (Infinite Scroll) ve bir sonraki mekanı uçtan gösteren
///   Mekan / Durak kartları slider'ı (`PageView` + `viewportFraction: 0.86`)
class RouteDetailScreen extends StatefulWidget {
  const RouteDetailScreen({
    super.key,
    required this.route,
    required this.viewModel,
  });

  final PublishedRouteFeedItem route;
  final HomeFeedViewModel viewModel;

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  final TextEditingController _questionController = TextEditingController();
  PageController? _stopsPageController;
  ScrollController? _scrollController;

  int _currentHeaderSlide = 0;
  int _activeStopIndex = 0;
  double _collapseProgress = 0.0;
  bool _isSaved = false;
  final Set<String> _savedStopIds = {};
  final Set<String> _addedStopIds = {};

  static const int _kStopLoopFactor = 1000;

  ScrollController get scrollController {
    return _scrollController ??=
        (ScrollController()..addListener(_onScroll));
  }

  PageController get stopsPageController {
    return _stopsPageController ??= PageController(
      viewportFraction: 0.86,
      initialPage: widget.route.stops.isNotEmpty
          ? widget.route.stops.length * (_kStopLoopFactor ~/ 2)
          : 0,
    );
  }

  @override
  void initState() {
    super.initState();
    // Güvenli başlatma: hem initState hem de Hot Reload anında lazy getter ile çalışır
    final _ = stopsPageController;
    final _ = scrollController;
  }

  void _onScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    // 180 piksel kaydırıldığında sıvı cam üst bar tamamen aktifleşir
    final progress = (controller.offset / 180.0).clamp(0.0, 1.0);
    if ((progress - _collapseProgress).abs() > 0.01) {
      if (mounted) {
        setState(() {
          _collapseProgress = progress;
        });
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _stopsPageController?.dispose();
    _scrollController?.removeListener(_onScroll);
    _scrollController?.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    final text = _questionController.text.trim();
    if (text.length < 3) return;
    widget.viewModel.addQuestionToRoute(widget.route.id, text);
    _questionController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Sorunuz rota sahibinin profilindeki Q&A sekmesine iletildi!',
        ),
      ),
    );
  }

  void _toggleSave() {
    setState(() {
      _isSaved = !_isSaved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          _isSaved
              ? 'Rota kaydedilenler listenize eklendi!'
              : 'Rota kaydedilenlerden çıkarıldı.',
        ),
      ),
    );
  }

  void _toggleSaveStop(String stopId, String placeName) {
    final willSave = !_savedStopIds.contains(stopId);
    setState(() {
      if (willSave) {
        _savedStopIds.add(stopId);
      } else {
        _savedStopIds.remove(stopId);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(
          willSave
              ? '🚩 "$placeName" özel listenize kaydedildi!'
              : '"$placeName" özel listenizden çıkarıldı.',
        ),
      ),
    );
  }

  void _toggleAddToRouteStop(String stopId, String placeName) {
    final willAdd = !_addedStopIds.contains(stopId);
    setState(() {
      if (willAdd) {
        _addedStopIds.add(stopId);
      } else {
        _addedStopIds.remove(stopId);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Text(
          willAdd
              ? '📍 "$placeName" taslak rotanıza eklendi!'
              : '"$placeName" taslak rotanızdan çıkarıldı.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final sliderImages = route.cappedFeaturedMedia;
    final stops = route.stops;
    final virtualStopCount =
        stops.isNotEmpty ? stops.length * _kStopLoopFactor : 0;

    final rawTopPadding = MediaQuery.paddingOf(context).top;
    // Safari Web veya notch'suz ortamlarda üst sınıra yapışmayı önlemek için minimum 14px nefes payı
    final topPadding = rawTopPadding > 0 ? rawTopPadding : 14.0;
    final barHeight = topPadding + kToolbarHeight;
    final blurSigma = (18.0 * _collapseProgress).clamp(0.001, 18.0);

    return Scaffold(
      backgroundColor: BeenHereColors.background,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final questions = widget.viewModel.getQuestionsForRoute(route);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. ANA SAYFA KAYDIRMA LİSTESİ (Slivers)
              CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1.1. ÜST FOTOĞRAF SLIDER'I (Başlık indikatörlerin üzerinden kaldırıldı, tertemiz slider)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 330,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Sağa-Sola Kaydırılabilir Üst Fotoğraf Slider'ı
                          PageView.builder(
                            itemCount: sliderImages.length,
                            onPageChanged: (idx) {
                              setState(() {
                                _currentHeaderSlide = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              final imageUrl = sliderImages[index];
                              final imgWidget = Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1E3A5F),
                                          Color(0xFF0F2027),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.landscape_rounded,
                                        size: 54,
                                        color: BeenHereColors.secondaryAmber,
                                      ),
                                    ),
                                  );
                                },
                              );

                              if (index == 0) {
                                return Hero(
                                  tag: 'route-hero-image-${route.id}',
                                  child: imgWidget,
                                );
                              }
                              return imgWidget;
                            },
                          ),

                          // Alt Gradyan Gölgesi (Noktalar ve sayaç için kontrast)
                          const IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x990B1320),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Sağ Altta Fotoğraf Sayacı (Örn: 2 / 5)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.photo_library_outlined,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${_currentHeaderSlide + 1} / ${sliderImages.length}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Alt Ortada Slider Noktaları (Dots) - İndikatör alanı tertemiz!
                          if (sliderImages.length > 1)
                            Positioned(
                              bottom: 18,
                              left: 20,
                              child: IgnorePointer(
                                child: Row(
                                  children: List.generate(sliderImages.length,
                                      (idx) {
                                    final isSelected =
                                        idx == _currentHeaderSlide;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 4),
                                      width: isSelected ? 16 : 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? BeenHereColors.primaryCompass
                                            : Colors.white
                                                .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 1.2. ROTA DETAY İÇERİK BLOĞU
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rota Sahibi Profil Satırı
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: BeenHereColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: BeenHereColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: BeenHereColors.primaryCompass
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.hiking_rounded,
                                    size: 24,
                                    color: BeenHereColors.primaryCompass,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              route.authorDisplayName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    BeenHereColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '@${route.authorUsername}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  BeenHereColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: BeenHereColors.goldLeague
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              route.authorRankLabel,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    BeenHereColors.goldLeague,
                                              ),
                                            ),
                                          ),
                                          if (route.cities.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '• ${route.cities.join(', ')}',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: BeenHereColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: BeenHereColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BeenHereColors.borderSubtle,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                  tooltip: 'Gezgin Profilini İncele',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Başlık & Açıklama
                          Text(
                            route.title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: BeenHereColors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            route.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: BeenHereColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Seyahat Özet Rozetleri (Tarih, Süre, Kişi, Bütçe, Fork)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DetailChip(
                                icon: Icons.calendar_today_rounded,
                                text: route.dateRangeText,
                              ),
                              _DetailChip(
                                icon: Icons.timelapse_rounded,
                                text: '${route.durationDays} Günlük Rota',
                              ),
                              _DetailChip(
                                icon: Icons.people_alt_rounded,
                                text: route.childrenCount > 0
                                    ? '${route.travelersCount} Kişi (${route.adultsCount}Y + ${route.childrenCount}Ç)'
                                    : '${route.travelersCount} Yetişkin',
                              ),
                              _DetailChip(
                                icon: Icons.payments_outlined,
                                text:
                                    '\$${route.estimatedBudgetUsd.round()} (${route.estimatedBudgetLocal.round()} ${route.localCurrencySymbol})',
                                isAccent: true,
                              ),
                              _DetailChip(
                                icon: Icons.call_split_rounded,
                                text:
                                    '${route.forkCount} Gezgin Esinlendi (Fork)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),

                          // =======================================================
                          // 1. ROTA DURAKLARI VE GEZGİN NOTLARI (INFINITE SLIDER)
                          // =======================================================
                          Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                color: BeenHereColors.primaryCompass,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rota Durakları ve Gezgin Notları',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              if (stops.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BeenHereColors.primaryCompass
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_activeStopIndex + 1} / ${stops.length} Durak',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // MEKANLAR İÇİN INFINITE CAROUSEL (BİR SONRAKİ İTEM UÇTAN GÖRÜNÜR)
                          if (stops.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Bu rotada henüz eklenmiş durak bulunmuyor.',
                                style: TextStyle(
                                    color: BeenHereColors.textSecondary),
                              ),
                            )
                          else ...[
                            SizedBox(
                              height: 385,
                              child: PageView.builder(
                                controller: stopsPageController,
                                padEnds: false,
                                itemCount: virtualStopCount,
                                onPageChanged: (idx) {
                                  setState(() {
                                    _activeStopIndex = idx % stops.length;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final stop = stops[index % stops.length];
                                  final isSaved =
                                      _savedStopIds.contains(stop.id);
                                  final isAdded =
                                      _addedStopIds.contains(stop.id);

                                  return _StopSliderCard(
                                    stop: stop,
                                    isSaved: isSaved,
                                    isAddedToRoute: isAdded,
                                    onToggleSave: () => _toggleSaveStop(
                                      stop.id,
                                      stop.placeName,
                                    ),
                                    onToggleAddToRoute: () =>
                                        _toggleAddToRouteStop(
                                      stop.id,
                                      stop.placeName,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Alt Gösterge & Kaydırma Rehberi
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '📍 ${stops[_activeStopIndex].placeName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: BeenHereColors.goldLeague,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Kaydır',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: BeenHereColors.textSecondary,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 13,
                                      color: BeenHereColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 28),

                          // =======================================================
                          // 2. ESNEK KONAKLAMA ÖZETİ
                          // =======================================================
                          Row(
                            children: [
                              Icon(
                                Icons.hotel_rounded,
                                color: BeenHereColors.secondaryAmber,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Konaklama Noktaları',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BeenHereColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: BeenHereColors.borderSubtle),
                            ),
                            child: Column(
                              children: [
                                for (final stay in route.stays)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.bed_rounded,
                                          color: BeenHereColors.secondaryAmber,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            '${stay.stayTypeLabel} • ${stay.regionOrHotelName}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: BeenHereColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                BeenHereColors.surfaceElevated,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${stay.nightsCount} Gece',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: BeenHereColors.goldLeague,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // =======================================================
                          // 3. YUVARLAK BÜTÇE KALEMLERİ DAĞILIMI
                          // =======================================================
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: BeenHereColors.verifiedEmerald,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Seyahat Bütçesi ve Harcama Kalemleri',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BeenHereColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: BeenHereColors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Toplam Tahmini Maliyet:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: BeenHereColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '\$${route.estimatedBudgetUsd.round()} (${route.estimatedBudgetLocal.round()} ${route.localCurrencySymbol})',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: BeenHereColors.verifiedEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: BeenHereColors.borderSubtle),
                                const SizedBox(height: 8),
                                for (final entry in route.budgetBreakdown.entries)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: BeenHereColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '\$${entry.value.round()}',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                BeenHereColors.secondaryAmber,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // =======================================================
                          // 4. GEZGİN SORU & CEVAP (Q&A) ALANI
                          // =======================================================
                          Row(
                            children: [
                              Icon(
                                Icons.question_answer_rounded,
                                color: BeenHereColors.goldLeague,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Gezgin Soru & Cevap (Q&A)',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BeenHereColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border:
                                  Border.all(color: BeenHereColors.borderSubtle),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (route.isQaEnabled) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _questionController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'Rota sahibine soru sor (örn: yol durumu, biletler)...',
                                            hintStyle: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  BeenHereColors.textSecondary,
                                            ),
                                            filled: true,
                                            fillColor:
                                                BeenHereColors.background,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: _submitQuestion,
                                        child: const Text('Sor'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (questions.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      'Henüz bu rotaya soru sorulmamış. İlk soruyu sen sorabilirsin!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: BeenHereColors.textSecondary,
                                      ),
                                    ),
                                  )
                                else
                                  for (final q in questions)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: BeenHereColors.surfaceElevated,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '@${q.askerUsername}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      BeenHereColors.goldLeague,
                                                ),
                                              ),
                                              Text(
                                                q.createdAtLabel,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: BeenHereColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'S: ${q.questionText}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  BeenHereColors.textPrimary,
                                            ),
                                          ),
                                          if (q.answerText != null) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'C (@${route.authorUsername}): ${q.answerText}',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: BeenHereColors
                                                    .verifiedEmerald,
                                              ),
                                            ),
                                          ] else ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '⏳ Rota sahibinin yanıtı bekleniyor...',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: BeenHereColors
                                                    .textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 2. "LIQUID GLASS" (FROSTED GLASS BLUR) ÜST BAR
              // Aşağı kaydırıldığında devreye girer, arkadaki içerikleri buğular
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      height: barHeight,
                      padding: EdgeInsets.only(top: topPadding),
                      decoration: BoxDecoration(
                        color: BeenHereColors.background.withValues(
                          alpha: 0.72 * _collapseProgress,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(
                              alpha: 0.12 * _collapseProgress,
                            ),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: NavigationToolbar(
                        leading: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.55 * (1.0 - _collapseProgress),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        middle: Opacity(
                          opacity: _collapseProgress,
                          child: Text(
                            route.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                        ),
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.55 * (1.0 - _collapseProgress),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isSaved
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    color: _isSaved
                                        ? BeenHereColors.secondaryAmber
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: _toggleSave,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                backgroundColor: Colors.black.withValues(
                                  alpha: 0.55 * (1.0 - _collapseProgress),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.ios_share_rounded,
                                    color: Colors.white,
                                    size: 19,
                                  ),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                            'Rota bağlantısı panoya kopyalandı!'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Mekanlar için yatay infinite slider kartı (`viewportFraction: 0.86`).
/// Bir sonraki mekanın kartı sağ uçtan zarifçe görünür.
class _StopSliderCard extends StatelessWidget {
  const _StopSliderCard({
    required this.stop,
    required this.isSaved,
    required this.isAddedToRoute,
    required this.onToggleSave,
    required this.onToggleAddToRoute,
  });

  final RouteStopDetailItem stop;
  final bool isSaved;
  final bool isAddedToRoute;
  final VoidCallback onToggleSave;
  final VoidCallback onToggleAddToRoute;

  @override
  Widget build(BuildContext context) {
    final isGeoVerified = stop.verificationType == 'GEO_VERIFIED';
    final hasPhoto = stop.photoUrls.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: 12, top: 4, bottom: 6),
      decoration: BoxDecoration(
        color: BeenHereColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BeenHereColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ÜST: Mekan Görseli veya Gradient Banner
          SizedBox(
            height: 145,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasPhoto)
                  Image.network(
                    stop.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildFallbackBanner(),
                  )
                else
                  _buildFallbackBanner(),

                // Karartma Gradyanı
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55000000),
                        Colors.transparent,
                        Color(0x990B1320),
                      ],
                    ),
                  ),
                ),

                // Sağ Üst: Yıldız Puanı
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: BeenHereColors.goldLeague,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stop.rating}.0',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sol Alt: Doğrulama Rozeti (Geo-Verified / Photo-Verified)
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGeoVerified
                              ? Icons.verified_rounded
                              : Icons.camera_alt_rounded,
                          size: 13,
                          color: BeenHereColors.verifiedEmerald,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isGeoVerified
                              ? 'Geo-Verified (+50p)'
                              : 'Photo-Verified (+20p)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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

          // 2. ALT: Mekan Bilgileri, Yorum ve Uyarılar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mekan Adı & Şehir
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        stop.city,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Vibe Etiketleri: İlk 2 Etiket + [+X Diğer] Tıklanabilir Rozeti
                  if (stop.vibes.isNotEmpty) ...[
                    Row(
                      children: [
                        for (final vibe in stop.vibes.take(2))
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: BeenHereColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: BeenHereColors.borderSubtle,
                                ),
                              ),
                              child: Text(
                                '#$vibe',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: BeenHereColors.goldLeague,
                                ),
                              ),
                            ),
                          ),
                        if (stop.vibes.length > 2)
                          InkWell(
                            onTap: () => _showAllVibesModal(context, stop),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: BeenHereColors.primaryCompass
                                    .withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: BeenHereColors.primaryCompass
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+${stop.vibes.length - 2} Diğer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: BeenHereColors.primaryCompass,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 12,
                                    color: BeenHereColors.primaryCompass,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Gezgin Yorumu (Uzun yazılarda "Devamını Oku" ile modal açılır)
                  Expanded(
                    child: InkWell(
                      onTap: () => _showFullCommentModal(context, stop),
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              stop.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: BeenHereColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (stop.comment.length > 60) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Devamını Oku',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: BeenHereColors.primaryCompass,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 13,
                                  color: BeenHereColors.primaryCompass,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Saha Uyarısı (Varsa - Dokununca tam metin ve tüm uyarılar modal ile açılır)
                  if (stop.warnings.isNotEmpty)
                    InkWell(
                      onTap: () => _showAllWarningsModal(context, stop),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF451A1C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BeenHereColors.primaryCompass.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: BeenHereColors.secondaryAmber,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                stop.warnings.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (stop.warnings.length > 1) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${stop.warnings.length - 1}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: BeenHereColors.secondaryAmber,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 13,
                              color: BeenHereColors.secondaryAmber,
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Aksiyon Butonları (Flag / Özel Liste & Rotaya Ekle)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        _PlaceCardActionButton(
                          icon: isSaved
                              ? Icons.flag_rounded
                              : Icons.outlined_flag_rounded,
                          label: isSaved ? 'Listede' : 'Kaydet',
                          isActive: isSaved,
                          activeColor: BeenHereColors.goldLeague,
                          onTap: onToggleSave,
                        ),
                        const SizedBox(width: 8),
                        _PlaceCardActionButton(
                          icon: isAddedToRoute
                              ? Icons.check_circle_rounded
                              : Icons.add_location_alt_rounded,
                          label: isAddedToRoute ? 'Rotada' : 'Rotaya Ekle',
                          isActive: isAddedToRoute,
                          activeColor: BeenHereColors.verifiedEmerald,
                          onTap: onToggleAddToRoute,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllVibesModal(BuildContext context, RouteStopDetailItem stop) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 20,
                    color: BeenHereColors.goldLeague,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stop.placeName} • Topluluk Etiketleri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Gezginlerin bu mekan için en çok oy verdiği atmosfer etiketleri:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: BeenHereColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final vibe in stop.vibes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              BeenHereColors.goldLeague.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag_rounded,
                            size: 13,
                            color: BeenHereColors.goldLeague,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vibe,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BeenHereColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFullCommentModal(BuildContext context, RouteStopDetailItem stop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color:
                          BeenHereColors.primaryCompass.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.format_quote_rounded,
                      size: 20,
                      color: BeenHereColors.primaryCompass,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${stop.city} • Gezgin Seyahat Notu',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: BeenHereColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: BeenHereColors.borderSubtle),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BeenHereColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BeenHereColors.borderSubtle),
                ),
                child: Text(
                  stop.comment,
                  style: TextStyle(
                    fontSize: 14,
                    color: BeenHereColors.textPrimary,
                    height: 1.55,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              if (stop.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF451A1C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          BeenHereColors.primaryCompass.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: BeenHereColors.secondaryAmber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.warnings.first,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAllWarningsModal(BuildContext context, RouteStopDetailItem stop) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: BeenHereColors.borderSubtle, width: 1.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BeenHereColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A2022),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: BeenHereColors.secondaryAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: BeenHereColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${stop.city} • Gezgin Saha Uyarıları (${stop.warnings.length} Bildirim)',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: BeenHereColors.secondaryAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: BeenHereColors.borderSubtle),
              const SizedBox(height: 14),
              Text(
                'Bu mekan için gezginler tarafından bildirilen dikkat edilmesi gereken durumlar:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: BeenHereColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final warning in stop.warnings)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF381517),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          BeenHereColors.primaryCompass.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.report_problem_rounded,
                          size: 16,
                          color: BeenHereColors.secondaryAmber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.4,
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
    );
  }

  Widget _buildFallbackBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0F2027),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 44,
          color: BeenHereColors.secondaryAmber,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.text,
    this.isAccent = false,
  });

  final IconData icon;
  final String text;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAccent
            ? BeenHereColors.verifiedEmerald.withValues(alpha: 0.15)
            : BeenHereColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: isAccent
            ? Border.all(
                color: BeenHereColors.verifiedEmerald.withValues(alpha: 0.4),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isAccent
                ? BeenHereColors.verifiedEmerald
                : BeenHereColors.goldLeague,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAccent
                  ? BeenHereColors.verifiedEmerald
                  : BeenHereColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mekan kartı altındaki aksiyon butonu (Flag, Rotaya Ekle, Faydalı Reaksiyon).
class _PlaceCardActionButton extends StatelessWidget {
  const _PlaceCardActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fgColor = isActive ? activeColor : BeenHereColors.textSecondary;
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.16)
        : BeenHereColors.surfaceElevated;
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.45)
        : BeenHereColors.borderSubtle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 0.9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13.5,
                color: fgColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
