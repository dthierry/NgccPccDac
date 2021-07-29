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
df_pow_c = DataFrame(CSV.File("../resources/FLECCSPriceSeriesData.csv")) #: 9th col)
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

bDacSteaBaseEload = df_steam_full_power[3, 2]  #Full power gives you the min steam
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
tHorz = 24 * 7
rnum = df_rf[1:tHorz, 1]
# USD/MWh
pow_price =(df_pow_c[!, "MiNg_150_ERCOT"])  # USD/MWh

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

@variable(m, 60 <= yGasTelecLoad[0:tHorz - 1] <= 100)
@variable(m, 0 <= xPowGasTur[0:tHorz - 1])
@variable(m, 0 <= xPowGross[0:tHorz - 1])
@variable(m, 0 <= xPowOut[ 0:tHorz - 1])

@variable(m, xAuxPowGasT[0:tHorz - 1] >= 0)

# Steam Turbine
@variable(m, 0 <= xPowHp[0:tHorz - 1])
@variable(m, 0 <= xPowIp[0:tHorz - 1])
@variable(m, 0 <= xPowLp[0:tHorz - 1])

@variable(m, 0 <= xFuel[0:tHorz - 1])
@variable(m, 0 <= xCo2Fuel[0:tHorz - 1])
@variable(m, xDacSteaDuty[0:(tHorz -1)] >= 0.0)

@variable(m, 0 <= xCcRebDuty[0:tHorz - 1])
@variable(m, 0 <= xDacSteaBaseDuty[0:tHorz - 1])

@variable(m, 0 <= xSideSteam[0:tHorz - 1])
@variable(m, 0 <= xSteaPowLp[0:tHorz - 1])
@variable(m, 0 <= xSideSteaDac[0:tHorz - 1])

#

@variable(m, 0 <= xPowSteaTur[0:tHorz - 1])
@variable(m, 0 <= xAuxPowSteaT[0:tHorz - 1])

# Pcc
#@variable(m, 0 <= xCo2CapPcc[0:tHorz - 1] <= vCapPcc)
@variable(m, 0 <= xCo2CapPcc[0:tHorz - 1])
@variable(m, 0 <= xSteaUsePcc[0:tHorz - 1])
@variable(m, 0 <= xPowUsePcc[0:tHorz - 1])
@variable(m, 0 <= xCo2PccOut[0:tHorz - 1])
#@variable(m, 0 <= vCo2PccVent[0:tHorz - 1] <= 0.1)
@variable(m, 0 <= vCo2PccVent[0:tHorz - 1])
#vCo2PccVent = 0.0
@variable(m, 0 <= xCo2DacFlueIn[0:tHorz - 1])
@variable(m, 0 <= xPccSteaSlack[0:tHorz - 1])

