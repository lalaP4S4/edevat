# TMDloadv2.ps1 Kullanım Kılavuzu

`TMDloadv2.ps1`, Trend Micro'nun kurumsal ürünleri (Apex One, Apex Central ve Deep Security) için geliştirilmiş merkezi bir indirme ve takip aracıdır. Önceki `TMDloadCheck` ve `TMDeepSecurityDload` araçlarının tüm yeteneklerini tek bir modern arayüzde birleştirir.

## 📋 Genel Bakış

Bu araç, iki farklı veri kaynağını harmonize eder:

1. **Web Scraping**: Apex One ve Central için `HtmlAgilityPack` kullanarak Download Center'ı tarar.
2. **XML Parsing**: Deep Security Manager (LTS) için resmi XML envanterini (`DeepSecurityInventory_en.xml`) ayrıştırır.

### 💎 dad-u-bab Standartları

- **Asenkron İndirme**: Tüm indirme işlemleri PowerShell Job'ları ile arka planda yapılır.
- **Durum Takibi**: Aktif işler, hız ve kalan süre gibi bilgilerle takip edilebilir.
- **Güvenlik**: SHA256/MD5 doğrulaması ve güvenli klasör yönetimi sunar.

## 🛠 Kullanım

```powershell
.\TMDloadv2.ps1
```

### Ana Menü Seçenekleri

1. **Apex One / Apex Central Paketleri**: Web üzerinden en güncel full paket ve hotfix bilgilerini çeker.
2. **Deep Security Manager (LTS)**: Linux ve Windows için en son 10 LTS sürümünü listeler.
3. **Durum Takibi**: Arka planda devam eden indirmelerin durumunu (Running/Completed) gösterir.
4. **İndirme Geçmişi (History)**: Oturum boyunca tamamlanan tüm indirmelerin özetini sunar.

## ⚙️ Teknik Detaylar

### İndirme Mantığı

- **Timeout**: Büyük paketler için 30 dakikalık (1800s) timeout süresi tanımlanmıştır.
- **Çatışma Yönetimi**: Aynı isimde dosya varsa üzerine yazma sorulur veya otomatik tarih damgalı yeni isim atanır.
- **Önbellek**: `HtmlAgilityPack.dll` dosyası `%LOCALAPPDATA%\TrendMicroUpdateCheck` klasöründe saklanır.

## 📥 Klasör Yapısı

İndirilen dosyalar varsayılan olarak şu yapıda saklanır:
`[Seçilen Klasör]\TrendMicro\[Ürün Adı]\...`

## 🔐 Güvenlik ve Ağ

- Gereken Adresler: `downloadcenter.trendmicro.com`, `files.trendmicro.com`, `nuget.org`.
- Proxy: Sistem proxy ayarları otomatik olarak `Invoke-WebRequest` tarafından kullanılır.
