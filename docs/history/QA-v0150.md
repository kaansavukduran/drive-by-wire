# Drive-By Wire 0.15.0 · Silah/mayın tek-olay bütünlüğü, Mühür-01 oyunculuğu ve Cam Ormanı derinliği

22 Kasım 2026. Taban yerel `main` `0.14.0` (`6794241`). Önceki `0.14.0` kanıtları [0.14.0 arşivinde](history/QA-v0140.md) korunur.

| Kontrol | Sonuç | Kanıt / sınır |
|---|---|---|
| Native Godot 4.6.3 | PASS | 32 takım / 2325 kontrol / 0 hata (`tests/test_combat_events.gd` 38 yeni kontrol dahil). Uzun karede (`delta = 0.25s`, `0.8s`) tek mayın patlaması, tek öldürme/puan, mermi isabet kıvılcımı, kamyon arka ağız yük eşzamanlaması, Mühür-01 durum akışı (`entering → telegraph → firing → recover → phase_shift → defeated`), Faz 2’de ön-eksen kısıtı, mola dondurması ve Cam Ormanı RNG ayrımı. |
| Web export | PASS | `packaging/build_web.py` 0 script/parse hatasıyla `0.15.0` paketini üretti. |
| Çatışma uyarıları (`browser_warnings.cjs`) | PASS | Gerçek web akışında uyarı görünürlüğü, duraklatılmış hazırlık ve Cam Ormanı omuz parıltıları (`work/v0150/warnings/warning-shot-live.png`). Hata: 0. |
| Tam lineer akış · Klavye (`browser_linear.cjs`) | PASS | İki 400 m etap, Mühür-01 (`act_state: defeated`, Faz 1–2) ve Yankı-02 (Faz 1–2), iki ara sahne ("Yan yana" ve Kurt kurtarma), `cliffReload: true`, Devam edecek ve yeniden açılış koruması. Hata: 0. `work/v0150/linear-kb/linear-results.json`. |
| Görsel inceleme (Mühür-01 & Cam Ormanı) | PASS | `work/v0150/linear-kb/stage1-boss1.png`, `stage1-boss2.png` ve `work/v0150/warnings/warning-shot-live.png` incelendi: Mühür-01 zemin gölgesi, Faz 2 reaktör halkası, Cam Ormanı omuz parıltıları temiz. Not: Faz 2 çift halka yarıçapı üst HUD başlığına yaklaşmasın diye `0.16.0` içinde daraltılacak. |
| GitHub Pages canlı dağıtımı | BLOCKED | `git push origin main` HTTP 403 (`Permission to kaansavukduran/drive-by-wire.git denied`): repo bu oturumun proje GitHub kaynaklarına yazma yetkisiyle bağlı değildir. Yerel `main` commit’i ve doğrulanmış `build/web` hazırdır; canlı GitHub Pages hâlâ `0.13.3` (`69904f45999e`) sürümündedir. |
| Fiziksel cihaz / insan değerlendirmesi | NOT TESTED | Fiziksel telefon/tablet/Xbox, Safari/Firefox ve insan estetik/oynanış değerlendirmesi yapılmadı. |
| Önceki performans / OS-font sınırları | FAIL | Yazılım renderer 60 FPS hedefi ve Web Canvas’ın OS sistem font dosyalarına erişememesi açık sınırdır. |

Tekrar: `GODOT=.ci-godot/bin/godot bash tests/run_all.sh`; `GODOT_BIN=.ci-godot/bin/godot python3 packaging/build_web.py`; `DBW_INPUT=keyboard node tests/browser_linear.cjs`. Rollback tabanı `6794241/0.14.0`.
