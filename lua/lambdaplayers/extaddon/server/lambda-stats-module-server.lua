if !file.Exists( "lambdaplayers/stats.json", "DATA" ) then
    LAMBDAFS:WriteFile( "lambdaplayers/stats.json", {individual={}}, "json" )
end


local function GetStatDatabase()
    if _LambdaPlayersStatsDB then return _LambdaPlayersStatsDB end
    local data = LAMBDAFS:ReadFile( "lambdaplayers/stats.json", "json" )
    return data
end

local function SaveDatabase()
    LAMBDAFS:WriteFile( "lambdaplayers/stats.json", _LambdaPlayersStatsDB, "json" )
end

_LambdaPlayersStatsDB = _LambdaPlayersStatsDB or GetStatDatabase()


hook.Add( "ShutDown", "lambdastats_save", function()
    SaveDatabase()
end )

timer.Create("lambdastats_save", 300, 0, function()
    SaveDatabase()
    print( "Lambda Stats Module: Saving database.. A lag spike may occur" )
end )


-- Adds time to a Lambda's playtime
local function AddPlayTime( lambda, time )
    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    stats[ "playtime" ] = stats[ "playtime" ] and stats[ "playtime" ] + time or time
    stats[ "lastseen" ] = os.time()

    data["individual"][ lambda:Name() ] = stats
    
end

-- Log Local and Global deaths
hook.Add( "LambdaOnKilled", "lambdastats_onkilled", function( lambda )
    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    stats[ "deaths" ] = stats[ "deaths" ] and stats[ "deaths" ] + 1 or 1
    data[ "glb_deaths" ] = data[ "glb_deaths" ] and data[ "glb_deaths" ] + 1 or 1

    data["individual"][ lambda:Name() ] = stats
    
end )

-- Log Lambda play time individually
hook.Add( "LambdaOnThink", "lambdastats_onthink", function( lambda )
    if CurTime() > lambda.l_stats_nexttimeupdate then
        AddPlayTime( lambda, ( CurTime() - lambda.l_stats_reftime ) )
        
        lambda.l_stats_reftime = CurTime()
        lambda.l_stats_nexttimeupdate = CurTime() + 15
    end
end )

-- Logs individual play time on remove and logs last seen time
hook.Add( "LambdaOnRemove", "lambdastats_onremove", function( lambda )
    AddPlayTime( lambda, ( CurTime() - lambda.l_stats_reftime ) )

    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    stats[ "lastseen" ] = os.time()

    data["individual"][ lambda:Name() ] = stats
    
end )

-- Logs every byte of text sent in chat
hook.Add( "LambdaPlayerSay", "lambdastats_playersay", function( lambda, text )
    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    stats[ "textsize" ] = stats[ "textsize" ] and stats[ "textsize" ] + #text or #text
    data[ "glb_textsize" ] = data[ "glb_textsize" ] and data[ "glb_textsize" ] + #text or #text

    data["individual"][ lambda:Name() ] = stats
    
end )

-- Log Local and Global kills
hook.Add( "LambdaOnOtherKilled", "lambdastats_onotherkilled", function( lambda, victim, info )
    if info:GetAttacker() != lambda or !info:GetAttacker().IsLambdaPlayer then return end
    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    local wepdata = _LAMBDAPLAYERSWEAPONS[ lambda:GetWeaponName() ]
    local weaponstats = stats[ "weaponstats" ] or {}
    local glb_weaponstats = data[ "glb_weaponstats" ] or {}

    local weapondata = weaponstats[ wepdata.prettyname ] or {}
    local glb_weapondata = glb_weaponstats[ wepdata.prettyname ] or {}

    weapondata.kills = weapondata.kills and weapondata.kills + 1 or 1
    glb_weapondata.kills = glb_weapondata.kills and glb_weapondata.kills + 1 or 1

    weaponstats[ wepdata.prettyname ] = weapondata
    glb_weaponstats[ wepdata.prettyname ] = glb_weapondata

    stats[ "kills" ] = stats[ "kills" ] and stats[ "kills" ] + 1 or 1
    data[ "glb_kills" ] = data[ "glb_kills" ] and data[ "glb_kills" ] + 1 or 1

    stats[ "weaponstats" ] = weaponstats
    data[ "glb_weaponstats" ] = glb_weaponstats
    data["individual"][ lambda:Name() ] = stats
    
end )

-- Log Local and Global initial spawns
hook.Add( "LambdaOnInitialize", "lambdastats_oninitialize", function( lambda )
    lambda.l_stats_nexttimeupdate = CurTime() + 15
    lambda.l_stats_reftime = CurTime()

    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}

    data[ "glb_initialspawns" ] = data[ "glb_initialspawns" ] and data[ "glb_initialspawns" ] + 1 or 1
    stats[ "initialspawns" ] = stats[ "initialspawns" ] and stats[ "initialspawns" ] + 1 or 1

    data["individual"][ lambda:Name() ] = stats
    
end )

-- Log Local and Global weapons uses
hook.Add( "LambdaOnSwitchWeapon", "lambdastats_onswitchweapon", function( lambda, wepent, wepdata )
    local data = GetStatDatabase()
    local stats = data["individual"][ lambda:Name() ] or {}
    local weaponstats = stats[ "weaponstats" ] or {}
    local glb_weaponstats = data[ "glb_weaponstats" ] or {}

    local weapondata = weaponstats[ wepdata.prettyname ] or {}
    weapondata.uses = weapondata.uses and weapondata.uses + 1 or 1

    local glb_weapondata = glb_weaponstats[ wepdata.prettyname ] or {}
    glb_weapondata.uses = glb_weapondata.uses and glb_weapondata.uses + 1 or 1

    weaponstats[ wepdata.prettyname ] = weapondata
    glb_weaponstats[ wepdata.prettyname ] = glb_weapondata

    stats[ "weaponstats" ] = weaponstats
    data["individual"][ lambda:Name() ] = stats
    data[ "glb_weaponstats" ] = glb_weaponstats
    
end )

