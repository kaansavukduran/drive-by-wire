# Güncel resmî AIONIA referansının proje kapsamı

Kaynak: https://docs.google.com/document/d/16jj2cwbm8SiVWqDy3N3dzqxTlLoK7JR2_aH6hl4noWY/edit

Erişim: 12 Kasım 2026. Belge başarıyla okundu. Kullanıcının istediği sürüm v1.1; kaynak erişim sırasında **v1.2** başlığı taşıyordu. Belgedeki v1.1 evrensel kalite bölümü ile güncel oyun/kontrolcü ve UI maddeleri birlikte değerlendirildi. Bu dosya iç belgeyi bütünüyle yeniden yayımlamaz; projeye uygulanan kuralları özetler. Uyumluluk sertifikası değildir.

- Önce ürün amacı, kullanıcı grupları, mevcut teknoloji ve eksikler incelenir. Teknoloji ve kullanıcı ihtiyacıyla ilgisiz karakter veya pixel art zorlanmaz; yeni motor/framework geliştirilmez.
- Temel çalışan akış ve küçük oynanabilir bölüm önceliklidir. Bilgi mimarisi, geri bildirim, yükleme, hata, boş durum ve geri dönüşler bütünlüklü tasarlanır.
- Klavye, görünür odak, okunabilir metin/kontrast, yeterli etkileşim alanı, ses ve azaltılmış hareket seçenekleri sağlanır. Tam erişilebilirlik/WCAG iddiası yalnız gerçekten doğrulanan kapsam için yapılır.
- Oyunlar kontrolcü akışını planlar: analog, D-pad, düğme/tetikleyici, cihaz ipuçları, yeniden atama, ölü bölge, titreşim tercihi, bağlantı kesilmesi ve geri bağlanma. Fiziksel cihaz testi yazılım olay testinden ayrılır.
- Özgün görsel kimlik, performans, güvenlik, mahremiyet ve sürdürülebilir kod ürünün parçasıdır. Kullanıcı verisi, izinler, sürümleme ve yayın kalitesi değerlendirilir.
- Test sonuçları PASS / FAIL / NOT TESTED olarak kanıtla raporlanır; yapılmamış test veya onaylanmamış karakter varyantı tamamlanmış kabul edilmez.

[Tasarım ve teknik inceleme](DESIGN_BRIEF.md) · [Mahremiyet](PRIVACY.md) · [Gerçek test raporu](QA.md) · [Önceki sanat incelemesi](ART_BIBLE.md).