# Dac-Flue
@variable(m, 0 <= xA0Flue[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= xA1Flue[0:tHorz]) # State
@variable(m, 0 <= xA2Flue[0:tHorz]) # State

@variable(m, 0 <= xR0Flue[0:tHorz - 1])  # Not-a-State
@variable(m, 0 <= xR1Flue[0:tHorz])  # State
@variable(m, 0 <= xFflue[0:tHorz])  # State
@variable(m, 0 <= xSflue[0:tHorz])  # State

@variable(m, 0 <= vAbsFlue[0:tHorz - 1])  # Input
@variable(m, 0 <= vRegFlue[0:tHorz - 1])  # Input

@variable(m, 0 <= xCo2StorDacFlue[0:tHorz - 1])
@variable(m, 0 <= xCo2CapDacFlue[0:tHorz - 1])
@variable(m, 0 <= xSteaUseDacFlue[0:tHorz - 1])
@variable(m, 0 <= xPowUseDacFlue[0:tHorz - 1])
@variable(m, 0 <= xCo2DacVentFlue[0:tHorz - 1])

# Dac-Air
@variable(m, 0 <= xA0Air[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= xA1Air[0:tHorz]) # State
@variable(m, 0 <= xA2Air[0:tHorz]) # State

@variable(m, 0 <= xR0Air[0:tHorz - 1])  # Not-a-State
@variable(m, 0 <= xR1Air[0:tHorz])  # State
@variable(m, 0 <= xFair[0:tHorz])  # State
@variable(m, 0 <= xSair[0:tHorz])  # State

@variable(m, 0 <= vAbsAir[0:tHorz - 1])  # Input
@variable(m, 0 <= vRegAir[0:tHorz - 1])  # Input

@variable(m, 0 <= xCo2StorDacAir[0:tHorz - 1])
@variable(m, 0 <= xCo2CapDacAir[0:tHorz - 1])
@variable(m, xSteaUseDacAir[0:tHorz - 1] >= 0)
@variable(m, 0 <= xPowUseDacAir[0:tHorz - 1])

@variable(m, 0 <= xDacSteaSlack[0:tHorz - 1])


# CO2 compression
@variable(m, 0 <= xCo2Comp[0:tHorz - 1])
#@variable(m, 0 <= xPowUseComp[0:tHorz - 1] <= vCapComp)
@variable(m, 0 <= xPowUseComp[0:tHorz - 1])
#@variable(m, 0 <= vCapComp)
@variable(m, xCo2Vent[0:tHorz - 1])  # This used to be only positive.

@variable(m, xAuxPow[0:tHorz - 1])

# Constraints
# Gas Turbine
@constraint(m, powGasTur[i = 0:tHorz - 1], 
            xPowGasTur[i] == aPowGasTeLoad * yGasTelecLoad[i] + bPowGasTeLoad
           )
# 4
@constraint(m, fuelEq[i = 0:(tHorz - 1)], 
            xFuel[i] == aFuelEload * yGasTelecLoad[i] + bFuelEload
           )
# 5
@constraint(m, co2FuelEq[i = 0:tHorz - 1], 
            xCo2Fuel[i] == aEmissFactEload * yGasTelecLoad[i] + bEmissFactEload
           )

@constraint(m, auxPowGasT[i = 0:tHorz - 1],
            xAuxPowGasT[i] == aAuxRateGas * yGasTelecLoad[i] + bAuxRateGas
           )
# 6
# Steam
# 7a
@constraint(m, powHpEq[i = 0:tHorz - 1], 
            xPowHp[i] == aPowHpEload * yGasTelecLoad[i] + bPowHpEload
           )
# 7b
@constraint(m, powIpEq[i = 0:tHorz - 1], 
            xPowIp[i] == aPowIpEload * yGasTelecLoad[i] + bPowIpEload
           )

# 11
@constraint(m, powLpEq[i = 0:tHorz - 1], 
#            xPowLp[i] == aPowLpEload * yGasTelecLoad[i] + bPowLpEload
xPowLp[i] == xSteaPowLp[i] * aLpSteaToPow / 1000
           )
# 12
@constraint(m, powerSteaEq[i = 0:tHorz - 1], 
            xPowSteaTur[i] == xPowHp[i] + xPowIp[i] + xPowLp[i])

@constraint(m, ccRebDutyEq[i = 0:tHorz - 1],
            xCcRebDuty[i] == aCcRebDutyEload * yGasTelecLoad[i] + bCcRebDutyEload
           )

@constraint(m, dacSteaDutyEq[i = 0:tHorz - 1],
            xDacSteaBaseDuty[i] == aDacSteaBaseEload * yGasTelecLoad[i] + bDacSteaBaseEload
           )


@constraint(m, sideSteaEloadEq[i = 0:(tHorz-1)],
            xSideSteam[i] == aSideSteaEload * yGasTelecLoad[i] + bSideSteaEload
           )

@constraint(m, sideSteaRatioEq[i = 0:(tHorz-1)],
            xSideSteam[i] == xSideSteaDac[i] + xSteaPowLp[i]
           )

@constraint(m, availSteaDacEq[i = 0:tHorz - 1],
            xDacSteaDuty[i] == xDacSteaBaseDuty[i] + xSideSteaDac[i]
           )

@constraint(m, auxPowSteaTEq[i = 0:tHorz - 1],
            xAuxPowSteaT[i] == aAuxRateStea * yGasTelecLoad[i] + bAuxRateStea 
           )

# PCC
# 13
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], xCo2CapPcc[i] == aCo2PccCapRate * xCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz - 1], 
            xCo2CapPcc[i] == aCapRatePcc * xCo2Fuel[i])
# 14
@constraint(m, co2PccOutEq[i = 0:tHorz - 1], 
            xCo2PccOut[i] == xCo2Fuel[i] - xCo2CapPcc[i])
# 15
@constraint(m, co2DacFlueInEq[i = 0:tHorz - 1], 
            xCo2DacFlueIn[i] == xCo2PccOut[i] - vCo2PccVent[i])
# 16
# @constraint(m, co2CapPccIn[i = 0:tHorz - 1], xCo2CapPcc[i] <= vCapPcc)
# Dav: Sometimes there is not enough steam, so we have to relax this constraint 
@constraint(m, steamUsePccEq[i = 0:tHorz - 1], 
            xSteaUsePcc[i] <= aSteaUseRatePcc * xCo2CapPcc[i])
