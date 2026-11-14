# Drive-By Wire 0.13.2 · okunurluk ve durum koruması

14 Kasım 2026. Taban main b7516c7e5085/0.13.1; yetkili public repo kaansavukduran/drive-by-wire. Canlı AIONIA belgesinin içeriği yeniden okundu: v1.7, aynı revizyon. Kurulu Fragaria Unslop ve Unslop; UI, behavior, game, sprite ve extended kontrolleri uygulandı. Bağlantılı ChatGPT konuşmaları read_thread aracı bulunmadığından okunmuş sayılmaz. Önceki sonuçlar [0.13.1](history/QA-v0131.md), PR18 ve önceki QA arşivlerindedir.

## Bulgular ve kalıcı regresyonlar

| Kimlik | Doğrulanan belirti / neden | Onarım ve kabul |
|---|---|---|
| DBW-HUD-001 | Mevcut test_hud_text tek kutuya sığmayı ölçüyordu; bildirim ve kontrol ipuçlarının ortak alanını kapsamıyordu.0.13.1 gerçek oyun görüntüsünde KALKAN bildirimi kontrol yazılarının üstüne basıyor. Bazı stat metinlerinin rect/gölge alanları da kesişiyor. | Sol HUD satırları ve bildirim ayrı sabit alanlarda. Harf dış çizgisi dahil komşu metinler ayrılır; font küçültülmez, büyük kart eklenmez. Bare dünya metni açık temada da okunur krem/mint/altın ve koyu dış çizgi kullanır; konuşma paneli seçilen temayı kullanır. test_hud_text, yeni test_ui_readability ve ortak browser hud_contract. |
| DBW-READ-001 | Yeniden sayfalama eski sayfa numarasını koruyordu; pencere/font değişince o numara başka kelimelere denk gelip okunmamış metni atlayabiliyordu. Kontrollü native reader testi eski kaynakta FAIL. | Aynı görünür-karakter konumu korunur. Yardım/günlük/son, telsiz, garaj ve ara sahne aynı TextFit yardımcılarını kullanır. Tekrarlanan reflow konumu geri sarmamalı; kelimeler kesilmez, bütün metin erişilir. Tema değişimleri reader'da tek ertelenmiş reflow'da birleşir. |
| DBW-SET-001 | Gerçek web'de Lexend seçimi satır ölçülerini değiştirdi; font seçeneği başka sayfaya taşınıp görünmez oldu. Sayfa index'i düzenlenen kontrolü temsil etmiyordu. | Ayar sayfası odaktaki satırı/öğe kimliğini korur. Native test odak/görünürlük ve açık Sonraki eylemini doğrular. Web testi font seçildikten sonra kontrolün görünür kalmasını, temaya normal gezinmeyi ve kaydedilmiş iki tercihi reload sonrası doğrular. |
| DBW-INPUT-001 | Gamepad ipucu RT/A ve X'i sabit yazıyordu; gerçek özel atama farklıysa yanlış tuş gösteriyordu. | Menü ve HUD ipucu aynı mevcut InputMap atamalarından isim alır. Y/RB native ataması ve gerçek aksiyon eşleşmesi sınanır. Varsayılanlar veya kullanıcının kayıtlı atamaları değiştirilmez. |
| DBW-COPY-001 | Proje/web/Linux açıklamalarında artık var olmayan13son ve eski İLİN adı; garajda eski zorunlu alt marka metni kalmıştı. | Gerçek iki etap/iki ara sahne, Omega-3 ve Fragaria Interactive adıyla uyumlu açıklamalar.13etap planı ve3–13'ün henüz oynanmadığı bilgisi korunur. Paket kimlikleri/kayıt yolları değiştirilmez. |

## Gerçek test matrisi

