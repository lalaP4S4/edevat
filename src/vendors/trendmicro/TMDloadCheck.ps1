# ---------------------------------------------------------------------------
# Trend Micro Unified Download Tool (v2.0.0)
# Desteklenen Ürünler: Apex One, Apex Central, Deep Security Manager (LTS)
# Yazar: dad-u-bab
# ---------------------------------------------------------------------------

# Karakter kodlamasini ve Konsol ayarlarini UTF-8 olarak duzenle
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {}
$OutputEncoding = [System.Text.Encoding]::UTF8

# 0. Renkler ve Tema
$COLOR_ZUMRUT = "DarkCyan"
$COLOR_ELMAS = "White"
$COLOR_ALTIN = "Yellow"
$COLOR_YAKUT = "Red"
$COLOR_GRI = "Gray"

# 1. Yapilandirma ve Global Degiskenler
$global:ActiveDownloads = @()
$global:DownloadHistory = @()
$global:ApexProducts = @{
    "1" = @{ Name = "Apex One"; ProdId = "1745" }
    "2" = @{ Name = "Apex Central"; ProdId = "1746" }
}

# 2. Yardımcı Görsel Fonksiyonlar
function Write-Color {
    param([string]$Message, [string]$Color = $COLOR_ELMAS)
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

# 3. Bağımlılık ve Önbellek Yönetimi
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

# 4. Apex Veri Çekme (Scraping) Mantığı
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
        $tables = $doc.DocumentNode.SelectNodes("//table[contains(@class, 'file_results') or contains(@class, 'all_content_table')]")
        if ($null -eq $tables -or $tables.Count -lt 1) {
            $tables = $doc.DocumentNode.SelectNodes("//table[.//a[contains(@class, 'file_link')]]")
        }

        if ($null -eq $tables -or $tables.Count -lt 1) {
            Write-Color "Hata: Indirme tablolari bulunamadi." -Color $COLOR_YAKUT
            return $null
        }

        $sectionMap = @{ "Main" = 0; "Hotfix" = 1 }
        foreach ($type in $sectionMap.Keys) {
            $idx = $sectionMap[$type]
            if ($idx -ge $tables.Count) { continue }
            
            $table = $tables[$idx]
            $firstRow = $table.SelectSingleNode(".//tr[1]")
            $linkNode = $firstRow.SelectSingleNode(".//a[contains(@class, 'file_link')]")
            $dateNode = $firstRow.SelectSingleNode(".//td[2]")
            
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
            Show-MebadiBanner
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

# 5. Deep Security Veri Çekme (XML Parsing) Mantığı
function Get-DeepSecurityManagerInfo {
    param([string]$Platform) # "Linux" veya "Windows"
    
    $xmlUrl = "https://files.trendmicro.com/products/deepsecurity/en/DeepSecurityInventory_en.xml"
    Write-Color "`nEnvanter dosyası çekiliyor (LTS Sürümleri): $xmlUrl" -Color $COLOR_GRI
    
    try {
        $resp = Invoke-WebRequest -Uri $xmlUrl -UseBasicParsing -ErrorAction Stop
        [xml]$xml = $resp.Content
        
        $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $ns.AddNamespace("atom", "http://www.w3.org/2005/Atom")
        $ns.AddNamespace("ds", "http://www.trendmicro.com/ns/DeepSecurity/swmanifest/1.0")
        
        $xpath = "//atom:entry[ds:product='Manager' and ds:platform='$Platform' and ds:releaseType='LTS']"
        $entries = $xml.SelectNodes($xpath, $ns)
        
        if ($null -eq $entries -or $entries.Count -eq 0) {
            Write-Color "Hata: $Platform için uygun LTS Manager kaydı bulunamadı." -Color $COLOR_YAKUT
            return $null
        }

        $managerList = @()
        foreach ($entry in $entries) {
            $major = $entry.SelectSingleNode("ds:version/ds:major", $ns).InnerText
            $minor = $entry.SelectSingleNode("ds:version/ds:minor", $ns).InnerText
            $sp = $entry.SelectSingleNode("ds:version/ds:sp", $ns).InnerText
            $build = "$major.$minor.$sp"
            
            $filename = $entry.SelectSingleNode("ds:pkgInfo/@name", $ns).Value
            $md5 = $entry.SelectSingleNode("ds:pkgInfo/ds:md5", $ns).InnerText
            $sha256 = $entry.SelectSingleNode("ds:pkgInfo/ds:sha256", $ns).InnerText
            
            $absLink = $entry.SelectSingleNode("ds:download", $ns).InnerText
            if ([string]::IsNullOrWhiteSpace($absLink)) {
                $relLink = $entry.SelectSingleNode("atom:link[@rel='related']/@href", $ns).Value
                $baseUri = [System.Uri]$xmlUrl
                $absLink = [System.Uri]::new($baseUri, $relLink).AbsoluteUri
            }
            
            $updated = $entry.updated
            $managerList += [PSCustomObject]@{
                Filename = $filename
                Build    = $build
                MD5      = $md5
                SHA256   = $sha256
                Link     = $absLink
                Updated  = $updated
            }
        }
        
        return $managerList | Sort-Object Updated -Descending | Select-Object -First 10
    }
    catch {
        Write-Color "XML işleme hatası: $_" -Color $COLOR_YAKUT
        return $null
    }
}

# 6. Ortak İndirme ve Klasör İşlemleri
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
            Invoke-WebRequest -Uri $u -OutFile $o -ErrorAction Stop -TimeoutSec 1800
            return @{ Success = $true; Path = $o; Size = (Get-Item $o).Length / 1MB; Time = (Get-Date) - $start; Desc = $d; Prod = $p; End = Get-Date }
        }
        catch { return @{ Success = $false; Error = $_.Exception.Message; Desc = $d; Prod = $p } }
    }
    $job = Start-Job -ScriptBlock $script -ArgumentList $Url, $finalPath, $Description, $ProductName
    $global:ActiveDownloads += @{ Job = $job; Desc = $Description; Prod = $ProductName; Start = Get-Date }
    Write-Color "`nIndirme arka planda baslatildi (ID: $($job.Id))" -Color $COLOR_ZUMRUT
    Write-Color "Takip için ana menüden 'Durum Takibi' sekmesini kullanabilirsiniz." -Color $COLOR_GRI
}

