#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import math
import sys
#: By David Thierry @ 2021
#: Take into account the Air


def main():
    #hour0 = 2270
    hour0 = 5090

    delta_max = 20
    slice = 1
    delta = delta_max / slice

    hourf = hour0 + delta
    hour0 = int(hour0)
    hourf = int(hourf)
    # 2190
    # 4383
    # 8000

    # 5090

    # Normal time range
    r0 = range(hour0, hourf)
    xt = np.arange(hour0, hourf + 1, step=int((hourf-hour0)/4))
    #df_time = pd.read_csv("./df_time.csv")

    # Dac-flue bars
    df = pd.read_csv("./df_dac_flue.csv")

    fig, ax = plt.subplots()

    a = df["xFflue"]
    b = df["xSflue"]
    c = df["xA0Flue"]
    d = df["xA1Flue"]
    e = df["xA2Flue"]
    f = df["xR0Flue"]
    g = df["xR1Flue"]

    # Calculate the unallocated bars
    remain_frs = a + g - c
    remain_sat = b + e - f

    # Time series always starts at 0.
    h0_dac = hour0 * slice
    hf_dac = (hourf) * slice

    # Get the time as a list.
    r_dac = range(h0_dac, hf_dac)
    r_list = df["time"].values.tolist()

    # Subset of vlaues.
    r_t = [float(r_list[i]) for i in r_dac]

    print("normal hours")
    print(hour0, hourf)
    print([i for i in r0])
    print("dac hours")
    print(h0_dac, hf_dac)
    print(r_t)

    w = 1/slice
    ax.bar(r_t,
        remain_frs.iloc[r_dac],
        label="Unalloc. Fresh",
        color="lightblue",
        align="edge",
        width = w)
    ax.bar(r_t,
        c.iloc[r_dac],
        bottom=remain_frs.iloc[r_dac],
        label="Alloc. Absorption",
        color="moccasin",
        align="edge",
        width = w)
    ax.bar(r_t,
        d.iloc[r_dac],
        bottom=remain_frs.iloc[r_dac] + c.iloc[r_dac],
        label="1-h Absorption",
        color="lavender",
        align="edge",
        width = w)
    ax.bar(r_t,
        remain_sat.iloc[r_dac],
        bottom=remain_frs.iloc[r_dac] + c.iloc[r_dac] + d.iloc[r_dac],
        label="Unalloc. Saturated",
        color="lightcoral",
        align="edge",
        width = w)
    ax.bar(r_t,
        f.iloc[r_dac],
        bottom=remain_frs.iloc[r_dac] + c.iloc[r_dac] + d.iloc[r_dac] + remain_sat.iloc[r_dac],
        label="Alloc. Regen",
        color="plum",
        align="edge",
        width = w)

    ax.set_xticks(xt)
    ax.legend()
    ax.set_title("DAC-Flue Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent (Tonne)")
    plt.savefig("bars_flue.png", format="png", dpi=300)
    plt.close(fig)

    # Dac-air bars
    df = pd.read_csv("./df_dac_air.csv")
    fig, ax = plt.subplots()

    a = df["xFair"].iloc[r_dac]
    b = df["xSair"].iloc[r_dac]
    c = df["xA0Air"].iloc[r_dac]
    d = df["xA1Air"].iloc[r_dac]
    e = df["xA2Air"].iloc[r_dac]
    f = df["xR0Air"].iloc[r_dac]
    g = df["xR1Air"].iloc[r_dac]

    # Calculate the unallocated bars
    remain_frs = a + g - c
    remain_sat = b + e - f

    w = 1/slice
    ax.bar(r_t,
        remain_frs,
        label="Unalloc. Fresh",
        color="lightblue",
        align="edge",
        width=w)
    ax.bar(r_t,
        c,
        bottom=remain_frs,
        label="Alloc. Absorption",
        color="moccasin",
        align="edge",
        width=w)
    ax.bar(r_t,
        d,
        bottom=remain_frs + c,
        label="1-h Absorption",
        color="lavender",
        align="edge",
        width=w
        )
    ax.bar(r_t,
        remain_sat,
        bottom=remain_frs + c + d,
        label="Unalloc. Saturated",
        color="lightcoral",
        align="edge",
        width=w)
    ax.bar(r_t,
        f,
        bottom = remain_frs + c + d + remain_sat,
        label="Alloc. Regen",
        color="plum",
        align="edge",
        width=w)
    ax.set_xticks(xt)
    ax.legend()
    ax.set_title("DAC-Air Allocation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent (Tonne)")

    fig.savefig("bars_air.png", format="png", dpi=300)
    plt.close(fig)

    # Power lines
    df = pd.read_csv("./df_pow.csv")
    dfb = pd.read_csv("./df_pow_price.csv")


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
    ax.stackplot(r0,
        df["PowOut"].iloc[r0],
        df["PowGross"].iloc[r0] - df["PowOut"].iloc[r0],
        labels=["Out", "Gross"])

    ax.legend()
    ax.set_xticks(xt)
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MW)")
    ax.set_title("Power Gross")
    plt.savefig("Powah.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.plot(r0,
        df["yGasTelecLoad"].iloc[r0], drawstyle="steps-post",
        color="lightcoral",
        label="GT Load",
        linewidth=2.5)
    ax.legend(loc=0)
    ax.set_xticks(xt)
    ax.set_xlabel("Hour")
    ax.set_ylabel("\% Load")
    ax.set_title("Load / Price")
    ax.set_ylim([57, 103])

    axb = ax.twinx()
    axb.plot(r0,
        dfb.loc[r0, "price"],
        marker="|",
        label="Price USD/MWh", markersize=6,
        color="mediumpurple",
             linewidth=2.5)
    axb.set_ylim(-3, max(dfb.loc[:, "price"]+3))

    axb.hlines(max(dfb.loc[:, "price"]), min(r0), max(r0),
        linestyle="dashed",
        label="Max. Price")

    axb.legend(loc=0)
    ax.set_xticks(xt)
    axb.set_ylabel("Price $/MWh")
    plt.savefig("GTLoad.png", format="png", dpi=300)
    plt.close(fig)


    # Power area
    #df = pd.read_csv("./df_pow.csv")
    #: Maximum power generated
    max_power = max(df["PowGross"])
    fig, ax = plt.subplots()
    ax.stackplot(r0, df["PowGasTur"].iloc[r0],
            df["PowHp"].iloc[r0],
            df["PowIp"].iloc[r0],
            df["PowLp"].iloc[r0],
            labels=["PowGasTur", "PowHp", "PowIp", "PowLp"],
            colors=["seashell", "tomato", "coral", "crimson"])
    #: ToDo set same ylims
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MW)")
    ax.set_ylim(0, max_power * 1.01)
    ax.legend(loc=0)
    ax.set_xticks(xt)
    fig.savefig("Powah_g_stacked.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.stackplot(r0,
            df["PowHp"].iloc[r0],
            df["PowIp"].iloc[r0],
            df["PowLp"].iloc[r0],
            labels=["PowHp", "PowIp", "PowLp"],
            colors=["tomato", "coral", "crimson"])
    #ax = df.plot.area(y=["PowGasTur", "PowHp", "PowIp", "PowLp"])
    ax.set_title("Power Generation")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MW)")
    ax.legend()
    ax.set_xticks(xt)
    fig.savefig("Powah_s_stacked.png", format="png", dpi=300)
    plt.close(fig)

    trd = df[["PowUsePcc",
        "PowUseDacFlue",
        "PowUseDacAir",
        "PowUseComp",
        "AuxPowGasT",
        "AuxPowSteaT"]].iloc[r0]
    #trd["Demand"] = df["Demand"] - trd.sum(axis=1)
    #trd["Gross"] = df["PowGross"] - df["Demand"]
    fig, ax = plt.subplots()
    ax.stackplot(r0,
        trd["PowUsePcc"],
        trd["PowUseDacFlue"],
        trd["PowUseDacAir"],
        trd["PowUseComp"],
        trd["AuxPowGasT"],
        trd["AuxPowSteaT"],
        labels=["PowUsePcc",
                         "PowUseDacFlue",
                         "PowUseDacAir",
                         "PowUseComp",
                         "AuxPowGasT",
                         "AuxPowSteaT"],
                 colors=["lightgray", "skyblue", "lightcoral", "lavender",
                 "mediumpurple", "moccasin"])

    ax.set_title("Power Consumption")
    ax.legend()
    ax.set_xticks(xt)
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power (MW)")
    fig = ax.get_figure()
    fig.savefig("Powah_c_stacked.png", format="png", dpi=300)
    plt.close(fig)

    # Co2
    df = pd.read_csv("./df_co.csv")
    trd = df[["Co2CapPcc", "Co2CapDacFlue"]]
    #: Calculate Emissions.
    trd["NotCaptCo2"] = df["Co2Fuel"] - trd.sum(axis=1)
    trd["Co2CapDacAir"] = df["Co2CapDacAir"]
    #: Compute the maximum
    trd["Co2FuelpAir"] = df["Co2Fuel"] + trd["Co2CapDacAir"]
    max_co = max(trd["Co2FuelpAir"])
    #: I don't remember why I've put this.
    trd.loc[trd["NotCaptCo2"] < 0, "NotCaptCo2"] = 0.0

    fig, ax = plt.subplots()
    ax.stackplot(r0, trd["Co2CapPcc"].iloc[r0],
                 trd["Co2CapDacFlue"].iloc[r0],
                 trd["NotCaptCo2"].iloc[r0],
                 trd["Co2CapDacAir"].iloc[r0],
                 labels=["Co2CapPcc", "Co2CapDacFlue", "Emissions",
                 "Co2CapDacAir"],
                 colors=["lightgray", "skyblue", "lightcoral", "lavender"])
    ax.set_title("CO2 Capture")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2/hr")
    ax.set_ylim(0, max_co * 1.01)
    ax.legend()
    ax.set_xticks(xt)
    fig.savefig("co2capture.png", format="png", dpi=300)
    plt.close(fig)


    # Co2 dac only
    fig, ax = plt.subplots()
    ax.stackplot(r0, trd["Co2CapDacFlue"].iloc[r0],
                 trd["NotCaptCo2"].iloc[r0],
                 trd["Co2CapDacAir"].iloc[r0],
                 labels=["Co2CapDacFlue", "NotCaptCo2", "Co2CapDacAir"],
                 colors=["skyblue", "lightcoral", "lavender"])
    ax.set_title("CO2 Capture DAC only")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Tonne CO2/hr")
    ax.legend()
    ax.set_xticks(xt)
    fig.savefig("co2daconly.png", format="png", dpi=300)
    plt.close(fig)

    # Steam
    df = pd.read_csv("./df_steam.csv")
    h = df.index
    df["DacTotal"] = df["SteaUseDacFlue"] + df["SteaUseDacAir"]
    x = np.arange(hour0, hourf)
    w = 0.35
    fig, ax = plt.subplots()
    ax.stackplot(r0,
        df["SteaUsePcc"].iloc[r0],
        df["PccSteaSlack"].iloc[r0],
        labels=["SteamUsedPcc", "SteamAvailablePcc"],
                 colors=["skyblue", "lightcoral"])

    ax.set_title("Steam Used Pcc")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU/hr)")
    ax.legend()
    ax.set_xticks(xt)
    fig = ax.get_figure()
    fig.savefig("steamPcc.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    ax.stackplot(r0,
        df["DacTotal"].iloc[r0], df["DacSteaSlack"].iloc[r0],
                 labels=["SteamUsedDac", "SteamAvailableDac"],
                 colors=["skyblue", "lightcoral"])

    ax.set_title("Steam Used Dac")
    ax.set_xlabel("Hour")
    ax.set_ylabel("Steam (MMBTU/hr)")
    ax.legend()
    ax.set_xticks(xt)
    fig = ax.get_figure()
    fig.savefig("steamDac.png", format="png", dpi=300)
    fig.clf()
    ax.cla()

    fig, ax = plt.subplots()
    ax.stackplot(r0,
        df["DacSteaBaseDuty"].iloc[r0], df["SideSteaDac"].iloc[r0],
                 labels=["Nominal Heat", "Additional Heat (LP)"],
                 colors=["skyblue", "lightcoral"])
    ax.legend()
    ax.set_xticks(xt)
    ax.set_xlabel("Hour")
    ax.set_ylabel("Heat (MMBTU/hr)")
    ax.set_title("Dac Steam Source")
    plt.savefig("dac_Stea.png", format="png", dpi=300)
    plt.close(fig)

    # Costs
    fig, ax = plt.subplots()

    df = pd.read_csv("./df_cost.csv")
    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo-"] = abs(df.loc[:, "cCo2Em"])
    df.loc[df.loc[:, "cCo2Em"] >= 0, "cCo-"] = 0.0  # Set the remaining to zero

    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo2Em"] = 0.0
    #df.to_csv("adbreak.csv")
    w = 0.25
    x = np.arange(hour0, hourf)
    ax.bar(x - 2 * w, df["cNG"].iloc[r0],
        width=w,
        color="skyblue",
        align="edge",
        label="Natural Gas")
    ax.bar(x - w, df["cTransp"].iloc[r0],
        width=w,
        color="lavender",
        align="edge",
        label="Transportation")
    ax.bar(x, df["cCo-"].iloc[r0],
        width=w,
        color="lightgray",
        align="edge",
        label="Negative Emissions")
    ax.bar(x + w, df["cCo2Em"].iloc[r0],
        width=w,
        color="lightcoral",
        align="edge",
        label="Emissions")

    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD/hr")
    ax.legend()
    ax.set_xticks(xt)
    fig = ax.get_figure()
    fig.savefig("cost.png", format="png", dpi=300)
    plt.close(fig)

    #: Costs.
    fig, ax = plt.subplots()


    ax.stackplot(r0,
        df["cNG"].iloc[r0],
        df["cTransp"].iloc[r0],
        df["cCo2Em"].iloc[r0],
        labels=["Nat. Gas", "Transport.", "Emissions"],
        colors=["skyblue", "lavender", "lightcoral"])

    #: Sum of cost
    s_c = df["cNG"] + df["cTransp"] + df["cCo2Em"]
    s_max = max(s_c)
    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD/hr")
    ax.legend()
    ax.set_xticks(xt)
    ax.set_ylim(0, s_max)
    fig.savefig("cost_stacked.png", format="png", dpi=300)
    plt.close(fig)

    #: Negative emissions.
    fig, ax = plt.subplots()
    ax.stackplot(r0,
        df["cCo-"].iloc[r0],
        labels=["Negative Emissions"],
        colors=["crimson"])


    ax.set_title("Cost")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD/hr")
    ax.legend()
    ax.set_xticks(xt)
    ax.set_ylim(0, s_max)
    fig.savefig("cost_stacked_negem.png", format="png", dpi=300)
    plt.close(fig)

    fig, ax = plt.subplots()
    profit = df.loc[:, "PowSales"] + df.loc[:, "cCo-"] - df.loc[:, "cCo2Em"] - df.loc[:, "cNG"] - df.loc[:, "cTransp"]

    profit.to_csv("profit.csv")

    profitp = profit.copy()
    profitp.loc[profitp.iloc[:] < 0] = 0
    profitn = profit.copy()
    profitn.loc[profitn.iloc[:] >= 0] = 0
    #: Get the maximum and minimum profit so we can scale the y-axis.
    min_profit = min(profitn)
    max_profit = max(profitp)
    ax.bar(r0, profitp.iloc[r0],
        color="cornflowerblue",
        label="gains",
        align="edge",
        width=0.8)
    ax.bar(r0, profitn.iloc[r0],
        color="lightcoral",
        label="losses",
        align="edge",
        width=0.8)
    ax.set_title("Profit")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD/hr")
    ax.set_ylim(min_profit * 1.1, max_profit * 1.01)
    ax.hlines(max_profit, min(r0), max(r0),
        linestyle="dashed",
        label="Max. Profit",
        color="cornflowerblue")
    ax.hlines(min_profit, min(r0), max(r0),
        linestyle="dashed",
        label="Max. Loss",
        color="lightcoral")

    ax.legend()
    ax.set_xticks(xt)
    plt.axhline(0)
    #profit.to_csv("whatnot.csv")

    fig.savefig("profit.png", format="png", dpi=300)
    plt.close(fig)
    #




