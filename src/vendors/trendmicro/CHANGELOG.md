# Trend Micro Vendors Changelog

Bu dosya, `Apex Kurulum` dizinindeki dağınık ve versiyonlanmış scriptlerin `src/vendors/trendmicro` altında nasıl birleştirildiğini ve iyileştirildiğini belgeler.

## [1.0.1] - 2026-01-28

### İyileştirmeler & Refactor

- **GitHub Hazırlığı:** Tüm dokümantasyon ve scriptlerdeki mutlak (local) dosya yolları göreceli yollarla değiştirildi.
- **Sürüm Takibi:** Her scriptin başına `.VERSION` ve sürüm bilgisi (v1.0.1) eklendi.
- **İnteraktif Mod (UX):** `A1ConfigUpdater.ps1` için parametre girmeden ayar seçilebilen menü yapısı eklendi.
- **Güvenlik Teşhisi:** `A1PreReqCheck.ps1` içine IISCrypto ve SSL/TLS yapılandırmalarını (ClientAuthTrustMode, HTTP/2) denetleyen yeni bir test modülü eklendi.
- **Hata Giderme:** `A1PreReqCheck.ps1` ana menüsündeki fonksiyon isimlendirmeleri (Check -> Test) standartlaştırıldı ve menü hataları düzeltildi.
- **Linguistik Uyum:** "Seksiyon" terimleri proje genelinde "Bab" olarak güncellendi.

## [1.0.0] - 2026-01-28

### Yeni Oluşturulan Superset Scriptler

#### 1. [A1PreReqCheck.ps1](A1PreReqCheck.ps1)

**Birleştirilen Dosyalar:**

- `Apex Kurulum/A1PreReqCheck.ps1` (v1)
- `Apex Kurulum/A1PreReqCheckv2.ps1` (v2)
- `Apex Kurulum/a1-shc.ps1` (Service health check)

**Yapılan Değişiklikler & İyileştirmeler:**

- **v2 Baz Alındı:** Modern diagnostic yapısı, CPU/RAM/OS/Disk/Network kontrolleri v2 üzerinden taşındı.
- **Modül Kontrolleri Eklendi:** v1'de bulunan Application Control, Endpoint Sensor, Vulnerability Protection ve MDR servis kontrolleri entegre edildi.
- **Merkezi Menü:** Tüm kontrolleri içeren interaktif bir konsol menüsü oluşturuldu.
- **Gelişmiş Raporlama:** Tüm çıktıları UTF-8 formatında TXT dosyasına döken merkezi raporlama fonksiyonu eklendi.

#### 2. [A1ConfigUpdater.ps1](A1ConfigUpdater.ps1)

**Birleştirilen Dosyalar:**

- `Apex Kurulum/ofcscaniniv2.ps1`
- `Apex Kurulum/ofcscaniniv3.ps1`
- `Apex Kurulum/ofcscaniniv4.ps1`
- `Apex Kurulum/ofscanini.ps1`
- `Apex Kurulum/ofcserverini.ps1`

**Yapılan Değişiklikler & İyileştirmeler:**

- **Parametrik Yapı:** Artık her ayar için ayrı script yerine `FilePath`, `Section`, `Key`, `Value` parametreleri alan merkezi bir yapı kuruldu.
- **Otomatik Yedekleme:** Her değişiklikten önce dosyanın tarih-saat damgalı bir yedeği alınır.
- **Bab Koruması:** INI yapısını bozmadan, sadece ilgili [SECTION] altındaki değerleri günceller veya yoksa ekler.
- **Format Normalizasyonu:** Ardışık boş satırları temizleyen ve dosyayı düzgün UTF-8 olarak kaydeden mantık eklendi.

#### 3. [A1Tools.ps1](A1Tools.ps1)

**Birleştirilen Dosyalar:**

- `Apex Kurulum/ACgetSQLinfo.ps1` (SQL Server bilgisi)
- `Apex Kurulum/AgentVersionCheck.ps1` (Ajan versiyonu)
- `Apex Kurulum/a1-fcc.ps1` (Sertifika kontrolü)
- `Apex Kurulum/a1-logerr.ps1` (Hata ayıklama)
- `Apex Kurulum/SetIPv4Precedence.ps1` (IPv4 önceliği)

**Yapılan Değişiklikler & İyileştirmeler:**

- **Fonksiyonel Kütüphane:** Tüm araçlar tek bir modül altında fonksiyonlara dönüştürüldü.
- **Sertifika Doğrulaması:** `a1-fcc.ps1`'deki IP bazlı sertifika doğrulama mantığı otomatiğe bağlandı.
- **Merkezi Hata Analizi:** Log dosyalarındaki hata ve uyarıları ayıklayıp tek bir klasöre raporlayan geliştirilmiş mantık eklendi.

### Teknik Standartlar

- **Encoding:** Tüm dosyalar UTF-8 (BOM) ile kaydedildi, Türkçe karakter sorunu giderildi.
- **Hata Yönetimi:** Tüm operasyonlarda `try/catch` blokları kullanılarak script dayanıklılığı artırıldı.
- **Yedekleme:** Kritik değişiklikler (INI güncellemeleri) öncesi her zaman otomatik yedekleme mekanizması çalıştırıldı.
