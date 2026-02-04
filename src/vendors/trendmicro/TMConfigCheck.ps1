<#
.SYNOPSIS
    Trend Micro Apex One & Central INI Ayar Güncelleyici (v1.0.1)

.DESCRIPTION
    Bu betik, Trend Micro yapılandırma dosyalarını (ofcscan.ini, ofcserver.ini) 
    güvenli ve idempotent (tekrar uygulanabilir) bir şekilde günceller.

    Sürüm: v1.0.1
    Tarih: 2026-01-28

    Özellikler:
    - Otomatik Yedekleme: Her değişiklikten önce .bak veya -yedek.ini uzantısıyla yedek alır.
    - Bab Bazlı Güncelleme: Belirtilen [SECTION] altına anahtar-değer çifti ekler veya günceller.
    - Format Koruması: Gereksiz boş satırları temizler ve dosya bütünlüğünü korur.
    - İnteraktif Mod: Parametre girmeden menü üzerinden ayar seçimi.
    - UTF-8 Desteği.

.AUTHOR
    dad-u-bab

.NOTES
    YASAL UYARI: Bu betik henüz tam teşekküllü test edilmemiştir. Sorumluluk kullanıcıya aittir.
    DISCLAIMER: This script is not fully tested. Use at your own risk.

.EXAMPLE
    # ofcscan.ini'de Global Setting altına ayar ekle
    .\A1ConfigUpdater.ps1 -FilePath "C:\ofcscan\ofcscan.ini" -Section "Global Setting" -Key "EnableUsbLogging" -Value "1"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$Section,

    [Parameter(Mandatory = $false)]
    [string]$Key,

    [Parameter(Mandatory = $false)]
    [string]$Value,

    [switch]$Force,
    [switch]$NoBackup,
    [switch]$Interactive
)

# Version: v1.1.0
# Author: dad-u-bab

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
        "7,İnzibat,Şüphesiz güçlükle beraber bir kolaylık vardır.,İnşirah, 5",
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

Show-MebadiBanner
Start-Sleep -Seconds 2

# --- Fonksiyonlar ---
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Invoke-Update {
    if (-not (Test-Path $FilePath)) {
        Write-Log "HATA: Dosya bulunamadı: $FilePath" -Color Red
        return
    }

    # 1. Yedek Al
    if (-not $NoBackup) {
        $backupPath = "$FilePath-$(Get-Date -Format 'yyyyMMdd_HHmm').bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Log "Yedek alındı: $backupPath" -Color Cyan
    }

    # 2. İçeriği Oku
    $content = Get-Content -Path $FilePath -Encoding UTF8
    $sectionHeader = "[$Section]"

    # 3. Bab Kontrolü
    $sectionIndex = ($content | Select-String -Pattern "^\s*\Q$sectionHeader\E" -SimpleMatch).LineNumber
    if (-not $sectionIndex) {
        Write-Log "UYARI: [$Section] Bab'ı bulunamadı. Dosya sonuna ekleniyor." -Color Yellow
        $content += ""
        $content += $sectionHeader
        $content += "$Key=$Value"
    }
    else {
        # Bab bulundu, anahtar kontrolü
        $startIdx = $sectionIndex # Select-String LineNumber 1-based, index is 0-based but we want AFTER header
        
        # Sonraki Bab'ı bul
        $nextSection = $content | Select-String -Pattern "^\s*\[" | Where-Object { $_.LineNumber -gt $sectionIndex } | Select-Object -First 1
        $endIdx = if ($nextSection) { $nextSection.LineNumber - 2 } else { $content.Count - 1 }

        $keyFound = $false
        for ($i = $startIdx; $i -le $endIdx; $i++) {
            if ($content[$i] -match "^\s*\Q$Key\E\s*=") {
                # Eskisiyle aynı mı?
                if ($content[$i] -eq "$Key=$Value" -and -not $Force) {
                    Write-Log "Ayar zaten mevcut ve değer aynı: $Key=$Value. Değişiklik yapılmadı." -Color Green
                    return
                }
                $content[$i] = "$Key=$Value"
                $keyFound = $true
                Write-Log "Ayar güncellendi: $Key=$Value" -Color Green
                break
            }
        }

        if (-not $keyFound) {
            # Anahtar bulunamadı, Bab'ın hemen altına ekle
            $newContent = $content[0..($startIdx - 1)] + "$Key=$Value" + $content[$startIdx..($content.Count - 1)]
            $content = $newContent
            Write-Log "Yeni ayar eklendi: $Key=$Value" -Color Green
        }
    }

    # 4. Format Temizliği (Ardışık boş satırları birleştir)
    # Not: Basit bir yöntem kullanıyoruz
    $finalContent = @()
    $prevEmpty = $false
    foreach ($line in $content) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            if (-not $prevEmpty) { $finalContent += ""; $prevEmpty = $true }
        }
        else {
            $finalContent += $line.Trim()
            $prevEmpty = $false
        }
    }

    # 5. Kaydet
    $finalContent | Set-Content -Path $FilePath -Encoding UTF8
    Write-Log "Dosya başarıyla kaydedildi: $FilePath" -Color Green
}

# --- İnceleme & İnteraktif Mod ---
function Start-InteractiveConfig {
    Write-Host "`n=== INI GÜNCELLEME İNTERAKTİF MENÜ ===" -ForegroundColor Cyan
    Write-Host "Yapılacak ayarı seçiniz:"
    Write-Host "1. USB Logging Etkinleştir (ofcscan.ini)"
    Write-Host "2. Client Unload Etkinleştir (ofcserver.ini)"
    Write-Host "3. Inactive Agent Purge Bildirimleri (ofcscan.ini)"
    Write-Host "Q. Çıkış"

    $c = Read-Host "`nSeçiminiz"
    switch ($c) {
        "1" {
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\ofcscan.ini" -Section "Global Setting" -Key "EnableUsbLogging" -Value "1"
            break
        }
        "2" {
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\Private\ofcserver.ini" -Section "SERVER_CONSOLE_SECTION" -Key "EnableClientUnload" -Value "1"
            break
        }
        "3" {
            $path = "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\ofcscan.ini"
            Invoke-Update -FilePath $path -Section "INI_STANDARD_ALERT_CLIENT_PURGE_SECTION" -Key "Std_Alert_Enable_SMTP" -Value "1"
            Invoke-Update -FilePath $path -Section "INI_STANDARD_ALERT_CLIENT_PURGE_SECTION" -Key "Std_Alert_SMTP_Subject" -Value "Inactive Agent Purged"
            break
        }
    }
}

# --- Çalıştır ---
if ($Interactive -or (-not $FilePath -and -not $Section)) {
    Start-InteractiveConfig
}
else {
    Invoke-Update
}
