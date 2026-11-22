# Drive-By Wire · Araçlı Yol Çatışması Karşılaştırmalı Araştırma ve Aktarım Kaydı

**Tarih:** 22 Kasım 2026  
**Kapsam:** Mission 1 (1. etap “Son geçiş” / Cam Ormanı, Mühür-01, “Yan yana” ilk ara sahnesi, ana menü/garaj/araç sunumu ve ses/web kabuğu)  
**Kanıt etiketleri:** `OBSERVED` (doğrudan okunan kaynak/oyun davranışı), `REPORTED` (birincil/ikincil kaynağın beyanı), `INFERRED` (tasarım yorumu), `PROPOSED` (DBW için önerilen/uygulanan özgün karar).  
**Dürüstlük sınırı:** Bu araştırma turunda referans oyunların video kayıtları izlenmemiş, oynanış kare sayıları (FPS/frame) ölçülmemiş ve taranmış PDF kılavuz sayfaları görsel olarak açılmamıştır. İzlenmemiş videoya zaman damgası veya ölçülmemiş animasyona sabit kare sayısı yazılmamıştır. Başka hiçbir oyunun sprite, ses veya müziği Drive-By Wire paketine kopyalanmaz.

---

## 1. Başlangıç ve Sentez

Drive-By Wire’ın onaylanmış temel sözleşmesi sabittir: yukarıdan görülen yol, serbest X/Y hareketi, sabit sanal joystick, yalnızca **öne ateş** ve **sınırsız/beklemeli arka mayın**, üç kozmetik araç, etap başına tek biyom ve 13 etaplık lineer hikâye (şu an iki çatışma etabı ve iki ara sahne).

Araştırma grubu üç ana ve üç tamamlayıcı araç oyunundan seçildi:

- **Ana referanslar:** *Spy Hunter* (1983 Arcade / 1987 NES ayrımıyla), *Super Spy Hunter / Battle Formula* (1991–1992 NES), *Highway Pursuit* (2003–2025 Windows).
- **Tamamlayıcı referanslar:** *Road Fighter* (1984 Arcade), *Death Rally* (1996 MS-DOS / 2011–2012 remake ayrımıyla), *OutRun* (1986 Arcade).

Ortak çekirdek ders: üstten görünüşlü araç çatışmasında oyuncunun “iyi hissettiği” şey yalnız hız veya düşman kalabalığı değil, **ön ve arka tehdidin siluet/konumla anında ayrılması**, **aracın küçük gövdesinde direksiyon/atış/hasar geri bildiriminin okunması**, **boss karşılaşmasında hazırlık–saldırı–toparlanma ritminin görünür olması** ve **yol boyunca atmosfer/müzik akışının bir yolculuk hissi vermesidir**.

---

## 2. Tarih, Üretim Bağlamı ve Sürüm/Platform Ayrımı

