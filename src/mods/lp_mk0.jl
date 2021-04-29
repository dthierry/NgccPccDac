#: by David Thierry
using JuMP
using Clp
tHorz = 25
m = Model()


@variable(m, 0 <= vCapCombTurb)
@variable(m, 0 <= vPowCombTurb[1:tHorz])

@variable(m, 0 <= ePowSteamTurb[1:tHorz])
@variable(m, 0 <= vCapSteamTurb)

@variable(m, 0 <= ePowOut[1:tHorz])
@variable(m, 0 <= ePowHp[1:tHorz])
@variable(m, 0 <= ePowIp[1:tHorz])
@variable(m, 0 <= vCapTransInter)

@variable(m, 0 <= eFuel[1:tHorz])

@variable(m, 0 <= eSteamIpLp[1:tHorz])
@variable(m, 0 <= eSteamLp1[1:tHorz])

@variable(m, 0 <= ePowLp1[1:tHorz])
@variable(m, 0 <= ePowLp2[1:tHorz])

@variable(m, 0 <= eCo2Fuel[1:tHorz])

# Pcc
@variable(m, 0 <= eCo2CapPcc[1:tHorz])

@variable(m, 0 <= eSteamUsePcc[1:tHorz])
@variable(m, 0 <= ePowUsePcc[1:tHorz])

@variable(m, 0 <= eCo2PccOut[1:tHorz])

@variable(m, 0 <= vCo2PccVent[1:tHorz])
@variable(m, 0 <= vCapPcc)

# Dac
@variable(m, 0 <= eCo2DacFlueIn[1:tHorz])

@variable(m, 0 <= eSteamUseDac[1:tHorz])
@variable(m, 0 <= ePowUseDac[1:tHorz])

@variable(m, 0 <= vCapDac)

@variable(m, 0 <= a0[1:tHorz])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1[0:tHorz])
#@variable(m, 0 <= a2[1:tHorz])

@variable(m, 0 <= aR0[0:tHorz])
#@variable(m, 0 <= aR1[1:tHorz])

@variable(m, 0 <= sF[0:tHorz])
@variable(m, 0 <= sS[0:tHorz])

@variable(m, 0 <= vAbs[1:tHorz])
@variable(m, 0 <= vReg[1:tHorz])

@variable(m, 0 <= eCo2StoreDac[1:tHorz])
@variable(m, 0 <= eCo2CapDac[1:tHorz])
@variable(m, 0 <= eCo2DacVent[1:tHorz])

@variable(m, 0 <= eCo2Comp[1:tHorz])
@variable(m, 0 <= ePowUseComp[1:tHorz])
@variable(m, 0 <= vCapComp)
@variable(m, 0 <= eCo2Vent[1:tHorz])
# Parameters
pHeatRateCombTur = 1.
# pSteamRate = 1.
pEmissFactor = 1.

# pCo2CapRatePcc = 1.

#: Turbine Parameters
pFuelPowHp = 1.
pFuelPowIp = 1.
pFuelSteamIpLp = 1.
pHeatRateLp1 = 1.
pFuelPowLp = 1.
#
#
pSteamUseRatePcc = 1.
pPowUseRatePcc = 1.

pSteamUseRateDacAir = 1.
pSteamUseRateDacFlue = 1.

pPowUseRateDacAir = 1.
pPowUseRateDacFlue = 1.

pHeatRateSteamTur = 1.

pCo2PccCapRate = 1.
pSorbCo2Cap = 1.

pPowUseRateDac = 1.

pPowUseRateComp = 1.
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
pCo2TranspPrice = 0.1


# Constraints
# 1
@constraint(m, capCombTurEq[i = 1:tHorz], vPowCombTurb[i] <= vCapCombTurb)
# 2
@constraint(m, capSteamTurbEq[i = 1:tHorz], ePowSteamTurb[i] <= vCapSteamTurb)
# 3
@constraint(m, capTransmIntercEq[i = 1:tHorz], ePowOut[i] <= vCapTransInter)
# 4
@constraint(m, fuelEq[i = 1:tHorz], eFuel[i] == pHeatRateCombTur * vPowCombTurb[i])
# 5
@constraint(m, co2FuelEq[i = 1:tHorz], eCo2Fuel[i] == pEmissFactor * vPowCombTurb[i])
# 6
@constraint(m, powOutEq[i = 1:tHorz], ePowOut[i] == vPowCombTurb[i] + ePowSteamTurb[i] - ePowUseDac[i] - ePowUsePcc[i] - ePowUseComp[i])

# Steam
# 7a
@constraint(m, powHpEq[i = 1:tHorz], ePowHp[i] == pFuelPowHp * eFuel[i])
# 7b
@constraint(m, powIpEq[i = 1:tHorz], ePowIp[i] == pFuelPowIp * eFuel[i])

