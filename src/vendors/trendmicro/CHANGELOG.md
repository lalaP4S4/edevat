# Trend Micro Vendors Changelog

Bu dosya, `Apex Kurulum` dizinindeki dağınık ve versiyonlanmış scriptlerin `src/vendors/trendmicro` altında nasıl birleştirildiğini ve iyileştirildiğini belgeler.

## [2.2.0] - 2026-02-11

### Eklendi

- `TMDloadv2.ps1`: Apex One, Apex Central ve Deep Security Manager (LTS) indirme araçları tek bir gelişmiş arayüzde birleştirildi.
- Ortak asenkron (arka plan) indirme, durum takibi ve geçmiş kaydı (history) sistemleri tüm ürünler için harmonize edildi.
- Deep Security XML parsing mantığı Apex araçları ile aynı çatı altında toplandı.

## [2.1.0] - 2026-02-11

### 💎 Banner Standardization & Script Consolidation

**Özet:**
Proje genelinde görsel standartlar güncellendi ve `TMConfigCheck` sürümü en kapsamlı haliyle tek bir dosyada birleştirildi.

#### 🎨 Görsel Standartlar (Mebadi-i Aşere v2)

- **Banner Güncellemesi:** Tüm PowerShell betiklerindeki `Show-MebadiBanner` fonksiyonu yeni renk paleti (DarkYellow, White/DarkGreen) ve hizalamaya göre standardize edildi.
- **Renk Uyumu:** Banner satırları artık daha okunaklı ve tutarlı bir `Green` (Zümrüt) tonu kullanıyor.
- **Besmele Düzeni:** Besmele-i Şerif görsel olarak merkezlendi ve kontrastı artırıldı.

#### ⚙️ TMConfigCheck Consolidation (v3.1.0)

- **Superset Birleştirme:** `v2` ve `v3` sürümlerindeki tüm özellikler ana `TMConfigCheck.ps1` dosyasında birleştirildi.
- **Yeni Özellikler:** Inactive Agent Purge bildirimleri ve Global Güvenlik/Optimizasyon ayarları (Option 4) artık tek bir dosyada mevcut.
- **Temizlik:** Gereksiz hale gelen versiyonlanmış (`v2`, `v3`) yedek dosyalar temizlendi.

#### 🛠 Teknik İyileştirmeler

- **Hata Giderme:** Ayet referanslarındaki (Necm;39 vb.) boşluk ve gösterim hataları düzeltildi.
- **Merkezi Yönetim:** `TMMain.ps1` üzerindeki tüm linkler konsolide edilmiş dosyalara yönlendirildi.

---

## [2.0.0] - 2026-02-04

### 🎯 Major Update: TM Serisi Aktif - A1 Serisi Deprecated

**Özet:**
Proje scriptleri kapsamlı test ve iyileştirmelerden geçirilerek yeni `TM*` isimlendirme konvansiyonuna geçirildi.
Tüm kullanıcıların yeni TM serisi scriptlere geçmeleri önerilir.

#### Aktif Script Güncellemeleri

- **[TMMain.ps1](TMMain.ps1)**: `main.ps1` yerine kullanılacak merkezi yönetim paneli
  - Gelişmiş banner ve tema (cevherhane renk paleti)
  - Dinamik execution policy bypass
  - İyileştirilmiş menü yapısı
  
- **[TMReqCheck.ps1](TMReqCheck.ps1)**: `A1PreReqCheck.ps1`'den evrilmiş kapsamlı diagnostic tool
  - 16+ interaktif modül
  - AutoFix modu desteği
  - IISCrypto entegrasyonu
  - Detaylı raporlama
  
- **[TMConfigCheck.ps1](TMConfigCheck.ps1)**: `A1ConfigUpdater.ps1`'den yeniden adlandırıldı
  - Aynı fonksiyonellik, yeni isim
  
- **[TMCertCheck.ps1](TMCertCheck.ps1)**: `A1Tools.ps1`'den yeniden adlandırıldı
  - Aynı fonksiyonellik, yeni isim
  
- **[TMDloadCheck.ps1](TMDloadCheck.ps1)**: `TMDownloadcenter.ps1`'in yerine geçti
  - XPath-free implementasyon (tablo indeks bazlı)
  - HtmlAgilityPack kullanımı
  - Arka plan download desteği
  - Cevherhane tema entegrasyonu

#### Kullanımdan Kaldırılan Scriptler

- ❌ **main.ps1** → Retired, `TMMain.ps1` kullanın
- ❌ **TMDownloadcenter.ps1** → Retired, `TMDloadCheck.ps1` kullanın

#### Deprecated Scriptler (Bakım Modu)

- ⚠️ **A1PreReqCheck.ps1** → `TMReqCheck.ps1` kullanın
- ⚠️ **A1ConfigUpdater.ps1** → `TMConfigCheck.ps1` kullanın
- ⚠️ **A1Tools.ps1** → `TMCertCheck.ps1` kullanın

#### Dokümantasyon İyileştirmeleri

- Her TM script için detaylı `.md` dokümantasyonu eklendi
- Mermaid flowchart/pipeline diyagramları eklendi
- Fonksiyon ve değişken referans tabloları oluşturuldu
- Sistem modifikasyonları detaylı dokümante edildi

#### Görsel & Manevi Güncellemeler

- **Mebadi-i Aşere Entegrasyonu**: Tüm aktif scriptlerin başlangıcına "On İlke" banner'ı eklendi.
- **Tema Uyumluluğu**: Tüm bannerlar cevherhane renk paleti (Altın, Zümrüt, Elmas) ile harmonize edildi.
- **Sürüm Güncellemeleri**: Banner entegrasyonu ile tüm scriptler v1.1.0+ seviyesine yükseltildi.

### Teknik Standartlar (Devam Ediyor)

- **Encoding:** UTF-8 (BOM)
- **Hata Yönetimi:** Try-catch blokları
- **Tema:** Cevherhane renk paleti (Zümrüt, Elmas, Altın, Yakut)
- **Versiyon:** Bab-ı Kod standartları (mahlas: bab-ı kod)

---

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
- **[TMDloadv2.ps1](src/vendors/trendmicro/TMDloadv2.ps1)**: Apex One, Apex Central ve Deep Security Manager için merkezi indirme paneli.
- **[TEST_STATUS.md](TEST_STATUS.md)**: Tüm bileşenlerin test edilme durumlarını ve bilinen sorunları takip eden merkezi rapor.
lama fonksiyonu eklendi.

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