# 18
@constraint(m, powerUsePccEq[i = 0:tHorz - 1], 
            xPowUsePcc[i] == aPowUseRatePcc * xCo2CapPcc[i])

@constraint(m, pccSteaSlack[i = 0:tHorz - 1], 
            xPccSteaSlack[i] == xCcRebDuty[i] - xSteaUsePcc[i])

# DAC-Flue
@constraint(m, xA0FlueEq[i = 0:tHorz - 1], xA0Flue[i] == vAbsFlue[i])
@constraint(m, xR0FlueEq[i = 0:tHorz - 1], xR0Flue[i] == vRegFlue[i])
@constraint(m, a1dFlueEq[i = 0:tHorz - 1], xA1Flue[i + 1] == xA0Flue[i])
@constraint(m, a2dFlueEq[i = 0:tHorz - 1], xA2Flue[i + 1] == xA1Flue[i])
@constraint(m, aRdFlueEq[i = 0:tHorz - 1], xR1Flue[i + 1] == xR0Flue[i])
@constraint(m, storeFflueeq[i = 0:tHorz - 1], xFflue[i + 1] == xFflue[i] - vAbsFlue[i] + xR1Flue[i])
@constraint(m, storeSflueeq[i = 0:tHorz - 1], xSflue[i + 1] == xSflue[i] - vRegFlue[i] + xA2Flue[i])
# Initial conditions
@constraint(m, icXa1FlueEq, xA1Flue[0] == 0.)
@constraint(m, icxA2FlueEq, xA2Flue[0] == 0.)
@constraint(m, icAR1FlueEq, xR1Flue[0] == 0.)
@constraint(m, capDacFlueEq, xFflue[0] == aSorbAmountFreshFlue)
@constraint(m, icSsFlueEq, xSflue[0] == 0.)
# End-point constraints
@constraint(m, endXa1FlueEq, xA1Flue[tHorz] == 0.)
@constraint(m, endxA2FlueEq, xA2Flue[tHorz] == 0.)
@constraint(m, endAR1FlueEq, xR1Flue[tHorz] == 0.)
@constraint(m, endDacFlueEq, xFflue[tHorz] == aSorbAmountFreshFlue)
@constraint(m, endSsFlueEq, xSflue[tHorz] == 0.)


# 23
@constraint(m, co2StorDacFlueEq[i = 0:tHorz - 1], xCo2StorDacFlue[i] == aSorbCo2CapFlue * xSflue[i])
# 24
@constraint(m, co2CapDacFlueEq[i = 0:tHorz - 1], xCo2CapDacFlue[i] == aSorbCo2CapFlue * xR1Flue[i])
# 25
@constraint(m, steamUseDacFlueEq[i = 0:tHorz - 1], xSteaUseDacFlue[i] == aSteaUseRateDacFlue * xCo2CapDacFlue[i])
# 26
@constraint(m, powUseDacFlueEq[i = 0:tHorz - 1], xPowUseDacFlue[i] == aPowUseRateDacFlue * xCo2CapDacFlue[i])
# Equal to the amount vented, at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 0:tHorz - 1], xCo2DacVentFlue[i] == xCo2DacFlueIn[i] - xCo2CapDacFlue[i])

# DAC-Air
# Bluntly assume we can just take CO2 from air in pure form.
@constraint(m, xA0AirEq[i = 0:tHorz - 1], xA0Air[i] == vAbsAir[i])
@constraint(m, xR0AirEq[i = 0:tHorz - 1], xR0Air[i] == vRegAir[i])
@constraint(m, a1dAirEq[i = 0:tHorz - 1], xA1Air[i + 1] == xA0Air[i])
@constraint(m, a2dAirEq[i = 0:tHorz - 1], xA2Air[i + 1] == xA1Air[i])
@constraint(m, aRdAirEq[i = 0:tHorz - 1], xR1Air[i + 1] == xR0Air[i])
@constraint(m, storeFairEq[i = 0:tHorz - 1], xFair[i + 1] == xFair[i] - vAbsAir[i] + xR1Air[i])
@constraint(m, storeSaireq[i = 0:tHorz - 1], xSair[i + 1] == xSair[i] - vRegAir[i] + xA2Air[i])
# Initial conditions - Air
@constraint(m, capDacAirEq, xFair[0] == aSorbAmountFreshAir)
@constraint(m, icA1AirEq, xA1Air[0] == 0.)
@constraint(m, icA2AirEq, xA2Air[0] == 0.)
@constraint(m, icAR1AirEq, xR1Air[0] == 0.)
@constraint(m, icSsAirEq, xSair[0] == 0.)
# End-point conditions - Air
@constraint(m, endDacAirEq, xFair[0] == aSorbAmountFreshAir)
@constraint(m, endA1AirEq, xA1Air[0] == 0.)
@constraint(m, endA2AirEq, xA2Air[0] == 0.)
@constraint(m, endAR1AirEq, xR1Air[0] == 0.)
@constraint(m, endSsAirEq, xSair[0] == 0.)
#
@constraint(m, co2StorDacAirEq[i = 0:tHorz - 1], xCo2StorDacAir[i] == aSorbCo2CapAir * xSair[i])
# Money, baby.
@constraint(m, co2CapDacAirEq[i = 0:tHorz - 1], xCo2CapDacAir[i] == aSorbCo2CapAir * xR1Air[i])
# 
@constraint(m, steamUseDacAirEq[i = 0:tHorz - 1], xSteaUseDacAir[i] == aSteaUseRateDacAir * xCo2CapDacAir[i])
# 
@constraint(m, powUseDacAirEq[i = 0:tHorz - 1], xPowUseDacAir[i] == aPowUseRateDacAir * xCo2CapDacAir[i])


