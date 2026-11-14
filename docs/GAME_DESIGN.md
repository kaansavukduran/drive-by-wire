# Drive-By Wire · tasarım 0.12.0

Oyuncu vaadi: Omega-3 ve arkadaşlarınla iki tehlikeli yolu aç, mola anlarında birbirinizi dinle; hikâyeye kaldığın yerden dön.

Hedef: araç çatışması ve karakter sohbeti seven tek oyuncu. Mevcut Godot 4.6.3, serbest XY sürüş ve onaylı sabit joystick/klavye/gamepad korunur. Yeni motor/framework yoktur.

Döngü: hazırlık/isteğe bağlı sohbet → sabit etap → 400m ve robot → ara sahne → sıradaki etap. Bu dilim ikinci ara sahneden sonra Devam edecek ile kapanır. 13 etap geliştirme planıdır; tamamlanmış içerik sayısı iki etaptır. Sohbetler dallansa da rota ve bitiş lineerdir.

Üç mekanik: dört yönde araç konumlandırma; ön ateş + sınırsız arka mayınla çift yönlü savunma; durdurulabilir karakter sahneleri ve kalıcı replik kayıtları. Ölüm aynı etap başına döndürür, diğer kayıtları silmez. Sonuç düğmeleri gamepad ile de kullanılabilir.

Koyu tema, tutarlı panel/odak aileleri, daha kompakt metin alanları, değişmeyen 44px eylemler ve kelime kaybetmeyen sayfalama kullanılır. Dekoratif hareket/ses ayrı kapatılabilir. Orijinal paftalardaki kısa oranlar ve ortak piksel işçiliği korunur. Uçurum sahnesinde görünen araç gövdeleri gerçekten temas eder; karakterler sabit ayak köklerine bağlıdır.

Kayıt/migrasyon ayrıntısı JOURNEY.md, kontrol kararı CONTROLS.md, gerçek test kapsamı QA.md. Fiziksel cihaz, yardımcı teknoloji ve insan eğlence testi otomasyona eşdeğer sayılmaz.
