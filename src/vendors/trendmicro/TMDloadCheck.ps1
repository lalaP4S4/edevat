# ---------------------------------------------------------------------------
# TrendMicro Download Center - Next Gen (XPath-Free)
# Dinamik Link Takip ve İndirme Aracı (v1.0.1)
# ---------------------------------------------------------------------------

# Karakter kodlamasini ve Konsol ayarlarini UTF-8 olarak duzenle
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {}
$OutputEncoding = [System.Text.Encoding]::UTF8

# 0. Renkler ve Tema (Jewel Theme)
$COLOR_ZUMRUT = "DarkCyan"   # Koyu Zumrut Yesili
$COLOR_ELMAS = "White"      # Elmas Beyazi
$COLOR_ALTIN = "Yellow"     # Altin Sarisi
$COLOR_YAKUT = "Red"        # Yakut Kirmizisi
$COLOR_GRI = "Gray"       # Bilgi Satirlari

function Write-Color {
    param(
        [string]$Message,
        [string]$Color = $COLOR_ELMAS
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title)
    $w = 60
    $p = [math]::Max(0, [math]::Floor(($w - $Title.Length - 4) / 2))
    $pad = " " * $p
    
    Write-Color ("+" + ("=" * ($w - 2)) + "+") -Color $COLOR_ZUMRUT
    Write-Color ("| " + $pad + $Title + $pad + " |") -Color $COLOR_ELMAS
    Write-Color ("+" + ("=" * ($w - 2)) + "+") -Color $COLOR_ZUMRUT
}

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
    Start-Sleep -Seconds 1
}

# 1. Yapilandirma ve Global Degiskenler
$global:ActiveDownloads = @()
$global:DownloadHistory = @()
$products = @{
    "1" = @{ Name = "Apex One"; ProdId = "1745" }
    "2" = @{ Name = "Apex Central"; ProdId = "1746" }
}

# 2. Bagimlilik ve Onbellek Yonetimi
function Initialize-HtmlAgilityPack {
    $cacheDir = Join-Path $env:LOCALAPPDATA "TrendMicroUpdateCheck"
    $dllPath = Join-Path $cacheDir "HtmlAgilityPack.dll"

    if (Test-Path $dllPath) {
        try {
            Add-Type -Path $dllPath -ErrorAction Stop
            return $cacheDir
        }
        catch {
            Write-Color "Önbellekteki DLL yüklenemedi, yeniden denenecek." -Color $COLOR_ALTIN
        }
    }

    $tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) "HAP_$(Get-Date -Format 'HHmmss')"
    if (-not (Test-Path $cacheDir)) { New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null }
    New-Item -ItemType Directory -Path $tempFolder | Out-Null

    try {
        Write-Color "HtmlAgilityPack indiriliyor..." -Color $COLOR_ALTIN
        $nugetUrl = "https://www.nuget.org/api/v2/package/HtmlAgilityPack/1.11.53"
        Invoke-WebRequest -Uri $nugetUrl -OutFile (Join-Path $tempFolder "pkg.zip") -ErrorAction Stop
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $tempFolder "pkg.zip"), $tempFolder)
        
        $found = Get-ChildItem -Path $tempFolder -Recurse -Filter "HtmlAgilityPack.dll" | Select-Object -First 1
        if ($found) {
            Copy-Item $found.FullName $dllPath -Force
            Add-Type -Path $dllPath
            Write-Color "Bağımlılık başarıyla yüklendi." -Color $COLOR_ZUMRUT
            return $cacheDir
        }
    }
    catch {
        Write-Color "Hata: $_" -Color $COLOR_YAKUT
    }
    finally {
        if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force -ErrorAction SilentlyContinue }
    }
    return $null
}

function Clear-AppCache {
    $cacheDir = Join-Path $env:LOCALAPPDATA "TrendMicroUpdateCheck"
    if (Test-Path $cacheDir) {
        Remove-Item $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Color "Uygulama önbelleği temizlendi." -Color $COLOR_ZUMRUT
    }
    else {
        Write-Color "Temizlenecek önbellek bulunamadı." -Color $COLOR_GRI
    }
}