| Kapsam | Durum | Kanıt / sınır |
|---|---|---|
| Eski kaynakta odaklı regresyon | FAIL | İlk işlevsel okunurluk koşusu132 kontrolde 33 FAIL:32metin alanı kesişmesi ve1okuma konumu. İlk test dosyasının yerel Skin sınıf adı hatası düzeltilmiş, ürün hatası diye sayılmamıştır.0.13.1 gerçek oyun görüntüsü work/v0131/production-hatch/keyboard-open.png aynı sorunu gösterir. |
| Son native Godot4.6.3 | PASS |30 takım / 2.232 kontrol / 0 hata. Yeni ui_readability 208 kontrol; iki tema/font, dört viewport, iki giriş ailesi ve klavye/pad durumları, metin/dış çizgi sınırları, tam fitting, okunan kelime/konum, ayar satırı/odak ve doğru özel gamepad ipucu. |
| Altı gerçek web düzeni | PASS |1280×720,390×844,844×390,768×1024,1024×768 ve düşük güç telefon. Çilek yükleyici, garajın sabit gerçek pikselleri, görünür düğmeler, ipuçları, joystick/çoklu parmak, ayarlar ve günlüğe gerçek giriş; runtime hatası 0. |
| Görünüm ve kalıcılık | PASS | Masaüstünde gerçek ayarlardan Lexend + açık tema seçildi; düzenlenen font satırı görünür kaldı, normal reload sonrası iki tercih korundu. Açık temalı gerçek HUD görüntüsü incelendi. |
| Okurken yön değişimi | PASS | Telefonda günlüğün sonraki sayfasına gerçek dokunma, dikey→yatay→dikey, aynı kelime/karakter konumu ve tam fitting. Dokunmatik girişler dönüşte temizlenir; native telsiz/garaj konumu da sınanır. |
| Tam klavye/fare akışı | PASS | İki 400m/boss fazları, iki ara sahne, Kurt dört pozu, teşekkür adımında reload, Devam edecek ve tekrar açılış.135/135 can, runtime hatası 0. Normal oyun boyunca HUD fitting/komşu alanlar örneklenir. |
| Tam son dokunmatik | PASS | Yalnız sabit joystick/ateş/mayın ile iki 400m/boss fazları, iki ara sahne, dört Kurt pozu, dikey→yatay güvenli mola/devam, Devam edecek/reload.133/105 can, runtime hatası 0. Güçlendirilmiş metin fitting/komşu alan kontrolleri oynama boyunca çalışır. |
| Canlı gamepad akışı | NOT TESTED | Production yayımlandıktan sonra ayrı doğrulanır; PR/yayın makbuzu gerçek sonucu içerir. Önceki sürüm sonucu taşınmaz. |
| Eski mekanik/konum regresyonları | PASS | Sabit biyom/uzak arka spawn, araç/garaj pivotları, dört yön/ateş/mayın, sınırsız mayın, iki etap/lineer kayıt ve gerçek kamyon kapısı173kontrol dahil eski native takımlar geçti. |
| Yeni CI / production | NOT TESTED | Kaynak hazırlama sırasında henüz yayımlanmadı. Test kaynağı/ağaç, gerçek version/JS/WASM/PCK, public alias ve canlı oynama PR/yayın makbuzunda ayrı kaydedilir. Rollback0.13.1/b7516c7e5085. |
| Fiziksel cihaz / tarayıcı / erişilebilirlik | NOT TESTED | Fiziksel telefon/tablet/Xbox, Firefox/Edge/Safari/iOS, ekran okuyucu/WCAG, bağımsız yüzde200uygulama/yazı ölçeği, İngilizce tam akış, insan okunurluk/eğlence/estetik ve yeni bellek/enerji ölçümü yapılmadı. Chromium/SwiftShader emülasyonu fiziksel test değildir. |
| Önceki performans/font sınırları | FAIL | Önceden açık FPS ve Canvas OS-font dosyası sınırı bu okunurluk onarımıyla kapanmış sayılmaz. Yeni performans karşılaştırması yoktur. |

İlk altı-düzen koşusunda beş cihaz ve controller PASS, desktop tema adımında FAIL oldu. Testin eski/stale konumdan görünmez tema kontrolüne tıklaması kabul edilmedi; font seçimiyle düzenlenen satırın gerçekten kaybolduğu ortak PagedSettings nedeni düzeltildi. Yeniden test, düzenlenen kontrolün görünürlüğünü zorunlu tutar ve temaya yalnız görünür normal gezinmeyle ulaşır. Kabul koşulları atlanmadı.

Geometri denetimi görünür yazıların rect'ine font dış çizgisini de ekler; yalnız aynı label'ın yüksekliğini ölçmek yeterli sayılmaz. Bilinçli opak modal arkasındaki metin çiftleri çakışma sayılmaz; fitting/bounds kontrolleri korunur. Hiçbir ana bilgi kırpılarak veya font küçültülerek gizlenmedi. Kontrol şeması, varlıklar, hikâye ve gerçek oyuncu verisi korunur; yeni motor/bağımlılık eklenmez.

Kanıtlar ignored work/v0132: readability-baseline.log, readability-first/second/row.log, native-final.log, build-row.log; forge ilk FAIL ve forge-final/forge-results.json, desktop-light-hud.png; full-keyboard ve full-touch/linear-results.json. QA salt okunur. Browser testleri yalnız normal menü/girdi kullanır, oyun/kayıt/HP/RNG/konum setter'ı kullanmaz.

Tekrar: GODOT=godot bash tests/run_all.sh; GODOT_BIN=godot python3 packaging/build_web.py. DBW_URL/DBW_EVIDENCE_DIR ile tests/browser_forge.cjs; DBW_INPUT=keyboard|touch|pad ile tests/browser_linear.cjs. Ortak tests/hud_contract.cjs tam oynama boyunca aynı yazı kabulünü uygular.
