# Drive-By Wire · AIONIA 0.4 tasarım ve teknik inceleme

12 Kasım 2026. İstenen referans v1.1; verilen resmî Google Doc erişim sırasında v1.2 başlığı taşıyor. Evrensel v1.1 kuralları ve güncel belgedeki oyun/kontrolcü ilkeleri esas alındı. [Kaynak kapsamı](AIONIA_CURRENT_REFERENCE.md). Önceki karakter onay sınırları [sanat kılavuzunda](ART_BIBLE.md).

## Amaç ve kitle

Oyuncunun vaadi, MOMO adlı yol arkadaşıyla 1.200 metreyi aşan kısa ve tekrar oynanabilir bir otoyol çatışmasıdır. Şerit seçimi, turbo enerjisi ve yakın tehditlere ateş temel kararlardır. Garaj diyalogları güven ve hafıza üzerinden karakter bağı kurar. Komut yazarak sürüş zorunlu değildir; T ile sohbet isteğe bağlıdır.

Birincil kitle Türkçe arayüzle kısa arcade seansları oynayan klavye/fare oyuncularıdır. İkincil kitle kontrolcü ve yatay dokunmatik ekran oyuncularıdır. Basılı tutmakta zorlananlar için otomatik ateş, çubuk sapması yaşayanlar için ayarlanabilir ölü bölge, hareket hassasiyeti için iki ayrı efekt ayarı vardır. Düşük güçlü cihazlar için isteğe bağlı web çözünürlüğü seçeneği eklenir. Tam ekran okuyucu ile görmeden oynama, her yaş/engel/cihaz için erişilebilirlik ve bütün platformlarda uyumluluk doğrulanmış değildir.

## Mevcut teknoloji ve kimlik

Godot 4.6.3 standard, GDScript ve GL Compatibility; JSON denge verileri, sahneden bağımsız MOMO/parser/arcade/garaj/kayıt sınıfları ve mevcut platform export profilleri. Web tek iş parçacıklı resmî Godot şablonudur. Yeni motor, framework, hesap, analiz servisi veya runtime bağımlılığı eklenmez.

Bu proje AIONIA içinde bir oyun olduğundan mevcut pixel art uygundur. Mevcut Aion/Ömer ve MOMO görselleri korunur; onaysız paftalar veya çilek referansı kesin logo yapılmaz. Menü, HUD ve ayarlar aynı mürekkep/krema/nane/gül paleti ve kare çerçeveleri kullanır. Küçük yazılar Lexend ile okunabilir tutulur. Yeni bağımsız hazır grafik paketi alınmaz.

## İncelemede saptanan açıklar ve karşılıkları

| Önceki eksik | 0.4 karşılığı | Doğrulama |
| --- | --- | --- |
| Kontrolcü D-pad ile sınırlı; platform varsayılan menü onayı eksik | Sol analog, D-pad, RT/LT, LB/RB, açık A/B menü eşlemeleri; cihaz ipuçları | Gerçek Godot sahnelerine enjekte edilen olaylarla tüm akış; fiziksel donanım ayrı kapı |
| Basılı ateş ve sabit tuşlar bazı oyuncuları sınırlar | Otomatik ateş, klavye/pad düğmesi yeniden atama, çakışma mesajı, %20–60 ölü bölge, kapatılabilir titreşim | Sahne, yeniden atama ve drift testleri |
| Aynı analog hareketin artan olayları birden fazla şerit atlayabilir | Eşik/histerezis ve nötre dönünce yeniden kurulan mandal | Ardışık analog olay testi |
| Kayıt değişiminde önce eski dosya silinir; kurtarma kopyası yok | Aynı klasörde geçici dosya ve rename; önceki geçerli kayıt yedeği, hata görünürlüğü | Rename arızası, bozuk/kayıp/büyük dosya ve yeni şema testleri |
| Arayüzde yerel veriyi silme yolu yok | Veri sekmesi, açık açıklama ve onaylı sıfırlama | İptal ve doğrulanan silme; yedek/geçici dosya temizliği |
| Yazılım WebGL renderer 60 FPS hedefini karşılamıyor | HUD güncellemeleri 10 Hz; isteğe bağlı 640×360 web arka tamponu; normal çözünürlük varsayılan | Aynı viewport üzerinde iki mod ölçümü, QA.md |
| Canvas dışında erişilebilir kontrol açıklaması yok | Semantik HTML yardım ve odak bağlantısı, ölçeklenebilir metin; yardım açınca mola | Tarayıcı klavyesi, %200 metin ve sabit yol kontrolü |
| Moladan yanlışlıkla sürüş kaybı | Yeniden başlat/garaj/menü için onay, güvenli varsayılan iptal | Kontrolcü iptal akışı |
| Android CI herkese açık prototip imzasını kullanabiliyor | Sahip imzası zorunlu, gizli değer yoksa job çalışmaz | Kaynak yapılandırması; gerçek imza kurulumu NOT TESTED |

## Bilgi mimarisi ve kalite sınırı

İlk ekranda amaç, başla, garaj, yardım ve ayarlar görünür. Ayarlar üç görev grubudur: Oyun / Kontroller / Veri. Kaydırma odağı takip eder; doğal Godot düğmeleri klavye ve kontrolcü navigasyonu sağlar. LB/RB ayar sekmelerini değiştirir. Kaydetme kısa bir gecikmeyle birleştirilir; hata halinde ayar oturumda uygulanır ve yeniden denenebilir. Mola, odak kaybı ve kumanda kopması dünyayı durdurur; tekrar bağlanmak kendiliğinden sürüş başlatmaz.

Önce mevcut tek seferin güvenilirliği iyileştirildi. Yeni bölüm, para kazanma sistemi, çevrimiçi hesap veya yeni karakter eklenmedi. Teknik kapsam için otomatik testler ve tarayıcı kanıtı; eğlence/dengenin değerlendirilmesi için ayrıca insan oyuncu testi gerekir. [QA.md](QA.md) yayın kararında bağlayıcı açıkları gösterir.