# 3. Ayrirma ve Veri Cekme
function Get-TMPackageInfo {
    param([string]$Text, [string]$Type = "Main")
    $res = @{ Filename = "Bulunamadi"; SHA256 = "Bulunamadi" }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $res }

    if ($Type -eq "Main") {
        if ($Text -match '(?i)(?:Filename:\s*)?(\S+\.(?:exe|msi|zip|bin))') { $res.Filename = $matches[1] }
        if ($Text -match '([A-Fa-f0-9]{64})') { $res.SHA256 = $matches[0] }
    }
    else {
        if ($Text -match '(?i)Filename:\s*(\S+)') { $res.Filename = $matches[1] }
        if ($Text -match '(?i)SHA256(?: checksum)?:\s*([A-Fa-f0-9]{64})') { $res.SHA256 = $matches[1] }
    }
    return $res
}

function Get-SafeNodeValue {
    param($Doc, $XPath, $FallbackText = "")
    if ($null -eq $Doc) { return $FallbackText }
    $node = $Doc.DocumentNode.SelectSingleNode($XPath)
    if ($node) {
        return $node.InnerText.Trim()
    }
    return $FallbackText
}

# 3. Ayrıştırma ve Veri Çekme
function Get-TMPackageInfo {
    param([string]$Text, [string]$Type = "Main")
    $res = @{ Filename = "Bulunamadı"; SHA256 = "Bulunamadı" }
    if ([string]::IsNullOrWhiteSpace($Text)) { return $res }

    if ($Type -eq "Main") {
        if ($Text -match '(?i)(?:Filename:\s*)?(\S+\.(?:exe|msi|zip|bin))') { $res.Filename = $matches[1] }
        if ($Text -match '([A-Fa-f0-9]{64})') { $res.SHA256 = $matches[0] }
    }
    else {
        if ($Text -match '(?i)Filename:\s*(\S+)') { $res.Filename = $matches[1] }
        if ($Text -match '(?i)SHA256(?: checksum)?:\s*([A-Fa-f0-9]{64})') { $res.SHA256 = $matches[1] }
    }
    return $res
}

function Get-ProductInfo {
    param([hashtable]$Product, [bool]$Silent = $false)
    if (-not $Silent) { Write-Header "BILGILER ALINIYOR: $($Product.Name)" }
    
    $cache = Initialize-HtmlAgilityPack
    if ($null -eq $cache) { return $null }

    try {
        $url = "https://downloadcenter.trendmicro.com/index.php?regs=tr&prodid=$($Product.ProdId)"
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
        $doc = New-Object HtmlAgilityPack.HtmlDocument
        $doc.LoadHtml($resp.Content)

        $results = @{}
        
        # Dinamik Tablo Bulma (XPath Bağımlılığından Kurtulma)
        # Sitedeki 'all_content_table' veya 'file_results' class'ına sahip tabloları alıyoruz.
        $tables = $doc.DocumentNode.SelectNodes("//table[contains(@class, 'file_results') or contains(@class, 'all_content_table')]")
        
        if ($null -eq $tables -or $tables.Count -lt 1) {
            # Son çare: İçinde 'file_link' barındıran tabloları ara
            $tables = $doc.DocumentNode.SelectNodes("//table[.//a[contains(@class, 'file_link')]]")
        }

        if ($null -eq $tables -or $tables.Count -lt 1) {
            Write-Color "Hata: Indirme tablolari bulunamadi." -Color $COLOR_YAKUT
            return $null
        }

        # Tablo Indeksleri: 0 -> Full Version/Service Pack, 1 -> Hotfix/Patch (Genellikle)
        $sectionMap = @{ "Main" = 0; "Hotfix" = 1 }

        foreach ($type in $sectionMap.Keys) {
            $idx = $sectionMap[$type]
            if ($idx -ge $tables.Count) { continue }
            
            $table = $tables[$idx]
            # İlk satırdan link ve tarih bilgisini al
            $firstRow = $table.SelectSingleNode(".//tr[1]")
            $linkNode = $firstRow.SelectSingleNode(".//a[contains(@class, 'file_link')]")
            $dateNode = $firstRow.SelectSingleNode(".//td[2]")
            
            # İkinci satırdan (detay satırı) SHA256 ve Filename bilgisini al
            $detailRow = $table.SelectSingleNode(".//tr[2]")
            $detailText = if ($detailRow) { $detailRow.InnerText.Trim() } else { $table.InnerText }

            $info = Get-TMPackageInfo -Text $detailText -Type $type
            
            $link = ""
            if ($linkNode) { $link = $linkNode.GetAttributeValue("href", "").Trim() }
            if ($link -and $link -notmatch "^https?://") { $link = "https://downloadcenter.trendmicro.com" + $link }
            
            $info.DownloadLink = $link
            $info.ReleaseDate = if ($dateNode) { $dateNode.InnerText.Trim() } else { "Bilinmiyor" }
            $results[$type] = $info
        }

        if (-not $Silent) {
            Clear-Host
            Write-Header "GUNCEL BILGILER: $($Product.Name)"
            foreach ($type in @("Main", "Hotfix")) {
                $p = $results[$type]
                if ($null -eq $p) { continue }
                Write-Color "`n[$type] $($Product.Name)" -Color $COLOR_ALTIN
                Write-Color "  Dosya: $($p.Filename)"
                Write-Color "  SHA256: $($p.SHA256)"
                Write-Color "  Tarih: $($p.ReleaseDate)"
                Write-Color "  Link: $($p.DownloadLink)" -Color $COLOR_GRI
            }
        }
        return $results
    }
    catch {
        Write-Color "Bilgi çekme hatası: $_" -Color $COLOR_YAKUT
        return $null
    }
}

