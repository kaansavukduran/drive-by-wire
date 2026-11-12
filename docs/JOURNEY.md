# Eve Giden Yol · ilk oynanabilir bölüm

Bu, mevcut MOMO ve garaj ilişkisi üzerinden yazılmış **OYUN / TASLAK** bölümüdür. AIONIA ana kanonuna yeni şehir, tarih, karakter veya köken eklemez; resmî evren onayı iddiası yoktur. Kullanıcı anlamlı hikâyeli oyun istediği için ilk bölüm üzerinde çalışılmıştır; tamamlanmış çok bölümlü kampanya değildir.

Oyuncunun amacı MOMO'ya verdiği birlikte eve dönme sözünü tutmaktır. Başla veya garaj yükseltmesinden sonra, dünya henüz akmadan iki açık tercih sunulur:

- **Birbirimizi kollayalım:** +15 azami can; yol boyunca MOMO'ya en az bir kez destek ol.
- **İkmal toplayalım:** +2 mayın; en az iki ikmal kapsülü topla.

İki yol aynı 1.200 metrelik bölümü paylaşır; farklı harita sunulduğu iddia edilmez. Tercih gerçek kaynakları ve isteğe bağlı hedefi değiştirir. 300, 650 ve 1.000 metre diyalogları ilişkiyi yolculuk boyunca sürdürür. Görülmüş satırlar mola menüsündeki Yol günlüğünde tekrar okunur; günlük açıkken dünya durur. Hedefler sürüşten önce açıklanır ve HUD'da takip edilir.

Sonuç, eve varma/başaramama ve tercih hedefinin tamamlanmasına göre farklılaşır. Başarısızlık ilişkiyi bitirmez; yeni deneme için anlamlı bir karşılık verir. Bölüm tamamlama sayısı, son yol ve hedef durumu mevcut yerel hafızaya kaydolur. Aynı sonuç iki kez işlenmez. Eski kayıtlarda bu alanlar güvenli varsayılanlarla açılır.

Metin ve eşikler data/journey.json, küçük sahnesiz durum mantığı scripts/core/journey.gd, yol öncesi UI scripts/game/journey_screen.gd içindedir. Sürüş, çatışma ve kayıt mevcut Godot altyapısındadır. Yeni çizim, dış diyalog servisi, yeni motor veya genel hikâye framework'ü yoktur. İnsan oyuncu eğlence ve anlatı değerlendirmesi ayrıca gerekir.
