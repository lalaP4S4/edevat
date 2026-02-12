<#
.SYNOPSIS
    Trend Micro Apex One & Apex Central Sunucu Diagnostic ve Ön Hazırlık Aracı (v1.1.1)

.DESCRIPTION
    Bu betik, Trend Micro Apex One ve Apex Central kurulumları için kapsamlı bir sistem kontrolü, 
    ön hazırlık doğrulaması ve kurulum sonrası servis denetimi sunar. 

    Sürüm: v1.1.2
    Tarih: 2026-01-29

    Özellikler:
    - Execution Policy Bypass (Sadece bu script için)
    - Gelişmiş Hata Yönetimi ve Try-Catch Blokları
    - Klavye/Timezone/Hostname/Regional Settings Kontrolleri ve AutoFix
    - IIS Crypto Best Practice Uygulaması
    - Windows Role/Feature Kontrolü ve Kurulumu
    - HTTP/2 TLS/Cleartext Ayarları
    - ClientAuthTrustMode Kontrolü
    - Kapsamlı Sistem Kontrolleri (OS, CPU, RAM, Disk, .NET, IIS, MSMQ, SQL)
    - IPv4 Önceliği (Precedence) Kontrolü ve Optimizasyonu
    - Kurulum Sonrası Modül Kontrolleri (Application Control, Endpoint Sensor, VP, MDR)
    - Detaylı Loglama ve Rapor Dışa Aktarımı

.AUTHOR
    bab-ı kod

.NOTES
    YASAL UYARI: Bu betik henüz tam teşekkülü test edilmemiştir. Sorumluluk kullanıcıya aittir.
    DISCLAIMER: This script is not fully tested. Use at your own risk.

.EXAMPLE
    .\TrendMicro_Apex_Diagnostic_v1.1.1.ps1
    .\TrendMicro_Apex_Diagnostic_v1.1.1.ps1 -AutoFix
    .\TrendMicro_Apex_Diagnostic_v1.1.1.ps1 -ProductType "ApexOne" -AutoFix

#>

param(
    [string]$ProductType = "",  # "ApexOne" veya "ApexCentral"
    [switch]$NoDownload,
    [switch]$SkipRebootCheck,
    [switch]$AutoFix,
    [switch]$ApplyIISCrypto,
    [string]$LogPath = "C:\ApexSetupLogs"
)

# Sürüm: v1.1.2
# Yazar: bab-ı kod

function Show-MebadiBanner {
    Clear-Host
    Write-Host ("=" * 85) -ForegroundColor DarkYellow
    Write-Host (" " * 71) "  bab-ı kod  " -BackgroundColor DarkYellow -ForegroundColor Black
    Write-Host ("=" * 85) -ForegroundColor DarkYellow
    Write-Host (" " * 25) "Bismillahirrahmanirrahim" (" " * 34) -BackgroundColor White -ForegroundColor DarkGreen
    Write-Host ("-" * 85) -ForegroundColor DarkYellow

    $Lines = @(
        "1;Niyet;İnsan için ancak çalıştığının karşılığı vardır.;Necm;39",
        "2;İstikamet;Öyleyse emrolunduğun gibi dosdoğru ol.;Hûd;112",
        "3;Kâtiplik;O, kalemle (yazmayı) öğretendir.;Alak;4",
        "4;Zerafet;İnsanlara güzel söz söyleyin.;Bakara;83",
        "5;Basiret;De ki: Hiç bilenlerle bilmeyenler bir olur mu?;Zümer;9",
        "6;İlim;...Rabbim! Benim ilmimi artır, de.;Tâhâ;114",
        "7;İnzibat;Şüphesiz güçlükle beraber bir kolaylık vardır.;İnşirah;5",
        "8;İstişare;...İş hususunda onlarla müşavere et.;Âl-i İmrân;159",
        "9;Kanaat;...Yiyin, için fakat israf etmeyin.;A'râf;31",
        "10;Miras;Emanetlerine ve ahidlerine riayet ederler.;Mü'minûn;8"
    )

    foreach ($L in $Lines) {
        $c = $L.Split(';')
        if ($c.Count -ge 4) {
            $source = if ($c.Count -gt 4) { "$($c[3]); $($c[4])" } else { $c[3] }
            $row = "{0,-2} | {1,-10} | {2,-50} | {3}" -f $c[0], $c[1], $c[2], $source
            Write-Host $row -ForegroundColor Green
        }
    }
    Write-Host ("=" * 85) -ForegroundColor DarkYellow
}

function Show-Banner {
    Show-MebadiBanner
    Start-Sleep -Seconds 2
}

# Banner'ı çalıştır
Show-Banner

# Global değişkenler
$global:isApexOne = $true
$global:needsReboot = $false
$global:ExecutionErrors = @()
$global:ScriptResults = @{}
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# Loglama fonksiyonu
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
        
    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp [$Level] $Message"
            
        # Ekrana yaz
        Write-Host $logMessage -ForegroundColor $Color
            
        # Dosyaya yaz
        if (-not (Test-Path $LogPath)) {
            New-Item -Path $LogPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }
        $logFile = Join-Path $LogPath "apex_diag_$(Get-Date -Format 'yyyyMMdd').log"
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        Write-Warning "Log yazma hatası: $_"
    }
}

# Administrator kontrolü
function Test-Admin {
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-not $isAdmin) {
            Write-Log "HATA: Bu script Administrator olarak çalıştırılmalıdır!" -Level "ERROR" -Color Red
            Write-Log "Lütfen PowerShell'i 'Run as Administrator' ile başlatın." -Level "ERROR" -Color Red
            return $false
        }
        return $true
    }
    catch {
        Write-Log "HATA: Administrator kontrolü yapılamadı: $_" -Level "ERROR" -Color Red
        return $false
    }
}

