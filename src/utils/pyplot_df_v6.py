#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import sys
#: By David Thierry @ 2021
#: Take into account the Air


def main():
    hour0 = 2270
    hourf = 2270 + 80
    # 2190
    # 4383
    # 8000

    # 5090

    # Dac-flue bars
    df = pd.read_csv("../mods/df_dac_flue.csv")
    labels = [r"Frsh", r"Sat", r"Abs-0", r"Abs-1", r"Abs-2", r"Reg-0", r"Reg-1"]
    fig, ax = plt.subplots()

    a = df["xFflue"]
    b = df["xSflue"]
    c = df["vAbsFlue"]
    d = df["xA1Flue"]
    e = df["xA2Flue"]
    f = df["vRegFlue"]
    g = df["xR1Flue"]

    remain_frs = a + g - c
    remain_sat = b + e - f

    h = df.index
    r = range(hour0, hourf)
    ax.bar(r, remain_frs.iloc[r], label="Unalloc. Fresh", color="lightblue")
    ax.bar(r, c.iloc[r], bottom=remain_frs.iloc[r], label="Alloc. Absorption", color="moccasin")
    ax.bar(r, d.iloc[r], bottom=remain_frs.iloc[r] + c.iloc[r], label="1-h Absorption", color="lavender")
    ax.bar(r, remain_sat.iloc[r], bottom=remain_frs.iloc[r] + c.iloc[r] + d.iloc[r], label="Unalloc. Saturated",
           color="lightcoral")
    ax.bar(r, f.iloc[r], bottom=remain_frs.iloc[r] + c.iloc[r] + d.iloc[r] + remain_sat.iloc[r], label="Alloc. Regen",
           color="plum")
    ax.legend()
    ax.set_title("DAC-Flue Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent (Tonne)")
    plt.savefig("bars_flue.png", format="png", dpi=300)
    plt.close(fig)

    # Dac-air bars
    df = pd.read_csv("../mods/df_dac_air.csv")
    labels = [r"Frsh", r"Sat", r"Abs-0", r"Abs-1", r"Abs-2", r"Reg-0", r"Reg-1"]
    fig, ax = plt.subplots()

    a = df["xFair"].iloc[r]
    b = df["xSair"].iloc[r]
    c = df["vAbsAir"].iloc[r]
    d = df["xA1Air"].iloc[r]
    e = df["xA2Air"].iloc[r]
    f = df["vRegAir"].iloc[r]
    g = df["xR1Air"].iloc[r]

    remain_frs = a + g - c
    remain_sat = b + e - f

    h = df.index

    ax.bar(r, remain_frs, label="Unalloc. Fresh", color="lightblue")
    ax.bar(r, c, bottom=remain_frs, label="Alloc. Absorption", color="moccasin")
    ax.bar(r, d, bottom=remain_frs + c, label="1-h Absorption", color="lavender")
    ax.bar(r, remain_sat, bottom=remain_frs + c + d, label="Unalloc. Saturated",
           color="lightcoral")
    ax.bar(r, f, bottom = remain_frs + c + d + remain_sat, label="Alloc. Regen",
           color="plum")
    ax.legend()
    ax.set_title("DAC-Air Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent (Tonne)")
    plt.savefig("bars_air.png", format="png", dpi=300)
    plt.close(fig)

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
    # PowUseDacAir
    # PowUseComp,
    # xAuxPowGasT,
    # xAuxPowSteaT,
    # PowGross,
    # PowOut,
    # yGasTelecLoad,
    # Demand


    fig, ax = plt.subplots()
    ax.stackplot(r, df["PowOut"].iloc[r], df["PowGross"].iloc[r] - df["PowOut"].iloc[r], labels=["Out", "Gross"])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    ax.set_title("Power Gross")
    plt.savefig("Powah.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.step(r, df["yGasTelecLoad"].iloc[r], color="lightcoral", label="GT Load", linewidth=2.5)
    ax.legend(loc=0)
    ax.set_xlabel("Hour")
    ax.set_ylabel("% Load")
    ax.set_title("Load v. Price")
    ax.set_ylim([57, 103])

    axb = ax.twinx()
    axb.plot(r, dfb.loc[r, "price"], marker="|", label="Price USD/MWh", markersize=6, color="mediumpurple",
             linewidth=2.5)
    axb.set_ylim(-3, max(dfb.loc[:, "price"]+3))
    axb.hlines(max(dfb.loc[:, "price"]), min(r), max(r), linestyle="dashed", label="Max. Price")
    axb.legend(loc=0)
    axb.set_ylabel("Price $/MWh")
    plt.savefig("GTLoad.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.step(df.index, df["yGasTelecLoad"], color="lightcoral", label="GT Load")
    ax.set_xlabel("Hour")
    ax.set_ylabel("% Load")
    ax.set_title("Load v. Price")
    axb = ax.twinx()
    axb.plot(dfb.index, dfb["price"], color="mediumpurple", label="Price USD/MWh")
    plt.savefig("GTLoadAlllong.eps")
    plt.close(fig)


    # Power area
    #df = pd.read_csv("../mods/df_pow.csv")
    #: Maximum power generated
    max_power = max(df["PowGross"])
    fig, ax = plt.subplots()
    ax.stackplot(r, df["PowGasTur"].iloc[r],
            df["PowHp"].iloc[r],
            df["PowIp"].iloc[r],
            df["PowLp"].iloc[r],
            labels=["PowGasTur", "PowHp", "PowIp", "PowLp"],
            colors=["seashell", "tomato", "coral", "crimson"])
    #: ToDo set same ylims
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    ax.set_ylim(0, max_power * 1.01)
    ax.legend(loc=0)
    fig.savefig("Powah_g_stacked.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.stackplot(r,
            df["PowHp"].iloc[r],
            df["PowIp"].iloc[r],
            df["PowLp"].iloc[r],
            labels=["PowHp", "PowIp", "PowLp"],
            colors=["tomato", "coral", "crimson"])
    #ax = df.plot.area(y=["PowGasTur", "PowHp", "PowIp", "PowLp"])
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    ax.legend()
    fig.savefig("Powah_s_stacked.png", format="png", dpi=300)
    plt.close(fig)

    trd = df[["PowUsePcc",
        "PowUseDacFlue",
        "PowUseDacAir",
        "PowUseComp",
        "AuxPowGasT",
        "AuxPowSteaT"]].iloc[r]
    #trd["Demand"] = df["Demand"] - trd.sum(axis=1)
    #trd["Gross"] = df["PowGross"] - df["Demand"]
    fig, ax = plt.subplots()
    ax.stackplot(r, trd["PowUsePcc"], trd["PowUseDacFlue"], trd["PowUseDacAir"], trd["PowUseComp"], trd["AuxPowGasT"],
                 trd["AuxPowSteaT"],
                 labels=["PowUsePcc",
                         "PowUseDacFlue",
                         "PowUseDacAir",
                         "PowUseComp",
                         "AuxPowGasT",
                         "AuxPowSteaT"],
                 colors=["lightgray", "skyblue", "lightcoral", "lavender", "mediumpurple", "moccasin"])

    ax.set_title("Power Consumption")
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MWh)")
    fig = ax.get_figure()
    fig.savefig("Powah_c_stacked.png", format="png", dpi=300)
    plt.close(fig)

    # Co2
    df = pd.read_csv("../mods/df_co.csv")
    trd = df[["Co2CapPcc", "Co2CapDacFlue"]]
    #: Calculate Emissions.
    trd["NotCaptCo2"] = df["Co2Fuel"] - trd.sum(axis=1)
    trd["Co2CapDacAir"] = df["Co2CapDacAir"]
    #: Compute the maximum
    trd["Co2FuelpAir"] = df["Co2Fuel"] + trd["Co2CapDacAir"]
    max_co = max(trd["Co2FuelpAir"])
    trd.loc[trd["NotCaptCo2"] < 0, "NotCaptCo2"] = 0.0  #: I don't remember why I've put this.

    fig, ax = plt.subplots()
    ax.stackplot(r, trd["Co2CapPcc"].iloc[r],
                 trd["Co2CapDacFlue"].iloc[r],
                 trd["NotCaptCo2"].iloc[r],
                 trd["Co2CapDacAir"].iloc[r],
                 labels=["Co2CapPcc", "Co2CapDacFlue", "Emissions", "Co2CapDacAir"],
                 colors=["lightgray", "skyblue", "lightcoral", "lavender"])
    ax.set_title("CO2 Capture")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2")
    ax.set_ylim(0, max_co * 1.01)
    ax.legend()
    fig.savefig("co2capture.png", format="png", dpi=300)
    plt.close(fig)


    # Co2 dac only
    fig, ax = plt.subplots()
    ax.stackplot(r, trd["Co2CapDacFlue"].iloc[r],
                 trd["NotCaptCo2"].iloc[r],
                 trd["Co2CapDacAir"].iloc[r],
                 labels=["Co2CapDacFlue", "NotCaptCo2", "Co2CapDacAir"],
                 colors=["skyblue", "lightcoral", "lavender"])
    ax.set_title("CO2 Capture DAC only")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2")
    ax.legend()
    fig.savefig("co2daconly.png", format="png", dpi=300)
    plt.close(fig)

    # Steam
    df = pd.read_csv("../mods/df_steam.csv")
    h = df.index
    df["DacTotal"] = df["SteaUseDacFlue"] + df["SteaUseDacAir"]
    x = np.arange(hour0, hourf)
    w = 0.35
    fig, ax = plt.subplots()
    ax.stackplot(r, df["SteaUsePcc"].iloc[r], df["PccSteaSlack"].iloc[r],
                 labels=["SteamUsedPcc", "SteamAvailablePcc"],
                 colors=["skyblue", "lightcoral"])

    ax.set_title("Steam Used Pcc")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU)")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("steamPcc.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.stackplot(r, df["DacTotal"].iloc[r], df["DacSteaSlack"].iloc[r],
                 labels=["SteamUsedDac", "SteamAvailableDac"],
                 colors=["skyblue", "lightcoral"])

    ax.set_title("Steam Used Dac")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU)")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("steamDac.png", format="png", dpi=300)
    fig.clf()
    ax.cla()

    fig, ax = plt.subplots()
    ax.stackplot(r, df["DacSteaBaseDuty"].iloc[r], df["SideSteaDac"].iloc[r],
                 labels=["Nominal Heat", "Additional Heat (LP)"],
                 colors=["skyblue", "lightcoral"])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Heat (MMBTU)")
    ax.set_title("Dac Steam Source")
    plt.savefig("dac_Stea.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()

    df = pd.read_csv("../mods/df_cost.csv")
    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo-"] = abs(df.loc[:, "cCo2Em"])
    df.loc[df.loc[:, "cCo2Em"] >= 0, "cCo-"] = 0.0  # Set the remaining to zero

    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo2Em"] = 0.0
    w = .25
    x = np.arange(hour0, hourf)
    ax.bar(x - 2 * w, df["cNG"].iloc[r], width=w, color="skyblue", align="edge", label="Natural Gas")
    ax.bar(x - w, df["cTransp"].iloc[r], width=w, color="lavender", align="edge", label="Transportation")
    ax.bar(x, df["cCo-"].iloc[r], width=w, color="lightgray", align="edge", label="Negative Emissions")
    ax.bar(x + w, df["cCo2Em"].iloc[r], width=w, color="lightcoral", align="edge", label="Emissions")

    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD")
    ax.legend()
    fig = ax.get_figure()
    fig.savefig("cost.png", format="png", dpi=300)
    plt.close(fig)
    #: Costs.
    fig, ax = plt.subplots()
    ax.stackplot(r, df["cNG"].iloc[r], df["cTransp"].iloc[r], df["cCo2Em"].iloc[r],
                 labels=["Nat. Gas", "Transport.", "Emissions"],
                 colors=["skyblue", "lavender", "lightcoral"])
    #: Sum of cost
    s_c = df["cNG"] + df["cTransp"] + df["cCo2Em"]
    s_max = max(s_c)
    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD")
    ax.legend()
    ax.set_ylim(0, s_max)
    fig.savefig("cost_stacked.png", format="png", dpi=300)
    plt.close(fig)

    #: Negative emissions.
    fig, ax = plt.subplots()
    ax.stackplot(r, df["cCo-"].iloc[r],
                 labels=["Negative Emissions"],
                 colors=["crimson"])


    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD")
    ax.legend()
    ax.set_ylim(0, s_max)
    fig.savefig("cost_stacked_negem.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    profit = df.loc[:, "PowSales"] + df.loc[:, "cCo-"] - df.loc[:, "cCo2Em"] - df.loc[:, "cNG"] - df.loc[:, "cTransp"]
    profitp = profit.copy()
    profitp.loc[profitp.iloc[:] < 0] = 0
    profitn = profit.copy()
    profitn.loc[profitn.iloc[:] >= 0] = 0
    #: Get the maximum and minimum profit so we can scale the y-axis.
    min_profit = min(profitn)
    max_profit = max(profitp)
    ax.bar(r, profitp.iloc[r], color="cornflowerblue", label="gains")
    ax.bar(r, profitn.iloc[r], color="lightcoral", label="losses")
    ax.set_title("Profit")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD")
    ax.set_ylim(min_profit * 1.1, max_profit * 1.01)
    ax.hlines(max_profit, min(r), max(r), linestyle="dashed", label="Max. Profit", color="cornflowerblue")
    ax.hlines(min_profit, min(r), max(r), linestyle="dashed", label="Max. Loss", color="lightcoral")

    ax.legend()
    plt.axhline(0)

    fig.savefig("profit.png", format="png", dpi=300)
    plt.close(fig)
    #
    fig, ax = plt.subplots()
    ax.bar(profitp.index, profitp, color="cornflowerblue", label="gains")
    ax.bar(profitn.index, profitn, color="lightcoral", label="losses")
    #ax.set_title("Profit")
    #ax.set_xlabel("Hour")
    #ax.set_ylabel("USD")

    fig.savefig("profit.eps")

if __name__ == "__main__":
    main()



