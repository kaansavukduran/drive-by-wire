# Drive-By Wire 0.7.2 · gerçek doğrulama

PASS çalıştırılmış kapsam, FAIL karşılanmayan hedef, NOT TESTED denenmeyen kapsamdır. Godot 4.6.3 korunur. Önceki ayrıntılar [QA-v071](history/QA-v071.md) içinde; arşiv sonuçları bu sürümde yeniden çalıştırılmış sayılmaz.

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 1125 kontrol, 0 başarısız; 20 takım. Eski kayıt, 13×3 fizik etabı, dört yönlü kontrol, sınırsız arka mayın ve önceki yerleşim kontrolleri dahil. |
| Garaj karakter konumu | PASS | 68 yeni kontrol. Ana menü ve garajda dört viewportta zaman ilerlemesi/hareket açık-kapalı karakter konumunu veya sprite bölgesini değiştirmez. Tam hücre kendi alanına sığar; UI ile alanlar çakışmaz. |
| Aşamalar ve yön değişimi | PASS | Diyalog → yükseltme → hazır geçişlerinde aynı ayak işaretleri. Dikey/yatay dönüşten sonra aynı konumlar. Aynalama merkez etrafında yapılır. |
| Uzun garaj konuşması | PASS | Bütün altı prompt ve uzun hatırlama selamı gerçek font ölçüsüyle sayfalanır; metin kesilmez. İleri yalnız konuşma sayfasını değiştirir; karakteri, seçim aşamasını veya güveni değiştirmez. |
| Altı gerçek web düzeni | PASS | Chromium PC, telefon/tablet dikey-yatay ve düşük güç telefon. Oyunun normal menüsünden garaj; iki saniye arayla karakter alanının PNG pikselleri birebir aynı. Gerçek tıklamalarla diyalog/yükseltme/hazır konumları eşit; telefon yönünden dönüşte aynı alanlar. Sürüş/joystick/ateş/mayın/mola/ayarlar ve Gamepad API emülasyonu da kontrol edilir. |
| Web derleme | PASS | Yeni kaynakla import/parse, sahne açılışı ve export. Yeni runtime bağımlılığı/görsel üretimi yok; eski atlas değişmedi. |
| Normal mod 60 FPS / web Canvas OS fontu | FAIL | Önceki yazılım renderer hedefi ve font sınırı giderilmiş sayılmaz. Bu sürümde performans ölçümü yeniden yapılmadı. |
| Fiziksel telefon/tablet/Xbox, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Tarayıcı emülasyonu fiziksel cihaz testi değildir. |
| İnsan eğlence/denge, tam ekran okuyucu/WCAG, toplam bellek/enerji | NOT TESTED | Otomatik sonuç sertifika veya insan değerlendirmesi değildir. |
| Tam üç etaplı web hikâyesi / eski önbellek migration | NOT TESTED | Bu garaj yamasında yeniden oynatılmadı. Önceki gerçek sonuçlar arşivde; native 13×3 fizik yolları bu sürümde tekrar çalıştı. |

## Yeniden üretim

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
```

NODE_PATH mevcut Playwright kurulumuna göre verilir. Native kanıt work/tests-v072-publish.log; web kanıtı work/evidence-v072-final. ?qa salt okunur durumdur; test oyuna değer yazmaz. Başarısız ilk uzun metin ölçümü final PASS diye sunulmaz; ölçüye göre sayfalama ile düzeltildi.

Canlı yayın ayrıca version.json sürüm/commit/giriş, indirilen PCK hash'i, HTTP başlıkları ve yeni girişsiz PC/dikey/yatay oturumlarda gerçek garaj pikselleri/tuş/dokunmayla kontrol edilir. Kesin yayın commit ve dağıtım sonucu ayrı yayın kaydındadır. Yerel test tek başına canlı PASS değildir.
