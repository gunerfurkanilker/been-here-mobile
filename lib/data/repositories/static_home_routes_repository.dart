import '../../domain/models/route_feed_models.dart';

class StaticHomeRoutesRepository {
  StaticHomeRoutesRepository();

  static const List<CountryFilterOption> _allCountries = [
    // AVRUPA (Rota sayısına göre çoktan aza sıralı)
    CountryFilterOption(
      code: 'DE',
      nameTr: 'Almanya',
      flagEmoji: '🇩🇪',
      continent: ContinentFilter.europe,
      publishedRouteCount: 18,
    ),
    CountryFilterOption(
      code: 'IT',
      nameTr: 'İtalya',
      flagEmoji: '🇮🇹',
      continent: ContinentFilter.europe,
      publishedRouteCount: 15,
    ),
    CountryFilterOption(
      code: 'TR',
      nameTr: 'Türkiye',
      flagEmoji: '🇹🇷',
      continent: ContinentFilter.europe,
      publishedRouteCount: 14,
    ),
    CountryFilterOption(
      code: 'FR',
      nameTr: 'Fransa',
      flagEmoji: '🇫🇷',
      continent: ContinentFilter.europe,
      publishedRouteCount: 11,
    ),
    CountryFilterOption(
      code: 'BE',
      nameTr: 'Belçika',
      flagEmoji: '🇧🇪',
      continent: ContinentFilter.europe,
      publishedRouteCount: 7,
    ),
    CountryFilterOption(
      code: 'NL',
      nameTr: 'Hollanda',
      flagEmoji: '🇳🇱',
      continent: ContinentFilter.europe,
      publishedRouteCount: 5,
    ),
    // ASYA
    CountryFilterOption(
      code: 'TH',
      nameTr: 'Tayland',
      flagEmoji: '🇹🇭',
      continent: ContinentFilter.asia,
      publishedRouteCount: 12,
    ),
    CountryFilterOption(
      code: 'JP',
      nameTr: 'Japonya',
      flagEmoji: '🇯🇵',
      continent: ContinentFilter.asia,
      publishedRouteCount: 9,
    ),
    CountryFilterOption(
      code: 'RU',
      nameTr: 'Rusya',
      flagEmoji: '🇷🇺',
      continent: ContinentFilter.asia,
      publishedRouteCount: 6,
    ),
    // KUZEY AMERİKA
    CountryFilterOption(
      code: 'US',
      nameTr: 'ABD',
      flagEmoji: '🇺🇸',
      continent: ContinentFilter.northAmerica,
      publishedRouteCount: 10,
    ),
    CountryFilterOption(
      code: 'CA',
      nameTr: 'Kanada',
      flagEmoji: '🇨🇦',
      continent: ContinentFilter.northAmerica,
      publishedRouteCount: 4,
    ),
    // GÜNEY AMERİKA
    CountryFilterOption(
      code: 'BR',
      nameTr: 'Brezilya',
      flagEmoji: '🇧🇷',
      continent: ContinentFilter.southAmerica,
      publishedRouteCount: 6,
    ),
    CountryFilterOption(
      code: 'AR',
      nameTr: 'Arjantin',
      flagEmoji: '🇦🇷',
      continent: ContinentFilter.southAmerica,
      publishedRouteCount: 3,
    ),
  ];

