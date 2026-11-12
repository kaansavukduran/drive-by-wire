# Kontrol kararı · 0.5.0

12 Kasım 2026. Tür: üç şeritli, üstten görünen otoyol aksiyonu. Kamera doğrultusu sabit, araç şeritler arasında geçer. Temel eylemler: yön, turbo/fren, ateş, mayın, sıyrılma ve İLİN desteği. Hedefler: telefon/tablet dikey-yatay, PC ve gamepad. İki başparmak kullanımında eylem basılıyken yön değiştirilebilmelidir.

Kontrol şemasını seçmeden önce 2–4 uygun seçenek karşılaştırılır, birincil öneri sunulur ve kullanıcının seçimi beklenir. Açık onay olmadan değişiklik yapılmaz. Kullanıcının son açık seçimi, önceki virtual joystick isteğini değiştirmiştir: **“Sağa/sola kaydırma + eylem düğmeleri olsun mobil ve tabletten oynarken.”**

| Sıra | Tarz | Avantaj | Dezavantaj / karar |
| --- | --- | --- | --- |
| 1 · Öneri ve onaylanan | Sağa/sola kaydırma + eylem düğmeleri | Şerit modeliyle doğal, daha az yön düğmesi; ayrı parmak ateşte kalabilir | Dikey/çapraz hareket ve küçük titreşim ayrılmalı; hareket kısıtı olan kullanıcılar için evrensel çözüm iddiası yok |
| 2 | Sabit sol/sağ + eylem düğmeleri | Kesin ve öğrenmesi kolay | Fazla ekran alanı ve eşzamanlı dokunma ihtiyacı |
| 3 | Sol/sağ bölgeye dokunma + eylemler | Büyük hedef ve hızlı tepki | Eylem düğmelerine yakın yanlış yön girişi riski |
| 4 | Virtual joystick + eylemler | Sürekli yön hissi, serbest hareketli oyunlarda tanıdık | Bu üç şeritli modelde çubuk/nötr eşikleri gerekir; kalıcı parmak ve ekran alanı tüketir. Son seçim bu tarz değildir |

## Uygulanan davranış

Yol alanında başlayan yatay kaydırma 30 mantıksal piksel eşiğini ve yatay/dikey oranını geçince tek şerit değiştirir. Uzun veya geri dönen aynı hareket ikinci bir şerit atlatmaz; parmak kaldırılıp yeni hareket başlatılır. Küçük titreşim, dikey hareket ve yol dışında başlayan dokunma yön vermez. İkinci parmak ilk hareketin sahipliğini alamaz. Eşik Godot'un ölçeklenmiş UI koordinatlarındadır; düşük güç tamponu ve ekran ölçeği fazladan dönüşüm yaratmaz.

Ateş ve turbo basılı tutulabilir. Fren, mayın, sıyrılma ve destek açık etiketli düğmelerdir. Dikeyde iki sıra; yatayda yan alanlar kullanılır. Mola, odak kaybı ve yön değişiminde işaretçi/eylem durumları temizlenir. Ekran yönü değişince mola verilir; kullanıcı devam eder. Ayarlar içindeki otomatik ateş mevcut isteğe bağlı erişim tercihidir; kendiliğinden açılmaz.

PC: sol/sağ veya A/D bir şerit; yukarı/W turbo; aşağı/S fren; Space/F ateş; X mayın; Shift sıyrıl; C destek. Yol alanında fare sol basılı ateş, sağ sıyrılma; menüye tıklamak ateş etmez, yol dışında bırakmak ateşi keser. Sürüş için metin girmek gerekmez. T ile eski isteğe bağlı sohbet sistemi korunur.

Kumanda: analog/D-pad, A/RT ateş, RB turbo, LT fren, X mayın, B/LB sıyrıl, Y destek, Start mola. Menülerde A onay, B geri; tüm ana akış kontrolcüyle ilerler. Yeniden tuş/düğme atama ve ölü bölge ayarı korunur. Fiziksel cihaz testiyle yazılım emülasyonu aynı kabul edilmez.

[Gerçek test kapsamı](QA.md).

0.6.0: kullanıcı “Öneri 1’i uygula, onaylıyorum” diyerek kaydırma + eylemleri yeniden onayladı. Yeni seçim kitabı sürüşün türünü/kamerasını/hareket modelini değiştirmez. Onaylı şema korunur; eşit tam pixel düğme genişlikleri ve mobil menü hedefleri mevcut şema içinde iyileştirilir.

0.6.1: kontrol şeması aynı kalır. Kesik çizgi yaklaşan atışın kilitli hedefini, `!` işareti hazırlanmakta olan engeli gösterir; oyuncu onaylı şerit/sıyrılma girdileriyle kaçabilir. Yeni kontrol seçimi veya joystick eklenmedi.
