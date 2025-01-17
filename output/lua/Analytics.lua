Analytics = { data = {} }

local kAnalyticsUrl = "http://observatory.naturalselection2.com" --psql
local kFeedbackUrl = "http://observatory.naturalselection2.com/survey/"
local kOptionUrl = "http://observatory.naturalselection2.com/option/"

function Analytics.RecordLaunch( steamId, level, score, playTime )
    
    local launchId = 0

    if launchId == 0 or steamId == 0 then
        return
    end
    --[[
    if Client.GetStaticData() ~= 0 then        
        return
    end
    Client.SetStaticData( 1 )
    
    local doneTutorial = Client.GetAchievement("First_0_1")
       
    local data = {
        steamid = Client.GetSteamId(),
        launchid = launchId,
        level = level or -1,
        score = score or -1,
        playtime = playTime or -1,
        tutorial_complete = doneTutorial,
        build = Shared.GetBuildNumber(),
        locale = Client.GetOptionString( "locale", "enUS" ),
    }
    
    HPrint( "[Analytics] Recording launch event" )
    Shared.SendHTTPRequest( kAnalyticsUrl , "POST", { data = json.encode(data) }, function() end)
    --]]
end


function Analytics.RecordEvent( event, params )

    local launchId = 0

    if launchId == 0 then
        return
    end
    --[[
    if Client.GetStaticData() ~= 1 then
        return -- never sent launch event
    end
    
    local data = 
    {
        launchid = launchId,
        event = event,
    }
    if params then
        for k,v in pairs( params ) do
           data[k] = v
        end
    end
    
    Shared.SendHTTPRequest( kAnalyticsUrl , "POST", { data = json.encode(data) }, function() end)
    --]]
end

function Analytics.RecordFeedback( params )
    --local launchId = Client.GetClientSponitorLaunchId()
    return
    --[[
    local data = params
    data.launchid = launchId

    Shared.SendHTTPRequest( kFeedbackUrl , "POST", { data = json.encode(data) }, function() end)
    --]]
end

function Analytics.RecordOption( key, value )
    return 
    --[[
    if type(value) == "boolean" then
        value = value and 1 or 0 
    end
    
    local data = {
        steamid = Client.GetSteamId(),
        optionkey = key,
        optionvalue = value,
    }
    
    Shared.SendHTTPRequest( kOptionUrl , "POST", { data = json.encode(data) }, function() end)
    --]]
end