| Oyun | Asıl Sürüm / Platform | Yayımcı / Geliştirici | Doğrulanmış Ekip ve Roller (`REPORTED`) | Sürüm / Port Ayrımı |
| --- | --- | --- | --- | --- |
| **Spy Hunter** | Arcade (MCR-Scroll, Kasım 1983) | Bally Midway | Tasarım: George Gomez (Tom Leon ile birlikte); Arcade müzik uyarlaması: Bob Libbe, Michael Bartlow, Neil Falconer | 1983 Arcade kabini analog yoke, 2 vitesli kol, gaz pedalı ve 5 düğme kullanır. 1987 NES portu Sunsoft (Sun Denshi) tarafından geliştirildi; NES müzik düzenlemesi Naoki Kodaka’ya atfedilir. Arcade kabin fiziği ile NES D-pad uyarlaması aynı değildir. |
| **Super Spy Hunter** | Famicom (*Battle Formula*, 1991) / NES (1992) | Sunsoft / Sunsoft America | Ses ekibi: Naoki Kodaka, Nobuyuki Hara, Shinichi Seya (`REPORTED`, VGMPF / NESDev). Diğer jenerik rolleri bu turda birincil jenerik kaydından doğrulanmadı (`NOT EXAMINED`). | Japonya’da özgün *Battle Formula* adıyla çıktı; Kuzey Amerika’da Bally Midway anlaşmasıyla *Super Spy Hunter* adını aldı. Sonsuz yol yerine sahneli ve boss’lu yapıya geçer. |
| **Highway Pursuit** | Windows (v1.0 Kasım 2003 – v1.2.5 Mart 2025, Freeware) | Adam Dawes / Retrospec | Retrospec kaydı: Adam Dawes, John Blythe, Graham Goring, Bill Harbison (`REPORTED`). Bireysel alt roller ayrıca doğrulanmadığından her isme aynı görev atanmadı. | 2005 (v1.1) güncellemesinde tüm menülerin joystick/gamepad ile klavyesiz yönetilmesi ve özel tuş atamaları eklendi; 2015–2025 güncellemelerinde modern Windows uyumluluğu ve kullanıcı dizinine kayıt taşındı. |
| **Road Fighter** | Arcade (1984) | Konami | Konami Arcade ekibi; resmi HAMSTER Arcade Archives (2019 Switch/PS4) kaydı orijinal 1984 yapımını esas alır. | 6 etaplık yüksek hızlı (400 km/saat vurgulu) yol/yakıt/engel kaçış yapısı. 1995/1996 3D devamları farklı türdedir. |
| **Death Rally** | MS-DOS (Eylül 1996, klasik) vs iOS/Android/PC Remake (2011–2012) | 1996: Remedy Entertainment / Apogee / GT Interactive; 2011–2012: Remedy + Mountain Sheep + Cornfox & Brothers | 1996 klasiği Remedy’nin ilk oyunu (geliştirme adı *HiSpeed*); 2011–2012 yeniden yapımı Cornfox & Brothers ortaklığıyla üretildi. | İki sürüm ayrı üretimlerdir. Ortak odakları üstten görünüşlü küçük araçta silahlı çarpışma, isabet, duman, enkaz ve boss rakiplerdir. |
| **OutRun** | Arcade (Eylül 1986) | SEGA | SEGA AM2 / arcade sürümü; SEGA AGES Switch (2018) 60 fps ve ek parçalarla yeniden düzenlendi. | Arkadan kamera ve 16 yollu dallanan rota *OutRun*’a özgüdür; DBW’ye taşınmaz. Yalnızca çevre/müzik/yolculuk duygusu ders olarak alınır. |

---

## 3. Mekanik, Sanat, Ses ve Deneyim Çözümlemesi

### 3.1 Ön Tehdit vs Arka Tehdit Ayrımı (*Spy Hunter*, *Highway Pursuit*)
- `REPORTED`: *Spy Hunter*’da ön makineli tüfek sınırsızdır; yağ/duman gibi arka savunma araçları arkadan sıkıştıran veya yanaşan düşmanlara karşı kullanılır. Düşman tipleri farklı davranışla ayrılır (zırhlı itici *Road Lord*, lastik kesici *Switchblade*, yandan ateş eden *Enforcer*).
- `REPORTED`: *Highway Pursuit* farklı saldırı kalıplı düşman araçlarını, karargâh (HQ) telsiz uyarılarını, 3B ses efektlerini ve tüm menülerde gamepad gezintisini birleştirir.
- `INFERRED`: Oyuncunun ön ateş ve arka mayını refleksif biçimde ayırması için her iki eylemin **hem görsel çıkış noktası hem ses imzası hem de yol üzerindeki etki alanı** belirgin biçimde farklı olmalıdır. Mevcut DBW’de arka mayın patladığında ayrı bir patlama sesi çalınmıyor (yalnız düşman ölürse `kill` sesi duyuluyor) ve patlama görseli 60 px’lik gerçek etki alanını göstermiyordu.

### 3.2 Boss Ritim Okunurluğu (*Super Spy Hunter*)
- `REPORTED`: *Super Spy Hunter*’da bölümler belirgin boss karşılaşmalarıyla kapanır; Naoki Kodaka’nın ritmik bas hattı çatışma temposunu taşır.
- `INFERRED`: Sabit iki kare (normal/şarj) arasında geçiş yapan bir boss, oyuncuya “şimdi kaç, şimdi ateş et” penceresini yeterince net okumaz. Hazırlık (namlu şarjı + kilitli hedef), ateş (namlu tepmesi), toparlanma (soğutma buharı/açık çekirdek) ve yarı can faz değişimi (çekirdek dalgası + kırık zırh) görsel ve işitsel olarak ayrıldığında boss karşılaşması adil ve tatmin edici olur.

