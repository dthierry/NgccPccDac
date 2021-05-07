# vim: set wrap
#: by David Thierry 2021
using JuMP
using Clp
using DataFrames
using StatsPlots
using CSV

tHorz = 24
m = Model()

#vCapCombTurb = 3.
vCapSteamTurb = 2.
vCapTransInter = 5.
vCapPcc = 20.
vCapComp = 1000.

rnum = rand(Float64, tHorz)

#@variable(m, 0 <= vCapCombTurb)
#@variable(m, 0 <= vPowCombTurb[0:tHorz - 1] <= vCapCombTurb)
@variable(m, 0 <= vPowCombTurb[0:tHorz - 1])

#@variable(m, 0 <= ePowSteamTurb[0:tHorz - 1] <= vCapSteamTurb)
@variable(m, 0 <= ePowSteamTurb[0:tHorz - 1])
#@variable(m, 0 <= vCapSteamTurb)

#@variable(m, rnum[i+1] <= ePowOut[i = 0:tHorz - 1] <= vCapTransInter)
@variable(m, ePowOut[i = 0:tHorz - 1] >= rnum[i + 1])
@variable(m, 0 <= ePowGross[0:tHorz - 1])
#@variable(m, 0 <= ePowOut[i = 0:tHorz - 1])
@variable(m, 0 <= ePowHp[0:tHorz - 1])
@variable(m, 0 <= ePowIp[0:tHorz - 1])
#@variable(m, 0 <= vCapTransInter)

@variable(m, 0 <= eFuel[0:tHorz - 1])

@variable(m, 0 <= eSteamIpLp[0:tHorz - 1])
@variable(m, 0 <= eSteamLp1[0:tHorz - 1])

@variable(m, 0 <= ePowLp1[0:tHorz - 1])
@variable(m, 0 <= ePowLp2[0:tHorz - 1])

@variable(m, 0 <= eCo2Fuel[0:tHorz - 1])

# Pcc
#@variable(m, 0 <= eCo2CapPcc[0:tHorz - 1] <= vCapPcc)
@variable(m, 0 <= eCo2CapPcc[0:tHorz - 1])
@variable(m, 0 <= eSteamUsePcc[0:tHorz - 1])
@variable(m, 0 <= ePowUsePcc[0:tHorz - 1])
@variable(m, 0 <= eCo2PccOut[0:tHorz - 1])
#@variable(m, 0 <= vCo2PccVent[0:tHorz - 1] <= 0.1)
@variable(m, 0 <= vCo2PccVent[0:tHorz - 1])
#vCo2PccVent = 0.0
@variable(m, 0 <= eCo2DacFlueIn[0:tHorz - 1])