def all_long_loads():
    df = pd.read_csv("./df_pow.csv")
    dfb = pd.read_csv("./df_pow_price.csv")

    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)

    ax.step(df.index, df["yGasTelecLoad"],
        color="lightcoral", label="GT Load")

    ax.set_xlabel("Hour")
    ax.set_ylabel("\% Load")
    ax.set_title("Load / Price")
    axb = ax.twinx()

    axb.plot(dfb.index, dfb["price"],
        color="mediumpurple", label="Price USD/MWh")

    ax.legend()
    plt.savefig("GTLoadAlllong.png")
    plt.close(fig)

def all_long_profit():
    df = pd.read_csv("./df_cost.csv")
    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo-"] = abs(df.loc[:, "cCo2Em"])
    df.loc[df.loc[:, "cCo2Em"] >= 0, "cCo-"] = 0.0  # Set the remaining to zero

    df.loc[df.loc[:, "cCo2Em"] < 0, "cCo2Em"] = 0.0

    profit = df.loc[:, "PowSales"] + df.loc[:, "cCo-"] - df.loc[:, "cCo2Em"] - df.loc[:, "cNG"] - df.loc[:, "cTransp"]

    profitp = profit.copy()
    profitp.loc[profitp.iloc[:] < 0] = 0
    profitn = profit.copy()
    profitn.loc[profitn.iloc[:] >= 0] = 0
    #: Get the maximum and minimum profit so we can scale the y-axis.
    min_profit = min(profitn)
    max_profit = max(profitp)

    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)
    ax.bar(profitp.index, profitp, color="cornflowerblue", label="gains")
    ax.bar(profitn.index, profitn, color="lightcoral", label="losses")

    ax.legend()
    ax.set_title("Profit")
    ax.set_xlabel("Hour")
    ax.set_ylabel("USD/hr")

    fig.savefig("profit_all.png")

def all_long_halloc():
    df = pd.read_csv("./df_steam.csv")

    df["DacTotal"] = df["SteaUseDacFlue"] + df["SteaUseDacAir"]

    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)
    ax.stackplot(df.index,
        df["DacSteaBaseDuty"], df["SideSteaDac"],
                 labels=["Nominal Heat", "Additional Heat (LP)"],
                 colors=["pink", "skyblue"])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Heat (MMBTU/hr)")
    ax.set_title("Dac Steam Source")
    plt.savefig("dacstea_all_long.png", format="png")
    plt.close(fig)

if __name__ == "__main__":
    #all_long_loads()
    #all_long_profit()
    #all_long_halloc()
    main()



