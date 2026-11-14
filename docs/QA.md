# Drive-By Wire0.13.1 · kamyon arka kapıları

14 Kasım2026. Yetkili kaynak kaansavukduran/drive-by-wire; taban main d69735dfdc7d/0.13.0. Fragaria Unslop proje/game/sprite kontrolleri ve canlı AIONIA v1.7 okundu, öncekiyle aynı revizyon. Önceki ayrıntılı sonuçlar [0.13.0](history/QA-v0130.md) ve PR17 içindedir. Bu kayıt kaynak hazırlanırkenki sonuçtur; CI/production ve gerçek commit sonrasında PR/yayın makbuzunda ayrıca doğrulanır.

## DBW-TRUCK-001

Kaynak: kullanıcının kamyon kapağının mantıksız açılması bildirimi. Mevcut kayıtlarda aynı kapak için ayrı hata kimliği bulunmadı.0.13.0 canlı masaüstü sürümünde normal giriş/sürüşle yeniden üretildi: araç atlasının saldırı hücresi, arka kapı yerine kasanın orta/tavan bölümünde kapılar ve yük boşluğu gösteriyordu. Araç kökü sabit olsa da bütün gövde hücresi bir anda değişiyordu; bu bir cache varsayımı değildir.

Düzeltme: aynı kapalı kamyonun kabin/tavan/tekerlek pikselleri bütün durumlarda korunur. Mevcut metal kaynağından kaplanmış iki rijit kapı gerçek arka dikmelerdeki menteşelerden açılır.0.4sn açılış,0.12sn bırakma beklemesi,0.28sn kapanış; gerçek0.65sn saldırı uyarısı ve hasar/bekleme kuralları aynı kalır. Çıkış ve uyarı kaynağı ölçülen arka ağzın merkezine hizalanır. Geç iptal edilen saldırıda kapılar sıçramadan kapanır. Uyarı alanının dolu arka planı kapağı gizlememesi için çerçeveye dönüştürüldü; esas uyarı işareti korunur. Kontrol, kayıt, hikâye ve trafik ağırlıkları değiştirilmez.

| Kontrol / ortam | Sonuç | Kanıt ve sınır |
|---|---|---|
| Native Godot4.6.3 | PASS |29takım/2024kontrol/0hata. Yeni truck_hatch173kontrol: sabit menteşeler, rijit yapraklar, çatıdan uzak arka açılış, kademeli açılma/kapanma, açık kapıdan tek gerçek nesne, iptal ve RNG değişmemesi. Sonraki tek kaynak farkı uyarının dolu alanının çerçeve olmasıdır. |
| Gerçek web / klavye-fare | PASS |1280×720, normal başlat/yanıt/devam/sürüş; açılma, tam açık, gerçek bırakma, kapanma ve tekrar kapalı beş durum görüntülendi. Native kurgu spawnı veya QA yazdırma kullanılmaz. |
| Gerçek web / dokunmatik | PASS |390×844, sabit joystick/ateş/mayın ve normal girişle açılma, tam açık, gerçek bırakma, kapanma/tekrar kapalı durumları geçti; runtime hatası0. Son koşuda ilk doğal karşılaşma kullanıldı. Önceki kısa tam-açık örnekleme FAIL kanıtı korunur. |
| Kayıt ve eski regresyonlar | PASS | Mevcut sabit biyom, arka spawn, sağlık/metin yerleşimi, üç yanıt, sabit oyuncu/garaj/sahne pivotları, iki etap/ara sahne ve Devam edecek sınırı native takımlarda korunur. |
| CI ve production | NOT TESTED | Henüz yayımlanmadı; test edilmiş kaynak ağacı, gerçek version/JS/WASM/PCK ve canlı giriş ayrıca PR/yayın makbuzuna kaydedilir. Rollback tabanı d69735dfdc7d/0.13.0. |
| Fiziksel cihazlar / diğer tarayıcılar | NOT TESTED | Chromium/SwiftShader ve telefon emülasyonu kullanıldı. Fiziksel Xbox/telefon/tablet, Firefox/Edge/Safari/iOS, insan estetik/denge değerlendirmesi ve yeni performans ölçümü yapılmadı. |
| Önceki performans/font sınırlamaları | FAIL | Önceki FPS ve Canvas OS-font sınırları bu kapak onarımıyla çözülmüş sayılmaz. |

İlk yeni native koşu kapanış ucunda kayan nokta artığını yakaladı; uç hedefler yaklaşık eşitse tam0/1'e sabitlenir. Normal pozlar veya fizik koordinatları yuvarlanmaz. İlk tarayıcı gözlemlerinde rastgele trafik kamyon üretmeden etap bitti ya da boss bölümüne girdi; bu gözlem eksikliği ürün animasyon hatası diye sunulmaz. Test normal yeniden açılışla en fazla8sürüş içinde gerçek karşılaşma arar, denemeleri kaydeder; trafik RNG'sine, HP'ye, oyuna/kayıtlara testten değer yazılmaz. Dokunmatik gözlemde menü/konum okumalarının maliyeti kısa açık anı kaçırdı; aynı beş poz kabulü korunarak sabit canvas ölçüsü önbelleklendi ve gözlem giriş işlemlerinden önceye alındı.

Kanıtlar ignored work/v0131: baseline-observed/keyboard-old-roof-opening.png; native.log; hatch-first.log; hatch-verified ve hatch-retry-search ilk FAIL sonuçları; hatch-final güncel sonuçları; build-final.log. Kaynak sprite atlası değiştirilmedi, yeni marka/karakter/kanon tasarımı yoktur.

Tekrar: GODOT=godot bash tests/run_all.sh; GODOT_BIN=godot python3 packaging/build_web.py. DBW_URL ve DBW_EVIDENCE_DIR ile tests/browser_truck_hatch.cjs. Tam lineer akış için tests/browser_linear.cjs; genel altı yerleşim için tests/browser_forge.cjs. Yerel, export, production ve fiziksel cihaz sonuçları birbirinin yerine geçmez.
