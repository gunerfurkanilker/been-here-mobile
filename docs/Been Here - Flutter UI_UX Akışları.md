# **Been Here - Flutter UI/UX Akışları** 

Bu doküman, Been Here uygulamasının son kullanıcı (mobil) tarafındaki arayüz, navigasyon mimarisi ve kullanıcı deneyimi akışlarını detaylandırmaktadır. Ekran geçişleri ve etkileşim kurguları bu adımlara göre tasarlanacaktır. 

---

## **0. Sabit Alt Navigasyon Barı (Bottom Navigation Bar) ve Anasayfa (`PUBLISHED` Rotalar Akışı)**

### **0.1. Simetrik 5'li Alt Navigasyon Barı (Bottom Navigation)**
Ekranın alt kısmında yer alan sabit navigasyon barı, ortasında dikkat çekici ana aksiyon butonu bulunan **2 Sol – 1 Merkez (FAB) – 2 Sağ** simetrik dizilimine sahiptir:

1. **En Sol — 🏠 Anasayfa (Home Feed):** Instagram benzeri ev ikonu. Toplulukla paylaşılmış (`PUBLISHED`) rotaların aktığı ana vitrin ekranına yönlendirir.
2. **Sol-Orta — 🏆 Ligler (Leaderboards):** Kupa/Madalya ikonu. Rekabeti ve gamification motivasyonunu canlı tutmak için sezonluk, aylık ve bölgesel liderlik tablolarına doğrudan erişim sağlar.
3. **Tam Orta (Büyük & Canlı Merkez Buton) — 🧭 Pusula / Dünya (Rota Oluşturma):**
   - Diğer ikonlara kıyasla daha büyük, dışa taşan (`Center Docked FAB`) ve göze çarpan merkez butondur.
   - Hafifçe dönen bir Dünya veya telefonun hareketine/kaydırmaya göre kuzey ibresi tatlı bir yaylanma (`spring physics`) ile tepki veren **Pusula** ikonuna sahiptir.
   - Tıklandığında kullanıcıyı doğrudan **Rota Oluşturma Akışına** yönlendirir.
4. **Sağ-Orta — 🔍 Arama (Mekan Odaklı Keşif & Arama):** Büyüteç ikonu. Tamamen **Mekan (Place)** odaklı çalışan, açılışta kullanıcının geçmiş tercihlerine göre harmanlanmış sonsuz kaydırmalı (Infinite Scroll) mekan vitrinini sunan, sahibinden.com tarzı hızlı **🚩 Flag'leme** yapılabilen ve mekan kartı içindeki sekme/çekmeceden o mekanın ilintili olduğu rotalara ulaşılabilen ekrana yönlendirir.
5. **En Sağ — 👤 Profil & Rotalarım:** Kullanıcı/Rota ikonu. Kullanıcının kendi paylaştığı (`PUBLISHED`), taslak olarak tuttuğu (`DRAFT`), kişiye özel anı olarak sakladığı (`PRIVATE_MEMORY`) rotalara ve kendi **Flag'li (Bayraklı) Mekan Listelerine** yönlendirir.

---

### **0.2. Anasayfa (`PUBLISHED` Rotalar) Kıta > Ülke Kategorizasyonu ve Kart Tasarımı**