# Dac-Flue
@variable(m, 0 <= a0Flue[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1Flue[0:tHorz]) # State
@variable(m, 0 <= a2Flue[0:tHorz]) # State

@variable(m, 0 <= aR0Flue[0:tHorz - 1])  # Not-a-State
@variable(m, 0 <= aR1Flue[0:tHorz])  # State
@variable(m, 0 <= sFflue[0:tHorz])  # State
@variable(m, 0 <= sSflue[0:tHorz])  # State

@variable(m, 0 <= vAbsFlue[0:tHorz - 1])  # Input
@variable(m, 0 <= vRegFlue[0:tHorz - 1])  # Input

@variable(m, 0 <= eCo2StorDacFlue[0:tHorz - 1])
@variable(m, 0 <= eCo2CapDacFlue[0:tHorz - 1])
@variable(m, eSteaUseDacFlue[0:tHorz - 1] >= 0)
@variable(m, 0 <= ePowUseDacFlue[0:tHorz - 1])
@variable(m, 0 <= eCo2DacVentFlue[0:tHorz - 1])

# Dac-Air
@variable(m, 0 <= a0Air[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1Air[0:tHorz]) # State
@variable(m, 0 <= a2Air[0:tHorz]) # State

@variable(m, 0 <= aR0Air[0:tHorz - 1])  # Not-a-State
@variable(m, 0 <= aR1Air[0:tHorz])  # State
@variable(m, 0 <= sFair[0:tHorz])  # State
@variable(m, 0 <= sSair[0:tHorz])  # State

@variable(m, 0 <= vAbsAir[0:tHorz - 1])  # Input
@variable(m, 0 <= vRegAir[0:tHorz - 1])  # Input

@variable(m, 0 <= eCo2StorDacAir[0:tHorz - 1])
@variable(m, 0 <= eCo2CapDacAir[0:tHorz - 1])
@variable(m, eSteaUseDacAir[0:tHorz - 1] >= 0)
@variable(m, 0 <= ePowUseDacAir[0:tHorz - 1])

# CO2 compression
@variable(m, 0 <= eCo2Comp[0:tHorz - 1])
#@variable(m, 0 <= ePowUseComp[0:tHorz - 1] <= vCapComp)
@variable(m, 0 <= ePowUseComp[0:tHorz - 1])
#@variable(m, 0 <= vCapComp)
@variable(m, eCo2Vent[0:tHorz - 1])  # This used to be only positive.

# Parameters
pHeatRateCombTur = 1.
# pSteamRate = 1.
pEmissFactor = 20.1

# pCo2CapRatePcc = 1.

#: Turbine Parameters
pFuelPowHp = 1.
pFuelPowIp = 0.4
pFuelSteamIpLp = 1.
pHeatRateLp1 = 11.11
pFuelPowLp = 0.09
#
#
pSteamUseRatePcc = 0.001
pPowUseRatePcc = 0.022

pSteaUseRateDacAir = 1e-03
pSteaUseRateDacFlue = 1e-03

pPowUseRateDacAir = 5e-03
pPowUseRateDacFlue = 2e-03

pHeatRateSteamTur = 1.

pCo2PccCapRate = .1
pSorbCo2CapFlue = 0.1
pSorbCo2CapAir = 1e-06
pPowUseRateDac = 0.0001

pPowUseRateComp = 0.001
#

pCostInvCombTurb = 1e+02
pCostInvSteaTurb = 1e+02
pCostInvTransInter = 1e+02
pCostInvPcc = 1e+02
pCostInvDac = 1e+03
pCostInvComp = 1e+01

# Cost parameters.
pCostFuel = 1e+02
pEmissionPrice = 1e+04
pCo2TranspPrice = 1e+01
pPowBasePrice = 1e+01
pCo2Credit = 1e+00

# Constraints
# 1
#@constraint(m, capCombTurIn[i = 0:tHorz - 1], vPowCombTurb[i] <= vCapCombTurb)
# 2
# @constraint(m, capSteamTurbIn[i = 0:tHorz - 1], ePowSteamTurb[i] <= vCapSteamTurb)
# 3
# @constraint(m, capTransmIntercIn[i = 0:tHorz - 1], ePowOut[i] <= vCapTransInter)
# 4
@constraint(m, fuelEq[i = 0:tHorz - 1], eFuel[i] == pHeatRateCombTur * vPowCombTurb[i])
# 5
@constraint(m, co2FuelEq[i = 0:tHorz - 1], eCo2Fuel[i] == pEmissFactor * vPowCombTurb[i])
@constraint(m, powGrossEq[i = 0:tHorz - 1], ePowGross[i] == vPowCombTurb[i] + ePowSteamTurb[i])
# 6
@constraint(m, powOutEq[i = 0:tHorz - 1], ePowOut[i] ==  ePowGross[i] - ePowUsePcc[i] - ePowUseDacFlue[i] - ePowUseDacAir[i] - ePowUseComp[i])

# Steam
# 7a
@constraint(m, powHpEq[i = 0:tHorz - 1], ePowHp[i] == pFuelPowHp * eFuel[i])
# 7b
@constraint(m, powIpEq[i = 0:tHorz - 1], ePowIp[i] == pFuelPowIp * eFuel[i])

# 8
@constraint(m, stamIpLpEq[i = 0:tHorz - 1], eSteamIpLp[i] == pFuelSteamIpLp * eFuel[i])
# 9
@constraint(m, steamLp1[i = 0:tHorz - 1], eSteamLp1[i] == eSteamIpLp[i] - eSteamUsePcc[i] - eSteaUseDacFlue[i] -eSteaUseDacAir[i])
# 10
@constraint(m, powLp1Eq[i = 0:tHorz - 1], ePowLp1[i] == eSteamLp1[i] / pHeatRateLp1)
# 11
@constraint(m, powLp2Eq[i = 0:tHorz - 1], ePowLp2[i] == pFuelPowLp * eFuel[i])
# 12
@constraint(m, powerSteamEq[i = 0:tHorz - 1], ePowSteamTurb[i] == ePowHp[i] + ePowIp[i] + ePowLp1[i] + ePowLp2[i])

# PCC
# 13
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], eCo2CapPcc[i] == pCo2PccCapRate * eCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz - 1], eCo2CapPcc[i] == 0.5 * eCo2Fuel[i])
# 14
@constraint(m, co2PccOutEq[i = 0:tHorz - 1], eCo2PccOut[i] == eCo2Fuel[i] - eCo2CapPcc[i])
# 15
@constraint(m, co2DacFlueInEq[i = 0:tHorz - 1], eCo2DacFlueIn[i] == eCo2PccOut[i] - vCo2PccVent[i])
# 16
# @constraint(m, co2CapPccIn[i = 0:tHorz - 1], eCo2CapPcc[i] <= vCapPcc)
# 17
@constraint(m, steamUsePccEq[i = 0:tHorz - 1], eSteamUsePcc[i] == pSteamUseRatePcc * eCo2CapPcc[i])
# 18
@constraint(m, powerUsePccEq[i = 0:tHorz - 1], ePowUsePcc[i] == pPowUseRatePcc * eCo2CapPcc[i])