# 4. Indirme ve Dosya Islemleri
function Confirm-FileOverwrite {
    param([string]$FilePath)
    if (Test-Path $FilePath) {
        $f = Get-Item $FilePath
        Write-Color "UYARI: Dosya zaten mevcut: $($f.Name)" -Color $COLOR_YAKUT
        Write-Color "Boyut: $([math]::Round($f.Length/1MB,2)) MB - Tarih: $($f.LastWriteTime)" -Color $COLOR_GRI
        $c = Read-Host "Uzerine yazilsin mi? [E/H]"
        if ($c -ne "E" -and $c -ne "e") {
            $dir = Split-Path $FilePath -Parent
            $name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
            $ext = [System.IO.Path]::GetExtension($FilePath)
            return Join-Path $dir "$($name)_$(Get-Date -Format 'HHmmss')$ext"
        }
    }
    return $FilePath
}

function Start-BackgroundDownload {
    param($Url, $OutputPath, $Description, $ProductName)
    $finalPath = Confirm-FileOverwrite -FilePath $OutputPath
    $script = {
        param($u, $o, $d, $p)
        try {
            $start = Get-Date
            Invoke-WebRequest -Uri $u -OutFile $o -ErrorAction Stop
            return @{ Success = $true; Path = $o; Size = (Get-Item $o).Length / 1MB; Time = (Get-Date) - $start; Desc = $d; Prod = $p; End = Get-Date }
        }
        catch { return @{ Success = $false; Error = $_.Exception.Message; Desc = $d; Prod = $p } }
    }
    $job = Start-Job -ScriptBlock $script -ArgumentList $Url, $finalPath, $Description, $ProductName
    $global:ActiveDownloads += @{ Job = $job; Desc = $Description; Prod = $ProductName; Start = Get-Date }
    Write-Color "Indirme arka planda baslatildi (ID: $($job.Id))" -Color $COLOR_ZUMRUT
}

# 5. UI ve Menuler
function Show-Status {
    if ($global:ActiveDownloads.Count -eq 0) { Write-Color "Aktif indirme yok." -Color $COLOR_GRI; return }
    Write-Header "INDIRME DURUMU"
    $toRemove = @()
    for ($i = 0; $i -lt $global:ActiveDownloads.Count; $i++) {
        $d = $global:ActiveDownloads[$i]; $j = $d.Job
        Write-Color "$($i+1). $($d.Prod) - $($d.Desc) ($($j.State))" -Color $COLOR_ALTIN
        if ($j.State -eq "Completed") {
            $res = Receive-Job -Job $j
            if ($res.Success) {
                Write-Color "   Tamamlandi: $($res.Size)MB, Sure: $($res.Time.ToString('mm\:ss'))" -Color $COLOR_ZUMRUT
                $global:DownloadHistory += $res
            }
            else { Write-Color "   Hata: $($res.Error)" -Color $COLOR_YAKUT }
            $toRemove += $i
        }
    }
    foreach ($idx in ($toRemove | Sort-Object -Descending)) {
        $global:ActiveDownloads[$idx].Job | Remove-Job -Force
        $global:ActiveDownloads = $global:ActiveDownloads | Where-Object { $_ -ne $global:ActiveDownloads[$idx] }
    }
}

