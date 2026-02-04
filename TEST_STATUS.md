# 🧪 Proje Test Durum Raporu (Test Status Report)

Bu dosya, projede yer alan araçların test edilme durumlarını ve bilinen sorunları takip eder.

## 📊 Özet Tablo

| Bileşen (Component) | Versiyon | Durum (Status) | Son Kontrol | Notlar |
| :--- | :--- | :--- | :--- | :--- |
| **Trend Micro (TM Series)** | | | | |
| `TMMain.ps1` | v1.1.0 | 🧪 Test Edildi | 2026-02-04 | Merkezi yönetim paneli, stabil. |
| `TMReqCheck.ps1` | v1.1.2 | 🧪 Test Edildi | 2026-02-04 | Kapsamlı pre-req ve diagnostic, en gelişmiş araç. |
| `TMConfigCheck.ps1` | v1.1.0 | 🧪 Test Edildi | 2026-02-04 | INI güncelleme, yedekleme özelliği doğrulandı. |
| `TMCertCheck.ps1` | v1.1.0 | 🧪 Test Edildi | 2026-02-04 | SQL/Sertifika/Log araçları kütüphanesi. |
| `TMDloadCheck.ps1` | v1.1.0 | 🧪 Test Edildi | 2026-02-04 | Dinamik patch takip ve indirme aracı. |
| **Trend Micro (Deprecated)** | | | | |
| `A1*` Serisi | v1.0.1 | 🛑 Deprecated | 2026-02-04 | Yerine `TM*` serisi araçlar kullanılmalıdır. |
| **Power Manager Modülleri** | | | | |
| `power-manager.sh` | v1.0.1 | ⚠️ Sorunlar Var | 2026-01-28 | TLP servisinin durumuna göre gecikme olabiliyor. |
| `power-dashboard.py` | v1.0.1 | 🧪 Test Edildi | 2026-01-28 | Örnek CSV verisi ile grafik çizimi doğrulandı. |

## 🏷 Durum Etiketleri Açıklaması

- 🧪 **Test Edildi**: Fonksiyonlar hedef ortamlarda eksiksiz doğrulandı.
- 🏗 **Geliştiriliyor**: Temel yapı hazır, ancak uç senaryo testleri devam ediyor.
- ⚠️ **Sorunlar Var**: Test sırasında hatalar saptandı, düzeltme aşamasında.
- 🛑 **Deprecated / Eski**: Artık geliştirilmiyor veya yerini yeni bir araca bıraktı.

## 🛠 Bilinen Sorunlar (Known Issues)

### Trend Micro (TM Series)

- **Banner Display**: Çok dar konsol pencerelerinde banner kayması olabilir. Standart 80+ sütun önerilir.
- **Network Path**: `TMDloadCheck.ps1` indirme sırasında zayıf bağlantılarda `Invoke-WebRequest` timeout verebilir.

### Power Tools (v1.0.1)

- `power-manager.sh`: `tlp` kurulu olmayan sistemlerde sessizce hata verme durumu iyileştirilecek.

---
> [!CAUTION]
> **Yasal Uyarı**: Test aşamasındaki kodların kritik sistemlerde kullanımı sorumluluğu kullanıcıya aittir.

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm."
