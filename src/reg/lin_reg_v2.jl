using DataFrames
using CSV
using GLM
using Lathe

df_steam_t = DataFrame(CSV.File("../resources/data3.csv"))
coln_steam = Symbol[]
for i in string.(names(df_steam_t))
    i = replace(strip(i), " " => "_")
    i = replace(i, "-" => "")
    i = replace(i, "/" => "")
    i = replace(i, "(" => "")
    i = replace(i, ")" => "")
    i = replace(i, "%" => "")
    i = replace(i, "," => "")
    i = replace(i, "*" => "")
    i = replace(i, "+" => "")
    println(i)
    push!(coln_steam, Symbol(i))
end

rename!(df_steam_t, coln_steam)
#LP_Turbine_Power_kW
#Condenser_Duty_MMBTUhr
#DAC_Steam_Duty_MMBTUhr
#Total_ST_and_BOP_Auxiliary_Loads_kW
formulasSteamT = FormulaTerm[]
#
fm0st = @formula(LP_Turbine_Power_kW ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasSteamT, fm0st)
fm1st = @formula(Duty_of_CC_Reboiler_MMBTUhr ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasSteamT, fm1st)
fm2st = @formula(DAC_Steam_Duty_MMBTUhr ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasSteamT, fm2st)
fm3st = @formula(Total_ST_and_BOP_Auxiliary_Loads_kW ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasSteamT, fm3st)
coef_steam_df = DataFrame(y = String[], b = Float64[], a = Float64[])
for i in formulasSteamT
    linReg = lm(i, df_steam_t)
    y = string(terms(i)[1])
    b = coef(linReg)[1]
    a = coef(linReg)[2]
    push!(coef_steam_df, (y, b, a))
    println(linReg)
    println(deviance(linReg))
    println(coef(linReg))
end

CSV.write("steam_coeffs_v3.csv", coef_steam_df)


