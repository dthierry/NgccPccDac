# vim: set wrap
#: by David Thierry 2021
using JuMP
using Clp
using DataFrames
using StatsPlots
using CSV

tHorz = 24
m = Model()

## Parameters
#: Gas Turbine
aPowGasTeLoad = 0.005
aFuelEload = 0.0001
aEmissFactEload = 0.002
aAuxRateGas = 1e-03
#: Steam Turbine Parameters
aPowHpEload = 1e-01
aPowIpEload = 1e-02
aPowLpEload = 1e-03

aDacSteaEload = 1.
aAuxRateStea = 1e-08
aCcRebDutyEload = 1e-04

#
#
aSteaUseRatePcc = 0.001
aPowUseRatePcc = 0.022

aSteaUseRateDacAir = 1e-03
aSteaUseRateDacFlue = 1e-03

aPowUseRateDacAir = 5e-03
aPowUseRateDacFlue = 2e-03


aCo2PccCapRate = .1
aSorbCo2CapFlue = 0.1
pSorbCo2CapAir = 1e-06
aPowUseRateDac = 0.0001

aPowUseRateComp = 0.001
#
cCostInvCombTurb = 1e+02
cCostInvSteaTurb = 1e+02
cCostInvTransInter = 1e+02
cCostInvPcc = 1e+02
cCostInvDac = 1e+03
cCostInvComp = 1e+01

# Cost parameters.
cCostFuel = 1e+02
pEmissionPrice = 1e+04
pCo2TranspPrice = 1e+01
pPowBasePrice = 1e+01
pCo2Credit = 1e+00


#vCapCombTurb = 3.
vCapSteaTurb = 2.
vCapTransInter = 5.
vCapPcc = 20.
vCapComp = 1000.

rnum = rand(Float64, tHorz)
@variable(m, 60 <= yGasTelecLoad[0:tHorz - 1] <= 100)
#@variable(m, 0 <= vCapCombTurb)
#@variable(m, 0 <= xPowGasTur[0:tHorz - 1] <= vCapCombTurb)
@variable(m, 0 <= xPowGasTur[0:tHorz - 1])

#@variable(m, 0 <= xPowSteaTur[0:tHorz - 1] <= vCapSteaTurb)
#@variable(m, 0 <= vCapSteaTurb)

#@variable(m, rnum[i+1] <= xPowOut[i = 0:tHorz - 1] <= vCapTransInter)
#@variable(m, xPowOut[i = 0:tHorz - 1] >= rnum[i + 1])
@variable(m, 0 <= xPowGross[0:tHorz - 1])
@variable(m, 0 <= xPowOut[ 0:tHorz - 1])

@variable(m, xAuxPowGasT[0:tHorz - 1] >= 0)

# Steam Turbine
@variable(m, 0 <= xPowHp[0:tHorz - 1])
@variable(m, 0 <= xPowIp[0:tHorz - 1])
@variable(m, 0 <= xPowLp[0:tHorz - 1])
#@variable(m, 0 <= vCapTransInter)

@variable(m, 0 <= xFuel[0:tHorz - 1])
@variable(m, 0 <= xCo2Fuel[0:tHorz - 1])

@variable(m, 0 <= xCcRebDuty[0:tHorz - 1])
@variable(m, 0 <= xDacSteaDuty[0:tHorz - 1])

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
@variable(m, 0 <= a0Flue[0:tHorz - 1])  # We could generalize this for any number of hours.
@variable(m, 0 <= a1Flue[0:tHorz]) # State
@variable(m, 0 <= a2Flue[0:tHorz]) # State

@variable(m, 0 <= aR0Flue[0:tHorz - 1])  # Not-a-State
@variable(m, 0 <= aR1Flue[0:tHorz])  # State
@variable(m, 0 <= sFflue[0:tHorz])  # State
@variable(m, 0 <= sSflue[0:tHorz])  # State

@variable(m, 0 <= vAbsFlue[0:tHorz - 1])  # Input
@variable(m, 0 <= vRegFlue[0:tHorz - 1])  # Input

