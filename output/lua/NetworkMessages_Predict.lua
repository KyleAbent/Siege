-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\NetworkMessages_Predict.lua
--
--    Created by:   Mats Olsson (mats.olsson@matsotech.se)
--
-- See the Messages section of the Networking docs in Spark Engine scripting docs for details.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

function OnCommandClearTechTree()
    PROFILE("NetworkMessages_Predict:OnCommandClearTechTree")
    ClearTechTree()
end

function OnCommandTechNodeBase(techNodeBaseTable)
    PROFILE("NetworkMessages_Predict:OnCommandTechNodeBase")
    GetTechTree():CreateTechNodeFromNetwork(techNodeBaseTable)
end

function OnCommandTechNodeUpdate(techNodeUpdateTable)
    PROFILE("NetworkMessages_Predict:OnCommandTechNodeUpdate")
    GetTechTree():UpdateTechNodeFromNetwork(techNodeUpdateTable)
end

Predict.HookNetworkMessage("ClearTechTree", OnCommandClearTechTree)
Predict.HookNetworkMessage("TechNodeBase", OnCommandTechNodeBase)
Predict.HookNetworkMessage("TechNodeUpdate", OnCommandTechNodeUpdate)
