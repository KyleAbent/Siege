-- ======= Copyright (c) 2022, Unknown Worlds Entertainment, Inc. All rights reserved. =====
--
-- lua/VotingThunderdomeDrawGame.lua
--
--    Created by:   Darrell Gentry (darrell@naturalselection2.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/thunderdome/ThunderdomeGlobals.lua")
Script.Load("lua/thunderdome/ThunderdomeRules.lua")

local kExecuteVoteDelay = 2

RegisterVoteType("VoteThunderdomeDrawGame", { })

if Client then

    local function SetupThunderdomeDrawGameVote(voteMenu)

        -- This function translates the networked data into a question to display to the player for voting.
        local function GetVoteDrawGameQuery(data)
            return "Draw Match due to Team Imbalance?" -- Locale.ResolveString("VOTE_TD_DRAW_GAME_QUERY")
        end
        AddVoteStartListener("VoteThunderdomeDrawGame", GetVoteDrawGameQuery)

    end
    AddVoteSetupCallback(SetupThunderdomeDrawGameVote)

end

if Server then

    local function OnThunderdomeDrawGameVoteSuccessful(data)
        GetThunderdomeRules():OnVotedDrawGameSuccess(data)
    end

	-- default to 50%+1 of server players to succeed on a draw-game vote
    SetVoteSuccessfulCallback("VoteThunderdomeDrawGame", kExecuteVoteDelay, OnThunderdomeDrawGameVoteSuccessful)

end
