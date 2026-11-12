# AIONIA kalite raporu · Drive-By Wire 0.6.1

12 Kasım 2026. PASS çalıştırılmış kapsam, FAIL karşılanmayan hedef, NOT TESTED denenmeyen kapsamdır. Godot 4.6.3/GDScript korunur. Fiziksel cihaz veya insan eğlence testi emülasyonla eşdeğer sayılmaz. Standart kapsamı [AIONIA_CURRENT_REFERENCE.md](AIONIA_CURRENT_REFERENCE.md), önceki sonuçlar [0.6.0 raporunda](history/QA-v060.md).

| Kontrol | Sonuç | Kanıt / sınır |
| --- | --- | --- |
| Native regresyon toplamı | PASS | **821 kontrol, 0 başarısız; 16 takım.** Her takım ayrı geçici XDG dizininde. Script/parse hatası başarısız sayılır. |
| Önceki kontrol ve kayıt davranışı | PASS | Parser 110, ilişki 89, garaj/kayıt 72, sefer 15, arcade 32, eski tam sefer 4, başlık 13, kurtarma 18, kontrolcü 32, ayarlar 9, kaydırma/eski bölüm 38. Eski ani ateş varsayımı yeni ön uyarı + ateş davranışıyla güncellendi; saldırı hâlâ gerçek mermi üretir. |
| 13 son ve seçim yolları | PASS | 257 kontrol; her son için üç gerçek fizik etabı, toplam 39. Yeni düşman kurallarıyla yeniden tamamlandı. Teleport, ek HP veya ölümsüzlük yok. Ham sonuçlar story-runs.json. |
| Kitap UI / görünüm | PASS | 32 / 24 kontrol. Üç karar, üç etap, kapanış/sonlar kitabı, yeni hikâyede sonları koruma, başarısızlık ve etabın başından devam. Tema/font kaydı, ok glifleri ve palet kontrastı korunur. |
| Görsel ayarlar altında aynı oynanış | PASS | 44 yeni kontrol. Aynı fizik girdilerinde 60 saniyelik iki gerçek sahne: hareket/sarsıntı kapalı ve açık, farklı dekor seed'leri, fazladan kamera örnekleri. Trafik, mermiler, ikmal, can, puan ve gameplay RNG durumu aynı. Eski kod ilk fizik adımında ayrıştı; before/after logları kanıtta. |
| Uyarı, saldırı ve mermi yaşam döngüsü | PASS | 32 yeni kontrol: ateşten önce süre ve kilitli hedef; ilan edilen yöne gerçek mermi; mola sırasında sabit zaman/işaret; 0.65 sn kamyon hazırlığı, geç kalan engeli iptal; şerit kırma ve tek arka şerit işareti; renk dışı şekiller için ayrı katman. Ekran dışı yatay/düşman mermileri temizlenir; arka takipçiye atış gerçek HP azaltır. |
| PC / telefon / tablet | PASS | Gerçek Chromium klavye/fare/CDP touch. 1280×720; 390×844 / 844×390; 768×1024 / 1024×768; düşük güç telefon. Garaj sınırları, kaydırma+ateş, turbo+ateş, tek hareket/tek şerit, dikey ret, ayarlar/günlük ve yön değişiminde güvenli mola. |
| Gamepad API | PASS | Emüle D-pad/A garaj, konuşma, yükseltme ve karar; analog, RB/RT, Start/B, kopunca mola ve yeniden bağlanınca otomatik sürmeme. Fiziksel Xbox değildir. |
| Tam web hikâyesi | PASS | Gerçek girdilerle üç 400 m etap: 15/16/12 düşman, 6/7/6 ikmal. e01 açıldı; sonlar kitabı dokunmayla kullanıldı ve reload sonrası korundu. |
| Canlı saldırı uyarısı | PASS | Gerçek trafikte arka/şerit kırma/nişan işaretleri gözlendi. Mevcut T sohbet yavaşlatması gerçek tuşla açılarak canlı nişan çizgisi görüntülendi; mola hedef ve ilerlemeyi sabit tuttu. QA yalnız okur, oyuna değer yazmaz. |
| Varsayılan koyu / native font / HTML system-ui | PASS | Native görünüm regresyonu ve gerçek ekran düzenleri. Önceki web görünüm testi 0.6.0 raporunda; bu sürümde o test yeniden çalıştırılmadı. |
| Web Canvas gerçek OS font ailesi | FAIL | Tarayıcı OS font dosyalarını Godot'a açmaz; gömülü font yedeği kullanılır. Sistem fontuyla tam eşleşme iddiası yok. Lexend alternatif, HTML gerçek system-ui. |
| Normal mod 60 FPS hedefi | FAIL | Chromium SwiftShader, fiziksel GPU yok: [21, 20, 18] FPS; medyan **20**. 1280×720. |
| Düşük güç 30 FPS ara hedefi | PASS | Aynı viewport, 640×360 tampon: [41, 38, 38] FPS; medyan **38**. Donanım garantisi değildir. |
| HTML yardım ve %200 metin | PASS | Odak, yatay taşmadan akış, açılınca mola ve kapanınca molada kalma. Tam canvas ekran okuyucu oyunu değildir. |
| Fiziksel cihaz, Safari, gerçek gamepad/titreşim | NOT TESTED | Ortamda donanım yok. Yazılım olayları fiziksel test diye sunulmaz. |
| İnsan eğlence / denge / anlatı | NOT TESTED | 13 otomatik yol ve tam web koşusu insan değerlendirmesi değildir. |
| Tam ekran okuyucu / WCAG AA / toplam cihaz bellek ve enerji | NOT TESTED | Kontrast kontrolleri ve semantik HTML yardım kapsamı ayrı. JS heap toplam WASM/GPU belleği değildir. |
| İmzalı native kurulum / üretim yayını | NOT TESTED | Yeni native kurulum paketi veya main birleşimi yapılmadı. |
| GitHub / Vercel yayını | NOT TESTED | Kullanıcının 12 Kasım açık yayın talebiyle hazırlanıyor. Canlı sürüm, telefon görünümü ve girdiler yayından sonra doğrulanır. Yerel testler uzak test gibi sunulmaz. |

