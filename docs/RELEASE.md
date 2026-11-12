# Drive-By Wire 0.6.1 · Daha adil sürüş

Fragaria Interactive · AIONIA

Üç arcade etap ve seçimlere göre 13 son korunur. Mobil/tablette onaylı kaydırma + eylem düğmeleri, PC oklar/WASD/fare, gamepad analog/D-pad aynı şekilde çalışır.

- Ateş eden kamyonet, 0.55 saniye önceden nişan çizgisini ve dolan hazırlık çubuğunu gösterir. Atış bu noktaya kilitlenir; oyuncu şerit değiştirerek kaçabilir.
- Kamyon, engel bırakacağı yeri 0.65 saniye önceden `!` işaretiyle gösterir. Güvenli bırakma alanını geçmişse geç kalan saldırı iptal edilir.
- Şerit kıran çarpan araç yönünü gösterir; aynı şeritteki birden fazla arka takipçi tek işaret kullanır. İşaretler araçların üstünde, menülerin altında çizilir. Azaltılmış harekette önemli bilgiler korunur.
- Kamera, dekoratif yol ve İLİN replikleri düşman/ikmal rastgeleliğini tüketmez. Aynı fizik girdilerinde görsel tercihler canı, puanı ve trafiği değiştirmez.
- Yatay kaçan mermiler sınırlı alanın dışına çıkınca silinir. Arka takipçiye ateş, hedefe varmadan kesilmez.
- Menü/garaj sürüm yazısı artık project.godot değerinden gelir.

Godot 4.6.3 ve mevcut görsel kaynaklar korunur; yeni motor, framework veya runtime bağımlılığı yoktur. [Hikâye/İLİN](JOURNEY.md) OYUN/TASLAK statüsündedir. [Gerçek test raporu](QA.md) ve önceki [0.6.0 raporu](history/QA-v060.md) ayrı tutulur.

Kullanıcı 12 Kasım 2026'da kaynak ve oyunda kullanılan referansların GitHub/Vercel yayınını açıkça istedi. Yayın hedefi `https://drive-by-wire.vercel.app`; GitHub `kaansavukduran/drive-by-wire`. Yerelde hazırlanmış sürüm mevcut PR üzerinden main'e alınarak Vercel'in Git bağlantısıyla dağıtılır. `version.json` sürüm/commit bilgisi verir. Canlı sonuç ayrıca doğrulanır; eski yerel paket ve geçmiş raporlar yayın başarısı sayılmaz.

Tam Git geçmişi başka servise/pakete aktarılmaz. İLİN ve yeni anlatı OYUN/TASLAK; çilek görseli onaylı final logo ilan edilmez. Fiziksel cihaz ve insan eğlence testi tamamlanmış gösterilmez.

Public edition: private Drive/Docs URLs, private strawberry art and its test screenshots are excluded. The running game uses the Fragaria pixel wordmark; gameplay, İLİN and all 13 endings are included. Public deployment is verified separately.
