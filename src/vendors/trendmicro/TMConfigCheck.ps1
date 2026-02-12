<#
.SYNOPSIS
    Trend Micro Apex One & Central INI Ayar Güncelleyici (v3.1.0 - Consolidated)

.DESCRIPTION
    Bu betik, Trend Micro yapılandırma dosyalarını (ofcscan.ini, ofcserver.ini) 
    güvenli, idempotent ve toplu (batch) bir şekilde günceller.

    v3.1.0 Yenilikleri:
    - Konsolidasyon: v1, v2 ve v3 sürümleri bu ana dosyada birleştirildi.
    - Tüm Seçenekler: USB Logging, Purge Bildirimleri, Global Optimizasyonlar.
    - Banner Düzeltmesi: Ayet referanslarının (Necm; 39 vb.) tam gösterimi.
    - Atomik Güncelleme & Saniye bazlı yedekleme.
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

# Version: v3.1.0
# Author: bab-ı kod

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

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Color
}

function Invoke-Update {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Updates
    )

    if (-not (Test-Path $FilePath)) {
        Write-Log "HATA: Dosya bulunamadı: $FilePath" -Color Red
        return
    }

    # 1. Yedek Al
    if (-not $NoBackup) {
        $backupPath = "$FilePath-$(Get-Date -Format 'yyyyMMdd_HHmmss').bak"
        Copy-Item -Path $FilePath -Destination $backupPath -Force
        Write-Log "Yedek alındı: $backupPath" -Color Cyan
    }

    # 2. İçeriği Oku (BOM tespiti için PS varsayılanını kullan)
    $content = @(Get-Content -Path $FilePath)
    $modified = $false

    foreach ($update in $Updates) {
        $targetSection = $update.Section
        $targetKey = $update.Key
        $targetValue = $update.Value
        
        Write-Log "İşleniyor: [$targetSection] -> $targetKey=$targetValue" -Color Gray

        # 3. Bab (Section) Tespiti - Daha esnek matching
        $sectionIndex = -1
        $escSection = [regex]::Escape($targetSection)
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "^\s*\[\s*$escSection\s*\]") {
                $sectionIndex = $i
                break
            }
        }

        if ($sectionIndex -eq -1) {
            Write-Log "UYARI: [$targetSection] Bab'ı bulunamadı. Ekleniyor." -Color Yellow
            $content += ""
            $content += "[$targetSection]"
            $content += "$targetKey=$targetValue"
            $modified = $true
        }
        else {
            # Bab bulundu, anahtar kontrolü
            $keyFound = $false
            $insertIdx = $sectionIndex + 1
            $escKey = [regex]::Escape($targetKey)
            
            # Sonraki Bab'a veya dosya sonuna kadar ara
            for ($i = $sectionIndex + 1; $i -lt $content.Count; $i++) {
                $line = $content[$i].Trim()
                if ($line -match "^\s*\[") { break } # Yeni bölüm başladı
                
                if ($line -match "^\s*$escKey\s*=") {
                    # Mevcut değeri kontrol et
                    if ($line -eq "$targetKey=$targetValue" -and -not $Force) {
                        Write-Log "Değişiklik gerekmiyor: $targetKey zaten $targetValue" -Color Gray
                        $keyFound = $true
                        break
                    }
                    $content[$i] = "$targetKey=$targetValue"
                    $keyFound = $true
                    $modified = $true
                    Write-Log "Güncellendi: $targetKey=$targetValue" -Color Green
                    break
                }
                if ($line -ne "") { $insertIdx = $i + 1 }
            }

            if (-not $keyFound) {
                # Anahtar bulunamadı, bölüm sonuna veya altına ekle
                $head = $content[0..($insertIdx - 1)]
                $tail = if ($insertIdx -lt $content.Count) { $content[$insertIdx..($content.Count - 1)] } else { @() }
                $content = $head + "$targetKey=$targetValue" + $tail
                $modified = $true
                Write-Log "Eklendi: $targetKey=$targetValue" -Color Green
            }
        }
    }

    # 4. Kaydet
    if ($modified) {
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
        $finalContent | Set-Content -Path $FilePath -Encoding UTF8
        Write-Log "Dosya başarıyla güncellendi: $FilePath" -Color Cyan
    }
    else {
        Write-Log "Dosyada değişiklik yapılmasına gerek duyulmadı." -Color Green
    }
}

function Start-InteractiveConfig {
    Show-MebadiBanner
    Write-Host "`n=== INI GÜNCELLEME İNTERAKTİF MENÜ (v3.1) ===" -ForegroundColor Cyan
    Write-Host "Yapılacak ayarı seçiniz:"
    Write-Host "1. USB Logging Etkinleştir (ofcscan.ini)"
    Write-Host "2. Client Unload Etkinleştir (ofcserver.ini)"
    Write-Host "3. Inactive Agent Purge FULL Bildirimleri (ofcscan.ini)"
    Write-Host "4. Global Güvenlik & Optimizasyon Ayarları (ofcscan.ini)"
    Write-Host "Q. Çıkış"

    $c = Read-Host "`nSeçiminiz"
    switch ($c) {
        "1" {
            $updates = @([PSCustomObject]@{ Section = "Global Setting"; Key = "EnableUsbLogging"; Value = "1" })
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\ofcscan.ini" -Updates $updates
        }
        "2" {
            $updates = @([PSCustomObject]@{ Section = "SERVER_CONSOLE_SECTION"; Key = "EnableClientUnload"; Value = "1" })
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\Private\ofcserver.ini" -Updates $updates
        }
        "3" {
            $section = "INI_STANDARD_ALERT_CLIENT_PURGE_SECTION"
            $msg = "Inactive Agent Purged\nPurged Endpoint: %COMPUTER%\nIP Address: %IP%\nGUID: %GUID%\nDomain: %DOMAIN%\nInactive Since: %DATETIME%\n"
            $updates = @(
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_Enable_SMTP"; Value = "1" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_Enable_SMTP_RBA"; Value = "1" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_SMTP_Send_To"; Value = "test@trendmicro.com" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_SMTP_Subject"; Value = "Inactive Agent Purged" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_SMTP_Message"; Value = "Purged Endpoint: %COMPUTER%\nIP Address: %IP%\nGUID: %GUID%\nDomain: %DOMAIN%\nInactive Since: %DATETIME%\n" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_Enable_NTEvent"; Value = "1" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_NTEvent_Message"; Value = $msg },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_Enable_SNMP"; Value = "1" },
                [PSCustomObject]@{ Section = $section; Key = "Std_Alert_SNMP_Message"; Value = $msg }
            )
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\ofcscan.ini" -Updates $updates
        }
        "4" {
            $section = "Global Setting"
            $updates = @(
                [PSCustomObject]@{ Section = $section; Key = "VsapiNtkdControlFlag"; Value = "04,00" },
                [PSCustomObject]@{ Section = $section; Key = "ENABLE_APPROVEDLIST_HASH_WITH_IMP_EXP"; Value = "1" },
                [PSCustomObject]@{ Section = $section; Key = "WatchDogSPLog"; Value = "0" },
                [PSCustomObject]@{ Section = $section; Key = "AcceptXBC"; Value = "0" }
            )
            Invoke-Update -FilePath "C:\Program Files (x86)\Trend Micro\Apex One\PCCSRV\ofcscan.ini" -Updates $updates
        }
    }
}

if ($Interactive -or (-not $FilePath -and -not $Section)) {
    Start-InteractiveConfig
}
else {
    $updates = @([PSCustomObject]@{ Section = $Section; Key = $Key; Value = $Value })
    Invoke-Update -FilePath $FilePath -Updates $updates
}
