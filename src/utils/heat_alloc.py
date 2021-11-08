import pandas as pd
import matplotlib.pyplot as plt

def plot_xalloc(folder):
    df = pd.read_csv(folder + "df_steam.csv")
    df["h_fracc"] = df["SideSteaDac"] / df["SideStea"]

    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)
    ax.plot(df.index, df["h_fracc"], marker="o", fillstyle="none", color="firebrick", linestyle="dashed")
    plt.savefig("heat_frac.png", format="png")
    plt.close(fig)

def alloc_load_price(folder):
    dfpow = pd.read_csv(folder + "df_pow.csv")
    dfprice = pd.read_csv(folder + "df_pow_price.csv")

    df = pd.read_csv(folder + "df_steam.csv")
    df["h_fracc"] = df["SideSteaDac"] / df["SideStea"] * 100

    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)


    #l1 = ax.plot(dfpow.index, dfpow["xActualLoad"],
    l1 = ax.plot(dfpow.index, dfpow["yGasTelecLoad"],
        color="lightcoral", label="% GT Load")

    l2 = ax.plot(df.index, df["h_fracc"],
            marker=None,
            fillstyle="none",
            color="firebrick",
            linestyle="dashed", label="% Heat DAC")

    ax.set_xlabel("Hour")
    ax.set_ylabel("%")
    ax.set_title("Load, DAC Heat fracc, Price")
    ax.set_ylim([-3, 103])
    axb = ax.twinx()

    l3 = axb.plot(dfprice.index, dfprice["price"],
        color="mediumpurple", label="Price")
    axb.set_ylabel("Price USD/MWh")

    lns = l1 + l2 + l3
    labs = [l.get_label() for l in lns]
    ax.legend(lns, labs, loc=0)

    plt.savefig("heat_load_price.png", format="png")
    plt.close(fig)


if __name__ == "__main__":
    folder = "./"
    # plot_xalloc(folder)
    alloc_load_price(folder)
