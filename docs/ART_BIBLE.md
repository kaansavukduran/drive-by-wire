# Drive-By Wire · AIONIA sanat kılavuzu

Güncel uygulama 0.10.1 · 13 Kasım 2026 · [Güncel AIONIA referansı](AIONIA_CURRENT_REFERENCE.md). Eski bölümler önceki üretim kaydını da içerir.

## Kimlik ve sınır

Fragaria Interactive ana marka, Fragaria Games yayın markası, AIONIA kurgu evrenidir. Bu kısa oyunda sıcak bir dijital yol arkadaşı ile tehlikeli otoyolun gerilimi yan yana gelir. MOMO'nun ifadesi ve garajın sıcaklığı sevimli yönü; güven/hafıza derinliği; 1.200 metrelik kuşatmayı aşma hedefi ölçek ve risk hissini taşır. Ana evrene yeni tarih, tür veya coğrafya eklenmez.

Fragaria çilek referansı ve 18 karakter referansı indirildi, görüntülendi, boyutları ve SHA-256 özetleri kaydedildi. Başlangıç belgesi son görsel kanon onayının beklediğini açıkça söylüyor. Dosya adındaki canonical ifadesi onay kabul edilmedi. Çilek görseli resmî logo diye yayımlanmadı; yazılı marka hiyerarşisi kullanıldı. Yeni karakter varyantı çizilmedi.

## Oyun için sabit kararlar

- Mantıksal alan 640×360; masaüstü varsayılan 1280×720. Godot GL Compatibility, en-boy oranı korunur. `canvas_items` UI yazısını gerçek ekran çözünürlüğünde tutar; nearest filtre piksel çizimlerini keskin büyütür. 1440p tam 4× varlık ölçeğidir. Tam kat olmayan ekranlarda piksel genişlikleri eşit olmayabilir; bu sınır fiziksel cihaz testini gerektirir.
- Varlıklar mevcut projenin 48×80 araç paftalarını, manifestteki yol/çevre boyutlarını ve karakter paftalarını kullanır. Tüm evrene tek tile boyutu dayatılmaz.
- Palet: mürekkep `#111d2b`, gece mavisi `#23354c`, krem `#fff2df`, nane `#9de1c3`, gül `#f4a8c5`, enerji camgöbeği `#79d4ff`, ödül altını `#ffce70`. Çevrenin mevcut toprak/bakır tonları korunur.
- Panel ve düğmeler ortak UiSkin ile kare kenar, 1–2 piksel çerçeve, belirgin nane odak sınırı kullanır. Yazı Lexend; yalnız eksik oklar için lisanslı ControlSymbols alt kümesi. Bulanık gölge ve yeni asset kolajı yoktur.
- Katı renkler için hesaplanan metin kontrastı: krem/mürekkep 15,41:1; krem/düğme 11,29:1; ikincil metin/devre dışı düğme 5,96:1. Bu hesap bütün olası kareler için otomatik WCAG sertifikası değildir; gerçek ekranlar ayrıca incelendi.
- Onarım artı, enerji şimşek, koruma kalkan biçimiyle ayrılır. Sayı ve yazı rengi destekler. Ayarlar yalnız renkle anlatılmaz; Açık/Kapalı yazılır.

## Animasyon, hizalama ve kamera

Mevcut `assets/MANIFEST.json` kare genişliği/yüksekliği, sütun sayısı, pivot, fps, döngü ve kaynak yollarını taşır. Oyuncu animasyonları `main.gd/ANIMS` içinde 8–16 fps, MOMO ve çevre manifestte tanımlıdır. Sabit kare sayısını artırmak için yapay tekrar eklenmedi.

Ön/arka ateş tehdide yönelir; mermi arabanın hedefe bakan kenarından çıkar. Ateş, hasar animasyonunu veya devam eden şerit değişimi pozunu kesmez. Hareket/çarpışmalar Godot'un 60 Hz fizik adımındadır; render FPS'i ayrı ölçülür. Kamera sabit yukarıdan görünür; yalnız isteğe bağlı kısa darbe sarsıntısı vardır. Mola sırasında dünya ve sarsıntı durur. Arka plan hareketi kapatıldığında dekoratif yol/çevre akışı ve MOMO'nun boşta hareketi durur; yaklaşan düşmanların oynanış hareketi sürer.