# 8
@constraint(m, stamIpLpEq[i = 1:tHorz], eSteamIpLp[i] == pFuelSteamIpLp * eFuel[i])
# 9
@constraint(m, steamLp1[i = 1:tHorz], eSteamLp1[i] == eSteamIpLp[i] - eSteamUsePcc[i] - eSteamUseDac[i])
# 10
@constraint(m, powLp1Eq[i = 1:tHorz], ePowLp1[i] == eSteamLp1[i] / pHeatRateLp1)
# 11
@constraint(m, powLp2Eq[i = 1:tHorz], ePowLp2[i] == pFuelPowLp * eFuel[i])
# 12
@constraint(m, powerSteamEq[i = 1:tHorz], ePowSteamTurb[i] == ePowHp[i] + ePowIp[i] + ePowLp1[i] + ePowLp2[i])

# PCC
# 13
@constraint(m, co2CapPccEq[i = 1:tHorz], eCo2CapPcc[i] == pCo2PccCapRate * eCo2Fuel[i])
# 14
@constraint(m, co2PccOutEq[i = 1:tHorz], eCo2PccOut[i] == eCo2Fuel[i] - eCo2CapPcc[i])
# 15
@constraint(m, co2DacFlueInEq[i = 1:tHorz], eCo2DacFlueIn[i] == eCo2PccOut[i] - vCo2PccVent[i])
# 16
@constraint(m, co2CapPccIn[i = 1:tHorz], eCo2CapPcc[i] <= vCapPcc)
# 17
@constraint(m, steamUsePccEq[i = 1:tHorz], eSteamUsePcc[i] == pSteamUseRatePcc * eCo2CapPcc[i])
# 18
@constraint(m, powerUsePccEq[i = 1:tHorz], ePowUsePcc[i] == pPowUseRatePcc * eCo2CapPcc[i])

# DAC
# v2 of the model.
@constraint(m, a0Eq[i = 1:tHorz], a0[i] == vAbs[i])
@constraint(m, aR0Eq[i = 1:tHorz], aR0[i] == vReg[i])
@constraint(m, a1dEq[i = 1:tHorz - 1], a1[i + 1] == a0[i])
@constraint(m, storeFeq[i = 1:tHorz - 1], sF[i + 1] == sF[i] - vAbs[i] + aR0[i])
@constraint(m, storeSeq[i = 1:tHorz - 1], sS[i + 1] == sS[i] - vReg[i] + a1[i])
# 21
@constraint(m, capDacEq, sF[0] + sS[0] == vCapDac / pSorbCo2Cap)
# 22
@constraint(m, icA1Eq, a1[0] == 0.)
# @constraint(m, icA2Eq, aR1[0] == 0.)
@constraint(m, icSfEq, sF[0] == 100.)
@constraint(m, icSsEq, sS[0] == 100.)
# 23
@constraint(m, co2StoreDacEq[i = 1:tHorz], eCo2StoreDac[i] == pSorbCo2Cap * sS[i])
# 24
@constraint(m, co2CapDacEq[i = 1:tHorz], eCo2CapDac[i] == pSorbCo2Cap * aR0[i])
# 25
@constraint(m, steamUseDacEq[i = 1:tHorz], eSteamUseDac[i] == pSteamUseRateDacFlue * eCo2CapDac[i])
# 26
@constraint(m, powUseDacEq[i = 1:tHorz], ePowUseDac[i] == pPowUseRateDacFlue * eCo2CapDac[i])
# equal to the amount vented at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 1:tHorz], eCo2DacVent[i] == eCo2DacFlueIn[i] - eCo2CapDac[i])

# Co2 Compression
# 27
@constraint(m, co2CompEq[i = 1:tHorz], eCo2Comp[i] == eCo2CapPcc[i] + eCo2CapDac[i])
# 28
@constraint(m, powUseCompEq[i = 1:tHorz], ePowUseComp[i] == pPowUseRateComp * eCo2Comp[i])
# 29
@constraint(m, powUseCompIn[i = 1:tHorz], ePowUseComp[i] <= vCapComp)

@constraint(m, co2VentEq[i = 1:tHorz], eCo2Vent[i] == vCo2PccVent[i] + eCo2DacVent[i])

@expression(m, eObjfExpr, pCostInvCombTurb * vCapCombTurb + pCostInvSteaTurb * vCapSteamTurb
                           + pCostInvTransInter * vCapTransInter + pCostInvPcc * vCapPcc
                           + pCostInvDac * vCapDac + pCostInvComp * vCapComp
                           + sum(pCostFuel * eFuel[i] + pEmissionPrice * eCo2Vent[i] + pCo2TranspPrice * eCo2Comp[i] for i in 1:tHorz))
#@objective(m, Min, eobjf)
@objective(m, Min, eObjfExpr)

set_optimizer(m, Clp.Optimizer)
set_optimizer_attribute(m, "LogLevel", 4)
set_optimizer_attribute(m, "PresolveType", 1)

optimize!(m)
println(termination_status(m))
println(value.(ePowOut)[:])
println(value.(sF)[:])
println(value.(sS)[:])
println(value.(a1)[:])

write_to_file(
    m,
    "lp_mk0.mps";
    #format::MOI.FileFormats.FileFormat = MOI.FileFormats.FORMAT_AUTOMATIC
)

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
