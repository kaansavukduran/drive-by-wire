# Drive-By Wire 0.7.1 · gerçek doğrulama

PASS çalıştırılmış kapsam, FAIL karşılanmayan hedef, NOT TESTED denenmeyen kapsamdır. Godot 4.6.3 ve onaylı sabit joystick korunur. Önceki sürümün ayrıntıları [QA-v070](history/QA-v070.md) içinde; onun sonuçları bu sürümde yeniden yapılmış sayılmaz.

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 1049 kontrol, 0 başarısız; 19 takım. Gerçek geçici XDG kayıtları, script/parse hata denetimi. 13×3 fizik etabı, eski kayıtlar ve 13 son korunur. |
| Sürücü ve ortak pivot | PASS | Yeni sekiz karede Aion'un başının arkası görülür, direksiyon/eller aracın önündedir. Araba tamamen ters çevrilmedi. Hücre gövde merkezi, sprite ve hitbox konumu bütün pozlarda doğrulandı; ortak pivot (32,43.5). İnsan sanat onayı değildir. |
| Sınırsız arka savunma | PASS | 11 yeni kontrol: eski cephane sıfır olsa da bırakma, aynı kare spam engeli, mola sırasında donan bekleme, basılı X ile tekrar, sınırlı aktif nesne, gerçek arka takipçiye hasar ve mermilerin temizlenmesi. Oyuncuya patlama hasarı yok. |
| Küçük ekran / bütün karar düğümleri | PASS | 10 düğüm ×4 sayfa ×4 viewport =160 kontrol: 640×360, 360×640, 360×780, 640×480. Kontroller ve metin ölçümleri ekrana sığar; eylemler en az44 mantıksal piksel. İçerik gizlenip yalnız kaydırma çubuğu kapatılmadı; uzun günlük Sonraki sayfa ile bölünür. |
| Gerçek web kontrol akışı | PASS | Chromium PC, telefon dikey/yatay, tablet dikey/yatay ve düşük güç telefon; klavye/fare/CDP çoklu dokunma. Konuşma/Yanıt/Rota/Günlük sayfalarına dokunarak geçiş, görünür kontrollerin ekran/içerik sınırları, joystick+ateş, ters hareket, sınırsız mayın, mola/ayarlar/yön değiştirme. Gamepad API ayrıca emüle edildi. Fiziksel cihaz değildir. |
| Tam web hikâyesi | PASS | Gerçek tuş/fareyle üç 400 m etap; beş karakterin konuşması, yanıt seçimi, rota ve etap geçişi; sonlar kitabı ve reload kalıcılığı. Etap sonu can 93/40/110, düşman 7/11/10, ikmal 6/5/7; runtime hata listesi boş. QA salt okunur, oynanışa değer yazmaz. |
| Eski mayın yükseltmesi / rotalar | PASS | Kayıt alanları korunur. Eski bonuslar sınırsız mayının soğumasını kısaltır; başlangıç cephanesi ifadesi UI'da kaldırıldı. İkmal/görev beklemeyi sıfırlar. |
| Native/web derleme | PASS | Yeni kaynakla Godot import/parse, web export ve sahne açılışı. Playwright yalnız test aracıdır; runtime bağımlılığı eklenmedi. |
| Normal mod 60 FPS hedefi | FAIL | 0.7.0 SwiftShader medyan20 FPS sonucu giderilmiş sayılmaz. Bu sürümde performans ölçümü yeniden yapılmadı. |
| Web Canvas OS font ailesi | FAIL | Gömülü font yedeği sınırı devam ediyor. HTML system-ui ayrıdır. |
| Fiziksel mobil/tablet/Xbox, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Tarayıcı emülasyonu gerçek cihaz testi yerine sunulmaz. |
| İnsan eğlence/denge, tam ekran okuyucu/WCAG, toplam bellek/enerji | NOT TESTED | Otomatik koşu insan değerlendirmesi veya erişilebilirlik sertifikası değildir. |
| 0.7.1 eski önbellekten migration / Firefox Linux | NOT TESTED | 0.7.0 kayıt/önbellek geçişi ayrı arşivde; Linux Firefox WebGL2 engeli orada kayıtlı. Bu iki test bu yamada yeniden çalıştırılmadı. |

## Tekrarlama

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_book.cjs
```

NODE_PATH mevcut Playwright kurulumuna göre verilir. Yerel kanıtlar work/tests-v071-final.log, work/evidence-v071-final ve work/evidence-v071-story dizinlerinde. İlk sürümdeki yanlış etiket ve render taşması son testten önce giderildi. İlk başarısız denemeler final PASS diye sunulmaz.

Canlı GitHub/Vercel yayını ayrıca version.json commit/giriş, indirilen PCK hash'i, HTTP başlıkları ve yeni girişsiz PC/dikey/yatay tarayıcı oturumlarıyla doğrulanır. Kesin commit ve dağıtım sonucu ayrı yayın kaydında tutulur; yerel test tek başına canlı başarı sayılmaz.
