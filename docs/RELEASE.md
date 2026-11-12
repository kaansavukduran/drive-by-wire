# Drive-By Wire 0.2.0 · Arcade Forge

12 Kasım 2026 · Fragaria Interactive · Aionverse

Ok tuşları ana kontroldür. MOMO'nun ruh hali doğrudan direksiyon, silah veya kaçış girdisini geciktirmez. T ile açılan sohbet ve eski ayrıştırıcı isteğe bağlıdır.

Yeni: basılı turbo/fren/ateş, enerji yönetimi, onarım/enerji/kalkan kapsülleri, çarpanlı puan serisi, kısa görev ödülleri, 1.200 m başarı ekranı, yeniden sürüş düğmeleri, yerel rekor, gerçek mola, odak/kumanda kaybında mola, çoklu dokunma düğmeleri, D-pad eşlemesi, özgün kısa sesler, ayrı ses/sarsıntı tercihleri. Garajda Space ile hızlı sürüş vardır. Mevcut Aion ve Ömer çizimleri korunur.

## Bu çalışmada doğrulananlar

| Hedef | Gerçek durum |
| --- | --- |
| Godot 4.6.3 | Altı headless test takımı; gerçek sefer sahnesine klavye ve iki parmak olayları gönderildi. |
| Web | Release export üretildi; yerel HTTP sunucusunda Chromium ile garaj, sürüş, mola/devam ve telefon boyutunda çoklu dokunma incelendi. |
| Windows / Linux / Android native | Mevcut export/CI profilleri korundu. Bu çalışma sırasında yeni native paket üretilmedi veya cihazda test edilmedi. |
| Vercel canlı site | Üretim sitesi yayımlanmadı. Yerel web paketi canlı Vercel sürümü değildir. |
| Fiziksel kumanda, telefon, Safari | Test edilmedi. Tarayıcı dokunma emülasyonu fiziksel cihaz testi değildir. |

`DriveByWire-0.2.0-web.zip` dosyasını çıkartıp o klasörde `python3 -m http.server 8765` çalıştır; `http://localhost:8765` aç. Kaynak ZIP'i Godot projesidir. Releases sayfasındaki 0.1.0 kurulumları yeni sürümü içermez.

## Sınırlar

Bu sürüm hâlâ geliştirilen bir arcade oyunudur. İnsan oyuncularla eğlence/denge testi yapılmadı. Müzik ve tam dil seçimi yoktur; arayüz Türkçedir. Kısa ses efektleri vardır. Dikey telefonda oyun alanı küçülür; yatay ekran önerilir. Canlı sefer geri yüklenmez; rekor, güven, hafıza ve tercihler saklanır. Windows imzası ve mevcut Android prototip anahtarı için [BUILD.md](BUILD.md) geçerlidir; yeni mağaza yayını yapılmadı.
