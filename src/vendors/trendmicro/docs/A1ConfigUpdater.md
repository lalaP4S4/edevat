# A1ConfigUpdater.ps1 Kullanım Kılavuzu

> [!WARNING]
> **BU SCRIPT DEPRECATED (ESKİ SÜRÜM) OLARAK İŞARETLENMİŞTİR.**
> Yeni projelerde ve güncel işlemler için lütfen **[TMConfigCheck.ps1](TMConfigCheck.md)** kullanın.

`A1ConfigUpdater.ps1`, Trend Micro `.ini` yapılandırma dosyalarını güvenli, yedekli ve kontrollü bir şekilde güncellemek için tasarlanmış bir araçtır.

## 📋 Genel Bakış

Bu script, manuel dosya düzenleme risklerini (hatalı yazım, format bozulması, yedek almayı unutma) ortadan kaldırır.

## 🛠 Kullanım

Script parametrelerle çalışır. Doğrudan tıklanarak çalıştırılmaz.

### İnteraktif Kullanım

Herhangi bir parametre girmeden scripti çalıştırarak menü üzerinden hazır ayarları (USB Logging, Unload vb.) uygulayabilirsiniz:

```powershell
.\A1ConfigUpdater.ps1 -Interactive
```

### Parametrik Kullanım

```powershell
.\A1ConfigUpdater.ps1 -FilePath "C:\ofcscan.ini" -Section "Global Setting" -Key "EnableUsbLogging" -Value "1"
```

## ⚙️ Parametreler

- `-FilePath` (Zorunlu): Güncellenecek dosyanın tam yolu.
- `-Section` (Zorunlu): Ayarın ekleneceği veya güncelleneceği başlık (örn: `[Global Setting]`).
- `-Key` (Zorunlu): Ayar adı (örn: `EnableUsbLogging`).
- `-Value` (Zorunlu): Atanacak değer (örn: `1`).
- `-NoBackup`: Dosya yedeği almadan işlemi yapar (Önerilmez).
- `-Force`: Değer zaten aynı olsa bile dosyayı tekrar yazar.

## 🔐 Güvenlik ve Yedekleme

Script çalıştırıldığında:

1. Mevcut dosyanın yanına `dosya_adi.ini-YYYYMMDD_HHMM.bak` formatında bir yedek oluşturur.
2. Dosya içeriğinde belirtilen Bab'ı arar.
3. Ayar varsa günceller, yoksa Bab'ın altına ekler.
4. Dosyanın UTF-8 formatını korur ve gereksiz boşlukları temizler.

## ❓ Sık Karşılaşılan Sorunlar ve Çözümleri

### 1. Dosya bulunamadı hatası

- **Çözüm**: `-FilePath` parametresine verdiğiniz yolun doğruluğundan emin olun.

### 2. Bab bulunamadı uyarısı

- **Neden**: Belirttiğiniz `[Section]` dosyada mevcut değil.
- **Sonuç**: Script bu Bab'ı dosyanın en sonuna otomatik olarak ekler ve ayarı içine yazar.

### 3. Değişiklik uygulanmadı (Ayar zaten mevcut mesajı)

- **Neden**: Değiştirmek istediğiniz anahtar ve değer zaten dosyada mevcut.
- **Çözüm**: Eğer dosyayı her halükarda tekrar yazmak isterseniz `-Force` parametresini kullanın.
