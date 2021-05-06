#: by David Thierry 2021
using JuMP
using Clp
using DataFrames
using StatsPlots
using CSV
tHorz = 30
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

# Dac
@variable(m, 0 <= a0[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1[0:tHorz])
#@variable(m, 0 <= a2[0:tHorz - 1])

@variable(m, 0 <= aR0[0:tHorz - 1])
#@variable(m, 0 <= aR1[0:tHorz - 1])

@variable(m, 0 <= sF[0:tHorz])
@variable(m, 0 <= sS[0:tHorz])

@variable(m, 0 <= vAbs[0:tHorz - 1])
@variable(m, 0 <= vReg[0:tHorz - 1])

@variable(m, 0 <= eCo2StoreDac[0:tHorz - 1])
@variable(m, 0 <= eCo2CapDac[0:tHorz - 1])
@variable(m, eSteamUseDac[0:tHorz - 1] >= 0)
@variable(m, 0 <= ePowUseDac[0:tHorz - 1])
# CO2 compression

@variable(m, 0 <= eCo2DacVent[0:tHorz - 1])

@variable(m, 0 <= eCo2Comp[0:tHorz - 1])
#@variable(m, 0 <= ePowUseComp[0:tHorz - 1] <= vCapComp)
@variable(m, 0 <= ePowUseComp[0:tHorz - 1])
#@variable(m, 0 <= vCapComp)
@variable(m, 0 <= eCo2Vent[0:tHorz - 1])

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
pPowUseRatePcc = 0.0022

pSteamUseRateDacAir = 0.00001
pSteamUseRateDacFlue = 0.00001

pPowUseRateDacAir = 0.0001
pPowUseRateDacFlue = 0.00002

pHeatRateSteamTur = 1.

pCo2PccCapRate = .1
pSorbCo2Cap = 0.1

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
pPowBasePrice = 1e+02


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
@variable(m, 0 <= ePowGross[0:tHorz - 1])
@constraint(m, powGrossEq[i = 0:tHorz - 1], ePowGross[i] == vPowCombTurb[i] + ePowSteamTurb[i])
# 6
@constraint(m, powOutEq[i = 0:tHorz - 1], ePowOut[i] ==  ePowGross[i] - ePowUsePcc[i] - ePowUseDac[i] - ePowUseComp[i])

# Steam
# 7a
@constraint(m, powHpEq[i = 0:tHorz - 1], ePowHp[i] == pFuelPowHp * eFuel[i])
# 7b
@constraint(m, powIpEq[i = 0:tHorz - 1], ePowIp[i] == pFuelPowIp * eFuel[i])

# 8
@constraint(m, stamIpLpEq[i = 0:tHorz - 1], eSteamIpLp[i] == pFuelSteamIpLp * eFuel[i])
# 9
@constraint(m, steamLp1[i = 0:tHorz - 1], eSteamLp1[i] == eSteamIpLp[i] - eSteamUsePcc[i] - eSteamUseDac[i])
# 10
@constraint(m, powLp1Eq[i = 0:tHorz - 1], ePowLp1[i] == eSteamLp1[i] / pHeatRateLp1)
# 11
@constraint(m, powLp2Eq[i = 0:tHorz - 1], ePowLp2[i] == pFuelPowLp * eFuel[i])
# 12
@constraint(m, powerSteamEq[i = 0:tHorz - 1], ePowSteamTurb[i] == ePowHp[i] + ePowIp[i] + ePowLp1[i] + ePowLp2[i])

# PCC
# 13
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], eCo2CapPcc[i] == pCo2PccCapRate * eCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz - 1], eCo2CapPcc[i] == 0.95 * eCo2Fuel[i])
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

# DAC
@constraint(m, a0Eq[i = 0:tHorz - 1], a0[i] == vAbs[i])
@constraint(m, aR0Eq[i = 0:tHorz - 1], aR0[i] == vReg[i])

