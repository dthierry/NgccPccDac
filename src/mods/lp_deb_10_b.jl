# vim: set wrap
#: by David Thierry 2021
using JuMP
using Clp
using DataFrames
using CSV

#: Data frames section
#: Load parameters

df_gas = DataFrame(CSV.File("../reg/gas_coeffs.csv"))
df_steam_full_power = DataFrame(CSV.File("../reg/steam_coeffs.csv"))
df_steam_full_steam = DataFrame(CSV.File("../reg/steam_coeffs_v3.csv"))

#: Load Prices
df_pow_c = DataFrame(CSV.File("../resources/FLECCSPriceSeriesData.csv"))
df_ng_c = DataFrame(CSV.File("../resources/natural_gas_price.csv"))

#: Load random floats
df_rf = DataFrame(CSV.File("../resources/1year_2c.csv"))

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
tHorz = 1
rnum = df_rf[1:tHorz, 1]
# USD/MWh
# pow_price =(df_pow_c[!, "MiNg_150_ERCOT"])  # USD/MWh

pow_price =(df_pow_c[!, "MiNg_150_PJM-W"])  # USD/MWh
#: Natural gas price
# 0.056 lb/cuft STP
#std_w_ng1000cuft = 0.056 * 1000
#cNgPerLbUsd = (3.5 / 1000) / 0.056
cNgPerMmbtu = 3.5
m = Model()
#
# aPowUseRateComp = 0.279751187  # MWh/tonneCo2
aPowUseRateComp = 0.076 # MWh/tonneCo2 (Trimeric)
#
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

