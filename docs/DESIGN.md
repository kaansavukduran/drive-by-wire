# Drive-By Wire: tasarım (sahibinin verdiği özgün belge, özet değil)

## Konsept
Distopik bir otoyolda geçen roguelite araba çatışması. Arabayı direksiyonla sürmüyorsun; arabanın yapay zekâsına (adı MOMO) klavyeden komut yazıyorsun. MOMO kırılgan, ilgi bekleyen bir dijital evcil hayvan ve komutlarını kendi ruh haline göre yorumluyor.

## Tasarım sütunları
1. **Yazmak = sürmek.** Tek oyuncu girdisi klavyeden yazılan komutlar. Mouse ve WASD ile sürüş yok.
2. **Zaman yavaşlar, baskı sürer.** Komut kutusu açıkken oyun ~%10 hıza düşer ama durmaz. Uzun düşünmenin bir bedeli var.
3. **İlişki bir kaynaktır.** MOMO'nun güveni ve ruh hali, cephane ya da can kadar önemli. Kaba, çelişkili ya da tehlikeli komutlar güveni düşürür; teselli, övgü ve tutarlılık güveni artırır.
4. **Garajda bağ kurulur.** Seferler arasında MOMO ile konuşursun, onu "beslersin" (enerji/parça), onarırsın. Kalıcı ilerleme araba değil, MOMO'nun kişiliği ve hafızası.

## Dikey kesit kapsamı (sadece bu kadar)
- 1 otoyol bölümü: 3 şeritli, sonsuz kayan, yukarıdan 2D.
- Oyuncu arabası: 3 şerit arası geçiş, hızlan/yavaşla, ön silah, arka mayın.
- 3 düşman tipi: çarpan araba (rammer), ateş eden kamyonet, yola engel bırakan kamyon.
- Komut sistemi, MOMO ruh hali sistemi (aşağıda).
- 1 garaj ekranı: MOMO ile 3–4 seçenekli kısa diyalog, 1 yükseltme seçimi, "sefere çık" butonu.
- Sefer sonu ekranı: mesafe, yok edilen düşman, güven değişimi, MOMO'nun bir cümlelik yorumu.
- Ses ve müzik yok veya placeholder.

Kapsam dışı: çoklu bölüm, hikâye modu, çok oyunculu, kayıt bulutu, Steam entegrasyonu, LLM/API çağrısı.

## Komut sistemi
- Herhangi bir harfe basınca komut kutusu açılır ve zaman yavaşlar. Enter ile gönderilir, Esc ile iptal edilir.
- Komutlar **Türkçe ve İngilizce** anlaşılmalı, büyük/küçük harf ve Türkçe karakter farklarına (ı/i, ş/s, ğ/g, ç/c, ö/o, ü/u) toleranslı olmalı.
- Ayrıştırıcı deterministik ve veri odaklı: niyet (intent) → anahtar kelime/eş anlamlı listesi bir JSON dosyasında; sahibi sonradan kelime ekleyebilmeli.
- Başlangıç niyetleri: `lane_left`, `lane_right`, `speed_up`, `slow_down`, `fire` (hedefli: "kamyona ateş et", "öndekine ateş"), `drop_mine`, `dodge`, `ram`, `comfort` ("aferin", "iyi gidiyorsun", "korkma"), `insult` (küfür/hakaret listesi → güven düşer).
- Bir mesajda birden fazla komut zincirlenebilsin: "sağa geç ve kamyona ateş et".
- Anlaşılmayan komutta MOMO kafası karışmış bir tepki versin; komut boşa gitsin ama oyun çökmesin.
- Yazım hatası toleransı: kısa kelimelerde Levenshtein ≤1, uzunlarda ≤2.

## MOMO ruh hali sistemi
- İki değer: `trust` (0–100, seferler arası kalıcı) ve `mood` (korkmuş / sakin / heyecanlı / küskün, sefer içinde değişir).
- Mood komut yorumunu etkiler:
  - **korkmuş:** saldırı komutlarını %X ihtimalle reddeder veya geciktirir, kaçış komutlarını hızlı uygular.
  - **heyecanlı:** komutları hızlı uygular ama bazen fazladan bir şey yapar (iki kez ateş, gereksiz şerit değişimi).
  - **küskün:** komutlara yavaş veya laf sokarak tepki verir; ancak `comfort` ile çıkar.
  - **sakin:** komutları olduğu gibi uygular.
- Mood'u değiştiren olaylar: hasar almak, yakın kaza, hakaret, övgü, art arda çelişkili komut, başarılı manevra.
- Tüm olasılıklar ve eşikler tek bir config dosyasında, ayarlanabilir.
- MOMO ekranda küçük bir yüz/ikon + konuşma balonu ile tepki versin (kısa cümleler, Türkçe; her mood için en az 5 farklı satır, aynı satır art arda tekrar etmesin).

## Teknik
- Godot 4.6.3, GDScript. Hedef Windows 11 (ayrıca Linux, Android, Web); 1440p'de net, 60 FPS sabit.
- Oyun mantığı (komut ayrıştırma, mood kuralları) sahne/düğümlerden ayrı, saf ve test edilebilir script'lerde.
- Niyet sözlüğü, MOMO replikleri ve denge değerleri kod dışı JSON dosyalarında.
- Testler: ayrıştırıcı ve mood geçişleri için headless birim testleri. En az 30 ayrıştırma örneği (Türkçe, İngilizce, yazım hatalı, zincirli, anlamsız).
- Kayıt: `trust` ve garaj seçimleri yerel dosyaya.
- Kök `README.md`: nasıl çalıştırılır, kontroller, dosya yapısı, config'in yeri.

## Kilometre taşları
1. İskelet: sonsuz kayan 3 şeritli yol, oyuncu arabası şerit değiştiriyor.
2. Komut kutusu: yazma, zaman yavaşlaması, ayrıştırıcı + testler.
3. Çatışma: 3 düşman tipi, silah, mayın, hasar, sefer sonu.
4. MOMO: mood/trust, tepki balonları, yorumun mood'a göre değişmesi.
5. Garaj döngüsü: diyalog, yükseltme, kayıt, yeni sefer.
6. Cila: denge, ekran sarsıntısı, okunabilirlik, README.

## Sahibin ek istekleri (2026-11-11)
- Görsel: placeholder değil, **piksel art**; kare kare animasyonlu sprite sheet'ler. Tarz örneği: `aion_endless_run` reposu.
- Sahibin karakterleri kullanılabilir: Aion (axolotl), Accursed Wise Wolf, Blessed Ignorant Sheep, Baykuş Ömer.
- Dağıtım: Windows portable + Setup, Linux, Android APK, Vercel üzerinde web; GitHub Releases.
- Dürüstlük: gerçekten çalıştırılıp doğrulanmayan şeye "çalışıyor" denmez.
