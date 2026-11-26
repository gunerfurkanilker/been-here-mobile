import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:been_here_mobile/main.dart';
import 'package:been_here_mobile/ui/core/theme/been_here_theme.dart';
import 'package:been_here_mobile/ui/core/view_models/navigation_shell_view_model.dart';
import 'package:been_here_mobile/ui/core/widgets/been_here_shell_scaffold.dart';

void main() {
  testWidgets(
    'BeenHereShellScaffold: Aşağı kaydırmada yalnızca Topbar gizlenmeli, Alt Bar her zaman görünür kalmalı; yukarı kaydırmada Topbar belirmeli',
    (WidgetTester tester) async {
      await tester.pumpWidget(const BeenHereApp());
      await tester.pump(const Duration(milliseconds: 450));

      // Başlangıçta: Topbar ('Rotalar') ve Alt Menü ('Rota Oluştur' butonu) görünür
      expect(find.text('Rotalar'), findsOneWidget);
      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.byTooltip('Rota Oluştur').hitTestable(), findsOneWidget);

      // Rota Oluştur sekmesine geç
      await tester.tap(find.byTooltip('Rota Oluştur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('Rota Oluştur'), findsOneWidget);
      final initialBottomNavRect = tester.getRect(find.byTooltip('Rota Oluştur'));

      // Route Builder içindeki dikey scrollable'ı bul
      final scrollableFinder = find.byType(Scrollable).first;

      // 1. Aşağıya doğru kaydır (drag up, content moves up / scroll down)
      await tester.drag(scrollableFinder, const Offset(0, -350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Topbar gizlenmeli, ancak Alt Bar yerinden kıpırdamadan görünür ve tıklanabilir kalmalı
      expect(find.byType(AppBar).hitTestable(), findsNothing);
      expect(find.byTooltip('Rota Oluştur').hitTestable(), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Rota Oluştur')),
        initialBottomNavRect,
      );

      // 2. Yukarı doğru kaydır (drag down, content moves down / scroll up)
      await tester.drag(scrollableFinder, const Offset(0, 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Topbar ve Alt Bar görünür olmalı
      expect(find.text('Rota Oluştur'), findsOneWidget);
      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.byTooltip('Rota Oluştur').hitTestable(), findsOneWidget);
    },
  );

  testWidgets(
    'BeenHereShellScaffold: Sekme değiştiğinde gizli olan Topbar otomatik geri görünür olmalı',
    (WidgetTester tester) async {
      final viewModel = NavigationShellViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: BeenHereShellScaffold(
            viewModel: viewModel,
            tabBodies: {
              BeenHereNavTab.home: ListView.builder(
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(
                  height: 60,
                  child: Text('Home Item $i'),
                ),
              ),
              BeenHereNavTab.compassRouteBuilder: ListView.builder(
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(
                  height: 60,
                  child: Text('Builder Item $i'),
                ),
              ),
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));

      // Başlangıç: Home sekmesi aktif
      expect(find.text('Rotalar'), findsOneWidget);
      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      final initialBottomNavRect = tester.getRect(find.byTooltip('Mekanlar'));

      // Aşağı doğru kaydır -> Topbar gizlenmeli, Alt Bar görünür kalmalı
      await tester.drag(find.text('Home Item 1'), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(AppBar).hitTestable(), findsNothing);
      expect(find.byTooltip('Mekanlar').hitTestable(), findsOneWidget);
      expect(tester.getRect(find.byTooltip('Mekanlar')), initialBottomNavRect);

      // Sekmeyi Rota Oluştur'a değiştir
      viewModel.selectTab(BeenHereNavTab.compassRouteBuilder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Sekme değişince Topbar otomatik olarak görünür olmalı
      expect(find.text('Rota Oluştur'), findsOneWidget);
      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.text('Builder Item 0'), findsOneWidget);
    },
  );

  testWidgets(
    'BeenHereShellScaffold: Yatay kaydırma barların gizlenmesine neden olmamalı',
    (WidgetTester tester) async {
      final viewModel = NavigationShellViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: BeenHereShellScaffold(
            viewModel: viewModel,
            tabBodies: {
              BeenHereNavTab.home: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 20,
                itemBuilder: (_, i) => SizedBox(
                  width: 200,
                  child: Text('Horizontal Item $i'),
                ),
              ),
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.text('Rotalar'), findsOneWidget);

      // Yatay kaydırma yap
      await tester.drag(find.text('Horizontal Item 1'), const Offset(-150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Topbar hala görünür olmalı
      expect(find.text('Rotalar'), findsOneWidget);
    },
  );

  testWidgets(
    'BeenHereShellScaffold: Topbar görünürken dy == 0.0 konumunda boşluksuz oturur ve body kırpılır',
    (WidgetTester tester) async {
      final viewModel = NavigationShellViewModel();
      const bodyProbeKey = ValueKey<String>('web-body-top-probe');

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.zero,
            ),
            child: BeenHereShellScaffold(
              viewModel: viewModel,
              tabBodies: {
                BeenHereNavTab.home: Column(
                  children: [
                    const SizedBox(key: bodyProbeKey, height: 40),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 30,
                        itemBuilder: (_, i) => SizedBox(
                          height: 60,
                          child: Text('Web Item $i'),
                        ),
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));

      final appBarRect = tester.getRect(find.byType(AppBar));
      expect(appBarRect.top, 0.0);
      expect(appBarRect.height, kToolbarHeight);

      final bodyTop = tester.getTopLeft(find.byKey(bodyProbeKey)).dy;
      expect(bodyTop, kToolbarHeight);

      // AppBar alanında solid background ColoredBox ve body içinde ClipRect bulunur
      final coloredBoxes = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        coloredBoxes.any((box) => box.color == BeenHereColors.background),
        isTrue,
      );
      expect(
        find.descendant(
          of: find.byType(NotificationListener<ScrollNotification>),
          matching: find.byType(ClipRect),
        ),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'BeenHereShellScaffold: Çentikli cihazda Topbar dy == 0.0 konumunda tam hizalanır, gizlenince status bar altına taşmaz',
    (WidgetTester tester) async {
      final viewModel = NavigationShellViewModel();
      const bodyProbeKey = ValueKey<String>('notch-body-top-probe');
      const notchTopPadding = 47.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 844),
              padding: EdgeInsets.only(top: notchTopPadding),
            ),
            child: BeenHereShellScaffold(
              viewModel: viewModel,
              tabBodies: {
                BeenHereNavTab.home: Column(
                  children: [
                    const SizedBox(key: bodyProbeKey, height: 48),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 40,
                        itemBuilder: (_, i) => SizedBox(
                          height: 60,
                          child: Text('Notch Item $i'),
                        ),
                      ),
                    ),
                  ],
                ),
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));

      // Topbar görünürken: üst kenar dy == 0.0, yükseklik kToolbarHeight + notchTopPadding,
      // body hemen altında başlar (çift padding veya ekstra boşluk yok).
      final visibleAppBarRect = tester.getRect(find.byType(AppBar));
      expect(visibleAppBarRect.top, 0.0);
      expect(visibleAppBarRect.height, kToolbarHeight + notchTopPadding);
      expect(
        tester.getTopLeft(find.byKey(bodyProbeKey)).dy,
        kToolbarHeight + notchTopPadding,
      );

      // Aşağı kaydırınca Topbar gizlenir ama body çentik/status bar alanına (0..47) girmez.
      // İlk kaydırma listeyi pixels > 0 konumuna taşır; devam eden aşağı kaydırma
      // UserScrollNotification(reverse) ile Topbar'ı gizler.
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(tester.getTopLeft(find.byKey(bodyProbeKey)).dy, notchTopPadding);

      // Yukarı kaydırınca Topbar tekrar dy == 0.0 konumunda tam görünür olur
      await tester.drag(find.byType(ListView), const Offset(0, 320));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      final restoredAppBarRect = tester.getRect(find.byType(AppBar));
      expect(restoredAppBarRect.top, 0.0);
      expect(restoredAppBarRect.height, kToolbarHeight + notchTopPadding);
      expect(
        tester.getTopLeft(find.byKey(bodyProbeKey)).dy,
        kToolbarHeight + notchTopPadding,
      );
    },
  );

  testWidgets(
    'BeenHereShellScaffold: İç içe yatay kart üzerinde mouse tekerleği (PointerScrollEvent) ile dikey kaydırma Topbarı gizler, Alt Bar görünür kalır, yukarı kaydırma Topbarı geri getirir',
    (WidgetTester tester) async {
      final viewModel = NavigationShellViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: BeenHereShellScaffold(
            viewModel: viewModel,
            tabBodies: {
              BeenHereNavTab.home: ListView.builder(
                itemCount: 20,
                itemBuilder: (_, cardIndex) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      itemBuilder: (_, photoIndex) => Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        alignment: Alignment.center,
                        child: Text('Card $cardIndex - Photo $photoIndex'),
                      ),
                    ),
                  ),
                ),
              ),
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.byTooltip('Rotalar').hitTestable(), findsOneWidget);
      final initialBottomNavRect = tester.getRect(find.byTooltip('Rotalar'));

      final cardCenter = tester.getCenter(find.text('Card 0 - Photo 0'));
      final mousePointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(mousePointer.hover(cardCenter));

      // Aşağı mouse wheel (ScrollUpdateNotification üretir) -> Topbar gizlenmeli, Alt Bar kalmalı
      await tester.sendEventToBinding(
        mousePointer.scroll(const Offset(0, 120)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(AppBar).hitTestable(), findsNothing);
      expect(find.byTooltip('Rotalar').hitTestable(), findsOneWidget);
      expect(tester.getRect(find.byTooltip('Rotalar')), initialBottomNavRect);

      // Yukarı mouse wheel -> Topbar tekrar görünür olmalı
      await tester.sendEventToBinding(
        mousePointer.scroll(const Offset(0, -120)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(AppBar).hitTestable(), findsOneWidget);
      expect(find.byTooltip('Rotalar').hitTestable(), findsOneWidget);
    },
  );
}
