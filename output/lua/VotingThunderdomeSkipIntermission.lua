-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua/VotingThunderdomeSkipIntermission.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/ThunderdomeRules.lua")

local kExecuteVoteDelay = 2

RegisterVoteType("VoteThunderdomeSkipIntermission", { })

if Client then

    local function SetupThunderdomeSkipIntermissionVote(voteMenu)

        -- This function translates the networked data into a question to display to the player for voting.
        local function GetVoteSkipIntermissionQuery(data)
            return Locale.ResolveString("VOTE_TD_SKIP_INTERMISSION_QUERY")
        end
        AddVoteStartListener("VoteThunderdomeSkipIntermission", GetVoteSkipIntermissionQuery)

    end
    AddVoteSetupCallback(SetupThunderdomeSkipIntermissionVote)

end

if Server then

    local function ExtraCheck(_, numYesVotes, _)
        return numYesVotes == Server.GetThunderdomeExpectedPlayerCount()
    end

    local function OnThunderdomeSkipIntermissionVoteSuccessful(data)
        GetThunderdomeRules():OnVotedSkipIntermissionSuccess(data)
    end

    -- Update number of required votes to the number of players currently on the server
    function SetupThunderdomeIntermissionVote()
        SetVoteSuccessfulCallback("VoteThunderdomeSkipIntermission", kExecuteVoteDelay, OnThunderdomeSkipIntermissionVoteSuccessful, nil, Server.GetNumPlayers() - #gServerBots)
    end

end
