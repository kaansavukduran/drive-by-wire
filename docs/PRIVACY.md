# Yerel veri ve güvenlik

Drive-By Wire hesap, reklam SDK'sı, analitik veya LLM/API kullanmaz. Oyun kodu rekoru, MOMO güven/hafızasını, yükseltmeleri, bölüm tamamlama/rota durumunu ve tercihleri Godot `user://save.json` içinde saklar. Web sürümünde bu alan tarayıcının yerel IndexedDB deposudur. `save.json.bak` önceki geçerli kayıt, `.tmp` tamamlanmamış yazımdır. Web düşük güç açılış tercihi ayrıca aynı origin'in `localStorage` alanındaki `dbw.low_power` anahtarında tutulur. Başka sitelerle paylaşılmaz.

Ayarlar → Veri → Sıfırla, onay sonrasında bu üç oyun kayıt dosyasını ve düşük güç tercihini kaldırır. Tarayıcı depolamasını temizlemek de web ilerlemesini silebilir. Yerel kayıt şifreli değildir; bu cihazı/tarayıcı profilini kullanan kişi okuyabilir. Kayıtta kişisel kimlik veya ödeme bilgisi istenmez. Sıfırlama, dosya sisteminde adli düzeyde geri getirilemez silme garantisi değildir.

Web oyununun dosyaları barındırıcıdan indirilir. Barındırıcı kendi ağ erişim kayıtlarını tutabilir; bu oyun içi telemetri değildir. Paket aynı origin'den font ve oyun verisini yükler; üçüncü taraf CDN yazı tipi veya takip isteği yoktur. Yerel QA FPS/yükleme sayaçları DOM'a yazılır, ağla gönderilmez.

Kayıt okuyucu 512 KiB üstünü reddeder, sayısal/anahtar sınırları uygular, bozuk ana dosyada yedeğe döner. Yeni şema sürümündeki dosya eski sürüm tarafından üzerine yazılmaz. Yedek alma veya rename hatası önceki ana kaydı silmez. İşletim sistemi elektrik kesintisi ve tüm depolama aygıtı arızası için tam dayanıklılık iddiası yoktur.

Vercel yapılandırması nosniff, no-referrer ve kullanılmayan kamera/mikrofon/konum/ödeme API kısıtları içerir. Üretimde bu başlıkların gerçekten uygulandığı henüz doğrulanmadı. Godot JavaScriptBridge kullandığından test edilmemiş katı bir CSP eklenmedi.

Android CI artık herkese açık prototip anahtarına dönmez. Sahibe ait gizli imza verileri ve `DBW_ANDROID_SIGNING_READY=true` olmadan Android job atlanır; çok platformlu yayın kapısı tamamlanmaz. Eski prototip anahtarı Git geçmişinde ve eski paketlerde hâlâ herkese açıktır; kaldırma geçmişi veya eski APK'ları güvenli imzaya dönüştürmez. Yeni anahtar eski prototip kurulumunun üzerine güncelleme yapamaz. Gerçek yeni anahtar kurulumu/mağaza yayını bu çalışmada yapılmadı.

`?qa` açık test bayrağıyla tarayıcıya salt okunur sahne/odak hedefi/oynanış durumu anlık görüntüsü yazılır. Kontrol testi içindir; ağ gönderimi veya oyun durumunu dışarıdan değiştirme yolu değildir. Normal açılışta kapalıdır.
