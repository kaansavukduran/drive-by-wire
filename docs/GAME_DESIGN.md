# Drive-By Wire · AIONIA oynanış tasarımı

## Oyuncu vaadi

İLİN ile üç kısa arcade etapta yol aç; aralardaki seçimlerle 13 farklı gelecekten birine ulaş. Genel arcade ve seçim kitabı oyuncularına yönelik yerel tek oyunculu bir oyun. Yaş derecesi alınmadı. Mevcut Godot 4.6.3, üç şeritli kamera/hareket ve çevre çizimleri korunur.

## Döngü

Fragaria yükleyicisi → ana menü → isteğe bağlı garaj/yükseltme → karar → 400 m arcade → yeni karar → ikinci 400 m → son karar → son 400 m → seçilen kapanış ve sonlar kitabı. Başarısızlık tamamlanan etapları silmez. Devam et mevcut etabın başından açar. Yeni hikâye açılmış sonları korur. [JOURNEY.md](JOURNEY.md) karar ağacını, kaynak etkilerini, kayıt kurallarını ve İLİN taslağını ayrıntılandırır.

Üç ayırt edici mekanik:

1. **İLİN ile bağ:** Ruh hali ve hafıza sürer; sürüş girdisi reddedilmez. C ile sınırlı aralıkta destek ve enerji kazanılır. T sohbeti isteğe bağlıdır.
2. **Güvenli rota / ikmal kararı:** Turbo enerji harcar, bırakınca yenilenir. Onarım, enerji/mayın ve tek darbeli kalkan için şerit değiştirmenin riskini oyuncu seçer. En yakın ön veya arka tehdide otomatik nişan, yazı yazma ihtiyacını kaldırır.
3. **Seri ve sözleşmeler:** Düşman, başarılı kaçış ve ikmal seri puanını büyütür; hasar veya beş saniyelik seri boşluğu onu kırar. Mesafe/düşman/ikmal görevleri puan, can ve mayın verir. Aynı görev ödülü iki kez yazılmaz.

Üç düşman tipi korunur: arkadan yaklaşan çarpan araç, ateş eden kamyonet, engel bırakan kamyon. Düşman türleri mesafeyle açılır. Şerit değişimi 0,16 saniye; temel hız, hasar, beklemeler ve yeni ödüller `data/balance.json` içindedir. Eşikler insan oyuncularla uzun denge testinden geçmemiştir.

## İlk dakika ve erişim

İlk ekranda hedef, sol/sağ ok, turbo/fren, ateş ve mola görünür. Nasıl oynanır ekranı üç adımı ve kapsül şekillerini açıklar. Ana menü, yardım ve ayarlar fare, klavye odak sırası ve dokunmayla kullanılır. Açık pencereler arkadaki menü düğmelerini devre dışı bırakır. Odak veya kumanda kaybı seferi duraklatır; dönüşte basılı kalan eylemler temizlenir.

Mola, devam, tekrar, garaj, ana menü ve ortak ayarlara erişim sağlar. Ses aç/kapat ve düzey, kamera sarsıntısı, dekoratif hareket ayrı seçeneklerdir. Kayıt yazılamazsa bu oturumda uygulandığı ve diske yazılamadığı açıklanır. Web yüklemesi başarısızsa kullanıcıya yeniden deneme verilir.

## Tamamlanma ölçütü

Bu dilim için gerçek girdi, çatışma, üç destek kapsülü, puan/görev, başarı/ölüm, tekrar, kayıt, menü, ses ve web açılışı doğrulanır. PASS/FAIL/NOT TESTED sonuçları [QA.md](QA.md) içindedir. İnsanlarla eğlence testi ve hedef cihaz performansı, bu dilimin otomatik testleriyle eşdeğer sayılmaz.

## Güncel kontrol ve hikâye kararı

[CONTROLS.md](CONTROLS.md) son kullanıcı onayını, seçenekleri ve çoklu girdi davranışını; [JOURNEY.md](JOURNEY.md) üç etap/13 sonun anlamlı tercihlerini ve kanon sınırını kaydeder. Telefon/tablette kaydırma + eylemler, PC’de oklar/WASD + fare, gamepad’de analog/D-pad kullanılır. Dikey/yatay düzenler ayrıdır; sürüş için metin zorunluluğu yoktur.

## 0.6.1 · Oyuncuya tepki fırsatı

Kamyonet 0.55 saniye önceden kilitlenen nişan çizgisi; kamyon 0.65 saniye önceden engel noktası gösterir. Atış sırasında hedef sonradan oyuncuyu izleyerek değişmez. Kamyon güvenli bırakma alanını geçerse hazırlanan engeli iptal eder. Şerit kıran çarpan aracın yönü işaretlenir. Uyarılar renk yanında şekil/konumla anlaşılır; dekoratif hareket kapalıyken ve mola sırasında bilgi korunur. Cooldown saldırı hazırlığının başında kurulur, böylece sonraki saldırı aralığı mevcut dengede kalır.

Trafik, dekoratif çizimler ve İLİN replikleri ayrı RNG akışlarıdır. Kamera fiziğin zamanından örneklenir; render sayısıyla yeni şans çekmez. Ekran dışı mermi ömrü düşmanların canlı kaldığı alanla sınırlıdır. Bunlar ayar değişimini zorluk değişimine dönüştürmez.
