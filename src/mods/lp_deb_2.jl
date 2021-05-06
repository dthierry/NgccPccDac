#: by David Thierry
using JuMP
using Clp
using DataFrames
using StatsPlots
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


#@variable(m, 0 <= a0[0:tHorz - 1])  # We could generalize this for any number of hours.
#@variable(m, 0 <= a1[0:tHorz])
#@variable(m, 0 <= a2[0:tHorz - 1])

#@variable(m, 0 <= aR0[0:tHorz - 1])
#@variable(m, 0 <= aR1[0:tHorz - 1])

#@variable(m, 0 <= sF[0:tHorz])
#@variable(m, 0 <= sS[0:tHorz])

@variable(m, 0 <= eCo2DacVent[0:tHorz - 1])

@variable(m, 0 <= eCo2Comp[0:tHorz - 1])
#@variable(m, 0 <= ePowUseComp[0:tHorz - 1] <= vCapComp)
@variable(m, 0 <= ePowUseComp[0:tHorz - 1])
#@variable(m, 0 <= vCapComp)
@variable(m, 0 <= eCo2Vent[0:tHorz - 1])

# Parameters
pHeatRateCombTur = 1.
# pSteamRate = 1.
pEmissFactor = 200.1

# pCo2CapRatePcc = 1.

#: Turbine Parameters
pFuelPowHp = 1.
pFuelPowIp = 1.
pFuelSteamIpLp = 1.
pHeatRateLp1 = 1.
pFuelPowLp = 1.
#
#
pSteamUseRatePcc = 0.001
pPowUseRatePcc = 0.022

pSteamUseRateDacAir = 0.00001
pSteamUseRateDacFlue = 0.00001

pPowUseRateDacAir = 0.0001
pPowUseRateDacFlue = 0.02

pHeatRateSteamTur = 1.

pCo2PccCapRate = .1
pSorbCo2Cap = 0.1

pPowUseRateDac = 0.001

pPowUseRateComp = 0.001
#

pCostInvCombTurb = 1e+02
pCostInvSteaTurb = 1e+02
pCostInvTransInter = 1e+02
pCostInvPcc = 1e+02
pCostInvDac = 1e+03
pCostInvComp = 1e+01

# Cost parameters.
pCostFuel = 100.
pEmissionPrice = 1.
pCo2TranspPrice = 1e+03


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
@constraint(m, powOutEq[i = 0:tHorz - 1], ePowOut[i] ==  ePowGross[i] - ePowUsePcc[i] - ePowUseComp[i])

# Steam
# 7a
@constraint(m, powHpEq[i = 0:tHorz - 1], ePowHp[i] == pFuelPowHp * eFuel[i])
# 7b
@constraint(m, powIpEq[i = 0:tHorz - 1], ePowIp[i] == pFuelPowIp * eFuel[i])

# 8
@constraint(m, stamIpLpEq[i = 0:tHorz - 1], eSteamIpLp[i] == pFuelSteamIpLp * eFuel[i])
# 9
@constraint(m, steamLp1[i = 0:tHorz - 1], eSteamLp1[i] == eSteamIpLp[i] - eSteamUsePcc[i])
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


@constraint(m, co2DacFlueVentEq[i = 0:tHorz - 1], eCo2DacVent[i] == eCo2DacFlueIn[i])
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
                              ePowOut[i] * 10 for i in 0:tHorz - 1))
#@expression(m, eObjfExpr, sum(-ePowOut[i] for i in 0:tHorz - 1))

@objective(m, Min, eObjfExpr)

set_optimizer(m, Clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 3)
set_optimizer_attribute(m, "PresolveType", 1)

# set_start_value(vCapCombTurb, 3.)
# set_start_value(vCapSteamTurb, 2.)
# set_start_value(vCapTransInter, 5.)
# set_start_value(vCapPcc, 5.)
# set_start_value(vCapComp, 8.)

# fix(vCapCombTurb, 3., force = true)
# fix(vCapSteamTurb, 2., force = true)
# fix(vCapTransInter, 5., force = true)
# fix(vCapPcc, 5., force = true)
# fix(vCapComp, 8., force = true)

# fix(a0[0], 0., force = true)
# fix(aR0[0], 0., force = true)
# fix(vAbs[0], 0., force = true)
# fix(vReg[0], 0., force = true)

#fix.(a0, 0., force = true)
#fix.(aR0, 0., force = true)
#fix.(vAbs, 0., force = true)
#fix.(vReg, 0., force = true)

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

df = DataFrame(Symbol("eFuel[i]") => Float64[],
               Symbol("eCo2Fuel[i]") => Float64[],
               Symbol("eCo2CapPcc[i]") => Float64[],
               Symbol("eCo2Vent") => Float64[],
               Symbol("vCo2PccVent") => Float64[],
               Symbol("ePowUsePcc[i]") => Float64[],
               Symbol("ePowUseComp[i]") => Float64[],
               Symbol("demand") => Float64[],
               Symbol("ePowGross") => Float64[],
               Symbol("ePowOut") => Float64[])
for i in 0:tHorz-1
    push!(df, (value(eFuel[i]),
               value(eCo2Fuel[i]),
               value(eCo2CapPcc[i]), 
               value(eCo2Vent[i]), 
               value(vCo2PccVent[i]), 
               value(ePowUsePcc[i]), 
               value(ePowUseComp[i]), 
               rnum[i+1], 
               value(ePowGross[i]), 
               value(ePowOut[i])))
end

print(df)

