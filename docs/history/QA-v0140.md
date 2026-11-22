# Drive-By Wire 0.14.0 · Araç hareketi, araştırma ve yayın kapısı

22 Kasım 2026. Taban public main `69904f45999e/0.13.3`. `modern-web-guidance` okundu (`accessibility`, `motion`, `form-factor-adaptation`, `progress`); diğer beş haricî Codex becerisi (`planlama`, `fragaria-unslop`, `unslop`, `yazilim-denetle`, `oyun-gelistirme-amaciyla-arastirma-ve-inceleme`) bu ortamda kurulu değildir (`SKILL_NOT_LOADED`). Önceki 0.13.3 kanıtları [0.13.3 arşivinde](history/QA-v0133.md) korunur.

| Kontrol | Sonuç | Kanıt / sınır |
|---|---|---|
| Benzer oyun araştırması | PASS | `docs/RESEARCH_VEHICULAR_COMBAT.md`: Spy Hunter (1983/1987), Super Spy Hunter (1991–1992), Highway Pursuit (2003–2025), Road Fighter (1984), Death Rally (1996/2011), OutRun (1986); sürüm/platform farkları ve izlenebilir DBW uygulama tablosu. İzlenmeyen video zaman damgası veya ölçülmemiş kare sayısı yazılmadı. |
| Native Godot 4.6.3 | PASS | 31 takım / 2287 kontrol / 0 hata (`tests/test_vehicle_motion.gd` 55 yeni kontrol dahil). Üç kozmetik araç (`roadster`, `courier`, `comet`) için sabit pivot/hitbox sözleşmesi, direksiyon açısı, ön teker dönüşü, ateş tepmesi, mayın çıkışı, hasar kademeleri, azaltılmış hareket, deterministik RNG ayrımı ve mevcut 30 regresyon takımı. |
| Web export | PASS | `packaging/build_web.py` (`work/.gdignore` korumalı ve `--export-release` `check_output=True` ile script/parse hatasında duran kapı) 0 hata ile `0.14.0` paketini üretti. |
| Yükleme ve hata kurtarma (`browser_loading.cjs`) | PASS | Masaüstü 1280×720, dikey telefon 390×844, yatay telefon 844×390, 30 sn duraklama bildirimi, PCK ağ hatası + tekrar deneme ve sürüm-kapsamlı `fragaria-strawberry.jpg` SHA-256 doğrulaması. `work/v0140/loading/loading-results.json`. |
| Çatışma uyarıları ve görünüm (`browser_warnings.cjs`) | PASS | Gerçek web akışında uyarı görünürlüğü, per-vertex yumuşatılmış far konileri, çift katmanlı zemin gölgesi ve kırpılmayan isteğe bağlı T sohbet kutusu yer tutucusu (`Omega-3’e yaz · Enter / Esc`). `work/v0140/warnings-final/warnings-browser-results.json`. |
| Tam lineer akış · Klavye (`browser_linear.cjs`) | PASS | İki 400 m etap (Cam Ormanı + Buzlu Arşiv), Mühür-01 ve Yankı-02 Faz 1–2, iki ara sahne ("Yan yana" ve Kurt kurtarma), `cliffReload: true`, Devam edecek ve yeniden açılış koruması. Hata: 0. `work/v0140/linear-kb2/linear-results.json`. |
| Tam lineer akış · Dokunmatik (`browser_linear.cjs`) | PASS | Sabit sanal joystick + Ateş/Mayın ile iki 400 m etap, iki boss, iki ara sahne, `cliffRotation: true`, Devam edecek ve yeniden açılış koruması. Hata: 0. `work/v0140/linear-touch2/linear-results.json`. |
| Web anlık yenileme kayıt güvenliği | PASS | Web'de IDBFS `FS.syncfs` tamamlanmadan anlık yenileme sırasında ara sahne kayıt kaybı yakalandı; `scripts/core/save_store.gd` yalnız Web `user://save.json` için eşzamanlı `localStorage` aynası (`dbw.save_v1`) eklendi ve `cliffReload: true` ile doğrulandı. |
| GitHub Pages dağıtım kapısı | PASS | `.github/workflows/pages.yml` `verify_native` → `build` (Godot Web export + Chromium `browser_loading`, `browser_warnings`, `browser_linear`) → `deploy` sırasına bağlandı. Canlı `0.14.0` yayını itmeden hemen sonra `version.json` ve canlı Chromium ile ayrıca doğrulanır. |
| Fiziksel cihaz / insan değerlendirmesi | NOT TESTED | Fiziksel telefon/tablet/Xbox, Safari/Firefox ve insan estetik/oynanış değerlendirmesi yapılmadı. Chromium dokunmatik emülasyonu fiziksel test değildir. |
| Önceki performans / OS-font sınırları | FAIL | Yazılım renderer 60 FPS hedefi ve Web Canvas’ın OS sistem font dosyalarına erişememesi açık sınırdır; bu sürümde kapatılmış sayılmaz. |

Tarayıcı testleri yalnızca normal menü ve gerçek klavye/dokunmatik girdilerini kullanır; HP/RNG/konum/boss/kayıt setter’ı yoktur.

Tekrar: `GODOT=.ci-godot/bin/godot bash tests/run_all.sh`; `GODOT_BIN=.ci-godot/bin/godot python3 packaging/build_web.py`; `DBW_INPUT=keyboard|touch node tests/browser_linear.cjs`. Rollback tabanı `69904f45999e/0.13.3`.
