# Güncel AIONIA standardı · proje uygulaması

Kaynak: [private reference omitted]

12 Kasım 2026'da belge başarıyla okundu. Kullanıcı v1.4 istedi; kaynak erişimde **v1.5** başlığını taşıyordu. v1.4 tema/font hükümleri ve v1.5 aile geometrisi maddeleri birlikte değerlendirildi. Bu dosya iç standardı bütünüyle yayımlamaz; projedeki uygulama ve açık sınırları kaydeder. Sertifikasyon iddiası değildir.

- Mevcut Godot 4.6.3/GDScript korunur. Ürün üç şeritli, üstten görülen kısa arcade hikâye oyunudur; hedef genel oyuncu, PC ve mobil/tablet kullanıcısıdır. Yeni motor, framework, hesap, reklam/analiz SDK'sı veya bağımlılık eklenmedi.
- Son açık kontrol seçimi **Öneri 1: sağa/sola kaydırma + eylem düğmeleri**. PC oklar/WASD + fare; gamepad analog/D-pad ve düğmeler. Kullanıcı bunu tekrar onayladı. Standart §17, önceden onaylanan şemanın yeniden sorulmasını gerektirmez. Tür ve ana hareket modeli değişmedi.
- Varsayılan koyu tema. Görünüm sekmesinde açık/koyu/sistem ve sistem/Lexend seçimi yerel kayda yazılır. Tek paylaşılan Theme ve stil kaynakları tutarlı renk, odak, kenar ve boşlukları günceller. Mobil eylem düğmelerinin sütunları eşit tam pixel genişliğindedir. Dikey/yatay, çoklu dokunma ve yön değişiminde güvenli mola korunur.
- Native Godot SystemFont cihazın sans-serif fontunu çözer. **Web Canvas OS font dosyalarına erişemediğinden gömülü Godot font yedeği kullanır**; testte Open Sans SemiBold döndü. HTML yardım/yükleme CSS `system-ui` kullanır. Web oyun tuvalinin gerçek OS fontuyla tam uyumu sağlanmış gösterilmez. Kullanıcıdan font izni istemek veya yeni yazı renderer'ı eklemek tercih edilmedi.
- Fragaria yükleyici siyah zemin, doğrulanmış özgün çilek referansı, pixel marka yazısı ve on parçalı pembe/yeşil/gri çubuk kullanır. Web yüzdesi engine byte ilerlemesinden; native sahne yüzdesi ResourceLoader'dan gelir. Boyut bilinmiyorsa yüzde uydurulmaz. Gerçek sürüm, hata/yeniden dene, uzun bekleme ve semantik durum bulunur. Dekoratif font yalnız marka yazısındadır.
- Drive 00_BAŞLA, standartlar ve mevcut 19 görsel önceki incelemede okundu; çilek kaynağı bu güncellemede yeniden indirildi/görüldü. **Ayrı onaylı final logo kompozisyonu bulunamadı**. Referans JPG byte olarak aynen korunur; runtime kullanımı art direction referansıdır, nihai marka onayı sayılmaz. Kaynak ve hash ART_BIBLE / manifestte kayıtlıdır.
- Kullanıcının istediği yeni AI İLİN ve 13 sonlu hikâye OYUN/TASLAK olarak eklendi. Mevcut beş AIONIA karakterine onaysız varyant uygulanmadı.
- Güvenli/mahrem yerel kayıt, erişilebilir odak/kontrast, azaltılmış hareket, ses, yeniden atama ve otomatik ateş korunur. Fiziksel cihaz/yardımcı teknoloji ve insan eğlence testi, emülasyonla aynı sayılmaz. Sonuçlar PASS / FAIL / NOT TESTED raporlanır.

[Tasarım incelemesi](DESIGN_BRIEF.md) · [Kontrol kararı](CONTROLS.md) · [Yeni hikâye/İLİN](JOURNEY.md) · [Sanat kaynakları](ART_BIBLE.md) · [QA](QA.md).

**Görsel yayımlama durumu:** Çilekli yükleyici yerelde test edildi. Özel Drive JPG’sinin public GitHub/önizlemeye aktarımı otomatik onay denetimince açık paylaşım izni olmadığı için reddedildi. İzin beklenirken kamuya açık kaynak/önizleme yalnız Fragaria marka yazısını gösterir; JPG ve onu içeren yükleme ekranı görüntüsü bu kaynağa dahil edilmez. 13 son ve diğer oyun özellikleri bundan etkilenmez.

**Uzak yayın durumu:** v0.6 kaynak ağacının gönderimi, içerdiği özel referans bağlantıları/varlık kapsamı nedeniyle otomatik onay denetimince ayrıca reddedildi. GitHub dalı/PR ve uzak oyun önizlemesi bu sürüme güncellenmedi. Wordmark fallback temiz kaynak ağacında yerelde derlendi ve web smoke PASS; bu uzak yayın başarısı değildir. Çilekli tam sürüm ve görsel kanıtlar yalnız yerel teslimde bulunur. Dışarı aktarma için kaynak, referans bağlantıları ve görselleri kapsayan açık hedef onayı beklenir.

Public edition: private Drive/Docs URLs, private strawberry art and its test screenshots are excluded. The running game uses the Fragaria pixel wordmark; gameplay, İLİN and all 13 endings are included. Public deployment is verified separately.
