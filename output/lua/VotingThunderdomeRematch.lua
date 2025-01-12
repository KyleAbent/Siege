-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua\VotingThunderdomeRematch.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/ThunderdomeRules.lua")


local kExecuteVoteDelay = 2

RegisterVoteType("VoteThunderdomeRematch", { })

if Client then

    local function SetupThunderdomeRematchVote(voteMenu)
    
        --[[
        local function StartThunderdomeRematchVote(data)
            AttemptToStartVote("VoteThunderdomeRematch", { })
        end
        
        voteMenu:AddMainMenuOption(Locale.ResolveString("VOTE_TD_REMATCH"), nil, StartThunderdomeRematchVote)
        --]]
        
        -- This function translates the networked data into a question to display to the player for voting.
        local function GetVoteRematchQuery(data)
            return Locale.ResolveString("VOTE_TD_REMATCH_QUERY")
        end
        AddVoteStartListener("VoteThunderdomeRematch", GetVoteRematchQuery)
        
    end
    AddVoteSetupCallback(SetupThunderdomeRematchVote)
    
end

if Server then

    local function ExtraCheck(_, numYesVotes, _)
        return numYesVotes == Server.GetThunderdomeExpectedPlayerCount()    --McG-Note: may need to change to % of, in case of a few leavers
    end

    local function OnThunderdomeRematchVoteSuccessful(data)
        GetThunderdomeRules():OnVotedRematchSuccess(data)
    end
    SetVoteSuccessfulCallback("VoteThunderdomeRematch", kExecuteVoteDelay, OnThunderdomeRematchVoteSuccessful, ExtraCheck, Server.GetThunderdomeExpectedPlayerCount())
    
end