# vim: set wrap
#: by David Thierry 2021
#: Set all the eqns to hslice - 1
using JuMP
using SCIP
using DataFrames
using CSV

#: Data frames section
#: Load parameters
# We want two dumb turbines.

df_gas = DataFrame(CSV.File("../reg/gas_coeffs.csv"))
df_steam_full_power = DataFrame(CSV.File("../reg/steam_coeffs.csv"))
df_steam_full_steam = DataFrame(CSV.File("../reg/steam_coeffs_v3.csv"))

#: Load Prices
df_pow_c = DataFrame(CSV.File("../resources/FLECCSPriceSeriesData.csv"))
df_ng_c = DataFrame(CSV.File("../resources/natural_gas_price.csv"))


#: Assign parameters

#: Gas parameters
bPowGasTeLoad = df_gas[1, 2]
aPowGasTeLoad = df_gas[1, 3]

bFuelEload = df_gas[2, 2]
aFuelEload = df_gas[2, 3]
lbcoToTonneco = 0.4535924 / 1000
bEmissFactEload = df_gas[3, 2] * lbcoToTonneco
aEmissFactEload = df_gas[3, 3] * lbcoToTonneco

bPowHpEload = df_gas[4, 2] / 1000  #: To scale the kW to MW
aPowHpEload = df_gas[4, 3] / 1000

bPowIpEload = df_gas[5, 2] / 1000
aPowIpEload = df_gas[5, 3] / 1000

bAuxRateGas = df_gas[6, 2] / 1000
aAuxRateGas = df_gas[6, 3] / 1000

#: Steam params
bCcRebDutyEload = df_steam_full_steam[2, 2]
aCcRebDutyEload = df_steam_full_steam[2, 3]

#: Full power gives you the min steam
bDacSteaBaseEload = df_steam_full_power[3, 2]  
aDacSteaBaseEload = df_steam_full_power[3, 3]

bSideSteaEload = df_steam_full_steam[3, 2] - df_steam_full_power[3, 2]
aSideSteaEload = df_steam_full_steam[3, 3] - df_steam_full_power[3, 3]

bAuxRateStea = df_steam_full_power[4, 2] / 1000
aAuxRateStea = df_steam_full_power[4, 3] / 1000

aLpSteaToPow = 78.60233832  # MMBtu to kwh

kwhToMmbtu = 3412.1416416 / 1e+06
#aSteaUseRateDacAir = 1944 * kwhToMmbtu
#aSteaUseRateDacFlue = 1944 * kwhToMmbtu
# 7 GJ/tonneCO
aSteaUseRateDacAir = 5 * (7 * 1e+06 / 3600) * kwhToMmbtu
aSteaUseRateDacFlue = 5 * (7 * 1e+06 / 3600) * kwhToMmbtu

aPowUseRateDacAir = 500 / 1000
aPowUseRateDacFlue = 250 / 1000
# 1 mmol/gSorb #
# per gCo/gSorb
gCogSorbRatio = 1e-03 * 44.0095

aSorbCo2CapFlue = 1 * gCogSorbRatio
aSorbCo2CapAir = gCogSorbRatio
#aSorbAmountFreshFlue = 176. * 10  # Tonne sorb
#aSorbAmountFreshAir = 176. * 10  # Tonne sorb

aSorbAmountFreshFlue = 176. * 10   # Tonne sorb (Max. heat basis)
aSorbAmountFreshAir = 3162.18 - 176. * 10  # Tonne sorb (Max. heat basis)


aCapRatePcc = 0.97
# 2.4 MJ/kg (1,050 Btu/lb) CO2 page 379/
#aSteaUseRatePcc = aSteaUseRateDacFlue * 0.2
#aSteaUseRatePcc = 2.4 * 1000 * 1000 / 3600 * kwhToMmbtu 
#println(aSteaUseRatePcc)
# aPowUseRatePcc = 0.173514487  # MWh/tonneCoi2 (old)
aSteaUseRatePcc = 2.69 + 0.0218 + 0.00127 # MMBTU/tonne CO2 (trimeric)
println(aSteaUseRatePcc)
aPowUseRatePcc = 0.047 # MWh/tonne CO2 (trimeric)

#: Horizon Lenght
tHorz = 24 * 30 * 1 - 1


#: Slices per hour
hSlice = 4  # the number of slices of a given hour
# There are tHorz - 1 slices
# Each slice has hSlice points, but only states have the 0th

# If there's several slices in an hour we kind of need to divide the
# hourly-based quantities :(



# Correction for low load
slopeFactor =  (0.01/ 0.1) / ((.95 - .75) / (0.9 - 0.6))

# Dictionaries with the disjunction parameters

## Slope
aPowGt = Dict(0 => 1, 1 => aPowGasTeLoad * slopeFactor, 2 => aPowGasTeLoad)
aFuel = Dict(0 => 1, 1 => aFuelEload, 2 => aFuelEload)
aEmis = Dict(0 => 1, 1 => aEmissFactEload, 2 => aEmissFactEload)
aAuxGt = Dict(0 => 1, 
    1 => aAuxRateGas * slopeFactor, 
    2 => aAuxRateGas)
aPowHp = Dict(0 => 1, 1 => aPowHpEload * slopeFactor, 
    2 => aPowHpEload)
aPowIp = Dict(0 => 1, 1 => aPowIpEload * slopeFactor, 
    2 => aPowIpEload)
aCcReb = Dict(
    0 => 1, 
    1 => aCcRebDutyEload * slopeFactor, 
    2 => aCcRebDutyEload)
aDacSb = Dict(0 => 1, 1 => aDacSteaBaseEload * slopeFactor, 
    2 => aDacSteaBaseEload)
aSideS = Dict(0 => 1, 1 => aSideSteaEload * slopeFactor, 2 => aSideSteaEload)
aAuxSt = Dict(0 => 1, 1 => aAuxRateStea * slopeFactor, 2 => aAuxRateStea)

ldics = ["aPowGt", "aFuel", "aEmis", "aAuxGt", "aPowHp", "aPowIp", "aCcReb", "aDacSb", "aSideS", "aAuxSt"]
println("Slopes")
for v in ldics
    s = Symbol(v)
    println(v, eval(s))
