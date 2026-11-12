# Drive-By Wire · 0.5.0

**Fragaria Interactive · Fragaria Games · AIONIA**

MOMO ile distopik otoyolda 1.200 metrelik kuşatmayı aş. Ok tuşlarıyla sür, turboyu doğru anda kullan, takipçileri savuştur ve ikmalleri topla. MOMO artık sürüş kararlarını geciktirmez; ruh hali, güveni ve garaj hafızası yol arkadaşlığını sürdürür.

## Oyna

Ana menüde **Sürüşe başla / Space** ile Eve Giden Yol bölümüne gir. Yol öncesinde destek veya ikmal tercihini yap; seçim can/mayın desteğini, hedefini ve bölüm sonunu değiştirir. Mola menüsündeki Yol günlüğü diyalogları saklar. **Nasıl oynanır?** hedefi ve kapsülleri açıklar. **Önce garaja uğra** ile MOMO'ya 1–4 üzerinden cevap verip yükseltme seçebilirsin.

| Tuş | İşlev |
| --- | --- |
| Sol / Sağ ok veya A / D | Anında bir şerit değiştir |
| Yukarı ok veya W (basılı) | Enerji tüketerek turbo |
| Aşağı ok veya S (basılı) | Fren |
| Space veya F (basılı) | En yakın tehdide, arka dahil, tekrarlanan ateş |
| X | Arkaya mayın bırak |
| Shift | Bekleme süreli sıyrılma |
| C | MOMO'ya destek ve enerji; 8 saniye bekleme |
| Esc veya P | Mola / devam |
| T | İsteğe bağlı sohbet; Enter gönderir, Esc kapatır |

Kumandada sol analog veya D-pad şerit, yukarı/RB turbo, aşağı/LT fren, A/RT ateş, X mayın, B/LB sıyrılma, Y destek, Start mola. Menülerde yönler, A onay, B geri; ayarlarda LB/RB sekme değiştirir. Tuşlar ve düğmeler yeniden atanabilir; analog ölü bölgesi ayarlanabilir. Yazılım olaylarıyla akış testlidir; fiziksel kumanda henüz doğrulanmadı.

Telefon/tablette **yol üzerinde sağa/sola kaydırarak** tek şerit değiştir. Eylem düğmeleriyle ateş, turbo, fren, mayın, sıyrılma ve destek kullan. Ayrı parmakla ateşe basılıyken kaydırabilirsin. Dikey ve yatay düzenler vardır; döndürünce güvenli mola verilir. Mola menüsünden dokunmatik kontroller elle açılır. Bu şema kullanıcının açık seçimidir; virtual joystick uygulanmadı.

PC'de oklar/WASD yanında yol alanında fare sol basılı ateş, fare sağ sıyrılmadır. Menüler fareyle kullanılır; tıklama sürüş komutu yazdırmaz.

**Kapsüller:** Artı onarım, şimşek enerji + bir mayın, kalkan tek darbeye koruma verir. Renk yanında şekiller farklıdır. Kalkan en fazla 7 saniye sürer. Düşmanları yenmek, kapsülleri toplamak ve başarılı kaçışlar seri puanı kazandırır; hasar veya seriye katkı olmadan 5 saniye geçmesi seriyi sıfırlar. Kısa görevler puan, onarım ve mayın kazandırır. 1.200 metrede sefer başarıyla biter. Sonuçta Enter ile yeniden sür, G ile garaja dön.

Otomatik ateş, düşük güç web modu, titreşim, ses düzeyi, ses kapatma, ekran sarsıntısı ve dekoratif hareket ana menüden veya mola ekranından ayrı ayarlanabilir. Tercihler, rekor, güven ve garaj hafızası yereldir. Ayarlar → Veri ile onay sonrasında sıfırlanabilir. Bozuk kayıt önceki geçerli yedekten kurtarılır. Odak kaybında veya kumanda ayrılınca mola verilir. Hesap, reklam, telemetri, LLM/API bağlantısı yoktur.

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

**Önizleme durumu:** İşlev testleri geçiyor; bulut yazılım renderer ortamında 60 FPS hedefi sağlanmadı. Fiziksel hedefler ve üretim yayını henüz doğrulanmadı. Ayrıntılar QA raporunda.
 HTML dosyasına çift tıklamak yeterli değildir. [Sürüm ve platform durumu](docs/RELEASE.md) · [Güncel AIONIA referansı](docs/AIONIA_CURRENT_REFERENCE.md) · [Kontrol kararı](docs/CONTROLS.md) · [Hikâyeli bölüm](docs/JOURNEY.md) · [Tasarım incelemesi](docs/DESIGN_BRIEF.md) · [Mahremiyet](docs/PRIVACY.md) · [Sanat kılavuzu](docs/ART_BIBLE.md) · [Test sonuçları](docs/QA.md) · [Forge kaydı](docs/FORGE.md) · [Derleme](docs/BUILD.md) · [Vercel](docs/VERCEL.md).

`Releases/latest` önceki 0.1.0 paketlerini gösterebilir; bu dalın paketleriyle aynı değildir.

## Kaynaklar

- `data/balance.json`: sürüş, düşmanlar, turbo, kapsül, görev ve puan dengesi.
- `scripts/core/arcade.gd`: sahneden bağımsız puan, seri, görevler.
- `scripts/game/controls.gd`, `touch_control.gd`: klavye, analog/D-pad, yeniden atama ve çoklu dokunma.
- `scripts/core/`: MOMO, garaj, isteğe bağlı ayrıştırıcı ve kayıt.
- `scripts/game/main.gd`: sefer, çatışma, HUD ve mola.
- `scripts/game/sounds.gd`: yerel üretilen özgün kısa sesler.
- `assets/`, `tools/art/`: mevcut piksel çizimler ve kaynak kayıtları.
- `packaging/`, `export_presets.cfg`, `.github/`: derleme profilleri.
