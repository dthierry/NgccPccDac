import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors
from random import *

def main():
    directory = "./"

    df = pd.read_csv(directory + "df_binary.csv")
    k = ["y00", "y01", "y02", "y03", "y04", "y10", "y11", "y12", "y13", "y14"]
    d = dict()
    for j in k:
        d[j] = []
    for j in k:
        i0 = 0
        for i in df.index:
            if df.loc[i, j] > 0.5:
                i0 += 1
            else:
                if i0 > 1:
                    d[j].append((i - i0, i0))
                i0 = 0
        if i0 > 1:
            d[j].append((i - i0, i0))
    print(d)

    selected_colours = ["#dc143c", "#ff6347", "#ff7f50", "#ff8c00", "#ffa500"]
    selected_colours.reverse()
    lc = []
    c = mcolors.CSS4_COLORS
    for i in c.keys():
        lc.append(c[i])
    fig, ax = plt.subplots(nrows=2, ncols=1,
            figsize=(16, 4),
            dpi=300,
            sharex=True)
    fig.suptitle("Unit Schedule")
    ax[1].set_xlabel("Hour")

    vw = 10
    i0 = 0
    k0 = ["y00", "y01", "y02", "y03", "y04"]
    for j in k0:
        ax[0].broken_barh(d[j], (vw * i0, vw),
                label=j,
                facecolors=selected_colours[i0],
                hatch="\\",
                alpha=0.9)
        i0 += 1
    ax[0].set_yticks([5, 15, 25, 35, 45])
    ax[0].set_yticklabels(["OffLine", "ColdSync", "WarmSync", "Soak", "Dispatch"], rotation=45)
    ax[0].grid(True)
    ax[0].invert_yaxis()
    ax[0].set_title("Unit a")

    i0 = 0
    k0 = ["y10", "y11", "y12", "y13", "y14"]
    for j in k0:
        ax[1].broken_barh(d[j], (vw * i0, vw),
                label=j,
                facecolors=selected_colours[i0],
                hatch="/",
                alpha=0.9)
        i0 += 1
    ax[1].set_yticks([5, 15, 25, 35, 45])
    ax[1].set_yticklabels(["OffLine", "ColdSync", "WarmSync", "Soak", "Dispatch"], rotation=45)
    ax[1].grid(True)
    ax[1].invert_yaxis()
    ax[1].set_title("Unit b")

    plt.savefig("schedule_5.png")
    #ax.hlines(0.0, min(df.index)-1, max(df.index)+1, color="k", linestyle=(0, (1, 10)))
    #ax.step(df.index, df["y00"], label="Off_a", color="navy", linestyle="dotted", marker=".", fillstyle="none")
    #ax.step(df.index, df["y10"], label="Off_b", color="navy", linestyle="dashed")
    #ax.hlines(1.2, min(df.index)-1, max(df.index)+1, color="k", linestyle=(0, (1, 10)))
    #ax.step(df.index, df["y01"] + 1.2, label="ColdStart_a", color="dodgerblue", linestyle="dotted", marker=".", fillstyle="none")
    #ax.step(df.index, df["y11"] + 1.2, label="ColdStart_b", color="dodgerblue", linestyle="dashed")
    #ax.hlines(2.4, min(df.index)-1, max(df.index)+1, color="k", linestyle=(0, (1, 10)))
    #ax.step(df.index, df["y02"] + 2.4, label="WarmStart_a", color="tomato", linestyle="dotted", marker=".", fillstyle="none")
    #ax.step(df.index, df["y12"] + 2.4, label="WarmStart_b", color="tomato",  linestyle="dashed")
    #ax.hlines(3.6, min(df.index)-1, max(df.index)+1, color="k", linestyle=(0, (1, 10)))
    #ax.step(df.index, df["y03"] + 3.6, label="Dispatch_a", color="maroon", linestyle="dotted", marker=".", fillstyle="none")
    #ax.step(df.index, df["y13"] + 3.6, label="Dispatch_b", color="maroon",  linestyle="dashed")
    #ax.spines['top'].set_visible(False)
    #ax.spines['right'].set_visible(False)

    #ax.spines['left'].set_visible(False)
    #ax.legend()
    #ax.set_yticks([])
    #ax.set_title("Switches")
    #ax.set_xlabel("Hour")
    #plt.savefig("binary.png", format="png", transparent=False)
    #plt.clf()


if __name__ == "__main__":
    main()

