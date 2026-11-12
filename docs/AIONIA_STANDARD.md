> Tarihsel v1.0 kopyası. Güncel kullanıcı belgesinin v1.1/v1.2 kapsamı için [güncel referans kapsamı](AIONIA_CURRENT_REFERENCE.md), uygulama için [tasarım incelemesi](DESIGN_BRIEF.md) ve [test raporu](QA.md).

# AIONIA standardı · Sürümlü kaynak kopyası

Normatif kaynak: https://docs.google.com/document/d/16jj2cwbm8SiVWqDy3N3dzqxTlLoK7JR2_aH6hl4noWY/edit

Okuma tarihi: 12 Kasım 2026. Sürüm: 1.0. Bu dosya kaynak metnin kopyasıdır; proje özelindeki kararlar ART_BIBLE.md, GAME_DESIGN.md, LORE_LINKS.md ve QA.md içindedir.

AIONIA — EVREN, SANAT VE OYUN KALİTE STANDARTLARI
Sürüm 1.0 | 12 Kasım 2026 | Statü: Kullanıcı kuruluş kararlarına dayalı normatif referans
Üst marka: Fragaria Interactive | Oyun yayın markası: Fragaria Games | Kurgu evreni: AIONIA


0. KULLANIM KURALI
“AIONIA standartlarında oyun geliştir” dendiğinde bu belgeyi proje şartnamesi kabul et. Kullanıcının son açık talimatları bu belgeden üstündür. Mevcut projeyi, kaynakları ve referans görselleri önce incele. AIONIA oyun motoru üretme veya Godot'u yeniden yazma görevi YOKTUR. Mevcut Godot projesini ve uygun hazır özelliklerini kullan. Belgeye erişilemiyorsa erişmiş gibi davranma; kullanıcıdan bağlantı veya belgeyi iste. Kanon ve varlıklar için doğrulanmış kaynak dışında içerik uydurup kesinleşmiş kabul etme.


1. EVREN KİMLİĞİ
AIONIA, Fragaria Interactive çatısında özgün, çok dünyalı, genişlemeye açık bir kurgu evrenidir. Aion bir karakter olabilir; evrenin adı AIONIA'dır. AIONIA yalnızca bir oyun veya tek bir gezegen değildir. Atmosfer: sevimli, derin ve epik. Ne yalnızca çocukça şekerleme estetiği ne de sürekli kasvetli karanlık. Merak, keşif, sıcaklık, karakter duygusu, eski uygarlıklar ve büyük ölçekli gizem birlikte yaşayabilir. Her oyunun ekoloji veya veganlık temalı olması şart değildir. Oyunların tonu ve yaş hedefi proje bazında tanımlanır.


2. KANON VE DÜNYA İNŞASI
Kanon katmanları: ANA (kesin evren gerçekleri), YEREL (dünya/bölge), OYUN (oyun olayları), ALTERNATİF (ayrı süreklilik), TASLAK (onaysız). Yeni karakter, şehir, tarih veya tür eklerken mevcut kayıtlarla çelişki denetimi yap. Bilinmeyen bilgi = boşluk, otomatik icat edilecek gerçek değil. Önerilen lore'u “TASLAK” olarak işaretle. Karakter kimliği, türü, görünüşü, kişiliği, motivasyonu, ilişkileri, kökeni ve animasyon kaynakları kaydedilir. Dünya kayıtlarında coğrafya, ekosistem, kültür, tarih, teknoloji/büyü kuralları ve oyun bağlantıları bulunur. Yeni içerik mevcut kimliği koruyarak evreni genişletir.


3. GÖRSEL SANAT YÖNETİMİ
Öncelikli sanat dili: elle tasarlanmış hissi veren, okunaklı, ayrıntısı kontrollü 2D pixel art. Stil hedefi “cute + profound + epic”. Keskin piksel kenarları; tutarlı piksel ızgarası, oran, ışık yönü, gölgelendirme, renk ilişkisi ve görsel hiyerarşi. Bulanık büyütme, rastgele farklı piksel yoğunlukları, tutarsız karakter ölçekleri, aşırı efekt ve birbirinden kopuk hazır asset kolajı yasak. Yapay zekâ üretimi grafikler de aynı sanat denetiminden geçer. Palet, iç çözünürlük, tile boyutu, kamera ölçeği, referans siluet ve animasyon FPS değerleri her oyun için ART_BIBLE'da kararlaştırılır; evren genelinde keyfî tek sayı dayatılmaz. Pixel-perfect görünüm hedeflenir; ekran boyutları ve erişilebilirlik ayrıca test edilir.


4. KARAKTER VE SPRITE SHEET STANDARDI
Önce Drive ve repo içindeki onaylı Aion, kurt, kuzu, baykuş ve diğer mevcut karakter paftalarını incele; bulunmayan varlığı varmış gibi gösterme. Kaynak karakterlerin özgün kimliğini, renklerini, oranlarını ve ayırt edici özelliklerini koru. Sprite sheet: kare/hücre ölçüsü, kare sayısı, animasyon adı, yön, pivot, hitbox, frame süresi, döngü bilgisi ve kaynak dosya tanımlansın. Gereken eylemler oyuna göre idle, walk, run, jump, fall, land, hurt, interact, attack vb. olabilir; eksik animasyonu sahte tekrarlarla tamamlanmış gösterme. Animasyon geçişleri, çarpışma, hizalama ve kamera ölçeği oyun içinde test edilir. Lisans/kaynak bilgisi korunur. Başka projeden izinsiz asset devşirilmez.