## Yeniden üretim

```sh
bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8765 --directory build/web
node tests/browser_forge.cjs
node tests/browser_warnings.cjs
node tests/browser_book.cjs
node tests/browser_quality.cjs
```

Playwright test aracıdır; runtime bağımlılığı değildir. NODE_PATH mevcut kuruluma göre verilir. ?qa salt okunur snapshot açar. Native fixture'lar kontrollü durumlarda fizik kodunu; web testleri gerçek tuş/fare/dokunma/Gamepad API yollarını kullanır. Kamera/dekor rastgeleliği ayrılması bir render performansı garantisi değildir. Native bitiş yollarının değişen sayıları yeni kanıtta tutulur.

Özel çilek görseli ve referans bağlantıları yerelde korunur. İLİN/hikâye OYUN/TASLAK'tır; nihai logo veya ANA kanon onayı iddia edilmez. Kullanıcı 12 Kasım 2026 son talebinde kaynak ve oyundaki referansların GitHub/Vercel yayınını açıkça istedi. Bu onay yalnız proje yayını içindir; tam Git geçmişini başka yere taşımayı kapsamaz.

Ölçülen açılış 3184 / 2047 ms; önbellek ve VM etkisi olabilir. CDP JS heap 12.2 / 12.3 MB, yalnız JS kısmıdır. Ölçümde üçüncü taraf istek ve runtime hata listeleri boştu. Önceki ölçümle fark kontrollü bir A/B sonucu değildir; FPS artışı iddia edilmez.

Public edition: private Drive/Docs URLs, private strawberry art and its test screenshots are excluded. The running game uses the Fragaria pixel wordmark; gameplay, İLİN and all 13 endings are included. Public deployment is verified separately.
