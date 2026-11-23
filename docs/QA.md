# Drive-By Wire 0.16.0 · Mission 1 Teknik Kabul Adayı

22 Kasım 2026. Taban yerel `main` `20bb505/0.15.0` (GitHub canlı başlangıç tabanı `69904f45999e/0.13.3`). `modern-web-guidance` okundu ve kabukta uygulandı (`accessibility`, `motion`, `form-factor-adaptation`, `progress`); diğer beş haricî Codex becerisi (`planlama`, `fragaria-unslop`, `unslop`, `yazilim-denetle`, `oyun-gelistirme-amaciyla-arastirma-ve-inceleme`) bu VM’de kurulu değildir (`SKILL_NOT_LOADED`). Önceki `0.15.0` kanıtları [0.15.0 arşivinde](history/QA-v0150.md) korunur.

## Doğrulama özeti (`0.16.0`)

| Kontrol | Sonuç | Kanıt / sınır |
|---|---|---|
| Native Godot 4.6.3 | PASS | 33 takım / 2384 kontrol / 0 hata (`test_vehicle_motion` 55, `test_combat_events` 38, `test_audio_world` 59 yeni kontrol dahil). 15 prosedürel SFX + 3 kesintisiz müzik katmanı (`road`, `boss`, `aftermath`), anti-clipping, sıfır-geçişli döngü kenarları, mola/susturma/ses düzeyi, 5 ardışık tekrar temizliği, tüm eski 30 regresyon takımı. |
| Web export (`build_web.py`) | PASS | `work/.gdignore` korumalı ve `--export-release` `check_output=True` ile 0 script/parse hatasıyla `0.16.0` üretildi. |
| Yükleme ve hata kurtarma (`browser_loading.cjs`) | PASS | Masaüstü 1280×720, dikey telefon 390×844, yatay telefon 844×390, 30 sn duraklama bildirimi, PCK ağ hatası + odaklı yeniden dene, sürüm-kapsamlı `fragaria-strawberry.jpg` SHA-256 doğrulaması. `work/v0160/loading/loading-results.json`. |
| Çatışma uyarıları (`browser_warnings.cjs`) | PASS | Gerçek web akışında arka/ram/atış uyarıları, duraklatılmış hazırlık ve Cam Ormanı omuz parıltıları. Hata: 0. `work/v0160/warnings/warnings-browser-results.json`. |
| Tema ve yazı tipi (`browser_appearance.cjs`) | PASS | Varsayılan koyu, açık tema, Lexend seçimi, sistem teması değişimi ve yenileme sonrası kalıcılık. Web Canvas OS font sınırı (`web_fallback: true`, `native_system: false`) dürüstçe açık tutulur. `work/v0160/appearance/appearance-browser-results.json`. |
| Kalite, kumanda ve 200% erişilebilir yardım (`browser_quality.cjs`) | PASS | Normal (1280×720 SwiftShader 10–12 FPS) vs düşük güç (640×360 SwiftShader 21–24 FPS), 0 üçüncü taraf istek, Gamepad Start/B mola, `#accessible-help` %200 metin akışı ve odak dönüşü. `work/v0160/quality/quality-results.json`. |
| Performans ve 5 ardışık tekrar (`browser_perf.cjs`) | PASS | Chromium SwiftShader yazılım renderer (fiziksel GPU yok, düşük güç 640×360): soğuk açılış 5130 ms; Cam Ormanı sürüş p50 49.9 ms / p95 66.6 ms / ort 22.7 FPS; 5 ardışık tekrar p50 33.4–50.0 ms / ort 22.7–24.8 FPS, bellek 9.5–20.7 MB (5. deneme sonunda 16.6 MB), 0 hata. `work/v0160/perf2/perf-results.json`. |
| Tam lineer akış · Klavye (`browser_linear.cjs`) | PASS | İki 400 m etap, Mühür-01 & Yankı-02 Faz 1–2, iki ara sahne, `cliffReload: true`, Devam edecek & yeniden açılış. Hata: 0. `work/v0160/linear-kb/linear-results.json`. |
| Tam lineer akış · Dokunmatik (`browser_linear.cjs`) | PASS | Sabit joystick + Ateş/Mayın ile iki 400 m etap (1. etap 135 CAN, 2. etap 133 CAN), iki boss, iki ara sahne, `cliffRotation: true`, Devam edecek & yeniden açılış. Hata: 0. `work/v0160/linear-touch3/linear-results.json`. |
| Tam lineer akış · Gamepad (`browser_linear.cjs`) | PASS | Yalnız emüle Gamepad API ile iki 400 m etap (135/135 CAN), iki boss, iki ara sahne, Devam edecek & yeniden açılış. Hata: 0. `work/v0160/linear-pad/linear-results.json`. |
| Altı cihaz düzeni ve kumanda (`browser_forge.cjs`) | PASS | `desktop`, `phone-portrait`, `phone-landscape`, `tablet-portrait`, `tablet-landscape`, `phone-low-power` + tam Gamepad akışı (D-pad/A garaj, diyalog, yükseltme, rota, analog, X/RT, Start/B, kopma/bağlanma). Hata: 0. `work/v0160/forge/forge-results.json`. |
| GitHub Pages canlı dağıtımı | BLOCKED | `git push origin main` HTTP 403 (`Permission to kaansavukduran/drive-by-wire.git denied`): repo bu oturumun proje GitHub kaynaklarına yazma yetkisiyle bağlı değildir. Yerel `main` dalı (`0.14.0 → 0.15.0 → 0.16.0`) ve doğrulanmış `build/web` hazırdır; canlı GitHub Pages hâlâ `0.13.3` (`69904f45999e`) sürümündedir. |
| Fiziksel cihaz / gerçek ses dinleme / insan kabulü | NOT TESTED | Fiziksel telefon/tablet/Xbox, Safari/Firefox, hoparlörden insan ses dinlemesi ve kullanıcının estetik/oynanış kabulü yapılmadı. Chromium dokunmatik/Gamepad API emülasyonu fiziksel cihaz kanıtı değildir. |
| Önceki yazılım FPS / Web Canvas OS-font sınırları | FAIL | Yazılım renderer normal mod 60 FPS hedefi (10–12 FPS ölçüldü) ve Web Canvas’ın OS sistem font dosyalarına erişememesi açık sınır olarak korunur. |

