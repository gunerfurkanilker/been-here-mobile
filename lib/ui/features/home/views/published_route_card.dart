import 'package:flutter/material.dart';
import '../../../../domain/models/route_feed_models.dart';
import '../../../core/theme/been_here_theme.dart';

class PublishedRouteCard extends StatefulWidget {
  const PublishedRouteCard({
    super.key,
    required this.route,
    required this.onTapCard,
  });

  final PublishedRouteFeedItem route;
  final VoidCallback onTapCard;

  @override
  State<PublishedRouteCard> createState() => _PublishedRouteCardState();
}

class _PublishedRouteCardState extends State<PublishedRouteCard> {
  int _currentSlideIndex = 0;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final sliderImages = route.cappedFeaturedMedia;
    final placeTags = route.cappedPreviewPlaces;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTapCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. KARTIN EN ÜSTÜ: Rota Sahibini Gösteren Ayrı Başlık Alanı (Card Header)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  // Gezgin Avatarı
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        BeenHereColors.primaryCompass.withValues(alpha: 0.18),
                    child: Icon(
                      Icons.hiking_rounded,
                      size: 20,
                      color: BeenHereColors.primaryCompass,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // İsim, Kullanıcı Adı ve Rütbe
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                route.authorDisplayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: BeenHereColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '@${route.authorUsername}',
                              style: TextStyle(
                                fontSize: 12,
                                color: BeenHereColors.textSecondary,
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
                                color: BeenHereColors.goldLeague.withValues(
                                  alpha: 0.18,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                route.authorRankLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: BeenHereColors.goldLeague,
                                ),
                              ),
                            ),
                            if (route.cities.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '• ${route.cities.join(' • ')}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: BeenHereColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Sağ Üst Rota Bayrağı / Ülke Kodu Rozeti
                  if (route.countryNames.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BeenHereColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BeenHereColors.borderSubtle,
                        ),
                      ),
                      child: Text(
                        route.countryNames.first,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BeenHereColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2. ÖNCELİKLİ GÖRSEL ALANI: Maksimum 5 Fotoğraflı Geniş Slider (Üzerinde gereksiz sayaç yok)
            SizedBox(
              height: 270,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    itemCount: sliderImages.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentSlideIndex = idx;
                      });
                    },
                    itemBuilder: (context, index) {
                      final imageUrl = sliderImages[index];
                      final imageWidget = Image.network(
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.landscape_rounded,
                                    size: 48,
                                    color: BeenHereColors.secondaryAmber,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${route.cities.join(' • ')} (${index + 1}/${sliderImages.length})',
                                    style: TextStyle(
                                      color: BeenHereColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          if (index == 0)
                            Hero(
                              tag: 'route-hero-image-${route.id}',
                              child: imageWidget,
                            )
                          else
                            imageWidget,
                          // Alt kısımda slider noktaları için hafif gölge gradyanı
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.center,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0x770B1320),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Alt Orta: Slider Nokta Göstergeleri (Dots)
                  if (sliderImages.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(sliderImages.length, (idx) {
                          final isSelected = idx == _currentSlideIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isSelected ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? BeenHereColors.primaryCompass
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),

            // 3. İLK BAKIŞTA SADECE BAŞLIK + SAĞA KAYAN KONUM ETİKETLERİ
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3.1. Rota Başlığı
                  Text(
                    route.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BeenHereColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3.2. Sağa Doğru Yatay Kaydırılabilir Konum Etiketleri
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: placeTags.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final placeTitle = placeTags[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: BeenHereColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: BeenHereColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 13,
                                color: BeenHereColors.primaryCompass,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                placeTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: BeenHereColors.textPrimary,
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
          ],
        ),
      ),
    );
  }
}