#### **A. Üst Kıta > Ülke Kategorizasyonu (Çoklu Ülke Seçimi + En Çok Rota Olan Ülkeler Üstte)**
Anasayfa akışının en üstünde, kullanıcının ilgilendiği coğrafyaya göre rotaları süzebileceği iki kademeli bir yapı (`GET /gamification/geography-tree` & `GET /routes/discovery-deck`) yer alır:
- **1. Global**
- **2. Avrupa** (`2.1 Tümü`, `2.2 Almanya`, `2.3 Fransa`, `2.4 Belçika`, `2.5 İtalya` ...)
- **3. Asya** (`3.1 Tümü`, `3.2 Rusya`, `3.3 Tayland`, `3.4 Japonya` ...)
- **4. Kuzey Amerika** (`4.1 Tümü` ...)
- **5. Güney Amerika** (`5.1 Tümü` ...)
- **6. Afrika / Okyanusya** (`Tümü` ...)
- **Sıralama, Arama ve Çoklu Seçim Kuralı (Anasayfa'ya Özel):**
  - Kıta altındaki ülkeler listelenirken **en çok yayınlanmış rota (`route_count`) bulunan ülkeler en üstte** gösterilir ve hızlıca ülke araması (`q`) yapılabilir.
  - **Anasayfa akışında ülke filtresi çoktan seçmeli (`countries="Almanya,Fransa,Belçika"`)** olarak çalışır; kullanıcı aynı anda birden fazla ülkenin rotalarını akışta birlikte inceleyebilir.

#### **B. Anasayfa Rota Kartı Tasarımı**
Anasayfa akışında listelenen her bir `PUBLISHED` rota kartı şu görsel ve bilgi hiyerarşisine sahiptir:

1. **Kartın En Üstünde Ayrı Gezgin Başlık Alanı (Card Header):**
   - Görselin üzerine bindirme yapılmaksızın, kartın en tepesinde gezginin profili ayrı bir satır olarak yer alır:
     - Gezgin Avatarı (`Icons.hiking_rounded` / profil görseli)
     - Gezgin Adı Soyadı + `@kullanıcıadı`
     - Gezgin Rütbe Rozeti (Örn: `Master of Routes`, `Elite Traveler`) ve rotanın geçtiği şehirler
     - Sağ üstte rota ülkesi rozeti
2. **Öncelikli Geniş Görsel Alanı (Maksimum 5 Fotoğraflı Temiz Slider):**
   - Kullanıcıyı ilk bakışta cezbeden ana unsur görsellerdir. Görselin üzerinde dikkat dağıtıcı `1 / 5` gibi fotoğraf sayaçları bulunmaz.
   - Maksimum 5 görsel geniş bir alanda (`PageView`) yatay kaydırılabilir. Sadece alt ortada hangi fotoğrafta olunduğunu hissettiren zarif nokta göstergeler (Dots) yer alır.
3. **Kart Yüzeyinde İlk Bakışta Sadeleştirilmiş Alt Alan (Sadece Başlık + Sağa Kayan Konum Etiketleri):**
   - **Rota Başlığı (`title`):** Görselin hemen altında kalın ve vurucu tipografi ile yer alır (Örn: *"Marmaris Turu"*).
   - **Sağa Doğru Yatay Kayan Konum Etiketleri (`preview_place_names`):** Başlığın hemen altında tek satırda sağa doğru kaydırılabilir (`ListView.horizontal`) şekilde mekan adları dizilir (Örn: `📍 Amintas Kaya Mezarları` → `📍 Yuvarlakçay` → `📍 Sakar Seyir Noktası` ...).
4. **Alternatif 1: Hero Animasyonlu Tam Ekran Rota Detay Sayfası (`Hero` + `SliverAppBar`):**
   - Kullanıcı karta veya kapak görseline dokunduğunda, görsel akıcı bir animasyonla (`Hero(tag: 'route-hero-image-...')`) tam ekrana genişler.
   - Sayfanın üstünde kaydırdıkça küçülen parallax kapak görseli (`SliverAppBar`), yarı şeffaf geri butonu (`Icons.arrow_back_ios_new_rounded`), kaydet (`bookmark`) ve paylaş (`ios_share`) butonları yer alır.
   - Sayfa gövdesinde sıkışma olmaksızın:
     - Gezgin profil satırı ve "Profil" butonu
     - Rota başlığı, açıklaması ve seyahat özet rozetleri (Tarih, Süre, Kişi, Çift Dövizli Bütçe, Fork Sayısı)
     - Gün-gün duraklar (`RouteStopDetailItem`), Geo/Photo-verified rozetleri, gezgin notları ve saha uyarıları
     - Konaklama noktaları (`RouteStayDetailItem`)
     - Yuvarlak bütçe kalemleri dağılımı
     - Gezgin Soru & Cevap (Q&A) alanı (klavye açıldığında taşma yapmayan ferah metin girişi ve soru listesi)
   - iOS'ta sol kenardan sağa kaydırarak (`Swipe-to-pop`) veya üstteki geri butonuyla anında anasayfaya dönülür.

---

## **1. İlk Karşılama, İlgi Alanı Seçimi ve İzinler (Onboarding & Permissions)** 

- **Ziyaretçi Modu (Read-Only):** Kullanıcı uygulamayı ilk açtığında zorunlu bir "Kayıt Ol" ekranıyla karşılaşmaz. İçerikleri ve Keşif Destesi'ni doğrudan inceleyebileceği ana ekrana yönlendirilir. 

- **İlgi Alanı Seçimi:** Daha kişiselleştirilmiş bir deneyim sunmak için kullanıcıya (Tarih, Doğa, Yerel Lezzet, Kamp vb.) filtre etiketleri sunulur. Seçilen bu etiketler, uygulamanın öncelikli olarak önereceği mekan algoritmasını besler. 

- **Konum ve Bildirim İzinleri:** KVKK/GDPR standartlarına uygun bir izin penceresi (Opt-In Modal) çıkarılır. Kullanıcı onay verirse, cihaz seviyesinde arka plan konum takibi ve sanal çit (Geofence) mekanizması aktifleşir. Reddedilirse uygulama pasif (manuel) modda çalışmaya devam eder. 

## **2. 🔍 Mekan Odaklı Arama, Keşif Akışı ve Sahibinden Tarzı Flag'leme (Search & Place Discovery)** 

Alt navigasyon barında merkezdeki Pusula butonunun hemen sağında yer alan **🔍 Arama** ekranı, Anasayfa'nın rota odaklı yapısını tamamlayacak şekilde tamamen **Mekan (Place) Odaklı** bir konsepte sahiptir:

### **2.1. İlk Açılış Vitrini: Tercih Öncelikli + Rastgele Infinite Scroll ve %80 / %20 Kart Görünümü**
- **Tercih Öncelikli Harmanlama (`GET /places/feed`):** Ekran ilk açıldığında (kullanıcı henüz arama yapmadan önce) aşağıya doğru **Infinite Scroll (Sonsuz Kaydırma)** şeklinde mekanlar listelenir. Bu akışta kullanıcının daha önce tercih ettiği (rotalarına eklediği veya flag'lediği) mekan kategorileri (`ui_category`) önceliklendirilir ve keşif hissini korumak için rastgele mekanlarla harmanlanır.
- **%80 / %20 Kart Yüksekliği Oranı:** Mekanlar **alt alta tekli yatay/geniş kartlar** halinde dizilir; ekranda aktif mekan kartı alanın yaklaşık **%80'ini** kaplarken, hemen altındaki sıradaki mekan kartının üst kısmı (**~%20**) ucundan görünür şekilde konumlanır ve kullanıcıyı aşağı kaydırmaya teşvik eder.

### **2.2. İki Ayrı Arama Modu ve Google Places API Fallback (Min. 3-4 Karakter Kuralı)**
- **Arama Girişi ve 2 Ayrı Aksiyon Butonu (`GET /places/search`):**
  - Kullanıcı arama metnini girer (veya filtrelerle birlikte boş bırakır) ve kendisine **iki ayrı buton** olarak sunulan arama seçeneklerinden birini tetikler:
    1. **`📍 Yakınımdaki Konumları Göster` (`search_mode = NEARBY`):** Kullanıcının anlık konumunu merkez alarak yarıçap (`ST_DWithin`) içindeki mekanları listeler.
    2. **`🌍 Konum Bağımsız Genel Arama` (`search_mode = GLOBAL`):** Cihaz konumundan bağımsız olarak tüm yerel PostgreSQL/PostGIS veritabanında genel arama yapar.
- **Google Haritalar Tetikleyicisi (`POST /places/fetch-google`):**
  - Arama sonucunda kullanıcı aradığı mekanı listede bulamadıysa veya hiç sonuç dönmediyse listenin altında **"Aradığınız mekanı bulamadınız mı? Google Haritalar'da Ara"** butonu/metni gösterilir.
  - **Minimum Karakter Kuralı:** Kullanıcının sadece `"A"` gibi tek bir harfe basıp Google Places API'den binlerce alakasız mekan çekmesini önlemek için en az **3-4 harften oluşan** bir arama metni girmiş olması zorunludur (`@MinLength(3)`). Eşleşen mekanlar Google Places API'den çekildiği anda çoklu dil (`JSONB`) desteğiyle doğrudan veritabanına kaydedilir (Upsert).

### **2.3. Sahibinden.com Tarzı Hızlı Flag'leme ve Mekanın İlintili Olduğu Rotalar**
- **Sahibinden.com Tarzı Favori Listesine Ekleme (Flag'leme):**
  - Her mekan kartının üzerinde kolayca erişilebilen bir **🚩 Flag (Bayrak / Kaydet)** butonu yer alır (`is_flagged`, `flagged_in_list_ids`).
  - Kullanıcı bu butona bastığında tıpkı *sahibinden.com*'da bir ilanı favori listesine eklerken açılan pencere gibi kullanıcının mevcut listeleri (`Favori Liste 1`, `Favori Liste 2` vb.) ve **`+ Yeni Liste Oluştur`** seçeneği açılır; kullanıcı tek dokunuşla mekanı istediği listeye kaydeder (`POST /places/lists/:listId/items`).
- **Mekanın İlintili Olduğu Rotalar (`GET /places/:id/routes`):**
  - Arama ekranı doğrudan mekan odaklıdır; kullanıcı incelediği bir mekanın hangi rotalarda yer aldığını görmek isterse mekan kartındaki/detayındaki **ayrı bir sekme veya çekmece (Bottom Sheet)** üzerinden o mekanın dahil olduğu yayınlanmış (`PUBLISHED`) rotaları görüntüler ve dilerse ilgili rotaya geçiş yapar.
- **30 Günlük Lazy Refresh:** Mekan detay kartı açıldığında mekan verisi 30 günden eskiyse kullanıcıya hissettirilmeden arka planda güncel veri çekilir. 

## **3. 🧭 Merkez Pusula Butonu: İnteraktif Rota Oluşturma ve Forklama Akışı (Swipe & Pick)** 

Alt navigasyon barının tam ortasındaki **Pusula / Dünya** butonuna basıldığında kullanıcı adım adım şu rota oluşturma akışını izler:

### **3.1. Adım 1: Seyahat Parametrelerinin Seçimi**
Kullanıcıya öncelikle nasıl bir seyahat planladığı sorulur:
- **Hedef Ülke ve Şehir Seçimi (`countries` & `cities`):** Birden fazla ülke ve birden fazla şehir seçilebilir (Çoklu seçim desteklenir; örn. İtalya içinde çok sayıda şehir seçildiğinde arayüzde taşmayı önleyecek kompakt/genişleyebilir bileşen kurgusu geliştirme aşamasında detaylandırılacaktır).
- **Seyahat Tarihleri (`start_date` - `end_date` / `flexible_period`):** *Opsiyonel.* Hangi tarihlerde ziyaret edileceği.
- **Ziyaretçi Dağılımı (`adults_count` & `children_count`):** *Opsiyonel.* **X Yetişkin, Y Çocuk** şeklinde ayrı ayrı tutulur ve toplam kişi sayısı (`travelers_count`) otomatik hesaplanır. (Çocuk sayısına göre otomatik mekan kısıtlaması veya uyarı popup'ı gösterilmez; karar tamamen kullanıcıya bırakılır).
- **Seyahat Bütçesi (`estimated_total_budget` & `currency`):** *Opsiyonel.* Hedeflenen bütçe aralığı.

### **3.2. Adım 2: Geçmiş / Anlık Tarihlerde Otomatik EXIF Mekan Yakalama**
- Eğer kullanıcının seçtiği tarih aralığı **geçmiş bir tarihe** aitse veya **anlık olarak o tarih aralığının içinde** bulunuluyorsa, o an için rota/anı oluşturuluyor demektir.
- Cihaz galerisindeki o tarih aralığına ait fotoğrafların EXIF (GPS ve Zaman) verileri istemci tarafında taranır ve kullanıcıya şu soru yöneltilir:
  > *"Falanca tarihte **X, Y ve Z** konumlarında bulunmuşsunuz, rotanıza bu durakları otomatik olarak eklemek ister misiniz?"*
- Kullanıcı onay verirse bu mekanlar otomatik olarak ilgili tarihe/güne `PHOTO_VERIFIED` durak olarak düşülür ve rota oluşturma akışına kaldığı yerden devam edilir.

### **3.3. Adım 3: Rota Oluşturma Modları (3 Ana Sekme)**
Parametre ve (varsa) EXIF adımı sonrasında kullanıcı, üstten birbiri arasında serbestçe geçiş yapabileceği **3 ana rota oluşturma modunun** bulunduğu ekrana yönlendirilir:

1. **Kendi Rotan (Mekan Destesi):**
   - Önceki adımda seçilen ülke/şehir ve bütçe parametreleriyle örtüşen popüler mekanlar (`PLACES` modu) Tinder tarzı bir kart destesi olarak gelir.
   - Kullanıcı beğendiği mekanları **sağa kaydırarak** rotasına ekler, **sola kaydırarak** pas geçer.
2. **Gezgin Rotaları (Topluluktan Mekan Çekme / Fork Stops):**
   - Başlangıçtaki filtrelerle (bölge, tarih/mevsim, bütçe, kişi sayısı) en çok örtüşen gezginlerin rotaları (`ROUTES` modu), **alt alta dikey Gezgin/Rota Kartları** şeklinde listelenir (Kart üzerinde rotaya dair kısa özet bilgiler yer alır).
   - Kullanıcı bir gezginin kartına girdiğinde o gezginin rotasındaki durakları (`RouteStop`) tek tek sağa/sola kaydırarak kendi rotasına çeker (`POST /routes/:id/fork`).
   - **Zincirleme Geçiş:** İncelenen gezginin rotasındaki mekanlar bittiğinde sistem otomatik olarak listedeki bir sonraki uyumlu gezginin rotasına geçer.
   - **Gezginler Arası Ortak Mekan Tekilleştirme (Cross-Traveler Deduplication):**
     - Örneğin **A gezgini** rotasına `X, Y, Z` yerlerini kaydetmiş, **B gezgini** ise `X, Z, A, B, C` lokasyonlarını kaydetmiş olsun.
     - Kullanıcı A gezgininin rotasını incelerken ortak olan `X` ve `Z` yerlerini **sağa veya sola kaydırarak değerlendirdiyse**, B gezginine geçtiğinde `X` ve `Z` mekanlarını **tekrardan görmez** (yalnızca `A, B, C` gösterilir).
     - Ancak A gezgininde `X` veya `Z` üzerinde henüz **herhangi bir değerlendirme (swipe) yapmadıysa**, B gezginine geçtiğinde bu mekanları görmesinde sakınca yoktur ve gösterilir.
3. **Tur Şirketleri (Kurumsal / Enterprise B2B Alanı — İleriki Faz):**
   - Tur şirketlerinin uygulamaya kurumsal (Enterprise) seviyede dahil edilip kendi paket rotalarını/reklamlarını sergileyebileceği vizyon alanıdır (Detaylı iş kurgusu ilerleyen aşamalarda netleştirilecektir).

### **3.4. Filtrelenen Mekanlar Bittiğinde Geçiş, Manuel Arama ve Sabit Erişim Widget'ları**
- **Filtrelenen Mekanlar Bittiğinde ("End-of-Deck" Soru Kartı):**
  - Kullanıcının seçtiği dar filtrelerdeki mekanlar tükendiğinde, filtreyi arka planda sessizce sıfırlamak yerine destenin sonuna şık bir geçiş kartı gelir:
    > *"Rotanıza eklenmeyi bekleyen diğer mekanları da görmek istemez misiniz?"*
  - Kullanıcı onayladığında dar filtreler esnetilerek o şehir/ülkedeki diğer popüler mekanlar desteye yüklenir.
- **Manuel Mekan Arama ve Google Places API Çekmecesi:**
  - Kullanıcı aradığı spesifik bir mekanı destede bulamazsa, aynı ekran üzerinden erişebileceği arama butonuna/çekmecesine (`Bottom Sheet` / Popup) basarak mekanı elle aratabilir; yerel veritabanında yoksa doğrudan **Google Places API** tetiklenerek mekan çekilir ve rotaya eklenir.
- **Sola Kaydırılan (Pas Geçilen) Mekanları Geri Kazanma (`dismissed_place_ids`):**
  - Kullanıcının rota oluştururken sola kaydırdığı mekanlar o rota bazında ayrı bir **"Sola Kaydırılanlar / Pas Geçilenler"** listesinde (`GET /routes/:id/dismissed-places`) tutulur. Kullanıcı sonradan fikrini değiştirirse bu listeden ilgili mekanı tek tıkla rotasına geri ekleyebilir (`POST /routes/:id/dismissed-places/:placeId/restore`).
- **Ekranda Her An Erişilebilir Sabit Alanlar:**
  - **Rota Önizleme (Route Preview) Widget'ı:** Kullanıcının o ana kadar rotasına kaç mekan eklediğini gördüğü, tıkladığında eklenen durakların sırasını/günlerini önizleyip düzenleyebildiği sabit erişim alanı.
  - **Flag'li (Bayraklı) Mekanlar Erişimi:** Kullanıcının daha önceden bayrakladığı mekanlar (seçilen ülke/şehir filtresiyle kesişenler öncelikli olmak üzere) ayrı bir sekme yerine ekran üzerinde her an erişilebilir bir çekmece/bar olarak göz önünde durur. 

## **4 & 5. 📡 [Sadece PREMIUM] Seyahat Esnasında Canlı Geofence Kumbarası ve Gün Sonu EXIF Eşleştirme** 

Bu iki otomatik yakalama mekanizması yalnızca **Premium** kullanıcılara açıktır ve kullanıcı deneyimini yormadan iki noktadan kontrol edilir:
- **Erişim ve Aktifleştirme (Üst Köşede Parlayan İkon & Pusula İçi Kontrol):**
  - Hem **🧭 Pusula / Rota Oluşturma** akışının içinde hem de ekranın üst köşesinde **parlayan bir ikon / anahtar (📡 *"Canlı Seyahat Yakalayıcı"* Switch'i)** yer alır.
  - Kullanıcı seyahate çıktığında bu parlayan ikona basarak otomatik yakalama modunu açıp kapatabilir (Free kullanıcı tıkladığında Premium avantaj ekranı açılır).
- **1. Sanal Çit / Geofence Bildirimi ve Kumbarası (`In-Trip Geofence`):**
  - Özellik aktifken uygulama arka planda pil dostu sanal çit mekanizmasıyla çalışır.
  - Kullanıcı sisteme kayıtlı bir mekanın yakınına (örn: 100-150m) geldiğinde veya orada vakit geçirdiğinde cihazına _"Şu an [Mekan Adı] yakınındasın, ziyaret ettin mi?"_ bildirimi düşer veya sessizce **Geofence Kumbarası**'na (`POST /routes/batch-geofence-sync`) kaydedilir.
  - Bu duraklar **`GEO_VERIFIED`** rozeti alır ve gezgine en yüksek puanı (**durak başı 50 puan**) kazandırır.
- **2. Gün Sonu Pasif Günlük ve EXIF Eşleştirme (`Passive Journaling`):**
  - Aktif rotası olan veya seyahatte olan kullanıcıya gün sonunda (veya rota oluştururken geçmiş/anlık tarih seçtiğinde) galerisindeki fotoğrafların EXIF (GPS ve Zaman) verileri cihaz üzerinde taranarak mekanlarla eşleştirilir (`POST /routes/match-exif`).
  - Konum verisi olmayan fotoğraflar "Aday Mekanlar" listesinden tek tıkla atanabilir; onaylanan duraklar **`PHOTO_VERIFIED` (20 puan)** rozeti alır.
- **Cihaz İçi Görsel Sıkıştırma:** Cihaz kamerasından veya galeriden seçilen fotoğraflar, sunucuya yüklenmeden hemen önce cihaz üzerinde %90 oranında (`1080p WebP`) sıkıştırılır.

---

## **6. 🚀 Taslak Rotayı Tamamlama: "Kişisel Anı Olarak Sakla" vs "Public Yayınla (Smart Publish)"** 

Kullanıcı oluşturduğu taslak rotayı (`DRAFT`) tamamladığında kendisine iki ana seçenek sunulur:

### **6.1. Seçenek A: 🔒 Kişisel Anı Olarak Sakla (`PRIVATE_MEMORY`)**
- Kullanıcı rotayı toplulukla paylaşmak istemeyip sadece kendi anı defterinde saklamak isterse (`POST /routes/:id/save-as-memory`);
- **Herhangi bir yuvarlak bütçe, yıldız puanlama veya konaklama girişi şartı aranmadan** rota doğrudan `PRIVATE_MEMORY` statüsüne çekilir (Free üye toplam maks. 5 özel anı saklayabilir; Premium sınırsızdır).
- Kullanıcı sonrasında bu "anılaşmış rotayı" istediği zaman tekrar düzenleyebilir veya dilerse sonradan Public olarak yayınlayabilir.

### **6.2. Seçenek B: 🌍 Public Olarak Yayınla (`PUBLISHED` — Smart Publish)**
Kullanıcı rotayı toplulukla paylaşmak (`POST /routes/:id/publish`) isterse şu tamamlayıcı adımları doldurur:
1. **Her Mekan Durağı İçin Puanlama (Zorunlu):** Rotadaki her bir mekan için 1-5 yıldız puanlama (`rating`) ve opsiyonel yorum / topluluk vibe & saha uyarısı seçimi yapılır.
2. **EsnekBütçe Girişi ve Kalem Kalem Detay Bonusu (Zorunlu):**
   - Kullanıcı ister tek kalemde **Genel Toplam Bütçe (`estimated_total_budget`)**, ister **Kalem Kalem Yuvarlak Bütçe (`budget_breakdown`: Yeme-İçme, Konaklama, Ulaşım, Aktivite)** girebilir.
   - **Gezgin Puanı Teşviki:** Sadece genel bütçe girene **`+30 puan`**, üşenmeyip **kalem kalem bütçe girene ekstra `+20 puan` (toplam `+50 puan`)** gezginlik puanı verilir.
3. **Esnek Konaklama Girişi (`stays`):** *"Bungalov - 3 Gece Kaldım"* veya *"Haritada Seçtiğim Otel - 2 Gece"* formatında pratik konaklama bilgisi girilir.
4. **Öne Çıkarılan Maksimum 5 Fotoğraf (`featured_media_urls`):** Anasayfa vitrin kartındaki slider için en fazla 5 fotoğraf seçilir (Seçilmezse duraklardaki ilk 5 fotoğraf otomatik kullanılır).

---

## **7. 🍓 Anıdan Sosyal Medya Hikaye/Kart Çıktısı Alma (`Social Share` — İleriki Faz / Faz 2)** 

> **Not:** Bu özellik uygulamanın ana iskeleti ("pasta") tamamlandıktan sonra eklenecek olan görsel cilalama ("pasta üzerindeki çilek") fazıdır.
- Rota veya Anı detay ekranındaki "Dışa Aktar / Paylaş" butonuna basıldığında seçilen 3 fotoğraf, istatistikler ve rotanın harita çizgisi `9:16 (Instagram Story)` veya `1:1 (Post)` formatında kolajlanarak paylaşım menüsüne aktarılır. 

## **8. 🏆 Liderlik Tablosu (Leaderboards) ve 👤 Gezgin Profili (Profile)** 

### **8.1. 🏆 Liderlik Tablosu / Ligler Ekranı (Sol-Orta Buton — Kıta > Tekil Ülke ve Adil Bölgesel Sıralama)**
Alt navigasyon barında sol-ortada yer alan **Ligler (Leaderboards)** ekranı, yerel ve bölgesel gezginlerin kendisini gösterebilmesi ve son kullanıcının o bölgeyi gerçekten gezmiş yerel gezginlerden en doğru tecrübeyi yakalayabilmesi için şu coğrafi kırılıma sahiptir (`GET /gamification/leaderboard` & `GET /gamification/geography-tree`):

1. **Kıta > Ülke Hiyerarşisi (Tekil Seçim):**
   - **1. Global**
   - **2. Avrupa** (`2.1 Tümü`, `2.2 Almanya`, `2.3 Fransa`, `2.4 Belçika` ...)
   - **3. Asya** (`3.1 Tümü`, `3.2 Rusya`, `3.3 Tayland` ...)
   - **4. Kuzey Amerika** (`4.1 Tümü` ...)
   - **5. Güney Amerika** (`5.1 Tümü` ...)
   - **6. Afrika / Okyanusya** (`Tümü` ...)
   - Ülkeler listelenirken **en çok rota bulunan ülkeler en üstte** yer alır ve ülke araması (`q`) yapılabilir.
   - **Tekil Seçim Kuralı:** Anasayfa'dan farklı olarak **Ligler ekranında ülke seçimi çoktan seçmeli değildir (tekildir)**; her lig tek bir kıtayı (`Tümü`) veya tek bir ülkeyi temsil eder.
2. **Adil Bölgesel Puanlama (`regional_points` vs `global_points`):**
   - **`Global`** seçildiğinde gezginlerin toplam global puanı (`global_points`) sıralanır.
   - Ancak bir **Kıta (`Avrupa > Tümü`)** veya **Ülke (`Avrupa > Almanya`)** seçildiğinde; Amerika'da 50.000 puan toplamış bir gezginin Almanya'da 5.000 puan toplamış yerel uzmanın önüne geçmesini engellemek için **yalnızca seçilen kıta/ülke sınırlarındaki doğrulanmış duraklardan ve o bölge rotalarının aldığı etkileşimlerden kazanılan bölgesel puan (`regional_points`)** baz alınarak adil sıralama yapılır.
   - Ayrıca zaman filtresi (`Tüm Zamanlar`, `Bu Ay`, `Sezonluk`) ile dönemsel şampiyonlar görüntülenir.

### **8.2. 👤 Gezgin Profili Ekranı (En Sağdaki Buton — Instagram Esinlenmeli Yapı)**
Alt navigasyon barının en sağındaki **Profilim** butonuna basıldığında açılan ekran şu görsel ve işlevsel hiyerarşiye sahiptir:

1. **Üst Kimlik Alanı (Header):**
   - **Sol Üstte Maksimum 3 Profil Fotoğrafı (`avatar_urls`):**
     - **1 adet ana fotoğraf** her zaman görünür; diğer **2 alternatif fotoğraf** ise kullanıcı profil fotoğrafının **üzerine basılı tuttuğunda (`Long Press`)** açılır.
     - Kullanıcı henüz fotoğraf yüklemediyse varsayılan **sırt çantalı gezgin silüetli** bir avatar (veya sistemin hazır gezgin avatarlarından biri) atanır.
   - **Hemen Yanında:** Üstte **Kullanıcı Adı (`username` / `display_name`)**, hemen altında **Gezginlik Rütbesi (`global_rank`)**.
   - **Sağ Üstte:** **⚙️ Ayarlar** ikonu butonu.
2. **Rütbenin Hemen Altında Yatay "Öne Çıkarılanlar / Story Highlights" (`profile_highlights`):**
   - Tıpkı Instagram'daki "Story Highlights" gibi, kullanıcının daha önce rotalarına yüklediği fotoğraflardan seçip isim vererek oluşturduğu fotoğraf dizileri yatay olarak sağa kaydırılabilir şekilde dizilir.
   - **Kota sınırı yoktur** (fotoğraflar zaten rota içi kotalara tabi olarak yüklenmiştir) ve **başka bir gezgin de** profili ziyaret ettiğinde bu öne çıkarılan fotoğraf dizilerini izleyebilir.
3. **Alt İçerik Sekmeleri ve Filtreleme:**
   - **1. Paylaşılan Rotalar (`PUBLISHED`):** Instagram post mantığıyla kullanıcının paylaştığı rotalar listelenir. Üst kısmında **Ülke/Şehir** ve **Tarih/Yıl** bazlı filtreleme yer alır; böylece gezginin hangi tarihte hangi ülkede rota paylaştığı kolayca süzülür (`GET /routes/user/:userId` & `GET /routes/me`).
   - **2. Taslaklarım (`DRAFT`):** Henüz yayımlanmamış taslak rotalar (3 + 1 kotası) burada listelenir ve buradan doğrudan **Rotayı Yayınla (Publish)** akışına yönlendirme yapılır.
   - **3. Kişisel Anılarım (`PRIVATE_MEMORY`):** Sadece kullanıcının kendisinin gördüğü özel anı rotalarıdır (`GET /routes/memories/me`). Tıpkı Paylaşılan Rotalar sekmesinde olduğu gibi burada da **Ülke/Şehir** ve **Tarih/Yıl** bazlı filtreleme birebir çalışır.
   - **4. Favori Mekan Listelerim (Flag'li Mekanlar):** Kullanıcının kaydettiği kişisel mekan listeleri (`Favori Liste 1`, `Favori Liste 2`...).
   - **5. Soru & Cevap (`Q&A` — `route_questions` Tablosu):** Kullanıcının paylaştığı rotalarla alakalı diğer gezginlerden gelen soruları kendi profilindeki ayrı bir sekmeden görüp cevaplayabildiği (`GET /routes/qa/me`, `PATCH /routes/qa/:questionId/answer`) ve dilerse ilgili rotanın Q&A fonksiyonunu kapatabildiği (`PATCH /routes/:id/qa-settings`, `is_qa_enabled`) alandır. 

