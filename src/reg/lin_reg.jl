using DataFrames
using CSV
using GLM
using Lathe
using Plots


df_gas = DataFrame(CSV.File("../resources/data1.csv"))

colnames = Symbol[]
for i in string.(names(df_gas))
    i = replace(strip(i), " " => "_")
    i = replace(i, "-" => "")
    i = replace(i, "/" => "")
    i = replace(i, "(" => "")
    i = replace(i, ")" => "")
    i = replace(i, "%" => "")
    i = replace(i, "," => "")
    i = replace(i, "*" => "")
    println(i)
    push!(colnames, Symbol(i))
    #push!(colnames, Symbol(replace(replace(replace(strip(i), " " => "_"), "-" => "_"), "/" => "_")))
end

rename!(df_gas, colnames)
println(names(df_gas))
scplot = scatter(df_gas["Percent_of_Gas_Turbine_Electrical_Load"],
                 df_gas["Electrical_Power_MW"])

formulasGasT = FormulaTerm[]

fm0 = @formula(Electrical_Power_MW ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasGasT, fm0)
fm1 = @formula(Natural_Gas_Flow_lbhr ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasGasT, fm1)
fm2 = @formula(CO2_Emissions_lbhr ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasGasT, fm2)
fm3 = @formula(HP_Turbine_Power_kW ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasGasT, fm3)
fm4 = @formula(IP_Turbine_Power_kW ~ Percent_of_Gas_Turbine_Electrical_Load)
push!(formulasGasT, fm4)
fm5 = @formula(Total_kW ~ Percent_of_Gas_Turbine_Electrical_Load) # auxiliary
push!(formulasGasT, fm5)

coefReg = Vector{Float64}[]
coef_gas_df = DataFrame(y = String[], b = Float64[], a = Float64[])
for i in formulasGasT
    linReg = lm(i, df_gas)
    y = string(terms(i)[1])
    b = coef(linReg)[1]
    a = coef(linReg)[2]
    push!(coef_gas_df, (y, b, a))
    println(linReg)
    println(deviance(linReg))
    println(coef(linReg))
end

CSV.write("gas_coeffs.csv", coef_gas_df)

df_steam_t = DataFrame(CSV.File("../resources/data2.csv"))
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
fm1st = @formula(Condenser_Duty_MMBTUhr ~ Percent_of_Gas_Turbine_Electrical_Load)
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

CSV.write("steam_coeffs.csv", coef_steam_df)