@variable(m, 0 <= xCo2StorDacFlue[0:tHorz - 1])
@variable(m, 0 <= xCo2CapDacFlue[0:tHorz - 1])
@variable(m, 0 <= xSteaUseDacFlue[0:tHorz - 1])
@variable(m, 0 <= xPowUseDacFlue[0:tHorz - 1])
@variable(m, 0 <= xCo2DacVentFlue[0:tHorz - 1])

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
            xPowGasTur[i] == aPowGasTeLoad * yGasTelecLoad[i]
           )
# 4
@constraint(m, fuelEq[i = 0:tHorz - 1], 
            xFuel[i] == aFuelEload * yGasTelecLoad[i]
           )
# 5
@constraint(m, co2FuelEq[i = 0:tHorz - 1], 
            xCo2Fuel[i] == aEmissFactEload * yGasTelecLoad[i]
           )

@constraint(m, auxPowGasT[i = 0:tHorz - 1],
            xAuxPowGasT[i] == aAuxRateGas * yGasTelecLoad[i])
# 6
# Steam
# 7a
@constraint(m, powHpEq[i = 0:tHorz - 1], 
            xPowHp[i] == aPowHpEload * yGasTelecLoad[i])
# 7b
@constraint(m, powIpEq[i = 0:tHorz - 1], 
            xPowIp[i] == aPowIpEload * yGasTelecLoad[i])

# 11
@constraint(m, powLpEq[i = 0:tHorz - 1], 
            xPowLp[i] == aPowLpEload * yGasTelecLoad[i])
# 12
@constraint(m, powerSteaEq[i = 0:tHorz - 1], 
            xPowSteaTur[i] == xPowHp[i] + xPowIp[i] + xPowLp[i])

@constraint(m, ccRebDutyEq[i = 0:tHorz - 1],
            xCcRebDuty[i] == aCcRebDutyEload * yGasTelecLoad[i])

@constraint(m, dacSteaDutyEq[i = 0:tHorz - 1],
            xDacSteaDuty[i] == aDacSteaEload * yGasTelecLoad[i])

@constraint(m, auxPowSteaTEq[i = 0:tHorz - 1],
            xAuxPowSteaT[i] == aAuxRateStea * yGasTelecLoad[i])



# PCC
# 13
#@constraint(m, co2CapPccEq[i = 0:tHorz - 1], xCo2CapPcc[i] == aCo2PccCapRate * xCo2Fuel[i])
@constraint(m, co2CapPccEq[i = 0:tHorz - 1], 
            xCo2CapPcc[i] == 0.5 * xCo2Fuel[i])
# 14
@constraint(m, co2PccOutEq[i = 0:tHorz - 1], 
            xCo2PccOut[i] == xCo2Fuel[i] - xCo2CapPcc[i])
# 15
@constraint(m, co2DacFlueInEq[i = 0:tHorz - 1], 
            xCo2DacFlueIn[i] == xCo2PccOut[i] - vCo2PccVent[i])
# 16
# @constraint(m, co2CapPccIn[i = 0:tHorz - 1], xCo2CapPcc[i] <= vCapPcc)
# 17
@constraint(m, steamUsePccEq[i = 0:tHorz - 1], 
            xSteaUsePcc[i] == aSteaUseRatePcc * xCo2CapPcc[i])
# 18
@constraint(m, powerUsePccEq[i = 0:tHorz - 1], 
            xPowUsePcc[i] == aPowUseRatePcc * xCo2CapPcc[i])

@constraint(m, pccSteaSlack[i = 0:tHorz - 1], 
            xPccSteaSlack[i] == xCcRebDuty[i] - xSteaUsePcc[i])

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
@constraint(m, co2StorDacFlueEq[i = 0:tHorz - 1], xCo2StorDacFlue[i] == aSorbCo2CapFlue * sSflue[i])
# 24
@constraint(m, co2CapDacFlueEq[i = 0:tHorz - 1], xCo2CapDacFlue[i] == aSorbCo2CapFlue * aR1Flue[i])
# 25
@constraint(m, steamUseDacFlueEq[i = 0:tHorz - 1], xSteaUseDacFlue[i] == aSteaUseRateDacFlue * xCo2CapDacFlue[i])
# 26
@constraint(m, powUseDacFlueEq[i = 0:tHorz - 1], xPowUseDacFlue[i] == aPowUseRateDacFlue * xCo2CapDacFlue[i])
# Equal to the amount vented, at least in flue mode.
@constraint(m, co2DacFlueVentEq[i = 0:tHorz - 1], xCo2DacVentFlue[i] == xCo2DacFlueIn[i] - xCo2CapDacFlue[i])

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
@constraint(m, co2StorDacAirEq[i = 0:tHorz - 1], xCo2StorDacAir[i] == pSorbCo2CapAir * sSair[i])
# Money, baby.
@constraint(m, co2CapDacAirEq[i = 0:tHorz - 1], xCo2CapDacAir[i] == pSorbCo2CapAir * aR1Air[i])
# 
@constraint(m, steamUseDacAirEq[i = 0:tHorz - 1], xSteaUseDacAir[i] == aSteaUseRateDacAir * xCo2CapDacAir[i])
# 
@constraint(m, powUseDacAirEq[i = 0:tHorz - 1], xPowUseDacAir[i] == aPowUseRateDacAir * xCo2CapDacAir[i])


