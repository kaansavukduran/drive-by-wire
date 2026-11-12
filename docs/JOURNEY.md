# Yolun Hafızası · 0.6.0

Üç adet 400 metrelik arcade etap ve aralarındaki üç karar, seçim kitabı biçiminde ilerler. Toplam sürüş mesafesi 1.200 metredir. Aynı otoyol çizimleri kullanılır; 13 ayrı harita iddiası yoktur. Oyuncu ateş, şerit, turbo/fren, mayın, sıyrılma ve destekle yolu açar; kararlar canı, mayını, trafik baskısını, ikmal sıklığını ve isteğe bağlı yol hedefini değiştirir. Hedefi kaçırmak hikâyeyi kilitlemez.

İlk ayrım sinyale yanıt vermek, bellek izini araştırmak veya güvenli yolu bulmaktır. İkinci ayrım ilk karara, üçüncü ayrım ilk iki karara göre değişir. On karar düğümü ve 22 seçenek vardır. Her kapanışın farklı bir metni, sonucu ve karar yolu bulunur. Kaza yapmak 14. bir son değildir: tamamlanan etaplar korunur, mevcut karar yeniden seçilir.

| Son | Karar yolu | Kapanış |
| --- | --- | --- |
| 01 | signal / share / anchor | Birlikte Yanan Işık |
| 02 | signal / share / release | Ayrı Yollar, Aynı Ses |
| 03 | signal / shield / stay | Dönüş Noktası |
| 04 | signal / shield / escort | Son Aracın Ardında |
| 05 | archive / open / broadcast | Sabah Yayını |
| 06 | archive / open / witness | Birbirini Hatırlayanlar |
| 07 | archive / seal / garden | Toprağın Hafızası |
| 08 | archive / seal / return | Kendi Adıyla |
| 09 | escape / convoy / lead | Bekleyen Öncü |
| 10 | escape / convoy / follow | Birlikte Varılan Yer |
| 11 | escape / alone / keep | Açık Ufuk |
| 12 | escape / alone / turnback | Kendi Seçiminle Dönmek |
| 13 | signal / share / sleep | Uyanacak Bir Sabah |

Karar seçilince etap başlangıç noktası diske kaydedilir. Kazanılan etap, puan, yol hedefi ve açılan sonlar aynı güvenli SaveStore kaydına yazılır. Yeniden açınca son etabın **başından** devam edilir; metre başına kayıt veya bulut senkronizasyonu yoktur. Yazma başarısızsa oturum içi ilerleme korunur ve kullanıcı bilgilendirilir. Yeni hikâye açılmış sonları korur. Veri sıfırlaması açık onaydan sonra tüm yerel ilerlemeyi siler.

Ana menüde Sonlar kitabı 13 yuvayı gösterir; yalnız kazanılan kapanışlar okunabilir. Kayıtlı ilerleme ve sonlar kitabı klavye, kumanda, fare ve dokunmayla kullanılır. Günlükte mevcut etabın konuşmaları ve önceki kararlar okunabilir; dünya durur.

Metinler `data/story_book.json`, sınırlı saf durum geçişleri `scripts/core/story_book.gd` içindedir. İki seçenekli eski bölüm yalnız eski kuralların regresyonlarında korunur; oyuncunun normal akışı yeni kitaptır. Dış diyalog/LLM servisi, yeni motor veya genel anlatı framework'ü eklenmedi.

## İLİN · OYUN / TASLAK

Kullanıcının yeni yapay zekâ karakter talebiyle yaratıldı. Adı **İLİN**. Yol izlerini okuyabilen, kendi belleği üzerinde söz hakkı isteyen bir yol arkadaşıdır. Sakin ve açık konuşur; riski söyler, oyuncuyu aşağılamaz. Hikâye bakım, rıza, tanıklık, topluluk ve özgürlük arasında seçimler kurar. Tek bir ahlaki puan tüm sonları iyi/kötü diye sıralamaz.

Görseli 48×44 pixel ızgarada kesik köşeli bir hafıza pusulasıdır: iki üst anten, yan yön kanatları, ortada bellek tohumu ve iki optik. Gri gövde, mint/amber/gül vurgu paleti, kısa konuşma ışığı. CRT/MOMO paftası ve üzerinde MOMO yazan çerçeve kullanılmaz. Azaltılmış harekette dekoratif animasyon durur; hasar bildirimi süresi yine biter. Yüz `scripts/game/companion_face.gd` içinde özgün Godot çizimidir.

İLİN'in varlığı, kökeni ve bu yolculuk **ana AIONIA kanon onayı değildir**. Kullanıcı oyun için yeni karakteri yetkilendirdi; ANA kanon kararı ayrı kalır. Aion, Kurt, Kuzu, Baykuş Ömer ve Tavşan Emre tasarımları yeniden çizilmedi. Eski kayıt/çekirdek dosyalarındaki `momo` kimlikleri uyumluluk için tutulur; oyuncuya gösterilen isim İLİN'dir.
