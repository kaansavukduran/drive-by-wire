# Drive-By Wire 0.7.4 · gerçek doğrulama

PASS çalıştırılmış kapsam; FAIL karşılanmayan hedef; NOT TESTED denenmeyen kapsam. Godot 4.6.3 korunur. Önceki sonuçlar [QA-v073](history/QA-v073.md) içinde. Yerel test canlı yayın anlamına gelmez.

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 1439 kontrol, 0 başarısız; 22 takım. Eski kayıtlar, 13×3 fizik etabı, sabit karakterler, joystick, sınırsız mayın ve gamepad sonuç seçimi tekrar çalıştırıldı. |
| Yeni metin regresyonu | PASS | 288 kontrol: dört viewport, system/Lexend, dokunma açık/kapalı ve klavye/gamepad. Bütün hikâye telsizleri, kullanıcının bildirdiği Ömer repliği ve uzun paragraf. Gerçek Label satır yükseklikleriyle bütün sayfaların sığması, kelimelerin korunması, konuşan kişi/portre, günlük, molada okuma süresi, biten repliğin yeniden boyutlandırmada geri gelmemesi, HUD/görev/enerji ve sonuç düğmesi ayrımı. |
| Gerçek üç etaplı web hikâyesi | PASS | Chromium klavye/fare girdileriyle archive→seal→garden, gerçek 3×400 m çatışma. Can 78/125/95; düşman 8/9/5; ikmal 8/6/7. Bildirilen Ömer repliği görüldü, sayfalar alana sığdı, statü alanı ayrı kaldı. e07 sonu ve reload sonrası kayıt PASS; runtime hata yok. Bu test son garaj ölçüm değişikliğinden önce, aynı HUD koduyla yapıldı. |
| Altı web düzeni / font değişimi | PASS | Chromium PC, telefon/tablet dikey-yatay ve düşük güç telefon; görünür HUD metinleri alana sığdı. Ayarlardan gerçek Lexend seçimi, joystick/çoklu dokunma, fare ateş/arka mayın/Shift/R, mola/günlük ve Gamepad API akışı geçti. Garaj karakter pikselleri beklemede aynı kaldı; runtime hata yok. Bu yapıdan sonraki tek runtime değişikliği, süresi biten repliğin yeniden boyutlandırmada geri gelmesini engeller; native regresyonu ayrıca PASS. |
| Web import/parse/export | PASS | Godot Web export üretildi. Yeni runtime bağımlılığı yok; ölçüm Godot TextParagraph ile mevcut font/fallback ve satır aralığını kullanır. |
| Normal mod 60 FPS / Canvas OS fontu | FAIL | Önceki sınırlar kapanmadı; performans bu yamada yeniden ölçülmedi. Web Canvas gömülü font yedeği kullanır. |
| Fiziksel Xbox/telefon/tablet, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Chromium viewport ve Gamepad API emülasyonu gerçek donanım değildir. |
| İnsan ergonomi/denge, tam ekran okuyucu/WCAG, bellek/enerji | NOT TESTED | Otomatik geçiş insan değerlendirmesi veya sertifika değildir. |
| Dokunarak sonlar galerisi / eski önbellek migration | NOT TESTED | Bu yamada tam hikâye masaüstü işaretçiyle tamamlandı; önceki testler bunun yerine sunulmaz. |
| Yeni sürümün canlı yayını | NOT TESTED | Kaynak ve yerel web doğrulandıktan sonra aynı Vercel projesinde denenir. Önceki dağıtımlar günlük derleme kotasına takıldı; canlı sürüm ayrıca version.json ile doğrulanır. |

## Yeniden üretim

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8877 DBW_BOOK_PATH=1,1,0 DBW_ENDING=e07 DBW_TOUCH=0 node tests/browser_book.cjs
```

NODE_PATH mevcut Playwright kurulumuna göre verilir. Native kanıt work/tests-v074-complete.log; web kanıt work/evidence-v074-release ve work/evidence-v074-book-final. QA yalnız okur; oyun fiziğine değer yazılmaz. Tam kaynak commit/giriş/PCK hash'i ve yayın sonucu ayrı sürüm makbuzunda tutulur.