## Gerçek paydalı ilerleme tablosu

| İş grubu | Gerekli kapsam | Üretildi | Oyuna bağlandı | Davranış/görsel olarak doğrulandı | Açık iş |
| --- | --- | --- | --- | --- | --- |
| Kaynak/karar uzlaştırma | 1 repo, canlı Pages/Vercel, son kararlar | 1/1 doğrulandı (`69904f45999e`) | N/A (envanter) | Okuma + canlı kontrol + 5 haricî beceri `SKILL_NOT_LOADED` kaydı | Repo proje push kaynağına bağlı değil (HTTP 403) |
| Referans araştırması | 3 ana + 3 tamamlayıcı oyun | 6/6 (`docs/RESEARCH_VEHICULAR_COMBAT.md`) | 6/6 somut DBW kararına bağlandı | 6/6 native + tarayıcı denemeleriyle sınandı | İzlenmeyen video/ölçülmemiş kare yok |
| Araç animasyonu | 3 kozmetik araç × (gölge, far, yatış/teker, ateş tepmesi, mayın çıkışı, hasar kademesi, azaltılmış hareket) | 3/3 (`vehicle_motion.gd`, `vehicle_overlay.gd`) | 3/3 (`main.gd`, `vehicle_screen.gd`) | 55 native kontrol + gerçek web ekran görüntüleri | Fiziksel cihazda görsel değerlendirme |
| Öne ateş/arka mayın | Tek-olay ateş/kıvılcım + sınırsız mayın kurulma/sensör/60 px çok aşamalı patlama | 2/2 silah akışı (`main.gd`) | 2/2 | 38 native + 11 arka savunma + uzun kare (`0.25s`) + 3 girdi ailesi web oynanışı | Fiziksel cihaz/kullanıcı hissi |
| Trafik/kamyon | Rammer/pickup/truck, kamera dışı arka giriş, arka menteşeli kapak + yük ağzı | Korundu + `hatch_puff` & `truck_hatch` ses eşlemesi | 3/3 (`main.gd`, `truck_hatch.gd`) | 173 kamyon + 32 uyarı + 3 girdi ailesi web oynanışı | — |
| Mühür-01 | 6 oyunculuk durumu (`entering/telegraph/firing/recover/phase_shift/defeated`), ön-eksen Faz 2, gölge/şarj/tepme/soğutma | 6/6 (`boss_encounter.gd`, `robot_art.gd`) | 6/6 (`main.gd`) | 45 + 38 native + `stage1-boss1/2.png` incelemesi + 3 girdi ailesi yenilgi | Kullanıcı estetik/denge geri bildirimi |
| Cam Ormanı | Tek biyom 400 m + omuz atmosfer derinliği (RNG-bağımsız) | 1/1 (`road_biomes.gd`) | 1/1 (`main.gd`) | Native RNG testi + web görsel kontrolü | — |
| Yan yana | 13 adım, Emre `0.28` ölçek, sabit ayak teması, 2 seçenekli düğümler, aftermath ses katmanı | Korundu + `aftermath` müzik katmanı (`road_story_screen.gd`) | 1/1 | 214 native + web 3 girdi ailesi + dikey/yatay ekran görüntüsü | Kullanıcı geri bildirimi |
| UI/giriş | Yükleyici, 3 yanıtlı hazırlık, HUD/metin, MWG kabuk (`viewport-fit`, safe-area, 44 px coarse, odak) | Güncellendi (`shell.html`, `entry.html`, `main.gd`, `vehicle_screen.gd`) | Tamamı | 208 + 288 + 152 native + 6 viewport `browser_forge` + `browser_loading/appearance/quality` | Web Canvas OS-font sınırı (FAIL) |
| Ses/performans | 15 SFX + 3 kesintisiz katman + statik önbellek + 5 tekrar bellek/kare süresi | 18/18 (`sounds.gd`, `PROVENANCE.json`) | `main.gd`, `road_story_screen.gd` | 59 native + `browser_perf` (5 tekrar) + `browser_linear` | Gerçek hoparlör dinlemesi (NOT TESTED); SwiftShader 60 FPS sınırı (FAIL) |
| İkinci etap regresyonu | Buzlu Arşiv + Yankı-02 + Kurt kurtarma + Devam edecek | Yeni içerik eklenmedi (kapsam korunur) | Korundu | 93 native + 3 girdi ailesi tam 2-etap web oynanışı + `cliffReload`/`cliffRotation` | — |
| Main/Pages | `0.14.0 → 0.15.0 → 0.16.0`, kapılı `pages.yml` | Yerel `main` + `build/web` hazır | `pages.yml` güncellendi | Yerel doğrulama PASS; uzak push HTTP 403 `BLOCKED` | Repo proje kaynaklarına bağlanıp `git push origin main` yapılmalı |
| Kullanıcı kabulü | Gerçek kullanıcı oynanış ve estetik onayı | N/A | N/A | Bekleniyor (`NOT TESTED`) | Kullanıcının gerçek oynanış geri bildirimi |

