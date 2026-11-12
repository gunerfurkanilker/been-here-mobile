# **Been Here - Travelog Manifesto** 

## **1. Amaç** 

Günümüzde herkes seyahat etmek ister. Ancak bu seyahatler belirli bir ücret ve zaman karşılığında gerçekleşir. Uygulamanın amacı elindeki bütçesi ve zamanına göre seyahat etmek isteyen kişilerin elindeki imkanlarla diğer kullanıcıların deneyimleri üzerinden çıkarımlarda bulunup seyahatini olabildiğince verimli geçirmesini, daha çok keşfetmesini amaçlamaktadır. 

## **2. Kapsam** 

Uygulamayı kullanacak olan kullanıcının aşağıdaki mantıkla uygulamayı kullanacağını düşünüyorum. Bu akışlara göre arayüzler tasarlanmalı, iş akışları bu kurgular üzerinden ilerlemeli. 

Bu uygulama deneyim paylaşma platformudur. Ucuz bilet bulma, araba kiralama gibi unsurları içermez. Sadece bu harcama kalemleri kullanıcılar tarafından deneyimlerinin sonunda istenir. 

- Herhangi bir seyahat tecrübesini sadece görüntülemek isteyen 

- Belirli bir noktaya seyahat planı yapmak ve bu konumla alakalı seyahat deneyimlerini görmek isteyen 

- Elimdeki bütçeye ve zamana göre hangi noktaları seyahat edebilirim? Diğer insanlar benzer imkanlarla hangi seyahatleri gerçekleştirebilmişler? 

- Elindeki bütçeye ve zamana göre belirli noktaları seyahat etmek ister, hangi seyahatler elindeki imkanlarla benzeşiyor? 

- Seyahat ettikten sonra seyahat ile alakalı anıların tutulması, gidilen mekanlar (restoran, tarihi, doğal güzellikler vs.), özel turlar (tekne turları), etkinlikler (konserler, festivaller vs.). İlgili seyahatle alakalı fotoğraflar, kısa 8-10 saniyelik videolar (Vine uygulaması tarzı) veya embed şekilde YouTube videosu da olabilir. Bir nevi anı günlüğü gibi düşünülebilir. Bu anıların sosyal medya platformlarında paylaşımı (Instagram Stories, Instagram gönderi veya Facebook vs.). 

## **3. Hedef Kitle & Gamification (Rütbe Sistemi)** 

Hedef kitlemiz dünyanın dört bir yanındaki gezginler, yerel ve global gezginler olarak 2 temel gruba ayrılır. Bu kitlenin uygulamada seyahat deneyimlerini paylaşmasını teşvik etmek amacıyla bir rütbe sistemi kurulacaktır. 

## **4. Ana Unsurlar (Domain Models / Entities)** 

Seyahat planını oluştururkenki temel domain nesneleridir: 

### **4.1. Mekan (Place)** 

- Mekanlar uygulamanın ana unsurudur. Veritabanı ve backend seviyesinde katı sınırlamalara yol açmamak adına kategoriler tek bir alana sabitlenmez; **Esnek Tagging Yapısı (Google Place Types Array)** olarak saklanır. 

- **Veri Katmanı (Database):** Google Places API'den gelen types dizisi esnek şekilde tutulur (["restaurant", "bakery", "point_of_interest"]). Ham API yanıtı veritabanında jsonb formatında saklanır. 

- **Sunum Katmanı (UI Mapping):** Arayüz seviyesinde dinamik filtreleme ve görsel gruplama amacıyla bu esnek etiketler 3 temel görünüm kategorisine (Yemek, Konaklama, Destinasyonlar) eşlenir (Mapping): 

   - **Yemek:** Restoranlar, kafeler, fırınlar, barlar vb. 

   - **Konaklama:** Oteller, kamp alanları, pansiyonlar, bungalovlar vb. 

   - **Destinasyonlar:** Müzeler, tarihi alanlar, doğal parklar, plajlar, etkinlikler vb. 

### **4.2. Rota (Sequence / Rotalar & Planlar)** 

