# Power Tools Changelog

Bu dosya, `Other-tools` dizinindeki dağınık scriptlerin `src/tools/power` altında nasıl birleştirildiğini belgeler.

## [1.0.1] - 2026-01-28

### Yeni Oluşturulan Superset Araçlar

#### 1. [power-manager.sh](power-manager.sh)

**Birleştirilen Yapılar:**

- `Other-tools/install-tlp-profiles.sh` (Kurulum mantığı)
- `work-mode.sh` (Mod değişimi)
- `game-mode.sh` (Mod değişimi)
- `battery-log.sh` (Loglama)

**Yapılan İyileştirmeler:**

- **Merkezi Menü**: Tüm fonksiyonlar tek bir script altında, interaktif menü ile toplandı.
- **Sürüm Takibi**: v1.0.1 etiketi ve `bab-ı kod` author bilgisi eklendi.
- **Hata Yönetimi**: Donanım algılama ve TLP kontrolü geliştirildi.

#### 2. [power-dashboard.py](power-dashboard.py)

**Refactor Edilen Dosya:**

- `Other-tools/battery_dashboard.py`

**Yapılan İyileştirmeler:**

- **Robustness**: Dosya varlık kontrolü ve hata yakalama eklendi.
- **Görselleştirme**: Grafik tasarımı iyileştirildi, grid ve net etiketler eklendi.
- **Parametrik Yapı**: Dışarıdan CSV yolu verebilme imkanı eklendi.

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm. (Bakara, 32)"