@constraint(m, dacSteaSlackEq[i = 0:tHorz - 1], 
            xDacSteaSlack[i] == xDacSteaDuty[i] - xSteaUseDacFlue[i] - xSteaUseDacAir[i])


# Co2 Compression
# 27
@constraint(m, co2CompEq[i = 0:tHorz - 1], xCo2Comp[i] == xCo2CapPcc[i] + xCo2CapDacFlue[i] + xCo2CapDacAir[i])
# 28
@constraint(m, powUseCompEq[i = 0:tHorz - 1], xPowUseComp[i] == aPowUseRateComp * xCo2Comp[i])
# 29
# @constraint(m, powUseCompIn[i = 0:tHorz - 1], xPowUseComp[i] <= vCapComp)

# @constraint(m, co2VentEq[i = 0:tHorz - 1], xCo2Vent[i] == vCo2PccVent[i] + xCo2DacVentFlue[i])
@constraint(m, co2VentEq[i = 0:tHorz - 1], 
            xCo2Vent[i] == vCo2PccVent[i] + xCo2DacVentFlue[i] - xCo2CapDacAir[i])


## Overall
#
#
@constraint(m, powGrossEq[i = 0:tHorz - 1], 
            xPowGross[i] == xPowGasTur[i] + xPowSteaTur[i]
           )
@constraint(m, auxPowEq[i = 0:tHorz - 1],
            xAuxPow[i] == xAuxPowGasT[i] + xAuxPowSteaT[i])
@constraint(m, powOutEq[i = 0:tHorz - 1], 
            xPowOut[i] == xPowGross[i] - xPowUsePcc[i] - xPowUseDacFlue[i] 
            - xPowUseDacAir[i] - xPowUseComp[i] - xAuxPow[i]
           )



@expression(m, eObjfExpr, sum(
                              cNgPerMmbtu * xFuel[i]
                              + cEmissionPrice * xCo2Vent[i]
                              + cCo2TranspPrice * xCo2Comp[i]
                              - pow_price[i+ 1] * xPowOut[i]
                              for i in 0:tHorz - 1
                             )
           )

@objective(m, Min, eObjfExpr)

set_optimizer(m, Clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 3)
set_optimizer_attribute(m, "PresolveType", 1)

optimize!(m)
println(termination_status(m))

#f = open("model.lp", "w")
#print(f, m)
#close(f)

#write_to_file(m, "lp_mk0.mps")
#format::MOI.FileFormats.FileFormat = MOI.FileFormats.FORMAT_AUTOMATIC

# Design decisions.
# vCapCombTurb
# vCapSteaTurb
# vCapTransInter
# vCapPcc
# vCapDac
# vCapComp
#
# Raw materials.
# xFuel
# sF0
# sS0
#
# penalties
# vCo2Vent
#

## vCo2PccVent * 2N

# Actual variables
# xPowGasTur * 2

# Co2 Data Frame
df_co = DataFrame(Symbol("Co2Fuel") => Float64[], # Pairs.
                  Symbol("Co2CapPcc") => Float64[],
                  Symbol("Co2PccOut") => Float64[],
                  Symbol("vCo2PccVent") => Float64[],
                  Symbol("Co2DacFlueIn") => Float64[],
                  Symbol("Co2StoreDacFlue") => Float64[],
                  Symbol("Co2CapDacFlue") => Float64[],
                  Symbol("Co2CapDacAir") => Float64[],
                  Symbol("Co2DacVentFlue") => Float64[],
                  Symbol("Co2Vent") => Float64[],
                 )