## Referanslar ve kullanım

Orijinaller Drive'da değişmeden durur; yerel indirmeler çalışma alanının attachments klasöründedir. Projeye büyük referans atlasları oyun varlığı olarak gömülmedi. `assets/sources/AIONIA_REFERENCES.json` her dosyanın URL'sini, özetini, çözünürlüğünü, renk modunu ve onay durumunu taşır. `assets/sources/.gdignore` referans kayıtlarını runtime kaynak taramasından ayırır.

| Karakter | İncelenen kaynaklar | Bu oyunda karar |
| --- | --- | --- |
| Aion | Ana referans, canonical-base, T poz A/B, turnaround, canonical/motion sprite | Pembe gövde, mavi göz/solungaç uçları, beyaz önlük ve DNA kuyruğu korunur. Arka kuyruk A/B farkı kesinleştirilmedi. Mevcut garaj çizimi değiştirilmedi. |
| Kurt | T poz/modelleme, canonical/motion sprite | Gri/mor kürk, açık göğüs/kuyruk ucu ve mor lanet izi referansı kaydedildi. Yeni görünüm/oynanabilir karakter eklenmedi. |
| Kuzu | v01/v02 pafta, canonical/motion sprite | Krem yün, amber göz, koyu toynak; v02 hale/kitap farkı kayıtlıdır. Son onay varsayılmadı. |
| Baykuş Ömer | Kanatlar açık modelleme, canonical/motion sprite | Kahverengi tüy, krem yüz/göğüs, amber göz korunur. Mevcut garaj çizimi değiştirilmedi. |
| Tavşan Emre | T poz/modelleme paftası | Bej tüy, yeşil göz, açık mavi gömlek, kırmızı kravat, koyu pantolon kaydedildi. Sprite yok; uydurma animasyon eklenmedi. |

Aion/Kurt/Kuzu motion atlasları 1536×1024; görülen 12×8 düzen için 128×128 aday hücreler vardır. Ömer ve canonical atlasların boyutları farklıdır; kullanıcı onayı, kare ayrımı, alfa temizliği ve pivot doğrulaması yapılmadan doğrudan runtime atlası sayılmazlar. Referansların tamamı final kaynak olarak onay bekler. Bu oyundaki mevcut paftaların çizim/lisans kaydı `assets/PROVENANCE.json` ve `THIRD_PARTY_NOTICES.md` içindedir.

## 0.6.0 · İLİN ve Fragaria yükleyicisi

Kullanıcının yeni AI talebiyle İLİN oluşturuldu; [JOURNEY.md](JOURNEY.md) yüz siluetini, paletini ve OYUN/TASLAK statüsünü kaydeder. Eski CRT/MOMO yüzü ve MOMO panosu yeni oyuncu akışında kullanılmaz. Aion, Kurt, Kuzu, Ömer ve Emre kaynakları korunur.

Yükleyici `assets/brand/fragaria-reference.jpg` dosyasını kullanır. 1058×1487, 144131 byte; SHA-256 `e72d624a012cb86e5b21011452fd1a8fb1954b2f19c68b51d8910bebef093828`. Özgün Drive JPG'si değişmeden kopyalandı; çizim yeniden üretilmedi. Siyah arka plan, pixel marka yazısı ve on parçalı ölçülen yükleme çubuğu standardın art direction'ını uygular. Onay klasöründe ayrı final logo/kompozisyon bulunmadı; bu kullanım kesin logo/ANA kanon onayı iddiası taşımaz.

Normal UI tek koyu/açık palet ve sistem tercihiyle çalışır; oyun dünyasının pixel çizimleri tema değiştirince yeniden renklendirilmez. HTML normal metinleri system-ui; native UI SystemFont, Web Canvas gömülü font yedeği; Lexend isteğe bağlıdır. Marka pixel yazısı istisnadır.