# Pause fonksiyonu (ISE uyumlu)
function Invoke-Pause {
    param([string]$Message = "Devam etmek için bir tuşa basın...")
        
    Write-Host "`n$Message" -ForegroundColor Gray
        
    # ISE veya non-interactive ortamlarda ReadKey çalışmaz
    if ($host.Name -eq 'ConsoleHost') {
        try {
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        catch {
            # ReadKey başarısız olursa Read-Host kullan
            Read-Host "Enter tuşuna basın"
        }
    }
    else {
        # ISE veya diğer host'larda Read-Host kullan
        Read-Host "Enter tuşuna basın"
    }
}

# --- YENİ: Klavye Kontrolü ve Ayarı (Turkish-Q) ---
function Test-KeyboardLayout {
    Write-Log "`n--- Klavye Düzeni Kontrolü ---" -Color Cyan
        
    try {
        $langList = Get-WinUserLanguageList
        $hasTurkishQ = $langList[0].InputMethodTips -contains "041f:0000041f"
            
        if ($hasTurkishQ) {
            Write-Log "  ✓ Turkish-Q klavye düzeni zaten aktif." -Color Green
            $global:ScriptResults['KeyboardLayout'] = $true
            return $true
        }
        else {
            Write-Log "  ⚠ Turkish-Q klavye düzeni aktif değil." -Color Yellow
            $global:ScriptResults['KeyboardLayout'] = $false
                
            if ($AutoFix) {
                Write-Log "  AutoFix aktif, Turkish-Q klavye ayarlanıyor..." -Color Yellow
                Set-WinUserLanguageList -LanguageList (New-WinUserLanguageList tr-TR) -Force
                Write-Log "  ✓ Turkish-Q klavye düzeni uygulandı." -Color Green
                $global:needsReboot = $true
                return $true
            }
            else {
                $ans = Read-Host "  Klavye düzenini Turkish-Q olarak değiştirmek istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') {
                    Set-WinUserLanguageList -LanguageList (New-WinUserLanguageList tr-TR) -Force
                    Write-Log "  ✓ Turkish-Q klavye düzeni uygulandı." -Color Green
                    $global:needsReboot = $true
                    return $true
                }
                else {
                    Write-Log "  ℹ Kullanıcı işlemi iptal etti." -Color Gray
                    return $false
                }
            }
        }
    }
    catch {
        Write-Log "  HATA: Klavye düzeni kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Keyboard Layout Error: $_"
        return $false
    }
}

# --- YENİ: Hostname Kontrolü ---
function Test-Hostname {
    Write-Log "`n--- Hostname Kontrolü ---" -Color Cyan
        
    try {
        $hostname = $env:COMPUTERNAME
        Write-Log "  Mevcut Hostname: $hostname" -Color Gray
            
        # Varsayılan hostname pattern'i (DESKTOP-XXXXX, WIN-XXXXX, LAPTOP-XXXXX)
        if ($hostname -match '^(DESKTOP|LAPTOP|WIN)-[A-Z0-9]{5,15}$') {
            Write-Log "  ⚠ VARSAYILAN HOSTNAME TESPIT EDİLDİ!" -Color Yellow
            $global:ScriptResults['Hostname'] = $false
                
            if ($AutoFix) {
                Write-Log "  ℹ AutoFix modunda hostname değişikliği güvenlik nedeniyle atlanıyor." -Color Gray
                Write-Log "  Lütfen hostname'i manuel olarak değiştirin." -Color Yellow
                return $false
            }
            else {
                $newHostname = Read-Host "  Yeni hostname girin"
                if (-not [string]::IsNullOrWhiteSpace($newHostname)) {
                    $confirm = Read-Host "  Hostname '$newHostname' olarak değiştirilsin mi? (Y/N)"
                    if ($confirm -match '^[Yy]$') {
                        Rename-Computer -NewName $newHostname -Force
                        Write-Log "  ✓ Hostname '$newHostname' olarak değiştirildi. REBOOT GEREKLİ." -Color Green
                        $global:needsReboot = $true
                        return $true
                    }
                }
                Write-Log "  ℹ İşlem iptal edildi." -Color Gray
                return $false
            }
        }
        else {
            Write-Log "  ✓ Özel hostname kullanılıyor - PASS" -Color Green
            $global:ScriptResults['Hostname'] = $true
            return $true
        }
    }
    catch {
        Write-Log "  HATA: Hostname kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Hostname Check Error: $_"
        return $false
    }
}

# --- YENİ: Timezone Kontrolü ---
function Test-TimeZone {
    Write-Log "`n--- Timezone Kontrolü ---" -Color Cyan
        
    try {
        $currentTZ = (Get-TimeZone).Id
        Write-Log "  Mevcut Timezone: $currentTZ" -Color Gray
            
        if ($currentTZ -ne "Turkey Standard Time") {
            Write-Log "  ⚠ Timezone İstanbul (+3) değil!" -Color Yellow
            $global:ScriptResults['TimeZone'] = $false
                
            if ($AutoFix) {
                Write-Log "  AutoFix aktif, timezone İstanbul olarak ayarlanıyor..." -Color Yellow
                Set-TimeZone -Id "Turkey Standard Time"
                Write-Log "  ✓ Timezone İstanbul (+3) olarak güncellendi." -Color Green
                $global:ScriptResults['TimeZone'] = $true
                return $true
            }
            else {
                $ans = Read-Host "  Timezone'u İstanbul (+3) olarak ayarlamak istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') {
                    Set-TimeZone -Id "Turkey Standard Time"
                    Write-Log "  ✓ Timezone İstanbul (+3) olarak güncellendi." -Color Green
                    return $true
                }
                else {
                    Write-Log "  ℹ Değişiklik yapılmadı." -Color Gray
                    return $false
                }
            }
        }
        else {
            Write-Log "  ✓ Timezone zaten İstanbul (+3) - PASS" -Color Green
            $global:ScriptResults['TimeZone'] = $true
            return $true
        }
    }
    catch {
        Write-Log "  HATA: Timezone kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "TimeZone Check Error: $_"
        return $false
    }
}

