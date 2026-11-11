# Drive-By Wire

Yazarak sürülen roguelite araba çatışması (prototip, geliştirme sürüyor). Arabanın yapay zekâsı MOMO, klavyeden yazdığın komutları ruh haline göre yorumlar.

## Şu anki durum (0.1.0, geliştirme)
Var: kayan üç şeritli yol, yazarak şerit değiştirme / hız / ateş / mayın, komut kutusu açıkken %10 zaman, Türkçe-İngilizce ayrıştırıcı, MOMO güven ve ruh hali, web derlemesi.
Henüz yok: düşmanlar ve hasar, garaj ekranı, sefer sonu, kayıt ekranı, tam çizimler, Windows/Linux/Android paketleri ve Release.

## Oyna
- Herhangi bir harfe bas: komut kutusu açılır ve zaman yavaşlar. **Enter** gönderir, **Esc** vazgeçer.
- Örnekler: `sola geç`, `sağa geç ve ateş et`, `hızlan`, `yavaşla`, `mayın bırak`, `aferin`, `go left`, `fire`.

## Çalıştır
Godot 4.6.3 ile `project.godot` dosyasını aç ve F5, ya da:

```bash
godot --path .
```

Testler:

```bash
godot --headless --path . --script tests/test_parser.gd
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
