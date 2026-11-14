# Kontrol kararı · 0.7.3

Son açık kullanıcı seçimi: **sabit sanal joystick + eylem düğmeleri**. Önceki kaydırma şeması, kullanıcının istediği dört yönlü serbest sürüşe geçiş nedeniyle değişti. Üstten sabit kamera ve akan yol korunur; araç yol içinde X/Y eksenlerinde ilerler ve geri çekilir. Açık dünya veya gerçekçi geri vites simülatörü değildir.

Seçim öncesinde üç seçenek uygunluk sırasıyla sunuldu:

| Sıra | Kontrol | Avantaj | Dezavantaj |
| --- | --- | --- | --- |
| 1 · Kullanıcının seçimi | Sabit joystick + eylemler | Dört yön, hassas çapraz hareket ve tutarlı başlangıç noktası | Sol alt alanı kaplar |
| 2 | Dokunulan yerde beliren joystick | Parmağın konumuna uyum | Başlangıç noktası değişir, görsel yerleşimi takip etmek daha zor |
| 3 | Dört yön düğmesi + eylemler | Net basışlar | Analog hassasiyet sınırlı, daha fazla hedef |

Joystick’in merkezi sabittir; her dokunuş için yeniden konumlanmaz. Tek bir parmak sahibi olur. Ayrı parmak ateş/turbo tutabilir. Radyal ölü bölge %13; çapraz hareket normalize edilir. Girdisiz araç kısa sürede durur, yol kenarında gizli hız birikmez. Mola, yön değişimi ve odak kaybı parmak sahipliğini temizler. UI ekran koordinatlarında, dünya kendi ölçek/dönüşümünde kalır.

| Platform | Hareket | Ateş / mayın | Diğer |
| --- | --- | --- | --- |
| Telefon/tablet | Sol altta sabit joystick, dört yön | Sağda Öne Ateş / Arkaya Mayın | Turbo, fren, sıyrılma, Omega-3 desteği |
| PC | Oklar / WASD, basılı süre boyunca sürekli XY | Space/F veya fare sol; fare sağ/X mayın | E turbo, Q fren, Shift/C alan darbesi, R sıyrılma, Esc/P mola |
| Gamepad | Sol çubuk / D-pad | A/RT öne ateş; X arkaya mayın | RB turbo, LT fren, B/LB sıyrılma, Y destek, Start mola |

Menü ve NPC konuşmaları fare/dokunma veya yönler+A/Enter ile kullanılabilir. Konuşma / Yanıt / Rota / Günlük sabit sayfaları fare tekerleği gerektirmez; uzun günlük metni Sonraki sayfa düğmesiyle ilerler. Yeniden atama, gamepad ölü bölgesi, otomatik ateş, ses ve hareket tercihleri korunur. T sohbeti isteğe bağlı eski uyumluluk yoludur; sürüş metin gerektirmez.

Ön silah, arkadaki hedef için yönünü tersine çevirmez. Ön hedefe küçük nişan yardımı vardır; çıkış noktası her zaman aracın ön merkezidir. Mayın arka merkezden çıkar. İki silahın da çıkışı, oyuncu hitbox'ı ve sprite pivotu aynı fizik X/Y konumuna bağlıdır.

Portre: joystick solda; sağda eşit geometriye sahip iki sütun/üç sıra eylem. Yatay: sol joystick; sağ tarafta konuşma, ayrı mola ve üç sıra eylem. Joystick, eylemler ve mola alanları için taşma/çakışma regresyonu vardır. Fiziksel telefon/tablet veya Xbox testi, yazılım emülasyonu yerine gösterilmez.

0.7.1: Mayın sınırsızdır. X veya dokunmatik Mayın düğmesini basılı tutmak bekleme süresi dolunca tekrar bırakır. Varsayılan 0,7 sn, eski mayın yükseltmesi/rota desteği başına 0,05 sn daha kısa, alt sınır 0,3 sn. Mayın 0,12 sn sonra etkinleşir; arka mermi temasında patlar, 60 piksel içindeki düşmanlara hasar verir ve mermileri temizler. Mola süreyi durdurur. İkmal ve görev ödülü beklemeyi sıfırlar; eski cephane bitmesi sürüşü engellemez.

0.7.3: Etap sonundaki Sonraki seçim / Garaj / Kararı gözden geçir düğmeleri analog veya D-pad ile seçilir; A/Enter seçili düğmeyi onaylar, B garaja döner. Açık yatay/dikey ve Tab odak yolları var; odak kaybolursa kumanda/klavye geri getirir. Fare sağ basılı mayın bırakır; HUD üstünde bırakılsa da tutulma temizlenir. Shift mevcut Omega-3 alan darbesidir: 90 mantıksal piksel yakınındaki düşman mermilerini temizler ve enerji desteği verir; bekleme 8 sn. R sıyrılma. Özel klavye/gamepad atamaları ve kayıt biçimi korunur.