# --- YENİ: Bölgesel Ayarlar (Regional Settings) Kontrolü ---
function Test-RegionalSettings {
    Write-Log "`n--- Bölgesel Ayarlar (Regional Settings) Kontrolü ---" -Color Cyan
        
    try {
        $culture = Get-Culture
        $sysLocale = Get-WinSystemLocale
        $uiLang = if ((Get-WinUILanguageOverride)) { Get-WinUILanguageOverride } else { $sysLocale.Name }
        $userLangList = Get-WinUserLanguageList
        $homeLoc = Get-WinHomeLocation
            
        Write-Log "  Display Language: $uiLang" -Color Gray
        Write-Log "  Input Language(s): $($userLangList.InputMethodTips -join ', ')" -Color Gray
        Write-Log "  Format (Culture): $($culture.Name)" -Color Gray
        Write-Log "  Location (GeoId): $($homeLoc.GeoId)" -Color Gray
            
        $allPassed = $true
        $changes = @()
            
        # Display Language Check
        if ($uiLang -ne "en-US") {
            Write-Log "  ⚠ Display Language en-US değil!" -Color Yellow
            $allPassed = $false
            $changes += "DisplayLanguage"
        }
        else {
            Write-Log "  ✓ Display Language: PASS" -Color Green
        }
            
        # Culture/Format Check
        if ($culture.Name -ne "en-US") {
            Write-Log "  ⚠ Format (Culture) en-US değil!" -Color Yellow
            $allPassed = $false
            $changes += "Culture"
        }
        else {
            Write-Log "  ✓ Format (Culture): PASS" -Color Green
        }
            
        # Location Check
        if ($homeLoc.GeoId -ne 244) {
            # 244 = United States
            Write-Log "  ⚠ Location US (244) değil!" -Color Yellow
            $allPassed = $false
            $changes += "Location"
        }
        else {
            Write-Log "  ✓ Location: PASS" -Color Green
        }
            
        # Input Language Check (Turkish-Q)
        if (-not ($userLangList[0].InputMethodTips -match "0000041F$")) {
            Write-Log "  ⚠ Input Language Turkish-Q değil!" -Color Yellow
            $allPassed = $false
            $changes += "InputLanguage"
        }
        else {
            Write-Log "  ✓ Input Language: PASS" -Color Green
        }
            
        $global:ScriptResults['RegionalSettings'] = $allPassed
            
        # AutoFix veya Manuel Fix
        if (-not $allPassed) {
            if ($AutoFix) {
                Write-Log "`n  AutoFix aktif, bölgesel ayarlar düzeltiliyor..." -Color Yellow
                    
                if ($changes -contains "DisplayLanguage") {
                    Set-WinUILanguageOverride -Language "en-US"
                    Write-Log "  ✓ Display Language en-US olarak ayarlandı." -Color Green
                    $global:needsReboot = $true
                }
                if ($changes -contains "Culture") {
                    Set-Culture en-US
                    Write-Log "  ✓ Format (Culture) en-US olarak ayarlandı." -Color Green
                }
                if ($changes -contains "Location") {
                    Set-WinHomeLocation -GeoId 244
                    Write-Log "  ✓ Location US olarak ayarlandı." -Color Green
                }
                if ($changes -contains "InputLanguage") {
                    $langList = New-WinUserLanguageList en-US
                    $langList[0].InputMethodTips.Clear()
                    $langList[0].InputMethodTips.Add("0000041f")
                    Set-WinUserLanguageList $langList -Force
                    Write-Log "  ✓ Input Language Turkish-Q olarak ayarlandı." -Color Green
                }
            }
            else {
                $ans = Read-Host "`n  Tüm bölgesel ayarları düzeltmek istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') {
                    if ($changes -contains "DisplayLanguage") {
                        Set-WinUILanguageOverride -Language "en-US"
                        Write-Log "  ✓ Display Language değiştirildi." -Color Green
                        $global:needsReboot = $true
                    }
                    if ($changes -contains "Culture") {
                        Set-Culture en-US
                        Write-Log "  ✓ Format (Culture) değiştirildi." -Color Green
                    }
                    if ($changes -contains "Location") {
                        Set-WinHomeLocation -GeoId 244
                        Write-Log "  ✓ Location değiştirildi." -Color Green
                    }
                    if ($changes -contains "InputLanguage") {
                        $langList = New-WinUserLanguageList en-US
                        $langList[0].InputMethodTips.Clear()
                        $langList[0].InputMethodTips.Add("0000041f")
                        Set-WinUserLanguageList $langList -Force
                        Write-Log "  ✓ Input Language değiştirildi." -Color Green
                    }
                }
            }
        }
            
        return $allPassed
    }
    catch {
        Write-Log "  HATA: Bölgesel ayarlar kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Regional Settings Error: $_"
        return $false
    }
}

# --- YENİ: ClientAuthTrustMode Kontrolü ---
function Test-ClientAuthTrustMode {
    Write-Log "`n--- ClientAuthTrustMode Kontrolü ---" -Color Cyan
        
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel"
        $valueName = "ClientAuthTrustMode"
            
        try {
            $value = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop).$valueName
            Write-Log "  Mevcut ClientAuthTrustMode: $value" -Color Gray
                
            if ($value -eq 2) {
                Write-Log "  ✓ ClientAuthTrustMode: PASS (Değer: 2)" -Color Green
                $global:ScriptResults['ClientAuthTrustMode'] = $true
                return $true
            }
            else {
                Write-Log "  ⚠ ClientAuthTrustMode: FAIL (Değer: $value, Beklenen: 2)" -Color Yellow
                $global:ScriptResults['ClientAuthTrustMode'] = $false
                    
                if ($AutoFix) {
                    Write-Log "  AutoFix aktif, ClientAuthTrustMode düzeltiliyor..." -Color Yellow
                    $backupFile = "C:\Schannel_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                    reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel" $backupFile /y | Out-Null
                    Set-ItemProperty -Path $regPath -Name $valueName -Value 2 -Force
                    Write-Log "  ✓ ClientAuthTrustMode 2 olarak ayarlandı. Yedek: $backupFile" -Color Green
                    $global:needsReboot = $true
                    return $true
                }
                else {
                    $ans = Read-Host "  ClientAuthTrustMode değerini 2 olarak ayarlamak istiyor musunuz? (Y/N)"
                    if ($ans -match '^[Yy]$') {
                        $backupFile = "C:\Schannel_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                        reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel" $backupFile /y | Out-Null
                        Set-ItemProperty -Path $regPath -Name $valueName -Value 2 -Force
                        Write-Log "  ✓ ClientAuthTrustMode 2 olarak ayarlandı. Yedek: $backupFile" -Color Green
                        $global:needsReboot = $true
                        return $true
                    }
                }
            }
        }
        catch {
            Write-Log "  ⚠ ClientAuthTrustMode bulunamadı!" -Color Yellow
            $global:ScriptResults['ClientAuthTrustMode'] = $false
                
            if ($AutoFix) {
                Write-Log "  AutoFix aktif, ClientAuthTrustMode oluşturuluyor..." -Color Yellow
                $backupFile = "C:\Schannel_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel" $backupFile /y | Out-Null
                New-ItemProperty -Path $regPath -Name $valueName -Value 2 -PropertyType DWORD -Force | Out-Null
                Write-Log "  ✓ ClientAuthTrustMode oluşturuldu ve 2 olarak ayarlandı." -Color Green
                $global:needsReboot = $true
                return $true
            }
            else {
                $ans = Read-Host "  ClientAuthTrustMode oluşturup 2 olarak ayarlamak istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') {
                    $backupFile = "C:\Schannel_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
                    reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel" $backupFile /y | Out-Null
                    New-ItemProperty -Path $regPath -Name $valueName -Value 2 -PropertyType DWORD -Force | Out-Null
                    Write-Log "  ✓ ClientAuthTrustMode oluşturuldu ve 2 olarak ayarlandı." -Color Green
                    $global:needsReboot = $true
                    return $true
                }
            }
        }
            
        return $false
    }
    catch {
        Write-Log "  HATA: ClientAuthTrustMode kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "ClientAuthTrustMode Error: $_"
        return $false
    }
}

