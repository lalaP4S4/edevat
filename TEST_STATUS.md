# 🧪 Proje Test Durum Raporu (Test Status Report)

Bu dosya, projede yer alan araçların test edilme durumlarını ve bilinen sorunları takip eder.

## 📊 Özet Tablo

| Bileşen (Component) | Versiyon | Durum (Status) | Son Kontrol | Notlar |
| :--- | :--- | :--- | :--- | :--- |
| **Trend Micro Modülleri** | | | | |
| `A1PreReqCheck.ps1` | v1.0.1 | 🏗 Geliştiriliyor | 2026-01-28 | Lab ortamında temel fonksiyonlar doğrulandı. |
| `A1ConfigUpdater.ps1` | v1.0.1 | 🛑 Test Edilmedii | 2026-01-28 | INI manipülasyonu hassas; yedekleme özelliği test bekliyor. |
| `A1Tools.ps1` | v1.0.1 | 🏗 Geliştiriliyor | 2026-01-28 | SQL ve Sertifika sorguları Lab cihazında denendi. |
| **Power Manager Modülleri** | | | | |
| `power-manager.sh` | v1.0.1 | ⚠️ Sorunlar Var | 2026-01-28 | TLP servisinin durumuna göre geçişlerde gecikme olabiliyor. |
| `power-dashboard.py` | v1.0.1 | 🧪 Test Edildi | 2026-01-28 | Örnek CSV verisi ile grafik çizimi doğrulandı. |

## 🏷 Durum Etiketleri Açıklaması

- 🧪 **Test Edildi**: Fonksiyonlar hedef ortamlarda eksiksiz doğrulandı.
- 🏗 **Geliştiriliyor**: Temel yapı hazır, ancak uç senaryo testleri devam ediyor.
- ⚠️ **Sorunlar Var**: Test sırasında hatalar saptandı, düzeltme aşamasında.
- 🛑 **Henüz Test Edilmedi**: Kod hazır ancak hiçbir ortamda koşturulmadı.

## 🛠 Bilinen Sorunlar (Known Issues)

### Trend Micro (v1.0.1)

- `A1ConfigUpdater.ps1`: Bazı çok eski `.ini` dosyalarında (UTF-16) karakter bozulması riski olabilir. UTF-8 (BOM) zorunlu kılınmalı.

### Power Tools (v1.0.1)

- `power-manager.sh`: `tlp` kurulu olmayan sistemlerde sessizce hata verme durumu iyileştirilecek.

---
> [!CAUTION]
> **Yasal Uyarı**: Test aşamasındaki kodların kritik sistemlerde kullanımı sorumluluğu kullanıcıya aittir.

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm."