# DAC-Flue
@constraint(m, a0FlueEq[i = 0:tHorz - 1], a0Flue[i] == vAbsFlue[i])
@constraint(m, aR0FlueEq[i = 0:tHorz - 1], aR0Flue[i] == vRegFlue[i])
@constraint(m, a1dFlueEq[i = 0:tHorz - 1], a1Flue[i + 1] == a0Flue[i])
@constraint(m, a2dFlueEq[i = 0:tHorz - 1], a2Flue[i + 1] == a1Flue[i])
@constraint(m, aRdFlueEq[i = 0:tHorz - 1], aR1Flue[i + 1] == aR0Flue[i])
@constraint(m, storeFflueeq[i = 0:tHorz - 1], sFflue[i + 1] == sFflue[i] - vAbsFlue[i] + aR1Flue[i])
@constraint(m, storeSflueeq[i = 0:tHorz - 1], sSflue[i + 1] == sSflue[i] - vRegFlue[i] + a2Flue[i])
@constraint(m, capDacFlueEq, sFflue[0] == 100)
# 22
@constraint(m, icA1FlueEq, a1Flue[0] == 0.)
@constraint(m, icA2FlueEq, a2Flue[0] == 0.)
@constraint(m, icAR1FlueEq, aR1Flue[0] == 0.)
#
@constraint(m, icSsFlueEq, sSflue[0] == 0.)
# 23
@constraint(m, co2StorDacFlueEq[i = 0:tHorz - 1], eCo2StorDacFlue[i] == pSorbCo2CapFlue * sSflue[i])
# 24
@constraint(m, co2CapDacFlueEq[i = 0:tHorz - 1], eCo2CapDacFlue[i] == pSorbCo2CapFlue * aR1Flue[i])
# 25
@constraint(m, steamUseDacFlueEq[i = 0:tHorz - 1], eSteaUseDacFlue[i] == pSteaUseRateDacFlue * eCo2CapDacFlue[i])
# 26
@constraint(m, powUseDacFlueEq[i = 0:tHorz - 1], ePowUseDacFlue[i] == pPowUseRateDacFlue * eCo2CapDacFlue[i])
# Equal to the amount vented, at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 0:tHorz - 1], eCo2DacVentFlue[i] == eCo2DacFlueIn[i] - eCo2CapDacFlue[i])