# --- YENİ: HTTP/2 Ayarları Kontrolü ---
function Test-HTTP2Settings {
    Write-Log "`n--- HTTP/2 Ayarları Kontrolü ---" -Color Cyan
        
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
        $backupFile = "C:\HTTP_Parameters_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $needsBackup = $false
        $allPassed = $true
            
        foreach ($valueName in @("EnableHttp2Tls", "EnableHttp2Cleartext")) {
            try {
                $value = (Get-ItemProperty -Path $regPath -Name $valueName -ErrorAction Stop).$valueName
                    
                if ($value -eq 0) {
                    Write-Log "  ✓ $valueName`: $value - PASS" -Color Green
                }
                else {
                    Write-Log "  ⚠ $valueName`: $value - FAIL (Beklenen: 0)" -Color Yellow
                    $allPassed = $false
                        
                    if ($AutoFix) {
                        if (-not $needsBackup) {
                            reg export "HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" $backupFile /y | Out-Null
                            $needsBackup = $true
                        }
                        Set-ItemProperty -Path $regPath -Name $valueName -Value 0 -Force
                        Write-Log "    ✓ $valueName 0 olarak ayarlandı." -Color Green
                        $global:needsReboot = $true
                    }
                    else {
                        $ans = Read-Host "    $valueName değerini 0 olarak ayarlamak istiyor musunuz? (Y/N)"
                        if ($ans -match '^[Yy]$') {
                            if (-not $needsBackup) {
                                reg export "HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" $backupFile /y | Out-Null
                                $needsBackup = $true
                            }
                            Set-ItemProperty -Path $regPath -Name $valueName -Value 0 -Force
                            Write-Log "    ✓ $valueName 0 olarak ayarlandı." -Color Green
                            $global:needsReboot = $true
                        }
                    }
                }
            }
            catch {
                Write-Log "  ⚠ $valueName bulunamadı!" -Color Yellow
                $allPassed = $false
                    
                if ($AutoFix) {
                    if (-not $needsBackup) {
                        reg export "HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" $backupFile /y | Out-Null
                        $needsBackup = $true
                    }
                    New-ItemProperty -Path $regPath -Name $valueName -Value 0 -PropertyType DWORD -Force | Out-Null
                    Write-Log "    ✓ $valueName oluşturuldu ve 0 olarak ayarlandı." -Color Green
                    $global:needsReboot = $true
                }
                else {
                    $ans = Read-Host "    $valueName oluşturup 0 olarak ayarlamak istiyor musunuz? (Y/N)"
                    if ($ans -match '^[Yy]$') {
                        if (-not $needsBackup) {
                            reg export "HKLM\SYSTEM\CurrentControlSet\Services\HTTP\Parameters" $backupFile /y | Out-Null
                            $needsBackup = $true
                        }
                        New-ItemProperty -Path $regPath -Name $valueName -Value 0 -PropertyType DWORD -Force | Out-Null
                        Write-Log "    ✓ $valueName oluşturuldu ve 0 olarak ayarlandı." -Color Green
                        $global:needsReboot = $true
                    }
                }
            }
        }
            
        if ($needsBackup) {
            Write-Log "  ℹ Registry yedeklendi: $backupFile" -Color Gray
        }
            
        $global:ScriptResults['HTTP2Settings'] = $allPassed
        return $allPassed
    }
    catch {
        Write-Log "  HATA: HTTP/2 ayarları kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "HTTP/2 Settings Error: $_"
        return $false
    }
}

# --- YENİ: Windows Features/Roles Kontrolü ---
function Test-WindowsFeatures {
    Write-Log "`n--- Windows Features/Roles Kontrolü ---" -Color Cyan
        
    try {
        # Windows Server kontrolü
        $os = Get-CimInstance Win32_OperatingSystem
        $isServer = $os.ProductType -ne 1  # 1=Workstation, 2=Domain Controller, 3=Server
            
        if (-not $isServer) {
            Write-Log "  ℹ Bu bir Windows Server değil, role kontrolü atlanıyor." -Color Gray
            return $true
        }
            
        Write-Log "  Yüklü Windows Features listeleniyor..." -Color Gray
        $installedFeatures = Get-WindowsFeature | Where-Object { $_.InstallState -eq "Installed" }
            
        if ($installedFeatures.Count -eq 0) {
            Write-Log "  ⚠ Hiçbir Windows Feature yüklü görünmüyor!" -Color Yellow
        }
        else {
            Write-Log "  Toplam $($installedFeatures.Count) feature yüklü." -Color Gray
            foreach ($feature in $installedFeatures | Select-Object -First 10) {
                Write-Log "    - $($feature.Name): $($feature.DisplayName)" -Color Gray
            }
            if ($installedFeatures.Count -gt 10) {
                Write-Log "    ... ve $($installedFeatures.Count - 10) daha" -Color Gray
            }
        }
            
        # Apex Central için gerekli roller
        if (-not $global:isApexOne) {
            Write-Log "`n  Apex Central için gerekli roller kontrol ediliyor..." -Color Yellow
                
            $requiredFeatures = @(
                "Web-Server",
                "Web-Windows-Auth",
                "Web-ASP",
                "Web-Asp-Net45",
                "Web-Net-Ext45",
                "Web-CGI",
                "MSMQ",
                "MSMQ-Services"
            )
                
            $missingFeatures = @()
            foreach ($featureName in $requiredFeatures) {
                $feature = Get-WindowsFeature -Name $featureName -ErrorAction SilentlyContinue
                if ($feature -and $feature.InstallState -eq "Installed") {
                    Write-Log "    ✓ $featureName yüklü" -Color Green
                }
                else {
                    Write-Log "    ✗ $featureName EKSIK!" -Color Red
                    $missingFeatures += $featureName
                }
            }
                
            if ($missingFeatures.Count -gt 0) {
                $global:ScriptResults['WindowsFeatures'] = $false
                    
                if ($AutoFix) {
                    Write-Log "`n  AutoFix aktif, eksik roller kuruluyor..." -Color Yellow
                    $ans = 'Y'
                }
                else {
                    $ans = Read-Host "`n  Eksik rolleri kurmak istiyor musunuz? (Y/N)"
                }
                    
                if ($ans -match '^[Yy]$') {
                    Write-Log "  Eksik roller kuruluyor: $($missingFeatures -join ', ')" -Color Yellow
                    Install-WindowsFeature $missingFeatures -IncludeManagementTools
                    Write-Log "  ✓ Roller kuruldu. REBOOT GEREKLİ." -Color Green
                    $global:needsReboot = $true
                }
            }
            else {
                Write-Log "  ✓ Tüm gerekli roller yüklü." -Color Green
                $global:ScriptResults['WindowsFeatures'] = $true
            }
        }
            
        return $true
    }
    catch {
        Write-Log "  HATA: Windows Features kontrolü başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Windows Features Error: $_"
        return $false
    }
}

