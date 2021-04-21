#: by David T
using JuMP

t_h = 25
m = Model()

#@variable(m, 0 <= vCapCombTurb[0:t_h])
@variable(m, 0 <= vCapCombTurb)
@variable(m, 0 <= vPowCombTurb[0:t_h])

@variable(m, 0 <= ePowSteamTurb[0:t_h])
#@variable(m, 0 <= vCapSteamTurb[0:t_h])
@variable(m, 0 <= vCapSteamTurb)

@variable(m, 0 <= ePowOut[0:t_h])
#@variable(m, 0 <= vCapTransInter[0:t_h])
@variable(m, 0 <= vCapTransInter)

@variable(m, 0 <= eFuel[0:t_h])
@variable(m, 0 <= eSteam[0:t_h])

@variable(m, 0 <= eCo2Fuel[0:t_h])

# Pcc
@variable(m, 0 <= eCo2CapPcc[0:t_h])
# @variable(m, 0 <= eCo2Vent[0:t_h])

@variable(m, 0 <= eSteamUsePcc[0:t_h])
@variable(m, 0 <= ePowUsePcc[0:t_h])

@variable(m, 0 <= vCo2Vent[0:t_h])

@variable(m, 0 <= eCo2DacFlueIn[0:t_h])

@variable(m, 0 <= eSteamUseDac[0:t_h])
@variable(m, 0 <= ePowUseDac[0:t_h])

@variable(m, 0 <= vCaptureDac[0:t_h])
@variable(m, 0 <= eCo2CaptureDac[0:t_h])

@variable(m, 0 <= vCapDac[0:t_h])

@variable(m, 0 <= eCo2Comp[0:t_h])
@variable(m, 0 <= ePowUseComp[0:t_h])
@variable(m, 0 <= vCapComp[0:t_h])

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

# Constraints

#@constraint(m, capCombTur[i = 0:t_h], vPowCombTurb[i] <= vCapCombTurb[i])
#@constraint(m, capSteamTurb[i = 0:t_h], ePowSteamTurb[i] <= vCapSteamTurb[i])
#@constraint(m, capTransmInterc[i = 0:t_h], ePowSteamTurb[i] <= vCapSteamTurb[i])

@constraint(m, capCombTur[i = 0:t_h], vPowCombTurb[i] <= vCapCombTurb)
@constraint(m, capSteamTurb[i = 0:t_h], ePowSteamTurb[i] <= vCapSteamTurb)
@constraint(m, capTransmInterc[i = 0:t_h], ePowOut[i] <= vCapTransInter)

@constraint(m, fuel[i = 0:t_h], eFuel[i] == pHeatRateCombTur * vPowCombTurb[i])
@constraint(m, steam[i = 0:t_h], eSteam[i] == pSteamRate * eFuel[i])
@constraint(m, co2emission[i = 0:t_h], eCo2Fuel[i] == pEmissFactor * vPowCombTurb[i])
