-- Adding NSL skill tier icons.
local kGoldTexture   = PrecacheAsset("ui/badges/nsl_open_tournament_2019_gold.dds")
local kSilverTexture = PrecacheAsset("ui/badges/nsl_open_tournament_2019_silver.dds")
local kBronzeTexture = PrecacheAsset("ui/badges/nsl_open_tournament_2019_bronze.dds")

local kAnimatedShader = PrecacheAsset("ui/badges/nsl_open_tournament_2019_animated.surface_shader")

local kGoldFrameCount = 29
local kSilverFrameCount = 30
local kBronzeFrameCount = 28

local kTourneyName = "NSL Season 18"

local kGoldTooltip   = "%s First Place Winner (Team '%s')"
local kSilverTooltip = "%s Second Place Winner (Team '%s')"
local kBronzeTooltip = "%s Third Place Winner (Team '%s')"

-- Hardcode the NS2 steam IDs of players awarded these badges.  Value is team name.
local goldTeamName = "Alski Syndrome"
local kNSLGoldIDs = {}

local silverTeamName = "Snoofed"
local kNSLSilverIDs = {}


local bronzeTeamName = "ELOgain"
local kNSLBronzeIDs = {}

-- Returns either nil (no special recipient), or a table:
--  name        Name to use for "skillTierName" field... not sure where this is actually used, just
--                  dotting my i's and crossing my t's here...
--  shader      Shader to use for this icon.
--  tex         Texture file to use.
--  frameCount (optional) Number of frames in the animation.  Sets a float parameter in the shader named "frameCount".
--  tooltip     Tooltip of the icon for the player found (includes their team name).
--  texCoords (optional)    Normalized texture coordinates to use.
--  texPixCoords (optional) Texture coordinates (in pixels) to use.
function CheckForSpecialBadgeRecipient(steamId)

    if steamId == nil then
        return nil
    end

    local result
    if kNSLGoldIDs[steamId] then
        result =
        {
            name = string.format("%s Gold", kTourneyName),
            shader = kAnimatedShader,
            tex = kGoldTexture,
            frameCount = kGoldFrameCount,
            tooltip = string.format(kGoldTooltip, kTourneyName, kNSLGoldIDs[steamId]),
            texCoords = {0, 0, 1, 1},
        }
    elseif kNSLSilverIDs[steamId] then
        result =
        {
            name = string.format("%s Silver", kTourneyName),
            shader = kAnimatedShader,
            tex = kSilverTexture,
            frameCount = kSilverFrameCount,
            tooltip = string.format(kSilverTooltip, kTourneyName, kNSLSilverIDs[steamId]),
            texCoords = {0, 0, 1, 1},
        }
    elseif kNSLBronzeIDs[steamId] then
        result =
        {
            name = string.format("%s Bronze", kTourneyName),
            shader = kAnimatedShader,
            tex = kBronzeTexture,
            frameCount = kBronzeFrameCount,
            tooltip = string.format(kBronzeTooltip, kTourneyName, kNSLBronzeIDs[steamId]),
            texCoords = {0, 0, 1, 1},
        }
    end

    return result

end
