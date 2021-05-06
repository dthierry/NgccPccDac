using DataFrames
using CSV
using StatsPlots

df = DataFrame(CSV.File("../mods/df_dac.csv"))
print(df)

remain_abs = df.sF + df.a2 - df.vAbs
remain_reg = df.sS + df.aR1 - df.vReg

groupedbar([remain_abs df.vAbs df.a1 remain_reg df.vReg], bar_position=:stack)
xlabel!("Hour")
savefig("bars.pdf")