0.6.0 oyun simgesi de yeni İLİN çiziminden gelir: `assets/brand/ilin-icon.svg` özgün pixel geometri; `tools/art/render_ilin_icon.gd` PNG çıktısını üretir. Eski MOMO ikonu arşiv varlığı olarak kaldı, uygulama/favicon/export onu kullanmaz. Garajın eski terminal yüzeyi runtime paneliyle kapatılıp İLİN gösterilir; kaynak arka plan değiştirilmez.

Yayın kapısı: bu sürümde özel referansların, kaynak ağacının ve test ekranlarının public GitHub aktarımı onaylanmadı. Yerel geliştirme/inceleme tamamlandı; dal ve uzak önizleme 0.6 olarak yayımlanmadı.

## 0.7.0 · Aion sürücü ve tutarlı dünya koordinatları

Kullanıcı eski sürücüyü değiştirmeyi ve diğer karakterlerle konuşmayı istedi. Ana Aion referansı ve dört karakterin paftaları yeniden incelendi. Yeni araç/portreler AI destekli oyun uyarlamasıdır; mevcut kaynaklar korunur, final ANA kanon varyantı ilan edilmez. Kaynak özeti, orijinal üretim hash'i ve işlenmiş dosya hash'i `assets/sources/OMEGA3_ART.json` içindedir.

- Araç: 4×2 hücre, her hücre 64×96; sabit pivot (32,45), çizim 48×80. Gövde animasyonun alfa sınırına göre hizalanmaz. Oyuncu hitbox merkezi fizik `(car_x,car_y)`; sprite yalnız görüntü için en fazla yarım mantıksal piksele yuvarlanır.
- Ön namlu `(0,-30)`, arka mayın `(0,+30)` aynı fizik merkezine bağlıdır. Namlu parlaması/elektrik görseli araç merkezini izler; fırlatılan mermi ve mayın kendi dünya hareketine geçer. Kamera sarsıntısı bütün dünya katmanına uygulanır; UI CanvasLayer'da kalır.
- 8 ayrı araç pozu vardır: dört sürüş/ifade, iki turbo, bir ön ateş, bir hasar. Yeni yürüme/koşma karakter animasyonları varmış gibi gösterilmez. Sakin göz kırpma yaklaşık 3,8 sn aralıklıdır; azaltılmış harekette dekoratif sürüş pozu sabittir.
- Portre: 3×2 atlas, 64×64 hücre, beş karakter ve bir kullanılmayan hücre. Portreler statiktir. Runtime alfa eşiği 0,94, kare en-boy oranı ve eşit hücreler korunur. Replik boyu portreyi esnetmez.
- Büyük üretimler `tools/art/import_omega_atlas.gd` ile hücre hücre nearest örneklenir. Bu bir oyun varlığı içe alma adımıdır; yeni motor veya renderer değildir. Orijinal üretimler değiştirilmez. Atlas PNG toplamı 131.244 byte; gerçek GPU bellek tahsisi ölçülmüş sayılmaz.

Sabit joystick sekizgen piksel kontur ve ortak UiSkin paleti kullanır. Aynı eylem ailesi eşit ölçü/kenar/boşluk kullanır; joystick, mola ve eylem hitbox'ları için dört native ve altı tarayıcı düzeni denetlenir. [Kontrol kararı](CONTROLS.md).

## 0.7.1 · Sürücü yönü

Aion, kuzeye bakan aracın sürüş yönüne döner. Başın arkası, mavi uçlu solungaçlar ve beyaz önlük görünür; direksiyon ve eller başın kuzeyindedir. Sekiz karelik atlas aynı fizik pivotunu `(32,43.5)` kullanır; yeni çizimin gövde merkezine göre doğrulandı. Silah/mayın çıkış noktaları ve hitbox değişmedi. Üretim orijinali yerelde korunur; oyuna 64×96 hücreler nearest örneklenir. Yeni karelerde sürücü yüzü arkaya çizilmez.

## 0.7.2 · Garaj sahne alanları

Mevcut characters_standing.png değiştirilmez. Ana menü ve garajda Aion ilk satırın ilk karesi, Ömer ikinci satırın ilk karesinde sabit durur. Bu sahne boşta farklı gövde pozları arasında çevrim yapmaz. Sprite2D 72×64 bölge, merkezli X ve (36,61) ayak pivotu kullanır; Ömer kendi merkezinde sola döner. Her karakter ayrı Control alanında, tamamı sığacak şekilde çizilir. Zaman, diyalog veya seçim kareyi/konumu değiştirmez. Dikey/yatay düzen tek yerleşim fonksiyonundan türetilir; UI bu alanları kullanmaz.


