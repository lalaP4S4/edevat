# eDevat - Sistem Yönetim ve Güç Araçları

Bu repository, sistem yöneticileri için Trend Micro Apex One/Central kurulum, diagnostic ve indirme araçları ile Linux güç yönetimi (TLP) scriptlerini içerir.

> [!IMPORTANT]
> **ŞUBAT 2026 GÜNCELLEMESİ**: Proje çapında "Major" bir dönüşüm yapılmıştır. Eski `A1*` serisi scriptler deprecated (kullanım dışı) bırakılmış, yerini çok daha gelişmiş, dökümante edilmiş ve interaktif `TM*` serisine bırakmıştır.

## 📂 Proje Yapısı

- **[src/vendors/trendmicro/](src/vendors/trendmicro/)**:
  - **TM Series (v2.3.0 - Aktif)**: "bab-ı kod" estetiğine sahip (Zümrüt/Altın/İnci), Mebadi-i Aşere prensipleriyle kuşatılmış sistem araçları.
    - **Launcher**: `TMMain.ps1` - Tüm araçlar için merkezi yönetim paneli.
    - **Diagnostic**: `TMReqCheck.ps1` - Kapsamlı sistem ve gereksinim kontrolü.
    - **Configuration**: `TMConfigCheck.ps1` - Konsolide INI yapılandırma güncelleyici.
    - **Downloader**: `TMDloadCheck.ps1` - Apex & Deep Discovery (DDAN, DDD, DDI, DDEI) indirme yönetimi.
    - **Utilities**: `TMCertCheck.ps1` - SQL, Versiyon ve Sertifika araçları.
  - **A1 Series (Deprecated)**: Eski sürüm scriptler ve geçiş dökümanları.
- **[src/tools/power/](src/tools/power/)**: Linux (Laptop) güç yönetimi, TLP profilleri ve batarya sağlığı takip araçları.

## 💎 bab-ı kod Estetiği ve Mebadi-i Aşere

Yeni `TM*` serisi scriptler, sadece teknik bir araç değil, aynı zamanda manevi ve mesleki birer nişanedir:

- **Renk Paleti**: Cevherhane Zümrüt (Koyu Yeşil), Altın (Sarı) ve İnci (Beyaz) renkleriyle konsol çıktıları harmonize edilmiştir.
- **Prensip**: Tüm scriptler, iş ahlakı ve profesyonelliği temsil eden 10 temel ilke (**Mebadi-i Aşere**) ile başlar.

## ⚖️ Yasal Uyarı (Disclaimer)

ÖNEMLİ: Bu araçların kullanımı sonucunda oluşabilecek veri kaybı veya sistem kararsızlığından geliştirici (**bab-ı kod**) sorumlu tutulamaz. **Kullanıcı, bu araçları çalıştırırken TÜM SORUMLULUĞU kabul etmiş sayılır.**

---
> "Sübhaneke la ilmelena illa ma allemtena inneke entel alimul hakîm. (Bakara, 32)"