function Show-Status {
    if ($global:ActiveDownloads.Count -eq 0) { Write-Color "Aktif indirme yok." -Color $COLOR_GRI; return }
    Write-Header "INDIRME DURUMU"
    $toRemove = @()
    for ($i = 0; $i -lt $global:ActiveDownloads.Count; $i++) {
        $d = $global:ActiveDownloads[$i]; $j = $d.Job
        Write-Host ("$($i+1). $($d.Prod) - $($d.Desc) ($($j.State))") -ForegroundColor $COLOR_ALTIN
        if ($j.State -eq "Completed") {
            $res = Receive-Job -Job $j
            if ($res.Success) {
                Write-Color "   Tamamlandı: $([math]::Round($res.Size,2))MB, Süre: $($res.Time.ToString('mm\:ss'))" -Color $COLOR_ZUMRUT
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
    Show-MebadiBanner
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

# 7. Ana Menü ve Döngü
function Start-MainMenu {
    while ($true) {
        Show-MebadiBanner
        Write-Host "`n[ Trend Micro Unified Download Tool - v2.0.0 ]" -ForegroundColor $COLOR_ALTIN
        Write-Host " 1. Apex One / Apex Central Paketleri"
        Write-Host " 2. Deep Security Manager (LTS)"
        Write-Host " 3. Durum Takibi ($($global:ActiveDownloads.Count) aktif)"
        Write-Host " 4. İndirme Geçmişi (History)"
        Write-Host " 5. Uygulama Önbelleğini Temizle"
        Write-Host " Q. Çıkış"
        
        $mChoice = Read-Host "`nSeçiminiz"
        switch ($mChoice) {
            "1" {
                Show-MebadiBanner
                Write-Header "URUN SECIMI (Apex)"
                Write-Color " 1. Apex One"
                Write-Color " 2. Apex Central"
                Write-Color " B. Geri Dön"
                $selection = Read-Host "`nUrun Numarasi"
                if ($selection -match "[12]") {
                    $prod = $global:ApexProducts[$selection]
                    $infos = Get-ProductInfo -Product $prod
                    if ($null -ne $infos) {
                        $ask = Read-Host "`nIndirme islemi baslatilsin mi? [E/H]"
                        if ($ask -eq "E" -or $ask -eq "e") {
                            $folder = Select-Folder -Prod $prod.Name
                            Show-MebadiBanner
                            Write-Header "PAKET SECIMI"
                            Write-Color " 1. Ana Paket (Full/SP)"
                            Write-Color " 2. Yama/Hotfix"
                            Write-Color " 3. Her Ikisi"
                            $target = Read-Host "`nIndirilecek Paket"
                            if ($target -in "1", "3") { Start-BackgroundDownload -Url $infos.Main.DownloadLink -OutputPath (Join-Path $folder $infos.Main.Filename) -Description "Ana Paket" -ProductName $prod.Name }
                            if ($target -in "2", "3") { Start-BackgroundDownload -Url $infos.Hotfix.DownloadLink -OutputPath (Join-Path $folder $infos.Hotfix.Filename) -Description "Hotfix" -ProductName $prod.Name }
                            Wait-ForKeyPress
                        }
                    }
                    else { Wait-ForKeyPress }
                }
            }
            "2" {
                Show-MebadiBanner
                Write-Host "`n[ Deep Security - Platform Seçimi ]" -ForegroundColor $COLOR_ALTIN
                Write-Host " 1. Linux Manager"
                Write-Host " 2. Windows Manager"
                Write-Host " B. Geri Dön"
                $pChoice = Read-Host "`nPlatform"
                if ($pChoice -eq "B" -or $pChoice -eq "b") { continue }
                $platform = switch ($pChoice) { "1" { "Linux" } "2" { "Windows" } default { $null } }
                if ($null -ne $platform) {
                    $list = Get-DeepSecurityManagerInfo -Platform $platform
                    if ($null -ne $list) {
                        Show-MebadiBanner
                        Write-Host "`n[ $platform Manager Listesi ]" -ForegroundColor $COLOR_ALTIN
                        for ($i = 0; $i -lt $list.Count; $i++) {
                            $item = $list[$i]
                            Write-Host ("$($i + 1). Build: $($item.Build) | $($item.Filename)") -ForegroundColor $COLOR_ELMAS
                            Write-Host ("   SHA256: $($item.SHA256)") -ForegroundColor $COLOR_GRI
                            Write-Host ("   MD5:    $($item.MD5)") -ForegroundColor $COLOR_GRI
                            Write-Host ("   Tarih:  $($item.Updated)") -ForegroundColor $COLOR_GRI
                            Write-Host ("-" * 40) -ForegroundColor DarkGray
                        }
                        $idxChoice = Read-Host "`nİndirmek istediğiniz numara (Geri dönmek için Enter)"
                        if ($idxChoice -match '^\d+$') {
                            $idx = [int]$idxChoice - 1
                            if ($idx -ge 0 -and $idx -lt $list.Count) {
                                $folder = Select-Folder -Prod "DeepSecurity"
                                Start-BackgroundDownload -Url $list[$idx].Link `
                                    -OutputPath (Join-Path $folder $list[$idx].Filename) `
                                    -Description "$platform Manager (Build $($list[$idx].Build))" `
                                    -ProductName "Deep Security"
                                Wait-ForKeyPress
                            }
                        }
                    }
                    else { Wait-ForKeyPress }
                }
            }
            "3" { Show-MebadiBanner; Show-Status; Wait-ForKeyPress }
            "4" {
                Show-MebadiBanner
                Write-Header "INDIRME GECMISI"
                if ($global:DownloadHistory.Count -eq 0) { Write-Color "Gecmis kaydi bulunamadi." -Color $COLOR_GRI }
                foreach ($h in $global:DownloadHistory) { 
                    Write-Color " • $($h.Prod) - $($h.Desc) ($([math]::Round($h.Size,2)) MB)" -Color $COLOR_ZUMRUT 
                }
                Wait-ForKeyPress
            }
            "5" { Clear-AppCache; Wait-ForKeyPress }
            "Q" {
                if ($global:ActiveDownloads.Count -gt 0) {
                    $c = Read-Host "Aktif indirmeler var. Çıkılsın mı? [E/H]"
                    if ($c -ne "E" -and $c -ne "e") { continue }
                }
                return
            }
            "q" { return }
        }
    }
}

# Başlat
Start-MainMenu
Write-Host "`n*Gayret bizden, tevfik Allah'tandir. | dad-u-bab (v2.0.0)*"
