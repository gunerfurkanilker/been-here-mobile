import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:been_here_mobile/main.dart';

void main() {
  testWidgets('BeenHere Faz 1 & 2: Anasayfa PUBLISHED rotalar akışı ve alt navigasyon testi',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BeenHereApp());

    // Varsayılan sekme: Rotalar — Büyük arama çubuğu ve görsel odaklı rota kartı
    // (Rotalarda Yakınımdaki Konumlar butonu yer almaz)
    expect(find.text('Ülke, konum veya şehir ismi ile ara...'), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsNothing);
    expect(find.text('Marmaris Turu'), findsOneWidget);
    expect(find.text('Amintas Kaya Mezarları'), findsOneWidget);
    expect(find.text('Yuvarlakçay'), findsOneWidget);

    // Rota kartına tıkla -> Alternatif 1: Hero animasyonlu tam ekran detay sayfası açılmalı
    await tester.tap(find.text('Marmaris Turu'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Rota Durakları ve Gezgin Notları'), findsOneWidget);
    expect(find.text('Konaklama Noktaları'), findsOneWidget);
    expect(find.text('Seyahat Bütçesi ve Harcama Kalemleri'), findsOneWidget);
    expect(find.text('Gezgin Soru & Cevap (Q&A)'), findsOneWidget);

    // Sayfayı duraklara doğru kaydır
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 400));

    // Mekan kartı aksiyon butonları: Flag (Kaydet), Rotaya Ekle
    expect(find.text('Kaydet'), findsWidgets);
    expect(find.text('Rotaya Ekle'), findsWidgets);

    // Kaydet butonuna tıkla -> 'Listede' durumuna geçmeli
    await tester.tap(find.text('Kaydet').first);
    await tester.pump();
    expect(find.text('Listede'), findsWidgets);

    // Rotaya Ekle butonuna tıkla -> 'Rotada' durumuna geçmeli
    await tester.tap(find.text('Rotaya Ekle').first);
    await tester.pump();
    expect(find.text('Rotada'), findsWidgets);

    // Geri dön
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Alt navigasyondaki 5 ikonlu Liquid Glass menü, üstteki dinamik sekme başlığı ('Rotalar') ve Canlı İzleme butonu görünür olmalı
    expect(find.text('Rotalar'), findsOneWidget);
    expect(find.byTooltip('Rotalar'), findsOneWidget);
    expect(find.byTooltip('Gezgin Ligleri'), findsOneWidget);
    expect(find.byTooltip('Rota Oluştur'), findsOneWidget);
    expect(find.byTooltip('Mekanlar'), findsOneWidget);
    expect(find.byTooltip('Anılarım'), findsOneWidget);
    expect(find.text('Geofence / EXIF'), findsOneWidget);

    // Mekanlar sekmesi ikonuna tıkla -> Üst başlık 'Mekanlar' olmalı ve Mekan Odaklı Arama ekranı açılmalı
    await tester.tap(find.byTooltip('Mekanlar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Mekanlar'), findsOneWidget);
    expect(find.text('Global (Tüm Dünya)'), findsOneWidget);
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.text('Amintas Kaya Mezarları'), findsWidgets);
    expect(find.text('#Antik Likya'), findsOneWidget);
    expect(find.text('1 Rotada Geçiyor'), findsWidgets);
    expect(find.textContaining('Benzer Lokasyonlar'), findsWidgets);

    // Yakınımdaki Mekanlar ikonuna tıkla -> Konum doğrulama ibaresi görünmeli
    await tester.tap(find.byIcon(Icons.my_location_rounded));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Konak / İzmir / Türkiye'), findsOneWidget);

    // Yakınımdaki Mekanlar butonunun yanındaki Dünya ikonuna tıkla -> Hiyerarşik ağaç çekmecesi açılmalı
    await tester.tap(find.byIcon(Icons.public_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bölge, Ülke ve Şehir Filtresi'), findsOneWidget);

    // Ağaç içi akıllı arama kutusuna "İzm" yaz -> Avrupa > Türkiye otomatik açılıp İzmir görünmeli
    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Kıta, ülke veya şehir ara (Örn: İzmir, İtalya)...',
      ),
      'İzm',
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('🇹🇷 Türkiye'), findsOneWidget);
    expect(find.text('İzmir'), findsOneWidget);

    // İzmir şehrini seç ve çekmeceyi kapat -> Seçilen bölge filtresi doğrudan aktif olmalı
    await tester.tap(find.text('İzmir'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('🇹🇷 Türkiye: İzmir'), findsOneWidget);
  });
}