end

## b
bPowGt = Dict(0 => 0, 
    1 => 60 * (-aPowGt[1] + aPowGt[2]) + bPowGasTeLoad, 
    2 => bPowGasTeLoad)
bFuel = Dict(0 => 0, 1 => bFuelEload, 2 => bFuelEload)
bEmis = Dict(0 => 0, 1 => bEmissFactEload, 2 => bEmissFactEload)
bAuxGt = Dict(0 => 0, 
    1 => 60 * (-aAuxGt[1] + aAuxGt[2]) + bAuxRateGas, 
    2 => bAuxRateGas)
bPowHp = Dict(0 => 0, 
    1 => 60 * (-aPowHp[1] + aPowHp[2]) + bPowHpEload,
    2 => bPowHpEload)
bPowIp = Dict(0 => 0,
    1 => 60 * (-aPowIp[1] + aPowIp[2]) + bPowIpEload,
    2 => bPowIpEload
    )
bCcReb = Dict(0 => 0,
    1 => 60 * (-aCcReb[1] + aCcReb[2]) + bCcRebDutyEload,
    2 => bCcRebDutyEload)
bDacSb = Dict(0 => 0,
    1 => 60 * (-aDacSb[1] + aDacSb[2]) + bDacSteaBaseEload,
    2 => bDacSteaBaseEload)
bSideS = Dict(0 => 0,
    1 => 60 * (-aSideS[1] + aSideS[2]) + bSideSteaEload,
    2 => bSideSteaEload)
bAuxSt = Dict(0 => 0,
    1 => 60 * (-aAuxSt[1] + aAuxSt[2]) + bAuxRateStea,
    2 => bAuxRateStea)


ldics = ["bPowGt", "bFuel", "bEmis", "bAuxGt", "bPowHp", "bPowIp", "bCcReb", "bDacSb", "bSideS", "bAuxSt"]
println("InterC")
for v in ldics
    s = Symbol(v)
    println(v, eval(s))
end


# USD/MWh
pow_price =(df_pow_c[!, "MiNg_150_ERCOT"])  # USD/MWh

# pow_price =(df_pow_c[!, "MiNg_150_PJM-W"])  # USD/MWh
#: Natural gas price
# 0.056 lb/cuft STP
#std_w_ng1000cuft = 0.056 * 1000
#cNgPerLbUsd = (3.5 / 1000) / 0.056

# Cost of natural gas
cNgPerMmbtu = 3.5

m = Model()

# aPowUseRateComp = 0.279751187  # MWh/tonneCo2
aPowUseRateComp = 0.076 # MWh/tonneCo2 (Trimeric)

# Other costs
cCostInvCombTurb = 1e+02
cCostInvSteaTurb = 1e+02
cCostInvTransInter = 1e+02
cCostInvPcc = 1e+02
cCostInvDac = 1e+03
cCostInvComp = 1e+01

# Cost parameters.
cEmissionPrice = 1.5e+02 # USD/tonne CO2
cCo2TranspPrice = 1e+00
pCo2Credit = 1e+00


#vCapCombTurb = 3.
vCapSteaTurb = 2.
vCapTransInter = 5.
vCapPcc = 20.
vCapComp = 1000.
# Capital Cost DAC USD/tCo2/yr 
cCostInvDacUsdtCo2yr = 750
cCostFixedDacUsdtCo2yr = 25
cCostVariableDacUsdtCo2yr = 12

nMod = 2
nUnit = 1  # We go from 0 to 1

# 0 -> off
# 1 -> warm-up
# 2 -> on

# 0 for off 2 for other ones.
extrPoint = Dict(0 => 0, 1 => 0:1, 2 => 0:1)
# Convex weight
@variable(m, 0 <= lambda[0:tHorz, 0:nUnit, i=0:nMod, extrPoint[i]] <= 1)
# On/Off
@variable(m, y[0:tHorz, 0:nUnit, 0:nMod], Bin, start = 0)  # On and off
# Transition
@variable(m, z[0:tHorz, 0:nUnit, j1 = 0:nMod, j2 = 0:nMod], Bin, start = 0)

for i in 0:tHorz
    for j in 0:nUnit
        set_start_value(y[i, j, 1], 1)
    end
end

# "Actual variables power, fuel, etc."
@variable(m, 0 <= xActualLoad[0:tHorz] <= 100)

@variable(m, 0 <= xPowGasTur[0:tHorz])
@variable(m, 0 <= xPowGross[0:tHorz])
@variable(m, 0 <= xPowOut[0:tHorz])

@variable(m, 0 <= xAuxPowGasT[0:tHorz])

# Steam Turbine
@variable(m, 0 <= xPowHp[0:tHorz])
@variable(m, 0 <= xPowIp[0:tHorz])
@variable(m, 0 <= xPowLp[0:tHorz])

@variable(m, 0 <= xFuel[0:tHorz])
@variable(m, 0 <= xCo2Fuel[0:tHorz])
@variable(m, 0 <= xDacSteaDuty[0:tHorz])


@variable(m, 0 <= xCcRebDuty[0:tHorz])
@variable(m, 0 <= xDacSteaBaseDuty[0:tHorz])

@variable(m, 0 <= xAllocSteam[0:tHorz])
@variable(m, 0 <= xSteaPowLp[0:tHorz])
@variable(m, 0 <= xSideSteaDac[0:tHorz])

# You still have a single steam power generation, 
# so what is the point of
# going below 30?
@variable(m, 0 <= xPowSteaTur[0:tHorz])
@variable(m, 0 <= xAuxPowSteaT[0:tHorz])

# Unit load

# Disagretated variables
@variable(m, xLoadD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xPowGtD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xFuelD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xEmisD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xAuxGtD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xPowHpD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xPowIpD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xPccRebD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xDacSbD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xAllocD[0:tHorz, 0:nUnit, 0:nMod])
@variable(m, 0 <= xAuxStD[0:tHorz, 0:nUnit, 0:nMod])

# Per unit variables
@variable(m, 0 <= xLoadU[0:tHorz, 0:nUnit] <= 100)
@variable(m, 0 <= xPowGtU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xFuelU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xEmisU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xAuxGtU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xPowHpU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xPowIpU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xPccRebU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xDacSbU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xAllocU[0:tHorz, 0:nUnit])
@variable(m, 0 <= xAuxStU[0:tHorz, 0:nUnit])

