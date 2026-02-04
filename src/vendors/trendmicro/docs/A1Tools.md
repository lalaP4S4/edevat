# A1Tools.ps1 Kullanım Kılavuzu

> [!WARNING]
> **BU SCRIPT DEPRECATED (ESKİ SÜRÜM) OLARAK İŞARETLENMİŞTİR.**
> Yeni projelerde ve güncel işlemler için lütfen **[TMCertCheck.ps1](TMCertCheck.md)** kullanın.

`A1Tools.ps1`, Trend Micro Apex One ve Central için sık kullanılan yardımcı fonksiyonları tek bir kütüphanede toplar.

## 📋 Genel Bakış

Bu script hem interaktif bir menü ile kullanılabilir hem de başka scriptlerin içine `import` edilerek (dot-sourcing) fonksiyonları çağrılabilir.

## 🛠 Kullanım

### İnteraktif Menü

```powershell
.\A1Tools.ps1
```

### Menü Seçenekleri

1. **SQL Bilgilerini Göster**: Registry üzerinden kullanılan SQL Server adını ve veritabanı ismini çeker.
2. **Ajan Versiyonunu Sorgula**: Makinede kurulu Apex One ajanının tam versiyon numarasını gösterir.
3. **Sertifika Doğrulaması (FCC)**: Sunucu üzerindeki kritik sertifikaların (Personal ve Trusted People) geçerliliğini ve IP uyumunu kontrol eder.
4. **Log Hatalarını Tara**: `OFCMAS.log`, `OFCSVR.log` gibi kritik loglardaki hata ve uyarıları ayıklayıp `C:\A1\LogErr` klasörüne raporlar.
5. **IPv4 Önceliğini Ayarla**: IPv4-mapped IPv6 sorunlarını gidermek için registry ayarı yapar.

## 🧩 Fonksiyonel Kullanım (Kütüphane Olarak)

Başka bir script içinden kullanmak isterseniz:

```powershell
. .\A1Tools.ps1
$sql = Get-A1SQLInfo
Write-Host "Veritabanı: $($sql.DBName)"
```

## ❓ Sık Karşılaşılan Sorunlar ve Çözümleri

### 1. SQL Bilgileri Boş Geliyor

- **Neden**: Apex Central veya One düzgün kurulmamış ya da registry anahtarları farklı bir konumdadır.
- **Çözüm**: `Get-A1SQLInfo` fonksiyonundaki registry yollarını sunucunuzun kurulumuna göre kontrol edin.

### 2. Sertifika Hatası (FAIL)

- **Neden**: Genellikle sunucu IP değişikliği yapıldığında sertifikalar eski IP'de kalır.
- **Çözüm**: Apex One Sunucu Ayarları altından sertifikaları yenilemeniz gerekebilir.

### 3. Log Taraması Hataları

- **Neden**: Log dosyası çok büyükse veya başka bir işlem tarafından kilitlendiyse tarama yapılamayabilir.
- **Çözüm**: Trend Micro servislerini durdurmadan veya loglar çok şişmeden tarama yapın.
