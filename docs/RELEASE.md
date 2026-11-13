# 0.7.4 · Taşmayan telsiz ve HUD

Sağ telsizde uzun konuşmalar gerçek font ve satır aralığıyla sayfalanır; sayfa sayacı ve mola günlüğünde tam metin bulunur. Başlık portredeki konuşan kişiyi gösterir. Hikâye repliği bitmeden rastgele tepkiyle değiştirilmez; molada okuma süresi durur. Güven/kalkan, kontrol ipuçları, sol can/enerji, görev, hedef/bildirim ve sonuç alanları ayrıldı. Garaj aynı ölçüm yordamını kullanır. [Gerçek testler](QA.md); canlı yayın yerel testten ayrı doğrulanır.

# 0.7.3 · Gamepad sonuç seçimi ve PC eylemleri

Etap sonunda analog/D-pad ile seçim, A ile onay; odak kaybından klavye/kumanda ile dönüş. PC yol alanında sol tık öne ateş, sağ tık sınırsız arka mayın; Shift alan darbesi, R sıyrılma. X/C alternatifleri ve kayıtlı özel atamalar korunur. Sağ tık menüsü oyun tuvalinde açılmaz. Aynı main→Vercel otomatik web yayını kullanılır.

# 0.7.2 · Sabit garaj yerleşimi

Ana menü ve garajda Aion ve Ömer için ayrı zemin alanları; boşta yana kaydıran poz döngüsü kaldırıldı. Diyalog/yükseltme/hazırlık ve ekran yönünden dönüşte konum sabit kalır. Uzun garaj konuşması İleri ile sayfalanır; düğmeler karakter alanına taşmaz. Önceki sürüş, sınırsız mayın ve kayıt davranışı korunur. GitHub main → Vercel yayını aynı akıştadır.

# 0.7.1 · Kullanıcı geri bildirimi düzeltmeleri

Aion ve direksiyon yol yönüne döndü. Hikâye karar ekranında dört sabit sayfa; kaydırma gerekmez. Mayın sınırsız, bekleme süreli ve basılı tutmayla tekrar eder; arka mermilere karşı alan savunması sağlar. Aynı GitHub main → Vercel otomatik web dağıtımı kullanılır. Eski kayıtlar korunur. Ayrıntılı kapsam QA.md.

# Drive-By Wire 0.7.0 · Omega-3 / Üçüncü Nabız

[Oyunu aç](https://drive-by-wire.vercel.app/play/). Godot 4.6.3/GDScript korunur. `main` gönderimleri mevcut Git bağlantısıyla Vercel'e otomatik dağıtılır; web yayını GitHub Release beklemez. Sürüm/commit/giriş adresi `/version.json` içindedir.

İLİN adı oyuncu arayüzünde Omega-3 oldu. Kullanıcının açık seçimiyle üç şeritli giriş yerine yol içinde dört yönlü serbest hareket ve sabit sanal joystick geldi. PC oklar/WASD; gamepad sol çubuk/D-pad aynı fizik modelini kullanır. Turbo artık E/RB, fren Q/LT. Ön silah öne, mayın arkaya gider; bütün çıkışlar aynı araç merkezine bağlıdır.

- Yeni Aion sürücülü araç atlası: 8 poz, 64×96 hücre, sabit (32,45) pivot; oyun içi 48×80 boyut. Sakin göz kırpma, turbo, ön ateş ve hasar ifadeleri. Yeni beş kişilik statik portre atlası; oran/padding korunur.
- Üçüncü Nabız: 10 ayrım düğümü, 13 ayrı kapanış; Kurt, Kuzu, Baykuş Ömer ve Tavşan Emre ile ilerletilebilir konuşmalar. Yanıtlar ilişkiyi ve etap başındaki 7 sn kalkan veya +1 mayını etkiler. Aynı konuşma yanıtı tekrar ödül vermez.
- Namlu parlaması, mevcut patlama/duman paftaları, Omega-3 elektrik darbesi ve iki yeni sentez ses. Destek, yakın düşman mermilerini temizler. Hareket/sarsıntı/ses/titreşim tercihleri korunur.
- Yatay ekrandaki turbo/mola alanı çakışması düzeltildi. Arka mayın, ekran dışındaki takipçiye ulaşmadan silinmez. Sprite gövdesi, hitbox, kalkan ve silah çıkışları X/Y hareketinde birlikte kalır.
- Yeni görüntüler hücre hücre nearest örneklemeyle sabit piksel ızgarasına alındı; orijinal üretimler yerelde korundu. PNG toplamı 3.645.688 → 131.244 byte. İşlenmiş varlıklar repo içindedir; çalışma anında Drive gerekmez.

Mevcut güven, rekor, etap kaydı ve 13 sonun kimlikleri korunur. Eski `momo`/`ilin` dosya adları kayıt/kod uyumluluğu için kalabilir; görünen karakter adı Omega-3'tür. Önceki kayıtlar veri silinmeden açılır. Sürümlü HTML/JS/WASM/PCK ve açık oyunda isteğe bağlı güncelleme bildirimi korunur.

Yeni senaryo ve görsel uyarlamalar **OYUN/TASLAK** statüsündedir. Özel referans paftaları, belge bağlantıları, çilek görseli ve Git geçmişi bu yayına taşınmaz. Yeni ana kanon veya resmî logo onayı iddia edilmez. [Gerçek test kapsamı](QA.md).
