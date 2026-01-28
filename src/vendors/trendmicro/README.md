# Trend Micro Apex Installation & Diagnostic Tools

Bu dizin, Trend Micro Apex One ve Apex Central kurulum hazırlığı, yapılandırması ve diagnostic işlemleri için optimize edilmiş, birleştirilmiş (superset) PowerShell betiklerini içerir.

## 📂 Dizin Yapısı

- **[A1PreReqCheck.ps1](A1PreReqCheck.ps1)**: Merkezi diagnostic ve ön hazırlık aracı.
- **[A1ConfigUpdater.ps1](A1ConfigUpdater.ps1)**: Güvenli INI (ofcscan/ofcserver) güncelleyici.
- **[A1Tools.ps1](A1Tools.ps1)**: Yardımcı araçlar kütüphanesi ve SQL/Versiyon/Sertifika sorgulayıcı.
- **[CHANGELOG.md](CHANGELOG.md)**: Sürüm geçmişi ve birleştirilen eski scriptlerin listesi.
- **[docs/](docs/)**: Her script için detaylı kullanım kılavuzları.

## 🚀 Hızlı Başlangıç

### 1. Sistem Kontrolü

Kuruluma başlamadan önce veya bir sorun anında tüm sistemi denetlemek için:

```powershell
.\A1PreReqCheck.ps1
```

### 2. Yapılandırma Güncelleme

`ofcscan.ini` dosyasına güvenli bir şekilde ayar eklemek için:

```powershell
.\A1ConfigUpdater.ps1 -FilePath "C:\PCCSRV\ofcscan.ini" -Section "Global Setting" -Key "EnableUsbLogging" -Value "1"
```

### 3. Utility Araçları

SQL bilgilerini çekmek veya sertifikaları kontrol etmek için:

```powershell
.\A1Tools.ps1
```

## 🛠 Kurulum ve Gereksinimler

- **İşletim Sistemi**: Windows Server 2012 R2 ve üzeri önerilir.
- **PowerShell**: PowerShell 5.1 veya PowerShell 7+ (Önerilen).
- **Yetki**: Scriptlerin çoğu **Administrator** yetkisi gerektirir.

## 📖 Detaylı Dokümantasyon

Her scriptin detaylı parametreleri, kullanım örnekleri ve hata giderme adımları için `docs/` klasörüne göz atın:

1. [A1PreReqCheck Detayları](docs/A1PreReqCheck.md)
2. [A1ConfigUpdater Detayları](docs/A1ConfigUpdater.md)
3. [A1Tools Detayları](docs/A1Tools.md)

## ⚖️ Yasal Uyarı (Disclaimer)

Bu projede yer alan betikler ve araçlar henüz "Production" ortamında tam teşekküllü test edilmemiştir. Kullanım sırasında oluşabilecek veri kaybı, sistem kesintisi veya yapılandırma hatalarından geliştirici sorumlu tutulamaz. Her türlü işlem öncesi yedek almanız şiddetle önerilir.

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm. ()" |
