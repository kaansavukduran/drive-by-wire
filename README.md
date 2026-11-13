# Drive-By Wire · 0.9.0

**Fragaria Interactive · Fragaria Games · AIONIA**

Garajda Aion ve Ömer sabit ayak hizalarında durur; konuşma/yükseltme metinleri karakter alanına taşmaz. Uzun konuşmalar İleri düğmesiyle okunur.

Omega-3 ile Üçüncü Nabız’ı yaşa: iki 400 metrelik çatışma etabı ve bir seçimli yol hikâyesi, üç dallanan karar ve **13 ayrı son**. Direksiyon oklar/WASD, fare, gamepad veya mobilde sabit joystick ile sende. Kararlar kaynakları, trafik baskısını ve geleceğinizi değiştirir.

Sürüşte uzun telsiz konuşmaları ölçülen alana göre otomatik sayfalanır; tam metin mola günlüğünde kalır. Başlık konuşan karakteri gösterir. Konuşma, güven/kalkan durumu, kontrol ipuçları ve enerji bilgileri ayrı alanlarda görünür.

0.9.0: Ana menüden **Yol Arkadaşı, Postacı veya Kuyruklu Yıldız** seç; gövde değişir, sürüş dengesi ve çarpışma alanı aynı kalır. Mobil sürüş panelleri daha az yer kaplar.

**İkinci bölüm: Yan yana.** Emre ile sohbet et, dostça yarışın temposunu seç. Kurulmuş tuzak arabasını patlatınca yol kenarında yanında kal. Verdiğin söz üçüncü bölümün desteğini, bağlarını ve epilogunu değiştirir. Bu bölümde ateş/mayın veya çatışma yoktur. Diyalog kendi hızında, 1/2, Enter/A veya dokunmatik düğmelerle ilerler; aradaki kısa yarış ve patlama animasyonları mola verilebilir. Her replikte kayıt noktası vardır.

İlk ve son etapta **Mühür-01 ve Tasnif-13** yolu keser. Uyarıları izle; robot öndeyken ateş, arkadayken mayın kullan. Yarı canda ikinci faz başlar. Robot durdurulmadan çatışma etabı bitmez. Orta yol Emre’nin dostça yarışı için Cam Ormanı’ndadır.

Son metinleri, sonlar galerisi, oyun yardımı, mola günlüğü ve ayarlar sabit sayfalardadır; tekerlek gerekmez. Metinlerde Önceki/Sonraki veya ←/→; menüde yönler ve A/Enter kullanılabilir. Galeri13 kaydı dört sayfada gösterir. Ayarlarda Önceki/Sonraki veya PageUp/PageDown kullanılır.

## Oyna

Ana menüde **Hikâyeye başla**. Emre, Kuzu, Kurt ve Baykuş Ömer ile telsiz konuşmalarını ilerlet; yanıtını ver, ardından rota seç. Konuşma, yanıt, rota ve günlük ayrı sabit sayfalardadır; bu ekranda kaydırma veya fare tekerleği gerekmez. Yanıtlar ilişkiyi ve etap başındaki kalkan/mayın soğutma desteğini etkiler. Tamamlanan bölüm bir sonraki kararı açar; üç karar **13 ayrı sona** ulaşır. Kaza, yeni bir son açmaz. Önceki etaplar ve kazanılan sonlar korunur.

Telefon/tablette **sabit sol joystick** ile ileri/geri/sağa/sola serbestçe sür. Sağdaki Ateş öne, Mayın arkaya gider. Mayın sınırsızdır; basılı tutunca her 0,7 saniyede bırakılır. Eski yükseltmeler ve ikmal rotaları bu süreyi kısaltır. Mayın patlaması arka mermileri de temizler. Diğer eylemler turbo, fren, sıyrılma ve Omega-3 desteğidir. Dikey/yatay düzen, bağımsız parmaklar ve yön değişiminde güvenli mola vardır.

Etap sonunda analog/D-pad ile iki eylem arasında gezip A ile onaylayabilirsin; fare gerekmez.

PC: **oklar/WASD** sürekli dört yönlü hareket, **Space/F/fare sol** öne ateş, **fare sağ/X** arka mayın, **E** turbo, **Q** fren, **Shift/C** alan darbesi, **R** sıyrılma, **Esc/P** mola. Gamepad: sol çubuk/D-pad hareket, A/RT ateş, X mayın, RB turbo, LT fren, B/LB sıyrılma, Y destek, Start mola. Yeniden atama ve ölü bölgesi ayarı korunur. Sürüş için yazı yazılmaz; T sohbeti isteğe bağlıdır.

