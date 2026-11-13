# Drive-By Wire 0.9.0 · doğrulama

13 Kasım 2026. Godot 4.6.3; izole fixture kayıtları, localhost ve taze Chromium bağlamları. Gerçek donanım veya insan eğlence testi yapılmış sayılmaz.

| Kapsam | Sonuç | Kanıt / sınır |
|---|---|---|
| Native regresyon | PASS | 25 takım, 2188 kontrol. 13 yol için 26 gerçek çatışma ve 13 novel bölümü tamamlandı. İkinci bölümde boss bekleyen eski test, açık kullanıcı talebine uygun değişti; ilk/son boss çarpışma testleri korunur. |
| Yeni sahne, kayıt, sprite ve araçlar | PASS | 184 kontrol: iki font/beş boyutta tüm diyalog kelimeleri, 44 px eylemler, portre/metin ayrımı, sabit zemin, altı ayrı oynayan yaralı karesi, mola, checkpoint, tek seferlik tamamlama, üç araçta gerçek sprite/fizik/namlu hizası. |
| Son web paketi: tam hikâye | PASS | Gerçek girdilerle araç seçimi/reload, ilk boss, yarış/tuzak/yaralı Emre, yön değişiminde mola, replik checkpoint’inden reload, kurtarma seçimi, son boss ve e01 epilogu/galeri tamamlandı. İlk/son etap can126/155, düşman10/9, ikmal5/6. İki robotun iki fazı, dört çatışma biyomu; epilog10 sabit sayfada okundu ve reload geçti. Runtime hatası yok. |
| Altı web düzeni | PASS | PC, telefon/tablet iki yön, düşük güç telefon; native font/Lexend gerçek ayar seçimi, HUD ölçümü, sabit garaj pikselleri, joystick/bağımsız parmaklar, mola/günlük ve Gamepad API regresyonu. |
| Web gamepad | PASS | Gerçek ilk boss ve araç seçimi, analog ile novel kurtarma tercihi, A ile üçüncü bölüme geçiş; fare kullanılmadı. Son pakette can126, 400m, 9 düşman; kurtarma sözü ve üçüncü karar ekranı. Emüle Gamepad API’dir. |
| Son web paketi / dokunmatik novel | PASS | Gerçek dokunma olaylarıyla bağımsız joystick/eylem parmakları, Mühür-01 ve iki faz, dikey→yatay güvenli mola/devam; can55, 400m, 8 düşman. Sonra mobil novelde yarış, tuzak, yaralı Emre, intikam sözü ve üçüncü karar ekranı tamamlandı. Runtime hatası yok. |
| Mobil alan karşılaştırması | PASS | Aynı 390×844 Chromium/düşük render koşulunda 360×640 oyun alanı: yol dokunma bölgesi y196/h270 → y166/h300. Yükseklik +%11,1. Yazı fontları korunur; sadeleştirilen yatay HUD’da gereksiz hız tekrarları kaldırıldı. |
| Normal mod 60 FPS / Canvas OS fontu | FAIL | Önceden gözlenen yazılım renderer performansı ve OS font erişimi sınırı kapanmadı; bu sürüm yeni bir 60 FPS ölçümü iddia etmez. |
| Fiziksel Xbox/telefon/tablet, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Tarayıcı emülasyonu gerçek cihaz yerine geçmez. |
| İnsan anlatı/denge/görsel kalite, ekran okuyucu/WCAG, enerji/bellek | NOT TESTED | Otomatik kabul insan değerlendirmesi veya sertifika değildir. |
| Canlı 0.9.0 yayını (bu kaynak raporu hazırlanırken) | NOT TESTED | GitHub main ve Vercel sürüm/commit/PCK yayın makbuzunda ve PR açıklamasında ayrıca doğrulanır. Önceki 0.8.0 yayını Vercel günlük kotasıyla engellenmişti; yeni kaynak eski canlı sürümün güncellendiği anlamına gelmez. |

İlk adayda yeni sahnenin portre minimum boyu yazıyla çakıştı, yatay HUD’ın Web fallback fontu kutuya sığmadı ve yön değişiminde mola eksikti. Bunlar düzeltildi; aynı koşullar ve gerçek ekran görüntüleriyle tekrar PASS. Son mobil sadeleştirme karakterlerin mantıksal alanını değiştirmez.

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8892 --bind 127.0.0.1 --directory build/web
DBW_URL=http://127.0.0.1:8892 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8892 DBW_TOUCH=0 node tests/browser_book.cjs
DBW_URL=http://127.0.0.1:8892 node tests/browser_result_pad.cjs
DBW_URL=http://127.0.0.1:8892 node tests/browser_touch_boss.cjs
```

`?qa` yalnız okur. Browser testleri oyun durumuna veya kayda değer yazmaz. Native fixture’lar durum/çarpışma kurallarını ayrıca yalıtarak dener; oynanan yol testleri can, fizik veya hasarı değiştirmez. Kanıtlar yerel `work/v090` içinde; son kaynak/paket/canlı durumları yayın makbuzunda ayrılır.

Son paket üzerinde iki eşzamanlı otomatik oynanış denemesi araç kaybıyla bitti ve FAIL olarak saklandı. Tek başına dokunmatik tekrar aynı oyun değerleriyle PASS oldu. Bir ilk dokunma sürücüsü denemesi zaten bırakılmış parmağa tekrar TouchEnd gönderdi; sürücü idempotent bırakmayla düzeltildi. Bunlar oyun canını/hasarını değiştiren test hileleriyle aşılmadı. Aynı paketin tek başına tam hikâye tekrarı da can126/155 ile PASS oldu.

İlk iki GitHub temiz Linux koşusu yatay mobil mayın etiketinin farklı sistem fontunda görseli büyüttüğünü yakaladı (her koşuda free_drive 4 FAIL). Yalnız etiketi kısaltmak yeterli değildi; aşağıdaki geçici büyüme kök nedeni ayrıca yerelde yeniden üretildi. İki satırlı cooldown yerine sabit tek satırlı “MAYIN” etiketi kullanılır; dokunma alanı küçültülmez ve metin kırpılmaz. Sınırsız/basılı mayın davranışı değişmez. İlgili test başarısız olursa artık düğmenin minimum/gerçek/hedef ölçülerini de yazar. Düzeltmenin temiz CI sonucu PR/yayın makbuzunda ayrıca kaydedilir.

Font hatası yerelde DejaVu Sans ile yeniden üretildi: etiket kısaldığında minimum boy45×24’e inerken görsel65/66×44 kalıyordu; hedef64×44 idi. Kaynak neden, aynı güncellemede önce uzun sonra kısa etiket atamasıydı. Son etiket tek kez atanır ve görsel gerçek dokunma alanına yeniden oturur. Kalıcı regresyon DejaVu Sans ve Noto Sans ile iki cooldown durumuna 4 yeni kontrol ekler; eski sınır assertion’ları korunur.

Yatay dokunmatik büyütmede ön robotun ekran sınırlarıyla geçici bildirimin çakıştığı native transform testiyle doğrulandı. Geçici bildirim daha küçük sol yan alana taşındı; aynı yerdeki sürüş ipucu bildirim süresince saklanır. Yeni görünüm testi robot/başlık/bildirim sınırlarını gerçek ölçek ve konumla karşılaştırır. Fizik konumları değişmez.