@constraint(m, a1dEq[i = 0:tHorz - 1], a1[i + 1] == a0[i])
@constraint(m, storeFeq[i = 0:tHorz - 1], sF[i + 1] == sF[i] - vAbs[i] + aR0[i])
@constraint(m, storeSeq[i = 0:tHorz - 1], sS[i + 1] == sS[i] - vReg[i] + a1[i])
@constraint(m, capDacEq, sF[0] == 100 / pSorbCo2Cap)
# 22
@constraint(m, icA1Eq, a1[0] == 0.)
# @constraint(m, icA2Eq, aR1[0] == 0.)
#@constraint(m, icSfEq, sF[0] == 100.)
@constraint(m, icSsEq, sS[0] == 0.)
# 23
@constraint(m, co2StoreDacEq[i = 0:tHorz - 1], eCo2StoreDac[i] == pSorbCo2Cap * sS[i])
# 24
@constraint(m, co2CapDacEq[i = 0:tHorz - 1], eCo2CapDac[i] == pSorbCo2Cap * aR0[i])
# 25
@constraint(m, steamUseDacEq[i = 0:tHorz - 1], eSteamUseDac[i] == pSteamUseRateDacFlue * eCo2CapDac[i])
# 26
@constraint(m, powUseDacEq[i = 0:tHorz - 1], ePowUseDac[i] == pPowUseRateDacFlue * eCo2CapDac[i])
# equal to the amount vented at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 0:tHorz - 1], eCo2DacVent[i] == eCo2DacFlueIn[i] - eCo2CapDac[i])
#
# Co2 Compression
# 27
@constraint(m, co2CompEq[i = 0:tHorz - 1], eCo2Comp[i] == eCo2CapPcc[i])
# 28
@constraint(m, powUseCompEq[i = 0:tHorz - 1], ePowUseComp[i] == pPowUseRateComp * eCo2Comp[i])
# 29
# @constraint(m, powUseCompIn[i = 0:tHorz - 1], ePowUseComp[i] <= vCapComp)

@constraint(m, co2VentEq[i = 0:tHorz - 1], eCo2Vent[i] == vCo2PccVent[i] + eCo2DacVent[i])

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
                  Symbol("Co2StoreDac") => Float64[],
                  Symbol("Co2CapDac") => Float64[],
                  Symbol("Co2DacVent") => Float64[],
                  Symbol("Co2Vent") => Float64[],
                 )
for i in 0:tHorz-1
    push!(df_co, (value(eCo2Fuel[i]),
               value(eCo2CapPcc[i]),
               value(eCo2PccOut[i]), 
               value(vCo2PccVent[i]), 
               value(eCo2DacFlueIn[i]), 
               value(eCo2StoreDac[i]), 
               value(eCo2CapDac[i]), 
               value(eCo2DacVent[i]), 
               value(eCo2Vent[i])))
end

print(df_co)

df_pow = DataFrame(Symbol("vPowCombTurb") => Float64[], # Pairs.
                  Symbol("PowSteamTurb") => Float64[],
                  Symbol("PowHp") => Float64[],
                  Symbol("PowIp") => Float64[],
                  Symbol("PowLp1") => Float64[],
                  Symbol("PowLp2") => Float64[],
                  Symbol("PowUsePcc") => Float64[],
                  Symbol("PowUseDac") => Float64[],
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
                   value(ePowUseDac[i]), 
                   value(ePowUseComp[i]),
                   value(ePowGross[i]),
                   value(ePowOut[i]),
                   rnum[i + 1]
                  ))
end

df_steam = DataFrame(Symbol("SteamIpLp") => Float64[], # Pairs.
                     Symbol("SteamLp1") => Float64[],
                     Symbol("SteamUsePcc") => Float64[],
                     Symbol("SteamUseDac") => Float64[],
                     Symbol("Fuel") => Float64[]
                    )
for i in 0:tHorz-1
    push!(df_steam, (
                     value(eSteamIpLp[i]),
                     value(eSteamLp1[i]),
                     value(eSteamUsePcc[i]),
                     value(eSteamUseDac[i]),
                     value(eFuel[i])
                    ),
         )
end
# Generate Dataframe of the DAC variables.
df_dac = DataFrame(:sF => Float64[],
                     :sS => Float64[],
                     :vAbs => Float64[],
                     :vReg => Float64[],
                     :a0 => Float64[],
                     :a1 => Float64[],
                     :aR0 => Float64[])
for i in 0:tHorz - 1
    push!(df_dac,(value(sF[i]), value(sS[i]),
                  value(vAbs[i]), value(vReg[i]),
                  value(a0[i]), value(a1[i]),
                  value(aR0[i])))
end

print(df_co)
print(df_pow)
print(df_steam)
print(df_dac)

CSV.write("df_co.csv", df_co)
CSV.write("df_pow.csv", df_pow)
CSV.write("df_steam.csv", df_steam)
CSV.write("df_dac.csv", df_dac)

