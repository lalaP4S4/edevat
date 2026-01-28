# ---------------------------------------------------------------------------
# TrendMicro Download Center - V5 (Master Superset)
# Hizli Guncelleme Takip ve Indirme Araci
# ---------------------------------------------------------------------------

# Karakter kodlamasini UTF-8 olarak ayarla
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
    $line = "=" * ($Title.Length + 4)
    Write-Color $line -Color $COLOR_ZUMRUT
    Write-Color "  $Title" -Color $COLOR_ZUMRUT
    Write-Color $line -Color $COLOR_ZUMRUT
}

# 1. Konfigurasyon ve Global Degiskenler
$global:ActiveDownloads = @()
$global:DownloadHistory = @()
$products = @{
    "1" = @{
        Name   = "Apex One"
        ProdId = "1745"
        Main   = @{
            DownloadXPath = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[1]/td[3]/a"
            ReleaseXPath  = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[1]/td[2]"
            FileSHAXPath  = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[2]/td/div[2]/p[1]"
        }
        Hotfix = @{
            ReleaseXPath  = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[1]/td[2]"
            DownloadXPath = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[1]/td[3]/a"
            FileSHAXPath  = "/html/body/div[1]/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[2]/td/div[2]/p[1]"
        }
    }
    "2" = @{
        Name   = "Apex Central"
        ProdId = "1746"
        Main   = @{
            DownloadXPath = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[1]/td[3]/a"
            ReleaseXPath  = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[1]/td[2]"
            FileSHAXPath  = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[1]/div/div/table/tbody/tr[2]/td/div[2]/p[1]"
        }
        Hotfix = @{
            ReleaseXPath  = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[1]/td[2]"
            DownloadXPath = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[1]/td[3]/a"
            FileSHAXPath  = "/html/body/div/div[1]/div[2]/div[1]/div/div/div[2]/div/div/table/tbody/tr[2]/td/div[2]/p[1]"
        }
    }
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
            Write-Color "Onbellekteki DLL yuklenemedi, yeniden denenecek." -Color $COLOR_ALTIN
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
            Write-Color "Bagimlilik basariyla yuklendi." -Color $COLOR_ZUMRUT
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
        Write-Color "Onbellek temizlendi." -Color $COLOR_ZUMRUT
    }
    else {
        Write-Color "Temizlenecek onbellek bulunamadi." -Color $COLOR_GRI
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
        foreach ($type in @("Main", "Hotfix")) {
            $xpath = $Product.$type.FileSHAXPath
            $text = Get-SafeNodeValue -Doc $doc -XPath $xpath
            if ([string]::IsNullOrWhiteSpace($text)) { $text = $doc.DocumentNode.InnerText }
            
            $info = Get-TMPackageInfo -Text $text -Type $type
            $linkNode = $doc.DocumentNode.SelectSingleNode($Product.$type.DownloadXPath)
            $link = ""
            if ($linkNode) {
                $link = $linkNode.GetAttributeValue("href", "").Trim()
            }
            if ($link -and $link -notmatch "^https?://") { $link = "https://downloadcenter.trendmicro.com" + $link }
            
            $info.DownloadLink = $link
            $info.ReleaseDate = Get-SafeNodeValue -Doc $doc -XPath $Product.$type.ReleaseXPath -FallbackText "Bilinmiyor"
            $results[$type] = $info
        }

        if (-not $Silent) {
            Clear-Host
            Write-Header "GUNCEL BILGILER: $($Product.Name)"
            foreach ($type in @("Main", "Hotfix")) {
                $p = $results[$type]
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
        Write-Color "Bilgi cekme hatasi: $_" -Color $COLOR_YAKUT
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
    Write-Header "KLASOR SECIMI: $Prod"
    Write-Color "1. Masaustu"
    Write-Color "2. Indirilenler"
    Write-Color "3. Mevcut Dizin"
    Write-Color "4. Ozel"
    $s = Read-Host "Secim [1-4]"
    $base = switch ($s) {
        "1" { [Environment]::GetFolderPath("Desktop") }
        "2" { Join-Path ([Environment]::GetFolderPath("UserProfile")) "Downloads" }
        "4" { Read-Host "Tam Yol" }
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
        Clear-Host
        Write-Header "TREND MICRO V5 SUPERSET"
        Write-Color "1. Urun Sorgula & Indir"
        Write-Color "2. Durum Goruntule"
        Write-Color "3. Gecmis"
        Write-Color "4. Onbellek Temizle"
        Write-Color "5. Cikis"
        $m = Read-Host "Secim"
        switch ($m) {
            "1" {
                Write-Color "1. Apex One"
                Write-Color "2. Apex Central"
                Write-Color "3. Geri"
                $selection = Read-Host "Urun"
                if ($selection -match "[12]") {
                    $prod = $products[$selection]
                    $infos = Get-ProductInfo -Product $prod
                    if ($null -ne $infos) {
                        $ask = Read-Host "`nIndirme yapilsin mi? [E/H]"
                        if ($ask -eq "E" -or $ask -eq "e") {
                            $folder = Select-Folder -Prod $prod.Name
                            Write-Color "1. Ana Paket"
                            Write-Color "2. Hotfix"
                            Write-Color "3. Her Ikisi"
                            $target = Read-Host "Indirilecek"
                            if ($target -in "1", "3") { Start-BackgroundDownload -Url $infos.Main.DownloadLink -OutputPath (Join-Path $folder $infos.Main.Filename) -Description "Ana Paket" -ProductName $prod.Name }
                            if ($target -in "2", "3") { Start-BackgroundDownload -Url $infos.Hotfix.DownloadLink -OutputPath (Join-Path $folder $infos.Hotfix.Filename) -Description "Hotfix" -ProductName $prod.Name }
                        }
                    }
                    Wait-ForKeyPress
                }
            }
            "2" { Clear-Host; Show-Status; Wait-ForKeyPress }
            "3" {
                Clear-Host; Write-Header "GECMIS"
                if ($global:DownloadHistory.Count -eq 0) { Write-Color "Gecmis temiz." -Color $COLOR_GRI }
                foreach ($h in $global:DownloadHistory) { Write-Color "• $($h.Prod) - $($h.Desc) ($($h.Size)MB)" -Color $COLOR_ZUMRUT }
                Wait-ForKeyPress
            }
            "4" { Clear-AppCache; Wait-ForKeyPress }
            "5" { if ($global:ActiveDownloads.Count -gt 0) { $c = Read-Host "Aktif indirmeler var. Cikilsin mi? [E/H]"; if ($c -ne "E" -and $c -ne "e") { continue } }; break }
        }
    }
}

Start-MainLoop
