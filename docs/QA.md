# Drive-By Wire 0.8.0 · doğrulama

PASS çalıştırılmış kapsam; FAIL karşılanmayan hedef; NOT TESTED denenmeyen kapsam. Yerel test canlı yayın anlamına gelmez. Önceki sonuçlar [QA-v074](history/QA-v074.md) içinde.

| Kontrol | Sonuç | Gerçek kapsam / sınır |
| --- | --- | --- |
| Native regresyon | PASS | 1988 kontrol, 0 başarısız; 24 takım. 13×3 oynanan hikâye yolunda boss yenildi. Yeni boss44 kontrol ve sayfalı UI466 kontrol (gerçek analog sağ/sol sayfa girdileri dahil); kayıt/joystick/arka mayın/karakter konumu/gamepad sonuç regresyonları tekrar geçti. |
| Sonlar kitabı ve menü geometrisi | PASS | Bütün 13 son, iki font ve dört viewportta her sayfanın gerçek Label yüksekliği ölçüldü. Kelimeler korunur; portre, metin, sayfa gezinmesi ve alt eylemler ayrı alanlarda. Galeri dört sabit sayfada13 girdiyi erişilebilir tutar. Yardım/günlük/ayarlar tekerlek gerektirmeyen sayfalar kullanır. Godot’un yerleşik açılır seçimlerinin iç ScrollContainer düğümleri oyun içeriği sayılmaz; ana ayar kategorilerinin tamamı PagedSettings’tir. |
| Gerçek üç etaplı web hikâyesi | PASS | Son yapıda klavye/fare ile üç robotun iki fazı ve altı biyom gözlendi. Can89/107/130; düşman7/7/8; ikmal9/5/7. e07 epilogu sekiz sabit sayfada okundu; Ömer metni, galeri/portre dönüşü ve reload geçti. Robotun önü HUD altında, arka fazı gerçek mayının arming mesafesinde; renkli portre ve arka yön işareti doğrulandı. Runtime hata yok. |
| Altı web düzeni | PASS | Chromium PC, telefon/tablet dikey-yatay, düşük güç telefon. Lexend gerçek ayarlardan seçildi; fare eylemleri, joystick/bağımsız parmaklar, mola/günlük, sabit karakter pikselleri, Gamepad API akışı geçti. |
| Son web paketi / gamepad boss | PASS | Import/parse/export geçti. Gamepad API ile gerçek400m ve Mühür-01: can115,düşman7,ikmal6; analog/D-pad/A sonuç akışı geçti. Gerçek dokunma girdileriyle joystick/eylem parmakları, ilk boss ve dikey→yatay güvenli mola/devam: can38,düşman6. Runtime hata yok. |
| Normal mod60FPS / Canvas OS fontu | FAIL | Önceki yazılım renderer sınırı ve gerçek OS fontuna erişim kısıtı kapanmadı; bu sürümde performans yeniden ölçülmedi. |
| Fiziksel Xbox/telefon/tablet, Safari/iOS, Firefox Android, titreşim | NOT TESTED | Emülasyon gerçek donanım değildir. |
| İnsan okunabilirlik/denge/anlatı, tam ekran okuyucu/WCAG, bellek/enerji | NOT TESTED | Otomatik test insan değerlendirmesi veya sertifika sayılmaz. |
| Canlı0.8.0 yayını | NOT TESTED | Sürüm/commit/PCK ve gerçek yeni oturumlarla ayrıca doğrulanır. Önceki Vercel günlük yayın kotası kaynak hatası sayılmaz; eski sürüm yeni özelliklerin kanıtı değildir. |

İki ilk dokunma botu koşusu araç kaybıyla bitti. Sürücünün parmak bırakma/yeniden basma akışı, tam joystick sapması, mayına kısa dokunup ateşe dönüş ve uyarıdan kaçış davranışı düzeltildi; son koşu PASS. Oyun canına, ölümsüzlüğe veya kayda değer yazılmadı. Bu sonuç insan oyuncu denge testi yerine geçmez.

## Yeniden üretim

```sh
GODOT=godot bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8877 --directory build/web
DBW_URL=http://127.0.0.1:8877 node tests/browser_forge.cjs
DBW_URL=http://127.0.0.1:8877 DBW_BOOK_PATH=1,1,0 DBW_ENDING=e07 DBW_TOUCH=0 node tests/browser_book.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_result_pad.cjs
DBW_URL=http://127.0.0.1:8877 node tests/browser_touch_boss.cjs
```

QA yalnız okur. Native boss fixture’ları çarpışmayı yalıtarak dener;13×3 oynanan hikâye yolları ve browser testleri fizik, can, cephane ve hasarı değiştirmez. Kumanda menü testi bitmiş çatışma fixture’ını kullanır; bu bir oynanmış boss savaşı diye raporlanmaz. Tüm boss karşılaşmaları ayrıca gerçek atış/mayın/uyarılarla tamamlanır. Kanıtlar work/v080 içinde; kesin yayın makbuzu ayrı tutulur.
