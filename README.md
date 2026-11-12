# Drive-By Wire

Yazarak sürülen roguelite araba çatışması (prototip, geliştirme sürüyor). Arabanın yapay zekâsı MOMO, klavyeden yazdığın komutları ruh haline göre yorumlar.

## İndir ve oyna
- **Tarayıcıda:** Vercel bağlandığında `https://<vercel-adresi>.vercel.app` (kurulum: [docs/VERCEL.md](docs/VERCEL.md)).
- **İndirilebilir sürümler:** [Releases](https://github.com/kaansavukduran/drive-by-wire/releases/latest)
  - Windows: `DriveByWire-<sürüm>-windows-x64-Setup.exe` (kurulum, yönetici izni gerekmez) veya `-windows-x64-portable.zip` (çıkart, `DriveByWire.exe` çalıştır)
  - Linux: `-linux-x64.AppImage`, `-linux-x64.deb`, `-linux-x64-portable.tar.gz`
  - Android: `-android-arm64-x64.apk` (prototip; herkese açık prototip anahtarıyla imzalı, ayrıntı [docs/BUILD.md](docs/BUILD.md))
  - Web çevrimdışı: `-web-offline.tar.gz`
- Platform durumu ve sürüm notları: [docs/RELEASE.md](docs/RELEASE.md)

## Şu anki durum (0.1.0, geliştirme)
Var: piksel art (yol, araçlar, efektler, MOMO yüzü, garaj, Aion ve Baykuş Ömer), garaj (MOMO selamı, 3–4 seçenekli diyalog, bu sefer için tek yükseltme), kayan üç şeritli yol, yazarak sürüş, komut kutusu açıkken %10 zaman, çarpan araba / ateş eden kamyonet / engel bırakan kamyon, hedefli ateş, mayın, kaç, çarp, can ve ekran sarsıntısı, MOMO yüzü ve ruh haline göre yorum, sefer sonu ekranı, yerel kayıt (güven + hafıza), web derlemesi.
Henüz yok: ses ve müzik (kapsam dışı), kilometre taşı 6 dengesi için uzun oyun testi, gerçek telefonda APK denemesi, Windows kod imzası.

## Oyna
- Garajda rakam tuşuyla (1–4) MOMO'ya cevap ver, bir yükseltme seç, Enter ile sefere çık.
- Herhangi bir harfe bas: komut kutusu açılır ve zaman yavaşlar. **Enter** gönderir, **Esc** vazgeçer.
- Örnekler: `sola geç`, `sağa geç ve ateş et`, `hızlan`, `yavaşla`, `mayın bırak`, `aferin`, `go left`, `fire`.

## Çalıştır
Godot 4.6.3 ile `project.godot` dosyasını aç ve F5, ya da:

```bash
godot --path .
```

Testler:

```bash
bash tests/run_all.sh
```

Web (Vercel'in çalıştırdığı komut):

```bash
python3 packaging/build_web.py
```

## Dosya yapısı
- `data/balance.json`: tüm ayarlanabilir sayılar (config burada).
- `data/intents.json`: komut kelimeleri; yeni kelime eklemek için yalnızca bu dosya.
- `data/momo_lines.json`, `data/garage.json`: replikler ve garaj içeriği.
- `scripts/core/`: saf oyun mantığı (ayrıştırıcı, MOMO, garaj, kayıt).
- `scripts/game/`, `scenes/`: sahneler.
- `assets/`, `tools/art/`: piksel art ve onu üreten betikler.
- `packaging/`, `vercel.json`, `export_presets.cfg`: derleme ve yayın.