for i in 0:tHorz - 1
    push!(df_co, (
                  value(xCo2Fuel[i]),
               value(xCo2CapPcc[i]),
               value(xCo2PccOut[i]), 
               value(vCo2PccVent[i]), 
               value(xCo2DacFlueIn[i]), 
               value(xCo2StorDacFlue[i]), 
               value(xCo2CapDacFlue[i]), 
               value(xCo2CapDacAir[i]), 
               value(xCo2DacVentFlue[i]), 
               value(xCo2Vent[i])))
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
                  Symbol("yGasTelecLoad") => Float64[],
                  Symbol("Demand") => Float64[]
                 )
for i in 0:tHorz-1
    push!(df_pow, (
                   value(xPowGasTur[i]),
                   value(xPowSteaTur[i]),
                   value(xPowHp[i]), 
                   value(xPowIp[i]), 
                   value(xPowLp[i]), 
                   value(xPowUsePcc[i]), 
                   value(xPowUseDacFlue[i]), 
                   value(xPowUseDacAir[i]), 
                   value(xPowUseComp[i]),
                   value(xAuxPowGasT[i]),
                   value(xAuxPowSteaT[i]),
                   value(xPowGross[i]),
                   value(xPowOut[i]),
                   value(yGasTelecLoad[i]),
                   rnum[i + 1]
                  ))
end

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
for i in 0:tHorz-1
    push!(df_steam, (
                     value(xCcRebDuty[i]),
                     value(xSteaUsePcc[i]),
                     value(xPccSteaSlack[i]),
                     value(xDacSteaDuty[i]),
                     value(xSteaUseDacFlue[i]),
                     value(xSteaUseDacAir[i]),
                     value(xDacSteaSlack[i]),
                     value(xSideSteam[i]),
                     value(xDacSteaBaseDuty[i]),
                     value(xSideSteaDac[i]),
                     value(xFuel[i])
                    ),
         )
end

# Generate Dataframe of the DAC-Flue variables.
df_dac_flue = DataFrame(
                     :xFflue => Float64[],
                     :xSflue => Float64[],
                     :vAbsFlue => Float64[],
                     :vRegFlue => Float64[],
                     :xA0Flue => Float64[],
                     :xA1Flue => Float64[],
                     :xA2Flue => Float64[],
                     :xR0Flue => Float64[],
                     :xR1Flue => Float64[])
for i in 0:tHorz - 1
    push!(df_dac_flue,(value(xFflue[i]), value(xSflue[i]),
                  value(vAbsFlue[i]), value(vRegFlue[i]),
                  value(xA0Flue[i]), value(xA1Flue[i]), value(xA2Flue[i]),
                  value(xR0Flue[i]), value(xR1Flue[i])))
end

# Generate Dataframe of the DAC-Air variables.
df_dac_air = DataFrame(:xFair => Float64[],
                     :xSair => Float64[],
                     :vAbsAir => Float64[],
                     :vRegAir => Float64[],
                     :xA0Air => Float64[],
                     :xA1Air => Float64[],
                     :xA2Air => Float64[],
                     :xR0Air => Float64[],
                     :xR1Air => Float64[])
for i in 0:tHorz - 1
    push!(df_dac_air,(value(xFair[i]), value(xSair[i]),
                  value(vAbsAir[i]), value(vRegAir[i]),
                  value(xA0Air[i]), value(xA1Air[i]), value(xA2Air[i]),
                  value(xR0Air[i]), value(xR1Air[i])))
end


df_pow_price = DataFrame(
                         price = Float64[]
                        )
for i in 0:tHorz - 1
    push!(df_pow_price, (pow_price[i + 1],))
end


df_cost = DataFrame(
                    cNG = Float64[],
                    cCo2Em = Float64[],
                    cTransp = Float64[],
                    PowSales = Float64[]
                   )
for i in 0:tHorz - 1
    cng = cNgPerMmbtu * value(xFuel[i])
    cco = cEmissionPrice * value(xCo2Vent[i])
    ctr = cCo2TranspPrice * value(xCo2Comp[i])
    cpow = pow_price[i + 1] * value(xPowOut[i])
    push!(df_cost, (cng, cco, ctr, cpow))
end

CSV.write("df_co.csv", df_co)
CSV.write("df_pow.csv", df_pow)
CSV.write("df_steam.csv", df_steam)
CSV.write("df_dac_flue.csv", df_dac_flue)
CSV.write("df_dac_air.csv", df_dac_air)
CSV.write("df_pow_price.csv", df_pow_price)
CSV.write("df_cost.csv", df_cost)

