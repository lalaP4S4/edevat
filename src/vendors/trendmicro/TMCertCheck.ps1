# Sürüm: v1.1.0
# Mahlas: dad-u-bab (2026-02-04)

function Show-MebadiBanner {
    # v1.0.0 - Mebadi-i Aşere Banner (Besmele Eklenmiş)
    $ESC = [char]27
    $BG_GOLD = "$ESC[48;5;214m"
    $FG_EMERALD = "$ESC[38;5;29m"
    $FG_DIAMOND = "$ESC[38;5;15m"
    $RESET = "$ESC[0m"

    Clear-Host

    # Başlık (Altın üzerine Zümrüt)
    Write-Host "$BG_GOLD$FG_EMERALD  MEBÂDİ-İ AŞERE | dad-u-bab  $RESET"
    Write-Host "$FG_EMERALD$(New-Object System.String '=', 85)$RESET"

    # Besmele-i Şerif
    Write-Host (" " * 25) "$FG_DIAMOND Bismillahirrahmanirrahim $RESET"
    Write-Host "$FG_EMERALD$(New-Object System.String '-', 85)$RESET"

    $Lines = @(
        "1,Niyet,İnsan için ancak çalıştığının karşılığı vardır.,Necm, 39",
        "2,İstikamet,Öyleyse emrolunduğun gibi dosdoğru ol.,Hûd, 112",
        "3,Kâtiplik,O, kalemle (yazmayı) öğretendir.,Alak, 4",
        "4,Zerafet,İnsanlara güzel söz söyleyin.,Bakara, 83",
        "5,Basiret,De ki: Hiç bilenlerle bilmeyenler bir olur mu?,Zümer, 9",
        "6,İlim,...Rabbim! Benim ilmimi artır, de.,Tâhâ, 114",
        "7,İnzibat,Şüphesiz güçlükle beraber bir kolaylık vardır.,Inşirah, 5",
        "8,İstişare,...İş hususunda onlarla müşavere et.,Âl-i İmrân, 159",
        "9,Kanaat,...Yiyin, için fakat israf etmeyin.,A'râf, 31",
        "10,Miras,Emanetlerine ve ahidlerine riayet ederler.,Mü'minûn, 8"
    )

    foreach ($L in $Lines) {
        $c = $L.Split(',')
        $row = "{0,-2} | {1,-10} | {2,-50} | {3}" -f $c[0], $c[1], $c[2], $c[3]
        Write-Host "$FG_DIAMOND$row$RESET"
    }
    Write-Host "$FG_EMERALD$(New-Object System.String '=', 85)$RESET"
}

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

# --- Menü (Opsiyonel) ---
function Show-A1ToolsMenu {
    Show-MebadiBanner
    Write-Host "=== APEX ONE TOOLS & UTILS (v1.1.0) ===" -ForegroundColor Cyan
    Write-Host "  MAHLAS : dad-u-bab" -ForegroundColor White
    Write-Host " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
    Write-Host "1. SQL Bilgilerini Göster"
    Write-Host "2. Ajan Versiyonunu Sorgula"
    Write-Host "3. Sertifika Doğrulaması (FCC)"
    Write-Host "4. Log Hatalarını Tara"
    Write-Host "Q. Çıkış"

    $choice = Read-Host "`nSeçiminiz"
    switch ($choice) {
        "1" { $s = Get-A1SQLInfo; if ($s) { $s | Format-Table }; break }
        "2" { Write-Host "Versiyon: $(Get-A1AgentVersion)"; break }
        "3" { Test-A1Certificates; break }
        "4" { Export-A1LogErrors; break }
    }
    if ($choice -ne "q") { Read-Host "Devam..."; Show-A1ToolsMenu }
}

if ($MyInvocation.InvocationName -ne '.') { Show-A1ToolsMenu }
