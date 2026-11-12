# Arcade Forge · Geliştirme ve doğrulama kaydı

12 Kasım 2026 · Kaynak tabanı `f7fd67082eec6609a66b5e8c40dc5dcea774925f` · Yeni sürüm 0.2.0

## İnceleme sonucu

0.1 sürümünde her harf oyun zamanını %10'a indiren komut kutusunu açıyordu. Şerit değişimi dahi MOMO'nun ruh haline bağlı olarak gecikebiliyordu. HUD metni yolun üstüne taşıyor, amaç yalnızca ölüm gelene kadar ilerlemekti. İkmal çizimleri vardı fakat seferde toplanan destek döngüsü yoktu. Duraklatma, doğrudan dokunmatik sürüş ve ses geri bildirimi yoktu.

Kullanıcının yeni kararı tasarımı değiştirir: anında ok tuşlu sürüş birincildir. MOMO kişilik, ilişki ve garaj hafızasını taşır. İsteğe bağlı sohbet T ile açılır; eski parser testleri korunur. Direksiyon/silah/kaçışın doğrudan girdileri MOMO yorumuna girmez.

## Fragaria / Aionverse kaynaklarının kullanımı

- [Drive proje rehberi](https://docs.google.com/document/d/1-hHPx3KPhnD5uNrBq-52E7NfWGh1oS93RYnB5tN7fYc/edit): doğru repo ve yedek yapısı bulundu. Eski yedekler değiştirilmedi.
- [Aion Endless Run](https://github.com/kaansavukduran/aion_endless_run), mevcut README: net doğrudan kontrol, mola, çoklu dokunma, yerel tercihler ve görsel okunabilirlik referansı.
- [Save the Planet geliştirme briefi](https://docs.google.com/document/d/1zET837DgEs98lPp9jHPhCEplHGt82VC3yctOpXe786Y/edit): Fragaria Interactive yayıncı adı, kanonik karakterleri koruma, renk yanında şekil, odak kaybında mola ve doğrulama dürüstlüğü ilkeleri. Başka oyuna ait hikâye/bölüm kapsamı bu oyuna taşınmadı.
- [Fragaria Classification System taslağı](https://drive.google.com/file/d/1A0dxkJbgimSMA1Hg8a3WqeVT1SgnjnJC/view): belge kendi kapsamını sınıflandırma olarak tanımlıyor; kalite sertifikası sayılmadı, kayıt kimliği uydurulmadı.

Aionverse için ayrı, yayımlanmış bir oyun kalite standardı belgesi aramada bulunamadı. Bu çalışma yukarıdaki gerçek referanslara dayanır; resmî sertifikasyon iddiası değildir. Mevcut Aion / Ömer, MOMO, araç ve çevre paftaları değiştirilmedi. Lexend ana yazı tipi korundu, dört ok glifi için lisanslı küçük bir DejaVu alt kümesi eklendi. Fragaria Interactive ve Aionverse isimleri garajda; Fragaria adı sürüş HUD'ında görünür.

## Yeni oyun döngüsü

1. Garajda doğrudan Space ile zırhlı hızlı sürüş veya diyalog + yükseltme.
2. Oklarla şerit değiştir; yukarı okla sınırlı enerji kullanarak turbo, aşağı okla fren. Boşluk/F basılıyken ön/arka en yakın tehdide ateş. X mayın, Shift sıyrılma, C destek.
3. Onarım, enerji/mayın ve tek darbeyi emen kalkan kapsüllerini topla. Şekiller renk bilgisi olmadan da ayırt edilir.
4. Seri puanını büyüt; hasar veya beş saniyelik seri boşluğu çarpanı sıfırlar. Mesafe, düşman ve ikmal görevleri sırasıyla gelir; ödülleri bir kez verilir.
5. 1.200 metrede başarı; ölümde tekrar deneme. Sonuç ekranından tek adımda yeniden sür veya garaja dön. Rekor, güven, hafıza ve tercihler yerelde kalır.

Tüm yeni denge sayıları `data/balance.json` içindeki `run.arcade` alanındadır. Puan/görev mantığı sahneden bağımsız `scripts/core/arcade.gd` içindedir. Yeni sesler dış örnek içermeyen kısa sentezlerdir; müzik eklenmedi.

## Doğrulama

Godot 4.6.3 / Linux çalışma ortamında altı test takımı: parser 110, MOMO 89, garaj/kayıt 72, mevcut sefer 14, yeni arcade sahnesi 32, tam sefer 4; **321 başarılı, 0 başarısız**. Gerçek sahneye klavye ve iki parmak olayları gönderilir. Küs MOMO sırasında gecikmesiz sürüş, turbo tüketimi, fren, ateş/mayın, mola, ayrı parmakların bırakılması, gerçek kapsül çarpışması, tek darbeli kalkan, görev, başarı, ödülün tek verilmesi, rekor ve tercih kaydı sınanır. Sabit 42 tohumlu tam sefer simülasyonunda basit ateş/turbo/ikmal takip stratejisi, 91,15 oyun saniyesinde 1.200 metreye ulaştı: 31 düşman, 17 kapsül, 6 görev ve 5.640 puan. Bu otomatik simülasyondur; insan oyuncu testi değildir.

```sh
bash tests/run_all.sh
python3 packaging/build_web.py
python3 -m http.server 8765 --directory build/web
# Ayrı terminal, Playwright kuruluysa:
DBW_CHROMIUM=/usr/bin/chromium node tests/browser_smoke.cjs
```

Yazma kısıtlı ortamlarda Godot'un XDG_DATA_HOME, XDG_CONFIG_HOME ve XDG_CACHE_HOME yollarını proje içindeki geçici `work/runtime/` altına yönlendirmek gerekir. Test kayıtları oyuncunun gerçek kaydını değiştirmeyen ayrı adlar kullanır.

Web export resmî SHA-512 doğrulamalı şablonlarla üretildi. Derleme kontrolü hem garajı hem gerçek sefer sahnesini açar ve script hatalarında durur. Chromium 1280×720 masaüstü ve 844×390 dokunmatik emülasyonda çalıştırıldı. Mola sırasında yol görüntüsünün sabitliği ve tarayıcı hata kaydı kontrol edilir; ekran görüntüleri ayrıca incelendi. İki parmakla turbo ve ateş aynı anda kullanılabilir. Fiziksel cihaz testi veya insan oyuncu eğlence testi yapılmış sayılmaz.

![Masaüstü sefer](evidence-v020/run.png)

![Telefonda iki parmakla turbo ve ateş](evidence-v020/mobile-multitouch.png)

## Teslim ve sınırlar

Web ZIP'i HTTP sunucusundan oynanır; çift tıklamayla açılmaz. Kaynak ZIP'i Godot projesidir. GitHub geliştirme dalı ana sürümden ayrıdır. Bu çalışma üretim Vercel sitesini değiştirmez ve yeni Windows/Linux/Android native paketi yayımlamaz. Bu hedeflerin mevcut CI/export profilleri korunur; fiziksel kumanda ve telefon, Safari, native kurulumlar ve insanlarla uzun denge testi sonraki doğrulama hedefleridir. Oyun arayüzü Türkçedir. Dikey telefonda alan küçülür; yatay ekran önerilir.

[Drive önizleme paketleri](https://drive.google.com/drive/folders/1bvUEq2Q_bgTZApV2xbQXnNgVmJdONoPU): kaynak, web ve doğrulama arşivi. Eski kaynak yedekleri aynı kimlik ve konumlarıyla korundu.