## 0.8.0 · Yol robotları ve biyomlar

Üç özgün robot aynı koyu mürekkep/çelik gölge/açık metal paletini kullanır. Mühür-01 sıcak amber zırh/çift namlu, Yankı-02 mavi kanatlı verici, Tasnif-13 pembe ağır gövde siluetindedir. robot_art.gd blokları aynı merkezde çizer; egzost hareketi çekirdeği/hitbox’ı oynatmaz. NPC atlası değişmez. Robot portresinde atlasın alfa kesme shader’ı kullanılmaz; mevcut karakterler aynı shader ve atlasla kalır.

Altı biyomda mevcut yol dokusu korunur; çevrede şehir direkleri, yağmurlu hat, cam ağaçlar, buz kristalleri, santral boruları ve arşiv kabinleri ayrı şekillerle çizilir. Yeni robot/çevre uyarlamaları OYUN/TASLAK; ana evren kanonu ilan edilmez.

## 0.9.0 · Yeni oyun paftaları

`tools/art/author_road_story.py` mevcut yerel Pillow ile özgün piksel geometrisini tekrar üretir; runtime bağımlılığı eklemez. Özel referanslar dışarı gönderilmez. `ROAD_STORY_ART.json` boyut/pivot/fps/hash ve TASLAK statüsünü kaydeder.

- Postacı ve Kuyruklu Yıldız: 64×96 kare, 4×2 atlas; farklı gövde silüetleri, teker/ışık/turbo/atış/hasar kareleri. Aion’un mevcut sürücü resmi runtime’da aynı noktada katmanlanır; karakter yeniden uydurulmaz. Mevcut Yol Arkadaşı aynen korunur.
- Emre tuzak atlası: 8 ayrı 64×96 kare; çatlak, gövde deformasyonu, alev ve duman. Araç pivotu (32,43.5) sabittir.
- Yaralı Emre: 6 ayrı 128×80 kare, 5 fps; nefes, göz kırpma ve uzanan el. Zemin pivotu (64,72) sabittir. Bej kürk, yeşil göz, açık mavi gömlek, kırmızı kravat ve koyu pantolon korunur. Mevcut portre ve paftanın yerine final kanon diye geçirilmez.

Aion’un yer sahnesi mevcut sabit 72×64 ayakta karesini kullanır; yeni yürüme veya diz çökme animasyonu yapılmış sayılmaz. Patlama efekti mevcut sprite sheet’tir. Azaltılmış hareket yaralı karakteri sabit pozda tutar ve dekoratif yarış akışını durdurur; sahne geçişleri çalışır.


## 0.10.0 · Yol kenarı oyunculuğu

0.9.0’ın küçük, düz geometrili yaralı Emre çizimi bu sahnenin duygu ve kimlik gereksinimini karşılamıyordu. Yeni paftalar kürk, dikiş, kumaş kıvrımı, yüz ifadesi ve aynı serin gece/sıcak yol ışığıyla üretildi. Aion’un pembe/mavi solungaçları, beyaz önlüğü ve DNA kuyruğu; Emre’nin bej kürkü, yeşil gözü ve düz kırmızı kravatı korunur. Eren turuncu kürk, uzun kirpik, benek, sivri yanak, koyu ceket ve çizgili kravatla ayrı okunur. Kullanıcının kedi referansı ayrıntı/ışık hedefidir; karakterlere kedi kimliği veya maceracı kıyafeti taşınmaz.

`data/story_cast_art.json` runtime pafta ölçüleri, kaynak temas noktaları, sabit dünya kökleri, klip süreleri ve PNG SHA-256 özetlerini tutar. Meta veri `assets/sources/.gdignore` altında tutulmaz; ilk web denemesinde dışa aktarımın onu atlaması gerçek tarayıcı testinde yakalandı. Normal `data/*.json` ihracıyla düzeltildi.

