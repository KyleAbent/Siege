
local function FindNearestPhaseGate(marine, favoredGateId, fromPos)
    
    local gates = GetEntitiesForTeam( "PhaseGate", marine:GetTeamNumber() )

    return GetMinTableEntry( gates,
            function(gate)

                assert( gate ~= nil )

                if gate:GetIsBuilt() and gate:GetIsPowered() and gate:GetIsLinked() then

                    local dist = GetBotWalkDistance(gate, fromPos or marine)
                    if gate:GetId() == favoredGateId then
                        return dist * 0.9
                    else
                        return dist
                    end

                else
                    return nil
                end

            end)

end

function GetPhaseDistanceForMarine(marine, to, lastNearestGateId )
    PROFILE("MarineBrain - GetPhaseDistanceForMarine")

    local marinePos = marine:GetOrigin()
    local p0Dist, p0 = FindNearestPhaseGate(marine, lastNearestGateId)
    local p1Dist, p1 = FindNearestPhaseGate(marine, nil, to)
    local walkDistance = GetBotWalkDistance(marine, to)

    -- Favor the euclid dist just a bit..to prevent thrashing  ....McG: eh, not convinced this comment is correct
    local hasTwoPhasegates = (p0 and p1) and (p0:GetId() ~= p1:GetId())
    if hasTwoPhasegates and (p0Dist + p1Dist) < walkDistance then
        return (p0Dist + p1Dist), p0
    else
        return walkDistance, nil
    end

end

local inf = tonumber("inf")

--Return the closest entity in the given set which is all of:
-- + built
-- + powered
-- + in a 'nearby' room (directly connected to the current)
function FilterNearbyMarineEntity(marine, ents, favoredId, lastGateId)
	local bestDist = inf
	local bestEnt = nil

	local locName = marine:GetLocationName()

	-- BOT-TODO: include per-team transient links into the graph (e.g. tunnels, phase gates)
	local nearby = GetLocationGraph():GetDirectPathsForLocationName(locName)
	if not nearby then
		return bestDist, bestEnt
	end

	for i = 1, #ents do
		local ent = Shared.GetEntity(ents[i])

		local entLoc = ent:GetLocationName()
		if (locName == entLoc or nearby:Contains(entLoc)) and ent:GetIsBuilt() and ent:GetIsPowered() then
			local dist, _ = GetPhaseDistanceForMarine( marine, ent, lastGateId )

			if ents[i] == favoredId then
				dist = dist * 0.9
			end

			if dist < bestDist then
				bestDist = dist
				bestEnt = ent
			end
		end
	end

	return bestDist, bestEnt
end

--Return the closest entity (potentially across the map) in the given set which is all of:
-- + built
-- + powered
function FilterNearestMarineEntity(marine, ents, favoredId, lastGateId)
	local bestDist = inf
	local bestEnt = nil

	for i = 1, #ents do
		local ent = Shared.GetEntity(ents[i])

		if ent:GetIsBuilt() and ent:GetIsPowered() then
			local dist, _ = GetPhaseDistanceForMarine( marine, ent, lastGateId )

			if ents[i] == favoredId then
				dist = dist * 0.9
			end

			if dist < bestDist then
				bestDist = dist
				bestEnt = ent
			end
		end
	end

	return bestDist, bestEnt
end
