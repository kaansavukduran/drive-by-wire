# Drive-By Wire 0.10.0 · doğrulama

13 Kasım 2026 · Godot4.6.3 · izole kayıtlar / taze Chromium SwiftShader bağlamları. Önceki sürümün ayrıntılı kaydı [QA-v090](history/QA-v090.md) içinde korunur. Bu rapor yerel kaynak ve web adayını kapsar; canlı main/dağıtım ayrıca yayın makbuzunda doğrulanır.

| Kapsam | Sonuç | Gerçek kanıt / sınır |
|---|---|---|
| Native regresyon | PASS | 25 takım /2215 kontrol; tüm13 yol için26 çatışma ve13 novel bölümü. Ardından güncel road_story214 kontrolü tekrar PASS; Eren kaydının gerçek sahne tamamlaması/disk reload sonrası korunması, bağın yalnız bir kez verilmesi ve bilinmeyen kaydın reddi için3 ek kontrol. Son toplam2218 ayrı kabul kontrolü. |
| Pafta / gerçek yerleşim | PASS | 14 ayrı kaynak poz; kaynak temasının opak piksele oturması, bölge/offset ve Sprite2D gerçek dünya kökü; iki font/beş viewport’ta bütün diyalog kelimeleri, portre/metin ayrımı ve44px eylemler. Azaltılmış hareket Emre’yi sabitler; yardım pozları ve seçimler sürer. |
| Web: baştan sona hikâye | PASS | Gerçek araç seçimi/reload; Mühür-01, yeni yol sahnesi/Eren, yarış/tuzak, kurtarma, mühürlü kayıt, Tasnif-13, e01 epilogu ve galeri/reload. İlk/son can106/142; düşman8/8, ikmal6/4. İki robotun iki fazı, dört çatışma biyomu. Epilog11 sabit sayfada, Eren’in seçilen kararı gerçek metinde görüldü. Runtime hatası0. |
| Web: animasyon ve telefon | PASS | Altı Emre karesi gerçek zamanlı döngüde görüldü. Aion/Emre/Eren gerçek kök ve global temasları35+ örnekte sabit; aynı yol düzlemi. 390×844 yön değişiminde güvenli mola, replik checkpoint reload. Masaüstü ve telefon sahne görüntüsü incelendi. |
| Web: gamepad | PASS | Emüle Gamepad API ile fare kullanmadan araç seçimi, gerçek400m/Mühür-01, sonuç düğmeleri, analog kurtarma ve Eren’in sinyal paylaşımı seçimi, üçüncü bölüme geçiş. Can115, düşman10, ikmal7. Runtime hatası0. Fiziksel Xbox testi değildir. |
| Web: altı düzen regresyonu | PASS | PC, telefon/tablet iki yön, düşük güç telefon. Sabit garaj pikselleri; joystick çapraz/geri hareket, bağımsız ateş/turbo parmakları, yön değişimi ve basılı girdi temizliği; HUD/eylem ayrımı. Gerçek ayar düğmesiyle Lexend seçimi; kumanda kopma/bağlanma. Hata0. |
| Web export | PASS | Yeni data/story_cast_art.json ve dört PNG gerçek pakette yüklenerek sahne oynandı. Godot betik/parse hatası yok. |
| Normal yazılım renderer60FPS / Canvas OS fontu | FAIL | Önceki performans ve gerçek OS font erişimi sınırları kapanmış sayılmaz; bu tur yeni60FPS veya bellek/enerji ölçümü yapılmadı. |
| Fiziksel telefon/tablet/Xbox, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Chromium dokunma/Gamepad emülasyonu fiziksel donanım değildir. |
| İnsan estetik/duygu/denge, ekran okuyucu/WCAG | NOT TESTED | Otomatik kabul insanın sanat veya hikâye değerlendirmesini yerine getirmez. Yeni sanat OYUN/TASLAK’tır. |
| Yeni kaynak için CI/üretim dağıtımı | NOT TESTED | Bu kaynak raporu yazılırken henüz main’e alınmadı. Commit/iş/üretim adresi ve son canlı test yayın makbuzunda ayrıca kaydedilir. |

## Bulunan ve giderilen sorunlar

İlk web adayında karakterler görünmedi, aktörler0,0 oldu ve JSON yükleme hatası çıktı: metadata assets/sources/.gdignore altında kaldığından include_filter onu pakete sokmadı. Dosya data/story_cast_art.json konumuna taşındı. Aynı normal hikâye girişi ve gerçek tarayıcı görüntüsüyle karakterler ve sabit temaslar doğrulandı; hata0. Native PASS tek başına web yayını sayılmadı.

İkinci adayda230ms aralıklı test örnekleri kısa göz kırpma karesini kaçırıp6 yerine5 kare gördü. Altı ayrı kare kabulü korunarak örnekleme75ms ve birkaç gerçek döngüye çıkarıldı. Son testte0–5 karelerin tümü gözlendi; oyun zamanı veya durumuna test değeri yazılmadı.

## Tekrar üretme

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8912 --bind 127.0.0.1 --directory build/web
DBW_URL=http://127.0.0.1:8912 DBW_TOUCH=1 node tests/browser_book.cjs
DBW_URL=http://127.0.0.1:8912 node tests/browser_result_pad.cjs
DBW_URL=http://127.0.0.1:8912 node tests/browser_forge.cjs
```

Kanıtlar yerel work/v010 içindedir. Browser testleri yalnız gerçek girdi gönderir; ?qa salt okunurdur. Kayıtlar sentetiktir, oyuncunun gerçek kaydı değiştirilmez. GitHub CI ve Vercel üretimi bu yerel testin aynısı diye varsayılmaz.
