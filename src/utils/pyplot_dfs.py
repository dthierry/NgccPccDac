#!/usr/bin/env python3

import matplotlib.pyplot as plt
import pandas as pd
import sys

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

    remain_frs = a + g - c
    remain_sat = b + e - f
    
    h = df.index


    ax.bar(h, remain_frs, label="avail Fresh")
    ax.bar(h, c, bottom = remain_frs, label="vAbs")
    ax.bar(h, d, bottom = remain_frs + c, label="1-h")
    ax.bar(h, remain_sat, bottom = remain_frs + c + d, label="avail Sat")
    ax.bar(h, f, bottom = remain_frs + c + d + remain_sat, label="vReg")
    #ax.bar([i for i in range(df.shape[0])], df["vAbs"], bottom = a + b, label=labels[2])
    #ax.bar([i for i in range(df.shape[0])], to_reg, bottom = to_abs + a1, label="avail Reg")
    #ax.bar([i for i in range(df.shape[0])], df["a2"], bottom = a + b + c + d, label=labels[4])
    #ax.bar([i for i in range(df.shape[0])], df["vReg"], bottom = a + b + c + d, label=labels[5])
    #ax.bar([i for i in range(df.shape[0])], df["aR1"], bottom = a + b + c + d + e + f, label=labels[6])
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Mass of Sorbent")
    plt.savefig("bars.png")
    plt.close()
    #sys.exit()
    df = pd.read_csv("../mods/df_pow.csv")

    h = df.index

    fig, ax = plt.subplots()
    ax.plot(h, df["Demand"], marker="o", label="Demand")
    ax.plot(h, df["PowGross"], marker="x", label="PowGross")
    ax.plot(h, df["PowOut"], marker=".", label="PowOut")
    ax.plot(h, df["PowUsePcc"], marker=".", label="PowUsePcc")
    ax.plot(h, df["PowUseDac"], marker=".", label="PowUseDac")
    ax.legend()
    ax.set_xlabel("Hour")
    ax.set_ylabel("Power")
    ax.set_title("Power")
    plt.savefig("Pow.png")
    plt.close()

if __name__ == "__main__":
    main()



