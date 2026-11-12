# Drive-By Wire 0.5.0 · Eve Giden Yol

Fragaria Interactive · Fragaria Games · AIONIA

Telefon ve tablette kullanıcının onayladığı **sağa/sola kaydırma + eylem düğmeleri** uygulanır. Dikey/yatay UI, çoklu dokunma ve döndürünce güvenli mola vardır. PC oklar/WASD ile sürülür; yol alanında fare sol ateş, sağ sıyrılmadır. Kontrolcü menüden garaja, hikâye tercihine ve sürüşe kadar kullanılabilir. Sürmek için yazı yazmak gerekmez.

İlk hikâyeli bölümde MOMO'yla eve dönme sözü oyuncunun hedefidir. Yol öncesi tercih +15 can veya +2 mayın ve farklı bir hedef verir. Mesafe diyalogları günlükte saklanır. Bölüm sonu eve varma ve hedefe göre değişir; ilerleme yerel kayda geçer. Bu bölüm OYUN/TASLAK kapsamındadır; yeni kesin AIONIA kanonu veya tamamlanmış çok bölümlü kampanya değildir.

Mevcut Godot 4.6.3, karakter çizimleri, arcade döngüsü, ses/erişim ayarları ve güvenli kayıt korunur. Yeni motor, framework veya runtime servisi eklenmez. Kontrol şeması seçim kuralı AGENTS.md / CONTROLS.md'de kayıtlıdır.

429 otomatik kontrol, altı web ekran düzeni ve emüle kontrolcü akışı PASS. Normal modda bulut yazılım renderer 60 FPS hedefi FAIL (medyan 19); düşük güç medyanı 36 FPS. Fiziksel cihaz/Safari, tam ekran okuyucu, gerçek cihaz belleği, insan eğlence/denge testi ve native kurulum NOT TESTED. [Ayrıntılı QA](QA.md).

Web ZIP'ini çıkartıp klasöründe `python3 -m http.server 8765` çalıştır; `http://localhost:8765` aç. Kaynak ZIP'i Godot projesidir. Önceki sürümler korunur. Tam Git geçmişi bu teslimin parçası değildir. Main birleştirme veya üretim yayını yapılmaz; varsa PR önizlemesi ayrı doğrulanır.
