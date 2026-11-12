# Drive-By Wire 0.1.0 · İlk oynanabilir prototip

Arabayı direksiyonla değil, yazarak sürüyorsun. Arabanın yapay zekâsı MOMO komutlarını ruh haline göre yorumluyor. Bu bir **prototip**: çekirdek döngü (garaj → sefer → sefer sonu) oynanabilir, çizimlerin bir kısmı hâlâ geçici.

- Garajda MOMO ile kısa diyalog (1–4), bir yükseltme seçimi, Enter ile sefere çıkış.
- Herhangi bir harf komut kutusunu açar ve zamanı yavaşlatır; Enter gönderir, Esc vazgeçer.
- Türkçe ve İngilizce komutlar, Türkçe karakter ve küçük yazım hatası toleransı, zincirli komutlar (`sağa geç ve kamyona ateş et`).
- Üç düşman tipi, ateş, mayın, kaçış, çarpma; MOMO'nun ruh hali ve kalıcı güveni.
- Güven ve garaj seçimleri cihazda yerel olarak kaydedilir. İnternet gerekmez (web sürümü hariç).

## İndir

**Assets** bölümünden cihazına uygun dosyayı seç:

| Cihaz | Dosya | Nasıl açılır |
| --- | --- | --- |
| Windows 10/11 x64, kurulumlu | `DriveByWire-0.1.0-windows-x64-Setup.exe` | Aç ve kur. Yönetici izni istemez; kendi kullanıcı klasörüne kurar, Başlat menüsüne kısayol ekler, Uygulamalar listesinden kaldırılır. |
| Windows x64, taşınabilir | `DriveByWire-0.1.0-windows-x64-portable.zip` | ZIP'i tamamen çıkart, `DriveByWire.exe` dosyasını aç. Tek dosya; kurulum yok. |
| Linux x64 | `DriveByWire-0.1.0-linux-x64.AppImage` | Çalıştırma izni ver (`chmod +x`), aç. |
| Debian / Ubuntu | `DriveByWire-0.1.0-linux-x64.deb` | `sudo apt install ./DriveByWire-0.1.0-linux-x64.deb`; menüde "Drive-By Wire" çıkar. |
| Linux x64, taşınabilir | `DriveByWire-0.1.0-linux-x64-portable.tar.gz` | Çıkart, `DriveByWire/DriveByWire.x86_64` dosyasını çalıştır. |
| Android 7.0+ (ARM64 / x86_64) | `DriveByWire-0.1.0-android-arm64-x64.apk` | APK'yı açıp kur; sistem bilinmeyen kaynak izni isteyebilir. |
| Tarayıcı, çevrimdışı kopya | `DriveByWire-0.1.0-web-offline.tar.gz` | Çıkart ve yerel bir sunucuyla aç (`python3 -m http.server`). Doğrudan çift tıklamayla açılmaz. |

`SHA256SUMS` dosyası tüm paketlerin özetlerini içerir.

Oyun klavyeyle oynanır. Android'de fiziksel klavye en rahatıdır; ekran klavyesiyle deneyim henüz doğrulanmadı.

## Platform durumu (dürüst tablo)

| Platform | Durum |
| --- | --- |
| Linux (tar.gz, AppImage, deb) | CI'da derlendi; her biri başsız (headless) çalıştırılıp ana sahneyi hatasız yükledi. Görüntü/ses/klavye gerçek masaüstünde doğrulanmadı. |
| Windows (portable, Setup) | CI'da derlendi; exe başsız çalıştı, kurulum sessiz kuruldu, kurulan exe çalıştı, kaldırıcı çalıştı. Gerçek bir Windows 11 makinesinde ekranla oynanarak doğrulanmadı. |
| Web | Chromium'da yüklenip yazarak oynandı. Canlı Vercel adresi, sahibi depoyu Vercel'e bağladığında oluşur. |
| Android | CI'da derlendi ve imzası doğrulandı. Gerçek bir telefonda ya da emülatörde açılış doğrulanmadı. |
| macOS / iPhone | Yok. |

## Bilinen sınırlar

- Windows paketleri Authenticode ile imzalı değildir; SmartScreen "Bilinmeyen yayımcı" uyarısı gösterebilir ("Ek bilgi → Yine de çalıştır").
- Android APK, depoda **herkese açık bırakılmış bir prototip anahtarıyla** imzalanır. Bu, sonraki prototip sürümlerinin güncelleme olarak kurulabilmesi içindir; ama aynı anahtarla başkası da APK imzalayabilir. APK'yı yalnızca bu deponun Releases sayfasından indir. Gerçek anahtara geçildiğinde prototipi kaldırıp yeniden kurmak gerekir (kayıt silinir). Ayrıntı: `docs/BUILD.md`.
- Kayıt, Godot'un kullanıcı veri klasöründedir (Windows: `%APPDATA%\Godot\app_userdata\Drive-By Wire`, Linux: `~/.local/share/godot/app_userdata/Drive-By Wire`). Kaldırma kaydı silmez.
- Ses ve müzik yok ya da geçici.
