# Drive-By Wire 0.4.0 · AIONIA önizlemesi

Fragaria Interactive · Fragaria Games · AIONIA

MOMO ile 1.200 metrelik otoyol seferi: oklarla doğrudan sürüş, turbo/fren, ateş, mayın, sıyrılma, destek ve puan/görev döngüsü. Mevcut Godot altyapısı ve karakter çizimleri korunur. Komut yazmak zorunlu değildir.

0.4, erişilebilir kontrol ve güvenilir yerel deneyime odaklanır: analog çubuk/tetikleyici ve A/B menü eşlemeleri, klavye/pad düğmesi yeniden atama, ölü bölge, otomatik ateş, titreşim tercihi; Oyun/Kontroller/Veri sekmeleri; onaylı sıfırlama; yedekten kayıt kurtarma; yanlışlıkla seferden ayrılmayı önleyen onay. Webde semantik yardım ve isteğe bağlı düşük güç modu vardır. Android CI herkese açık prototip imzasına geri dönmez.

Verilen resmî standart okundu: kaynak erişim anında v1.2 başlığını taşıyor; istenen v1.1 evrensel kalite kuralları ve ilgili güncel oyun maddeleri uygulandı. Onaysız karakter/logo kesinleştirilmedi.

390 otomatik kontrol ve Chromium masaüstü/dokunma/kontrolcü taklidi testleri PASS. Düşük güçte yazılım renderer akıcılığı artar; normal modda 60 FPS hedefi FAIL. Fiziksel cihazlar, Safari, tam ekran okuyucuyla oynama, gerçek Android sahip imzası ve üretim yayını NOT TESTED. Ayrıntılı ölçümler ve kapsam [QA.md](QA.md) içindedir.

Web ZIP'ini çıkartıp klasöründe `python3 -m http.server 8765` çalıştır; `http://localhost:8765` aç. HTML dosyasına çift tıklamak yeterli değildir. Kaynak ZIP'i Godot 4.6.3 projesidir; git bundle geçmişi taşır. Eski paketler ayrı sürümler olarak korunur. Main birleştirme/üretim yayını yapılmadı.
