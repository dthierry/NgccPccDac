#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import sys
#: By David Thierry @ 2021
#: Take into account the Air
def main():
    # Dac-flue bars
    df = pd.read_csv("../notebooks/df_dac_flue.csv")
    labels = [r"Frsh", r"Sat", r"Abs-0", r"Abs-1", r"Abs-2", r"Reg-0", r"Reg-1"]
    fig, ax = plt.subplots()

    a = df["sFflue"]
    b = df["sSflue"]
    c = df["vAbsFlue"]
    d = df["a1Flue"]
    e = df["a2Flue"]
    f = df["vRegFlue"]
    g = df["aR1Flue"]

    remain_frs = a + g - c
    remain_sat = b + e - f

    h = df.index

    ax.bar(h, remain_frs, label="avail Fresh")
    ax.bar(h, c, bottom = remain_frs, label="vAbs")
    ax.bar(h, d, bottom = remain_frs + c, label="1-h")
    ax.bar(h, remain_sat, bottom = remain_frs + c + d, label="avail Sat")
    ax.bar(h, f, bottom = remain_frs + c + d + remain_sat, label="vReg")
    ax.legend()
    ax.set_title("DAC-Flue Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent")
    plt.savefig("bars_flue.png")
    plt.close()
    # Dac-air bars
    df = pd.read_csv("../notebooks/df_dac_air.csv")
    labels = [r"Frsh", r"Sat", r"Abs-0", r"Abs-1", r"Abs-2", r"Reg-0", r"Reg-1"]
    fig, ax = plt.subplots()

    a = df["sFair"]
    b = df["sSair"]
    c = df["vAbsAir"]
    d = df["a1Air"]
    e = df["a2Air"]
    f = df["vRegAir"]
    g = df["aR1Air"]

    remain_frs = a + g - c
    remain_sat = b + e - f

    h = df.index

    ax.bar(h, remain_frs, label="avail Fresh")
    ax.bar(h, c, bottom = remain_frs, label="vAbs")
    ax.bar(h, d, bottom = remain_frs + c, label="1-h")
    ax.bar(h, remain_sat, bottom = remain_frs + c + d, label="avail Sat")
    ax.bar(h, f, bottom = remain_frs + c + d + remain_sat, label="vReg")
    ax.legend()
    ax.set_title("DAC-Air Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent")
    plt.savefig("bars_air.png")
    plt.close()

    # Power lines
    df = pd.read_csv("../notebooks/df_pow.csv")
    dfb = pd.read_csv("../notebooks/df_pow_price.csv")
    h = df.index

    # PowGasTur,
    # PowSteaTurb,
    # PowHp,
    # PowIp,
    # PowLp
    # PowUsePcc,
    # PowUseDacFlue,
    # PowUseDacAir,
    # PowUseComp,
    # xAuxPowGasT,
    # xAuxPowSteaT,
    # PowGross,
    # PowOut,
    # yGasTelecLoad,
    # Demand


    fig, ax = plt.subplots()
    ax.plot(h, df["Demand"], marker="o", label="Demand")
    ax.plot(h, df["PowGross"], marker="x", label="PowGross")
    ax.plot(h, df["PowOut"], marker=".", label="PowOut")
    ax.plot(h, df["PowUsePcc"], marker=".", label="PowUsePcc")
    ax.plot(h, df["PowUseDacFlue"], marker=".", label="PowUseDacFlue")
    ax.plot(h, df["PowUseDacAir"], marker=".", label="PowUseDacAir")
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    ax.set_title("Power")
    plt.savefig("Powah.png")
    plt.close()

    fig, ax = plt.subplots()
    ax.plot(h, df["yGasTelecLoad"], marker="o", label="GT Load")
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("\%")
    ax.set_title("Load")
    ax.set_ylim([60, 100])
    axb = ax.twinx()
    axb.plot(h, dfb["price"], marker="x", label="Price Pow USD/MWh")
    plt.savefig("GTLoad.png")
    plt.close()
    axb.clear()



    # Power area
    #df = pd.read_csv("../notebooks/df_pow.csv")
    ax = df.plot.area(y=["PowGasTur", "PowHp", "PowIp", "PowLp"])
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    fig = ax.get_figure()
    fig.savefig("Powah_g_stacked.png")
    fig.clf()

    trd = df[["PowUsePcc", "PowUseDacFlue", "PowUseDacAir", "AuxPowGasT", "AuxPowSteaT"]]
    #trd["Demand"] = df["Demand"] - trd.sum(axis=1)
    #trd["Gross"] = df["PowGross"] - df["Demand"]
    ax = trd.plot.area()
    ax.set_title("Power Consumption")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    fig = ax.get_figure()
    fig.savefig("Powah_c_stacked.png")
    fig.clf()

    # Co2
    df = pd.read_csv("../notebooks/df_co.csv")

    trd = df[["Co2CapPcc", "Co2CapDacFlue", "Co2CapDacAir"]]
    trd["remainingCo2"] = df["Co2Fuel"] - trd.sum(axis=1)
    ax = trd.plot.area()
    ax.set_title("CO2 Capture")
    ax.set_xlabel("Hour")
    ax.set_ylabel("CO2")
    fig = ax.get_figure()
    fig.savefig("co2air.png")
    fig.clf()

    # Steam
    df = pd.read_csv("../notebooks/df_steam.csv")
    trd = df
    trd.pop("Fuel")
    trd.pop("DacSteaSlack")
    trd.pop("PccSteaSlack")
    ax = trd.plot.line()
    ax.set_title("Steam")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU)")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("steam.png")
    fig.clf()




if __name__ == "__main__":
    main()



