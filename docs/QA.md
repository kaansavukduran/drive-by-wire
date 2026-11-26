# Drive-By Wire 0.17.0 · Forge inceleme adayı

Başlangıç GitHub `main` ve Pages `0.16.0` (`3551b72619ee`). Eski yayın, yerel doğrulama ve platform sınırları [0.16.0 QA arşivinde](history/QA-v0160.md).

| Alan | Sonuç | Kanıt |
| --- | --- | --- |
| Native Godot 4.6.3 | PASS | 33/33 takım, 2.427/2.427 kontrol. |
| Yerel Web release export | PASS | Godot 4.6.3. Chromium `156.0.8078.79` masaüstü, dikey ve yatay yükleme. 30 saniye WASM beklemesi ve PCK hata/yeniden dene akışı. |
| Chromium yerleşimleri | PASS | Masaüstü, telefon dikey/yatay, tablet dikey/yatay ve düşük güçlü telefon. |
| Klavye | PASS | İki savaş ve iki ara sahne. Mühür-01 ve Yankı-02 dörder kez saldırdı. Tek replik atlandı ve kurtarış sırasında yenileme doğru adıma döndü. Son regresyon, zafer animasyonunda mesafenin 400 m’de kaldığını denetler. |
| Dokunmatik | PASS | İki savaş ve iki ara sahne. Mühür-01 dört, Yankı-02 altı kez saldırdı. Toplu replik atlamada yarış ve tuzak oynadı. Kurt’un dünya noktası dönüşte korundu. Kapanış yeniden açıldı. |
| Emüle gamepad | PASS | İki savaş ve iki ara sahne, kumandayla okuma, mücadele ve kapanış. |
| Tehdit uyarıları | PASS | Gerçek arka giriş, saldırı hedefi ve ilerleme, mola sırasında sabit kaldı. |
| Müzik | PASS | Chromium oturumlarında üç paketlenmiş OGG kaynağı kullanıldı. Native kaynak testi dosyaların açıldığını doğruladı. [Lisans ve kaynaklar](../THIRD_PARTY_NOTICES.md#music). |
| Fiziksel cihaz, gerçek dinleme ve oyuncu kabulü | NOT TESTED | Tarayıcı girdi emülasyonu ve ses kaynağının oynatılması otomatik kanıttır. |
| GitHub Pages üretim yayını | 0.16.0 | `0.17.0` [taslak inceleme dalında](https://github.com/kaansavukduran/drive-by-wire/pull/21). |

## Web performansı

Aynı Linux Chromium SwiftShader ortamı, 1280×720 tarayıcı alanı, düşük güç 640×360 render. Her sahne için gerçek klavye akışına yayılan beş 600 ms örnekleme penceresi. Değerler milisaniyedir.

| Sahne | 0.16.0 p95 / p99 | 0.17.0 p95 / p99 | 50 ms üzeri kare önce / sonra |
| --- | --- | --- | --- |
| Cam Ormanı | 16,8 / 33,3 | 16,8 / 33,4 | 1 / 2 |
| Mühür-01 | 16,8 / 33,3 | 16,8 / 33,3 | 0 / 0 |
| Buzlu Arşiv | 16,8 / 33,4 | 16,8 / 33,3 | 0 / 1 |
| Yankı-02 | 16,8 / 33,3 | 16,7 / 16,8 | 0 / 1 |
| Kurt’un kurtarışı | 16,7 / 16,8 | 16,8 / 16,8 | 0 / 0 |

Ayrı açılış ve yeniden sürüş koşusunda soğuk açılış 2.896 → 2.474 ms, menü p95 33,4 → 33,4 ms. İki sürüm de aynı tarayıcı belgesi içinde beş ardışık yeniden sürüşü tamamladı. Sürüşte ayrılmış WASM belleği her tekrarda 69,73 MB kaldı. Adayın tekrarlarındaki JS heap 13,78–17,33 MB arasında değişti. PCK 30,59 → 32,37 MB oldu. Uçurum parçasını 12 saniyeye indirmek ilk aday PCK’sından 1,28 MB çıkardı. Bunlar bu ortama ait ölçümlerdir.

0.16.0’ın ilk tekrarlı yükleme koşusunda kapanmış yükleme katmanına ilerleme olayı ulaştı. 0.17.0 geç olayı durduruyor. Adayın yenileme ve yükleme kurtarma kontrollerinde aynı hata gözlenmedi.

Yeniden doğrulama için Godot 4.6.3 ile `bash tests/run_all.sh`, Web export için `GODOT_BIN=godot python3 packaging/build_web.py`. Yerel HTTP sunucusuna karşı `DBW_INPUT=keyboard|pad|touch node tests/browser_linear.cjs` ve `node tests/browser_perf.cjs`.
