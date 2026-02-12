# Trend Micro Apex Installation & Diagnostic Tools

> [!IMPORTANT]
> **Script Durumu Güncellemesi (2026-02-04)**
>
> - ✅ **Aktif (Current)**: `TM*.ps1` scriptleri test edilmiş ve aktif kullanımdadır
> - ⚠️ **Kullanımdan Kaldırıldı (Retired)**: `TMDownloadcenter.ps1`, `main.ps1`
> - 🗃️ **Eski Sürüm (Deprecated)**: `A1*.ps1` scriptleri bakım modundadır

Bu dizin, Trend Micro Apex One ve Apex Central kurulum hazırlığı, yapılandırması ve diagnostic işlemleri için optimize edilmiş PowerShell betiklerini içerir.

## 📂 Dizin Yapısı

### ✅ Aktif Scriptler (TM Serisi)

- **[TMMain.ps1](TMMain.ps1)**: 🎯 Merkezi yönetim paneli - tüm araçları tek bir menüden başlatın
- **[TMReqCheck.ps1](TMReqCheck.ps1)**: 🔍 Kapsamlı diagnostic ve ön hazırlık aracı (pre & post-install)
- **[TMConfigCheck.ps1](TMConfigCheck.ps1)**: ⚙️ Güvenli INI (ofcscan/ofcserver) yapılandırma güncelleyici
- **[TMCertCheck.ps1](TMCertCheck.ps1)**: 🔐 Yardımcı araçlar kütüphanesi (SQL/Versiyon/Sertifika/Log)
- **[TMDloadCheck.ps1](TMDloadCheck.ps1)**: 📥 Deep Discovery & Apex Download Manager (v2.2.1)

### 🗃️ Eski Scriptler (A1 Serisi - Deprecated)

> [!WARNING]
> Bu scriptler artık aktif olarak geliştirilmemektedir. Yeni projelerde `TM*.ps1` scriptlerini kullanın.

- **[A1PreReqCheck.ps1](A1PreReqCheck.ps1)**: ⚠️ Deprecated → `TMReqCheck.ps1` kullanın
- **[A1ConfigUpdater.ps1](A1ConfigUpdater.ps1)**: ⚠️ Deprecated → `TMConfigCheck.ps1` kullanın
- **[A1Tools.ps1](A1Tools.ps1)**: ⚠️ Deprecated → `TMCertCheck.ps1` kullanın

### 📚 Dokümantasyon

- **[CHANGELOG.md](CHANGELOG.md)**: Sürüm geçmişi ve script evrim notları
- **[docs/](docs/)**: Her script için detaylı kullanım kılavuzları, flowchart'lar ve örnekler

## 🚀 Hızlı Başlangıç

### 1. Merkezi Panel (Önerilen)

En kolay kullanım için merkezi yönetim panelini başlatın:

```powershell
.\TMMain.ps1
```

### 2. Sistem Kontrolü (Pre-Install)

Kuruluma başlamadan önce tüm sistem gereksinimlerini kontrol edin:

```powershell
.\TMReqCheck.ps1
# veya AutoFix modu ile
.\TMReqCheck.ps1 -AutoFix
```

### 3. Yapılandırma Güncelleme

`ofcscan.ini` dosyasına güvenli bir şekilde ayar eklemek için:

```powershell
.\TMConfigCheck.ps1 -FilePath "C:\PCCSRV\ofcscan.ini" -Section "Global Setting" -Key "EnableUsbLogging" -Value "1"
# veya interaktif mod
.\TMConfigCheck.ps1 -Interactive
```

### 4. Utility Araçları

SQL bilgilerini çekmek veya sertifikaları kontrol etmek için:

```powershell
.\TMCertCheck.ps1
```

### 5. Download Center Kontrolü

En güncel Apex paketlerini sorgulamak ve indirmek için:

```powershell
.\TMDloadCheck.ps1
```

## 🛠 Kurulum ve Gereksinimler

- **İşletim Sistemi**: Windows Server 2012 R2 ve üzeri önerilir
- **PowerShell**: PowerShell 5.1 veya PowerShell 7+ (Önerilen)
- **Yetki**: Scriptlerin çoğu **Administrator** yetkisi gerektirir
- **Bağımlılıklar**:
  - `TMDloadCheck.ps1` için: HtmlAgilityPack (otomatik indirilir)
  - `TMReqCheck.ps1` için: IISCryptoCli (otomatik indirilir, isteğe bağlı)

## 📖 Detaylı Dokümantasyon

Her scriptin detaylı parametreleri, kullanım örnekleri, flowchart'ları ve hata giderme adımları için `docs/` klasörüne göz atın:

- **TM Series (Aktif)**: Mebadi-i Aşere prensipleriyle kuşatılmış, "bab-ı kod" estetiğine sahip (Zümrüt/Altın/Elmas) yeni nesil araçlar.

### Aktif Scriptler

1. [TMMain.ps1 Detayları](docs/TMMain.md) - Merkezi yönetim paneli
2. [TMReqCheck.ps1 Detayları](docs/TMReqCheck.md) - Diagnostic ve ön hazırlık  
3. [TMConfigCheck.ps1 Detayları](docs/TMConfigCheck.md) - INI yapılandırma aracı
4. [TMCertCheck.ps1 Detayları](docs/TMCertCheck.md) - Utility araçlar kütüphanesi
5. [TMDloadCheck.ps1 Detayları](docs/TMDloadCheck.md) - Download Center aracı

### Deprecated Scriptler

- [A1PreReqCheck Detayları](docs/A1PreReqCheck.md) ⚠️
- [A1ConfigUpdater Detayları](docs/A1ConfigUpdater.md) ⚠️
- [A1Tools Detayları](docs/A1Tools.md) ⚠️

## ⚖️ Yasal Uyarı (Disclaimer)

Bu projede yer alan betikler ve araçlar henüz "Production" ortamında tam teşekküllü test edilmemiştir. Kullanım sırasında oluşabilecek veri kaybı, sistem kesintisi veya yapılandırma hatalarından geliştirici sorumlu tutulamaz. Her türlü işlem öncesi yedek almanız şiddetle önerilir.

---
> "Sübhaneke la ilme lena illa ma allemtena inneke entel alimul hakîm. (Bakara, 32)" | **bab-ı kod (v2.2.1)**