### 3.3 Küçük Üstten Araçta Hareket, İsabet ve Hasar Hissi (*Road Fighter*, *Death Rally*)
- `REPORTED`: *Road Fighter*’da yol kenarı ve trafik ayrımı yüksek hızda temiz siluet ve net görüş koridoru gerektirir. *Death Rally* üstten küçük araçta silahlı çatışma, yanık lastik/enkaz ve patlayıcı geri bildirim üzerine kuruludur.
- `OBSERVED` (DBW 0.13.3): `scripts/game/main.gd` içindeki `_animate()` animasyon adı ve kare saysa da `Vehicles.configure()` her karede aynı statik gövdeyi çiziyordu. Oyuncu aracı sola/sağa yönelirken gövde ağırlığı, direksiyon açısı, atış tepmesi, mayın kapağı parıltısı veya %50/%25 altı hasar dumanı göstermiyordu.
- `INFERRED`: Fiziksel hitbox’ı ve pivotu 1 piksel bile kaydırmadan; zemin temas gölgesi, yanal direksiyon yatışı, tekerlek dönüş açısı, atış tepmesi/isabet kıvılcımı ve ilerleyici hasar dumanı eklendiğinde sürüş “ağırlıklı ama gecikmesiz” hissedilir.

### 3.4 Tek Biyomda Yolculuk Atmosferi ve Müzik (*OutRun*, *Super Spy Hunter*)
- `REPORTED`: *OutRun*, yarıştan çok “manzara + müzikle yolculuk” duygusuyla öne çıkar; *Super Spy Hunter* yüksek enerjili bas yürüyüşüyle çatışma temposunu canlı tutar.
- `OBSERVED` (DBW 0.13.3): `scripts/game/sounds.gd` yalnızca 7 kısa sinüs tonu üretiyor; motor/yol tabanı, mayın patlaması, mermi isabeti, boss uyarı/faz sesleri ve müzik katmanı yok.
- `INFERRED`: DBW’de tek biyom (Cam Ormanı) kuralını bozmadan; hafif cam-ormanı atmosfer parçacıkları, düşük hacimli motor/yol tabanı ve sahneye duyarlı özgün sentez müzik (sürüş → Mühür-01 gerilimi → Yan yana duygusal ortam) yolculuk hissini güçlendirir.

---

## 4. Malzeme ve Kaynak Kataloğu

| Kaynak | URL | Erişim Durumu | Kullanım Kuralı |
| --- | --- | --- | --- |
| Highway Pursuit geliştirici sayfası | https://www.adamdawes.com/games/highway-pursuit.html | `OBSERVED` (metin okundu, 22 Kasım 2026) | Referans analiz ve kaynakça; kod/varlık kopyalanmaz |
| Retrospec Highway Pursuit kaydı | https://retrospec.sgn.net/info.htm?id=highwaypursuit&t=g | `OBSERVED` (metin okundu, 22 Kasım 2026) | Ekip adları doğrulaması |
| Road Fighter (HAMSTER / Konami) | https://www.arcadearchives.com/en/title/aca-084/ | `OBSERVED` (metin okundu, 22 Kasım 2026) | Yıl/platform ve yol okunurluğu referansı |
| Death Rally (Cornfox & Brothers) | https://www.cornfox.com/death-rally | `OBSERVED` (metin okundu, 22 Kasım 2026) | Remake sürüm ayrımı |
| OutRun (SEGA AGES arşivi) | https://archives.sega.jp/segaages/outrun/ | `OBSERVED` (metin okundu, 22 Kasım 2026) | Atmosfer/müzik yolculuk ilkesi |
| Spy Hunter Wikipedia / tarihçe | https://en.wikipedia.org/wiki/Spy_Hunter | `OBSERVED` (özet okundu, 22 Kasım 2026) | 1983 Arcade vs 1987 NES port ayrımı |
| Super Spy Hunter (VGMPF / VGMdb) | https://vgmpf.com/Wiki/index.php?title=Super_Spy_Hunter_(NES) | `OBSERVED` (özet okundu, 22 Kasım 2026) | Battle Formula kökeni ve ses ekibi |
| Spy Hunter / Super Spy Hunter PDF kılavuzları | Prompt §6 bağlantıları | `NOT EXAMINED` (görsel sayfalar açılmadı) | Ölçü veya doğrudan alıntı üretilmedi |

---

## 5. Drive-By Wire Mission 1’e İzlenebilir Özgün Aktarım Tablosu

