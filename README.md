# Drive-By Wire

Yazarak sürülen roguelite araba çatışması (prototip, geliştirme sürüyor). Arabanın yapay zekâsı MOMO, klavyeden yazdığın komutları ruh haline göre yorumlar.

## Şu anki durum (0.1.0, geliştirme)
Var: garaj (MOMO selamı, 3–4 seçenekli diyalog, bu sefer için tek yükseltme), kayan üç şeritli yol, yazarak sürüş, komut kutusu açıkken %10 zaman, çarpan araba / ateş eden kamyonet / engel bırakan kamyon, hedefli ateş, mayın, kaç, çarp, can ve ekran sarsıntısı, MOMO yüzü ve ruh haline göre yorum, sefer sonu ekranı, yerel kayıt (güven + hafıza), web derlemesi.
Henüz yok: düşmanların, yolun, MOMO yüzünün ve garajın son piksel art çizimleri (şimdilik kodla çizilmiş geçici çizimler), Windows/Linux/Android paketleri ve GitHub Release.

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
