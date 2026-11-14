# Drive-By Wire 0.13.3 · Emre sahne ölçeği

14 Kasım 2026. Taban public main f40e3a97e66d/0.13.2. Fragaria Unslop uygulandı; güncel canlı AIONIA belgesi v1.7, aynı revizyon. Bu sürüm yalnız ilk yol kenarı ara sahnesinde yaralı Emre’nin uniform ölçeğini 0.375 → 0.28 indirir: yaklaşık %25.33 küçülme. Yeni çizim yoktur. Önceki okunurluk bulguları, ilk FAIL kanıtları ve sonuçlar [0.13.2 arşivinde](history/QA-v0132.md) korunur.

| Kontrol | Sonuç | Kanıt / sınır |
|---|---|---|
| Sanatın korunması | PASS | Emre, Aion ve Eren’in PNG dosyaları tabanla bit düzeyinde aynı. Aion/Eren’in bütün sahne verileri, Emre’nin hücreleri/temasları/world/klipleri aynı. Yalnız Emre scale ve açıklaması değişti. work/v0133/art-preservation.json. |
| Native Godot 4.6.3 | PASS | Mevcut 30 takım / 2232 kontrol / 0 hata; road_story, görsel temaslar, sabit kökler, altı yaralı kare, ekran yönleri ve önceki metin/giriş regresyonları. work/v0133/native.log. |
| Web export | PASS | Gerçek Godot export tamamlandı, 0.13.3 immutable giriş üretildi. work/v0133/build.log. |
| Masaüstü normal oyun | PASS | Gerçek klavye/fare girdileriyle iki 400m/boss, bütün ara sahne adımları, kayıtla devam, Devam edecek/reload. Runtime hatası 0. work/v0133/full-keyboard/linear-results.json. |
| Küçültülmüş sahnenin görünümü | PASS | Masaüstü1280×720, telefon390×844 ve844×390 görüntüleri incelendi. Aynı resmin eşit XY ölçeği; zemin teması korunur. İlk ara sahnede dikey→yatay→dikey güvenli mola/devam, metin fittingi ve normal dokunma doğrulandı. work/v0133/full-touch/emre-landscape.png ve emre-portrait-restored.png. |
| Tam dokunmatik akış | PASS | Sabit joystick/ateş/mayın ile iki400m/boss ve iki ara sahne, ilk ve ikinci ara sahnede yön değişimi, Devam edecek/reload. Runtime hatası0. work/v0133/full-touch/linear-results.json. |
| CI / production | NOT TESTED | Hazırlama sırasında yayın bekleniyor. Exact head/base, CI, merge ağaç eşitliği, Vercel deployment/alias, canlı version/asset ve gerçek oynama sonucu PR/yayın makbuzunda ayrıca kaydedilir. |
| Fiziksel cihaz / insan değerlendirmesi | NOT TESTED | Fiziksel telefon/tablet/Xbox, diğer tarayıcılar ve insan estetik/oynanış değerlendirmesi yapılmadı. Chromium dokunmatik/Gamepad API emülasyonu fiziksel test değildir. |
| Önceki performans / OS-font sınırları | FAIL | Önceden açık FPS ve Canvas sistem-font dosyası sınırları bu ölçek değişikliğiyle kapanmış sayılmaz. Yeni performans ölçümü yoktur. |

Tarayıcı akışları normal menü/girdi kullanır; HP/RNG/konum/kayıt setter’ı yoktur. Küçük ölçek değişikliğini aynalayan yeni test eklenmedi; mevcut anlamlı sahne ve tam oyun regresyonları çalıştırıldı. Telefonun ilk ara sahnede iki yönde kontrolü mevcut akışın ignored work/v0133/touch-review.cjs kopyasıyla yapıldı. Kaynak sanat, ayarlar, kontrol şeması ve hikâye değişmedi.

Tekrar: GODOT=godot bash tests/run_all.sh; GODOT_BIN=godot python3 packaging/build_web.py; DBW_INPUT=keyboard|touch|pad ile tests/browser_linear.cjs. Rollback kaynak f40e3a97e66d/0.13.2.