# Pcc
#@variable(m, 0 <= xCo2CapPcc[0:tHorz - 1] <= vCapPcc)
@variable(m, 0 <= xCo2CapPcc[0:tHorz])
@variable(m, 0 <= xSteaUsePcc[0:tHorz])
@variable(m, 0 <= xPowUsePcc[0:tHorz])
@variable(m, 0 <= xCo2PccOut[0:tHorz])

@variable(m, 0 <= vCo2PccVent[0:tHorz])
@variable(m, 0 <= xCo2DacFlueIn[0:tHorz])
@variable(m, 0 <= xPccSteaSlack[0:tHorz])

# Dac-Flue, takes one time slot for adsorption
@variable(m, 0 <= xA0Flue[0:tHorz, 0:hSlice-1]) # Kind of input 
@variable(m, 0 <= xA1Flue[0:tHorz, 0:hSlice]) # State

@variable(m, 0 <= xR0Flue[0:tHorz, 0:hSlice-1])  # Kind of input
@variable(m, 0 <= xR1Flue[0:tHorz, 0:hSlice])  # State

@variable(m, 0 <= xFflue[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xSflue[0:tHorz, 0:hSlice])  # State

@variable(m, 0 <= xCo2CapDacFlue[0:tHorz, 0:hSlice-1])
@variable(m, 0 <= xSteaUseDacFlue[0:tHorz, 0:hSlice-1])
@variable(m, 0 <= xPowUseDacFlue[0:tHorz, 0:hSlice-1])
@variable(m, 0 <= xCo2DacVentFlue[0:tHorz])

# Dac-Air, takes two time slots for adsorption
@variable(m, 0 <= xA0Air[0:tHorz, 0:hSlice-1]) # Kind of input
@variable(m, 0 <= xA1Air[0:tHorz, 0:hSlice]) # State
@variable(m, 0 <= xA2Air[0:tHorz, 0:hSlice]) # State

@variable(m, 0 <= xR0Air[0:tHorz, 0:hSlice-1])  # Kind of input

@variable(m, 0 <= xR1Air[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xFair[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xSair[0:tHorz, 0:hSlice])  # State


@variable(m, 0 <= xCo2CapDacAir[0:tHorz, 0:hSlice-1])
@variable(m, 0 <= xSteaUseDacAir[0:tHorz, 0:hSlice-1])
@variable(m, 0 <= xPowUseDacAir[0:tHorz, 0:hSlice-1])

@variable(m, 0 <= xDacSteaSlack[0:tHorz])
# DAC hourly capacity
#
# CO2 compression
@variable(m, 0 <= xCo2Comp[0:tHorz])
@variable(m, 0 <= xPowUseComp[0:tHorz])
#@variable(m, 0 <= vCapComp)
@variable(m, xCo2Vent[0:tHorz])  # This used to be only positive.

@variable(m, 0 <= xAuxPow[0:tHorz])

# Constraints
# Op mode
# Down times
# Up times

# Disjunction 0 (off)

extreme_d_0 = [0]
extreme_d_1 = [20.0, 50.0]
extreme_d_2 = [60.0, 100.0]

ep_list = [extreme_d_0, extreme_d_1, extreme_d_2]

# Convex combination
@constraint(m, cConvxEq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    sum(lambda[i, j, mod, k] * ep_list[mod + 1][k + 1] for k in extrPoint[mod]) 
    == xLoadD[i, j, mod]  # There is only a single extreme
    )

# jth mode
# Lambda constraint
@constraint(m, xLambdaEq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    sum(lambda[i, j, mod, k] for k in extrPoint[mod]) == y[i, j, mod]
    )

# Big M
@constraint(m, bmconEq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xLoadD[i, j, mod] <= maximum(ep_list[mod + 1])* y[i, j, mod]
    )

# Overall Disjunction

@constraint(m, gasLeq[i = 0:tHorz, j = 0:nUnit],
    xLoadU[i, j] == sum(xLoadD[i, j, mod] for mod in 0:nMod)
    )

@constraint(m, sumyEq[i = 0:tHorz,  j = 0:nUnit],
    sum(y[i, j, mod] for mod in 0:nMod) == 1
    )

# Switch
@constraint(m, switchConEq[i = 1:tHorz, j = 0:nUnit, mod = 0:nMod],
    sum(z[i, j, k, mod] for k in 0:nMod) - 
    sum(z[i, j, mod, k] for k in 0:nMod) 
    == y[i, j, mod] - y[i - 1, j, mod])

# Forbidden
# from off to full
@constraint(m, forbConOffFullEq[i = 0:tHorz, j = 0:nUnit],
    z[i, j, 0, 2] == 0)
# from full to warm-up
@constraint(m, forbConEq2[i = 0:tHorz, j = 0:nUnit],
    z[i, j, 2, 1] == 0)
# from warm-up to off
#@constraint(m, forbConwarmpuoff[i = 0:tHorz],
#    z[i, 1, 0] == 0)

# Ramping Constraints
rup = [0, 15, 30]
rdown = [0, 15, 30]
# good
#@constraints(m, begin 
#    rampup1eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i+1, j, 1] - xLoadD[i, j, 1] <= rup[2] + maximum(ep_list[1 + 1]) * (y[i+1, j, 1] - y[i, j, 1]) 
#    rampup2eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i+1, j, 2] - xLoadD[i, j, 2] <= rup[3] + maximum(ep_list[1 + 2]) * (y[i+1, j, 1] - y[i, j, 1]) 
#end)

@constraints(m, begin 
    rampup1eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i+1, j, 1] - xLoadD[i, j, 1] <= rup[2] + (minimum(ep_list[1 + 1])-1) * (y[i+1, j, 1] - y[i, j, 1]) 
    rampup2eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i+1, j, 2] - xLoadD[i, j, 2] <= rup[3] + (minimum(ep_list[1 + 2])-1) * (y[i+1, j, 2] - y[i, j, 2]) 
end)


@constraints(m, begin 
    rampdo1eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i, j, 1] - xLoadD[i+1, j, 1] <= rdown[2] + (minimum(ep_list[1 + 1])-1) * (y[i, j, 1] - y[i+1, j, 1]) 
    rampdo2eq[i=0:tHorz-1, j=0:nUnit], xLoadD[i, j, 2] - xLoadD[i+1, j, 2] <= rdown[3] + (minimum(ep_list[1 + 2])-1) * (y[i, j, 2] - y[i+1, j, 2]) 
end)

