# Drive-By Wire 0.17.0 · Forge inceleme adayı

Başlangıç GitHub `main` ve Pages `0.16.0` (`3551b72619ee`). Eski yayın, yerel doğrulama ve platform sınırları [0.16.0 QA arşivinde](history/QA-v0160.md).

| Alan | Doğrulama ölçütü |
| --- | --- |
| Lineer hazırlık ve ara sahne | Sabit replik sırası, tek replik ve toplu atlama. Toplu atlama yarış, tuzak, çarpışma, fren ve inişi oynatır. |
| Kurt’un kurtarışı | Tampon temasından fren ve inişe kadar kesintisiz sahne. Aion kapı repliği sırasında içeride, yardım sonrası dışarıda. Kayıt ve ekran dönüşünde ortak dünya pivotu. |
| Mühür-01 ve Yankı-02 | İki gerçek saldırı fazı, ön ateş ve arka mayın. Saldırı hedefi kilitli, çekirdek saldırıdan sonra açılır. |
| Müzik | Üç paketlenmiş OGG kaynağı, tek canlı müzik geçişi, yerel ayarlarla duraklatma ve kapatma. [Lisans ve kaynaklar](../THIRD_PARTY_NOTICES.md#music). |
| Fiziksel cihaz, gerçek dinleme ve oyuncu kabulü | NOT TESTED. Tarayıcı emülasyonu ayrı değerlendirilir. |
| GitHub Pages üretim yayını | Mevcut yayın `0.16.0`. `0.17.0` inceleme dalı. |

Yeniden doğrulama için Godot 4.6.3 ile `bash tests/run_all.sh`, Web export için `GODOT_BIN=godot python3 packaging/build_web.py`. Yerel HTTP sunucusuna karşı `DBW_INPUT=keyboard|pad|touch node tests/browser_linear.cjs` ve `node tests/browser_perf.cjs`.
