import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'ui/core/theme/been_here_theme.dart';
import 'ui/core/view_models/navigation_shell_view_model.dart';
import 'ui/core/widgets/been_here_shell_scaffold.dart';
import 'ui/features/home/view_models/home_feed_view_model.dart';
import 'ui/features/home/views/home_feed_screen.dart';
import 'ui/features/route_builder/view_models/route_builder_view_model.dart';
import 'ui/features/route_builder/views/route_builder_screen.dart';
import 'ui/features/search/view_models/place_search_view_model.dart';
import 'ui/features/search/views/place_search_screen.dart';

void main() {
  runApp(const BeenHereApp());
}

class BeenHereApp extends StatefulWidget {
  const BeenHereApp({super.key});

  @override
  State<BeenHereApp> createState() => _BeenHereAppState();
}

class _BeenHereAppState extends State<BeenHereApp> {
  NavigationShellViewModel? _shellViewModel;
  HomeFeedViewModel? _homeFeedViewModel;
  PlaceSearchViewModel? _placeSearchViewModel;
  RouteBuilderViewModel? _routeBuilderViewModel;

  NavigationShellViewModel get shellViewModel =>
      _shellViewModel ??= NavigationShellViewModel();
  HomeFeedViewModel get homeFeedViewModel =>
      _homeFeedViewModel ??= HomeFeedViewModel();
  PlaceSearchViewModel get placeSearchViewModel =>
      _placeSearchViewModel ??= PlaceSearchViewModel();
  RouteBuilderViewModel get routeBuilderViewModel =>
      _routeBuilderViewModel ??= RouteBuilderViewModel();

  @override
  void initState() {
    super.initState();
    final _ = shellViewModel;
    final _ = homeFeedViewModel;
    final _ = placeSearchViewModel;
    final _ = routeBuilderViewModel;
  }

  @override
  void dispose() {
    _shellViewModel?.dispose();
    _homeFeedViewModel?.dispose();
    _placeSearchViewModel?.dispose();
    _routeBuilderViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BeenHereThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Been Here',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _BeenHereScrollBehavior(),
          theme: BeenHereTheme.lightTheme,
          darkTheme: BeenHereTheme.darkTheme,
          themeMode: BeenHereThemeController.instance.themeMode,
          home: BeenHereShellScaffold(
            viewModel: shellViewModel,
            tabBodies: {
              BeenHereNavTab.home: HomeFeedScreen(viewModel: homeFeedViewModel),
              BeenHereNavTab.leaderboards: const _PhaseOnePreviewPlaceholder(
                icon: Icons.emoji_events_rounded,
                badgeText: 'FAZ 6\'DA DETAYLANDIRILACAK',
                title: '🏆 Ligler (Kıta > Tekil Ülke & Adil Bölgesel Sıralama)',
                highlights: [
                  '1. Global | 2. Avrupa (Tümü, Almanya, Fransa, Belçika...) | 3. Asya (Tümü, Rusya, Tayland...)',
                  'Tekil ülke seçimi (Anasayfa\'daki çoklu seçimden farklı olarak)',
                  'user_regional_scores tablosu üzerinden adil bölgesel puan (regional_points) sıralaması',
                ],
              ),
              BeenHereNavTab.compassRouteBuilder: RouteBuilderScreen(
                viewModel: routeBuilderViewModel,
              ),
              BeenHereNavTab.placeSearch: PlaceSearchScreen(
                viewModel: placeSearchViewModel,
                homeFeedViewModel: homeFeedViewModel,
              ),
              BeenHereNavTab.profile: const _PhaseOnePreviewPlaceholder(
                icon: Icons.person_rounded,
                badgeText: 'FAZ 6\'DA DETAYLANDIRILACAK',
                title: '👤 Profilim (Instagram Esinlenmeli Yapı)',
                highlights: [
                  'Sol üstte 1 Ana + Basılı Tutunca (Long Press) açılan 2 Alternatif Fotoğraf (Sırt çantalı gezgin silüeti)',
                  'Rütbenin altında yatay sağa kayan kotasız Story "Öne Çıkarılanlar (Highlights)"',
                  'Alt Sekmeler: Paylaşılan Rotalar (Ülke & Tarih filtreli), Taslaklarım, Kişisel Anılarım, Favori Listelerim ve Soru & Cevap (Q&A)',
                ],
              ),
            },
          ),
        );
      },
    );
  }
}

class _BeenHereScrollBehavior extends MaterialScrollBehavior {
  const _BeenHereScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _PhaseOnePreviewPlaceholder extends StatelessWidget {
  const _PhaseOnePreviewPlaceholder({
    required this.icon,
    required this.badgeText,
    required this.title,
    required this.highlights,
  });

  final IconData icon;
  final String badgeText;
  final String title;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: BeenHereColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BeenHereColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: BeenHereColors.primaryCompass.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: BeenHereColors.primaryCompass,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    icon,
                    color: BeenHereColors.goldLeague,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BeenHereColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: BeenHereColors.borderSubtle),
              const SizedBox(height: 12),
              for (final item in highlights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: BeenHereColors.verifiedEmerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            color: BeenHereColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
