# Drive-By Wire · çalışma kuralları

Mevcut Godot 4.6.3/GDScript altyapısını kullan. Yeni oyun motoru veya framework geliştirme. AIONIA referans kapsamı docs/AIONIA_CURRENT_REFERENCE.md; yeni evren/karakter tasarımları kesin kanon sayılmaz.

Mobil/tablet kontrol şemasını değiştirmeden önce tür, kamera/hareket modeli, temel eylemler, tek/çift el ergonomisi, ekran yönleri ve hedef cihazları incele. En uygun 2–4 tarzı avantaj/dezavantajlarıyla sırala, birincil öneriyi belirt ve kullanıcının seçimini sor. Açık onay gelmeden şemayı değiştirme.

12 Kasım 2026 güncel açık seçim (0.7.0): kullanıcı serbest dört yönlü sürüş için **sabit sanal joystick + eylem düğmeleri** önerisini açıkça seçti. Önceki sağa/sola kaydırma kararı bu yeni oyun mekaniği için değişti. PC oklar/WASD ile XY hareket, E turbo/Q fren, fare; gamepad sol çubuk/D-pad, RB turbo/LT fren. Ön silah öne ateş eder; mayın aracın arkasından bırakılır. Hareket, animasyon pivotu, silah/mayın çıkışı ve hitbox aynı fizik koordinatlarını kullanmalı; render veya sprite alpha sınırından fizik merkezi üretilmez. Ayrıntı docs/CONTROLS.md.

Dikey/yatay yönler, çoklu dokunma, odak kaybı ve yeniden boyutlandırmayı test et. Gerçek oyuncu kaydına yazmamak için bash tests/run_all.sh kullan. Web uçtan uca testi tests/browser_forge.cjs; geliştirme araçları yalnız test bağımlılığıdır. ?qa yalnız salt okunur yerel tarayıcı durumudur, oynanışa değer yazdırma.

Sonuçları PASS / FAIL / NOT TESTED raporla. Fiziksel cihaz, yardımcı teknoloji veya insan eğlence testi yapılmadıysa yapılmış gösterme. Eski prototip Android anahtarı Git geçmişinde açıktır; yeni dağıtımda kullanılmaz. Tam geçmişi başka yere aktarmak ayrıca açık kullanıcı izni gerektirir; güncel kaynak teslimiyle karıştırma.
