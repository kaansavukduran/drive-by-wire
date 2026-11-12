# Drive-By Wire 0.7.0 · gerçek doğrulama raporu

Godot 4.6.3 korunur. PASS çalıştırılmış kapsam, FAIL karşılanmayan hedef, NOT TESTED denenmeyen kapsamdır. Yeni karakter portreleri ve Üçüncü Nabız anlatısı OYUN/TASLAK; ana evren kanonu onayı iddia edilmez. Önceki yayın raporu [QA-v062](history/QA-v062.md), güncel standart kapsamı [AIONIA_CURRENT_REFERENCE](AIONIA_CURRENT_REFERENCE.md).

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 878 kontrol, 0 başarısız; 17 takım. Her takım geçici XDG dizininde, parse/script hatası başarısız sayılır. Son atlas ve odak düzeltmesiyle yeniden çalıştırıldı. |
| 13 son / kayıt uyumu | PASS | 13×3 gerçek fizik etabı. Eski son kimlikleri, kayıt kurtarma, etaba dönüş ve bitirilen sonların korunması. Bot direksiyon/cephane/hasar kurallarını kullanır; teleport, ek HP veya ölümsüzlük yoktur. |
| Serbest sürüş / konum regresyonu | PASS | 58 kontrol: dört yön, normalize çapraz hız, durunca kaymama, dört sınır, yeniden boyutlandırmada sabit fizik konumu, sekiz araç hücresinde ortak pivot, öne silah/arkaya mayın. Arka mayının erken temizlenmesi düzeltildi. |
| Dokunma sahipliği | PASS | Sabit merkez, deadzone, bağımsız ateş parmağı, mola/odak/yön değişiminde bırakma. Turbo ve mola çakışması giderildi. Fiziksel dokunmatik ekran testi değildir. |
| PC / telefon / tablet tarayıcı akışı | PASS | Chromium gerçek klavye/fare/CDP touch; 1280×720, 390×844, 844×390, 768×1024, 1024×768 ve düşük güç telefon. Joystick+ateş, ters çapraz hareket, mayın, HUD/eylem sınırları, ayarlar/günlük ve yön değişimi. Tablet seçim odağının kaydırma alanında görünmesi ayrıca doğrulanır. |
| Gamepad API | PASS | Emüle analog/D-pad, A, RB/RT, Start/B, kopunca mola ve yeniden bağlanınca otomatik sürmeme. Fiziksel Xbox testi değildir. |
| Tam web hikâyesi | PASS | Gerçek klavye/fareyle üç 400 m etap. Kurt, Kuzu, Baykuş Ömer, Tavşan Emre ve Omega-3 konuşmaları; yanıt ve bölüm desteği. Etap sonunda can 20/52/60, düşman 5/9/5, ikmal 4/5/6. e01, dokunmalı sonlar kitabı ve reload kalıcılığı. QA yalnız durum okur; oynanışa değer yazmaz. |
| Yanıt / ilişki | PASS | Her bölümde tek yanıt; tekrar ödül toplama engeli. Yedi saniye kalkan veya bir mayın desteği; bağlara göre kişisel kapanış. |
| Önbellekli eski sürümden geçiş | PASS | Aynı Chromium profili/origin üzerinde uzun önbellekli 0.6.1 fixture'ından 0.7.0 sürümlü JS/WASM/PCK'ya geçiş. Gerçek garaj güven kaydı 54 ve IndexedDB save.json birebir korundu; localStorage korundu. Kullanıcının telefonundaki kesin eski sürüm nedenini kanıtlamaz. |
| Güncelleme bildirimi | PASS | Test manifesti yeni commit sunduğunda bildirim; yalnız düğmeyle geçiş ve mola sırasında sabit mesafe. Kayıt/veri temizleme yapılmaz. |
| HTML yardım / %200 metin | PASS | Odak ve yatay taşmadan akış; açılınca mola, kapanınca molada kalma. Canvas için tam ekran okuyucu erişimi değildir. |
| Normal mod 60 FPS hedefi | FAIL | Chromium SwiftShader, fiziksel GPU yok: 20/21/18 FPS, medyan 20. Donanım performansı sonucu değildir. |
| Düşük güç 30 FPS ara hedefi | PASS | Aynı yazılım ortamı: 41/44/42 FPS, medyan 42. 640×360 tampon; fiziksel donanım garantisi değildir. |
| Açılış / JS heap | PASS | Ölçülen 3234/2067 ms; JS heap 12.2/9.9 MB. Yalnız JS kısmıdır; toplam WASM/GPU belleği veya kontrollü A/B kazancı iddiası yoktur. Runtime hata ve üçüncü taraf istek listesi boş. |
| Pixel atlas / dosya hacmi | PASS | İki atlas toplam 131244 byte; hücre bazında nearest import. Orijinaller korunur. Araç 8×64×96, portreler 6×64×64; beş portre statiktir, animasyon diye sunulmaz. |
| Varsayılan koyu / native sistem fontu / HTML system-ui | PASS | Paylaşılan tema, ayar kaydı ve native görünüm regresyonu. |
| Web Canvas gerçek OS font ailesi | FAIL | Tarayıcı OS font dosyalarını Godot'a açmaz; gömülü yedek kullanılır. |
| Firefox Linux otomatik açılış | NOT TESTED | BLOCKED: Firefox 144.0.2 bu headless ortamda WebGL2 sunamadı. Yükleyici WebGL2 gereksinimini açıkça gösterdi; oynanış doğrulanmadı. |
| Fiziksel mobil/tablet, Firefox Android, Safari/iOS, Xbox/titreşim | NOT TESTED | Donanım ve ilgili gerçek tarayıcılar mevcut değil. |
| İnsan eğlence / denge / anlatı | NOT TESTED | Otomatik etapların tamamlanması insan değerlendirmesine eşdeğer değildir. |
| Tam ekran okuyucu / WCAG AA / toplam bellek ve enerji | NOT TESTED | Kontrast, şekil ve semantik HTML yardım kontrollerinin ötesinde sertifikasyon iddia edilmez. |
| Yeni imzalı native kurulum | NOT TESTED | Bu teslim web yayınıdır; beş platformda kurulum testi yapılmadı. |

## Yeniden üretim

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_book.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_quality.cjs
node tests/browser_update.cjs
```

Playwright yalnız geliştirme/test aracıdır; runtime bağımlılığı değildir. NODE_PATH mevcut kuruluma göre verilir. Yerel kanıtlar `work/evidence-v070-final`, `work/evidence-v070-story`, `work/evidence-v070-compact`, `work/evidence-v070-update` altındadır; geçici URL/özel oturum bilgisi public kaynakta yoktur.

Canlı dağıtım ayrıca `/version.json` commit/sürüm/giriş, indirilen PCK hash'i, HTTP başlıkları ve yeni oturumlarda PC/dikey/yatay gerçek girdilerle kontrol edilir. Yerel PASS tek başına canlı PASS anlamına gelmez. GitHub PR ve Vercel yayın sonucu ayrı yayın kaydında raporlanır.