# DAC-Air
# Bluntly assume we can just take CO2 from air in pure form.
@constraint(m, a0AirEq[i = 0:tHorz - 1], a0Air[i] == vAbsAir[i])
@constraint(m, aR0AirEq[i = 0:tHorz - 1], aR0Air[i] == vRegAir[i])
@constraint(m, a1dAirEq[i = 0:tHorz - 1], a1Air[i + 1] == a0Air[i])
@constraint(m, a2dAirEq[i = 0:tHorz - 1], a2Air[i + 1] == a1Air[i])
@constraint(m, aRdAirEq[i = 0:tHorz - 1], aR1Air[i + 1] == aR0Air[i])
@constraint(m, storeFairEq[i = 0:tHorz - 1], sFair[i + 1] == sFair[i] - vAbsAir[i] + aR1Air[i])
@constraint(m, storeSaireq[i = 0:tHorz - 1], sSair[i + 1] == sSair[i] - vRegAir[i] + a2Air[i])
@constraint(m, capDacAirEq, sFair[0] == 1000)
# 
@constraint(m, icA1AirEq, a1Air[0] == 0.)
@constraint(m, icA2AirEq, a2Air[0] == 0.)
@constraint(m, icAR1AirEq, aR1Air[0] == 0.)
#
@constraint(m, icSsAirEq, sSair[0] == 0.)
# 
@constraint(m, co2StorDacAirEq[i = 0:tHorz - 1], eCo2StorDacAir[i] == pSorbCo2CapAir * sSair[i])
# Money, baby.
@constraint(m, co2CapDacAirEq[i = 0:tHorz - 1], eCo2CapDacAir[i] == pSorbCo2CapAir * aR1Air[i])
# 
@constraint(m, steamUseDacAirEq[i = 0:tHorz - 1], eSteaUseDacAir[i] == pSteaUseRateDacAir * eCo2CapDacAir[i])
# 
@constraint(m, powUseDacAirEq[i = 0:tHorz - 1], ePowUseDacAir[i] == pPowUseRateDacAir * eCo2CapDacAir[i])

# Co2 Compression
# 27
@constraint(m, co2CompEq[i = 0:tHorz - 1], eCo2Comp[i] == eCo2CapPcc[i])
# 28
@constraint(m, powUseCompEq[i = 0:tHorz - 1], ePowUseComp[i] == pPowUseRateComp * eCo2Comp[i])
# 29
# @constraint(m, powUseCompIn[i = 0:tHorz - 1], ePowUseComp[i] <= vCapComp)

# @constraint(m, co2VentEq[i = 0:tHorz - 1], eCo2Vent[i] == vCo2PccVent[i] + eCo2DacVentFlue[i])
@constraint(m, co2VentEq[i = 0:tHorz - 1], eCo2Vent[i] == vCo2PccVent[i] + eCo2DacVentFlue[i] - eCo2CapDacAir[i])

@expression(m, eObjfExpr, sum(pCostFuel * eFuel[i] + 
                              pEmissionPrice * eCo2Vent[i] + 
                              pCo2TranspPrice * eCo2Comp[i] - 
                              pPowBasePrice * ePowOut[i] for i in 0:tHorz - 1))
#@expression(m, eObjfExpr, sum(-ePowOut[i] for i in 0:tHorz - 1))

@objective(m, Min, eObjfExpr)

set_optimizer(m, Clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 3)
set_optimizer_attribute(m, "PresolveType", 1)

optimize!(m)
println(termination_status(m))

#f = open("model.lp", "w")
#print(f, m)
#close(f)

write_to_file(m, "lp_mk0.mps")
#format::MOI.FileFormats.FileFormat = MOI.FileFormats.FORMAT_AUTOMATIC

# Design decisions.
# vCapCombTurb
# vCapSteamTurb
# vCapTransInter
# vCapPcc
# vCapDac
# vCapComp
#
# Raw materials.
# eFuel
# sF0
# sS0
#
# penalties
# vCo2Vent
#

## vCo2PccVent * 2N

# Actual variables
# vPowCombTurb * 2

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
    push!(df_co, (value(eCo2Fuel[i]),
               value(eCo2CapPcc[i]),
               value(eCo2PccOut[i]), 
               value(vCo2PccVent[i]), 
               value(eCo2DacFlueIn[i]), 
               value(eCo2StorDacFlue[i]), 
               value(eCo2CapDacFlue[i]), 
               value(eCo2CapDacAir[i]), 
               value(eCo2DacVentFlue[i]), 
               value(eCo2Vent[i])))