  final List<PublishedRouteFeedItem> _routes = [
    const PublishedRouteFeedItem(
      id: 'route-tr-marmaris-00',
      title: 'Marmaris Turu',
      description:
          'Fethiye sınırından başlayıp Yuvarlakçay\'ın buz gibi sularından Sakar Geçidi manzarasına ve Marmaris koylarına uzanan Ege rotası.',
      authorUsername: 'furkan_yolda',
      authorDisplayName: 'Furkan Güner',
      authorRankLabel: 'Master of Routes',
      continent: ContinentFilter.europe,
      countryCodes: ['TR'],
      countryNames: ['Türkiye'],
      cities: ['Muğla', 'Marmaris', 'Köyceğiz', 'Fethiye'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1519046904884-53103b34b206?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Amintas Kaya Mezarları',
        'Yuvarlakçay',
        'Sakar Seyir Noktası',
        'Akyaka Azmak Nehri',
        'Kleopatra Plajı (Sedir Adası)',
        'Selimiye Koyu',
        'Bozburun Yarımadası',
      ],
      dateRangeText: '14–18 Temmuz 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 5,
      estimatedBudgetUsd: 680,
      estimatedBudgetLocal: 23460,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Butik Otel & Bungalov': 310,
        'Deniz Ürünleri & Yeme-İçme': 210,
        'Araç Yakıt & Tekne Girişleri': 160,
      },
      forkCount: 74,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-m1',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Amintas Kaya Mezarları',
          city: 'Fethiye',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Gün batımına yakın çıkınca tüm körfez ayaklarımızın altındaydı.',
          vibes: ['Antik Likya', 'Panoramik Manzara', 'Fotoğraf Noktası'],
          warnings: [
            'Gezgin Saha Uyarısı: Merdivenli Çıkış - Su Yanınızda Olsun (22 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-m2',
          orderIndex: 1,
          dayNumber: 2,
          placeName: 'Yuvarlakçay',
          city: 'Köyceğiz',
          uiCategory: 'FOOD',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Suyun üzerindeki çardaklarda alabalık ve salıncak keyfi.',
          vibes: ['Buz Gibi Su', 'Doğa İçinde', 'Serinleme Noktası'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-m3',
          orderIndex: 2,
          dayNumber: 2,
          placeName: 'Sakar Seyir Noktası',
          city: 'Muğla / Akyaka',
          uiCategory: 'DESTINATION',
          verificationType: 'PHOTO_VERIFIED',
          rating: 5,
          comment: 'Gökova Körfezi\'ni yukarıdan gören en etkileyici viraj cebi.',
          vibes: ['Körfez Manzarası', 'Kısa Mola'],
          warnings: [
            'Gezgin Saha Uyarısı: Virajlı Yol - Park Cebine Dikkatli Girin (15 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Sahil Butik Otel',
          regionOrHotelName: 'Selimiye, Marmaris',
          nightsCount: 4,
        ),
      ],
      questions: [
        RouteQuestionItem(
          id: 'q-m1',
          askerUsername: 'burak_rota',
          questionText:
              'Yuvarlakçay hafta sonu çok kalabalık oluyor mu, saat kaçta gitmeli?',
          createdAtLabel: '1 gün önce',
          answerText:
              'Sabah 10:30 gibi orada olursanız en güzel su üstü çardakları sıra beklemeden yakalarsınız.',
        ),
      ],
    ),
    const PublishedRouteFeedItem(
      id: 'route-de-be-01',
      title: 'Berlin, Köln ve Brüksel: Sanat, Tren & Sokak Lezzetleri',
      description:
          'Trenle geçiş yaptığımız 6 günlük Orta Avrupa rotası. Müzeler, tarihi katedraller ve yerel waffle/kahve durakları.',
      authorUsername: 'kaan_geziyor',
      authorDisplayName: 'Kaan Demir',
      authorRankLabel: 'Elite Traveler',
      continent: ContinentFilter.europe,
      countryCodes: ['DE', 'BE'],
      countryNames: ['Almanya', 'Belçika'],
      cities: ['Berlin', 'Köln', 'Brüksel'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1560969184-10fe8719e047?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1559113202-c916b8e44373?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1528728329032-2972f65dfb3f?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Brandenburg Kapısı',
        'Müzeler Adası',
        'East Side Gallery',
        'Barn Coffee Roasters',
        'Köln Katedrali',
        'Grand Place Brüksel',
        'Maison Dandoy Waffle',
      ],
      dateRangeText: '12–17 Mayıs 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 6,
      estimatedBudgetUsd: 1180,
      estimatedBudgetLocal: 40700,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Konaklama': 480,
        'Yeme - İçme': 340,
        'Şehirlerarası Tren': 210,
        'Müze & Aktivite': 150,
      },
      forkCount: 34,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-1',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Brandenburg Kapısı',
          city: 'Berlin',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment:
              'Sabah 07:30 gibi giderseniz kalabalık olmadan harika fotoğraflar çekebilirsiniz.',
          vibes: ['Tarihi', 'Sabah Yürüyüşü', 'Fotojenik'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1560969184-10fe8719e047?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-2',
          orderIndex: 1,
          dayNumber: 1,
          placeName: 'Müzeler Adası (Pergamon & Neues Museum)',
          city: 'Berlin',
          uiCategory: 'DESTINATION',
          verificationType: 'PHOTO_VERIFIED',
          rating: 5,
          comment:
              'Günlük kombine bilet almak tek tek almaktan çok daha ekonomik.',
          vibes: ['Sanat', 'Kültür'],
          warnings: [
            'Müzeler Adası Pazartesi günleri kapalıdır.',
            'Gezgin Saha Uyarısı: Online Rezervasyon Şart (19 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1528728329032-2972f65dfb3f?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-3',
          orderIndex: 2,
          dayNumber: 2,
          placeName: 'The Barn Coffee Roasters Mitte',
          city: 'Berlin',
          uiCategory: 'FOOD',
          verificationType: 'GEO_VERIFIED',
          rating: 4,
          comment: 'V60 demlemeleri ve kruvasanları mükemmel.',
          vibes: ['Üçüncü Nesil Kahve', 'Sessiz Çalışma'],
          warnings: ['Gezgin Saha Uyarısı: Sadece Kart Geçerli (11 oy)'],
          photoUrls: [],
        ),
        RouteStopDetailItem(
          id: 'stop-4',
          orderIndex: 3,
          dayNumber: 4,
          placeName: 'Grand Place & Maison Dandoy',
          city: 'Brüksel',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment:
              'Köln üzerinden hızlı trenle 2 saatte geçtik. Akşam ışıklandırması büyüleyici.',
          vibes: ['Gece Manzarası', 'Yerel Lezzet'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1559113202-c916b8e44373?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Butik Otel',
          regionOrHotelName: 'Mitte Bölgesi, Berlin',
          nightsCount: 3,
        ),
        RouteStayDetailItem(
          stayTypeLabel: 'Merkez Hostel / Apart',
          regionOrHotelName: 'Saint-Géry, Brüksel',
          nightsCount: 2,
        ),
      ],
      questions: [
        RouteQuestionItem(
          id: 'q-1',
          askerUsername: 'selin_yolda',
          questionText:
              'Berlin\'den Brüksel\'e tren biletlerini ne kadar süre önceden aldınız?',
          createdAtLabel: '2 gün önce',
          answerText:
              'Yaklaşık 3 hafta önceden DB Navigator üzerinden aldık, kişi başı 39 Euro\'ya geldi.',
        ),
      ],
    ),
    const PublishedRouteFeedItem(
      id: 'route-it-fr-02',
      title: 'Kuzey İtalya & Güney Fransa: Göller, Bağlar ve Sahil Kasabaları',
      description:
          'Milano\'dan başlayıp Como Gölü, Cinque Terre ve Nice kıyısına uzanan unutulmaz 5 günlük Akdeniz rotası.',
      authorUsername: 'ece_rotada',
      authorDisplayName: 'Ece Yalçın',
      authorRankLabel: 'Master of Routes',
      continent: ContinentFilter.europe,
      countryCodes: ['IT', 'FR'],
      countryNames: ['İtalya', 'Fransa'],
      cities: ['Milano', 'Como', 'Cinque Terre', 'Nice'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1534445867742-43195f401b6c?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1491166617655-0723a0999cfc?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1520175480921-4edfa2983e0f?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Duomo di Milano',
        'Bellagio (Como Gölü)',
        'Villa del Balbianello',
        'Vernazza Seyir Tepesi',
        'Manarola Gün Batımı',
        'Promenade des Anglais',
        'Vieux Nice Pazarı',
      ],
      dateRangeText: '2–6 Haziran 2026',
      adultsCount: 2,
      childrenCount: 1,
      durationDays: 5,
      estimatedBudgetUsd: 1450,
      estimatedBudgetLocal: 50025,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Konaklama': 620,
        'Yeme - İçme': 410,
        'Araç & Tren Ulaşımı': 280,
        'Tekne Turu & Girişler': 140,
      },
      forkCount: 52,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-201',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Bellagio & Villa del Balbianello',
          city: 'Como',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Varenna\'dan feribotla 15 dakikada geçiliyor, manzara eşsiz.',
          vibes: ['Romantik', 'Göl Manzarası', 'Tekne Turu'],
          warnings: [
            'Villa del Balbianello Pazartesi, Çarşamba günleri kapalıdır.',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1534445867742-43195f401b6c?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-202',
          orderIndex: 1,
          dayNumber: 3,
          placeName: 'Vernazza & Manarola Yürüyüş Patikası',
          city: 'Cinque Terre',
          uiCategory: 'DESTINATION',
          verificationType: 'PHOTO_VERIFIED',
          rating: 5,
          comment: 'Gün batımında Manarola kayalıklarında focaccia molası şart.',
          vibes: ['Gün Batımı', 'Doğa Yürüyüşü'],
          warnings: [
            'Gezgin Saha Uyarısı: Dik Tırmanış & Kaygan Zemin (27 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Göl Kenarı Apart',
          regionOrHotelName: 'Varenna, Como',
          nightsCount: 2,
        ),
        RouteStayDetailItem(
          stayTypeLabel: 'Sahil Oteli',
          regionOrHotelName: 'Vieux Nice, Fransa',
          nightsCount: 2,
        ),
      ],
      questions: [],
    ),
    const PublishedRouteFeedItem(
      id: 'route-th-03',
      title: 'Bangkok Tapınakları, Chiang Mai Ormanları & Phuket Koylari',
      description:
          'Sırt çantasıyla Kuzeyden Güneye Tayland! Gece pazarları, Michelin sokak lezzetleri ve gizli koylar.',
      authorUsername: 'mert_asya',
      authorDisplayName: 'Mert Aksoy',
      authorRankLabel: 'Pathfinder',
      continent: ContinentFilter.asia,
      countryCodes: ['TH'],
      countryNames: ['Tayland'],
      cities: ['Bangkok', 'Chiang Mai', 'Phuket'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1508009603885-50cf7c579365?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1528181304800-259b08848526?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1563492065599-3520f775eeed?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1537956965359-7573183d1f57?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Wat Arun Tapınağı',
        'Chinatown Yaowarat',
        'Jay Fai Street Food',
        'Doi Suthep Chiang Mai',
        'Fil Koruma Kampı',
        'Phi Phi Leh Lagünü',
        'Freedom Beach Phuket',
      ],
      dateRangeText: '10–18 Nisan 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 9,
      estimatedBudgetUsd: 890,
      estimatedBudgetLocal: 30705,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Bungalov & Konaklama': 320,
        'Sokak Lezzetleri & Yemek': 230,
        'İç Hat Uçuş & Feribot': 210,
        'Ada Turları': 130,
      },
      forkCount: 41,
      isBoosted: false,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-301',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Wat Arun (Şafak Tapınağı)',
          city: 'Bangkok',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Karşı kıyıdaki teras kafelerden gün batımında izlemek şahane.',
          vibes: ['Tapınak', 'Gün Batımı', 'Kültür'],
          warnings: [
            'Gezgin Saha Uyarısı: Omuz ve Diz Kapalı Kıyafet Zorunlu (38 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1508009603885-50cf7c579365?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Doğa Bungalovu',
          regionOrHotelName: 'Old City, Chiang Mai',
          nightsCount: 4,
        ),
        RouteStayDetailItem(
          stayTypeLabel: 'Sahil Bungalovu',
          regionOrHotelName: 'Kata Noi, Phuket',
          nightsCount: 4,
        ),
      ],
      questions: [],
    ),
    const PublishedRouteFeedItem(
      id: 'route-tr-04',
      title: 'Urla Bağ Yolu, Alaçatı ve Foça: Ege Gastronomi & Koy Rotası',
      description:
          'Hafta sonunu uzatıp 4 günde İzmir yarımadasının en sakin koylarını ve bağ restoranlarını gezdik.',
      authorUsername: 'deniz_ege',
      authorDisplayName: 'Deniz Kaya',
      authorRankLabel: 'Elite Traveler',
      continent: ContinentFilter.europe,
      countryCodes: ['TR'],
      countryNames: ['Türkiye'],
      cities: ['İzmir', 'Urla', 'Çeşme', 'Foça'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Urla Bağ Yolu',
        'Od Urla',
        'Delikli Koy Alaçatı',
        'Alaçatı Taş Evler',
        'Eski Foça Kozbeyli',
        'Siren Kayalıkları',
        'Tarihi Asansör İzmir',
      ],
      dateRangeText: '20–23 Mayıs 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 4,
      estimatedBudgetUsd: 540,
      estimatedBudgetLocal: 18600,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Taş Otel Konaklama': 240,
        'Gastronomi & Tadım': 190,
        'Araç Yakıt': 110,
      },
      forkCount: 63,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-401',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Od Urla & Urla Bağ Yolu',
          city: 'Urla',
          uiCategory: 'FOOD',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Zeytin ağaçları arasında akşam yemeği deneyimi harikaydı.',
          vibes: ['Gastronomi', 'Bağ Evi', 'Romantik'],
          warnings: [
            'Od Urla Pazartesi günleri kapalıdır.',
            'Gezgin Saha Uyarısı: Haftalar Öncesinden Rezervasyon Gerekli (31 oy)',
          ],
          photoUrls: [
            'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Taş Butik Otel',
          regionOrHotelName: 'Alaçatı Hacımemiş, Çeşme',
          nightsCount: 3,
        ),
      ],
      questions: [],
    ),
  ];

  static const Map<String, List<String>> citiesByCountryCode = {
    'TR': [
      'İzmir',
      'Urla',
      'Çeşme',
      'Foça',
      'Muğla',
      'Marmaris',
      'Köyceğiz',
      'Fethiye',
    ],
    'DE': ['Berlin', 'Köln', 'Münih'],
    'IT': ['Como', 'Milano', 'Cinque Terre', 'Roma'],
    'FR': ['Nice', 'Paris', 'Lyon'],
    'BE': ['Brüksel', 'Brugge'],
    'NL': ['Amsterdam', 'Rotterdam'],
    'TH': ['Bangkok', 'Chiang Mai', 'Phuket'],
    'JP': ['Tokyo', 'Kyoto', 'Osaka'],
    'RU': ['Moskova', 'St. Petersburg'],
    'US': ['New York', 'San Francisco', 'Los Angeles'],
    'CA': ['Toronto', 'Vancouver'],
    'BR': ['Rio de Janeiro', 'São Paulo'],
    'AR': ['Buenos Aires', 'Bariloche'],
  };

  List<CountryFilterOption> getCountriesForContinent(
    ContinentFilter continent, {
    String searchQuery = '',
  }) {
    if (continent == ContinentFilter.global) {
      return const [];
    }
    final normalizedQ = searchQuery.trim().toLowerCase();
    final filtered = _allCountries
        .where((c) => c.continent == continent)
        .where((c) {
          if (normalizedQ.isEmpty) return true;
          return c.nameTr.toLowerCase().contains(normalizedQ) ||
              c.code.toLowerCase().contains(normalizedQ);
        })
        .toList();

    // En çok rota olan ülkeler her zaman en üstte
    filtered.sort(
      (a, b) => b.publishedRouteCount.compareTo(a.publishedRouteCount),
    );
    return filtered;
  }

  /// İlgili ülke koduna ait şehir listesini döndürür
  List<String> getCitiesForCountry(String countryCode) {
    return citiesByCountryCode[countryCode] ?? const <String>[];
  }

  /// Hiyerarşik ağaç seçimine (Tam Kıta / Tam Ülke / Tekil Şehir), bütçe aralığına ve arama metnine göre yayınlanmış rotaları süzer
  List<PublishedRouteFeedItem> getFilteredFeedRoutesByHierarchy({
    required Set<ContinentFilter> selectedFullContinents,
    required Set<String> selectedFullCountries,
    required Set<String> selectedCities,
    bool isNearbyPriority = false,
    String searchQuery = '',
    double? minBudgetTl,
    double? maxBudgetTl,
  }) {
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final isGlobalSelected = selectedFullContinents.isEmpty &&
        selectedFullCountries.isEmpty &&
        selectedCities.isEmpty;

    final results = _routes.where((route) {
      // 1. Hiyerarşik Coğrafya Ağacı Filtresi:
      // Yalnızca Anlık Konum KAPALIYKEN ve Global değilken uygulanır.
      if (!isNearbyPriority && !isGlobalSelected) {
        final matchesFullContinent =
            selectedFullContinents.contains(route.continent);
        final matchesFullCountry =
            route.countryCodes.any(selectedFullCountries.contains);
        final matchesSpecificCity = route.cities.any(selectedCities.contains) ||
            route.stops.any((stop) => selectedCities.contains(stop.city));

        if (!matchesFullContinent &&
            !matchesFullCountry &&
            !matchesSpecificCity) {
          return false;
        }
      }

      // 2. Bütçe Aralığı Filtresi (TL)
      if (minBudgetTl != null && route.estimatedBudgetLocal < minBudgetTl) {
        return false;
      }
      if (maxBudgetTl != null && route.estimatedBudgetLocal > maxBudgetTl) {
        return false;
      }

      // 2. Metin Araması (Rota başlığı, açıklama, şehir, ülke veya durak adı)
      if (normalizedQuery.isNotEmpty) {
        final matchesTitle =
            route.title.toLowerCase().contains(normalizedQuery);
        final matchesDesc =
            route.description.toLowerCase().contains(normalizedQuery);
        final matchesCity = route.cities
            .any((c) => c.toLowerCase().contains(normalizedQuery));
        final matchesCountry = route.countryNames
            .any((c) => c.toLowerCase().contains(normalizedQuery));
        final matchesPlace = route.previewPlaceNames
                .any((p) => p.toLowerCase().contains(normalizedQuery)) ||
            route.stops.any(
              (s) => s.placeName.toLowerCase().contains(normalizedQuery),
            );

        if (!matchesTitle &&
            !matchesDesc &&
            !matchesCity &&
            !matchesCountry &&
            !matchesPlace) {
          return false;
        }
      }

      return true;
    }).toList();

    // Anlık Konum (Konak / İzmir / Türkiye) aktifse İzmir ve Ege rotalarını en öne sırala
    if (isNearbyPriority) {
      results.sort((a, b) {
        int score(PublishedRouteFeedItem r) {
          if (r.cities.contains('İzmir') || r.cities.contains('Urla')) return 0;
          if (r.countryCodes.contains('TR')) return 1;
          return 2;
        }

        return score(a).compareTo(score(b));
      });
    }

    return results;
  }

  static const List<PublishedRouteFeedItem> _extraBatchRoutes = [
    PublishedRouteFeedItem(
      id: 'route-tr-kapadokya-05',
      title: 'Kapadokya Vadileri, Uçhisar & Gündoğumu Balon Rotası',
      description:
          'Göreme Açık Hava Müzesi\'nden Kızılçukur gün batımına ve Uçhisar Kalesi\'ne uzanan 4 günlük masalsı Kapadokya rotası.',
      authorUsername: 'zeynep_kesifte',
      authorDisplayName: 'Zeynep Arslan',
      authorRankLabel: 'Master of Routes',
      continent: ContinentFilter.europe,
      countryCodes: ['TR'],
      countryNames: ['Türkiye'],
      cities: ['Nevşehir', 'Ürgüp', 'Göreme', 'Uçhisar'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1570939274717-7eda259b50ed?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1527838832700-5059252407fa?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Göreme Açık Hava Müzesi',
        'Uçhisar Kalesi',
        'Kızılçukur Vadisi',
        'Paşabağ Rahipler Vadisi',
        'Aşk Vadisi Seyir Terası',
      ],
      dateRangeText: '5–8 Ekim 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 4,
      estimatedBudgetUsd: 620,
      estimatedBudgetLocal: 21390,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Mağara Otel Konaklama': 320,
        'Yeme - İçme & Testi Kebabı': 180,
        'Müze & Vadi Turları': 120,
      },
      forkCount: 88,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-k1',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Uçhisar Kalesi',
          city: 'Nevşehir',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Tüm Kapadokya vadilerini kuşbakışı gören en yüksek zirve.',
          vibes: ['Panoramik Manzara', 'Gün Batımı', 'Tarihi Kale'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1641128324972-af3212f0f6bd?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-k2',
          orderIndex: 1,
          dayNumber: 2,
          placeName: 'Kızılçukur Vadisi',
          city: 'Ürgüp',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Gün batımında kayaların kızıl renge dönüşümü büyüleyici.',
          vibes: ['Doğa Yürüyüşü', 'Fotoğraf Noktası'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1570939274717-7eda259b50ed?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Kaya Mağara Otel',
          regionOrHotelName: 'Göreme Merkez, Nevşehir',
          nightsCount: 3,
        ),
      ],
      questions: [],
    ),
    PublishedRouteFeedItem(
      id: 'route-nl-be-06',
      title: 'Amsterdam Kanalları, Zaanse Schans & Brugge Ortaçağ Rotası',
      description:
          'Bisiklet yolları, yel değirmenleri ve Brugge\'ün masalsı kanalları arasında 5 günlük Kuzey Avrupa keşfi.',
      authorUsername: 'emre_avrupa',
      authorDisplayName: 'Emre Yıldız',
      authorRankLabel: 'Elite Traveler',
      continent: ContinentFilter.europe,
      countryCodes: ['NL', 'BE'],
      countryNames: ['Hollanda', 'Belçika'],
      cities: ['Amsterdam', 'Rotterdam', 'Brugge'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1512470876302-972faa2aa9a4?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1559113202-c916b8e44373?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Jordaan Kanal Bölgesi',
        'Rijksmuseum',
        'Zaanse Schans Yel Değirmenleri',
        'Brugge Markt Meydanı',
        'Rozenhoedkaai Kanalı',
      ],
      dateRangeText: '18–22 Ağustos 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 5,
      estimatedBudgetUsd: 1320,
      estimatedBudgetLocal: 45540,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Kanal Evi Otel': 590,
        'Yeme - İçme': 380,
        'Tren & Bisiklet': 350,
      },
      forkCount: 49,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-n1',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Jordaan Kanal Bölgesi',
          city: 'Amsterdam',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Sabah kahvesi ve kanal kenarı yürüyüşü için en huzurlu semt.',
          vibes: ['Kanal Manzarası', 'Bisiklet', 'Fotojenik'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?auto=format&fit=crop&w=900&q=80',
          ],
        ),
        RouteStopDetailItem(
          id: 'stop-n2',
          orderIndex: 1,
          dayNumber: 4,
          placeName: 'Rozenhoedkaai Kanalı',
          city: 'Brugge',
          uiCategory: 'DESTINATION',
          verificationType: 'PHOTO_VERIFIED',
          rating: 5,
          comment: 'Brugge\'ün kartpostallardaki en ikonik yansıma noktası.',
          vibes: ['Ortaçağ', 'Gece Işıkları'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1559113202-c916b8e44373?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Butik Kanal Oteli',
          regionOrHotelName: 'Centrum, Amsterdam',
          nightsCount: 3,
        ),
      ],
      questions: [],
    ),
    PublishedRouteFeedItem(
      id: 'route-jp-07',
      title: 'Tokyo, Kyoto & Osaka: Tapınaklar, Bambu Ormanı ve Sokak Lezzetleri',
      description:
          'Shinkansen ile Tokyo\'nun neon ışıklı caddelerinden Kyoto\'nun Fushimi Inari tapınaklarına ve Dotonbori mutfağına.',
      authorUsername: 'can_uzakdogu',
      authorDisplayName: 'Can Özkan',
      authorRankLabel: 'Master of Routes',
      continent: ContinentFilter.asia,
      countryCodes: ['JP'],
      countryNames: ['Japonya'],
      cities: ['Tokyo', 'Kyoto', 'Osaka'],
      featuredMediaUrls: [
        'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1545569341-9eb8b30979d9?auto=format&fit=crop&w=900&q=80',
      ],
      previewPlaceNames: [
        'Fushimi Inari Taisha',
        'Arashiyama Bambu Ormanı',
        'Shibuya Crossing',
        'Senso-ji Tapınağı',
        'Dotonbori Osaka',
      ],
      dateRangeText: '1–8 Kasım 2026',
      adultsCount: 2,
      childrenCount: 0,
      durationDays: 8,
      estimatedBudgetUsd: 1850,
      estimatedBudgetLocal: 63825,
      localCurrencySymbol: '₺',
      budgetBreakdown: {
        'Ryokan & Otel': 780,
        'JR Pass & Ulaşım': 540,
        'Ramen & Sushi Durakları': 530,
      },
      forkCount: 95,
      isBoosted: true,
      isQaEnabled: true,
      stops: [
        RouteStopDetailItem(
          id: 'stop-j1',
          orderIndex: 0,
          dayNumber: 1,
          placeName: 'Fushimi Inari Taisha',
          city: 'Kyoto',
          uiCategory: 'DESTINATION',
          verificationType: 'GEO_VERIFIED',
          rating: 5,
          comment: 'Binlerce kızıl Torii kapısından sabah 06:30\'da geçmek eşsiz.',
          vibes: ['Tapınak', 'Sabah Yürüyüşü', 'Kültür'],
          warnings: [],
          photoUrls: [
            'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=900&q=80',
          ],
        ),
      ],
      stays: [
        RouteStayDetailItem(
          stayTypeLabel: 'Geleneksel Ryokan',
          regionOrHotelName: 'Gion, Kyoto',
          nightsCount: 3,
        ),
      ],
      questions: [],
    ),
  ];

  /// Kullanıcı en altta knob'u %100 doldurduğunda yüklenecek yeni rota paketini döndürür
  List<PublishedRouteFeedItem> getNextBatchRoutes({
    required int batchIndex,
    required List<PublishedRouteFeedItem> baseFilteredRoutes,
  }) {
    final source = batchIndex == 1 && _extraBatchRoutes.isNotEmpty
        ? _extraBatchRoutes
        : (baseFilteredRoutes.isNotEmpty ? baseFilteredRoutes : _routes);

    return source
        .map(
          (r) => PublishedRouteFeedItem(
            id: '${r.id}-batch-$batchIndex',
            title: r.title,
            description: r.description,
            authorUsername: r.authorUsername,
            authorDisplayName: r.authorDisplayName,
            authorRankLabel: r.authorRankLabel,
            continent: r.continent,
            countryCodes: r.countryCodes,
            countryNames: r.countryNames,
            cities: r.cities,
            featuredMediaUrls: r.featuredMediaUrls,
            previewPlaceNames: r.previewPlaceNames,
            dateRangeText: r.dateRangeText,
            adultsCount: r.adultsCount,
            childrenCount: r.childrenCount,
            durationDays: r.durationDays,
            estimatedBudgetUsd: r.estimatedBudgetUsd,
            estimatedBudgetLocal: r.estimatedBudgetLocal,
            localCurrencySymbol: r.localCurrencySymbol,
            budgetBreakdown: r.budgetBreakdown,
            forkCount: r.forkCount,
            isBoosted: r.isBoosted,
            isQaEnabled: r.isQaEnabled,
            stops: r.stops,
            stays: r.stays,
            questions: r.questions,
          ),
        )
        .toList();
  }

  List<PublishedRouteFeedItem> getFilteredFeedRoutes({
    required ContinentFilter continent,
    required Set<String> selectedCountryCodes,
  }) {
    return _routes.where((route) {
      if (continent == ContinentFilter.global) {
        return true;
      }
      if (route.continent != continent) {
        return false;
      }
      if (selectedCountryCodes.isEmpty) {
        // "Tümü" seçili demektir
        return true;
      }
      // Anasayfa'da çoklu ülke seçimi (OR kesişimi): Seçilen ülkelerden herhangi birini içeren rotalar
      return route.countryCodes.any(selectedCountryCodes.contains);
    }).toList();
  }

  // ===========================================================================
  // YENİ ROTALAR ARAMA PANELİ: KITALAR, ALT BÖLGELER, ÖNERİLER & HAP FİLTRELEME
  // ===========================================================================

  static const List<RouteContinentCatalogItem> continentsCatalog = [
    RouteContinentCatalogItem(
      continent: ContinentFilter.europe,
      name: 'Avrupa',
      imageUrl:
          'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?auto=format&fit=crop&w=700&q=80',
      regions: [
        RouteRegionCatalogItem(
          id: 'western_europe',
          name: 'Batı Avrupa',
          continent: ContinentFilter.europe,
          countryCodes: ['DE', 'FR', 'BE', 'NL'],
          countryTags: ['Almanya', 'Fransa', 'Belçika', 'Hollanda'],
          imageUrl:
              'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'southern_europe_med',
          name: 'Güney Avrupa & Akdeniz',
          continent: ContinentFilter.europe,
          countryCodes: ['IT', 'TR'],
          countryTags: ['İtalya', 'Türkiye'],
          imageUrl:
              'https://images.unsplash.com/photo-1516483638261-f4dbaf036963?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'turkey_aegean',
          name: 'Türkiye & Ege',
          continent: ContinentFilter.europe,
          countryCodes: ['TR'],
          countryTags: ['Türkiye'],
          imageUrl:
              'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?auto=format&fit=crop&w=700&q=80',
        ),
      ],
    ),
    RouteContinentCatalogItem(
      continent: ContinentFilter.asia,
      name: 'Asya',
      imageUrl:
          'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=700&q=80',
      regions: [
        RouteRegionCatalogItem(
          id: 'east_asia',
          name: 'Doğu Asya',
          continent: ContinentFilter.asia,
          countryCodes: ['JP'],
          countryTags: ['Japonya'],
          imageUrl:
              'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'southeast_asia',
          name: 'Güneydoğu Asya',
          continent: ContinentFilter.asia,
          countryCodes: ['TH'],
          countryTags: ['Tayland'],
          imageUrl:
              'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'north_asia',
          name: 'Kuzey Asya',
          continent: ContinentFilter.asia,
          countryCodes: ['RU'],
          countryTags: ['Rusya'],
          imageUrl:
              'https://images.unsplash.com/photo-1513326738677-b964603b136d?auto=format&fit=crop&w=700&q=80',
        ),
      ],
    ),
    RouteContinentCatalogItem(
      continent: ContinentFilter.northAmerica,
      name: 'Kuzey Amerika',
      imageUrl:
          'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=700&q=80',
      regions: [
        RouteRegionCatalogItem(
          id: 'north_america_east',
          name: 'Kuzey Amerika Doğu',
          continent: ContinentFilter.northAmerica,
          countryCodes: ['US', 'CA'],
          countryTags: ['ABD', 'Kanada'],
          imageUrl:
              'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'north_america_west',
          name: 'Kuzey Amerika Batı',
          continent: ContinentFilter.northAmerica,
          countryCodes: ['US', 'CA'],
          countryTags: ['ABD', 'Kanada'],
          imageUrl:
              'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?auto=format&fit=crop&w=700&q=80',
        ),
      ],
    ),
    RouteContinentCatalogItem(
      continent: ContinentFilter.southAmerica,
      name: 'Güney Amerika',
      imageUrl:
          'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&w=700&q=80',
      regions: [
        RouteRegionCatalogItem(
          id: 'south_america_atlantic',
          name: 'Güney Amerika Atlantik',
          continent: ContinentFilter.southAmerica,
          countryCodes: ['BR'],
          countryTags: ['Brezilya'],
          imageUrl:
              'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&w=700&q=80',
        ),
        RouteRegionCatalogItem(
          id: 'andes_patagonia',
          name: 'Andlar & Patagonya',
          continent: ContinentFilter.southAmerica,
          countryCodes: ['AR'],
          countryTags: ['Arjantin'],
          imageUrl:
              'https://images.unsplash.com/photo-1518509562904-e7ef99cdcc86?auto=format&fit=crop&w=700&q=80',
        ),
      ],
    ),
  ];

  static const Map<String, ({String nameTr, String continentName, List<String> cities})>
      _popularExtraCatalog = {
    'ES': (
      nameTr: 'İspanya',
      continentName: 'Avrupa',
      cities: ['Madrid', 'Barselona', 'Sevilla', 'Cadiz'],
    ),
  };

  static String _normalizeTr(String input) {
    return input
        .trim()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }

  static String _continentDisplayName(ContinentFilter continent) {
    switch (continent) {
      case ContinentFilter.global:
        return 'Global';
      case ContinentFilter.europe:
        return 'Avrupa';
      case ContinentFilter.asia:
        return 'Asya';
      case ContinentFilter.northAmerica:
        return 'Kuzey Amerika';
      case ContinentFilter.southAmerica:
        return 'Güney Amerika';
      case ContinentFilter.africa:
        return 'Afrika';
      case ContinentFilter.oceania:
        return 'Okyanusya';
    }
  }

  RouteRegionCatalogItem? _findRegionById(String? regionId) {
    if (regionId == null) return null;
    for (final continent in continentsCatalog) {
      for (final region in continent.regions) {
        if (region.id == regionId) return region;
      }
    }
    return null;
  }

  int countRoutesForContinent(ContinentFilter continent) {
    return _routes.where((r) => r.continent == continent).length;
  }

  int countRoutesForRegion(RouteRegionCatalogItem region) {
    return _routes
        .where((r) => r.countryCodes.any(region.countryCodes.contains))
        .length;
  }

  bool _routeMatchesKeyword(PublishedRouteFeedItem route, String keyword) {
    final normalizedQuery = _normalizeTr(keyword);
    if (normalizedQuery.isEmpty) return true;

    final matchesTitle = _normalizeTr(route.title).contains(normalizedQuery);
    final matchesDesc =
        _normalizeTr(route.description).contains(normalizedQuery);
    final matchesCity =
        route.cities.any((c) => _normalizeTr(c).contains(normalizedQuery));
    final matchesCountry = route.countryNames
        .any((c) => _normalizeTr(c).contains(normalizedQuery));
    final matchesPlace = route.previewPlaceNames
            .any((p) => _normalizeTr(p).contains(normalizedQuery)) ||
        route.stops.any(
          (s) =>
              _normalizeTr(s.placeName).contains(normalizedQuery) ||
              _normalizeTr(s.city).contains(normalizedQuery),
        );

    return matchesTitle ||
        matchesDesc ||
        matchesCity ||
        matchesCountry ||
        matchesPlace;
  }

  bool _routeMatchesLocationPill(
    PublishedRouteFeedItem route,
    RouteFeedFilterPill pill,
  ) {
    switch (pill.type) {
      case RouteFilterPillType.continent:
        return pill.continent != null && route.continent == pill.continent;
      case RouteFilterPillType.region:
        final region = _findRegionById(pill.regionId);
        if (region == null) return false;
        return route.countryCodes.any(region.countryCodes.contains);
      case RouteFilterPillType.country:
        return pill.countryCode != null &&
            route.countryCodes.contains(pill.countryCode);
      case RouteFilterPillType.city:
        final target = _normalizeTr(pill.cityName ?? '');
        if (target.isEmpty) return false;
        return route.cities.any((c) => _normalizeTr(c) == target) ||
            route.stops.any((s) => _normalizeTr(s.city) == target);
      case RouteFilterPillType.keyword:
        return true;
    }
  }

  /// Aktif (isEnabled == true) filtre haplarına ve bütçe aralığına göre rotaları süzer.
  /// Konum hapları kendi aralarında OR birleşimi, kelime hapları ve bütçe ile AND kesişimi uygular.
  List<PublishedRouteFeedItem> getFilteredFeedRoutesByPills({
    required List<RouteFeedFilterPill> activePills,
    double? minBudgetTl,
    double? maxBudgetTl,
  }) {
    final enabledPills = activePills.where((p) => p.isEnabled).toList();
    final locationPills = enabledPills
        .where((p) => p.type != RouteFilterPillType.keyword)
        .toList();
    final keywordPills = enabledPills
        .where((p) => p.type == RouteFilterPillType.keyword)
        .toList();

    return _routes.where((route) {
      if (locationPills.isNotEmpty) {
        final matchesAnyLocation = locationPills.any(
          (pill) => _routeMatchesLocationPill(route, pill),
        );
        if (!matchesAnyLocation) return false;
      }

      if (keywordPills.isNotEmpty) {
        final matchesAllKeywords = keywordPills.every(
          (pill) => _routeMatchesKeyword(route, pill.keyword ?? pill.label),
        );
        if (!matchesAllKeywords) return false;
      }

      if (minBudgetTl != null && route.estimatedBudgetLocal < minBudgetTl) {
        return false;
      }
      if (maxBudgetTl != null && route.estimatedBudgetLocal > maxBudgetTl) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Arama panelindeki "Arama Sonuçları" kutusu için dinamik öneriler üretir.
  List<RouteSearchSuggestion> buildSearchSuggestions(String query) {
    final trimmed = query.trim();
    final q = _normalizeTr(trimmed);

    if (q.isEmpty) {
      return [
        const RouteSearchSuggestion(
          id: 'popular:city:marmaris',
          type: RouteSearchSuggestionType.city,
          title: 'Marmaris',
          subtitle: 'Avrupa - Türkiye',
          pill: RouteFeedFilterPill(
            id: 'city:marmaris',
            type: RouteFilterPillType.city,
            label: 'Marmaris',
            cityName: 'Marmaris',
            countryCode: 'TR',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:city:roma',
          type: RouteSearchSuggestionType.city,
          title: 'Roma',
          subtitle: 'Avrupa - İtalya',
          pill: RouteFeedFilterPill(
            id: 'city:roma',
            type: RouteFilterPillType.city,
            label: 'Roma',
            cityName: 'Roma',
            countryCode: 'IT',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:city:madrid',
          type: RouteSearchSuggestionType.city,
          title: 'Madrid',
          subtitle: 'Avrupa - İspanya',
          pill: RouteFeedFilterPill(
            id: 'city:madrid',
            type: RouteFilterPillType.city,
            label: 'Madrid',
            cityName: 'Madrid',
            countryCode: 'ES',
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:region:western_europe',
          type: RouteSearchSuggestionType.region,
          title: 'Batı Avrupa',
          subtitle: 'Avrupa - Bölge',
          pill: RouteFeedFilterPill(
            id: 'region:western_europe',
            type: RouteFilterPillType.region,
            label: 'Batı Avrupa',
            regionId: 'western_europe',
            continent: ContinentFilter.europe,
          ),
        ),
        const RouteSearchSuggestion(
          id: 'popular:continent:EUROPE',
          type: RouteSearchSuggestionType.continent,
          title: 'Avrupa',
          subtitle: 'Kıta',
          pill: RouteFeedFilterPill(
            id: 'continent:EUROPE',
            type: RouteFilterPillType.continent,
            label: 'Avrupa',
            continent: ContinentFilter.europe,
          ),
        ),
      ];
    }

    final suggestions = <RouteSearchSuggestion>[
      RouteSearchSuggestion(
        id: 'keyword:$q',
        type: RouteSearchSuggestionType.keyword,
        title: '$trimmed ile arama yap',
        subtitle: '(kelime ile arama)',
        pill: RouteFeedFilterPill(
          id: 'keyword:$q',
          type: RouteFilterPillType.keyword,
          label: '"$trimmed"',
          keyword: trimmed,
        ),
      ),
    ];

    final seenCityIds = <String>{};

    // 1. Repository şehirleri (ülkelere göre)
    for (final country in _allCountries) {
      final continentName = _continentDisplayName(country.continent);
      final cities = citiesByCountryCode[country.code] ?? const <String>[];
      for (final city in cities) {
        final normCity = _normalizeTr(city);
        if (normCity.contains(q) && seenCityIds.add(normCity)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'city:$normCity',
              type: RouteSearchSuggestionType.city,
              title: city,
              subtitle: '$continentName - ${country.nameTr}',
              pill: RouteFeedFilterPill(
                id: 'city:$normCity',
                type: RouteFilterPillType.city,
                label: city,
                cityName: city,
                countryCode: country.code,
              ),
            ),
          );
        }
      }
    }

    // 2. Popüler katalog şehirleri (örn: Madrid / İspanya)
    for (final entry in _popularExtraCatalog.entries) {
      for (final city in entry.value.cities) {
        final normCity = _normalizeTr(city);
        if (normCity.contains(q) && seenCityIds.add(normCity)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'city:$normCity',
              type: RouteSearchSuggestionType.city,
              title: city,
              subtitle: '${entry.value.continentName} - ${entry.value.nameTr}',
              pill: RouteFeedFilterPill(
                id: 'city:$normCity',
                type: RouteFilterPillType.city,
                label: city,
                cityName: city,
                countryCode: entry.key,
              ),
            ),
          );
        }
      }
    }

    // 3. Eşleşen ülkeler
    for (final country in _allCountries) {
      if (_normalizeTr(country.nameTr).contains(q) ||
          _normalizeTr(country.code) == q) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'country:${country.code}',
            type: RouteSearchSuggestionType.country,
            title: country.nameTr,
            subtitle: '${_continentDisplayName(country.continent)} - Ülke',
            pill: RouteFeedFilterPill(
              id: 'country:${country.code}',
              type: RouteFilterPillType.country,
              label: country.nameTr,
              countryCode: country.code,
            ),
          ),
        );
      }
    }
    for (final entry in _popularExtraCatalog.entries) {
      if (_normalizeTr(entry.value.nameTr).contains(q) ||
          _normalizeTr(entry.key) == q) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'country:${entry.key}',
            type: RouteSearchSuggestionType.country,
            title: entry.value.nameTr,
            subtitle: '${entry.value.continentName} - Ülke',
            pill: RouteFeedFilterPill(
              id: 'country:${entry.key}',
              type: RouteFilterPillType.country,
              label: entry.value.nameTr,
              countryCode: entry.key,
            ),
          ),
        );
      }
    }

    // 4. Eşleşen alt bölgeler ve kıtalar
    for (final continent in continentsCatalog) {
      for (final region in continent.regions) {
        if (_normalizeTr(region.name).contains(q)) {
          suggestions.add(
            RouteSearchSuggestion(
              id: 'region:${region.id}',
              type: RouteSearchSuggestionType.region,
              title: region.name,
              subtitle: '${continent.name} - Bölge',
              pill: RouteFeedFilterPill(
                id: 'region:${region.id}',
                type: RouteFilterPillType.region,
                label: region.name,
                regionId: region.id,
                continent: continent.continent,
              ),
            ),
          );
        }
      }
      if (_normalizeTr(continent.name).contains(q)) {
        suggestions.add(
          RouteSearchSuggestion(
            id: 'continent:${continent.continent.code}',
            type: RouteSearchSuggestionType.continent,
            title: continent.name,
            subtitle: 'Kıta',
            pill: RouteFeedFilterPill(
              id: 'continent:${continent.continent.code}',
              type: RouteFilterPillType.continent,
              label: continent.name,
              continent: continent.continent,
            ),
          ),
        );
      }
    }

    return suggestions;
  }
}