- Kullanıcının mekanları kombinleyerek oluşturduğu gün gün veya serbest kurgulanabilen seyahat bütünüdür. Mekan, konaklama ve tahmini maliyet öğelerini birleştirir.
- Tıpkı bir GitHub reposunun görünürlük durumu (Draft / Private / Public) gibi bir rotanın 3 temel yaşam döngüsü statüsü bulunur:
   - **`DRAFT` (Taslak Rota):** Planlama aşamasındaki rotalardır (Free üyeler için maksimum 3 normal taslak + 1 yayından düzenlemeye çekilen taslak).
   - **`PRIVATE_MEMORY` (Kişisel Anı / Private Rota):** Gezilmiş rotaların toplulukla paylaşılmadan, puanlama/bütçe şartı aranmaksızın sadece kişiye özel olarak saklanması durumudur (Free üyeler için toplam maksimum 5 adet).
   - **`PUBLISHED` (Toplulukla Paylaşılan Rota & Anı / Public Rota):** Hem toplulukla (Keşif Destesi'nde) paylaşılan hem de kullanıcının kendi anılarında saklanan rotalardır. Topluluk içerik havuzunu büyütmek amacıyla **Free üyeler dahil tamamen sınırsızdır**.

### **4.3. Anı (Personal Travelog / Anılaştırılmış Rota)** 

- Ayrı ve kopuk bir varlık olmaktan ziyade, oluşturulan veya gezilen rotaların (veya EXIF/Geofence ile derlenen ziyaretlerin) kişiye özel (`PRIVATE_MEMORY`) ya da topluluğa açık (`PUBLISHED`) şekilde anılaştırılmasıdır. Free kullanıcılar kişiye özel (Private) anılarını toplamda maksimum **5 adet** (`QUOTA_FREE_MAX_PRIVATE_MEMORIES=5`) ile tutabilirken, anılarını toplulukla paylaştıklarında (`PUBLISHED`) herhangi bir kota sınırına takılmazlar. 

### **4.4. Kullanıcı & Profil (User & Profile)** 

- Gezginlerin profilleri, paylaştığı rotalar, topladığı rütbe puanları ve sosyal medya bağlantılarını içerir. 

## **5. Mantıksal Unsurlar ve Sistem Kuralları (Business Logic & Rules)** 

### **5.1. Mekan Kuralları (Place Business Rules)** 

#### **5.1.1. Veri Kaynağı, Hibrit Arama ve Önbellek Stratejisi (On-Demand & Smart Caching)** 

Google Places API maliyetlerini optimize etmek, veritabanını organik olarak büyütmek ve arama performansını maksimumda tutmak için **DB-First (İstek Üzerine Genişletme) + Akıllı Önbellek (Lazy Refresh)** modeli uygulanır: 

1. **Önce Veritabanı (DB-First):** Kullanıcı isim, kategori veya konum/ülke bazlı bir mekan araması yaptığında, sistem ilk olarak aramayı sadece kendi PostgreSQL/PostGIS veritabanında gerçekleştirir (Maliyet: $0, Hız: ~10ms). 

2. **Sonuçların Gösterimi ve UX Kurgusu:** Veritabanındaki eşleşen mekanlar doğrudan kullanıcıya sunulur. Arayüzün/listenin en altına _"Aradığın mekanı bulamadın mı? Google Maps ile daha fazla gör"_ şeklinde dinamik bir buton/kart yerleştirilir. 

3. **Kullanıcı Tetiklemeli API İsteği (On-Demand):** Kullanıcı bu mekanı aramadığı veya butona basmadığı sürece dış API'ye hiçbir istek atılmaz. Kullanıcı bastığında, arka planda Google Places API (Text/Nearby Search) tek bir istekle çağrılır. 

4. **Organik Büyüme, Çoklu Dil Desteği & Veri Yazımı (JSONB Upsert & Raw Payload):** Google'dan dönen mekanların googlePlaceId değerleri eşsiz (unique) anahtar olarak kullanılır. Mekan isimleri tek bir dilde değil, PostgreSQL'in JSONB formatında bir dil sözlüğü olarak tutulur (Örn: {"tr": "Saat Kulesi", "en": "Clock Tower"}). Farklı dildeki bir 

kullanıcı kendi dilinde arama yapıp Google API'yi tetiklediğinde, sistem aynı mekanı ikinci kez eklemez; mevcut kaydın JSONB isim objesini yeni dil çevirisiyle güncelleyerek (Upsert) uygulamanın dil havuzunu organik olarak zenginleştirir. Gelen ham Google yanıtı da ileride kullanılabilecek ek detaylar için veritabanında jsonb formatında saklanır. 

5. **Akıllı Önbellek ve 30 Günlük Yenileme (Lazy Refresh / Google TOS Compliance):** Google Şartları'na (TOS) tam uyum sağlamak ve gereksiz API maliyetlerinden kaçınmak için mekan verileri 30 gün boyunca önbellekten servis edilir. Bir mekan 30 günden eskiyse ve **yalnızca aktif bir kullanıcı o mekanı incelediğinde/tıkladığında (ekranda görüntülendiğinde)** arka planda (asenkron) Google Places API'den güncel verisi çekilerek veritabanı taze tutulur. Kullanılmayan/aranmayan/görünmeyen mekanlar için arka planda fuzuli güncelleme yapılmaz. 

6. **Kartopu Etkisi:** Kullanıcılar arama yapıp butona bastıkça yeni mekanlar veritabanına akar. Aynı bölgede arama yapan sonraki kullanıcılar artık verileri doğrudan kendi veritabanından çeker. Zamanla Google API bağımlılığı ve maliyeti logaritmik olarak sıfıra yaklaşır. 

7. **Kategorizasyon ve Çoklu Filtreleme:** Yeni çekilen mekanın kategorilendirilmesi esnek etiket sistemi (UI Mapping) üzerinden otomatik eşlenir. Kullanıcılar manuel metin aramasının yanı sıra kategoriler ( _Balık Restoranı_ , _Kahvaltı/Fırın_ , _Müze_ , _Plaj/Kamp_ ) ve Vibe etiketleri ( _Gün Batımı_ , _Sessiz_ ) bazında tekli veya çoklu filtreleme yapabilir. 

8. **Yazım Hatası Toleranslı Bulanık Arama ve Karakter Normalizasyonu (Fuzzy Search & Trigram / Unaccent):** Kullanıcıların arama yaparken harf yutma, yanlış tuşa basma (Örn: _"Saat Kulesi"_ yerine _"Sat Kul"_ veya _"Saar Tulesi"_) ya da Türkçe/aksanlı karakter kullanmama (Örn: _"Çeşme Sığacık"_ yerine _"cesme sigacik"_) durumlarında sonuçsuz kalmaması ve gereksiz yere Google API'yi tetiklememesi için harici bir arama motoru maliyeti yaratmadan doğrudan PostgreSQL'in yerleşik **`pg_trgm` (Trigram)** ve **`unaccent`** eklentileri kullanılır:
   - **Karakter ve Aksan Normalizasyonu (`normalize_search_text`):** Veritabanı seviyesinde tanımlanan `IMMUTABLE` SQL fonksiyonu ile hem Türkçe karakterler (`İ, I, ı, Ş, ş, Ğ, ğ, Ü, ü, Ö, ö, Ç, ç` → `i, s, g, u, o, c`) hem de uluslararası aksanlı harfler (`unaccent`) küçük harfe ve saf ASCII formuna dönüştürülür.
   - **Üçlü Harf Parçalama ve Benzerlik Skoru (`pg_trgm` & `word_similarity`):** Metinler 3'er harflik parçalara (trigram) bölünerek `GIN (gin_trgm_ops)` indeksi ile indekslenir. Arama esnasında hem tam alt metin eşleşmesi (`LIKE`) hem de hem `default_name` hem `name_translations` (JSONB) üzerinde `word_similarity >= 0.3` (%30 ve üzeri benzerlik) koşulu birlikte çalıştırılır.
   - **Akıllı Sıralama (`GREATEST` + `verified_hype_score`):** Sonuçlar önce aranan ifadeye en yüksek benzerlik oranına (`GREATEST(word_similarity(...)) DESC`), ardından mekanın doğrulanmış popülerlik puanına (`verified_hype_score DESC`) göre sıralanır. Böylece yazım hatalı aramalarda bile doğru mekan milisaniyeler içinde ve $0 maliyetle en üstte sunulur.

#### **5.1.2. Yakındaki Benzer Noktalar ve Konum Bazlı Keşif (Contextual Nearby Discovery)** 

- **Konum Esnekliği:** Kullanıcının o an fiziksel olarak bulunması şart değildir; aratılan veya incelenen mekanın koordinatı/bölgesi merkez alınarak sorgu çalıştırılır. 

- **Mesafe & İl/İlçe Bazlı Filtreleme:** Arama sorguları veritabanı seviyesinde (PostGIS) seçili mekanın 2 km - 5 km yarıçapındaki dairesel alanda veya bulunulan İl/İlçe idari sınırlarında gerçekleştirilir. 

- **Kategori Eşleşmesi (Contextual Matching):** İncelenen mekanın esnek etiket kümesine (google_types) göre çevredeki benzer kategorideki noktalar filtrelenerek getirilir (Örn: Müze inceleniyorsa etraftaki diğer tarihi noktalar; fırın inceleniyorsa etraftaki yerel lezzet durakları). 

- **On-Demand Fetch Entegrasyonu:** Veritabanındaki yarıçap/ilçe bazlı sorgu sonucunda yeterli benzer mekan bulunamazsa, kullanıcı etkileşimiyle (kart listenin sonundaki tetikleyici bileşen/buton üzerinden) Google Places API (Nearby Search) devreye girerek o bölgedeki eksik mekanları veritabanına kazandırır. 

#### **5.1.3. Konum Bazlı Otomatik Mekan Hatırlatıcı ve Hızlı Check-In (Geofenced Quick Visit)** 

- **Hukuki ve Yasal Uyum (KVKK & GDPR / Opt-in):** Arka plan konum takibi ve bildirimler tamamen kullanıcının açık rızasına (Açık Rıza Beyanı) ve açık/kapalı yapılabilir izin seçeneğine (Opt-in) bağlıdır. Kullanıcının anlık konum geçmişi sunucuda kaydedilmez, sadece cihaz üzerinde yerel olarak işletim sistemi (Geofence API) tarafından işlenir. 

- ● **Teknik İşleyiş (Düşük Pil & Geofencing):** Cihaz arka plandayken pil tüketmemek adına sürekli GPS takibi yapılmaz. İşletim sistemi seviyesinde Geofence (Sanal Çit) tanımlanır. 

- ● **Hızlı Aksiyon & Gamification:** Kullanıcı kayıtlı bir mekanın ~50-100m yakınına geldiğinde yerel bildirim tetiklenir ( _"Şu an X mekanındasın, burayı ziyaret ettin mi?"_ ). İki hızlı buton sunulur: **[Buradaydım]** (Tek tıkla anıya kaydeder ve rütbe puanı kazandırır) ve **[Rota/Fotoğraf Ekle]** . 

- **Spam ve Hız Denetimi:** Aynı mekan için 24 saat içinde tekrar bildirim atılmaz (Cooldown). Araçla hızlı geçişlerde tetiklenmemesi için yürüme/duraklama hızı denetimi 

uygulanır. 

#### **5.1.4. Kullanıcı Kaynaklı Topluluk Etiketleri, Mekan Ruhu ve Saha Uyarıları (User-Generated Community Tags, Vibe & Field Warnings)** 

- **Google Etiketlerinin Ötesi:** Google Places API'den gelen teknik türlerin (restaurant, cafe vb.) yanı sıra gezginlerin mekanda hissettiği atmosfer (`community_vibes`) ve diğer gezginleri hazırlıklı olmaları için uyardıkları fiziksel/çevresel saha koşulları (`community_warnings`) saklanır. 

- **Topluluk Katkısı (Community Vibe Tagging):** Kullanıcılar bir mekan için feedback verirken _"Gün batımı manzaralı"_ , _"Sessiz / Çalışmaya Uygun"_ , _"Evcil Hayvan Dostu"_ , _"Yerel Lezzet"_ gibi esnek atmosfer etiketleri seçebilir veya ekleyebilir. 

- **Topluluk Saha Uyarıları (Community Field Warnings):** Gezginler ziyaret ettikleri mekanlarda yaşadıkları zorlukları veya hazırlık gerektiren durumları _"Yüksek UV / Gölgesiz Alan"_ (Örn: Pamukkale Travertenleri veya antik kentlerde öğle sıcağı riski), _"Dik Tırmanış / Engebeli Zemin"_, _"Yabani Yaşam / Sinek-Arı Uyarısı"_, _"Su / Market Yok"_, _"Kaygan Zemin"_, _"Sadece Nakit Geçerli"_ gibi uyarı etiketleriyle oylayabilir (`community_warnings` JSONB). Bu uyarılar mekan aramalarında, mekan detayında ve başka bir gezgin o mekanı rotasına eklediğinde `community_warning_badges` ve `warnings` dizisi içinde otomatik olarak kullanıcıya gösterilir.

- **Dinamik Rozetleme (Badges):** Topluluk tarafından en çok oy alan Vibe ve Saha Uyarısı etiketleri mekan kartlarında rozet olarak gösterilir ve arayüzde bu özel hissiyatlara göre filtreleme yapılmasına imkan tanınır. 

#### **5.1.5. Geçici/Kalıcı Kapalı Mekan Durumu ve Haftalık Çalışma Günleri Yönetimi (Soft-Delete, Place Status & Opening Hours Warnings)** 

- **Kapanan Mekanların Durumu:** Google'dan ilk çekim veya 30 günlük **Lazy Refresh** esnasında `businessStatus: "CLOSED_PERMANENTLY"` veya `"CLOSED_TEMPORARILY"` bilgisi geldiğinde mekan veritabanından silinmez (Soft-Delete). 

- **Anıların Korunması:** Mekanın geçmiş rotalarda, anılarda ve fotoğraflarda duran geçmiş kayıtlarının bozulmaması için veritabanında `status` alanı (`CLOSED_PERMANENTLY` / `CLOSED_TEMPORARILY`) güncellenir. 

- **Arama, Listeleme ve Rotaya Ekleme Kuralı:** Kapanmış mekanlar spontan keşif destesinde (`Discovery Deck`) veya yakındaki önerilerde öne çıkarılmaz; ancak **kullanıcı doğrudan arama yaptığında (`searchPlaces`) sonuçlardan gizlenmez** (aktif mekanların hemen altında sıralanır). Böylece kullanıcının mekanı bulamadığını sanıp gereksiz yere Google Places API isteği tetiklemesi önlenir. Arama sonucunda ve mekan rotaya durak olarak eklenirken kullanıcıya açıkça `status_warning` (Örn: _"[Mekan Adı] kalıcı olarak kapanmıştır."_ / _"geçici olarak kapalıdır."_) uyarısı dönülür.

- **Haftalık Çalışma Günleri ve Kapalı Gün Bilgilendirmesi (`opening_hours_warning`):** Rota planları tarihten bağımsız bir taslak olarak da oluşturulabildiğinden, Google Places API `regularOpeningHours.weekdayDescriptions` verisinden mekanın haftalık çalışma saatleri ve kapalı olduğu günler (`closed_days`) ayrıştırılarak `opening_hours` (`JSONB`) kolonunda saklanır. Mekan aramalarında, mekan detayında ve rotaya durak eklenirken tarihten bağımsız bilgi/uyarı olarak `opening_hours_warning` (Örn: _"İzmir Arkeoloji Müzesi Pazartesi günleri kapalıdır."_) cevabı dönülür. 

#### **5.1.6. Kişisel Mekan Listeleri ve Harita Bayraklama (Saved Place Lists / Google Maps Flagging)** 

- **Serbest Liste Oluşturma ve Varsayılan İsimlendirme:** Kullanıcılar aradıkları veya inceledikleri mekanları tıpkı Google Maps'teki bayraklama (flag / saved lists) mantığıyla kendi oluşturdukları kişisel listelerde saklayabilirler. Sabit/zorunlu kategoriler dayatılmaz; kullanıcı yeni liste oluştururken özel bir isim girmezse sistem sırasıyla _"Favori Liste 1"_, _"Favori Liste 2"_, _"Favori Liste 3"_ şeklinde otomatik isim önerisi atar. Kullanıcı dilerse liste adını (Örn: _"İzmir Kahvaltıcıları"_, _"Yazın Gidilecek Koylar"_) ve bayrak ikonunu özelleştirebilir.
- **Üyelik ve Kota Kuralları (`.env` Tabanlı):**
   - **Kayıtsız Ziyaretçi (Read-Only):** Mekan bayraklama veya liste oluşturma işlemi yapamaz (giriş ekranına yönlendirilir).
   - **Ücretsiz Üye (Free):** En fazla **3 adet kişisel mekan listesi** (`QUOTA_FREE_MAX_PLACE_LISTS=3`) oluşturabilir ve her bir listeye en fazla **10 adet mekan** (`QUOTA_FREE_MAX_PLACES_PER_LIST=10`) ekleyebilir.
   - **Premium Üye:** Sınırsız sayıda kişisel mekan listesi oluşturabilir ve listelerine sınırsız sayıda mekan ekleyebilir.

### **5.2. Rota Kuralları (Sequence Business Rules)** 

#### **5.2.1. Paylaşım ve Feedback Mantığı** 

- **Feedback Şartı:** Seyahat esnasında veya sonrasında feedback (yorum, puanlama, tahmini maliyet) verilmeyen rotalar paylaşıma açılamaz. Fotoğraflı feedbackler öncelikli gösterilir. 

#### **5.2.2. Kopyalama ve Düzenleme (Forking - Durak Çekme)** 

- Tarih bilgisi kesin bir aralık, ay veya tüm yıl olarak seçilebilir. 

- Seçilen tarih ve bütçeyle uyuşan örnek rotalar öncelikli getirilir; bir rotayı "forklamak" komple rotayı klonlamak anlamına gelmez. Kullanıcı, diğer gezginlerin rotalarındaki durakları sağa/sola kaydırma (Swipe Left / Right) yöntemiyle eleyerek sadece beğendiği mekanları **kendi mevcut taslak rotasına (`target_route_id`)** çeker (Ücretsiz üyeler için rota başı 20 durak kotası burada da denetlenir). 

#### **5.2.3. Esnek Konaklama Yapısı (Süre Bazlı Toplu Seçim & Gizlilik) ve Hızlı Yayınlama UX** 

- **Esnek Konaklama Seçenekleri (Tam Konum vs. Jenerik):** Kullanıcı dilerse konakladığı yeri doğrudan harita pini / mekan kaydı olarak ekleyebilir. Gizlilik sebebiyle kesin yer paylaşmak istemezse jenerik kategoriler seçebilir ( _3 Yıldızlı Otel_ , _5 Yıldızlı Otel_ , _Bungalov/Butik Otel_ , _Karavan/Çadır Kampı_ , _Pansiyon_ , _Arkadaşımda/Akrabamda Kaldım_ ). 

- **Pratik Süre Bazlı Konaklama (Serbest / Gün Takvimi Zorunsuz):** Kullanıcıyı "1. gün burası, 2. gün şurası" gibi karmaşık gün takvimi eşleştirmeleriyle **kesinlikle yormuyoruz** . Kullanıcı sadece "Burada 2 gece kaldım", "Şurada 3 gece kaldım" şeklinde pratik gecelemesini/süresini girer (örneğin: "A Konumunda X gün kaldım / B Konumunda Y gün kaldım"). Gün bazlı detaylı döküm/eşleştirme yapma zorunluluğu yoktur ve bu süreç tamamen opsiyoneldir. 

- **Kullanıcıyı Yormayan Hızlı Yayınlama Akışı (Smart Expense Modal):** Rotayı 

oluştururken her mekan için tek tek masraf girmek zorunlu tutulmaz (kullanıcıyı bıktırmamak için). 

- **Yayınlama Öncesi Özet Adımı:** Rota _"Paylaş"_ butonuna tıklandığında pratik bir özet ekranı açılır. Sistem, rotadaki mekanlar ve ulaşım/konaklama için kullanıcılara hızlıca **Tahmini Toplam Harcama** veya kategori bazlı yuvarlak bütçe aralıkları (ör. _"Yeme-İçme: ~1.500 TL", "Aktivite: ~500 TL"_ ) girmesine izin verir. 

- **Bütçe Esnekliği:** Tek tek kalem girmek isteyen detaycı kullanıcılar kalem girebilir; hızlıca paylaşmak isteyenler ise tek bir adımla tahmini toplam harcama seçip rotayı yayınlayabilir. 

#### **5.2.4. Zaman Tüneli Esaslı Rota Oluşturma Akışları (Pre/In/Post-Trip Workflows & Smart Prompts)** 

Kullanıcıların seyahat alışkanlıklarına göre (önceden planlayanlar, anlık/spontane gezenler ve seyahat sonrasında kayıt derleyenler) 3 farklı dinamik akış sunulur: 

- **Seyahat Öncesi Akışı (Pre-Trip / Planning Phase):** Kullanıcı seyahate çıkmadan önce gelecekteki rotasını taslak olarak kurgular. Diğer gezginlerin rotalarından yerleri "Forking" yöntemiyle planına ekler. 

- **Seyahat Esnasında Akıllı Kayıt ve Bildirim Akışı (In-Trip / Smart Logging & Geofenced Prompt):** 

   - Spontane ve plansız gezen kullanıcılar için arka planda Geofencing (Sanal Çit) ve Quick Check-in kumbarası çalışır. 

   - Seyahat veya hafta bitiminde sistem akıllı bir bildirim üretir: _"Bu hafta X bölgesinde 5 farklı yer ziyaret ettin! Bu harika seyahati tek tıkla Rotaya dönüştürmek ister misin?"_ 

   - Bildirime tıklandığında cihazda yerel biriken check-in'ler tek ekranda rota taslağı olarak açılır; kullanıcı sadece başlık ve toplam tahmini bütçe ekleyip tek tıkla onaylar. 

   - **Akşam Özet Bildirimleri ve Tarih Eşleşmeli Günlük Akış (Scheduled Evening Smart Prompts):** Kullanıcı sistemde aktif bir seyahat tarih aralığı (ör. 20-25 Ekim) tanımladıysa, geofencing altyapısıyla gün içinde cihazda yerel toplanan ziyaret verileri (check-in/konumlar) gün sonu için kuyruğa alınır. Belirlenen sakin saat aralığında (ör. 21:00 - 23:00 gibi), sisteme kayıtlı aktif rota tarihleriyle eşleştirilerek kullanıcının telefonuna şu tarz akıllı bir bildirim gönderilir: _"Bugün X, Y, Z konumlarını ziyaret ettin! Bu durakları [Rota Adı] planının bugünkü gününe eklemek ister misin?"_ Kullanıcı bildirime dokunduğunda günün planı tek tıkla onaylanarak güncellenir. 

- **Seyahat Sonrası Akışı (Post-Trip / Retroactive Creation):** Seyahat bittikten sonra geçmiş kayıtlarını rotaya veya anıya dönüştürmek isteyen kullanıcılar için **Bölüm 5.3.1** 'deki EXIF ve Galeri Eşleştirme akışı devreye girer. 

#### **5.2.5. İnteraktif Rota Oluşturma ve Forklama (Swipe & Pick / Discovery Deck)** 

Gezginlerin pasif kopyalama yapmak yerine eğlenceli ve kişiselleştirilmiş bir deneyim yaşaması amacıyla Tinder tarzı kart kaydırma (Swipe & Pick) arayüzü sunulur: 

- **Forklama Esnasında Ayıklama (Swipe & Trim):** Başkasının rotası kopyalanırken mekanlar kart destesi olarak açılır. Sağa kaydırılan (💚) mekanlar rotaya eklenir, sola kaydırılanlar (💚) elenir. 

- **Sıfırdan Rota Oluştururken Keşif Destesi (Discovery Deck):** Bölge seçildiğinde topluluğun en çok ziyaret ettiği ve yüksek puanlı popüler mekanları kart destesi şeklinde gelir. 

- **Kategori, Vibe & Rütbeli Gezgin Odaklı Filtreleme:** Kullanıcı karar yorgunluğu (decision fatigue) yaşamamak adına kart destesini kategorilere ( _Balık Restoranı_ , _Kafeler_ , _Müzeler_ ), topluluk etiketlerine ( _Gün Batımı_ , _Yerel Lezzet_ ) veya gamification/rütbe sistemiyle entegre **Yüksek Rütbeli / Onaylı Gezginlerin Tercihleri (Elite Travelers)** filtresine göre daraltabilir. 

- **Kişiselleştirilmiş Öneri Algoritması (Onboarding Preferences):** Kayıt esnasında kullanıcının seçtiği ilgi alanları ( _Tarih & Antik Kentler_ , _Doğa & Parklar_ , _Kafeler & Yerel Lezzetler_ , _Plaj & Kamp_ ) dikeyinde öncelikli kartlar sunulur. 

- **Arama ve Esneklik (Search Fallback):** Kart destesi haricinde arama çubuğu üzerinden manuel arama ve haritadan pin seçimi her zaman aktiftir. 

- **API Maliyet Yönetimi ve Lazy Refresh Sınırı:** Kaydırma kartları sadece kendi veritabanımızdan (PostGIS) beslenir (Maliyet: $0). Kart kaydırma esnasında Google Places API'ye istek atılmaz. 30 günlük önbellek yenilemesi (Lazy Refresh) sadece kullanıcı kartın detayını tıkladığında devreye girer. Bölgede yetersiz mekan varsa destenin sonundaki _"Google Maps ile Daha Fazla Gör"_ butonuyla tek bir istek üzerinden yeni mekanlar veritabanına kazandırılır. 

### **5.3. Anı ve Pasif Günlük İş Akışları (Personal Travelog & Passive Journaling)** 

#### **5.3.1. Pasif Günlük Oluşturma ve EXIF Eşleştirme İş Akışı (Geo-verified Passive Journaling)** 

Kullanıcının seyahat esnasında sürekli manuel veri girmesini gerektirmeden, gün sonunda veya seyahat sonrasında akıllı ve sürtünmesiz bir şekilde anı günlüğü oluşturmasını sağlayan iş akışıdır: 

1. **Tetikte Olma & Gün Sonu Bildirimi:** Aktif seyahat planı bulunan kullanıcıya gün sonunda (örneğin saat 21:00'de) bir bildirim gönderilir: _"Bugünkü gezini anıya dönüştürmek ister misin?"_ İşlemi kullanıcı tetikler. 

2. **Medya & EXIF Taraması (Client-Side & Privacy-First):** Kullanıcı akışı başlattığında, o günün tarih aralığında çekilmiş fotoğraflar taranır. KVKK / GDPR uyumu kapsamında kullanıcı fotoğrafları ve EXIF verileri sunucuya ham olarak yüklenmez; fotoğraf seçimi, çekim tarihi (Timestamp) ve koordinat (GPS) ayrıştırma işlemi tamamen cihaz üzerinde (Client-Side) gerçekleşir. Çıkarılan koordinatlar PostGIS üzerindeki mekan koordinatlarıyla eşleştirilir. 

3. **Mekan Bazlı Otomatik Gruplama & Onay:** Sistem, eşleşen fotoğrafları ilgili mekanların altında gruplanmış olarak listeler ( _Örn: Tarihi Asansör - 3 Fotoğraf_ ). Kullanıcı gerekirse istemediği fotoğrafları listeden çıkarabilir ve doğru mekan eşleşmesini tek tıkla onaylar. 

4. **Manuel Eşleştirme & Aday Mekanlar (Fallback):** Konum bilgisi (EXIF) bulunmayan veya eşleşmeyen fotoğraflar için sistem kullanıcı zorlamaz; çekim tarihini sabit tutarak o günkü güzergahındaki mekanları üstte **"Aday Mekanlar"** olarak önerir veya arama kutusuyla kolayca manuel eşleştirme yapmasını sağlar. 

5. **Anı Kaydı & Doğrulama Rozeti:** Onaylanan mekanlar ve fotoğraflar kullanıcının anı günlüğüne kaydedilir. EXIF / GPS verisi doğrulanan kayıtlar **"Photo-Verified"** / **"GeoVerified"** etiketi kazanarak mekanın sistemdeki **"Verified-Hype"** puanına katkıda bulunur. Manuel eklenen (doğrulanmamış) kayıtlar ise sadece kullanıcının kişisel anılarında yer alır, genel popülarite puanını manipüle etmez. 

### **5.4. Rütbe ve Puan Hesaplama Algoritması (Gamification Rules)** 

- **Genel Gezginlik Rütbesi (Global Rank):** Rota paylaştıkça, Geo-Verified (Konum Doğrulamalı) ve Photo-Verified (EXIF Doğrulamalı) mekan ziyaretleri yaptıkça ve diğer kullanıcılar bu rotaları faydalı bulup kopyaladıkça (fork) kullanıcının ana rütbesi artar. Yüksek rütbeli gezginlerin rotaları Keşif Destesi'nde diğer kullanıcılara öncelikli gösterilir. 

- **Kademeli Fork Puanlama Sistemi (Tiered Fork Rewards & Delta Hesabı):** Bir gezginin yayınladığı rotadan başka bir kullanıcı kendi rotasına mekan çektiğinde (`forkRoute`), kaynak rotanın `fork_count` değeri 1 artar ve rota sahibine çekilen toplam mekan sayısına göre kademeli rütbe puanı verilir (Tekil veya toplu çekimlerde fark/delta hesabı yapılarak puan manipülasyonu önlenir):
   - **1 – 3 mekan çekildiğinde:** `+5 Puan` (`FORK_REWARD_TIER1_POINTS`)
   - **4 – 6 mekan çekildiğinde:** `+15 Puan` (`FORK_REWARD_TIER2_POINTS`)
   - **7 – 9 mekan çekildiğinde:** `+25 Puan` (`FORK_REWARD_TIER3_POINTS`)
   - **10 ve üzeri mekan çekildiğinde:** `+25 Puan` + 9 mekanın üzerindeki her ekstra mekan için `+2 Puan` (`FORK_REWARD_BONUS_PER_EXTRA_STOP`)

- ● **Bölge ve Ülke Odaklı Uzmanlık (Regional Mastery):** Puanlama sadece global değil, lokasyon bazlı da hesaplanır. Belirli bir ülke veya bölgede (Örn: Ege Kıyıları, İtalya) çok fazla doğrulanmış içerik üretenler o bölgenin "Uzmanı" rozetini kazanır ve o bölgeye ait aramalarda öne çıkarılır. 

- **Vibe ve Kategori Rozetleri (Thematic Expertise):** Gezginler ilgi alanlarına göre de uzmanlaşır. Sürekli tarihi yerleri ziyaret edenlere "Tarih Kaşifi", yerel lezzetleri paylaşanlara "Gurme Gezgin" gibi rozetler verilir. Keşif destesinde kategori araması yapanlara bu uzmanların rotaları sunulur. 

- **Dinamik ve Sezonluk Ligler (Time-Boxed Leaderboards):** Tüm zamanlar listesinde yeni kullanıcıların rekabetten kopmasını önlemek için sıralamalar periyodik liglere bölünür (Örn: "Yaz Sezonu Şampiyonları", "Ekim Ayı Keşfedenleri"). 

- **Trust Score (Görünmez Güvenilirlik Puanı):** Nicelikten çok niteliği ölçen arka plan metriğidir. Bir kullanıcı çok rota üretse bile diğer gezginler bu rotaları Keşif Destesi'nde sürekli sola kaydırıp (Swipe Left) eliyorsa, kullanıcının görünürlük puanı düşer. 

- **Premium Öne Çıkarma:** Paylaşılan rotaları öne çıkarmak ek olarak ücretli bir model (Boost) olarak da sunulabilir. 

### **5.5. Spam ve İçerik Denetim Mekanizması** 

- Spam veya mükerrer rotalar için cronjob ve kullanıcı bildirimleri baz alınarak otomatik/yönetici denetim mekanizması çalışır. 

### **5.6. Fotoğraf Depolama ve Trafik Maliyet Yönetimi / Sübvansiyon Stratejisi** 

- **Agresif İstemci Tarafı Optimizasyonu (Client-Side Compression):** Yükleme öncesinde cihaz üzerinde fotoğraflar maksimum 1080p çözünürlüğe düşürülür ve WebP formatına dönüştürülür. Bu işlem depolama ve bant genişliği maliyetlerini %90 oranında azaltır. 

- **Sıfır Egress (Trafik) Maliyetli Altyapı:** Yüksek görüntülenme sayılarında bant genişliği ücretlerinin önüne geçmek için Cloudflare R2 gibi sıfır egress (trafik) maliyetli depolama sağlayıcıları tercih edilir. 

## **6. Üyelik Modeli, Fiyatlandırma ve Limitler** 

Uygulama, kullanıcıları kısıtlamalarla boğmayan ancak premium özelliklerle cezbeden bir freemium (ücretsiz + ücretli) model üzerine kuruludur. Ayrıca uygulamaya giriş bariyerini sıfırlamak için kayıt zorunluluğu olmayan bir "Read-Only" (Sadece Okunabilir) ziyaretçi modu da bulunur. 

### **6.1. Üyelik Seviyeleri ve Özellikleri** 

- **Kayıtsız Ziyaretçi (Hiç Login Olmamış):** Uygulamayı indirir indirmez giriş duvarı (Force Login) ile karşılaşmaz. Uygulamadaki popüler rotaları, mekanları ve Keşif Destesi'ni (Swipe & Pick) inceleyebilir. Ancak beğeni yapma, rotayı kopyalama (fork), kendi rotasını oluşturma veya anı kaydetme eylemlerinden herhangi birine tıkladığında kayıt/giriş ekranı tetiklenir (İçeriği yem olarak kullanan Read-only deneyim). 

- **Ücretsiz Kullanıcı (Topluluğun İşçileri):** Firebase üzerinden kayıt olan standart kullanıcılardır. Veritabanını büyüten ana motordur. Manuel ve EXIF tabanlı günlük oluşturabilirler. Ancak depolama ve taslak sınırlarına (kota) tabidirler. Reklam görürler. 

- **Premium Kullanıcı (Konfor Arayanlar):** Aylık psikolojik sınır olan **~50 (~1 Dolar) ₺** gibi erişilebilir bir ücretle abone olan kullanıcılardır. Limitlere takılmadan uygulamanın tüm potansiyelini (özellikle arka planda otomatik kayıt yapan Akıllı Geofence özelliğini) kullanırlar. 

### **6.2. Özellik Karşılaştırma Tablosu** 

|**Özellik**|**Kayıtsız Ziyaretçi**<br>**(Read-Only)**|**Ücretsiz Üye (Free)**|**Premium Üye (Aylık**<br>**~50 )**<br>**₺**|
|---|---|---|---|
|**İçerik Görüntüleme**|Görüntüleyebilir|Görüntüleyebilir|Görüntüleyebilir|
|**Akıllı Geofence**<br>**Takibi (Otomatik**<br>**Günlük)**|Yok|Yok (Sadece<br>Manuel/EXIF)|**Var (Arka planda**<br>**otomatik)**|
|**Taslak Rota**<br>**Kapasitesi**|0 (Kayıt İster)|Maksimum 3 Adet<br>(+1 Yayından Düzenlemeye Çekilen)|Sınırsız|
|**Rota İçi Mekan (Durak)**<br>**Sınırı**|0 (Kayıt İster)|Rota başı maksimum<br>20 Mekan (Durak)|Sınırsız Mekan (Durak)|
|**Kişisel Mekan Listesi**<br>**(Flag / Kaydedilenler)**|0 (Kayıt İster)|Maksimum 3 Liste<br>(Liste başı max 10 mekan)|Sınırsız Liste &<br>Sınırsız Mekan|
|**Kişisel Anı (Private**<br>**Anılaştırılmış Rota)**|0 (Kayıt İster)|Toplam Maksimum 5 Adet<br>(Public Paylaşılan Rotalar Sınırsız)|Sınırsız Private &<br>Public Anı|
|**Mekan İçi Medya**<br>**Sınırı**|Medya Yükleyemez|Mekan başı max 3 foto<br>(Rota başı doğal max 60 foto,<br>Video Yok)|Sınırsız Fotoğraf +<br>Kısa Video|
|**Keşif Destesi**<br>**(Algoritma)**<br>**Önceliği**|Yok|Standart|%20 - %30 Daha<br>Fazla Görünürlük<br>(Boost)|
|**Reklam Deneyimi**|Reklam Görür|Reklam Görür|**Tamamen**<br>**Reklamsız**|



### **6.3. Fiyatlandırma ve Sürdürülebilirlik Stratejisi (Pricing & Sustainability)** 

- **Psikolojik Eşik ve Sürümden Kazanım (Kahve Parası Modeli):** Aylık ~50  (~1 Dolar) ₺ seviyesindeki fiyatlandırma, kullanıcıların dijital aboneliklerdeki psikolojik ödeme bariyerini 

(bir kahve parası eşiğini) kolayca aşmasını sağlar. Düşük fiyatlandırma yüksek dönüşüm (conversion) ve toplu sürümden kazanım avantajı sunar. 

- **Mikroskobik Sunucu ve Altyapı Maliyetleri:** Sistemin operasyonel maliyetleri 3 ana mimari kolon sayesinde minimum seviyelere indirilir: 

   - **1. Sıfır Egress Trafik Maliyeti:** Cloudflare R2 entegrasyonu sayesinde fotoğraf görüntülemelerinde bant genişliği ve transfer maliyetleri tamamen sıfırlanır. 

   - **2. Cihaz İçi Sıkıştırma (Depolama Tasarrufu):** Fotoğrafların cihaz üzerinde yükleme öncesinde 1080p WebP formatına sıkıştırılması depolama alanı ihtiyacını %90 azaltır. 

   - **3. DB-First Mimarisi & Akıllı Önbellek:** Mekan aramalarının öncelikle yerel veritabanından karşılanması ve 30 günlük önbellek yenileme modeli sayesinde Google Places API çağrıları ve harcamaları logaritmik olarak sıfıra yaklaşır. 

- **Güçlü Sübvansiyon ve Yüksek Kârlılık:** Son derece optimize edilen bu altyapı sayesinde tek bir Premium kullanıcının sağladığı abonelik geliri, yüzlerce ücretsiz üyenin oluşturduğu sunucu ve depolama masrafını rahatlıkla sübvanse eder; projenin sürdürülebilir ve yüksek kârlı bir finansal yapıya kavuşmasını sağlar. 

## **7. Kimlik Doğrulama ve Kullanıcı Girişi (Authentication)** 

Uygulamaya giriş süreçleri, maliyet avantajı (ücretsiz MVP başlangıcı), Apple/Google entegrasyon kolaylığı ve bağımsız backend (NestJS + PostGIS) mimarisiyle kusursuz uyumu sebebiyle **Firebase Authentication** üzerinden yönetilir. 

Kullanıcı dönüşümünü (conversion) maksimize etmek ve giriş bariyerini en aza indirmek için aşağıdaki modern giriş yöntemleri sunulur: 

- **Google Hesabı ile Giriş:** Android ve genel ekosistem için tek tıkla hızlı giriş. 

- **Apple Hesabı ile Giriş (Sign in with Apple):** App Store kuralları gereği zorunlu olan ve iOS kullanıcıları için yüksek gizlilik odaklı giriş. 

- **E-posta Hesabı ile Giriş:** Geleneksel yöntemleri tercih edenler için standart (veya sihirli bağlantı / Magic Link destekli) giriş. 

- **Facebook Hesabı ile Giriş:** Sosyal medya erişimi için standart alternatif yöntem. 

