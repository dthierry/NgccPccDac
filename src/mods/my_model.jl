#: by David T
using JuMP

tHorz = 25
m = Model()

#@variable(m, 0 <= vCapCombTurb[0:tHorz])
@variable(m, 0 <= vCapCombTurb)
@variable(m, 0 <= vPowCombTurb[0:tHorz])

@variable(m, 0 <= ePowSteamTurb[0:tHorz])
#@variable(m, 0 <= vCapSteamTurb[0:tHorz])
@variable(m, 0 <= vCapSteamTurb)

@variable(m, 0 <= ePowOut[0:tHorz])
#@variable(m, 0 <= vCapTransInter[0:tHorz])
@variable(m, 0 <= ePowHp[0:tHorz])
@variable(m, 0 <= ePowIp[0:tHorz])
@variable(m, 0 <= ePowLp[0:tHorz])
@variable(m, 0 <= vCapTransInter)

@variable(m, 0 <= eFuel[0:tHorz])
@variable(m, 0 <= eSteam[0:tHorz])
@variable(m, 0 <= eSteamHp[0:tHorz])
@variable(m, 0 <= eSteamIp[0:tHorz])
@variable(m, 0 <= eSteamLp[0:tHorz])

@variable(m, 0 <= eCo2Fuel[0:tHorz])

# Pcc
@variable(m, 0 <= eCo2CapPcc[0:tHorz])
# @variable(m, 0 <= eCo2Vent[0:tHorz])

@variable(m, 0 <= eSteamUsePcc[0:tHorz])
@variable(m, 0 <= ePowUsePcc[0:tHorz])

@variable(m, 0 <= eCo2PccOut[0:tHorz])

@variable(m, 0 <= vCo2PccVent[0:tHorz])

@variable(m, 0 <= vCapPcc)

# Dac
@variable(m, 0 <= eCo2DacFlueIn[0:tHorz])

@variable(m, 0 <= eSteamUseDac[0:tHorz])
@variable(m, 0 <= ePowUseDac[0:tHorz])

@variable(m, 0 <= vCaptureDac)
@variable(m, 0 <= eCo2CaptureDac[0:tHorz])

@variable(m, 0 <= vCapDac)

@variable(m, 0 <= eCo2Comp[0:tHorz])
@variable(m, 0 <= ePowUseComp[0:tHorz])
@variable(m, 0 <= vCapComp[0:tHorz])

@variable(m, 0 <= a0[0:tHorz])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1[0:tHorz])
@variable(m, 0 <= a2[0:tHorz])

@variable(m, 0 <= aR0[0:tHorz])
@variable(m, 0 <= aR1[0:tHorz])

@variable(m, 0 <= sF[0:tHorz])
@variable(m, 0 <= sS[0:tHorz])

@variable(m, 0 <= vAbs[0:tHorz])
@variable(m, 0 <= vReg[0:tHorz])


# Parameters
pHeatRateCombTur = 1.
pSteamRate = 1.
pEmissFactor = 1.

pCo2CapRatePcc = 1.

pSteamUseRatePcc = 1.
pPowUserRatePcc = 1.

pSteamUseRateDacAir = 1.
pSteamUseRateDacFlue = 1.

pPowUseRateDacAir = 1.
pPowUseRateDacFlue = 1.

pHeatRateSteamTur = 1.

pHeatRateHp = 1.
pHeatRateIp = 1.
pHeatRateLp = 1.

pCo2PccCapRate = 1.
pSorbCo2Cap = 1.
pPowUsePcc = 1.

# Constraints

#@constraint(m, capCombTur[i = 0:tHorz], vPowCombTurb[i] <= vCapCombTurb[i])
#@constraint(m, capSteamTurb[i = 0:tHorz], ePowSteamTurb[i] <= vCapSteamTurb[i])
#@constraint(m, capTransmInterc[i = 0:tHorz], ePowSteamTurb[i] <= vCapSteamTurb[i])

@constraint(m, capCombTur[i = 0:tHorz], vPowCombTurb[i] <= vCapCombTurb)
@constraint(m, capSteamTurb[i = 0:tHorz], ePowSteamTurb[i] <= vCapSteamTurb)
@constraint(m, capTransmInterc[i = 0:tHorz], ePowOut[i] <= vCapTransInter)

@constraint(m, fuel[i = 0:tHorz], eFuel[i] == pHeatRateCombTur * vPowCombTurb[i])
@constraint(m, steam[i = 0:tHorz], eSteam[i] == pSteamRate * eFuel[i])
@constraint(m, co2emission[i = 0:tHorz], eCo2Fuel[i] == pEmissFactor * vPowCombTurb[i])

@constraint(m, powerSteam[i = 0:tHorz], ePowSteamTurb[i] == ePowHp[i] + ePowIp[i] + ePowLp[i])

@constraint(m, esteamhp[i = 0:tHorz], eSteamHp[i] == eSteam[i])
# Ip steam?
@constraint(m, esteamlp[i = 0:tHorz], eSteamLp[i] == eSteamIp[i] - eSteamUsePcc[i] - eSteamUseDac[i])

@constraint(m, PowHpEq[i = 0:tHorz], ePowHp[i] == eSteamHp[i] / pHeatRateHp)
@constraint(m, PowIpEq[i = 0:tHorz], ePowIp[i] == eSteamIp[i] / pHeatRateIp)
@constraint(m, PowLpEq[i = 0:tHorz], ePowLp[i] == eSteamLp[i] / pHeatRateLp)

# PCC
@constraint(m, co2CapPccEq[i = 0:tHorz], eCo2CapPcc[i] == pCo2PccCapRate * eCo2Fuel[i])
@constraint(m, co2PccOutEq[i = 0:tHorz], eCo2PccOut[i] == eCo2Fuel[i] - eCo2CapPcc[i])
@constraint(m, co2DacFlueInEq[i = 0:tHorz], eCo2DacFlueIn[i] == eCo2PccOut[i] - vCo2PccVent[i])

@constraint(m, co2CapPccIn[i = 0:tHorz], eCo2CapPcc[i] <= vCapPcc)
@constraint(m, steamUsePccEq[i = 0:tHorz], eSteamUsePcc[i] == pSteamUseRatePcc * eCo2CapPcc[i])
@constraint(m, powerUsePccEq[i = 0:tHorz], ePowUsePcc[i] == pPowUsePcc * eCo2CapPcc[i])

# DAC
# v1 of the model.
@constraint(m, a0Eq[i = 0:tHorz], a0[i] == vAbs[i])
@constraint(m, aR0Eq[i = 0:tHorz], aR0[i] == vReg[i])
@constraint(m, a1dEq[i = 0:tHorz - 1], a1[i + 1] == a0[i])
@constraint(m, a2dEq[i = 0:tHorz - 1], a2[i + 1] == a1[i])
@constraint(m, aR1Eq[i = 0:tHorz - 1], aR1[i + 1] == aR0[i])
@constraint(m, storeFeq[i = 0:tHorz - 1], sF[i + 1] == sF[i] - vAbs[i] + aR1[i])
@constraint(m, storeSeq[i = 0:tHorz - 1], sS[i + 1] == sS[i] - vReg[i] + a2[i])

@constraint(m, capDacEq, sF[0] + sS[0] == vCapDac / pSorbCo2Cap)
