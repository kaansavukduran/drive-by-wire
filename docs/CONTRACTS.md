# Ortak sözleşme (tüm geliştirme ajanları için)

> 12 Kasım 2026: Kullanıcının yeni isteğiyle sürüm 0.2.0, doğrudan ok tuşlu sürüş olarak geliştirilir. Aşağıdaki ajan sahiplikleri önceki çalışma organizasyonunu anlatır; bu tek geliştiricili değişikliğin dosya sınırı değildir. Godot 4.6.3, AIONIA v1.0, 640×360, kayıt uyumluluğu ve Türkçe glif koşulları korunur. [Güncel kararlar ve doğrulama](FORGE.md).

Sabitler: oyun adı "Drive-By Wire", dosya adı öneki `DriveByWire`, Android paketi `com.kaansavukduran.drivebywire`, sürüm `0.1.0`, Godot **4.6.3** (`godot` PATH'te), GL Compatibility.
Mantıksal çözünürlük 640×360, `canvas_items` stretch, en-boy `keep`, doku filtresi nearest. 1440p'de tam 4×. Yazılar vektör font ile çizilir (Türkçe karakter şart).

## Dosya sahipliği
| Yol | Sahip |
|---|---|
| `data/*.json`, `scripts/core/**`, `tests/**` | mantık |
| `assets/**`, `tools/art/**` | çizim |
| `scenes/**`, `scripts/game/**`, `project.godot` | oyun |
| `export_presets.cfg`, `packaging/**`, `.github/**`, `vercel.json`, `docs/BUILD.md`, `docs/RELEASE.md`, `docs/VERCEL.md`, `LICENSE`, `THIRD_PARTY_NOTICES.md` | paketleme |
| `README.md`, `docs/DESIGN.md`, `docs/CONTRACTS.md`, git | orkestratör |

Başka sahibin dosyasına dokunma; gerekiyorsa raporunda iste. Git komutu çalıştırma (commit'i orkestratör atar).

## Kurallar
- `scripts/core` saf GDScript: `extends RefCounted`, Node/sahne/Input yok; rastgelelik dışarıdan verilen `RandomNumberGenerator` ile (testte tohumlanır). Dosyalar `preload` ile kullanılır; `class_name` global önbelleğine güvenme.
- Tüm ayarlanabilir sayılar `data/balance.json` içinde; kelimeler `data/intents.json`, replikler `data/momo_lines.json`, garaj içeriği `data/garage.json`.
- Çizim çıktısı `assets/MANIFEST.json` ile anlatılır: her sheet için dosya, kare boyutu, animasyon adı → kare listesi, fps, döngü.
- Çalıştırıp görmediğin şeye "çalışıyor" yazma. Raporda komutları ve çıktıları ver.
