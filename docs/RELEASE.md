# Drive-By Wire 0.3.0 · AIONIA önizlemesi

Fragaria Interactive · Fragaria Games · AIONIA

Ok tuşlarıyla doğrudan sürüş, ön/arka tehdide basılı ateş, turbo/fren, mayın, sıyrılma, MOMO desteği, kapsüller, puan serileri ve 1.200 m başarı döngüsü korunur. Yeni açılış menüsü hedefi ve ilk kontrolleri gösterir; Nasıl oynanır ekranı ve isteğe bağlı garaj vardır.

Bütün ana düğmeler ve paneller ortak piksel çerçeveli stil kullanır. Ana menü ve molada aynı ayarlar açılır: ses aç/kapat, ses düzeyi, kamera sarsıntısı ve dekoratif hareket. Açık/kapalı durumları yazılıdır. Yardım/ayar açıkken arkadaki düğmeler devre dışıdır. Dokunma hedefleri büyütüldü; iki parmakla ateş ve turbo birlikte kullanılabilir. Simülasyon Godot'un 60 Hz fizik adımındadır; render FPS'i bundan bağımsızdır.

Resmî AIONIA başlangıç belgesi, standart v1.0, çilek referansı ve 18 karakter görseli incelendi. Kaynak özetleri ve onay durumları kayıtlıdır. Mevcut karakter çizimleri korunur; onaysız varyant veya resmî logo icat edilmez. Tavşan Emre sprite kaynağı doğrulanmadığından yeni animasyonu eklenmedi.

## Test ve yayın

[QA raporu](QA.md) PASS / FAIL / NOT TESTED durumlarını verir. 330 headless kontrol; Chromium masaüstü/dokunma akışı; Web Audio başlangıcı; yükleme hatasında yeniden deneme doğrulandı. Yazılım grafik ortamında 60 render FPS hedefi sağlanmadı. Bu açık performans eksikliği nedeniyle tam yayın kapısı geçilmiş sayılmaz.

Web ZIP'i üretildi. Çıkartıp o klasörde `python3 -m http.server 8765` çalıştır; `http://localhost:8765` aç. HTML dosyasına çift tıklamak yeterli değildir. Kaynak ZIP'i Godot 4.6.3 projesidir. Git bundle tam geçmişi taşır. Eski 0.2.0 paketleri ayrı önizlemedir.

Canlı Vercel üretim yayını yapılmadı. Bu çalışma sırasında yeni native Windows/Linux/Android paketi üretilmedi veya fiziksel cihazda denenmedi. Mevcut CI/export profilleri korunur. Fiziksel kumanda/telefon, Safari, insan oyuncu denge testi ve gerçek cihaz FPS/bellek doğrulaması NOT TESTED. Müzik ve tam dil seçimi yoktur; UI Türkçedir. Dikey telefonda oyun alanı küçülür; yatay ekran önerilir.
