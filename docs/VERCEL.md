# Vercel ile ücretsiz web sürümü

Depodaki `vercel.json`, oyunu her dağıtımda kaynak koddan derler (`python3 packaging/build_web.py`) ve `build/web` klasörünü yayımlar. Sunucu, veritabanı, API anahtarı veya ortam değişkeni gerekmez. Vercel Hobby planı kişisel projeler için ücretsizdir ve planın kullanım sınırlarına tabidir. İndirilebilir paketler (Windows, Linux, Android) GitHub Releases'ta kalır.

## Depoyu bağla (bir kez)

1. https://vercel.com adresinde GitHub hesabınla giriş yap (ya da e-posta hesabına GitHub bağla).
2. **Add New… → Project** seç.
3. **Import Git Repository** altında **Continue with GitHub / Install GitHub App** seç. GitHub'da **Only select repositories** seçip `kaansavukduran/drive-by-wire` deposunu işaretle, **Install & Authorize**.
4. Vercel'de `drive-by-wire` satırındaki **Import** düğmesine bas.
5. Ayarlar:
   - **Framework Preset:** Other
   - **Root Directory:** `.` (değiştirme)
   - Build/Output/Install komutlarına dokunma; `vercel.json` belirler (Build: `python3 packaging/build_web.py`, Output: `build/web`).
   - Ortam değişkeni ekleme.
6. **Deploy**. İlk derleme resmi Godot editörünü ve web şablonlarını indirdiği için birkaç dakika sürer (yaklaşık 1 GB'lık şablon arşivi indirilir, yalnızca iki web şablonu saklanır). Derleme oyunun ana sahnesini bir kez başsız çalıştırır; betik hatası varsa dağıtım başarısız olur, bozuk sürüm yayımlanmaz.
7. Bitince Vercel'in verdiği `https://<proje-adı>.vercel.app` adresini aç. Koyu bir sayfa, ardından oyun açılmalı. Sayfa açılınca klavye doğrudan oyuna gider; yazmaya başlamak için tıklamak gerekmez (odak kaybolursa oyuna bir kez tıkla).

GitHub listesi boşsa Vercel'deki **Adjust GitHub App Permissions** bağlantısıyla depoya erişim verildiğini kontrol et. Proje adını `drive-by-wire` bırakırsan adres büyük olasılıkla `https://drive-by-wire.vercel.app` olur; ad alınmışsa Vercel farklı bir ad verir. Gerçek adresi README'ye yaz.

## Sonrası

- `main` dalına her gönderim otomatik yeni dağıtım yapar; pull request'ler ayrı önizleme adresi alır.
- Hizmet çalışanı (service worker) ve çevrimdışı önbellek yoktur: oyun her açılışta ağdan yüklenir, yeni sürüm bir sonraki yenilemede gelir. Dosyalar `max-age=0, must-revalidate` ile sunulur, eski sürüm takılı kalmaz.
- Tek iş parçacıklı (no-threads) Godot şablonu kullanıldığı için COOP/COEP başlıkları gerekmez.
- Kayıt (MOMO'nun güveni) tarayıcının bu alan adına ait yerel deposunda tutulur; başka tarayıcı veya alan adı ayrı kayıt demektir.

Depoda `vercel.json` bulunması, yayımlanmış bir adres olduğu anlamına gelmez. İlk dağıtımdan sonra canlı adreste oyunun açıldığı, PC’de oklar/WASD ve fare, telefon/tablette kaydırma + eylemlerle oynanabildiği ayrıca kontrol edilmeli.
