#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import sys
#: By David Thierry @ 2021
#: Take into account the Air
def main():
    # Power
    df = pd.read_csv("../mods/df_pow.csv")
    ax = df.plot.area(y=["vPowCombTurb", "PowHp", "PowIp", "PowLp1", "PowLp2"])
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    fig = ax.get_figure()
    fig.savefig("Powah_g_stacked.png")
    fig.clf()

    trd = df[["PowUsePcc", "PowUseDacFlue", "PowUseDacAir"]]
    trd["Demand"] = df["Demand"] - trd.sum(axis=1)
    trd["Gross"] = df["PowGross"] - df["Demand"]
    ax = trd.plot.area()
    ax.set_title("Power Consumption")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    fig = ax.get_figure()
    fig.savefig("Powah_c_stacked.png")
    fig.clf()

    # Co2
    df = pd.read_csv("../mods/df_co.csv")
    trd = df[["Co2CapPcc", "Co2CapDacFlue", "Co2CapDacAir"]]
    ax = trd.plot.area()
    ax.set_title("CO2 Capture")
    ax.set_xlabel("Hour")
    ax.set_ylabel("CO2")
    fig = ax.get_figure()
    fig.savefig("co2air.png")
    fig.clf()


if __name__ == "__main__":
    main()