Karakter/araç, hitbox, ateş ve mayın aynı fizik konumuna bağlıdır. Aion sürücülü araç atlası sabit gövde pivotu kullanır; Aion ve direksiyon aracın önüne bakar. NPC portreleri kare oranını korur. Saldırı uyarıları, patlama paftaları, ön namlu parlaması ve Omega-3 elektrik darbesi vardır. Destek yakındaki düşman mermilerini temizler. Ses, titreşim, kamera sarsıntısı ve azaltılmış hareket tercihleri korunur.

Koyu varsayılan tema; açık/sistem ve font tercihi, otomatik ateş, düşük güç, bağımsız ses/hareket seçenekleri Ayarlar'dadır. Kayıtlar yereldir. Özel hesap, reklam, analiz veya LLM bağlantısı yoktur. Godot Web Canvas gerçek sistem fontuna erişemediğinden gömülü yedek kullanır. Fiziksel cihaz/gamepad ve insan eğlence testi yapılmış sayılmaz.

## Çalıştır

Godot **4.6.3 standard** ile `project.godot` dosyasını aç ve F5:

```sh
godot --headless --editor --import --quit
godot --path .
bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8765 --directory build/web
```

Web çıktısını `http://localhost:8765` ile aç.

**Doğrulama:** Kapsam ve güncel PASS / FAIL / NOT TESTED / BLOCKED sonuçları QA raporunda. Eski sürümün yayın kanıtı yeni commitin açıldığı anlamına gelmez; canlı sürüm ayrıca kontrol edilir.
 HTML dosyasına çift tıklamak yeterli değildir. [Sürüm ve platform durumu](docs/RELEASE.md) · [Güncel AIONIA referansı](docs/AIONIA_CURRENT_REFERENCE.md) · [Kontrol kararı](docs/CONTROLS.md) · [Hikâyeli bölüm](docs/JOURNEY.md) · [Tasarım incelemesi](docs/DESIGN_BRIEF.md) · [Mahremiyet](docs/PRIVACY.md) · [Sanat kılavuzu](docs/ART_BIBLE.md) · [Test sonuçları](docs/QA.md) · [Forge kaydı](docs/FORGE.md) · [Derleme](docs/BUILD.md) · [Vercel](docs/VERCEL.md).

`Releases/latest` önceki 0.1.0 paketlerini gösterebilir; bu dalın paketleriyle aynı değildir.

0.7.2: sabit garaj karakterleri, ayrı sahne alanları, karakterlerle çakışmayan düğmeler ve ölçüye göre sayfalanan konuşmalar. Omega-3, serbest sürüş, sınırsız mayın ve Üçüncü Nabız korunur. Önceki kayıt kimlikleri ve 13 sonun kimlikleri korunur.

## Kaynaklar

- `data/balance.json`: sürüş, düşmanlar, turbo, kapsül, görev ve puan dengesi.
- `scripts/core/arcade.gd`: sahneden bağımsız puan, seri, görevler.
- `scripts/game/controls.gd`, `touch_control.gd`: klavye, analog/D-pad, yeniden atama ve çoklu dokunma.
- `data/story_book.json`, `scripts/core/story_book.gd`: 13 sonlu seçim kitabı ve bölüm kaydı.
- `scripts/core/`: Omega-3 ilişkisi (eski `momo` kimliğiyle uyumlu), garaj, isteğe bağlı ayrıştırıcı ve kayıt.
- `scripts/game/main.gd`: sefer, çatışma, HUD ve mola.
- `scripts/game/ui_skin.gd`, `appearance.gd`: tek paylaşılan tema, font ve yerel görünüm tercihi.
- `scripts/game/companion_face.gd`: yeni Omega-3 pixel yüzü; OYUN/TASLAK.
- `packaging/web/shell.html`, `loading_screen.gd`: gerçek ilerlemeli Fragaria yükleyiciler.
- `scripts/game/sounds.gd`: yerel üretilen özgün kısa sesler.
- `assets/`, `tools/art/`: mevcut piksel çizimler ve kaynak kayıtları.
- `packaging/`, `export_presets.cfg`, `.github/`: derleme profilleri.

0.6.2: [Güncel oyunu aç](https://drive-by-wire.vercel.app/play/). Kök adres bu girişe yönlenir; oyun dosyaları sürüm ve commit içeren ayrı klasörden gelir. Eski HTML ile yeni PCK karışmaz. Açık oyun sonraki sürümü haber verir; oyuncu düğmeye basana kadar etap yenilenmez. Kayıt silinmez. `main` güncellenince Vercel otomatik dağıtır; GitHub Release gerekmez. Canlı sürüm/commit/giriş adresi `/version.json` üzerinden doğrulanabilir.

0.6.1: görsel ayarlar ve kamera çizim sıklığı trafik/ikmal şansını değiştirmez. Ekran dışına kaçan mermiler temizlenir; arkadaki araçlara ateş hedefe ulaşabilir.