- Emre: 1536×1024, 3×2, 512×512 hücre, **6 ayrı** nefes/uzanma/göz kırpma pozu. Her kaynak karenin basılı arka ayak noktası ayrı ölçülür; dünya kökü (445,248) değişmez.
- Aion: 1254×1254, 2×2, 627×627 hücre, **4 ayrı** diz çökme/göz kırpma/el uzatma pozu. İki boşta poz ve iki etkileşim pozu vardır; dört karelik yeni yürüyüş iddiası yoktur. Basılı ayak dünya kökü (210,248).
- Eren: aynı 2×2 hücre düzeni, **4 ayrı** ayakta/göz kırpma/diz çökme/battaniyeyle yardım pozu. Sağ ayakkabı kökü (520,248); çömelme gövdenin bu topuk çevresinde bilinçli yer değiştirmesidir. Yardımdan sonra yeniden ayağa zıplatılmaz.
- Arka plan: 1536×1024 orman/yol/enkaz, kaynak destek çizgisi y777. Aktörlerin ayak düzlemi bu yola oturur. Dikey ekranda arka plan kırpılır; UI veya konuşma sayfası dünya köklerini kaydırmaz.

`story_cast_art.gd` Sprite2D bölge/offset/ölçeğini kaynak temasına göre ayarlar; fizik veya dünya kökü alfa kutusundan hesaplanmaz. Gölgeler sabittir. Düşük alfa üretim halesi ortak cutout malzemesiyle temizlenir; gövde hareketi sahte kamera sallantısıyla üretilmez. Azaltılmış hareket nefes/kırpma döngüsünü durdurur, yardım pozunu ve seçimleri korur. Klipler kısa poz tutuşlarıdır; ara kare üretimi veya yürüme animasyonu yapılmış sayılmaz.

Bu paftalar OYUN/TASLAK; özel modelleme paftalarının yerine kesin kanon ilan edilmez. Orijinal referanslar, önceki runtime çizimleri ve kaynak kayıtları korunur. Eski `author_road_story.py` yalnız 0.9.0 geometrik kaynaklarını tekrar üretir; yeni paftaların üreticisi değildir.


## 0.10.1 · İşçilik ve özgün oranlar

Kullanıcı0.10.0’ın ayrıntı/ışık kalitesini beğendi ancak karakterleri paftalara göre fazla olgun buldu. Paftayla karşılaştırmada Emre’nin uzun gövdesi/dar gözleri, Eren’in uzun bacakları/dar yüzü ve Aion’un eklenmiş koyu gömlek/pantolon/boyun kartı doğrulandı. Yeni görseller aynı modelin yalnız küçültülmesi değildir: her pafta özgün referans ve önceki oyun karesinin ayrıntı/ışık örneği birlikte kullanılarak yeniden düzenlendi. Kaynak paftalar public depoya eklenmez.

Aion: geniş yuvarlak yüz, büyük mavi gözler, kısa pembe çıplak uzuv/gövde, beyaz kısa kollu önlük, özgün sonsuzluk/yaprak işareti ve küçük pembe/beyaz/mavi göğüs rozeti. Emre: iri yeşil gözler, yuvarlak krem yanak, iki ön diş, kısa açık mavi gömlek/düz kırmızı kravat/kahverengi kemer ve kısa koyu pantolon. Eren: geniş sivri yanak tüyleri, iri bordo gözler, özgün kirpik/benek/çizgili kravat, kısa ceket ve bacaklar, büyük yuvarlak ayakkabı. Kanon kimliği korunur; yeni oyun paftaları final kanon onayı diye sunulmaz.

Atlas düzenleri ve14 ayrı poz korunur. Yeni gerçek kaynak temasları: Aion(290,552); Emre x450/y405–406; Eren ayakta(360,610), diz çökerken(450,590). Mantıksal dünya kökleri aynıdır; Emre’nin sahne ölçeği0.4375→0.375 ile daha kısa gövde silüetine uyarlandı. Eren’in yeni geniş yüzü/kulakları için portre kaynak kutusu400×400’e açıldı. Arka plan, klip sırası/süreleri ve kamera düzeni değiştirilmedi. Anatomik sadakat elle karşılaştırıldı; bu ölçüm otomatik bir kanon/estetik sertifikası değildir.