# --- YENİ: IISCrypto Best Practice Uygulama ---
function Install-IISCryptoBestPractice {
    Write-Log "`n--- IISCrypto Best Practice Uygulaması ---" -Color Cyan
        
    try {
        $cliPath = "C:\IISCryptoCli.exe"
        $backupFile = "C:\IISCrypto_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
            
        # IISCryptoCli indir
        if (Test-Path $cliPath) {
            Write-Log "  ℹ IISCryptoCli zaten mevcut: $cliPath" -Color Gray
        }
        else {
            Write-Log "  İndiriliyor: IISCryptoCli.exe..." -Color Yellow
            try {
                Invoke-WebRequest "https://www.nartac.com/Downloads/IISCrypto/IISCryptoCli.exe" -OutFile $cliPath -ErrorAction Stop
                Write-Log "  ✓ IISCryptoCli indirildi: $cliPath" -Color Green
            }
            catch {
                Write-Log "  HATA: IISCryptoCli indirilemedi: $_" -Level "ERROR" -Color Red
                return $false
            }
        }
            
        # Yedek al
        Write-Log "  Registry yedekleniyor..." -Color Yellow
        reg export "HKLM\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL" $backupFile /y | Out-Null
        Write-Log "  ✓ Yedek oluşturuldu: $backupFile" -Color Green
            
        # Best Practice uygula
        if ($AutoFix -or $ApplyIISCrypto) {
            $ans = 'Y'
        }
        else {
            Write-Host "`n  ⚠ DİKKAT: IISCrypto Best Practice bazı eski protokolleri devre dışı bırakır!" -ForegroundColor Yellow
            Write-Host "  Bu işlem MachineKeys izinlerini etkileyebilir." -ForegroundColor Yellow
            $ans = Read-Host "  IISCrypto Best Practice uygulamak istiyor musunuz? (Y/N)"
        }
            
        if ($ans -match '^[Yy]$') {
            Write-Log "  IISCrypto Best Practice uygulanıyor..." -Color Yellow
            & $cliPath /template best /quiet
                
            if ($LASTEXITCODE -eq 0) {
                Write-Log "  ✓ IISCrypto Best Practice başarıyla uygulandı." -Color Green
                Write-Log "  ⚠ ÖNEMLÄ°: C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys izinlerini kontrol edin!" -Color Yellow
                $global:needsReboot = $true
                $global:ScriptResults['IISCrypto'] = $true
                return $true
            }
            else {
                Write-Log "  HATA: IISCrypto uygulaması başarısız (Exit Code: $LASTEXITCODE)" -Level "ERROR" -Color Red
                $global:ScriptResults['IISCrypto'] = $false
                return $false
            }
        }
        else {
            Write-Log "  ℹ İşlem iptal edildi." -Color Gray
            return $false
        }
    }
    catch {
        Write-Log "  HATA: IISCrypto işlemi başarısız: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "IISCrypto Error: $_"
        return $false
    }
}

# --- IPv6/v4 Precedence Kontrolü ---
function Set-IPv4Priority {
    Write-Log "  IPv4 önceliği artırılıyor..." -Color Yellow
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
        $name = "DisabledComponents"
            
        if (-not (Test-Path $regPath)) { 
            New-Item -Path $regPath -Force -ErrorAction Stop | Out-Null 
        }
            
        Set-ItemProperty -Path $regPath -Name $name -Value 0x20 -Type DWord -Force -ErrorAction Stop
        Write-Log "  ✓ IPv4 önceliği artırıldı (DisabledComponents = 0x20). REBOOT GEREKLİ." -Color Green
        $global:needsReboot = $true
        $global:ScriptResults['IPv4Priority'] = $true
        return $true
    }
    catch {
        Write-Log "  HATA: IPv4 önceliği ayarlanırken sorun oluştu: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "IPv4 Priority Error: $_"
        $global:ScriptResults['IPv4Priority'] = $false
        return $false
    }
}

function Test-IPv6Precedence {
    Write-Log "`n--- IPv6 Precedence Kontrolü ---" -Color Cyan
    try {
        $prefixOutput = netsh interface ipv6 show prefixpolicies 2>&1
            
        if ($LASTEXITCODE -ne 0) {
            Write-Log "  UYARI: IPv6 prefix policies alınamadı." -Level "WARNING" -Color Yellow
            return
        }

        $prefixes = $prefixOutput | Select-String "^\s*\d+" | ForEach-Object {
            $parts = ($_ -split '\s+') | Where-Object { $_ -ne "" }
            if ($parts.Count -ge 3) { 
                [PSCustomObject]@{ 
                    Precedence = [int]$parts[0]
                    Prefix     = $parts[2] 
                } 
            }
        }
            
        $ipv4 = $prefixes | Where-Object { $_.Prefix -eq "::ffff:0:0/96" }
        $ipv6 = $prefixes | Where-Object { $_.Prefix -eq "::/0" }
            
        if ($null -eq $ipv4 -or $null -eq $ipv6) {
            Write-Log "  UYARI: IPv4 veya IPv6 precedence değerleri okunamadı." -Level "WARNING" -Color Yellow
            return
        }

        $priority = if ($ipv4.Precedence -gt $ipv6.Precedence) { "IPv4" } else { "IPv6" }
        Write-Log "  Mevcut öncelik: $priority (IPv4: $($ipv4.Precedence), IPv6: $($ipv6.Precedence))" -Color $(if ($priority -eq "IPv4") { "Green" }else { "Yellow" })
            
        if ($priority -ne "IPv4") {
            Write-Log "  ⚠ IPv6 önceliği IPv4'ten yüksek. Trend Micro için IPv4 öncelikli olmalı." -Color Yellow
                
            if ($AutoFix) { 
                Write-Log "  AutoFix aktif, IPv4 önceliği ayarlanıyor..." -Color Yellow
                Set-IPv4Priority 
            }
            else {
                $ans = Read-Host "  IPv4 önceliğini artırmak istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') { Set-IPv4Priority }
            }
        }
        else {
            Write-Log "  ✓ IPv4 önceliği zaten doğru yapılandırılmış." -Color Green
        }
    }
    catch {
        Write-Log "  UYARI: IPv6 precedence kontrolü yapılamadı: $_" -Level "WARNING" -Color Yellow
        $global:ExecutionErrors += "IPv6 Precedence Check Error: $_"
    }
}