| Kimlik | Kaynak / Sürüm | Görülen Karar | Olası Neden | DBW İhtiyacı | Özgün Karşılık | Reddedilen / Uyumsuz Unsur | Hedef Dosya | Kabul Kanıtı |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `DBW-RES-01` | *Road Fighter* (1984) + *Death Rally* (1996) | Küçük üstten araçta yön, isabet ve hasar anında okunur | Oyuncu gözünü yoldan ayırmadan durum bilgisini gövdeden okur | 0.13.3’te 3 araç gövdesi tamamen statik; direksiyon/ateş/hasar poz farkı yok | `VehicleMotion` ile sabit pivot/hitbox üstünde zemin gölgesi, ön teker açısı, hafif gövde yatışı, atış tepmesi, mayın kapağı sinyali ve %50/%25 hasar dumanı | Drift, fren, turbo, araçlar arası fizik farkı, hitbox kayması | `scripts/game/vehicle_motion.gd`, `scripts/game/main.gd`, `scripts/game/vehicle_screen.gd` | `tests/test_vehicle_motion.gd` + `tests/test_free_drive.gd` + tarayıcı ekran kanıtı |
| `DBW-RES-02` | *Spy Hunter* (1983) + *Highway Pursuit* (2003–2025) | Ön silah ve arka savunma net rol ve etki ayrımı taşır | Ön/arka eşzamanlı tehditte hangi eylemin çalıştığı karışmamalı | Arka mayın patlamasında ayrı ses ve gerçek 60 px etki halkası yok; mermi isabet kıvılcımı eksik | Mayın kurulum halkası, aktif kırmızı uyarı nabzı, 60 px şok dalgası + çok aşamalı patlama, ön mermi isabet kıvılcımı ve uzun kare tek-olay güvencesi | Mühimmat tüketimi, yeni el bombası, serbest fare nişanı | `scripts/game/main.gd`, `scripts/game/sounds.gd` | `tests/test_combat_events.gd` + `tests/test_rear_defense.gd` |
| `DBW-RES-03` | *Super Spy Hunter* (1991–1992 NES) | Boss karşılaşması belirgin hazırlık–saldırı–toparlanma ritmine sahip | Adil okuma ve tatmin edici saldırı penceresi | Mühür-01 yalnızca normal/şarj iki hücre arasında değişiyor; toparlanma ve faz değişimi zayıf | `boss_encounter.gd` durum sözlüğü (`entering`/`telegraph`/`firing`/`recover`/`phase_shift`/`defeated`) + `robot_art.gd` namlu şarj/tepme, soğutma buharı ve faz-2 çekirdek halkası | Mühür-01’i arkaya geçirme (Yankı-02’nin rolünü çalma), aşırı HP şişirme | `scripts/core/boss_encounter.gd`, `scripts/game/robot_art.gd`, `scripts/game/main.gd` | `tests/test_boss_encounters.gd` + `tests/test_combat_events.gd` + `tests/browser_linear.cjs` |
| `DBW-RES-04` | *OutRun* (1986) + *Super Spy Hunter* (1991) + *Highway Pursuit* | Sürüş atmosferi + ritmik müzik + olay ses hiyerarşisi | Tehlike uyarısı motorun altında kalmaz; yol bir yolculuk hissi verir | `sounds.gd` 7 temel ton; motor/yol, mayın patlaması, boss uyarı/faz ve müzik yok | Özgün sentez katmanlı sesler (motor tabanı, mayın patlaması, isabet, kapak, boss uyarı/faz) + sahneye duyarlı özgün Cam Ormanı / boss / Yan yana döngüleri + Cam Ormanı ışık zerrecikleri | Telifli müzik/örnek kopyalama, dallanan rota, biyom değişimi | `scripts/game/sounds.gd`, `scripts/game/road_biomes.gd`, `scripts/game/main.gd`, `scripts/game/road_story_screen.gd` | `tests/test_combat_events.gd` + `tests/test_run_fairness.gd` + canlı web dinleme/oynanış |
| `DBW-RES-05` | *Highway Pursuit* v1.1 (2005) + Modern Web Guidance | Bütün menülerde gamepad/klavye odak bütünlüğü ve sağlam dağıtım | Fare gerektirmeden baştan sona erişim ve güvenilir yayın | `pages.yml` motor/tarayıcı testlerini beklemeden yayınlıyor; bazı web kabuğu detayları güncel rehberle sıkılaştırılabilir | `pages.yml` içinde `verify_native` → `build_and_verify_web` → `deploy` zorunlu kapısı; `shell.html` safe-area, reduced-motion ve odak iyileştirmeleri | PWA/Service Worker ekleme, kontrol şeması değiştirme | `.github/workflows/pages.yml`, `packaging/web/shell.html`, `tests/browser_launch.cjs` | GitHub Actions yeşil kapı + canlı `version.json` ve oyun doğrulaması |
