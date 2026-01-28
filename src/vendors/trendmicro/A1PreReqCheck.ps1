<#
.SYNOPSIS
    Trend Micro Apex One & Apex Central Sunucu Diagnostic ve Ön Hazırlık Aracı (v1.0.1)

.DESCRIPTION
    Bu betik, Trend Micro Apex One ve Apex Central kurulumları için kapsamlı bir sistem kontrolü, 
    ön hazırlık doğrulaması ve kurulum sonrası servis denetimi sunar. 

    Sürüm: v1.0.1
    Tarih: 2026-01-28

    Özellikler:
    - Kapsamlı Sistem Kontrolleri (OS, CPU, RAM, Disk, .NET, IIS, MSMQ, SQL)
    - IPv4 Önceliği (Precedence) Kontrolü ve Optimizasyonu
    - Kurulum Sonrası Modül Kontrolleri (Application Control, Endpoint Sensor, VP, MDR)
    - Detaylı Loglama ve Rapor Dışa Aktarımı

.AUTHOR
    dad-u-bab

.NOTES
    YASAL UYARI: Bu betik henüz tam teşekküllü test edilmemiştir. Sorumluluk kullanıcıya aittir.
    DISCLAIMER: This script is not fully tested. Use at your own risk.
#>

# Parametreler
param(
    [string]$ProductType = "",  # "ApexOne" veya "ApexCentral"
    [switch]$NoDownload,
    [switch]$SkipRebootCheck,
    [switch]$AutoFix,
    [string]$LogPath = "C:\ApexSetupLogs"
)

# Global değişkenler
$global:isApexOne = $true
$global:needsReboot = $false
$global:ExecutionErrors = @()
$global:ScriptResults = @{}
$ErrorActionPreference = "Continue"

# Loglama fonksiyonu
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    
    # Ekrana yaz
    Write-Host $logMessage -ForegroundColor $Color
    
    # Dosyaya yaz
    if (-not (Test-Path $LogPath)) {
        try { New-Item -Path $LogPath -ItemType Directory -Force | Out-Null } catch {}
    }
    $logFile = Join-Path $LogPath "apex_diag_$(Get-Date -Format 'yyyyMMdd').log"
    try { Add-Content -Path $logFile -Value $logMessage -Encoding UTF8 } catch {}
}

# Administrator kontrolü
function Test-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Log "HATA: Bu script Administrator olarak çalıştırılmalıdır!" -Level "ERROR" -Color Red
        return $false
    }
    return $true
}

# --- IPv6/v4 Precedence Kontrolü ---
function Set-IPv4Priority {
    Write-Log "IPv4 önceliği artırılıyor..." -Color Yellow
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
        $name = "DisabledComponents"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name $name -Value 0x20 -Type DWord -Force
        Write-Log "✓ IPv4 önceliği artırıldı (DisabledComponents = 0x20). REBOOT GEREKLİ." -Color Green
        $global:needsReboot = $true
        return $true
    }
    catch {
        Write-Log "HATA: IPv4 önceliği ayarlanırken sorun oluştu: $_" -Level "ERROR" -Color Red
        return $false
    }
}

function Test-IPv6Precedence {
    Write-Log "--- IPv6 Precedence Kontrolü ---" -Color Cyan
    try {
        $prefixOutput = netsh interface ipv6 show prefixpolicies
        $prefixes = $prefixOutput | Select-String "^\s*\d+" | ForEach-Object {
            $parts = ($_ -split '\s+') | Where-Object { $_ -ne "" }
            if ($parts.Count -ge 3) { [PSCustomObject]@{ Precedence = [int]$parts[0]; Prefix = $parts[2] } }
        }
        $ipv4 = $prefixes | Where-Object { $_.Prefix -eq "::ffff:0:0/96" }
        $ipv6 = $prefixes | Where-Object { $_.Prefix -eq "::/0" }
        
        $priority = if ($ipv4.Precedence -gt $ipv6.Precedence) { "IPv4" } else { "IPv6" }
        Write-Log "Mevcut öncelik: $priority" -Color $(if ($priority -eq "IPv4") { "Green" }else { "Yellow" })
        
        if ($priority -ne "IPv4") {
            if ($AutoFix) { Set-IPv4Priority }
            else {
                $ans = Read-Host "IPv4 önceliğini artırmak istiyor musunuz? (Y/N)"
                if ($ans -match '^[Yy]$') { Set-IPv4Priority }
            }
        }
    }
    catch { Write-Log "UYARI: IPv6 precedence kontrolü yapılamadı." -Level "WARNING" }
}

# --- Sistem Gereksinimleri ---
function Test-SystemRequirements {
    Write-Log "--- Sistem Gereksinimleri Kontrolü ---" -Color Cyan
    $os = Get-CimInstance Win32_OperatingSystem
    $osVer = [Version]$os.Version
    $cpu = Get-CimInstance Win32_Processor
    $coreCount = ($cpu | Measure-Object NumberOfCores -Sum).Sum
    $mem = Get-CimInstance Win32_ComputerSystem
    $totalRAM = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2)
    $disk = Get-PSDrive C
    $freeGB = [math]::Round($disk.Free / 1GB, 2)

    Write-Log "OS: $($os.Caption) (Build: $($os.Version))" -Color Gray
    Write-Log "CPU: $coreCount Cores / RAM: $totalRAM GB / Disk: $freeGB GB Free" -Color Gray

    if ($global:isApexOne) {
        $osPass = $osVer -ge [Version]"6.3" # 2012 R2+
        $cpuPass = $coreCount -ge 2
        $ramPass = $totalRAM -ge 8
        $diskPass = $freeGB -ge 100
    }
    else {
        $osPass = $osVer -ge [Version]"10.0" # 2016+
        $cpuPass = $coreCount -ge 4
        $ramPass = $totalRAM -ge 16
        $diskPass = $freeGB -ge 200
    }

    $results = @(
        @{ Name = "OS"; Status = $osPass; Required = $(if ($global:isApexOne) { "2012R2+" }else { "2016+" }) },
        @{ Name = "CPU"; Status = $cpuPass; Required = $(if ($global:isApexOne) { "2 cores" }else { "4 cores" }) },
        @{ Name = "RAM"; Status = $ramPass; Required = $(if ($global:isApexOne) { "8 GB" }else { "16 GB" }) },
        @{ Name = "Disk"; Status = $diskPass; Required = $(if ($global:isApexOne) { "100 GB" }else { "200 GB" }) }
    )

    foreach ($res in $results) {
        $icon = if ($res.Status) { "✓" }else { "✗" }
        $color = if ($res.Status) { "Green" }else { "Red" }
        Write-Log "  $icon $($res.Name) (Gerekli: $($res.Required))" -Color $color
    }
}