function Select-Folder {
    param($Prod)
    Show-Banner
    Write-Header "KLASOR SECIMI: $Prod"
    Write-Color " 1. Masaustu"
    Write-Color " 2. Indirilenler"
    Write-Color " 3. Mevcut Dizin"
    Write-Color " 4. Ozel Yol Belirt"
    $s = Read-Host "`nSeciminiz [1-4]"
    $base = switch ($s) {
        "1" { [Environment]::GetFolderPath("Desktop") }
        "2" { Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads" }
        "4" { Read-Host "Tam Klasör Yolunu Girin" }
        default { Get-Location }
    }
    $path = Join-Path $base "TrendMicro\$Prod"
    if (-not (Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
    return $path
}

function Wait-ForKeyPress {
    param([string]$Message = "Devam etmek icin bir tusa basin...")
    Write-Color "`n$Message" -Color $COLOR_GRI
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "(Enter tusuna basin)" -ForegroundColor $COLOR_GRI
        $null = Read-Host
    }
}

function Start-MainLoop {
    while ($true) {
        Show-Banner
        Write-Header "ANA MENU"
        Write-Color " [1] Urun Sorgula & Indirme Baslat" -Color $COLOR_ELMAS
        Write-Color " [2] Indirme Durumlarini Goruntule"
        Write-Color " [3] Indirme Gecmisi (History)"
        Write-Color " [4] Uygulama Onbellegini Temizle"
        Write-Color " [5] Guvenli Cikis" -Color $COLOR_YAKUT
        
        $m = Read-Host "`nSeciminiz"
        switch ($m) {
            "1" {
                Show-Banner
                Write-Header "URUN SECIMI"
                Write-Color " 1. Apex One"
                Write-Color " 2. Apex Central"
                Write-Color " 3. Ana Menuye Don"
                $selection = Read-Host "`nUrun Numarasi"
                if ($selection -match "[12]") {
                    $prod = $products[$selection]
                    $infos = Get-ProductInfo -Product $prod
                    if ($null -ne $infos) {
                        $ask = Read-Host "`nIndirme islemi baslatilsin mi? [E/H]"
                        if ($ask -eq "E" -or $ask -eq "e") {
                            $folder = Select-Folder -Prod $prod.Name
                            Show-Banner
                            Write-Header "PAKET SECIMI"
                            Write-Color " 1. Ana Paket (Full/SP)"
                            Write-Color " 2. Yama/Hotfix"
                            Write-Color " 3. Her Ikisi"
                            $target = Read-Host "`nIndirilecek Paket"
                            if ($target -in "1", "3") { Start-BackgroundDownload -Url $infos.Main.DownloadLink -OutputPath (Join-Path $folder $infos.Main.Filename) -Description "Ana Paket" -ProductName $prod.Name }
                            if ($target -in "2", "3") { Start-BackgroundDownload -Url $infos.Hotfix.DownloadLink -OutputPath (Join-Path $folder $infos.Hotfix.Filename) -Description "Hotfix" -ProductName $prod.Name }
                        }
                    }
                    Wait-ForKeyPress
                }
            }
            "2" { Show-Banner; Show-Status; Wait-ForKeyPress }
            "3" {
                Show-Banner
                Write-Header "INDIRME GECMISI"
                if ($global:DownloadHistory.Count -eq 0) { Write-Color "Gecmis kaydi bulunamadi." -Color $COLOR_GRI }
                foreach ($h in $global:DownloadHistory) { Write-Color " • $($h.Prod) - $($h.Desc) ($([math]::Round($h.Size,2)) MB)" -Color $COLOR_ZUMRUT }
                Wait-ForKeyPress
            }
            "4" { Clear-AppCache; Wait-ForKeyPress }
            "5" { 
                if ($global:ActiveDownloads.Count -gt 0) { 
                    $c = Read-Host "Aktif indirmeler var. Cikilsin mi? [E/H]"
                    if ($c -ne "E" -and $c -ne "e") { return } 
                } 
                return 
            }
        }
    }
}

# Betigi baslat
Start-MainLoop

Write-Host "`n*Gayret bizden, tevfik Allah'tandir. | dad-u-bab*"