## Mission 1 kabul matrisi

| Kabul alanı | Durum | Kanıt |
| --- | --- | --- |
| Güncel başlangıç | PASS | GitHub `69904f45999e/0.13.3`, canlı Pages `0.13.3`, Vercel `DEPLOYMENT_DISABLED` doğrulandı |
| Araştırma | PASS | `docs/RESEARCH_VEHICULAR_COMBAT.md` (6 oyun, kaynaklı, DBW aktarım tablosu) |
| Giriş/hazırlık | PASS | `browser_loading`, `browser_forge` (6 cihaz), 3 gerçek yanıt + 3 araç seçimi |
| Sürüş | PASS | `test_free_drive` (71), `browser_forge` + `browser_linear` (klavye/touch/pad) |
| Araç hareketi | PASS | `test_vehicle_motion` (55) + `stage1-boss2.png` / `warning-shot-live.png` |
| Öne ateş | PASS | `test_combat_events` (38), namlu/kıvılcım/tek hasar |
| Arka mayın | PASS | `test_rear_defense` (11), `test_combat_events` (38), uzun kare tek patlama + 60 px şok halkası |
| Trafik ve kamyon | PASS | `test_truck_hatch` (173), `test_enemy_warnings` (32), `browser_warnings` |
| Cam Ormanı | PASS | Tek biyom 400 m + omuz parıltıları (`road_biomes.gd`), 3 girdi ailesi web oynanışı |
| Mühür-01 | PASS | `test_boss_encounters` (45), `test_combat_events` (38), Faz 1–2 görsel kontrolü |
| Bitiş | PASS | 399.9 m boss kilidi + ara sahneye tek geçiş (`browser_linear` × 3) |
| Yan yana | PASS | `test_road_story` (214), Emre `0.28`, sabit temaslar, 2 yön + aftermath katmanı |
| Kayıt/retry | PASS | `test_save_recovery` (18), Web `localStorage` aynası (`cliffReload: true`), `browser_perf` 5 tekrar |
| Menü/HUD | PASS (OS-font FAIL açık) | `test_ui_readability` (208), `test_hud_text` (288), `browser_appearance`, `browser_quality` |
| Mobil/gamepad | PASS (emüle; fiziksel NOT TESTED) | `browser_forge` (6 cihaz + pad), `browser_linear` (touch + pad) |
| Sanat/kimlik | PASS (teknik) | `test_visual_art` (114), mevcut oranlar/çizimler korundu |
| Ses | PASS (teknik; insan dinleme NOT TESTED) | `test_audio_world` (59), 15 SFX + 3 katman, statik önbellek, 5 tekrar temizliği |
| Performans | PASS (emüle; normal 60 FPS FAIL açık) | `browser_perf` (SwiftShader düşük güç p50 33.4–50.0 ms, 0 hata) |
| Mevcut ikinci etap | PASS | `test_cliff_rescue` (93), 3 girdi ailesi tam 2-etap regresyonu |
| CI/main/Pages | BLOCKED | Yerel `main` + `pages.yml` hazır; `git push` HTTP 403 nedeniyle canlı Pages hâlâ `0.13.3` |
| Gerçek kullanıcı kabulü | NOT TESTED | Kullanıcının gerçek oynanış ve estetik geri bildirimi bekleniyor |

Tekrar: `GODOT=.ci-godot/bin/godot bash tests/run_all.sh`; `GODOT_BIN=.ci-godot/bin/godot python3 packaging/build_web.py`; `node tests/browser_loading.cjs`; `node tests/browser_forge.cjs`; `DBW_INPUT=keyboard|touch|pad node tests/browser_linear.cjs`; `node tests/browser_perf.cjs`. Rollback tabanı `20bb505/0.15.0` (uzak taban `69904f45999e/0.13.3`).
