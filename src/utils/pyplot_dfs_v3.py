#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd


def main():
    df = pd.read_csv("../mods/df_dac.csv")
    labels = [r"Frsh", r"Sat", r"Abs-0", r"Abs-1", r"Abs-2", r"Reg-0", r"Reg-1"]
    fig, ax = plt.subplots()

    a = df["sF"]
    b = df["sS"]
    c = df["vAbs"]
    d = df["a1"]
    e = df["a2"]
    f = df["vReg"]
    g = df["aR1"]

    to_abs = a + g
    to_reg = b + e
    a1 = d


    ax.bar([i for i in range(df.shape[0])], to_abs, label="avail Abs")
    ax.bar([i for i in range(df.shape[0])], a1, bottom = to_abs, label="1-hour Abs")
    #ax.bar([i for i in range(df.shape[0])], df["vAbs"], bottom = a + b, label=labels[2])
    ax.bar([i for i in range(df.shape[0])], to_reg, bottom = to_abs + a1, label="avail Reg")
    #ax.bar([i for i in range(df.shape[0])], df["a2"], bottom = a + b + c + d, label=labels[4])
    #ax.bar([i for i in range(df.shape[0])], df["vReg"], bottom = a + b + c + d, label=labels[5])
    #ax.bar([i for i in range(df.shape[0])], df["aR1"], bottom = a + b + c + d + e + f, label=labels[6])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorb")
    plt.show()

if __name__ == "__main__":
    main()



