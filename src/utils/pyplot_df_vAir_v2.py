#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import sys
#: By David Thierry @ 2021
#: Take into account the Air
def main():
    # Dac-flue bars
    df = pd.read_csv("../mods/df_dac_flue.csv")
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
    ax.set_ylabel("Mass of Sorbent (Tonne)")
    plt.savefig("bars_flue.png")
    plt.close()
    # Dac-air bars
    df = pd.read_csv("../mods/df_dac_air.csv")
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
    ax.set_ylabel("Mass of Sorbent (Tonne)")
    plt.savefig("bars_air.png")
    plt.close()

    # Power lines
    df = pd.read_csv("../mods/df_pow.csv")
    dfb = pd.read_csv("../mods/df_pow_price.csv")
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
    #ax.plot(h, df["Demand"], marker="o", label="Demand")
    #ax.plot(h, df["PowGross"], marker="x", label="PowGross")
    #ax.plot(h, df["PowOut"], marker=".", label="PowOut")
    #ax.plot(h, df["PowUsePcc"], marker=".", label="PowUsePcc")
    #ax.plot(h, df["PowUseDacFlue"], marker=".", label="PowUseDacFlue")
    #ax.plot(h, df["PowUseDacAir"], marker=".", label="PowUseDacAir")
    ax.stackplot(h, df["PowOut"], df["PowGross"] - df["PowOut"], labels=["Out", "Gross"])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    ax.set_title("Power Gross")
    plt.savefig("Powah.png")
    plt.close()

    fig, ax = plt.subplots()
    ax.step(h, df["yGasTelecLoad"], color="lightcoral", label="GT Load")
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("% Load")
    ax.set_title("Load v. Price")
    # ax.set_ylim([50, 110])
    axb = ax.twinx()
    axb.plot(h, dfb["price"], marker="D", label="Price USD/MWh")
    axb.legend()
    plt.savefig("GTLoad.png")
    plt.close()
    axb.clear()



    # Power area
    #df = pd.read_csv("../mods/df_pow.csv")
    ax = df.plot.area(y=["PowGasTur", "PowHp", "PowIp", "PowLp"])
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    fig = ax.get_figure()
    fig.savefig("Powah_g_stacked.png")
    fig.clf()

    trd = df[["PowUsePcc", "PowUseDacFlue", "PowUseDacAir", "AuxPowGasT", "AuxPowSteaT"]]
    #trd["Demand"] = df["Demand"] - trd.sum(axis=1)
    #trd["Gross"] = df["PowGross"] - df["Demand"]
    ax = trd.plot.area()
    ax.set_title("Power Consumption")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    fig = ax.get_figure()
    fig.savefig("Powah_c_stacked.png")
    fig.clf()

    # Co2
    df = pd.read_csv("../mods/df_co.csv")
    trd = df[["Co2CapPcc", "Co2CapDacFlue"]]
    trd["NotCaptCo2"] = df["Co2Fuel"] - trd.sum(axis=1)
    trd["Co2CapDacAir"] = df["Co2CapDacAir"]
    trd.loc[trd["NotCaptCo2"] < 0, "NotCaptCo2"] = 0.0
    ax = trd.plot.area()
    ax.set_title("CO2 Capture")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2")
    fig = ax.get_figure()
    fig.savefig("co2air.png")
    fig.clf()

    # Co2 dac only
    trd.pop("Co2CapPcc")
    ax = trd.plot.area()
    ax.set_title("CO2 Capture DAC only")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2")
    fig = ax.get_figure()
    fig.savefig("co2daconly.png")
    fig.clf()


    # Steam
    df = pd.read_csv("../mods/df_steam.csv")
    h = df.index
    df["DacTotal"] = df["SteaUseDacFlue"] + df["SteaUseDacAir"]
    x = np.arange(len(h))
    w = 0.35
    fig, ax = plt.subplots()
    ax.bar(x - w/2, df["SteaUsePcc"], w, bottom=0, label="Steam used PCC")
    ax.bar(x - w/2, df["PccSteaSlack"], w, bottom=df["SteaUsePcc"], label="Steam available PCC")

    ax.bar(x + w/2, df["DacTotal"], w, bottom=0, label="Steam used DAC")
    ax.bar(x + w/2, df["DacSteaSlack"], w, bottom=df["DacTotal"], label="Steam available DAC")

    ax.set_title("Steam")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU)")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("steam.png")
    fig.clf()

    df = pd.read_csv("../mods/df_cost.csv")
    df.loc[df["cCo2Em"] < 0, "cCo-"] = abs(df["cCo2Em"])
    df.loc[df["cCo2Em"] >= 0, "cCo-"] = 0.0
    df.loc[df["cCo2Em"] < 0, "cCo2Em"] = 0.0
    #df.plot.area(y=["cNG", "cCo2Em", "cTransp"])
    ax = df.plot.bar()
    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("cost.png")
    fig.clf()




if __name__ == "__main__":
    main()



