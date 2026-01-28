# Linux Power Manager Tools

Bu dizin, Linux sistemler (özellikle laptoplar) için güç yönetimi ve batarya sağlığı takip araçlarını içerir.

## 📂 Dizin Yapısı

- **[power-manager.sh](power-manager.sh)**: TLP profilleri arasında geçiş yapan ve şarj limitlerini ayarlayan ana script.
- **[power-dashboard.py](power-dashboard.py)**: Birikmiş batarya loglarını analiz eden ve grafiksel rapor sunan Python aracı.

## 🚀 Başlangıç

### 1. Güç Yönetimi

Profili değiştirmek veya kurulum yapmak için:

```bash
chmod +x power-manager.sh
./power-manager.sh
```

### 2. Batarya Paneli

Logları grafiksel olarak görmek için (Pandas ve Matplotlib gerektirir):

```bash
python3 power-dashboard.py
```

## 🛠 Özellikler

- **Work Mode**: Batarya ömrünü korumak için %40-%80 şarj limiti ve güç tasarrufu modu.
- **Game Mode**: Performans için %55-%95 şarj limiti ve turbo desteği.
- **Batarya Loglama**: Günlük olarak batarya kapasitesini ve cycle bilgisini kaydeder.
- **Görsel Analiz**: Zaman içindeki kapasite düşüşünü grafik olarak raporlar.

## ⚖️ Yasal Uyarı (Disclaimer)

Önemli: Güç yönetimi ayarları (TLP) donanım seviyesinde değişiklikler yapar. Bu araçlar henüz tam olarak test edilmemiştir. Kullanım sorumluluğu tamamen kullanıcıya aittir.

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm. (Bakara, 32)"
