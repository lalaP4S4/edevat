#!/bin/bash
<#
.SYNOPSIS
    Linux Güç Yönetimi ve TLP Profil Yöneticisi (v1.0.1)

.DESCRIPTION
    Bu betik, laptop sistemlerinde TLP profilleri arasında geçiş yapar, 
    pil şarj limitlerini ayarlar ve batarya sağlığı loglamasını yönetir.

    Sürüm: v1.0.1
    Tarih: 2026-01-28

.AUTHOR
    bab-ı kod

# DISCLAIMER: Bu betik henüz tam teşekküllü test edilmemiştir. Sorumluluk kullanıcıya aittir.
# DISCLAIMER: This script is not fully tested. Use at your own risk.
#>

set -e

# --- Yapılandırma ---
BASE_DIR="$HOME/.local/share/power-manager"
LOG_DIR="$HOME/.battery-log"
BIN_DIR="$HOME/.local/bin"
VERSION="1.0.1"

# --- Fonksiyonlar ---
Write-Status() {
    echo -e "\e[1;34m[PowerManager]\e[0m $1"
}

Test-Requirement() {
    if ! command -v tlp >/dev/null 2>&1; then
        echo "HATA: 'tlp' kurulu değil. Lütfen yükleyin: sudo apt install tlp"
        exit 1
    fi
}

Get-BatteryDevice() {
    local bat=$(ls /sys/class/power_supply | grep -E '^BAT' | head -n1 || true)
    if [ -z "$bat" ]; then
        echo ""
    else
        echo "$bat"
    fi
}

Set-WorkMode() {
    local bat=$(Get-BatteryDevice)
    Write-Status "WORK mode aktif ediliyor (40–80) [$bat]..."
    sudo tlp setcharge 40 80
    sudo tlp setcpu powersave
    if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    fi
    notify-send "Power Manager" "WORK mode aktif (40–80) [$bat]" 2>/dev/null || true
}

Set-GameMode() {
    local bat=$(Get-BatteryDevice)
    Write-Status "GAME mode aktif ediliyor (55–95) [$bat]..."
    sudo tlp setcharge 55 95
    sudo tlp setcpu performance
    if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
        echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    fi
    notify-send "Power Manager" "GAME mode aktif (55–95) [$bat]" 2>/dev/null || true
}

Invoke-Log() {
    local bat=$(Get-BatteryDevice)
    if [ -z "$bat" ]; then return; fi
    mkdir -p "$LOG_DIR"
    local logfile="$LOG_DIR/history.csv"
    local date=$(date +"%Y-%m-%d %H:%M")
    local full=$(cat /sys/class/power_supply/$bat/energy_full 2>/dev/null || cat /sys/class/power_supply/$bat/charge_full)
    local design=$(cat /sys/class/power_supply/$bat/energy_full_design 2>/dev/null || cat /sys/class/power_supply/$bat/charge_full_design)
    local cycle=$(cat /sys/class/power_supply/$bat/cycle_count 2>/dev/null || echo "0")
    echo "$date,$full,$design,$cycle" >> "$logfile"
}

Install-Tools() {
    Write-Status "Kurulum başlatılıyor..."
    mkdir -p "$BASE_DIR" "$LOG_DIR" "$BIN_DIR"
    
    # Kendi yolunu bul ve kopyala (opsiyonel ama portable olması iyidir)
    # cp "$0" "$BIN_DIR/power-manager"
    # chmod +x "$BIN_DIR/power-manager"

    # Cron kaydı
    ( crontab -l 2>/dev/null | grep -v "power-manager --log" ; \
      echo "0 10 * * * $BIN_DIR/power-manager --log" ) | crontab -
    
    Write-Status "Kurulum tamamlandı. 'power-manager' komutu kullanılabilir."
}

Show-Menu() {
    echo "=== POWER MANAGER v$VERSION ==="
    echo "1. WORK Mode (Battery Save 40-80)"
    echo "2. GAME Mode (Performance 55-95)"
    echo "3. Manuel Log Al"
    echo "4. Kurulumu Yap (Cron/Path)"
    echo "Q. Çıkış"
    read -p "Seçiminiz: " opt
    case $opt in
        1) Set-WorkMode ;;
        2) Set-GameMode ;;
        3) Invoke-Log; Write-Status "Log alındı." ;;
        4) Install-Tools ;;
        [Qq]*) exit 0 ;;
    esac
}

# --- Main ---
case "$1" in
    --work) Set-WorkMode ;;
    --game) Set-GameMode ;;
    --log)  Invoke-Log ;;
    --install) Install-Tools ;;
    *) Test-Requirement; Show-Menu ;;
esac

echo -e "\n*Gayret bizden, tevfik Allah'tandır. | bab-ı kod*"
