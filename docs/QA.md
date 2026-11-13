# Drive-By Wire0.10.1 · doğrulama

13 Kasım2026 · Godot4.6.3 · izole native kayıtları ve taze Chromium/SwiftShader. Önceki kayıt [QA-v0100](history/QA-v0100.md). Bu rapor kaynak hazırlanırkenki yerel sonuçtur; CI ve gerçek canlı dağıtım ayrıca yayın makbuzu/PR’de doğrulanır.

| Kapsam | Sonuç | Kanıt / sınır |
|---|---|---|
| Native regresyon | PASS | 25 takım2218 kontrol.13 yol/26 çatışma/13 novel; yeni14 kaynak pozun opak ayak teması, gerçek Sprite2D kökü/offset/bölgesi; iki font/beş viewport, bütün diyalog kelimeleri,44px eylemler ve portre/metin ayrımı. |
| Referans karşılaştırması | PASS | Aion ana referansı, Emre/Eren modelleme paftası ve0.10.0 karşılaştırıldı. Yuvarlak yüz/büyük göz/kısa gövde-uzuvlar ve özgün giysiler geri geldi. Aion’daki koyu gömlek/pantolon/boyun kartı kaldırıldı. Elle yapılan kapsamlı sanat kontrolüdür; otomatik kanon sertifikası veya kullanıcının nihai estetik onayı değildir. |
| Gerçek yerel web: tam hikâye | PASS | Normal giriş, araç seçimi/reload, ilk/son bossun iki fazı, yarış/tuzak/Eren/kurtarma/kayıt seçimi; e01epilogu11 sayfa, galeri dokunması/reload. Can128/43; düşman8/8; ikmal4/6. Runtime hatası0. |
|14 gerçek animasyon pozu | PASS | Aion0–3, Emre0–5, Eren0–3 sahnede gözlendi. Kaynak temasları yeni çizime göre ölçüldü; tüm döngüler/etkileşimlerde gerçek dünya kökü ve global temaslar sabit. 390×844 yön değişimi/mola ve replik checkpoint reload geçti. Masaüstü/telefon görüntüsü incelendi. |
| Kayıt/kontrol regresyonu | PASS | Native takımda klavye/mouse/gamepad ve çoklu dokunma; yeni kaynakta normal webde seçim/kayıt/yön değişimi. Onaylı kontrol şeması ve kayıt biçimi değişmedi. |
| Bu tur ayrı Gamepad API / altı düzen browser_forge | NOT TESTED |0.10.0’da PASS; bu tur yeniden çalıştırılmadı. Yeni paftaların beş native boyutu ve telefon dönüşü ayrıca geçti. Önceki emülasyon fiziksel gamepad diye sunulmaz. |
| Fiziksel telefon/tablet/Xbox, Safari/iOS, FirefoxAndroid, titreşim | NOT TESTED | Chromium emülasyonu gerçek cihaz değildir. |
| İnsan estetik/oyun dengesi, ekran okuyucu/WCAG, bellek/enerji | NOT TESTED | Kullanıcının yeni kareleri nihai onayladığı veya sertifikalandığı iddia edilmez. |
| Önceki normal yazılım renderer60FPS / Canvas OS fontu | FAIL | Önceki açıklar bu sanat düzeltmesiyle kapanmış sayılmaz; yeni performans/font ölçümü yapılmadı. |
| Yeni CI/canlı sürüm | NOT TESTED | Bu kaynak raporu yazılırken henüz yayınlanmadı; PR/yayın makbuzu gerçek sonraki durumu içerir. |

Yeni regresyon testleri eklenmedi; mevcut214 sahne kontrolü kaynak temaslarını ve gerçek aktör köklerini yeni atlaslarla yeniden denetler. Browser art akışı salt-okunur ?qa ile14 pozun tamamını normal oyun yolunda izler; oyun durumuna değer yazmaz. Kanıtlar yerel work/v0101 içindedir. Son kaynakların orijinal paftaları public depoya eklenmez; yeni oyun uyarlaması PNG ve yöntem/hash kaydı yayımlanır.

Tekrar: GODOT=godot bash tests/run_all.sh; python3 packaging/build_web.py; localhost normal girişinde tests/browser_book.cjs. Yerel ek14-poz gözlem betiği work/v010/browser_production_art.cjs, normal tam hikâye testine yalnız ek bekleme/okuma/assertion ekler.