# --- Sistem Gereksinimleri ---
function Test-SystemRequirements {
    Write-Log "`n--- Sistem Gereksinimleri Kontrolü ---" -Color Cyan
        
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $osVer = [Version]$os.Version
        $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
        $coreCount = ($cpu | Measure-Object NumberOfCores -Sum).Sum
        $mem = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $totalRAM = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2)
        $disk = Get-PSDrive C -ErrorAction Stop
        $freeGB = [math]::Round($disk.Free / 1GB, 2)
        $usedGB = [math]::Round($disk.Used / 1GB, 2)

        Write-Log "  OS: $($os.Caption) (Build: $($os.Version))" -Color Gray
        Write-Log "  CPU: $coreCount Cores ($($cpu[0].Name))" -Color Gray
        Write-Log "  RAM: $totalRAM GB" -Color Gray
        Write-Log "  Disk (C:): $freeGB GB Boş / $usedGB GB Kullanılmış" -Color Gray

        if ($global:isApexOne) {
            $osPass = $osVer -ge [Version]"6.3" # Windows Server 2012 R2+
            $cpuPass = $coreCount -ge 2
            $ramPass = $totalRAM -ge 8
            $diskPass = $freeGB -ge 100
        }
        else {
            $osPass = $osVer -ge [Version]"10.0" # Windows Server 2016+
            $cpuPass = $coreCount -ge 4
            $ramPass = $totalRAM -ge 16
            $diskPass = $freeGB -ge 200
        }

        $results = @(
            @{ Name = "OS"; Status = $osPass; Required = $(if ($global:isApexOne) { "2012R2+" }else { "2016+" }); Current = $os.Caption },
            @{ Name = "CPU"; Status = $cpuPass; Required = $(if ($global:isApexOne) { "2 cores" }else { "4 cores" }); Current = "$coreCount cores" },
            @{ Name = "RAM"; Status = $ramPass; Required = $(if ($global:isApexOne) { "8 GB" }else { "16 GB" }); Current = "$totalRAM GB" },
            @{ Name = "Disk"; Status = $diskPass; Required = $(if ($global:isApexOne) { "100 GB" }else { "200 GB" }); Current = "$freeGB GB free" }
        )

        $allPassed = $true
        foreach ($res in $results) {
            $icon = if ($res.Status) { "✓" }else { "✗"; $allPassed = $false }
            $color = if ($res.Status) { "Green" }else { "Red" }
            Write-Log "  $icon $($res.Name): $($res.Current) (Gerekli: $($res.Required))" -Color $color
        }

        $global:ScriptResults['SystemRequirements'] = $allPassed
            
        if (-not $allPassed) {
            Write-Log "`n  ⚠ UYARI: Bazı sistem gereksinimleri karşılanmıyor!" -Color Yellow
        }
    }
    catch {
        Write-Log "  HATA: Sistem gereksinimleri kontrol edilemedi: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "System Requirements Check Error: $_"
        $global:ScriptResults['SystemRequirements'] = $false
    }
}

# --- Servis Kontrolleri ---
function Test-ModuleServices {
    param(
        [Array]$ServiceList, 
        [String]$Title
    )
        
    Write-Log "`n--- $Title Kontrolü ---" -Color Cyan
        
    if ($null -eq $ServiceList -or $ServiceList.Count -eq 0) {
        Write-Log "  ℹ Kontrol edilecek servis bulunamadı." -Color Gray
        return
    }

    try {
        foreach ($Svc in $ServiceList) {
            try {
                $status = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
                    
                if ($status) {
                    $color = if ($status.Status -eq "Running") { "Green" }else { "Red" }
                    $icon = if ($status.Status -eq "Running") { "✓" }else { "✗" }
                    Write-Log "  $icon $($Svc.Display) -> $($status.Status) (StartType: $($status.StartType))" -Color $color
                }
                else {
                    Write-Log "  ℹ $($Svc.Display) bulunamadı (Yüklü değil)." -Color Gray
                }
            }
            catch {
                Write-Log "  ⚠ $($Svc.Display) kontrol edilemedi: $_" -Color Yellow
            }
        }
    }
    catch {
        Write-Log "  HATA: Servis kontrolleri sırasında bir hata oluştu: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Service Check Error ($Title): $_"
    }
}

function Test-AllServices {
    $ServerServices = @(
        @{Name = "TmMaster"; Display = "Apex One Master Service" },
        @{Name = "OfcAoSMgr"; Display = "Apex One Plug-in Manager" },
        @{Name = "OSCEIntegrationService"; Display = "Apex One Active Directory Service" },
        @{Name = "OfcLogReceiverSvc"; Display = "Apex One Log Receiver Service" },
        @{Name = "ofcDdaSvr"; Display = "Apex One Deep Discovery Service" },
        @{Name = "DbServer"; Display = "Apex One Database Process" }
    )
        
    $AgentServices = @(
        @{Name = "TmCCSF"; Display = "Common Client Solution Framework" },
        @{Name = "Tmlisten"; Display = "NT Listener" },
        @{Name = "Ntrtscan"; Display = "NT RealTimeScan" },
        @{Name = "TMBMSRV"; Display = "Unauthorized Change Prevention" }
    )
        
    Test-ModuleServices -ServiceList $ServerServices -Title "Apex Sunucu Servisleri"
    Test-ModuleServices -ServiceList $AgentServices -Title "Apex Ajan Servisleri"
}

# --- Modül Kontrolleri ---
function Test-ApexModules {
    $Modules = @(
        @{Title = "Application Control"; Services = @(@{Name = "OfcAoSMgr"; Display = "Plug-in Manager" }) },
        @{Title = "Endpoint Sensor"; Services = @(@{Name = "TmihSvc"; Display = "IMIH Service" }) },
        @{Title = "Vulnerability Protection"; Services = @(@{Name = "TmVsTm"; Display = "VP Service" }) }
    )
        
    foreach ($Mod in $Modules) {
        Test-ModuleServices -ServiceList $Mod.Services -Title $Mod.Title
    }
}

