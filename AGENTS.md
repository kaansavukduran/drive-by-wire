# Drive-By Wire · çalışma kuralları

Mevcut Godot 4.6.3/GDScript altyapısını kullan. Yeni oyun motoru veya framework geliştirme. AIONIA referans kapsamı docs/AIONIA_CURRENT_REFERENCE.md; yeni evren/karakter tasarımları kesin kanon sayılmaz.

Mobil/tablet kontrol şemasını değiştirmeden önce tür, kamera/hareket modeli, temel eylemler, tek/çift el ergonomisi, ekran yönleri ve hedef cihazları incele. En uygun 2–4 tarzı avantaj/dezavantajlarıyla sırala, birincil öneriyi belirt ve kullanıcının seçimini sor. Açık onay gelmeden şemayı değiştirme.

12 Kasım 2026 güncel açık seçim (0.7.0): kullanıcı serbest dört yönlü sürüş için **sabit sanal joystick + eylem düğmeleri** önerisini açıkça seçti. Önceki sağa/sola kaydırma kararı bu yeni oyun mekaniği için değişti. PC oklar/WASD ile XY hareket, E turbo/Q fren, fare; gamepad sol çubuk/D-pad, RB turbo/LT fren. Ön silah öne ateş eder; mayın aracın arkasından bırakılır. Hareket, animasyon pivotu, silah/mayın çıkışı ve hitbox aynı fizik koordinatlarını kullanmalı; render veya sprite alpha sınırından fizik merkezi üretilmez. Ayrıntı docs/CONTROLS.md.

Dikey/yatay yönler, çoklu dokunma, odak kaybı ve yeniden boyutlandırmayı test et. Gerçek oyuncu kaydına yazmamak için bash tests/run_all.sh kullan. Web uçtan uca testi tests/browser_forge.cjs; geliştirme araçları yalnız test bağımlılığıdır. ?qa yalnız salt okunur yerel tarayıcı durumudur, oynanışa değer yazdırma.

Sonuçları PASS / FAIL / NOT TESTED raporla. Fiziksel cihaz, yardımcı teknoloji veya insan eğlence testi yapılmadıysa yapılmış gösterme. Eski prototip Android anahtarı Git geçmişinde açıktır; yeni dağıtımda kullanılmaz. Tam geçmişi başka yere aktarmak ayrıca açık kullanıcı izni gerektirir; güncel kaynak teslimiyle karıştırma.

Garaj sahnesi: Aion ve Ömer ayrı sabit zemin alanlarında, ortak ayak pivotuyla durur. Kaydı yapılmamış farklı gövde pozları boşta döngüye eklenmez; diyalog/yükseltme/hazırlık metni veya animasyon saati karakterin alanını değiştiremez. Ekran yönünden dönüşte aynı zemin işaretleri geri gelmelidir. tests/test_garage_stage.gd ve tarayıcıdaki gerçek karakter piksel karşılaştırmasını koru.

0.7.3 PC açık kullanıcı isteği: yol alanında fare sol öne ateş, fare sağ basılı sınırsız arka mayın; Shift alan darbesi, R sıyrılma. X/C alternatifleri ve özel atamalar korunur. Etap sonu düğmelerinde açık dört yön/Tab odak komşuları ve analog/D-pad/A ile fare gerektirmeyen geçiş zorunlu; test_result_input.gd ve gerçek 400m browser_result_pad.cjs regresyonlarını koru.


0.7.4 metin yerleşimi: sabit HUD kutuları minimum içerik boyuyla komşu alanlara büyüyemez. Uzun konuşmaları TextFit ile gerçek font/fallback, genişlik, StyleBox iç boşlukları ve satır aralığına göre sayfala; metni kırparak kaybetme. Tam metin mola günlüğünde kalmalı. Konuşan kişinin adı/portresi eşleşmeli, bitmiş replik font/ekran değişiminde yeniden görünmemeli. test_hud_text.gd ve browser_book.cjs içindeki bildirilen Ömer repliği regresyonunu koru.


0.8.0: Son/galeri, yardım, günlük ve ayar içeriği tekerlek gerektirmeyen sabit sayfalar kullanır. Her sayfanın gerçek metin yüksekliğini ve komşu alanlarını test_paged_ui ile denetle; yalnız kutuyu kırpmak yeterli değildir. Oyun içeriği için yeni ScrollContainer ekleme. Godot’un yerleşik PopupMenu/ConfirmationDialog iç düğümleri bununla karıştırılmaz. Robot hedefleri uyarıdan sonra kilitli kalır; kozmetik çizim, efekt tercihi ve viewport fizik konumunu veya saldırı RNG’sini değiştiremez. test_boss_encounters ve gerçek çatışma yollarındaki boss-defeated kontrolünü koru.

0.9.0 açık kullanıcı talebi: ikinci bölüm çatışma yerine seçimli sohbet, yan yana dostça yarış, tuzak ve Emre’nin yaralandığı sahnedir. 13 yol için 26 çatışma ve 13 novel bölümünü oyna; ikinci bölümde boss bekleyen eski varsayımı sürdürme. Onaylı sürüş kontrolleri değişmez. Yeni araçlar aynı hitbox ve pivotu kullanır. Yeni sahnelerde portre/metin/44 px eylem alanlarını, kayıtla devamı ve sabit zemin pivotlarını test_road_story ile koru.

0.11.0 açık kullanıcı kararı: bu oyunun her Forge/kalite aşamasında mevcut Fragaria Unslop becerisini kullan. Ayrıntılı pixel-art tüm ana oyun yüzeylerinde ortak olmalı; ayrıntı karakteri olgunlaştırmaz. Paftadaki oran, yüz, tür, renk, kıyafet ve işaretler esas. Görsel kök/silah/hitbox/yol koordinatlarını ayırma; aynı görünür destek ve sabit temas testlerini koru. Yüksek çözünürlüklü atlasın ham piksel sınırı yerine gerçek dönüştürülmüş ekran sınırlarını doğrula.

0.12.0 son açık kullanıcı kararı önceki 13 son / ikinci bölüm novel düzenini değiştirir: 13 etaplık lineer plan; bu sürümde iki çatışma etabı ve her birinin ardından bir ara sahne. İlk ara sahne Emre/Eren, ikinci ara sahne Kurt’un yandan çarpıp Aion’u uçurumdan kurtarması, teşekkür/pert araba/yeni araba sözü. Ardından Devam edecek; 3–13 oynanabilir diye sunulmaz. Sohbet seçimleri yalnız konuşmayı değiştirir, rota/istatistik/son açmaz. Eski kayıtlar arşivlenerek geçer, ayar/araç/puan korunur. Kompakt paneller metni küçültmeden ve 44px eylemleri kaybetmeden sayfalanır.
