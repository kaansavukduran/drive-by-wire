# Drive-By Wire 0.6.2 · Güncel oyuna güvenilir giriş

[Oyunu aç](https://drive-by-wire.vercel.app/play/). Kök adres bu girişe yönlenir. GitHub `main` gönderimi Vercel'i otomatik tetikler; web yayını GitHub Release beklemez.

- Godot HTML, JS, WASM ve PCK aynı sürüm/commit klasöründe; önceki dosyalarla aynı URL kullanılmaz.
- Giriş ve sürüm bilgisi önbelleğe alınmaz. Sürüm klasöründeki büyük dosyalar değişmediği için tekrar kullanılabilir.
- 0.6.2 ve sonrası, sayfaya dönünce yeni sürümü haber verir. Güncelleme oyuncunun düğmeye basmasıyla açılır; etap kendiliğinden yenilenmez.
- Origin ve Godot kayıt alanı korunur; kullanıcıdan veri silmesi istenmez. Eski önbellekle geçiş ve gerçek kayıt içeriği tarayıcı testiyle doğrulandı.

Önceki 0.6.1 oynanış iyileştirmeleri:

Fragaria Interactive · AIONIA

Üç arcade etap ve seçimlere göre 13 son korunur. Mobil/tablette onaylı kaydırma + eylem düğmeleri, PC oklar/WASD/fare, gamepad analog/D-pad aynı şekilde çalışır.

- Ateş eden kamyonet, 0.55 saniye önceden nişan çizgisini ve dolan hazırlık çubuğunu gösterir. Atış bu noktaya kilitlenir; oyuncu şerit değiştirerek kaçabilir.
- Kamyon, engel bırakacağı yeri 0.65 saniye önceden `!` işaretiyle gösterir. Güvenli bırakma alanını geçmişse geç kalan saldırı iptal edilir.
- Şerit kıran çarpan araç yönünü gösterir; aynı şeritteki birden fazla arka takipçi tek işaret kullanır. İşaretler araçların üstünde, menülerin altında çizilir. Azaltılmış harekette önemli bilgiler korunur.
- Kamera, dekoratif yol ve İLİN replikleri düşman/ikmal rastgeleliğini tüketmez. Aynı fizik girdilerinde görsel tercihler canı, puanı ve trafiği değiştirmez.
- Yatay kaçan mermiler sınırlı alanın dışına çıkınca silinir. Arka takipçiye ateş, hedefe varmadan kesilmez.
- Menü/garaj sürüm yazısı artık project.godot değerinden gelir.
- Dikey telefonda mesafe, can ve enerji ayrı alanlarda gösterilir; mesafe yazısı enerji çubuğunun altında kalmaz.

Godot 4.6.3 ve mevcut görsel kaynaklar korunur; yeni motor, framework veya runtime bağımlılığı yoktur. [Hikâye/İLİN](JOURNEY.md) OYUN/TASLAK statüsündedir. [Gerçek test raporu](QA.md) ve önceki [0.6.0 raporu](history/QA-v060.md) ayrı tutulur.

12 Kasım 2026'da PR #1 main'e birleşti; 0.6.1 Vercel production üzerinde READY oldu. Canlı oyun: https://drive-by-wire.vercel.app. GitHub: `kaansavukduran/drive-by-wire`. `/version.json` sürüm/commit bilgisi verir. Girişsiz canlı tarayıcı testleri PC, telefon dikey ve telefon yatay akışlarını doğruladı; kapsam [QA raporunda](QA.md). Özel Drive içeriği public sürüme alınmadı.

Tam Git geçmişi başka servise/pakete aktarılmaz. İLİN ve yeni anlatı OYUN/TASLAK; çilek görseli onaylı final logo ilan edilmez. Fiziksel cihaz ve insan eğlence testi tamamlanmış gösterilmez.

Public edition: private Drive/Docs URLs, private strawberry art and its test screenshots are excluded. The running game uses the Fragaria pixel wordmark; gameplay, İLİN and all 13 endings are included. Public deployment is verified separately.