# --- Güvenlik & SSL Kontrolleri ---
function Test-SecuritySettings {
    Write-Log "`n--- Güvenlik (SSL/TLS) Kontrolleri ---" -Color Cyan
        
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel"
            
        # IISCrypto/Schannel Kontrolü
        if (Test-Path $regPath) {
            try {
                $cta = Get-ItemProperty -Path $regPath -Name "ClientAuthTrustMode" -ErrorAction SilentlyContinue
                if ($cta) {
                    $recommended = if ($cta.ClientAuthTrustMode -eq 2) { "✓" } else { "⚠" }
                    $color = if ($cta.ClientAuthTrustMode -eq 2) { "Green" } else { "Yellow" }
                    Write-Log "  $recommended ClientAuthTrustMode: $($cta.ClientAuthTrustMode) (Önerilen: 2)" -Color $color
                }
                else {
                    Write-Log "  ℹ ClientAuthTrustMode ayarı bulunamadı." -Color Gray
                }
            }
            catch {
                Write-Log "  ⚠ ClientAuthTrustMode okunamadı: $_" -Color Yellow
            }
        }
        else {
            Write-Log "  ℹ Schannel registry yolu bulunamadı." -Color Gray
        }

        # HTTP/2 Değerleri
        $http2Path = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
        if (Test-Path $http2Path) {
            try {
                $h2tls = Get-ItemProperty -Path $http2Path -Name "EnableHttp2Tls" -ErrorAction SilentlyContinue
                if ($h2tls) {
                    $recommended = if ($h2tls.EnableHttp2Tls -eq 0) { "✓" } else { "ℹ" }
                    $color = if ($h2tls.EnableHttp2Tls -eq 0) { "Green" } else { "Yellow" }
                    Write-Log "  $recommended EnableHttp2Tls: $($h2tls.EnableHttp2Tls) (Apex Central için 0 önerilir)" -Color $color
                }
            }
            catch {
                Write-Log "  ⚠ EnableHttp2Tls okunamadı: $_" -Color Yellow
            }
        }

        Write-Log "`n  ⚠ UYARI: IISCrypto veya SSL araçları dosya sistem izinlerini (MachineKeys) bozabilir." -Color Yellow
        Write-Log "  Lütfen 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys' izinlerini kontrol edin." -Color Gray
            
        $global:ScriptResults['SecuritySettings'] = $true
    }
    catch {
        Write-Log "  HATA: Güvenlik kontrolleri sırasında hata: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Security Settings Check Error: $_"
        $global:ScriptResults['SecuritySettings'] = $false
    }
}

# --- .NET Framework Kontrolü ---
function Test-DotNetFramework {
    Write-Log "`n--- .NET Framework Kontrolü ---" -Color Cyan
        
    try {
        $netPath = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full"
        if (Test-Path $netPath) {
            $release = (Get-ItemProperty -Path $netPath -ErrorAction Stop).Release
                
            $version = switch ($release) {
                { $_ -ge 533320 } { "4.8.1 veya üzeri"; break }
                { $_ -ge 528040 } { "4.8"; break }
                { $_ -ge 461808 } { "4.7.2"; break }
                { $_ -ge 461308 } { "4.7.1"; break }
                { $_ -ge 460798 } { "4.7"; break }
                default { "4.6 veya daha eski" }
            }
                
            $isOk = $release -ge 461808 # 4.7.2+
            $icon = if ($isOk) { "✓" } else { "⚠" }
            $color = if ($isOk) { "Green" } else { "Yellow" }
                
            Write-Log "  $icon .NET Framework: $version (Release: $release)" -Color $color
            if (-not $isOk) {
                Write-Log "    Önerilen: .NET Framework 4.7.2 veya üzeri" -Color Yellow
            }
        }
        else {
            Write-Log "  ⚠ .NET Framework 4.x bulunamadı!" -Color Yellow
        }
    }
    catch {
        Write-Log "  ⚠ .NET Framework kontrolü yapılamadı: $_" -Level "WARNING" -Color Yellow
    }
}

# --- Rapor Hazırlama ---
function Export-Report {
    Write-Log "`n--- Rapor Hazırlanıyor ---" -Color Yellow
        
    try {
        $reportPath = Split-Path $MyInvocation.PSCommandPath -Parent
        if ([string]::IsNullOrEmpty($reportPath)) {
            $reportPath = $PWD.Path
        }
            
        $reportFile = Join-Path $reportPath "ApexReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $csInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction Stop
            
        $report = @"
================================================================================
TREND MICRO APEX DIAGNOSTIC RAPORU
================================================================================
Tarih: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Script Versiyonu: v1.1.1
Ürün: $(if($global:isApexOne){"Apex One"}else{"Apex Central"})
--------------------------------------------------------------------------------

SİSTEM BİLGİLERİ:
  İşletim Sistemi: $($osInfo.Caption)
  Build: $($osInfo.Version)
  Bilgisayar Adı: $($csInfo.Name)
  CPU: $($cpuInfo[0].Name)
  CPU Çekirdek: $(($cpuInfo | Measure-Object NumberOfCores -Sum).Sum)
  Toplam RAM: $([math]::Round($csInfo.TotalPhysicalMemory / 1GB, 2)) GB
  
--------------------------------------------------------------------------------
KONTROL SONUÇLARI:
"@
        foreach ($key in $global:ScriptResults.Keys | Sort-Object) {
            $status = if ($global:ScriptResults[$key]) { "✓ BAŞARILI" } else { "✗ BAŞARISIZ" }
            $report += "`n  $key : $status"
        }

        if ($global:ExecutionErrors.Count -gt 0) {
            $report += "`n`n--------------------------------------------------------------------------------"
            $report += "`nHATALAR VE UYARILAR:"
            foreach ($err in $global:ExecutionErrors) {
                $report += "`n  - $err"
            }
        }

        if ($global:needsReboot) {
            $report += "`n`n--------------------------------------------------------------------------------"
            $report += "`n⚠⚠⚠ DİKKAT: Sistem yeniden başlatılmalı! ⚠⚠⚠"
            $report += "`nYapılan değişikliklerin aktif olması için sistemi yeniden başlatın."
        }

        $report += "`n`n================================================================================"
        $report += "`nRapor Son Güncelleme: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $report += "`n================================================================================"
            
        $report | Out-File $reportFile -Encoding UTF8 -ErrorAction Stop
        Write-Log "  ✓ Rapor oluşturuldu: $reportFile" -Color Green
            
        # Raporu aç
        $openReport = Read-Host "`n  Raporu açmak istiyor musunuz? (Y/N)"
        if ($openReport -match '^[Yy]$') {
            Start-Process notepad.exe -ArgumentList $reportFile
        }
    }
    catch {
        Write-Log "  HATA: Rapor dosyasına yazılamadı: $_" -Level "ERROR" -Color Red
        $global:ExecutionErrors += "Report Export Error: $_"
    }
}

# --- Ön Kontroller (Kurulum Öncesi) ---
function Start-PreInstallChecks {
    Write-Log "`n=================================================================================" -Color Cyan
    Write-Log "           KURULUM ÖNCESİ KONTROLLER BAŞLATILIYOR" -Color Cyan
    Write-Log "=================================================================================" -Color Cyan
        
    Test-SystemRequirements
    Test-KeyboardLayout
    Test-Hostname
    Test-TimeZone
    Test-RegionalSettings
    Test-ClientAuthTrustMode
    Test-HTTP2Settings
    Test-IPv6Precedence
    Test-DotNetFramework
    Test-WindowsFeatures
    Test-SecuritySettings
        
    Write-Log "`n=================================================================================" -Color Green
    Write-Log "           ÖN KONTROLLER TAMAMLANDI" -Color Green
    Write-Log "=================================================================================" -Color Green
        
    if ($global:needsReboot) {
        Write-Log "`n⚠⚠⚠ DİKKAT: Bazı değişiklikler sistem yeniden başlatılmasını gerektiriyor! ⚠⚠⚠" -Color Yellow
        Write-Log "Lütfen kuruluma devam etmeden önce sistemi yeniden başlatın." -Color Yellow
    }
}