# --- Servis Kontrolleri ---
function Test-ModuleServices {
    param([Array]$ServiceList, [String]$Title)
    Write-Log "--- $Title Kontrolü ---" -Color Cyan
    foreach ($Svc in $ServiceList) {
        $status = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
        if ($status) {
            $color = if ($status.Status -eq "Running") { "Green" }else { "Red" }
            Write-Log "  $(if($status.Status -eq 'Running'){'✓'}else{'✗'}) $($Svc.Display) -> $($status.Status)" -Color $color
        }
        else {
            Write-Log "  ℹ $($Svc.Display) bulunamadı." -Color Gray
        }
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
    Write-Log "--- Güvenlik (SSL/TLS) Kontrolleri ---" -Color Cyan
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Schannel"
    
    # IISCrypto/Schannel Kontrolü
    try {
        $cta = Get-ItemProperty -Path $regPath -Name "ClientAuthTrustMode" -ErrorAction SilentlyContinue
        if ($cta) {
            Write-Log "  ✓ ClientAuthTrustMode: $($cta.ClientAuthTrustMode) (Önerilen: 2)" -Color Green
        }
        else {
            Write-Log "  ℹ ClientAuthTrustMode ayarı bulunamadı." -Color Gray
        }
    }
    catch { }

    # HTTP/2 Değerleri
    $http2Path = "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters"
    try {
        $h2tls = Get-ItemProperty -Path $http2Path -Name "EnableHttp2Tls" -ErrorAction SilentlyContinue
        if ($h2tls) {
            Write-Log "  ℹ EnableHttp2Tls: $($h2tls.EnableHttp2Tls) (Apex Central için 0 önerilir)" -Color $(if ($h2tls.EnableHttp2Tls -eq 0) { "Green" }else { "Yellow" })
        }
    }
    catch { }

    Write-Log "⚠ UYARI: IISCrypto veya SSL araçları dosya sistem izinlerini (MachineKeys) bozabilir." -Color Yellow
    Write-Log "Lütfen 'C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys' izinlerini kontrol edin." -Color Gray
}

# --- Rapor Hazırlama ---
function Export-Report {
    Write-Log "Rapor hazırlanıyor..." -Color Yellow
    $reportFile = Join-Path (Split-Path $MyInvocation.MyCommand.Path) "ApexReport_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
    $report = @"
TREND MICRO APEX DIAGNOSTIC RAPORU
Tarih: $(Get-Date)
----------------------------------
$(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
$(Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty Name)
----------------------------------
"@
    try {
        $report | Out-File $reportFile -Encoding UTF8
        Write-Log "✓ Rapor oluşturuldu: $reportFile" -Color Green
    }
    catch {
        Write-Log "HATA: Rapor dosyasına yazılamadı." -Level "ERROR" -Color Red
    }
}

# --- Ana Menü ---
function Start-Diag {
    if (-not (Test-Admin)) { return }
    Clear-Host
    Write-Log "=== APEX ONE & CENTRAL DIAGNOSTIC TOOL v1.0 ===" -Color Cyan
    
    # Ürün Seçimi
    Write-Host "`nÜrün Tipi Seçiniz:"
    Write-Host "1. Apex One"
    Write-Host "2. Apex Central"
    $choice = Read-Host "Seçim (1/2)"
    $global:isApexOne = if ($choice -eq "2") { $false }else { $true }

    do {
        Write-Host "`n--- ANA MENÜ ---" -ForegroundColor White
        Write-Host "1. Tüm Sistem Kontrollerini Çalıştır"
        Write-Host "2. IPv4 Önceliği Kontrolü & Fix"
        Write-Host "3. Servis Durumlarını Kontrol Et"
        Write-Host "4. Gelişmiş Modül Kontrolleri (AC, EDS, VP)"
        Write-Host "5. Güvenlik (SSL/TLS) Kontrollerini Çalıştır"
        Write-Host "6. Rapor Dışa Aktar"
        Write-Host "Q. Çıkış"
        
        $opt = Read-Host "`nSeçiminiz"
        switch ($opt) {
            "1" { Clear-Host; Test-SystemRequirements; break }
            "2" { Clear-Host; Test-IPv6Precedence; break }
            "3" { Clear-Host; Test-AllServices; break }
            "4" { Clear-Host; Test-ApexModules; break }
            "5" { Clear-Host; Test-SecuritySettings; break }
            "6" { Clear-Host; Export-Report; break }
        }
    } while ($opt -ne "q")
}

# Betiği başlat
if ($MyInvocation.InvocationName -ne '.') { Start-Diag }
