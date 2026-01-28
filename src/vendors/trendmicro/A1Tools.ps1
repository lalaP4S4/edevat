<#
.SYNOPSIS
    Trend Micro Apex One & Central Yardımcı Araçlar Kütüphanesi (v1.0.1)

.DESCRIPTION
    Bu modül/script, Apex One ve Central yönetimi için kritik yardımcı fonksiyonları içerir.

    Sürüm: v1.0.1
    Tarih: 2026-01-28

.AUTHOR
    dad-u-bab

.NOTES
    YASAL UYARI: Bu betik henüz tam teşekküllü test edilmemiştir. Sorumluluk kullanıcıya aittir.
    DISCLAIMER: This script is not fully tested. Use at your own risk.
#>

# --- 1. SQL Bilgilerini Al ---
function Get-A1SQLInfo {
    <# Retrieves SQL server and DB details from registry #>
    $regPath = "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\TVCS"
    try {
        $regValues = Get-ItemProperty -Path $regPath -ErrorAction Stop
        return @{
            SQLServer = $regValues.SQLServer
            DBName    = $regValues.DBName
        }
    }
    catch {
        Write-Warning "SQL Registry bilgisi bulunamadı: $regPath"
        return $null
    }
}

# --- 2. Ajan Versiyonunu Kontrol Et ---
function Get-A1AgentVersion {
    $path = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ApexOneNT"
    try {
        return (Get-ItemProperty -Path $path -Name DisplayVersion -ErrorAction Stop).DisplayVersion
    }
    catch {
        return "Bulunamadı"
    }
}

# --- 3. Sertifika Kontrolü (Post-Install) ---
function Test-A1Certificates {
    $ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne "127.0.0.1" -and $_.InterfaceAlias -like "Ethernet*" } | Select-Object -First 1 -ExpandProperty IPAddress)
    if (-not $ipAddress) { Write-Warning "IP adresi tespit edilemedi."; return }

    Write-Host "`n[ Sertifika Kontrolleri (IP: $ipAddress) ]" -ForegroundColor Cyan
    
    # Personal Store
    $pCert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*${ipAddress}*" }
    Write-Host "  Personal Store (${ipAddress}): $(if($pCert){'PASS'}else{'FAIL'})" -ForegroundColor $(if ($pCert) { 'Green' }else { 'Red' })

    # Trusted People
    $tpIP = Get-ChildItem Cert:\LocalMachine\TrustedPeople | Where-Object { $_.Subject -like "*${ipAddress}*" }
    Write-Host "  Trusted People (${ipAddress}): $(if($tpIP){'PASS'}else{'FAIL'})" -ForegroundColor $(if ($tpIP) { 'Green' }else { 'Red' })

    $tpOSF = Get-ChildItem Cert:\LocalMachine\TrustedPeople | Where-Object { $_.Subject -like "*OfcOSFWebApp*" }
    Write-Host "  Trusted People (OfcOSFWebApp): $(if($tpOSF){'PASS'}else{'FAIL'})" -ForegroundColor $(if ($tpOSF) { 'Green' }else { 'Red' })
}

# --- 4. Log Hatalarını Ayıkla ---
function Export-A1LogErrors {
    param([string]$OutputDir = "C:\A1\LogErr")
    $logs = @(
        "C:\Windows\OFCMAS.log",
        "C:\Windows\OFCSVR.log",
        "C:\TMPatch.log"
    )
    if (-not (Test-Path $OutputDir)) { New-Item $OutputDir -ItemType Directory -Force | Out-Null }

    foreach ($log in $logs) {
        if (Test-Path $log) {
            $outFile = Join-Path $OutputDir ("$(Split-Path $log -Leaf)-err.txt")
            $foundMatches = Select-String -Path $log -Pattern "error|fail|warning"
            if ($foundMatches) {
                $foundMatches | ForEach-Object { $_.Line } | Set-Content $outFile
                Write-Host "Bulunan hatalar kaydedildi: $outFile" -ForegroundColor Yellow
            }
            else {
                Write-Host "Hata bulunamadı: $log" -ForegroundColor Green
            }
        }
    }
}

# --- 5. IPv4 Precedence Fix ---
function Set-A1IPv4Precedence {
    Write-Host "IPv4 önceliği registry üzerinden 0x20 olarak ayarlanıyor..." -ForegroundColor Yellow
    try {
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
        Set-ItemProperty -Path $regPath -Name "DisabledComponents" -Value 0x20 -Type DWord -Force
        Write-Host "✓ Başarılı. Değişiklik için reboot gereklidir." -ForegroundColor Green
    }
    catch {
        Write-Error "Registry hatası: $($_.Exception.Message)"
    }
}

# --- Menü (Opsiyonel) ---
function Show-A1ToolsMenu {
    Clear-Host
    Write-Host "=== APEX ONE TOOLS & UTILS ===" -ForegroundColor Cyan
    Write-Host "1. SQL Bilgilerini Göster"
    Write-Host "2. Ajan Versiyonunu Sorgula"
    Write-Host "3. Sertifika Doğrulaması (FCC)"
    Write-Host "4. Log Hatalarını Tara"
    Write-Host "5. IPv4 Önceliğini Ayarla (Reboot Gerekir)"
    Write-Host "Q. Çıkış"

    $choice = Read-Host "`nSeçiminiz"
    switch ($choice) {
        "1" { $s = Get-A1SQLInfo; if ($s) { $s | Format-Table }; break }
        "2" { Write-Host "Versiyon: $(Get-A1AgentVersion)"; break }
        "3" { Test-A1Certificates; break }
        "4" { Export-A1LogErrors; break }
        "5" { Set-A1IPv4Precedence; break }
    }
    if ($choice -ne "q") { Read-Host "Devam..."; Show-A1ToolsMenu }
}

if ($MyInvocation.InvocationName -ne '.') { Show-A1ToolsMenu }
