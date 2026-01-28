# A1PreReqCheck.ps1 Kullanım Kılavuzu

`A1PreReqCheck.ps1`, Trend Micro Apex One ve Central kurulumları için hepsi bir arada (all-in-one) bir diagnostic ve ön hazırlık aracıdır.

## 📋 Genel Bakış

Bu script, v1 ve v2 sürümlerinin en iyi özelliklerini birleştirir. Hem donanım/yazılım gereksinimlerini kontrol eder hem de kurulum sonrası modül sağlık durumlarını denetler.

## 🛠 Kullanım

Scripti **Administrator** yetkisiyle başlatın:

```powershell
.\A1PreReqCheck.ps1
```

### Ana Menü Seçenekleri

1. **Tüm Sistem Kontrollerini Çalıştır**: OS, CPU, RAM ve Disk alanını hedeflenen ürüne (Apex One veya Central) göre test eder.
2. **IPv4 Önceliği Kontrolü & Fix**: Windows'un IPv6 yerine IPv4 tercih etmesini sağlar.
3. **Servis Durumlarını Kontrol Et**: Temel Apex servislerinin çalışıp çalışmadığını denetler.
4. **Gelişmiş Modül Kontrolleri**: Application Control, Endpoint Sensor ve Vulnerability Protection modüllerini test eder.
5. **Rapor Dışa Aktar**: Tüm test sonuçlarını tarih damgalı bir `.txt` dosyasına kaydeder.

## ⚙️ Parametreler

- `-ProductType`: `ApexOne` veya `ApexCentral` (Manuel seçim yapılmazsa menüden sorulur).
- `-AutoFix`: IPv4 önceliği gibi düzeltilebilir sorunları onay almadan otomatik düzeltir.
- `-LogPath`: Logların kaydedileceği dizin (Varsayılan: `C:\ApexSetupLogs`).

## ❓ Sık Karşılaşılan Sorunlar ve Çözümleri

### 1. "Access Denied" Hatası

- **Neden**: Script Administrator yetkisiyle çalıştırılmamıştır.
- **Çözüm**: PowerShell'i sağ tıklayıp "Yönetici olarak çalıştır" seçeneğiyle açın.

### 2. IPv4 Önceliği "Fail" Görünüyor

- **Neden**: Windows varsayılan olarak IPv6'ya öncelik verir.
- **Çözüm**: Menüden 2. seçeneği (Fix) çalıştırın ve bilgisayarı yeniden başlatın.

### 3. Servis Bulunamadı (NOT FOUND)

- **Neden**: İlgili modül (örn. Endpoint Sensor) henüz kurulmamış veya kurulum yarım kalmış olabilir.
- **Çözüm**: Kurulum medyasını ve web konsol eklenti yöneticisini (Plug-in Manager) kontrol edin.

## 📝 Kurulum Notları

Scripti herhangi bir dizine kopyalayıp doğrudan çalıştırabilirsiniz. Bağımlılığı yoktur, sadece yerel sistemdeki PowerShell yetkilerine ihtiyaç duyar.