# --- Ana Menü ---
function Start-Diag {
    if (-not (Test-Admin)) { 
        Write-Host "`nScript Admin yetkisi olmadan çalıştırılamaz!" -ForegroundColor Red
        Invoke-Pause "Çıkmak için bir tuşa basın..."
        return 
    }
        
    Clear-Host

    Write-Log "=================================================================================" -Color Cyan
    Write-Log "     TREND MICRO APEX ONE & CENTRAL DIAGNOSTIC TOOL v1.1.1" -Color Cyan
    Write-Log "=================================================================================" -Color Cyan
    Write-Log "  Author: bab-ı kod" -Color Gray
    Write-Log "  Date: $(Get-Date -Format 'yyyy-MM-dd')" -Color Gray
    Write-Log "=================================================================================" -Color Cyan
        
    # Ürün Seçimi
    if ([string]::IsNullOrEmpty($ProductType)) {
        Write-Host "`nÜrün Tipi Seçiniz:" -ForegroundColor White
        Write-Host "  1. Apex One" -ForegroundColor White
        Write-Host "  2. Apex Central" -ForegroundColor White
            
        do {
            $choice = Read-Host "`nSeçim (1/2)"
        } while ($choice -notmatch '^[12]$')
            
        $global:isApexOne = ($choice -eq "1")
    }
    else {
        $global:isApexOne = ($ProductType -eq "ApexOne")
    }
        
    $productName = if ($global:isApexOne) { "Apex One" } else { "Apex Central" }
    Write-Log "`nSeçilen Ürün: $productName" -Color Green

    do {
        Write-Host "`n" -NoNewline
        Write-Host "================================================================================" -ForegroundColor White
        Write-Host "                            ANA MENÜ" -ForegroundColor White
        Write-Host "================================================================================" -ForegroundColor White
        Write-Host "  KURULUM ÖNCESİ KONTROLLER:" -ForegroundColor Cyan
        Write-Host "  1. Tüm Kurulum Öncesi Kontrolleri Çalıştır (ÖNERİLEN)" -ForegroundColor Yellow
        Write-Host "  2. Klavye Düzeni Kontrolü (Turkish-Q)" -ForegroundColor White
        Write-Host "  3. Hostname Kontrolü" -ForegroundColor White
        Write-Host "  4. Timezone Kontrolü" -ForegroundColor White
        Write-Host "  5. Bölgesel Ayarlar Kontrolü" -ForegroundColor White
        Write-Host "  6. ClientAuthTrustMode Kontrolü" -ForegroundColor White
        Write-Host "  7. HTTP/2 Ayarları Kontrolü" -ForegroundColor White
        Write-Host "  8. IPv4 Önceliği Kontrolü & Fix" -ForegroundColor White
        Write-Host "  9. Windows Features/Roles Kontrolü" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "  SİSTEM KONTROLLERI:" -ForegroundColor Cyan
        Write-Host "  10. Sistem Gereksinimlerini Kontrol Et" -ForegroundColor White
        Write-Host "  11. .NET Framework Kontrolü" -ForegroundColor White
        Write-Host "  12. Güvenlik (SSL/TLS) Kontrollerini Çalıştır" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "  KURULUM SONRASI KONTROLLER:" -ForegroundColor Cyan
        Write-Host "  13. Servis Durumlarını Kontrol Et" -ForegroundColor White
        Write-Host "  14. Gelişmiş Modül Kontrolleri (AC, EDS, VP)" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "  İLERİ SEVİYE:" -ForegroundColor Magenta
        Write-Host "  15. IISCrypto Best Practice Uygula" -ForegroundColor Magenta
        Write-Host "" -ForegroundColor White
        Write-Host "  16. Rapor Dışa Aktar" -ForegroundColor Yellow
        Write-Host "  Q. Çıkış" -ForegroundColor Red
        Write-Host "================================================================================" -ForegroundColor White
            
        $opt = Read-Host "`nSeçiminiz"
            
        switch ($opt) {
            "1" { Clear-Host; Start-PreInstallChecks; break }
            "2" { Clear-Host; Test-KeyboardLayout; break }
            "3" { Clear-Host; Test-Hostname; break }
            "4" { Clear-Host; Test-TimeZone; break }
            "5" { Clear-Host; Test-RegionalSettings; break }
            "6" { Clear-Host; Test-ClientAuthTrustMode; break }
            "7" { Clear-Host; Test-HTTP2Settings; break }
            "8" { Clear-Host; Test-IPv6Precedence; break }
            "9" { Clear-Host; Test-WindowsFeatures; break }
            "10" { Clear-Host; Test-SystemRequirements; break }
            "11" { Clear-Host; Test-DotNetFramework; break }
            "12" { Clear-Host; Test-SecuritySettings; break }
            "13" { Clear-Host; Test-AllServices; break }
            "14" { Clear-Host; Test-ApexModules; break }
            "15" { Clear-Host; Install-IISCryptoBestPractice; break }
            "16" { Clear-Host; Export-Report; break }
            { $_ -match '^[Qq]$' } { 
                Write-Log "`nÇıkılıyor..." -Color Yellow
                break 
            }
            default { 
                Write-Host "`nGeçersiz seçim! Lütfen 1-16 arası veya Q tuşlayın." -ForegroundColor Red 
            }
        }
            
        if ($opt -notmatch '^[Qq]$') {
            Invoke-Pause
        }
            
    } while ($opt -notmatch '^[Qq]$')
        
    Write-Log "=================================================================================" -Color Green
    Write-Log "                            PROGRAM SONLANDIRILDI" -Color Green
    Write-Log "=================================================================================" -Color Green
        
    if ($global:ExecutionErrors.Count -gt 0) {
        Write-Log "`n⚠ Toplam $($global:ExecutionErrors.Count) hata/uyarı kaydedildi." -Color Yellow
        Write-Log "Detaylar için log dosyasını kontrol edin: $LogPath" -Color Gray
    }
        
    if ($global:needsReboot) {
        Write-Log "`n⚠⚠⚠ SİSTEMİ YENİDEN BAŞLATMAYI UNUTMAYIN! ⚠⚠⚠" -Color Yellow
    }
}

# Betiği başlat
Start-Diag

Write-Host ("=" * 85) -ForegroundColor DarkYellow
Write-Host (" " * 25) "Gayret bizden, tevfik Allah'tandir." (" " * 23) -BackgroundColor DarkYellow -ForegroundColor Black
Write-Host ("=" * 85) -ForegroundColor DarkYellow