# AIONIA standardı · 0.7.0 uygulama kapsamı

Bu geliştirmede kullanıcı tarafından belirtilen güncel Drive belgesi ve 00_BAŞLA tekrar okundu. Belgenin başlığı eski v1.0 adını koruyor; **içerik sürümü v1.6**. Önceki proje notu v1.5'e dayanıyordu. Özel belge bağlantısı ve içeriği public pakete kopyalanmaz.

- Mevcut Godot 4.6.3/GDScript korunur. Yeni motor, framework, hesap veya telemetri eklenmez.
- Kullanıcı bu turda **sabit sanal joystick + eylem düğmeleri** seçti. Hareket modeli serbest X/Y oldu; önceki kaydırma kararı bunun için değişti. PC/gamepad aynı fizik modelini kullanır.
- Aion ana görseli, Kurt/Kuzu/Ömer/Emre paftaları ve önceki sprite kayıtları incelendi. Yeni sürücü/portre çizimleri istenen oyun uyarlamasıdır; final ana kanon varyantı ilan edilmez. Orijinaller korunur, private referans atlasları runtime'a gömülmez.
- Omega-3 kullanıcı tarafından verilen yeni addır. Eski dosya/kayıt kimlikleri uyumluluk için korunur. Üçüncü Nabız anlatısı, konuşmalar ve 13 son OYUN/TASLAK statüsündedir; başka bir oyunun öyküsü kopyalanmaz.
- Varsayılan koyu tema, açık/sistem seçenekleri, native sistem fontu ve HTML system-ui korunur. Godot Web Canvas gerçek OS font dosyasını çözmez; gömülü yedek sınırı sürer. Lexend alternatifi ve lisansı korunur.
- Marka yükleyicisi Fragaria pixel yazısı ve gerçek ilerleme/hata/yeniden deneme akışını kullanır. Özel çilek görseli public kaynağa eklenmez; nihai logo onayı iddia edilmez.
- Kontrol ailesi geometrisi, sabit pivot, sprite/hitbox/silah/mayın hizası ve ekran yönü regresyonları test edilir. V1.6 için eski önbellek geçişi ve doğru GitHub→Vercel commit/sürüm eşleşmesi korunur.
- Firefox/Gecko Linux testi gerçekten denendi; bu ortam WebGL 2 sunamadığında sonuç BLOCKED'dır. Chromium emülasyonu fiziksel Firefox Android, Safari/iOS veya Xbox kanıtı sayılmaz. Destek matrisi ve gerçek sonuçlar QA raporundadır.