5. OYNANIŞ VE UX STANDARDI
Her oyun için önce tek cümlelik oyuncu vaadi, ana oyun döngüsü, kazanma/kaybetme koşulları ve 3 ayırt edici mekanik yaz. İlk oynanabilir dakikada hedef ve kontroller anlaşılmalı. Hareket hissi, geri bildirim, adil zorluk eğrisi, tutarlı kamera, okunabilir HUD, menüler, duraklatma, yeniden başlatma, ses ayarı, klavye ve gerekiyorsa dokunmatik kontrol özenle tasarlanır. Menü ve yükleme ekranı jenerik motor demosu gibi bırakılmaz; Fragaria/AIONIA kimliğine uygun özel tasarım yapılır. Hareket azaltma, ses kapatma, okunabilir kontrast ve alternatif girişler uygun kapsamda değerlendirilir. Görsel gösteriş oynanışı engellemez.


6. TEKNİK VE PERFORMANS
Godot tabanlı mevcut proje tercih edilir; bağımsız Aionia Engine inşa edilmeyecek. GDScript/C# seçimi mevcut kod tabanına göre yapılır. Kod küçük, anlaşılır, modüler ve belgeli olmalı; tek kullanımlık oyun için gereksiz soyutlama yapılmaz. Web hedefinde HTML5 export, yükleme, tarayıcı uyumluluğu, giriş, ses başlatma, asset boyutu ve mobil ekran sınırları test edilir. Windows çıktısı da proje hedefiyse ayrıca doğrulanır. Vercel kullanımı projeye göre yapılandırılır; dağıtım başarılı varsayılmaz. Hedef FPS, bellek, indirme boyutu ve yükleme süresi proje bazında ölçülür; ölçülmemiş sayı raporlanmaz.


7. ÜRETİM VE TESLİMAT KAPILARI
A. Kaynak denetimi: repo, Drive assetleri, sürüm, mevcut hatalar, lisans.
B. Tasarım belgesi: oyun vaadi, evren bağı, referanslar, mekanikler, sanat kuralları.
C. Dikey dilim: tek kısa bölümde gerçek hareket, animasyon, UI, ses, oyun döngüsü.
D. İçerik üretimi: karakterler, bölümler, etkileşimler; tekrar kullanılabilir ama özgün.
E. QA: açılış, giriş, çarpışma, animasyon, kayıt, ses, UI, hata durumları, hedef cihazlar.
F. Yayın: temiz build, doğrulanmış URL/çıktı, sürüm notu, bilinen eksikler.
Her kapıda PASS / FAIL / NOT TESTED kullan. “Çalışıyor” yalnızca çalıştırılmış ve gözlenmişse denir. Eksik varlık, kırık bağlantı, sahte placeholder veya oynanamaz demo teslim tamamlandı sayılmaz.


8. REPO VE DOSYA KURALLARI
Her oyun bağımsız GitHub deposu olabilir. Projede /docs/AIONIA_STANDARD.md (bu belgenin sürümlü kopyası veya bağlantısı), /docs/ART_BIBLE.md, /docs/GAME_DESIGN.md, /docs/LORE_LINKS.md, /assets/sources, /assets/processed, /tests, /credits önerilir. Var olan projeyi zorla yeniden yapılandırma; uygun şekilde uyarlama yap. Drive normatif belge, repo ise uygulanabilir sürüm ve proje özelinde kararların kaydıdır. Kaynak dosyalarla işlenmiş çıktıları ayır. Değişiklikleri commit ve sürüm notuyla izle.


9. CODEX İÇİN DOĞRUDAN UYGULAMA KOMUTU
“AIONIA standartlarında oyun geliştir” ifadesi şu anlama gelir:
(1) Bu standardın güncel Drive belgesini ve projenin repo içi kopyasını oku, sürüm uyuşmazlığını bildir.
(2) Mevcut oyun, referans karakter paftaları, lore ve assetleri incele.
(3) AIONIA'nın sevimli-derin-epik kimliğine uygun, özgün, tutarlı pixel art ve oynanış tasarla.
(4) Godot'un mevcut altyapısını kullan; yeni motor yazma.
(5) Önce küçük oynanabilir dikey dilimi tamamla, sonra kapsamı genişlet.
(6) Animasyon, UI, ses, performans ve web dağıtımını gerçek testlerle doğrula.
(7) Kanon eklemelerini TASLAK olarak ayır; onaylanmamış lore'u resmileştirme.
(8) Değişen dosyaları, test sonuçlarını, eksikleri ve yayın durumunu açık raporla.
(9) Referanslar erişilemiyorsa durumu dürüstçe bildir; keyfî karakter veya asset ikamesi yapma.


10. KAPSAM DIŞI VE DEĞİŞİKLİK YÖNETİMİ
Bu standart bir oyun motoru geliştirme emri değildir. Yeni genel amaçlı engine, tüm oyun türleri için framework veya devasa lore ansiklopedisi zorunlu değildir. Sürüm değişiklikleri tarih, gerekçe ve önceki sürüm referansıyla kaydedilir. Kullanıcının açık onayı olmadan ana evren kimliği, marka hiyerarşisi ve mevcut karakterlerin temel tasarımı değiştirilmez.
