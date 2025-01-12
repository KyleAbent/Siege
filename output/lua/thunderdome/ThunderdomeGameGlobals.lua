-- ======= Copyright (c) 2021, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\thunderdome\ThunderdomeGameGlobals.lua
--
--    Created by:   Brock Gillespie (brock@naturalselection2.com)
--
-- This file is only included when Thunderdome-Mode is enabled. It's used to override default
-- game global variables. This file should only ever override variables declared in global-scope.
-- When adding new overrides here, be sure to include (via comment) what the default value was.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================


kMaxTimeBeforeReset = 3 * 60            --default:  3 * 60  (Unused in TD)
kMinTimeBeforeConcede = 1.5 * 60          --default:  7 * 60
kPercentNeededForVoteConcede = (4/6) - 0.01     --default:  0.75  65% is 4/6 votes, was 5/6