hSlice = 4  # the number of slices of a given hour
# There are tHorz - 1 slices
# Each slice has hSlice points, but only states have the 0th
@variable(m, 60 <= yGasTelecLoad[0:tHorz, 1:hSlice] <= 100)
@variable(m, 0 <= xPowGasTur[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowGross[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowOut[0:tHorz, 1:hSlice])

@variable(m, xAuxPowGasT[0:tHorz, 1:hSlice] >= 0)

# Steam Turbine
@variable(m, 0 <= xPowHp[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowIp[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowLp[0:tHorz, 1:hSlice])

@variable(m, 0 <= xFuel[0:tHorz, 1:hSlice])
@variable(m, 0 <= xCo2Fuel[0:tHorz, 1:hSlice])
@variable(m, 0 <= xDacSteaDuty[0:tHorz, 1:hSlice])


@variable(m, 0 <= xCcRebDuty[0:tHorz, 1:hSlice])
@variable(m, 0 <= xDacSteaBaseDuty[0:tHorz, 1:hSlice])

@variable(m, 0 <= xSideSteam[0:tHorz, 1:hSlice])
@variable(m, 0 <= xSteaPowLp[0:tHorz, 1:hSlice])
@variable(m, 0 <= xSideSteaDac[0:tHorz, 1:hSlice])

#

@variable(m, 0 <= xPowSteaTur[0:tHorz, 1:hSlice])
@variable(m, 0 <= xAuxPowSteaT[0:tHorz, 1:hSlice])

# Pcc
#@variable(m, 0 <= xCo2CapPcc[0:tHorz - 1] <= vCapPcc)
@variable(m, 0 <= xCo2CapPcc[0:tHorz, 1:hSlice])
@variable(m, 0 <= xSteaUsePcc[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowUsePcc[0:tHorz, 1:hSlice])
@variable(m, 0 <= xCo2PccOut[0:tHorz, 1:hSlice])
#@variable(m, 0 <= vCo2PccVent[0:tHorz - 1] <= 0.1)
@variable(m, 0 <= vCo2PccVent[0:tHorz, 1:hSlice])
#vCo2PccVent = 0.0
@variable(m, 0 <= xCo2DacFlueIn[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPccSteaSlack[0:tHorz, 1:hSlice])

# Dac-Flue
@variable(m, 0 <= xA0Flue[0:tHorz, 0:hSlice]) 

@variable(m, 0 <= xA1Flue[0:tHorz, 0:hSlice]) # State
@variable(m, 0 <= xA2Flue[0:tHorz, 0:hSlice]) # State

@variable(m, 0 <= xR0Flue[0:tHorz, 0:hSlice])  # Not-a-State

@variable(m, 0 <= xR1Flue[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xFflue[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xSflue[0:tHorz, 0:hSlice])  # State

@variable(m, 0 <= vAbsFlue[0:tHorz, 0:hSlice])  # Input
@variable(m, 0 <= vRegFlue[0:tHorz, 0:hSlice])  # Input

@variable(m, 0 <= xCo2CapDacFlue[0:tHorz, 1:hSlice])
@variable(m, 0 <= xSteaUseDacFlue[0:tHorz, 1:hSlice])
@variable(m, 0 <= xPowUseDacFlue[0:tHorz, 1:hSlice])
@variable(m, 0 <= xCo2DacVentFlue[0:tHorz, 1:hSlice])

# Dac-Air
@variable(m, 0 <= xA0Air[0:tHorz, 0:hSlice])  

@variable(m, 0 <= xA1Air[0:tHorz, 0:hSlice]) # State
@variable(m, 0 <= xA2Air[0:tHorz, 0:hSlice]) # State

@variable(m, 0 <= xR0Air[0:tHorz, 0:hSlice])  # Not-a-State

@variable(m, 0 <= xR1Air[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xFair[0:tHorz, 0:hSlice])  # State
@variable(m, 0 <= xSair[0:tHorz, 0:hSlice])  # State

@variable(m, 0 <= vAbsAir[0:tHorz, 0:hSlice])  # Input
@variable(m, 0 <= vRegAir[0:tHorz, 0:hSlice])  # Input

@variable(m, 0 <= xCo2CapDacAir[0:tHorz, 1:hSlice])
@variable(m, xSteaUseDacAir[0:tHorz, 1:hSlice] >= 0)
@variable(m, 0 <= xPowUseDacAir[0:tHorz, 1:hSlice])

@variable(m, 0 <= xDacSteaSlack[0:tHorz, 1:hSlice])
# DAC hourly capacity
#
@variable(m, 0 <= xCo2DacHr[0:tHorz])


# CO2 compression
@variable(m, 0 <= xCo2Comp[0:tHorz, 1:hSlice])
#@variable(m, 0 <= xPowUseComp[0:tHorz - 1] <= vCapComp)
@variable(m, 0 <= xPowUseComp[0:tHorz, 1:hSlice])
#@variable(m, 0 <= vCapComp)
@variable(m, xCo2Vent[0:tHorz, 1:hSlice])  # This used to be only positive.

@variable(m, 0 <= xAuxPow[0:tHorz, 1:hSlice])

# Constraints
# Gas Turbine
@constraint(m, powGasTur[i = 0:tHorz, j = 1:hSlice], 
            xPowGasTur[i, j] == aPowGasTeLoad * yGasTelecLoad[i, j] 
            + bPowGasTeLoad
           )
# 
@constraint(m, fuelEq[i = 0:tHorz, j = 1:hSlice], 
            xFuel[i, j] == aFuelEload * yGasTelecLoad[i, j] 
            + bFuelEload
           )
# 
@constraint(m, co2FuelEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2Fuel[i, j] == aEmissFactEload * yGasTelecLoad[i, j] 
            + bEmissFactEload
           )

@constraint(m, auxPowGasT[i = 0:tHorz, j = 1:hSlice],
            xAuxPowGasT[i, j] == aAuxRateGas * yGasTelecLoad[i, j] 
            + bAuxRateGas
           )
# 
# Steam
# 
@constraint(m, powHpEq[i = 0:tHorz, j = 1:hSlice], 
            xPowHp[i, j] == aPowHpEload * yGasTelecLoad[i, j] 
            + bPowHpEload
           )
# 
@constraint(m, powIpEq[i = 0:tHorz, j = 1:hSlice], 
            xPowIp[i, j] == aPowIpEload * yGasTelecLoad[i, j] 
            + bPowIpEload
           )

# 
@constraint(m, powLpEq[i = 0:tHorz, j = 1:hSlice], 
#            xPowLp[i] == aPowLpEload * yGasTelecLoad[i] + bPowLpEload
            xPowLp[i, j] == xSteaPowLp[i, j] * aLpSteaToPow / 1000
           )
# 
@constraint(m, powerSteaEq[i = 0:tHorz, j = 1:hSlice], 
            xPowSteaTur[i, j] == 
            xPowHp[i, j] + xPowIp[i, j] + xPowLp[i, j]
           )

@constraint(m, ccRebDutyEq[i = 0:tHorz, j = 1:hSlice],
            xCcRebDuty[i, j] == 
            aCcRebDutyEload * yGasTelecLoad[i, j] 
            + bCcRebDutyEload
           )

@constraint(m, dacSteaDutyEq[i = 0:tHorz, j = 1:hSlice],
            xDacSteaBaseDuty[i, j] == aDacSteaBaseEload * yGasTelecLoad[i, j] 
            + bDacSteaBaseEload
           )


@constraint(m, sideSteaEloadEq[i = 0:tHorz, j = 1:hSlice],
            xSideSteam[i, j] == aSideSteaEload * yGasTelecLoad[i, j] 
            + bSideSteaEload
           )

@constraint(m, sideSteaRatioEq[i = 0:tHorz, j = 1:hSlice],
            xSideSteam[i, j] == xSideSteaDac[i, j] + xSteaPowLp[i, j]
           )

@constraint(m, availSteaDacEq[i = 0:tHorz, j = 1:hSlice],
            xDacSteaDuty[i, j] == xDacSteaBaseDuty[i, j] + xSideSteaDac[i, j]
           )

@constraint(m, auxPowSteaTEq[i = 0:tHorz, j = 1:hSlice],
            xAuxPowSteaT[i, j] == aAuxRateStea * yGasTelecLoad[i, j] 
            + bAuxRateStea 
           )

# PCC
# 
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], 
#xCo2CapPcc[i] == aCo2PccCapRate * xCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2CapPcc[i, j] == aCapRatePcc * xCo2Fuel[i, j])
# 
@constraint(m, co2PccOutEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2PccOut[i, j] == xCo2Fuel[i, j] - xCo2CapPcc[i, j])
# 
@constraint(m, co2DacFlueInEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2DacFlueIn[i, j] == xCo2PccOut[i, j] - vCo2PccVent[i, j])
# 
# @constraint(m, co2CapPccIn[i = 0:tHorz - 1], xCo2CapPcc[i] <= vCapPcc)
# Dav: Sometimes there is not enough steam, so we have to relax this constraint 
@constraint(m, steamUsePccEq[i = 0:tHorz, j = 1:hSlice], 
            xSteaUsePcc[i, j] <= aSteaUseRatePcc * xCo2CapPcc[i, j])
# 
@constraint(m, powerUsePccEq[i = 0:tHorz, j = 1:hSlice], 
            xPowUsePcc[i, j] == aPowUseRatePcc * xCo2CapPcc[i, j]
           )

@constraint(m, pccSteaSlack[i = 0:tHorz, j = 1:hSlice], 
            xPccSteaSlack[i, j] == xCcRebDuty[i, j] - xSteaUsePcc[i, j])

# DAC-Flue
@constraint(m, xA0FlueEq[i = 0:tHorz, j=0:hSlice], 
            xA0Flue[i, j] == vAbsFlue[i, j]
           )
@constraint(m, xR0FlueEq[i = 0:tHorz, j=0:hSlice], 
            xR0Flue[i, j] == vRegFlue[i, j]
           )
#
#: "State equation"
@constraint(m, a1dFlueEq[i = 0:tHorz, j=1:hSlice], 
            xA1Flue[i, j] == xA0Flue[i, j-1]
           )
#: "State equation"
@constraint(m, a2dFlueEq[i = 0:tHorz, j=1:hSlice], 
            xA2Flue[i, j] == xA1Flue[i, j-1]
           )
#: "State equation"
@constraint(m, aRdFlueEq[i = 0:tHorz, j=1:hSlice], 
            xR1Flue[i, j] == xR0Flue[i, j-1]
           )
#: "State equation"
@constraint(m, storeFflueeq[i = 0:tHorz, j = 1:hSlice], 
            xFflue[i, j] == xFflue[i, j-1] - vAbsFlue[i, j-1] + xR1Flue[i, j-1]
           )
#: "State equation"
@constraint(m, storeSflueeq[i = 0:tHorz, j = 1:hSlice], 
            xSflue[i, j] == xSflue[i, j-1] - vRegFlue[i, j-1] + xA2Flue[i, j-1]
           )
# Initial conditions
@constraint(m, icXa1FlueEq, xA1Flue[0, 0] == 0.)
@constraint(m, icxA2FlueEq, xA2Flue[0, 0] == 0.)
@constraint(m, icAR1FlueEq, xR1Flue[0, 0] == 0.)
#@constraint(m, capDacFlueEq, xFflue[0] == xSorbFreshFlue)
@constraint(m, capDacFlueEq, xFflue[0, 0] == aSorbAmountFreshFlue)
@constraint(m, icSsFlueEq, xSflue[0, 0] == 0.)
# End-point constraints we need to get rid of them and then put them back
#
#@constraint(m, endXa1FlueEq, xA1Flue[tHorz, hSlice] == 0.)
#@constraint(m, endxA2FlueEq, xA2Flue[tHorz] == 0.)
#@constraint(m, endAR1FlueEq, xR1Flue[tHorz] == 0.)
#@constraint(m, endDacFlueEq, xFflue[tHorz] == xSorbFreshFlue)
#@constraint(m, endDacFlueEq, xFflue[tHorz] == aSorbAmountFreshFlue)
#@constraint(m, endSsFlueEq, xSflue[tHorz] == 0.)

#
#
@constraint(m, co2CapDacFlueEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2CapDacFlue[i, j] == aSorbCo2CapFlue * xR1Flue[i, j]
           )
#
@constraint(m, steamUseDacFlueEq[i = 0:tHorz, j = 1:hSlice], 
            xSteaUseDacFlue[i, j] == aSteaUseRateDacFlue * xCo2CapDacFlue[i, j]
           )
#
@constraint(m, powUseDacFlueEq[i = 0:tHorz, j = 1:hSlice], 
            xPowUseDacFlue[i, j] == aPowUseRateDacFlue * xCo2CapDacFlue[i, j]
           )
# Equal to the amount vented, at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2DacVentFlue[i, j] == xCo2DacFlueIn[i, j] - xCo2CapDacFlue[i, j]
           )

# DAC-Air
# Bluntly assume we can just take CO2 from air in pure form.
@constraint(m, xA0AirEq[i = 0:tHorz, j = 0:hSlice], 
            xA0Air[i, j] == vAbsAir[i, j]
           )
@constraint(m, xR0AirEq[i = 0:tHorz, j = 0:hSlice], 
            xR0Air[i, j] == vRegAir[i, j]
           )
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
            xFair[i, j] == xFair[i, j-1] - vAbsAir[i, j-1] + xR1Air[i, j-1]
           )
# "State equation"
@constraint(m, storeSaireq[i = 0:tHorz, j = 1:hSlice], 
            xSair[i, j] == xSair[i, j-1] - vRegAir[i, j-1] + xA2Air[i, j-1]
           )

# Initial conditions - Air
#@constraint(m, capDacAirEq, xFair[0] == xSorbFreshAir)
@constraint(m, capDacAirEq, xFair[0, 0] == aSorbAmountFreshAir)
# aSorbAmountFreshFlue 
@constraint(m, icA1AirEq, xA1Air[0, 0] == 0.)
@constraint(m, icA2AirEq, xA2Air[0, 0] == 0.)
@constraint(m, icAR1AirEq, xR1Air[0, 0] == 0.)
@constraint(m, icSsAirEq, xSair[0, 0] == 0.)
# End-point conditions - Air
#@constraint(m, endDacAirEq, xFair[0] == xSorbFreshAir)
#@constraint(m, endDacAirEq, xFair[0, 0] == aSorbAmountFreshAir)
#@constraint(m, endA1AirEq, xA1Air[0, 0] == 0.)
#@constraint(m, endA2AirEq, xA2Air[0, 0] == 0.)
#@constraint(m, endAR1AirEq, xR1Air[0, 0] == 0.)
#@constraint(m, endSsAirEq, xSair[0, 0] == 0.)

#
# Money, baby.
@constraint(m, co2CapDacAirEq[i = 0:tHorz, j=1:hSlice], 
            xCo2CapDacAir[i, j] == aSorbCo2CapAir * xR1Air[i, j]
           )
# 
@constraint(m, steamUseDacAirEq[i = 0:tHorz, j=1:hSlice], 
            xSteaUseDacAir[i, j] == aSteaUseRateDacAir * xCo2CapDacAir[i, j]
           )
# 
@constraint(m, powUseDacAirEq[i = 0:tHorz, j=1:hSlice], 
            xPowUseDacAir[i, j] == aPowUseRateDacAir * xCo2CapDacAir[i, j]
           )


@constraint(m, dacSteaSlackEq[i = 0:tHorz, j=1:hSlice], 
            xDacSteaSlack[i, j] == xDacSteaDuty[i, j] 
            - xCo2DacHr[i]
           )

@constraint(m, dacsteahrEq[i = 0:tHorz], 
            xCo2DacHr[i] ==
            sum(xSteaUseDacFlue[i, j] + xSteaUseDacAir[i, j] 
                for j in 1:hSlice)
           )


# Co2 Compression
# 
@constraint(m, co2CompEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2Comp[i, j] == xCo2CapPcc[i, j] 
            + sum(xCo2CapDacFlue[i, k] + xCo2CapDacAir[i, k] for k in 1:hSlice)
           )
# 
@constraint(m, powUseCompEq[i = 0:tHorz, j = 1:hSlice], 
            xPowUseComp[i, j] == aPowUseRateComp * xCo2Comp[i, j]
           )
# 
# @constraint(m, powUseCompIn[i = 0:tHorz - 1], xPowUseComp[i] <= vCapComp)

# @constraint(m, co2VentEq[i = 0:tHorz - 1], 
# xCo2Vent[i] == vCo2PccVent[i] + xCo2DacVentFlue[i])
@constraint(m, co2VentEq[i = 0:tHorz, j = 1:hSlice], 
            xCo2Vent[i, j] == vCo2PccVent[i, j] 
            + sum(xCo2DacVentFlue[i, k] - xCo2CapDacAir[i, k] for k in 1:hSlice)
           )

## Overall

#
@constraint(m, powGrossEq[i = 0:tHorz, j = 1:hSlice], 
            xPowGross[i, j] == xPowGasTur[i, j] + xPowSteaTur[i, j]
           )
@constraint(m, auxPowEq[i = 0:tHorz, j = 1:hSlice],
            xAuxPow[i, j] == xAuxPowGasT[i, j] + xAuxPowSteaT[i, j])

@constraint(m, powOutEq[i = 0:tHorz, j = 1:hSlice], 
            xPowOut[i, j] == xPowGross[i, j] 
            - xPowUsePcc[i, j]
            - sum(xPowUseDacFlue[i, k] + xPowUseDacAir[i, k] for k in 1:hSlice)
            - xPowUseComp[i, j] 
            - xAuxPow[i, j]
           )

# Piece-wise constant DOF
@constraint(m, pwleq[i = 0:tHorz, j = 2:hSlice],
            yGasTelecLoad[i, 1] == yGasTelecLoad[i, j]
           )
@constraint(m, pwssd[i = 0:tHorz, j = 2:hSlice],
           xSideSteaDac[i, 1] == xSideSteaDac[i, j]  
           )
@constraint(m, pwco2vent[i = 0:tHorz, j = 2:hSlice],
            vCo2PccVent[i, 1] == vCo2PccVent[i, j]
           )

# Continuity of states
@constraint(m, contxfflue[i = 1:tHorz], xFflue[i, 0] == xFflue[i - 1, hSlice])
@constraint(m, conta1flue[i = 1:tHorz], xA1Flue[i, 0] == xA1Flue[i - 1, hSlice])
@constraint(m, conta2flue[i = 1:tHorz], xA2Flue[i, 0] == xA2Flue[i - 1, hSlice])
@constraint(m, contcxsflue[i = 1:tHorz], xSflue[i, 0] == xSflue[i - 1, hSlice])
@constraint(m, contr1flue[i = 1:tHorz], xR1Flue[i, 0] == xR1Flue[i - 1, hSlice])

@constraint(m, contxfair[i = 1:tHorz], xFair[i, 0] == xFair[i - 1, hSlice])
@constraint(m, conta1air[i = 1:tHorz], xA1Air[i, 0] == xA1Air[i - 1, hSlice])
@constraint(m, conta2air[i = 1:tHorz], xA2Air[i, 0] == xA2Air[i - 1, hSlice])
@constraint(m, contcxsair[i = 1:tHorz], xSair[i, 0] == xSair[i - 1, hSlice])
@constraint(m, contr1air[i = 1:tHorz], xR1Air[i, 0] == xR1Air[i - 1, hSlice])


@expression(m, eObjfExpr, sum(
                              cNgPerMmbtu * xFuel[i, hSlice]
                              + cEmissionPrice * xCo2Vent[i, hSlice]
                              + cCo2TranspPrice * xCo2Comp[i, hSlice]
                              - pow_price[i+ 1] * xPowOut[i, hSlice]
                              for i in 0:tHorz
                             )
           )

@objective(m, Min, eObjfExpr)
println("The number of variables: ")
println(num_variables(m))
global n
n = 0
for i in list_of_constraint_types(m)
    global n
    println(num_constraints(m, i[1], i[2]))
    n += num_constraints(m, i[1], i[2])
end
println()
println("The number of constraints: ", n)
println()
set_optimizer(m, Clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 3)
set_optimizer_attribute(m, "PresolveType", 1)

optimize!(m)
println(termination_status(m))

f = open("model.lp", "w")
print(f, m)
close(f)

#write_to_file(m, "lp_mk0.mps")
write_to_file(m, "lp_mk10.lp", format=MOI.FileFormats.FORMAT_LP)

#format::MOI.FileFormats.FileFormat = MOI.FileFormats.FORMAT_AUTOMATIC

# Raw materials.
# xFuel
# sF0
# sS0
#
# penalties
# vCo2Vent

## vCo2PccVent * 2N

# Actual variables
# xPowGasTur * 2


