# Drive-By Wire 0.7.3 · gerçek doğrulama

PASS çalıştırılmış kapsam; FAIL karşılanmayan hedef; NOT TESTED denenmeyen kapsam. Godot4.6.3 korunur. Önceki ayrıntılar [QA-v072](history/QA-v072.md) içinde.

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 1150 kontrol,0 başarısız;21 takım. Eski kayıt,13×3 fizik etabı,sabit karakterler,joystick ve sınırsız mayın kontrolleri tekrar çalıştı. |
| Sonuç ekranı regresyonu | PASS | Önceki kodda analog sağ sonucu değiştirmedi; düzeltmeden sonra açık odak komşuları doğru düğmeyi seçti. Yeni InputEvent testi analog X/Y,D-pad,portre yerleşimi,odak kaybından dönüş,A ile Garaj/sonraki bölüm/başarısızlıkta yeniden deneme. |
| PC eylemleri | PASS | Yeni25 kontrolün içinde iki fare düğmesini birlikte tutma,aynı anda WASD,sağ fareyle tekrarlanan mayın,HUD üstünde bırakma,molada iki tutulmanın temizlenmesi. Shift gerçek alan etkisini başlatır ve yalnız yakın mermileri temizler;R sıyrılır. Özel atama sanitizasyonu korunur. |
| Gerçek gamepad-only web etabı | PASS | Tarayıcı Gamepad API emülasyonu;ana menü→rota→gerçek400m çatışma→sonuç→analog/D-pad iki seçenek→A ile sonraki bölüm. Can105,düşman9,ikmal5;runtime hata yok. Fare,klavye veya oynanış setter kullanılmadı. Fiziksel Xbox testi değildir. |
| Altı web düzeni | PASS | Chromium PC,telefon/tablet dikey-yatay,düşük güç telefon. Sağ fare mayın/Shift/R;mevcut joystick/çoklu dokunma,mola/ayarlar,karakter piksel sabitliği ve Gamepad API temel akışı. |
| Web build ve yardım | PASS | Import/parse/export;varsayılan eşlemeler native ve HTML yardımda. Canvas contextmenu engeli;erişilebilir HTML yardım tuval dışında korunur. Yeni runtime bağımlılığı yok. |
| Normal mod60FPS /Canvas OS fontu | FAIL | Önceki hedef/sınırlar kapanmadı;performans bu sürümde yeniden ölçülmedi. |
| Fiziksel gamepad/telefon/tablet,Safari/iOS,Firefox Android,titreşim | NOT TESTED | Emüle gamepad ve browser viewport gerçek donanım değildir. |
| İnsan ergonomi/denge,tam ekran okuyucu/WCAG,toplam bellek/enerji | NOT TESTED | Otomatik geçiş insan değerlendirmesi veya sertifika değildir. |
| Tam üç etaplı web hikâyesi /eski önbellek migration | NOT TESTED | Bu yamada yeniden çalıştırılmadı;gerçek ilk web etabı ve tüm native son yolları ayrı kapsamda doğrulandı. |

## Yeniden üretim

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_result_pad.cjs
```

NODE_PATH mevcut Playwright kurulumuna göre verilir. Kanıt work/tests-v073-publish.log,work/evidence-v073-final ve work/evidence-v073-pad. QA yalnız okur;Gamepad API mock yalnız cihaz girdisi yazar. UI tıklamaları ve fizik gerçek oyun kodundadır.

Canlı yayın ayrıca version.json/sürüm/commit/giriş,indirilen PCK hash'i,HTTP başlıkları ve girişsiz PC/dikey/yatay oturumlarda fare/Shift/gamepad akışlarıyla kontrol edilir. Kesin yayın sonucu ayrı kayıttadır;yerel PASS canlı PASS anlamına gelmez.