@constraint(m, dacSteaSlackEq[i = 0:tHorz - 1], 
            xDacSteaSlack[i] == xDacSteaDuty[i] - xSteaUseDacFlue[i] - xSteaUseDacAir[i])


# Co2 Compression
# 27
@constraint(m, co2CompEq[i = 0:tHorz - 1], xCo2Comp[i] == xCo2CapPcc[i])
# 28
@constraint(m, powUseCompEq[i = 0:tHorz - 1], xPowUseComp[i] == aPowUseRateComp * xCo2Comp[i])
# 29
# @constraint(m, powUseCompIn[i = 0:tHorz - 1], xPowUseComp[i] <= vCapComp)

# @constraint(m, co2VentEq[i = 0:tHorz - 1], xCo2Vent[i] == vCo2PccVent[i] + xCo2DacVentFlue[i])
@constraint(m, co2VentEq[i = 0:tHorz - 1], xCo2Vent[i] == vCo2PccVent[i] + xCo2DacVentFlue[i] - xCo2CapDacAir[i])


## Overall
#
#
@constraint(m, powGrossEq[i = 0:tHorz - 1], 
            xPowGross[i] == xPowGasTur[i] + xPowSteaTur[i]
           )
@constraint(m, auxPowEq[i = 0:tHorz - 1],
            xAuxPow[i] == xAuxPowGasT[i] + xAuxPowSteaT[i])
@constraint(m, powOutEq[i = 0:tHorz - 1], 
            xPowOut[i] == xPowGross[i] - xPowUsePcc[i] - xPowUseDacFlue[i] - xPowUseDacAir[i] - xPowUseComp[i] - xAuxPow[i]
           )



@expression(m, eObjfExpr, sum(cCostFuel * xFuel[i] + 
                              pEmissionPrice * xCo2Vent[i] + 
                              pCo2TranspPrice * xCo2Comp[i] - 
                              pPowBasePrice * xPowOut[i] for i in 0:tHorz - 1))
#@expression(m, eObjfExpr, sum(-xPowOut[i] for i in 0:tHorz - 1))

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
df_pow = DataFrame(Symbol("PowGasTur") => Float64[], # Pairs.
                  Symbol("PowSteaTurb") => Float64[],
                  Symbol("PowHp") => Float64[],
                  Symbol("PowIp") => Float64[],
                  Symbol("PowLp") => Float64[],
                  Symbol("PowUsePcc") => Float64[],
                  Symbol("PowUseDacFlue") => Float64[],
                  Symbol("PowUseDacAir") => Float64[],
                  Symbol("PowUseComp") => Float64[],
                  Symbol("xAuxPowGasT") => Float64[],
                  Symbol("xAuxPowSteaT") => Float64[],
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
                     Symbol("xCcRebDuty") => Float64[],
                     Symbol("xDacSteaDuty") => Float64[],
                     Symbol("SteaUsePccFlue") => Float64[],
                     Symbol("SteaUseDacFlue") => Float64[],
                     Symbol("SteaUseDacAir") => Float64[],
                     Symbol("Fuel") => Float64[]
                    )
for i in 0:tHorz-1
    push!(df_steam, (
                     value(xCcRebDuty[i]),
                     value(xDacSteaDuty[i]),
                     value(xSteaUsePcc[i]),
                     value(xSteaUseDacFlue[i]),
                     value(xSteaUseDacAir[i]),
                     value(xFuel[i])
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

