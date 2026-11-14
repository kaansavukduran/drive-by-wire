# Drive-By Wire · 0.13.2

**Fragaria Interactive · AIONIA**

Omega-3 ile yolu aç, arkadaşlarının sesini dinle. Oyun artık lineer: **1. etap → Emre/Eren ara sahnesi → 2. etap → Kurt’un kurtarışı → Devam edecek.** Sohbet yanıtları konuşmaları değiştirir; rota, combat bonusu veya farklı son açmaz.

**13 etap planlanıyor. Bu sürümde yalnızca ilk iki etap ve iki ara sahne oynanabilir. 3–13 hazır değildir.** Eski 13 son galerisi kaldırıldı; eski kararlar/kazanılmış kayıtlar yerel kayıt arşivinde korunur.

İkinci ara sahnede yol uçurumda kesilir. Kurt soldan gelip Aion’un aracına yandan çarpar, onu kenardan uzaklaştırır. Yanına gelir, iyi olup olmadığını sorar. Aion teşekkür eder; kendi arabası pert olmuştur. Kurt yeni bir araba getireceğine söz verir. Bu sürüm burada biter.

## Oyna

[Güncel web oyunu](https://drive-by-wire.vercel.app/). Ana menü → Hikâyeye başla → üç sohbet yanıtından birini seç → yanıtı oku → Yola devam et. Kazanınca Ara sahneye geç düğmesini kullan. Replikleri kendi hızında ilerlet. Ana menüde Bölümler, hazır içerikle gelecek etapları açıkça ayırır.

- PC: oklar/WASD dört yönlü sürüş; fare sol/Space öne ateş; fare sağ/X sınırsız arka mayın; Esc/P mola.
- Gamepad: sol çubuk/D-pad; RT/A ateş, X mayın; menü/seçimlerde yönler ve A, geri B.
- Telefon/tablet: onaylı sabit joystick + bağımsız eylem düğmeleri. Dikey/yatay oynanış ve yön değişiminde güvenli mola.

Her çatışma 400m; robot durdurulmadan etap bitmez. İlkinde Mühür-01, ikincisinde Yankı-02 vardır. Ölüm aynı etap başına döndürür; önceki ara sahne ve kayıtlar korunur. Ara sahneler replik/animasyon adımını kaydeder; yarım kısa hareket yeniden o adımdan oynar. İkinci ara sahne bittikten sonra yeniden açılış da Devam edecek ekranında kalır. Baştan oynamak açık bir düğmedir.

Kısa aksiyon yazıları gerçek metin yüksekliğine sığar. Normal konuşma kutuları daha dar ve kısa; uzun replikler bilgi kaybetmeden sayfalanır. Dokunmatik eylemler en az 44px kalır. Karakterler sabit kaynak ayak temasları ve ortak sahne koordinatları kullanır.

Godot 4.6.3 altyapısı, yüksek ayrıntılı pixel-art kaynaklar, seçilen araç, ses/hareket/font/tema ayarları ve klavye atamaları korunur. Kayıtlar bu cihazdadır; hesap/reklam/telemetri yoktur. Varsayılan koyu tema; Ayarlar’da açık/sistem, font, ses ve azaltılmış hareket seçenekleri vardır. Fiziksel cihaz ve insan oyun dengesi testi yapılmış sayılmaz.

## Geliştirme

Godot 4.6.3 standard ile project.godot dosyasını açıp F5 kullan veya:

```sh
godot --headless --editor --import --quit
GODOT=godot bash tests/run_all.sh
GODOT_BIN=godot python3 packaging/build_web.py
python3 -m http.server 8765 --directory build/web
```

Web’i http://localhost:8765 adresinden aç. HTML’ye çift tıklamak yeterli değildir. Normal girişte `?qa` yalnız salt okunur tarayıcı test durumunu açar; oyun durumuna yazma API’si yoktur.

`tests/browser_linear.cjs`: iki etap, iki ara sahne ve kayıtla devam için gerçek klavye/fare, Gamepad API veya dokunmatik girdileri. `DBW_INPUT=keyboard|pad|touch`, `DBW_URL` ve `DBW_EVIDENCE_DIR` ile çalışır. Eski browser_book/result_pad/touch_boss girişleri bu ortak akışa yönelir. `tests/browser_forge.cjs` altı düzen/input regresyonudur.

[Hikâye ve kayıt](docs/JOURNEY.md) · [Tasarım](docs/GAME_DESIGN.md) · [Kontroller](docs/CONTROLS.md) · [Sanat](docs/ART_BIBLE.md) · [QA](docs/QA.md) · [Forge](docs/FORGE.md) · [Sürüm](docs/RELEASE.md) · [AIONIA kaynak](docs/AIONIA_CURRENT_REFERENCE.md) · [Mahremiyet](docs/PRIVACY.md) · [Build](docs/BUILD.md)

Kaynaklar: data/story_book.json ve scripts/core/story_book.gd lineer ilerleme; road_story.json ilk ara sahne; cliff_story.json ikinci ara sahne. visual_art.json yeni resimlerin kaynak bölgeleri/hash/ayak temasları; assets/PROVENANCE.json üretim kaydıdır. Kullanıcının talebiyle sonraki kalite/Forge işleri Unslop becerisiyle yürütülür.

Canlı /version.json sürüm/build commit/giriş adresini bildirir. Build başarısı, yayın ve gerçek oynanış ayrı doğrulanır; otomatik Vercel yayını kota tarafından engellenebilir. Önizleme ile public domain aynı kaynak ağacından yayımlansa bile commit/target farkı yayın makbuzunda açıkça yazılır.

0.13.0: Her etap tek biyomdur: ilk etap Cam Ormanı, ikinci etap Buzlu Arşiv.180m’deki otomatik geçiş kaldırıldı; yarış da aynı ormanda kalır. Arkadan gelen araçlar gerçek kamera sınırının150 dünya birimi gerisinden başlar; mevcut araçlar yön değişiminde taşınmaz. Sürüşte yalnız Ateş ve Mayın, çıplak can barı ve kutusuz bildirimler vardır; karakter replikleri panelde kalır. Üç sohbet yanıtı farklı cevap verir, aynı hikâye ve sürüş kurallarına bağlanır. Mevcut Fragaria çileği web/native yükleyicisinde gerçek asset olarak paketlenir.

0.13.1: Kamyon kasasının ortasını açan saldırı resmi yerine sabit arka menteşeli kapılar; kademeli açılış, gerçek arka ağızdan yük bırakma ve kapanış. Gövde/kayıt/kontroller korunur.

0.13.2: Bildirimler ve kontrol ipuçları ayrı alanlarda; çıplak HUD yazısı iki temada okunur. Yön/font değişiminde okunan yer ve ayarlarda düzenlenen satır korunur. Gamepad ipucu gerçek özel atamayı gösterir; proje/web/Linux açıklaması gerçek lineer içerikle uyumludur.
