# Drive-By Wire · AIONIA oynanış tasarımı

## Oyuncu vaadi

MOMO ile hızlı, okunabilir ve tekrar denemesi kolay bir otoyol çatışmasında 1.200 metreyi aş; direksiyon her zaman senin elinde olsun.

Ton: sıcak yol arkadaşlığı ile çizgi film araç çatışması. Genel arcade oyuncusuna yöneliktir; resmî yaş derecesi yoktur. Bu sürüm bir kısa bölüm/dikey dilimdir. Dört yeni dünya veya yeni motor kapsamı yoktur.

## Döngü ve kurallar

Ana menü → isteğe bağlı garaj konuşması/yükseltme → Eve Giden Yol tercihi (can/destek hedefi veya mayın/ikmal hedefi) → şerit, turbo, fren ve çatışma → kapsül ve kısa görevler → 1.200 m başarı veya can bitince tercihe/hedefe göre bölüm sonu → tek adımda tekrar / garaj / ana menü. Ölümde kaybedilen sefer geri yüklenmez; güven, hafıza, rekor ve tercihler cihazda saklanır.

Üç ayırt edici mekanik:

1. **MOMO ile bağ:** Ruh hali ve hafıza sürer; sürüş girdisi reddedilmez. C ile sınırlı aralıkta destek ve enerji kazanılır. T sohbeti isteğe bağlıdır.
2. **Güvenli rota / ikmal kararı:** Turbo enerji harcar, bırakınca yenilenir. Onarım, enerji/mayın ve tek darbeli kalkan için şerit değiştirmenin riskini oyuncu seçer. En yakın ön veya arka tehdide otomatik nişan, yazı yazma ihtiyacını kaldırır.
3. **Seri ve sözleşmeler:** Düşman, başarılı kaçış ve ikmal seri puanını büyütür; hasar veya beş saniyelik seri boşluğu onu kırar. Mesafe/düşman/ikmal görevleri puan, can ve mayın verir. Aynı görev ödülü iki kez yazılmaz.

Üç düşman tipi korunur: arkadan yaklaşan çarpan araç, ateş eden kamyonet, engel bırakan kamyon. Düşman türleri mesafeyle açılır. Şerit değişimi 0,16 saniye; temel hız, hasar, beklemeler ve yeni ödüller `data/balance.json` içindedir. Eşikler insan oyuncularla uzun denge testinden geçmemiştir.

## İlk dakika ve erişim

İlk ekranda hedef, sol/sağ ok, turbo/fren, ateş ve mola görünür. Nasıl oynanır ekranı üç adımı ve kapsül şekillerini açıklar. Ana menü, yardım ve ayarlar fare, klavye odak sırası ve dokunmayla kullanılır. Açık pencereler arkadaki menü düğmelerini devre dışı bırakır. Odak veya kumanda kaybı seferi duraklatır; dönüşte basılı kalan eylemler temizlenir.

Mola, devam, tekrar, garaj, ana menü ve ortak ayarlara erişim sağlar. Ses aç/kapat ve düzey, kamera sarsıntısı, dekoratif hareket ayrı seçeneklerdir. Kayıt yazılamazsa bu oturumda uygulandığı ve diske yazılamadığı açıklanır. Web yüklemesi başarısızsa kullanıcıya yeniden deneme verilir.

## Tamamlanma ölçütü

Bu dilim için gerçek girdi, çatışma, üç destek kapsülü, puan/görev, başarı/ölüm, tekrar, kayıt, menü, ses ve web açılışı doğrulanır. PASS/FAIL/NOT TESTED sonuçları [QA.md](QA.md) içindedir. İnsanlarla eğlence testi ve hedef cihaz performansı, bu dilimin otomatik testleriyle eşdeğer sayılmaz.

## 0.5 kontrol ve hikâye kararı

[CONTROLS.md](CONTROLS.md) son kullanıcı onayını, seçenekleri ve çoklu girdi davranışını; [JOURNEY.md](JOURNEY.md) ilk bölümün anlamlı tercihlerini ve kanon sınırını kaydeder. Telefon/tablette kaydırma + eylemler, PC’de oklar/WASD + fare, gamepad’de analog/D-pad kullanılır. Dikey/yatay düzenler ayrıdır; sürüş için metin zorunluluğu yoktur.
