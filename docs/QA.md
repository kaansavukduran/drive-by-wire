# Drive-By Wire 0.11.0 · doğrulama

Godot 4.6.3; izole native kayıtları, taze Chromium/SwiftShader ve normal oyun girdileri. Önceki kayıt: [0.10.1](history/QA-v0101.md). Bu kaynak raporu yerel sonuçları kaydeder; sonraki CI ve canlı dağıtım sonucu PR/yayın makbuzunda ayrıca doğrulanır.

| Kapsam | Sonuç | Kanıt / sınır |
|---|---|---|
| Native regresyon | PASS | 26 takım, 2318 kontrol, 0 hata. 13 yol / 26 çatışma / 13 novel; 214 sahne ve yeni 99 atlas/portre/temas/Omega durum kontrolü. |
| Kaynak/kimlik incelemesi | PASS | Aion ana referansı, Kurt, Kuzu v01, Ömer, Emre ve Eren paftaları ile karşılaştırıldı. Kısa gövde/uzuv, büyük göz, özgün kıyafet/işaretler esas alındı. Omega pusula/bellek tohumu kimliğini korur. Elle sanat incelemesidir; otomatik kanon sertifikası veya kullanıcının nihai estetik onayı değildir. |
| Altı web düzeni ve giriş regresyonu | PASS | 1280×720; telefon 390×844 / 844×390; tablet 768×1024 / 1024×768; düşük güç telefon. Sabit garaj ayakları/alanları ve iki saniye boyunca birebir aynı aktör pikselleri; UI/metin/44px alanlar, WASD/ok, fare ateş/mayın, Shift, çoklu dokunma ve emüle Gamepad API. Runtime hatası 0. |
| Gerçek web tam hikâye | PASS | Gerçek araç seçimi/reload; altı konuşmacı, ilk ve son robotun iki fazı, dört biyom, yarış/tuzak/Eren/kurtarma/mühürlü kayıt; 11 sayfa epilog, galeri dokunması/reload. İlk/son çatışma can 135/155, düşman 11/11, ikmal 5/6. Runtime hatası 0. |
| 14 mevcut yer sahnesi pozu | PASS | Aion 0–3, Emre 0–5, Eren 0–3 normal hikâye sırasında gerçekten gözlendi; dünya kökü ve temas noktaları sabit. Telefon yön değişimi/mola ve replik checkpoint reload geçti. Bu pozlar 0.10.1’den korunur; yeni 55 kaynak hücresi 55 animasyon değildir. |
| Yalnız gamepad ile çatışma ve novel | PASS | Gerçek 400m Mühür-01 zaferi, can 115; analog/D-pad ile sonuç seçimi, A ile geçiş, rescue ve Eren’in shared kaydı, üçüncü karara ulaşma. Fare/oyun durumu yazıcısı yok; tarayıcı Gamepad API emülasyonu, fiziksel Xbox değildir. |
| Dokunmatik boss ve novel | PASS | Sabit joystick + bağımsız eylem parmakları; gerçek 400m, boss iki faz/zafer, can 80; dikey→yatay güvenli mola/devam, telefon novel/yariş/tuzak/intikam sözü ve üçüncü karar. Runtime hatası 0. İlk koşu 285m’de can -5 ile kaybedildi: FAIL zafer kabul koşulu ayrı korunur. Aynı test ve kaynak, oyun/RNG değiştirilmeden tek tekrarda geçti; botun her rastgele karşılaşmayı kazanacağı iddia edilmez. |
| Export ve görsel kaynaklar | PASS | Temiz import / gerçek web export; 11 PNG SHA-256 metadatasıyla eşleşir. Atlas bölgeleri ve gerçek dönüştürülmüş sınırlar doğrulanır. Dört araç gövdesi statiktir; ateş/turbo/hasar efektleri ayrıdır. Yerel PCK yaklaşık 25MB; fiziksel mobil performans ölçümü değildir. |
| Fiziksel cihaz, yardımcı teknoloji ve insan değerlendirmesi | NOT TESTED | Telefon/tablet/Xbox, Safari/iOS/Firefox Android, titreşim, ekran okuyucu/WCAG, insan eğlence/estetik ve bellek/enerji testleri yapılmadı. |
| Önceki normal yazılım renderer 60FPS / Canvas OS fontu | FAIL | Önceden açık sınırlamalar bu sanat değişikliğiyle kapanmış sayılmaz; yeni FPS veya OS font ölçümü yok. |
| Yeni CI / canlı sürüm | NOT TESTED | Kaynak hazırlanırken henüz yayınlanmadı. PR ve yayın makbuzu gerçek sonraki sonucu kaydeder; yerel export canlıyla karıştırılmaz. |

İlk denemelerde temiz import Texture preload hatası ve portre indent parse hatası yakalandı; import sonrası lazy yükleme ve boşluk tutarlılığıyla düzeltildi. Eski, artık kullanılmayan sekiz küçük yeşil araç karesine bağlı test yeni atlasın gerçek imported pivotu / fizik merkezi / hitbox kapsamını sınayacak şekilde güncellendi; aynı 1.1px tolerans, sekiz semantik durumun kök testi ve fizik kuralları korunur. Testteki yerel ad çakışması da düzeltildi. İlk FAIL logları son PASS koşularından ayrıdır.

Kanıtlar ignored work/v011: native-final.log, build-fourth.log, forge/forge-results.json, book/book-browser-results.json, pad/result-pad.json, touch/touch-boss-results.json ve touch-retry/touch-boss-results.json. Normal girdiler dışında oyun durumuna değer yazılmaz. Özel standart/referans paftaları public depoya eklenmez; yeni oyun PNG’leri ve üretim/hash kaydı yayımlanır.

Tekrar: GODOT=godot bash tests/run_all.sh; python3 packaging/build_web.py; tests/browser_forge.cjs, tests/browser_book.cjs, tests/browser_result_pad.cjs, tests/browser_touch_boss.cjs. Tam hikâyedeki ek 14-poz gözlem betiği work/v010/browser_production_art.cjs yalnız bekleme/okuma/assertion ekler. Canlı sürüm ayrıca aynı normal girişten oynanmalıdır.