# Minimum stay 
KminOff = [[0, 36, 0], [0, 0, 0], [48, 0, 0]]

# off to on(1)
@constraint(m, minstay01[i = 1:tHorz, j = 0:nUnit],
    y[i, j, 1] >= sum(z[i - k, j, 0, 1] for k in 0:(24-1) if (i-k) >= 0)
    )
# on(2) to off
@constraint(m, minstay20[i = 1:tHorz, j = 0:nUnit],
    y[i, j, 0] >= sum(z[i - k, j, 2, 0] for k in 0:(48-1) if (i-k) >= 0)
    )


# Disagregated variables
@constraint(m, powgtdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xPowGtD[i, j, mod] == 
    (aPowGt[mod] * xLoadD[i, j, mod] + bPowGt[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, fueldeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xFuelD[i, j, mod] == 
    (aFuel[mod] * xLoadD[i, j, mod] + bFuel[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, emissdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xEmisD[i, j, mod] == 
    (aEmis[mod] * xLoadD[i, j, mod] + bEmis[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, auxgtdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xAuxGtD[i, j, mod] == 
    (aAuxGt[mod] * xLoadD[i, j, mod] + bAuxGt[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, powhpdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xPowHpD[i, j, mod] == 
    (aPowHp[mod] * xLoadD[i, j, mod] + bPowHp[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, powipdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xPowIpD[i, j, mod] == 
    (aPowIp[mod] * xLoadD[i, j, mod] + bPowIp[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, pccrebdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xPccRebD[i, j, mod] == 
    (aCcReb[mod] * xLoadD[i, j, mod] + bCcReb[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, dacsbtdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xDacSbD[i, j, mod] == 
    (aDacSb[mod] * xLoadD[i, j, mod] + bDacSb[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, allocstdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xAllocD[i, j, mod] == 
    (aSideS[mod] * xLoadD[i, j, mod] + bSideS[mod] * y[i, j, mod]) * 0.5
    )
@constraint(m, auxstdeq[i = 0:tHorz, j = 0:nUnit, mod = 0:nMod],
    xAuxStD[i, j, mod] == 
    (aAuxSt[mod] * xLoadD[i, j, mod] + bAuxSt[mod] * y[i, j, mod]) * 0.5
    )


# Unit variable constraints
@constraint(m, powgtueq[i = 0:tHorz, j = 0:nUnit],
    xPowGtU[i, j] == sum(xPowGtD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, fuelueq[i = 0:tHorz, j = 0:nUnit],
    xFuelU[i, j] == sum(xFuelD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, emissueq[i = 0:tHorz, j = 0:nUnit],
    xEmisU[i, j] == sum(xEmisD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, auxgtueq[i = 0:tHorz, j = 0:nUnit],
    xAuxGtU[i, j] == sum(xAuxGtD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, powhpueq[i = 0:tHorz, j = 0:nUnit],
    xPowHpU[i, j] == sum(xPowHpD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, powipueq[i = 0:tHorz, j = 0:nUnit],
    xPowIpU[i, j] == sum(xPowIpD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, pccrebueq[i = 0:tHorz, j = 0:nUnit],
    xPccRebU[i, j] == sum(xPccRebD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, dacsbtueq[i = 0:tHorz, j = 0:nUnit],
    xDacSbU[i, j] == sum(xDacSbD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, allocstueq[i = 0:tHorz, j = 0:nUnit],
    xAllocU[i, j] == sum(xAllocD[i, j, mod] for mod in 0:nMod)
    )
@constraint(m, auxstueq[i = 0:tHorz, j = 0:nUnit],
    xAuxStU[i, j] == sum(xAuxStD[i, j, mod] for mod in 0:nMod)
    )


# Half the load of each GT
@constraint(m ,eloadeq[i = 0:tHorz],
    xActualLoad[i] == sum(xLoadU[i, j] * 0.5 for j in 0:nUnit)
    )

@constraint(m, powGasTur[i = 0:tHorz], 
            xPowGasTur[i] == sum(xPowGtU[i, j] for j in 0:nUnit)
           )
# 
@constraint(m, fuelEq[i = 0:tHorz], 
            xFuel[i] == sum(xFuelU[i, j] for j in 0:nUnit)
           )
# 
@constraint(m, co2FuelEq[i = 0:tHorz], 
            xCo2Fuel[i] == sum(xEmisU[i, j] for j in 0:nUnit)
           )

@constraint(m, auxPowGasT[i = 0:tHorz],
            xAuxPowGasT[i] == sum(xAuxGtU[i, j] for j in 0:nUnit)
           )
# 
# Steam
# 
@constraint(m, powHpEq[i = 0:tHorz], 
            xPowHp[i] == sum(xPowHpU[i, j] for j in 0:nUnit)
           )
# 
@constraint(m, powIpEq[i = 0:tHorz], 
            xPowIp[i] == sum(xPowIpU[i, j] for j in 0:nUnit)
           )

# 
@constraint(m, powLpEq[i = 0:tHorz], 
            xPowLp[i] == xSteaPowLp[i] * aLpSteaToPow / 1000
           )
# 
@constraint(m, powerSteaEq[i = 0:tHorz], 
            xPowSteaTur[i] == 
            xPowHp[i] + xPowIp[i] + xPowLp[i]
           )

@constraint(m, ccRebDutyEq[i = 0:tHorz],
            xCcRebDuty[i] == sum(xPccRebU[i, j] for j in 0:nUnit)
           )

@constraint(m, dacSteaDutyEq[i = 0:tHorz],
            xDacSteaBaseDuty[i] == sum(xDacSbU[i, j] for j in 0:nUnit)
           )


@constraint(m, sideSteaEloadEq[i = 0:tHorz],
            xAllocSteam[i] == sum(xAllocU[i, j] for j in 0:nUnit)
           )

@constraint(m, sideSteaRatioEq[i = 0:tHorz],
            xAllocSteam[i] == xSideSteaDac[i] + xSteaPowLp[i]
           )

@constraint(m, availSteaDacEq[i = 0:tHorz],
            xDacSteaDuty[i] == xDacSteaBaseDuty[i] + xSideSteaDac[i]
           )

@constraint(m, auxPowSteaTEq[i = 0:tHorz],
            xAuxPowSteaT[i] == sum(xAuxStU[i, j] for j in 0:nUnit)
           )

# PCC
# 
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], 
#xCo2CapPcc[i] == aCo2PccCapRate * xCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz], 
            xCo2CapPcc[i] == aCapRatePcc * xCo2Fuel[i])
# 
@constraint(m, co2PccOutEq[i = 0:tHorz], 
            xCo2PccOut[i] == xCo2Fuel[i] - xCo2CapPcc[i])
# 
@constraint(m, co2DacFlueInEq[i = 0:tHorz], 
            xCo2DacFlueIn[i] == xCo2PccOut[i] - vCo2PccVent[i])
# 
# @constraint(m, co2CapPccIn[i = 0:tHorz - 1], xCo2CapPcc[i] <= vCapPcc)
# Dav: Sometimes there is not enough steam, so we have to relax this constraint 
@constraint(m, steamUsePccEq[i = 0:tHorz], 
            xSteaUsePcc[i] <= aSteaUseRatePcc * xCo2CapPcc[i])
# 
@constraint(m, powerUsePccEq[i = 0:tHorz], 
            xPowUsePcc[i] == aPowUseRatePcc * xCo2CapPcc[i]
           )

@constraint(m, pccSteaSlack[i = 0:tHorz], 
            xPccSteaSlack[i] == xCcRebDuty[i] - xSteaUsePcc[i])

# DAC-Flue
# Flue gas takes 15 minutes to saturation?
#: "State equation"
@constraint(m, a1dFlueEq[i = 0:tHorz, j=1:hSlice], 
            xA1Flue[i, j] == xA0Flue[i, j-1]
           )

#: "State equation"
@constraint(m, aRdFlueEq[i = 0:tHorz, j=1:hSlice], 
            xR1Flue[i, j] == xR0Flue[i, j-1]
           )
#: "State equation"
@constraint(m, storeFflueeq[i = 0:tHorz, j = 1:hSlice], 
            xFflue[i, j] == xFflue[i, j-1] - xA0Flue[i, j-1] + xR1Flue[i, j-1]
           )
#: "State equation"
@constraint(m, storeSflueeq[i = 0:tHorz, j = 1:hSlice], 
            xSflue[i, j] == xSflue[i, j-1] - xR0Flue[i, j-1] + xA1Flue[i, j-1]
           )
# Initial conditions
@constraint(m, icXa1FlueEq, xA1Flue[0, 0] == 0.)
@constraint(m, icAR1FlueEq, xR1Flue[0, 0] == 0.)
@constraint(m, capDacFlueEq, xFflue[0, 0] == aSorbAmountFreshFlue)
@constraint(m, icSsFlueEq, xSflue[0, 0] == 0.)
# End-point constraints we need to get rid of them and then put them back
@constraint(m, endXa1FlueEq, xA1Flue[tHorz, hSlice] == 0.)
@constraint(m, endAR1FlueEq, xR1Flue[tHorz, hSlice] == 0.)
@constraint(m, endDacFlueEq, xFflue[tHorz, hSlice] == aSorbAmountFreshFlue)
@constraint(m, endSsFlueEq, xSflue[tHorz, hSlice] == 0.)
#
#These dac related variables must start at 0 and end at 1-hslice
@constraint(m, co2CapDacFlueEq[i = 0:tHorz, j = 0:hSlice-1], 
            xCo2CapDacFlue[i, j] == 
            #aSorbCo2CapFlue * xR1Flue[i, j]
            aSorbCo2CapFlue * xA1Flue[i, j]
           )
#
@constraint(m, steamUseDacFlueEq[i = 0:tHorz, j = 0:hSlice-1], 
            xSteaUseDacFlue[i, j] == 
            #aSteaUseRateDacFlue * xCo2CapDacFlue[i, j]
            aSteaUseRateDacFlue * aSorbCo2CapFlue * xR1Flue[i, j]
           )
#
@constraint(m, powUseDacFlueEq[i = 0:tHorz, j = 0:hSlice-1], 
            xPowUseDacFlue[i, j] == aPowUseRateDacFlue * xCo2CapDacFlue[i, j]
           )

# DAC-Air
# Bluntly assume we can just take CO2 from air in pure form.
# "State equation"
@constraint(m, a1dAirEq[i = 0:tHorz, j = 1:hSlice], 
            xA1Air[i, j] == xA0Air[i, j - 1]
           )
# "State equation"
@constraint(m, a2dAirEq[i = 0:tHorz, j = 1:hSlice], 
            xA2Air[i, j] == xA1Air[i, j - 1]
           )
# "State equation"
@constraint(m, aRdAirEq[i = 0:tHorz, j = 1:hSlice], 
            xR1Air[i, j] == xR0Air[i, j - 1]
           )
# "State equation"
@constraint(m, storeFairEq[i = 0:tHorz, j = 1:hSlice], 
            xFair[i, j] == xFair[i, j-1] - xA0Air[i, j-1] + xR1Air[i, j-1]
           )
# "State equation"
@constraint(m, storeSaireq[i = 0:tHorz, j = 1:hSlice], 
            xSair[i, j] == xSair[i, j-1] - xR0Air[i, j-1] + xA2Air[i, j-1]
           )

# Initial conditions - Air
@constraint(m, capDacAirEq, xFair[0, 0] == aSorbAmountFreshAir)
@constraint(m, icA1AirEq, xA1Air[0, 0] == 0.)
@constraint(m, icA2AirEq, xA2Air[0, 0] == 0.)
@constraint(m, icAR1AirEq, xR1Air[0, 0] == 0.)
@constraint(m, icSsAirEq, xSair[0, 0] == 0.)

# End-point conditions - Air
@constraint(m, endDacAirEq, xFair[tHorz, hSlice] == aSorbAmountFreshAir)
@constraint(m, endA1AirEq, xA1Air[tHorz, hSlice] == 0.)
@constraint(m, endA2AirEq, xA2Air[tHorz, hSlice] == 0.)
@constraint(m, endAR1AirEq, xR1Air[tHorz, hSlice] == 0.)
@constraint(m, endSsAirEq, xSair[tHorz, hSlice] == 0.)

#
@constraint(m, co2CapDacAirEq[i = 0:tHorz, j=0:hSlice-1], 
            xCo2CapDacAir[i, j] == 
            #aSorbCo2CapAir * xR1Air[i, j]
            (aSorbCo2CapAir * xA1Air[i, j]/2 + aSorbCo2CapAir * xA2Air[i, j]/2)
           )
# 
@constraint(m, steamUseDacAirEq[i = 0:tHorz, j=0:hSlice-1], 
            xSteaUseDacAir[i, j] == 
            #aSteaUseRateDacAir * xCo2CapDacAir[i, j]
            aSteaUseRateDacAir * aSorbCo2CapAir * xR1Air[i, j]
           )
# 
@constraint(m, powUseDacAirEq[i = 0:tHorz, j=0:hSlice-1], 
            xPowUseDacAir[i, j] == aPowUseRateDacAir * xCo2CapDacAir[i, j]
           )
# We need the integral over the whole time for DAC
@constraint(m, dacSteaSlackEq[i = 0:tHorz], 
            xDacSteaSlack[i] == xDacSteaDuty[i] 
            - sum(xSteaUseDacFlue[i, j] for j in 0:hSlice - 1)
            - sum(xSteaUseDacAir[i, j] for j in 0:hSlice - 1)
           )

# Equal to the amount vented, at least in flue mode.
# Integral for DAC
@constraint(m, co2DacFlueVentEq[i = 0:tHorz], 
            xCo2DacVentFlue[i] == xCo2DacFlueIn[i] 
            - sum(xCo2CapDacFlue[i, j] for j in  0:hSlice-1)
           )


# Co2 Compression
# 
# We need the integral over the whole time for DAC
@constraint(m, co2CompEq[i = 0:tHorz], 
            xCo2Comp[i] == xCo2CapPcc[i] 
            + sum(xCo2CapDacFlue[i, j] for j in 0:hSlice-1)
            + sum(xCo2CapDacAir[i, j] for j in 0:hSlice-1)
           )
# 
@constraint(m, powUseCompEq[i = 0:tHorz], 
            xPowUseComp[i] == aPowUseRateComp * xCo2Comp[i]
           )
# 
@constraint(m, co2VentEq[i = 0:tHorz], 
            xCo2Vent[i] == vCo2PccVent[i] 
            + xCo2DacVentFlue[i] - sum(xCo2CapDacAir[i, j] 
                for j in 0:hSlice-1)
           )

## Overall

#
@constraint(m, powGrossEq[i = 0:tHorz], 
            xPowGross[i] == xPowGasTur[i] + xPowSteaTur[i]
           )
@constraint(m, auxPowEq[i = 0:tHorz],
            xAuxPow[i] == xAuxPowGasT[i] + xAuxPowSteaT[i])

@constraint(m, powOutEq[i = 0:tHorz], 
            xPowOut[i] == xPowGross[i] 
            - xPowUsePcc[i]
            - sum(xPowUseDacFlue[i, j] for j in 0:hSlice-1)
            - sum(xPowUseDacAir[i, j] for j in 0:hSlice-1)
            - xPowUseComp[i] 
            - xAuxPow[i]
           )


# Continuity of states
@constraint(m, 
            contxfflue[i = 1:tHorz], xFflue[i, 0] == xFflue[i - 1, hSlice])
@constraint(m, 
            conta1flue[i = 1:tHorz], xA1Flue[i, 0] == xA1Flue[i - 1, hSlice])

@constraint(m, 
            contcxsflue[i = 1:tHorz], xSflue[i, 0] == xSflue[i - 1, hSlice])
@constraint(m, 
            contr1flue[i = 1:tHorz], xR1Flue[i, 0] == xR1Flue[i - 1, hSlice])

@constraint(m, 
            contxfair[i = 1:tHorz], xFair[i, 0] == xFair[i - 1, hSlice])
@constraint(m, 
            conta1air[i = 1:tHorz], xA1Air[i, 0] == xA1Air[i - 1, hSlice])
@constraint(m, 
            conta2air[i = 1:tHorz], xA2Air[i, 0] == xA2Air[i - 1, hSlice])
@constraint(m, 
            contcxsair[i = 1:tHorz], xSair[i, 0] == xSair[i - 1, hSlice])
@constraint(m, 
            contr1air[i = 1:tHorz], xR1Air[i, 0] == xR1Air[i - 1, hSlice])


oneHourofGas60Load = cNgPerMmbtu * (bFuelEload + 60 * aFuelEload)

shutdowncost = Dict(0 => oneHourofGas60Load * 5, 1 => oneHourofGas60Load) 
shutdownfromwarm = cNgPerMmbtu * (bFuelEload + 60 * aFuelEload) * 24
startupcost = Dict(0 => oneHourofGas60Load * 24/2, 1 => oneHourofGas60Load/2) 
# Objective function expression

@expression(m, eObjfExpr, 
    sum(cNgPerMmbtu * xFuel[i]
        + cEmissionPrice * xCo2Vent[i] 
        + cCo2TranspPrice * xCo2Comp[i]
        - pow_price[i + 1] * xPowOut[i]
        for i in 0:tHorz)
        +
    sum(shutdowncost[j] * z[i, j, 2, 0] 
        + startupcost[j] * z[i, j, 0, 1]
        + shutdownfromwarm * z[i, j, 1, 0]
        for i in 0:tHorz for j in 0:nUnit)
    )

@objective(m, Min, eObjfExpr)

print("The number of variables\t")
println(num_variables(m))
print("The number of constraints\n")

n = 0
for i in list_of_constraint_types(m)
    global n
    println(num_constraints(m, i[1], i[2]))
    n += num_constraints(m, i[1], i[2])
end


println()

# Set optimizer options
set_optimizer(m, SCIP.Optimizer)
#set_optimizer_attribute(m, "LogLevel", 3)
#set_optimizer_attribute(m, "PresolveType", 1)

optimize!(m)
println(termination_status(m))

#f = open("model.lp", "w")
#print(f, m)
#close(f)

#write_to_file(m, "lp_mk0.mps")
#write_to_file(m, "lp_mk10.lp", format=MOI.FileFormats.FORMAT_LP)

#format::MOI.FileFormats.FileFormat = MOI.FileFormats.FORMAT_AUTOMATIC

# Co2 Data Frame
df_co = DataFrame(Symbol("Co2Fuel") => Float64[], # Pairs.
                  Symbol("Co2CapPcc") => Float64[],
                  Symbol("Co2PccOut") => Float64[],
                  Symbol("vCo2PccVent") => Float64[],
                  Symbol("Co2DacFlueIn") => Float64[],
                  Symbol("Co2CapDacFlue") => Float64[],
                  Symbol("Co2CapDacAir") => Float64[],
                  Symbol("Co2DacVentFlue") => Float64[],
                  Symbol("Co2Vent") => Float64[],
                 )

# Co2 / hSlice
for i in 0:tHorz
    co2fuel = value(xCo2Fuel[i])
    co2pcc = value(xCo2CapPcc[i])
    co2pccout = value(xCo2PccOut[i])
    co2pccvent = value(vCo2PccVent[i])
    co2dacfluein = value(xCo2DacFlueIn[i])
    co2dacflue = sum(value(xCo2CapDacFlue[i, j]) for j in 0:hSlice-1)
    co2dacair = sum(value(xCo2CapDacAir[i, j]) for j in 0:hSlice-1)
    co2dacventflue = value(xCo2DacVentFlue[i])
    co2vent = value(xCo2Vent[i])
    push!(df_co,(
        value(co2fuel),
        value(co2pcc),
        value(co2pccout),
        value(co2pccvent),
        value(co2dacfluein),
        value(co2dacflue),
        value(co2dacair),
        value(co2dacventflue),
        value(co2vent),
        ))
end

# Power Data Frame.
df_pow = DataFrame(
                  Symbol("PowGasTur") => Float64[], # Pairs.
                  Symbol("PowSteaTurb") => Float64[],
                  Symbol("PowHp") => Float64[],
                  Symbol("PowIp") => Float64[],
                  Symbol("PowLp") => Float64[],
                  Symbol("PowUsePcc") => Float64[],
                  Symbol("PowUseDacFlue") => Float64[],
                  Symbol("PowUseDacAir") => Float64[],
                  Symbol("PowUseComp") => Float64[],
                  Symbol("AuxPowGasT") => Float64[],
                  Symbol("AuxPowSteaT") => Float64[],
                  Symbol("PowGross") => Float64[],
                  Symbol("PowOut") => Float64[],
                  Symbol("xActualLoad") => Float64[],
                 )


# Pow / hSlice
for i in 0:tHorz
    ygastelecload = value(xActualLoad[i])
    powgastur = value(xPowGasTur[i])
    powsteatur = value(xPowSteaTur[i])
    powhp = value(xPowHp[i])
    powip = value(xPowIp[i])
    powlp = value(xPowLp[i])
    powusepcc = value(xPowUsePcc[i])
    powusedacflue = sum(value(xPowUseDacFlue[i, j]) for j in 0:hSlice-1)
    powusedacair = sum(value(xPowUseDacAir[i, j]) for j in 0:hSlice-1)
    powusecomp = value(xPowUseComp[i])
    auxpowgast = value(xAuxPowGasT[i])
    auxpowsteat = value(xAuxPowSteaT[i])
    powgross = value(xPowGross[i])
    powout = value(xPowOut[i])
    push!(df_pow, (
        powgastur,
        powsteatur,
        powhp,
        powip,
        powlp,
        powusepcc,
        powusedacflue,
        powusedacair,
        powusecomp,
        auxpowgast,
        auxpowsteat,
        powgross,
        powout,
        ygastelecload
        ))
end


# Steam DataFrame
df_steam = DataFrame(
                     Symbol("CcRebDuty") => Float64[],
                     Symbol("SteaUsePcc") => Float64[],
                     Symbol("PccSteaSlack") => Float64[],
                     Symbol("DacSteaDuty") => Float64[],
                     Symbol("SteaUseDacFlue") => Float64[],
                     Symbol("SteaUseDacAir") => Float64[],
                     Symbol("DacSteaSlack") => Float64[],
                     Symbol("SideStea") => Float64[],
                     Symbol("DacSteaBaseDuty") => Float64[],
                     Symbol("SideSteaDac") => Float64[],
                     Symbol("Fuel") => Float64[]
                    )

# Steam / hSlice
for i in 0:tHorz
    ccrebduty = value(xCcRebDuty[i])
    steausepcc = value(xSteaUsePcc[i])
    pccsteaslack = value(xPccSteaSlack[i])
    dacsteaduty = value(xDacSteaDuty[i])
    steausedacflue = sum(value(xSteaUseDacFlue[i, j]) for j in 0:hSlice-1)
    steausedacair = sum(value(xSteaUseDacAir[i, j]) for j in 0:hSlice-1)
    dacsteaslack = value(xDacSteaSlack[i])
    sidesteam = value(xAllocSteam[i])
    dacsteabaseduty = value(xDacSteaBaseDuty[i])
    sidesteadac = value(xSideSteaDac[i])
    xfuel = value(xFuel[i])
    push!(df_steam, 
        (
            ccrebduty,
            steausepcc,
            pccsteaslack,
            dacsteaduty,
            steausedacflue,
            steausedacair,
            dacsteaslack,
            sidesteam,
            dacsteabaseduty,
            sidesteadac,
            xfuel
            ))
end

# DAC-flue DataFrame
df_dac_flue = DataFrame(
    :time => Float64[],
    :xFflue => Float64[],
    :xSflue => Float64[],
    :xA0Flue => Float64[],
    :xA1Flue => Float64[],
    :xR0Flue => Float64[],
    :xR1Flue => Float64[]
    )

sliceFact = 1/hSlice
for i in 0:tHorz
    for j in 0:hSlice-1
        currtime = i + j * sliceFact
        push!(df_dac_flue,(
            currtime,
            value(xFflue[i, j]), 
            value(xSflue[i, j]),
            value(xA0Flue[i, j]), 
            value(xA1Flue[i, j]), 
            value(xR0Flue[i, j]), 
            value(xR1Flue[i, j]))
        )
    end
end

# DAC-air DataFrame
df_dac_air = DataFrame(
    :time => Float64[],
    :xFair => Float64[],
    :xSair => Float64[],
    :xA0Air => Float64[],
    :xA1Air => Float64[],
    :xA2Air => Float64[],
    :xR0Air => Float64[],
    :xR1Air => Float64[])

for i in 0:tHorz
    for j in 0:hSlice-1
        currtime = i + j * sliceFact
        push!(df_dac_air,(
            currtime,
            value(xFair[i, j]), 
            value(xSair[i, j]),
            value(xA0Air[i, j]), 
            value(xA1Air[i, j]), 
            value(xA2Air[i, j]),
            value(xR0Air[i, j]), 
            value(xR1Air[i, j])))
    end
end


df_pow_price = DataFrame(
                         price = Float64[]
                        )
for i in 0:tHorz
    push!(df_pow_price, (pow_price[i + 1],))
end


# Cost DataFrame
df_cost = DataFrame(
                    cNG = Float64[],
                    cCo2Em = Float64[],
                    cTransp = Float64[],
                    PowSales = Float64[]
                   )

for i in 0:tHorz
    cng = cNgPerMmbtu * value(xFuel[i])
    cco = cEmissionPrice * value(xCo2Vent[i])
    ctr = cCo2TranspPrice * value(xCo2Comp[i])
    cpow = pow_price[i + 1] * value(xPowOut[i])
    push!(df_cost, (cng, cco, ctr, cpow))
end

df_time_slice = DataFrame(:time => Float64[])

for i in 0:tHorz
    for j in 0:hSlice-1
        currtime = i + j * sliceFact
        push!(df_time_slice, (currtime, ))
    end
end


# Binary variables
# Create the DataFrame for the binary variables.
bvars_names = ["y", "z"]

l0 = []
for v in bvars_names
    for j in 0:nUnit
        for mod in 0:nMod
            if v == "z"
                l = [v * string(j) * string(mod) * string(m2) => Float64[] 
                for m2 in 0:nMod]
            else
                l = [v * string(j) * string(mod) => Float64[]]
            end
            global l0 = vcat(l0, l)
        end
    end
end

df_binary = DataFrame(l0)
# Add the values to the DataFrame of binaries.
for i in 0:tHorz
    l0 = []
    for v in bvars_names
        s = Symbol(v)
        if v == "z"
            l = [value(m[s][i, j, m1, m2]) for j in 0:nUnit
             for m1 in 0:nMod  for m2 in 0:nMod]
        else
            l = [value(m[s][i, j, mod]) for j in 0:nUnit for mod in 0:nMod]
        end
        l0 = vcat(l0, l)
    end
    push!(df_binary, l0)
end

# ``Main'' disagregated variables.
dis_names = ["xLoadD", "lambda"]
l0 = []
for v in dis_names
    for j in 0:nUnit # Per unit
        for mod in 0:nMod # Per mod
            if v == "lambda"
                l = [v * string(j) * string(mod) * string(k) => Float64[] 
                for k in extrPoint[mod]]
            else
                l = [v * string(j) * string(mod) => Float64[]]
            end
            global l0 = vcat(l0, l)
        end
    end
end

df_mdv = DataFrame(l0)

for i in 0:tHorz
    l0 = []
    for v in dis_names
        s = Symbol(v)
        if v == "lambda"
            l = []
            for j in 0:nUnit
                for mod in 0:nMod
                    l1 = [value(m[s][i, j, mod, k]) for k in extrPoint[mod]]
                    l = vcat(l, l1)
                end
            end
        else
            l = [value(m[s][i, j, mod]) for j in 0:nUnit for mod in 0:nMod]
        end
        l0 = vcat(l0, l)
    end
    #print(l0)
    push!(df_mdv, l0)
end


# Write CSV
CSV.write("df_co.csv", df_co)
CSV.write("df_pow.csv", df_pow)
CSV.write("df_steam.csv", df_steam)
CSV.write("df_dac_flue.csv", df_dac_flue)
CSV.write("df_dac_air.csv", df_dac_air)
CSV.write("df_pow_price.csv", df_pow_price)
CSV.write("df_cost.csv", df_cost)
CSV.write("df_time_slice.csv", df_time_slice)
CSV.write("df_binary.csv", df_binary)
CSV.write("df_mdv.csv", df_mdv)

# By Unit Vars
dvars = ["xLoadU", "xPowGtU", "xFuelU", "xEmisU", "xAuxGtU", "xPowHpU", 
"xPowIpU", "xPccRebU", "xDacSbU", "xAllocU", "xAuxStU"]

l = []
for v in dvars
    global l = vcat(l, [v * string(j) => Float64[] for j in 0:nUnit])
end

df_unit = DataFrame(l)

for i in 0:tHorz
    l0 = []
    for v in dvars
        s = Symbol(v)
        l = [value(m[s][i, j]) for j in 0:nUnit]
        l0 = vcat(l0, l)
    end
    push!(df_unit, l0)
end

CSV.write("df_unit.csv", df_unit)

# By Disjunction Vars
dvars = ["xLoadD", "xPowGtD", "xFuelD", "xEmisD", "xAuxGtD", "xPowHpD", 
"xPowIpD", "xPccRebD", "xDacSbD", "xAllocD", "xAuxStD"]

l = []
for v in dvars
    global l = vcat(l, [v * string(j) * string(mod) => Float64[] 
        for j in 0:nUnit for mod in 0:nMod])
end

df_disj = DataFrame(l)

for i in 0:tHorz
    l0 = []
    for v in dvars
        s = Symbol(v)
        l = [value(m[s][i, j, mod]) for j in 0:nUnit for mod in 0:nMod]
        l0 = vcat(l0, l)
    end
    push!(df_disj, l0)
end

CSV.write("df_disj.csv", df_disj)



