# eDevat - Sistem Yönetim ve Güç Araçları

Bu repository, sistem yöneticileri için Trend Micro Apex One/Central kurulum ve diagnostic araçları ile Linux güç yönetimi (TLP) scriptlerini içerir.

> [!IMPORTANT]
> **ŞUBAT 2026 GÜNCELLEMESİ**: Proje çapında "Major" bir dönüşüm yapılmıştır. Eski `A1*` serisi scriptler deprecated (kullanım dışı) bırakılmış, yerini çok daha gelişmiş, dökümante edilmiş ve interaktif `TM*` serisine bırakmıştır.

## 📂 Proje Yapısı

- **[src/vendors/trendmicro/](src/vendors/trendmicro/)**:
  - **TM Series (Aktif)**: Mebadi-i Aşere prensipleriyle kuşatılmış, "bab-ı kod" estetiğine sahip (Zümrüt/Altın/Elmas) yeni nesil araçlar.
  - **A1 Series (Deprecated)**: Eski sürüm scriptler ve geçiş dökümanları.
- **[src/tools/power/](src/tools/power/)**: Linux (Laptop) güç yönetimi, TLP profilleri ve batarya sağlığı takip araçları.
- **[TEST_STATUS.md](TEST_STATUS.md)**: Tüm bileşenlerin test edilme durumlarını ve bilinen sorunları takip eden merkezi rapor.

## 💎 bab-ı kod Estetiği ve Mebadi-i Aşere

Yeni `TM*` serisi scriptler, sadece teknik bir araç değil, aynı zamanda manevi ve mesleki birer nişanedir:

- **Renk Paleti**: Zümrüt (Yeşil), Altın (Sarı) ve Elmas (Beyaz) renkleriyle konsol çıktıları harmonize edilmiştir.
- **Prensip**: Tüm scriptler, iş ahlakı ve profesyonelliği temsil eden 10 temel ilke (**Mebadi-i Aşere**) ile başlar.

## 🧪 Test Durumu

Tüm araçların güncel test durumlarına [TEST_STATUS.md](TEST_STATUS.md) dosyasından ulaşabilirsiniz.

## ⚖️ Yasal Uyarı (Disclaimer)

ÖNEMLİ: Bu araçların kullanımı sonucunda oluşabilecek veri kaybı veya sistem kararsızlığından geliştirici (**bab-ı kod**) sorumlu tutulamaz. **Kullanıcı, bu araçları çalıştırırken TÜM SORUMLULUĞU kabul etmiş sayılır.**

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm. (Bakara, 32)"