end

# Power Data Frame.
df_pow = DataFrame(Symbol("vPowCombTurb") => Float64[], # Pairs.
                  Symbol("PowSteamTurb") => Float64[],
                  Symbol("PowHp") => Float64[],
                  Symbol("PowIp") => Float64[],
                  Symbol("PowLp1") => Float64[],
                  Symbol("PowLp2") => Float64[],
                  Symbol("PowUsePcc") => Float64[],
                  Symbol("PowUseDacFlue") => Float64[],
                  Symbol("PowUseDacAir") => Float64[],
                  Symbol("PowUseComp") => Float64[],
                  Symbol("PowGross") => Float64[],
                  Symbol("PowOut") => Float64[],
                  Symbol("Demand") => Float64[]
                 )
for i in 0:tHorz-1
    push!(df_pow, (
                   value(vPowCombTurb[i]),
                   value(ePowSteamTurb[i]),
                   value(ePowHp[i]), 
                   value(ePowIp[i]), 
                   value(ePowLp1[i]), 
                   value(ePowLp2[i]), 
                   value(ePowUsePcc[i]), 
                   value(ePowUseDacFlue[i]), 
                   value(ePowUseDacAir[i]), 
                   value(ePowUseComp[i]),
                   value(ePowGross[i]),
                   value(ePowOut[i]),
                   rnum[i + 1]
                  ))
end

df_steam = DataFrame(Symbol("SteamIpLp") => Float64[], # Pairs.
                     Symbol("SteamLp1") => Float64[],
                     Symbol("SteamUsePccFlue") => Float64[],
                     Symbol("SteamUseDacFlue") => Float64[],
                     Symbol("SteamUseDacAir") => Float64[],
                     Symbol("Fuel") => Float64[]
                    )
for i in 0:tHorz-1
    push!(df_steam, (
                     value(eSteamIpLp[i]),
                     value(eSteamLp1[i]),
                     value(eSteamUsePcc[i]),
                     value(eSteaUseDacFlue[i]),
                     value(eSteaUseDacAir[i]),
                     value(eFuel[i])
                    ),
         )
end

# Generate Dataframe of the DAC-Flue variables.
df_dac_flue = DataFrame(:sFflue => Float64[],
                     :sSflue => Float64[],
                     :vAbsFlue => Float64[],
                     :vRegFlue => Float64[],
                     :a0Flue => Float64[],
                     :a1Flue => Float64[],
                     :a2Flue => Float64[],
                     :aR0Flue => Float64[],
                     :aR1Flue => Float64[])
for i in 0:tHorz - 1
    push!(df_dac_flue,(value(sFflue[i]), value(sSflue[i]),
                  value(vAbsFlue[i]), value(vRegFlue[i]),
                  value(a0Flue[i]), value(a1Flue[i]), value(a2Flue[i]),
                  value(aR0Flue[i]), value(aR1Flue[i])))
end

# Generate Dataframe of the DAC-Air variables.
df_dac_air = DataFrame(:sFair => Float64[],
                     :sSair => Float64[],
                     :vAbsAir => Float64[],
                     :vRegAir => Float64[],
                     :a0Air => Float64[],
                     :a1Air => Float64[],
                     :a2Air => Float64[],
                     :aR0Air => Float64[],
                     :aR1Air => Float64[])
for i in 0:tHorz - 1
    push!(df_dac_air,(value(sFair[i]), value(sSair[i]),
                  value(vAbsAir[i]), value(vRegAir[i]),
                  value(a0Air[i]), value(a1Air[i]), value(a2Air[i]),
                  value(aR0Air[i]), value(aR1Air[i])))
end


#print(df_co)
#print(df_pow)
#print(df_steam)
#print(df_dac)

CSV.write("df_co.csv", df_co)
CSV.write("df_pow.csv", df_pow)
CSV.write("df_steam.csv", df_steam)
CSV.write("df_dac_flue.csv", df_dac_flue)
CSV.write("df_dac_air.csv", df_dac_air)

