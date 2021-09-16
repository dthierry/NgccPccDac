import pandas as pd
import matplotlib.pyplot as plt

def main():
    directory = "./"

    df = pd.read_csv(directory + "df_binary.csv")
    fig, ax = plt.subplots(figsize=(16, 2), dpi=300)

    ax.hlines(0.0, min(df.index)-1, max(df.index)+1, color="k")
    ax.step(df.index, df["y00"], label="Off_a", color="lightcoral", linestyle="dotted", marker=".", fillstyle="none")
    ax.step(df.index, df["y10"], label="Off_b", color="lightcoral", linestyle="dashed")
    ax.hlines(1.2, min(df.index)-1, max(df.index)+1, color="k")
    ax.step(df.index, df["y01"] + 1.2, label="Warmup_a", color="coral", linestyle="dotted", marker=".", fillstyle="none")
    ax.step(df.index, df["y11"] + 1.2, label="Warmup_b", color="coral", linestyle="dashed")
    ax.hlines(2.4, min(df.index)-1, max(df.index)+1, color="k")
    ax.step(df.index, df["y02"] + 2.4, label="On_a", color="skyblue", linestyle="dotted", marker=".", fillstyle="none")
    ax.step(df.index, df["y12"] + 2.4, label="On_b", color="skyblue",  linestyle="dashed")
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    #ax.spines['bottom'].set_visible(False)
    ax.spines['left'].set_visible(False)
    ax.legend()
    ax.set_yticks([])
    ax.set_title("Switches")
    ax.set_xlabel("Hour")
    plt.savefig("binary.png", format="png", transparent=True)
    plt.clf()


if __name__ == "__main__":
    main()

