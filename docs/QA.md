# Drive-By Wire 0.13.0 · doğrulama

14 Kasım 2026. Fragaria Unslop ve UI/game/behavior/sprite kontrolleri uygulandı. Canlı AIONIA belgesinin v1.7 revizyonu öncekiyle aynı olarak doğrulandı; kapsam docs/AIONIA_CURRENT_REFERENCE.md. Godot4.6.3, izole sentetik kayıtlar, Chromium/SwiftShader. Önceki sonuçlar [0.12.0](history/QA-v0120.md) arşivindedir. Kaynak, gerçek export ve canlı yayın ayrı doğrulanır.

| Kapsam | Sonuç | Gerçek gözlem / sınır |
|---|---|---|
| Native regresyon | PASS |28 takım /1848 kontrol /0 hata; son mobil metrik yerleşimi sonrası road_presentation ayrıca152/152 PASS. Son commit CI sonucu PR/yayın makbuzunda kaydedilir. |
| Tek biyom | PASS | Her iki etabın0/179/180/280/399/400m noktası native; klavye/fareyle iki gerçek400m etap boyunca Cam Ormanı/Buzlu Arşiv sabit. Dostça yarış mevcut sabit ormanda kalır. |
| Arka trafik | PASS | Normal spawner araçları gerçek viewport altından150 dünya birimi geride başlatır; tüm sprite görünür sınırın dışında. Distant araç korunması, sürekli geliş ve layout sırasında konumun değişmemesi beş native viewportta; tarayıcıda yeni arka araçların ilk gözlemi kamera dışında. |
| Kontroller | PASS | Yalnız Ateş ve Mayın; dört yön/sabit joystick korunur. Eski E/Q/Shift/R/Y/RB/LT yetenek bağları etkin değil; eski kayıt atamaları silinmez. Sonsuz arka mayın beklemesi ve bağımsız parmak sahipliği mevcut regresyonlarda. |
| Yanıtlar | PASS | Hazırlık üç gerçek yanıtla açılır, her yanıt ayrı cevap ve kayıt üretir; aynı sürüş ve lineer sıraya bağlanır. Klavye/fareyle yanıt→devam→iki etap→iki ara sahne→Devam edecek→reload geçti. |
| Tam klavye/fare export | PASS | İki gerçek400m/boss ve iki ara sahne, Kurt’un dört pozu;135/66can, runtime hatası0. Sonraki değişiklik boss uyarısının mobil fittingi, metriklerin ayrılması ve kısa yanıt kayıt bilgisidir. |
| Son export / tam dokunmatik | PASS | Yalnız sabit joystick/ateş/mayın ile iki400m/boss, iki ara sahne ve Kurt’un dört pozu; dikey→yatay dönüş/mola/devam, Devam edecek ve reload.92/135can, runtime hatası0. Cam Ormanı/Buzlu Arşiv sabit,12+8 arka araç ilk gözlemde tüm sprite ile kamera dışında. İlk adaydaki boss uyarısı kırpılması düzeltildi; yeni beş-viewport regresyonu152kontrolde PASS. |
| Altı ekran / logo / giriş | PASS |1280×720,390×844,844×390,768×1024,1024×768 ve düşük güç telefon. Çilekli gerçek yükleme, sabit garaj pikselleri, taşmayan sayfalar, font ayarı, WASD/ok/fare, bağımsız joystick/ateş/mayın, dönüşte güvenli mola; Gamepad API menü/analog/X/RT/Start/B ve bağlantı kesilmesi. Runtime hatası0. Sonraki tek fark kısa yanıt kayıt bilgisidir. |
| Sağlık ve bildirim yerleşimi | PASS | Büyük can/enerji/görev panelleri gizli; çıplak10px bar ve metrikler. Geçici yazılarda StyleBoxEmpty, karakter konuşmasında panel korunur. Boss talimatları gerçek font yüksekliğiyle ve konuşma paneliyle ayrım üzerinden sınanır. |
| Fragaria çileği | PASS | Kullanıcının açık talebiyle mevcut özgün1058×1487JPG aynen eklendi; kaynak/copy SHA256 e72d624a012cb86e5b21011452fd1a8fb1954b2f19c68b51d8910bebef093828. Godot resource yüklenir; web export asset yoksa başarısız olur. Gerçek web yüklemesinde görünür çilek, ölçülü ilerleme, v0.13.0 ekran görüntüsü incelendi. Yeni logo tasarımı iddia edilmez. |
| Eski konum/metin/kayıt hataları | PASS | Sabit garaj pikselleri, metin kelime koruması/sayfalama, Emre/Eren14poz, Kurt4poz ve gerçek tampon teması, kayıt geçişi ve devam sınırı native regresyonlarda korunur. |
| Fiziksel cihaz / insan değerlendirmesi | NOT TESTED | Fiziksel telefon/tablet/Xbox, Safari/iOS/FirefoxAndroid, titreşim, ekran okuyucu/WCAG, insan denge/estetik değerlendirmesi ve bellek/enerji ölçümü yapılmadı. |
| Önceki60FPS / Canvas OS-font sınırı | FAIL | Önceki açık sınırlamalar kapanmış sayılmaz; yeni performans ölçümü yok. Çilek assetinin yokluğu bu sürümde çözüldü; önceki markasız-preview engeli güncel kullanıcı kararıyla kalktı. |
| CI / canlı alan adı | NOT TESTED | Yayın henüz yapılmadı; PR/yayın makbuzu kesin commit, build, alias ve gerçek oynama sonucunu içerir. |

Kabul gerekçeleri: önceki turbo/fren/darbe hedefleri kullanıcının açıkça kaldırdığı davranıştı; yeni testler onların bağlı/aktif olmamasını ve iki gerçek eylemin bağımsız çalışmasını ister. Eski iki-yanıt/tek-departure beklentisi üç kaydedilen yanıt ve aynı sürüş kabulüne dönüştürüldü. Önceki180m biyom geçişi bekleyen test artık her etapta sabitliği ister; fizik/konum/tam boss zaferi/kelime koruma kontrolleri korunur.

İlk yeni native testinde logo ölçüsü render tahmininden yanlış yazılmıştı; özgün/copy dosyaları PIL ile1058×1487 ve aynı hash olarak doğrulandı. Spawn değerinin float32/64 eşitliği için0.01 tolerans kullanılır; tüm sprite’ın gerçek viewport dışında olması ayrı katı geometri testidir. İlk dokunmatik export FAIL gerçek metin kırpılmasıydı; test atlanmadı, ortak yerleşim düzeltildi.

Kanıtlar ignored work/v013: native-final.log, presentation-final.log, build-verified.log; book-keyboard/linear-results.json; ilk book-touch/failure.png ve FAIL JSON; book-touch-verified/linear-results.json; forge/forge-results.json. QA arayüzü salt okunur; browser akışları yalnız normal giriş/düğmeleri kullanır, HP/kayıt/konum veya boss durumuna değer yazmaz.

Tekrar: GODOT=godot bash tests/run_all.sh; GODOT_BIN=godot python3 packaging/build_web.py. DBW_URL ve DBW_INPUT=keyboard|pad|touch ile tests/browser_linear.cjs; altı düzen için tests/browser_forge.cjs. Özel modelleme paftaları public kaynağa eklenmez.
