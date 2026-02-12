#!/usr/bin/env python3
"""
Linux Batarya Sağlığı Analiz Paneli (v1.0.1)
Author: bab-ı kod
DISCLAIMER: Bu betik henüz tam teşekküllü test edilmemiştir. Sorumluluk kullanıcıya aittir.
DISCLAIMER: This script is not fully tested. Use at your own risk.
"""

from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt
import sys

def plot_battery_health(csv_path=None):
    if csv_path is None:
        csv_path = Path.home() / ".battery-log" / "history.csv"
    else:
        csv_path = Path(csv_path)

    if not csv_path.exists():
        print(f"HATA: Log dosyası bulunamadı: {csv_path}")
        print("Lütfen önce 'power-manager --log' komutu ile log üretin.")
        return

    try:
        df = pd.read_csv(csv_path, header=None, names=["date","full","design","cycle"])
        df["date"] = pd.to_datetime(df["date"])
        df["health"] = (df["full"] / df["design"]) * 100

        plt.figure(figsize=(10, 6))
        plt.plot(df["date"], df["health"], marker='o', linestyle='-', color='b')
        plt.title("Batarya Sağlık Durumu Değişimi (Battery Health Over Time)")
        plt.ylabel("Sağlık / Health (%)")
        plt.xlabel("Tarih / Date")
        plt.grid(True, linestyle='--', alpha=0.7)
        plt.tight_layout()
        
        print(f"Grafik oluşturuluyor... (Son sağlık değeri: %{df['health'].iloc[-1]:.2f})")
        plt.show()
    except Exception as e:
        print(f"Beklenmedik bir hata oluştu: {e}")

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else None
    plot_battery_health(path)
    print("\n*Gayret bizden, tevfik Allah'tandır. | bab-ı kod*")
