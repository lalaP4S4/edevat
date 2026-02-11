# --- bab-ı kod: Merkezi Yönetim Paneli ---
# Version: v1.0.0 [cite: 2026-02-04]
# Mahlas: dad-u-bab [cite: 2026-02-04]

function Show-MebadiBanner {
    Clear-Host
    Write-Host ("=" * 85) -ForegroundColor DarkYellow
    Write-Host (" " * 71) "  dad-u-bab  " -BackgroundColor DarkYellow -ForegroundColor Black
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
}

# Değişken Tanımları
$scriptPath = $PSScriptRoot
$colorDiamond = "White"

do {
    Show-Banner
    
    Write-Host " 1. Requirement & Diagnostic Check (TMReqCheck.ps1)" -ForegroundColor $colorDiamond
    Write-Host " 2. Download Center Manager (TMDloadCheck.ps1)" -ForegroundColor $colorDiamond
    Write-Host " 3. INI Configuration Context (TMConfigCheck.ps1)" -ForegroundColor $colorDiamond
    Write-Host " 4. Utility Tools & Metrics (TMCertCheck.ps1)" -ForegroundColor $colorDiamond
    Write-Host " Q. Çıkış" -ForegroundColor "Red"
    
    $secim = Read-Host "`n Seçiminiz"
    
    # Seçime Göre İşlem Başlatma (Dinamik bypass ile)
    if ($secim -eq "1") {
        Write-Host ">> Requirement Check başlatılıyor..." -ForegroundColor "Cyan"
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-NoExit", "-File `"$scriptPath\TMReqCheck.ps1`"" -Wait
    }
    elseif ($secim -eq "2") {
        Write-Host ">> Download Center Check başlatılıyor..." -ForegroundColor "Cyan"
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-NoExit", "-File `"$scriptPath\TMDloadCheck.ps1`"" -Wait
    }
    elseif ($secim -eq "3") {
        Write-Host ">> Config Check başlatılıyor..." -ForegroundColor "Cyan"
        # 3. Script ismini burada belirlediğin isme göre güncelleyebilirsin
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-NoExit", "-File `"$scriptPath\TMConfigCheck.ps1`"" -Wait
    }
    elseif ($secim -eq "4") {
        Write-Host ">> Utility Tools başlatılıyor..." -ForegroundColor "Cyan"
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-NoExit", "-File `"$scriptPath\TMCertCheck.ps1`"" -Wait
    }
    elseif ($secim -eq "q") {
        Write-Host "`n İyi çalışmalar dad-u-bab..." -ForegroundColor "DarkGreen"
        break
    }
    else {
        Write-Host "Geçersiz seçim, lütfen tekrar deneyin." -ForegroundColor "Red"
        Start-Sleep -Seconds 1
    }

} while ($secim -ne "q")