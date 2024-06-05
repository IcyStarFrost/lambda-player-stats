
-- Blacklist these weapons from the popularity top 3s
local weapon_blacklist = {
    [ "Holster" ] = true,
    [ "[Garry's Mod] Physics Gun" ] = true,
    [ "[Garry's Mod] Toolgun" ] = true,
    [ "[Garry's Mod] Medkit" ] = true,
}

local clrs = {
    Color( 0, 255, 0 ),
    Color( 0, 128, 160 ),
    Color( 97, 44, 0 ),
}

-- Allows the ability to play a "typewriter" animation on DLabels.
-- Prefix is static prefix text, while text is the string that will be animated in
local function HandleText( prefix, text, lbl, no_animate )
    local text_table = string.ToTable( text )
    local cursor = 0

    if no_animate then
        lbl:SetText( prefix .. text )
        return
    end

    LambdaCreateThread( function()
        while IsValid( lbl ) do
            local txt = ""

            if cursor > #text_table then
                break
            end

            LocalPlayer():EmitSound( "buttons/button16.wav", 0, 255, 0.1 )
            
            for k, char in ipairs( text_table ) do
                if char == " " then 
                    txt = txt .. char
                elseif k > cursor then
                    txt = txt .. string.char( LambdaRNG( 100 ) )
                else
                    txt = txt .. char
                end
                
            end

            cursor = cursor + 1
            
            lbl:SetText( prefix .. txt )

            coroutine.wait( 0.07 )
        end
    end )
end

-- Panel style hook 
local function black_paint( self, w, h )
    surface.SetDrawColor( 0, 0, 0, 150 )
    surface.DrawRect( 0, 0, w, h )
end

-- Returns a sorted table based on Lambda kills
local function CreateLambdaKillsTable( tbl )
    local seq = {}
    for name, data in pairs( tbl ) do
        if !data.kills then continue end
        seq[ #seq + 1 ] = { name, data.kills }
    end
    table.sort( seq, function( a, b ) return a[2] > b[2] end )
    return seq
end

-- Returns a sorted table based on Lambda Kill/Death ratio
local function CreateLambdaKDTable( tbl )
    local seq = {}
    for name, data in pairs( tbl ) do
        if !data.kills then continue end
        local deaths = data.deaths or 1
        seq[ #seq + 1 ] = { name, math.Round( data.kills / deaths, 1 ) }
    end
    table.sort( seq, function( a, b ) return a[2] > b[2] end )
    return seq
end

-- Returns a sorted table based on an individual weapon's kills or times used
local function CreateWeaponsTable( tbl, sortbykills )
    local sorted = {}
    for name, data in SortedPairsByMemberValue( tbl, sortbykills and "kills" or "uses", true ) do
        if weapon_blacklist[ name ] then continue end
        sorted[ #sorted + 1 ] = { name, data }
    end
    return sorted
end

-- Opens a panel to view a individual Lambda's stats
local individual_main 
local function OpenIndividualStats( name, data )
    if IsValid( individual_main ) then
        individual_main:Remove()
    end

    -- The main panel
    individual_main = LAMBDAPANELS:CreateFrame( name .. "'s stats", ScrW() * 0.5, ScrH() * 0.5 )
    local scroll = LAMBDAPANELS:CreateScrollPanel( individual_main, false, FILL )

    individual_main:SetSizable( false )

    local kd = math.Round( ( ( data.kills or 0 ) / ( data.deaths or 1 ) ), 1 )
    
    ---------- Stat labels ----------
    local header = LAMBDAPANELS:CreateLabel( name .. "'s Individual Statistics", individual_main, TOP )
    local total_kills = LAMBDAPANELS:CreateLabel( "Total Kills: " .. ( data.kills or 0 ), scroll, TOP )
    local total_deaths = LAMBDAPANELS:CreateLabel( "Total Deaths: " .. ( data.deaths or 0 ), scroll, TOP )
    local kd_ratio = LAMBDAPANELS:CreateLabel( "Kill/Death Ratio: " .. kd, scroll, TOP )
    local total_spawns = LAMBDAPANELS:CreateLabel( "Total First Spawns: " .. ( data.initialspawns or 1 ), scroll, TOP )
    local lastseen = LAMBDAPANELS:CreateLabel( "Last seen: " .. os.date( "%m/%d/%Y %I:%M %p", ( data.lastseen or os.time() ) ), scroll, TOP )
    local playtime = LAMBDAPANELS:CreateLabel( "Play Time: " .. string.NiceTime( data.playtime ), scroll, TOP )
    local textsize = LAMBDAPANELS:CreateLabel( "Total Text Sent: " .. ( string.NiceSize( data.textsize or 0 ) ), scroll, TOP )

    local usedweapons_1 = LAMBDAPANELS:CreateLabel( "Most Popular Weapon: N/A", scroll, TOP )
    local usedweapons_2 = LAMBDAPANELS:CreateLabel( "Second Most Popular Weapon: N/A", scroll, TOP )
    local usedweapons_3 = LAMBDAPANELS:CreateLabel( "Third Most Popular Weapon: N/A", scroll, TOP )

    local effectiveweapons_1 = LAMBDAPANELS:CreateLabel( "Most Effective Weapon: N/A", scroll, TOP )
    local effectiveweapons_2 = LAMBDAPANELS:CreateLabel( "Second Most Effective Weapon: N/A", scroll, TOP )
    local effectiveweapons_3 = LAMBDAPANELS:CreateLabel( "Third Most Effective Weapon: N/A", scroll, TOP )
    ------------------------------

    -- Fallback parameters
    for name, wepdata in pairs( data.weaponstats ) do
        data.weaponstats[ name ].kills = data.weaponstats[ name ].kills or 0
        data.weaponstats[ name ].uses = data.weaponstats[ name ].uses or 1
    end

    ---------- Individual Weapon Stats ----------
    local individual_weaponpnl = LAMBDAPANELS:CreateBasicPanel( scroll, TOP )
    individual_weaponpnl:SetSize( scroll:GetWide(), 500 )

    local left = LAMBDAPANELS:CreateBasicPanel( individual_weaponpnl, LEFT )
    left:SetSize( individual_main:GetWide() / 2, 1 )
    left.Paint = black_paint

    local weaponuses = LAMBDAPANELS:CreateLabel( "--- Weapon Uses ---", left, TOP )
    weaponuses:SetFont("Trebuchet24")
    weaponuses:DockMargin( 0, 70, 0, 30 )

    local uses_scroll = LAMBDAPANELS:CreateScrollPanel( left, false, FILL )

    local right = LAMBDAPANELS:CreateBasicPanel( individual_weaponpnl, LEFT )
    right:SetSize( individual_main:GetWide() / 2, 1 )
    right.Paint = black_paint

    local weaponkills = LAMBDAPANELS:CreateLabel( "--- Weapon Kills ---", right, TOP )
    weaponkills:SetFont("Trebuchet24")
    weaponkills:DockMargin( 0, 70, 0, 30 )

    local kills_scroll = LAMBDAPANELS:CreateScrollPanel( right, false, FILL )

    -- Display individual weapon uses
    local weps = CreateWeaponsTable( data.weaponstats )
    local effectiveweps = CreateWeaponsTable( data.weaponstats, true )
    for k, tbl in pairs( weps ) do
        local lbl = LAMBDAPANELS:CreateLabel( k .. ".      " .. tbl[ 1 ] .. ": " .. tbl[ 2 ].uses .. " uses.", uses_scroll, TOP )
        if clrs[ k ] then
            lbl:SetColor( clrs[ k ] )
        end
    end

    -- Display individual weapon kills
    for k, tbl in pairs( effectiveweps ) do
        local lbl = LAMBDAPANELS:CreateLabel( k .. ".      " .. tbl[ 1 ] .. ": " .. tbl[ 2 ].kills .. " kills.", kills_scroll, TOP )
        if clrs[ k ] then
            lbl:SetColor( clrs[ k ] )
        end
    end
    ----------------------------------------
    
    header:SetColor( Color( math.random( 0, 255 ), math.random( 0, 255 ), math.random( 0, 255 ) ) )
    header:SetFont("Trebuchet24")
    header:SetWrap( true )


    --- Other ---
    total_kills:SetFont("Trebuchet24")
    total_deaths:SetFont("Trebuchet24")
    total_spawns:SetFont("Trebuchet24")
    lastseen:SetFont("Trebuchet24")
    playtime:SetFont("Trebuchet24")
    weaponuses:SetFont("Trebuchet24")
    kd_ratio:SetFont("Trebuchet24")
    textsize:SetFont("Trebuchet24")

    weaponuses:DockMargin( 0, 70, 0, 30 )
    kd_ratio:DockMargin( 0, 10, 0, 10 )
    textsize:DockMargin( 0, 10, 0, 10 )
    playtime:DockMargin( 0, 10, 0, 30 )
    total_kills:DockMargin( 0, 10, 0, 10 )
    lastseen:DockMargin( 0, 10, 0, 10 )
    total_deaths:DockMargin( 0, 10, 0, 10 )
    total_spawns:DockMargin( 0, 10, 0, 10 )
    ---------------------------------------------

    --- Top Weapons ---
    usedweapons_1:SetSize( 1, 80 )
    usedweapons_2:SetSize( 1, 80 )
    usedweapons_3:SetSize( 1, 80 )

    effectiveweapons_1:SetSize( 1, 80 )
    effectiveweapons_2:SetSize( 1, 80 )
    effectiveweapons_3:SetSize( 1, 80 )

    usedweapons_1:SetWrap( true )
    usedweapons_2:SetWrap( true )
    usedweapons_3:SetWrap( true )

    effectiveweapons_1:SetWrap( true )
    effectiveweapons_2:SetWrap( true )
    effectiveweapons_3:SetWrap( true )

    usedweapons_1:SetColor( Color( 0, 255, 0 ) )
    usedweapons_2:SetColor( Color( 0, 128, 160 ) )
    usedweapons_3:SetColor( Color( 97, 44, 0 ) )

    usedweapons_1:SetFont("Trebuchet24")
    usedweapons_2:SetFont("Trebuchet24")
    usedweapons_3:SetFont("Trebuchet24")

    usedweapons_1:SlideDown( 0.5 )
    usedweapons_2:SlideDown( 0.5 )
    usedweapons_3:SlideDown( 0.5 )

    effectiveweapons_1:SetColor( Color( 0, 255, 0 ) )
    effectiveweapons_2:SetColor( Color( 0, 128, 160 ) )
    effectiveweapons_3:SetColor( Color( 97, 44, 0 ) )

    effectiveweapons_1:SetFont("Trebuchet24")
    effectiveweapons_2:SetFont("Trebuchet24")
    effectiveweapons_3:SetFont("Trebuchet24")

    effectiveweapons_1:SlideDown( 0.5 )
    effectiveweapons_2:SlideDown( 0.5 )
    effectiveweapons_3:SlideDown( 0.5 )
    ---------------------------------------------

    function individual_main:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

    local effectiveweps = CreateWeaponsTable( data.weaponstats, true )

    -- Once again, fall back variables
    local first_wep = weps[ 1 ] and weps[ 1 ][ 1 ] or "N/A"
    local second_wep = weps[ 2 ] and weps[ 2 ][ 1 ] or "N/A"
    local third_wep = weps[ 3 ] and weps[ 3 ][ 1 ] or "N/A"

    local first_count = weps[ 1 ] and weps[ 1 ][ 2 ].uses or "N/A"
    local second_count = weps[ 2 ] and weps[ 2 ][ 2 ].uses or "N/A"
    local third_count = weps[ 3 ] and weps[ 3 ][ 2 ].uses or "N/A"

    local first_effective_wep = effectiveweps[ 1 ] and effectiveweps[ 1 ][ 1 ] or "N/A"
    local second_effective_wep = effectiveweps[ 2 ] and effectiveweps[ 2 ][ 1 ] or "N/A"
    local third_effective_wep = effectiveweps[ 3 ] and effectiveweps[ 3 ][ 1 ] or "N/A"

    local first_effective_count = effectiveweps[ 1 ] and effectiveweps[ 1 ][ 2 ].kills or "N/A"
    local second_effective_count = effectiveweps[ 2 ] and effectiveweps[ 2 ][ 2 ].kills or "N/A"
    local third_effective_count = effectiveweps[ 3 ] and effectiveweps[ 3 ][ 2 ].kills or "N/A"

    -- Animate these labels
    HandleText( "Most Used Weapon: ", first_wep .. " with " .. first_count .. " uses.", usedweapons_1 )
    HandleText( "Second Most Used Weapon: ", second_wep .. " with " .. second_count .. " uses.", usedweapons_2 )
    HandleText( "Third Most Used Weapon: ", third_wep .. " with " .. third_count .. " uses.", usedweapons_3 )

    HandleText( "Most Effective Weapon: ", first_effective_wep .. " with " .. first_effective_count .. " kills.", effectiveweapons_1 )
    HandleText( "Second Most Effective Weapon: ", second_effective_wep .. " with " .. second_effective_count .. " kills.", effectiveweapons_2 )
    HandleText( "Third Most Effective Weapon: ", third_effective_wep .. " with " .. third_effective_count .. " kills.", effectiveweapons_3 )

    HandleText( "", name .. "'s individual Statistics", header )
end

-- Opens a panel to list off every Lambda with stats saved.
-- Fairly simple panel
local database_main
local function OpenIndividualDataBase( data )
    if !data then return end
    if IsValid( database_main ) then
        database_main:Remove()
    end
    
    -- The main panel
    database_main = LAMBDAPANELS:CreateFrame( "Individual Stat Viewer", ScrW() * 0.2, ScrH() * 0.2 )
    local listview = vgui.Create( "DListView", database_main )
    listview:Dock(FILL)

    LAMBDAPANELS:CreateLabel( "Search Bar", database_main, TOP )
    LAMBDAPANELS:CreateSearchBar( listview, table.GetKeys( data ), database_main, false ):Dock( TOP )

    listview.Paint = black_paint

    LAMBDAPANELS:CreateLabel( "Double click on a Player Name to view their stats.", database_main, TOP )

    listview:AddColumn( "Player Name", 1 )

    for name, data in pairs( data ) do
        local line = listview:AddLine( name )
        line.Paint = black_paint
    end

    -- Open the individual Lambda's stats
    function listview:DoDoubleClick( id, line )
        OpenIndividualStats( line:GetColumnText( 1 ), data[ line:GetColumnText( 1 ) ] )
    end

    function database_main:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        surface.DrawRect( 0, 0, w, h )
    end

end

-- Opens the main stats panel
local function OpenStatsPanel( ply )
    -- Main panels
    local main = LAMBDAPANELS:CreateFrame( "Lambda Player Statistics", ScrW() * 0.7, ScrH() * 0.7 )
    local scroll = LAMBDAPANELS:CreateScrollPanel( main, false, FILL )

    local patience_inator9000 = LAMBDAPANELS:CreateLabel( "Please wait while the Panel retrieves the Lambda Stats from the Server..", main, TOP )

    main.Paint = black_paint
    scroll.Paint = black_paint

    main:SetSizable( false )

    local curdata
    local refresh_lbl = LAMBDAPANELS:CreateLabel( "Refreshing in N/A", main, TOP )
    
    function main:OnClose()
        if IsValid( database_main ) then database_main:Remove() end
        if IsValid( individual_main ) then individual_main:Remove() end
    end

    -- Auto refresh the panel's data
    LambdaCreateThread( function()
        local next_refresh = CurTime() + 10
        while IsValid( refresh_lbl ) do
            if CurTime() >= next_refresh then
                refresh_lbl:UpdateData( true )
                next_refresh = CurTime() + 10
            end

            refresh_lbl:SetText( "Refreshing in " .. string.NiceTime( next_refresh - CurTime() ) )

            coroutine.yield()
        end
    end )

    ---------- Global Stats ----------
    local toplambdas_1 = LAMBDAPANELS:CreateLabel( "Leading Player: N/A", scroll, TOP )
    local toplambdas_2 = LAMBDAPANELS:CreateLabel( "Second Leading Player: N/A", scroll, TOP )
    local toplambdas_3 = LAMBDAPANELS:CreateLabel( "Third Leading Player: N/A", scroll, TOP )

    local toplambdas_kd_1 = LAMBDAPANELS:CreateLabel( "Leading Kill/Death Ratio Player: N/A", scroll, TOP )
    local toplambdas_kd_2 = LAMBDAPANELS:CreateLabel( "Second Leading Kill/Death Ratio Player: N/A", scroll, TOP )
    local toplambdas_kd_3 = LAMBDAPANELS:CreateLabel( "Third Leading Kill/Death Ratio Player: N/A", scroll, TOP )

    local usedweapons_1 = LAMBDAPANELS:CreateLabel( "Most Used Weapon: N/A", scroll, TOP )
    local usedweapons_2 = LAMBDAPANELS:CreateLabel( "Second Most Used Weapon: N/A", scroll, TOP )
    local usedweapons_3 = LAMBDAPANELS:CreateLabel( "Third Most Used Weapon: N/A", scroll, TOP )

    local effectiveweapons_1 = LAMBDAPANELS:CreateLabel( "Most Effective Weapon: N/A", scroll, TOP )
    local effectiveweapons_2 = LAMBDAPANELS:CreateLabel( "Second Most Effective Weapon: N/A", scroll, TOP )
    local effectiveweapons_3 = LAMBDAPANELS:CreateLabel( "Third Most Effective Weapon: N/A", scroll, TOP )

    local total_kills = LAMBDAPANELS:CreateLabel( "Total Kills: N/A", scroll, TOP )
    local total_deaths = LAMBDAPANELS:CreateLabel( "Total Deaths: N/A", scroll, TOP )
    local total_spawns = LAMBDAPANELS:CreateLabel( "Total Lambdas Spawned: N/A", scroll, TOP )
    local total_textsize = LAMBDAPANELS:CreateLabel( "Total Text Sent: N/A", scroll, TOP )

    ---------- Buttons ----------
    LAMBDAPANELS:CreateButton( scroll, TOP, "View Individual Lambda Stats", function()
        OpenIndividualDataBase( curdata.individual )
    end )

    LAMBDAPANELS:CreateButton( scroll, TOP, "Reset Statistics (Warning Protected)", function()
        if !LocalPlayer():IsSuperAdmin() then chat.AddText( "Only Super Admins can reset statistical data!" ) return end
        Derma_Query( "This can not be undone! Are you sure?", "Reset Statistics", "Yes", function()
            LAMBDAPANELS:WriteServerFile( "lambdaplayers/stats.json", {individual={}}, "json" ) 
            chat.AddText( "Lambda Player Statistics reset!" )
            main:Remove()
        end, "No" )
    end )

    ---------- Individual Weapon Panels ----------
    local individual_weaponpnl = LAMBDAPANELS:CreateBasicPanel( scroll, TOP )
    individual_weaponpnl:SetSize( scroll:GetWide(), 500 )

    local left = LAMBDAPANELS:CreateBasicPanel( individual_weaponpnl, LEFT )
    left:SetSize( main:GetWide() / 2, 1 )
    left.Paint = black_paint

    local weaponuses = LAMBDAPANELS:CreateLabel( "--- Weapon Uses ---", left, TOP )
    weaponuses:SetFont("Trebuchet24")
    weaponuses:DockMargin( 0, 70, 0, 30 )

    local uses_scroll = LAMBDAPANELS:CreateScrollPanel( left, false, FILL )

    local right = LAMBDAPANELS:CreateBasicPanel( individual_weaponpnl, LEFT )
    right:SetSize( main:GetWide() / 2, 1 )
    right.Paint = black_paint

    local weaponkills = LAMBDAPANELS:CreateLabel( "--- Weapon Kills ---", right, TOP )
    weaponkills:SetFont("Trebuchet24")
    weaponkills:DockMargin( 0, 70, 0, 30 )

    local kills_scroll = LAMBDAPANELS:CreateScrollPanel( right, false, FILL )

    --- Global Data ---
    total_kills:SetFont("Trebuchet24")
    total_deaths:SetFont("Trebuchet24")
    total_spawns:SetFont("Trebuchet24")
    total_textsize:SetFont("Trebuchet24")

    total_kills:DockMargin( 0, 10, 0, 10 )
    total_textsize:DockMargin( 0, 10, 0, 10 )
    total_deaths:DockMargin( 0, 10, 0, 10 )
    total_spawns:DockMargin( 0, 10, 0, 10 )
    ---------------------------------------------

    --- Top Weapons ---
    usedweapons_1:SetColor( Color( 0, 255, 0 ) )
    usedweapons_2:SetColor( Color( 0, 128, 160 ) )
    usedweapons_3:SetColor( Color( 97, 44, 0 ) )

    usedweapons_1:SetFont("Trebuchet24")
    usedweapons_2:SetFont("Trebuchet24")
    usedweapons_3:SetFont("Trebuchet24")

    usedweapons_1:DockMargin( 0, 0, 0, 0 )
    usedweapons_1:Dock( TOP )
    usedweapons_1:SlideDown( 0.5 )
    
    usedweapons_2:DockMargin( 0, 20, 0, 0 )
    usedweapons_2:Dock( TOP )
    usedweapons_2:SlideDown( 0.5 )

    usedweapons_3:DockMargin( 0, 20, 0, 50 )
    usedweapons_3:Dock( TOP )
    usedweapons_3:SlideDown( 0.5 )

    effectiveweapons_1:SetColor( Color( 0, 255, 0 ) )
    effectiveweapons_2:SetColor( Color( 0, 128, 160 ) )
    effectiveweapons_3:SetColor( Color( 97, 44, 0 ) )

    effectiveweapons_1:SetFont("Trebuchet24")
    effectiveweapons_2:SetFont("Trebuchet24")
    effectiveweapons_3:SetFont("Trebuchet24")
    
    effectiveweapons_1:DockMargin( 0, 0, 0, 0 )
    effectiveweapons_1:Dock( TOP )
    effectiveweapons_1:SlideDown( 0.5 )

    effectiveweapons_2:DockMargin( 0, 20, 0, 0 )
    effectiveweapons_2:Dock( TOP )
    effectiveweapons_2:SlideDown( 0.5 )

    effectiveweapons_3:DockMargin( 0, 20, 0, 100 )
    effectiveweapons_3:Dock( TOP )
    effectiveweapons_3:SlideDown( 0.5 )
    
    ---------------------------------------------

    --- Top KD Lambdas ---
    toplambdas_kd_1:SetColor( Color( 0, 255, 0 ) )
    toplambdas_kd_2:SetColor( Color( 0, 128, 160 ) )
    toplambdas_kd_3:SetColor( Color( 97, 44, 0 ) )

    toplambdas_kd_1:SetFont("Trebuchet24")
    toplambdas_kd_2:SetFont("Trebuchet24")
    toplambdas_kd_3:SetFont("Trebuchet24")

    toplambdas_kd_1:DockMargin( 0, 10, 10, 10 )
    toplambdas_kd_1:Dock( TOP )
    toplambdas_kd_1:SlideDown( 0.5 )
    
    toplambdas_kd_2:DockMargin( 0, 10, 0, 10 )
    toplambdas_kd_2:Dock( TOP )
    toplambdas_kd_2:SlideDown( 0.5 )

    toplambdas_kd_3:DockMargin( 0, 10, 0, 100 )
    toplambdas_kd_3:Dock( TOP )
    toplambdas_kd_3:SlideDown( 0.5 )
    ---------------------------------------------

    --- Top Lambdas ---
    toplambdas_1:SetSize( 1, 40 )
    toplambdas_2:SetSize( 1, 40 )
    toplambdas_3:SetSize( 1, 40 )

    toplambdas_1:SetColor( Color( 0, 255, 0 ) )
    toplambdas_2:SetColor( Color( 0, 128, 160 ) )
    toplambdas_3:SetColor( Color( 97, 44, 0 ) )

    toplambdas_1:SetFont("DermaLarge")
    toplambdas_2:SetFont("DermaLarge")
    toplambdas_3:SetFont("DermaLarge")

    toplambdas_1:DockMargin( 0, 30, 0, 30 )
    toplambdas_1:Dock( TOP )
    toplambdas_1:SlideDown( 0.5 )

    toplambdas_2:DockMargin( 0, 30, 0, 30 )
    toplambdas_2:Dock( TOP )
    toplambdas_2:SlideDown( 0.5 )

    toplambdas_3:DockMargin( 0, 30, 0, 30 )
    toplambdas_3:Dock( TOP )
    toplambdas_3:SlideDown( 0.5 )
    ---------------------------------------------

    local weaponuses_lbls = {}
    local weaponkills_lbls = {}

    local function UpdateData( data, no_animation )

        if IsValid( patience_inator9000 ) then
            patience_inator9000:Remove()
        end
        
        if !data then return end
    
        -- Set the total labels
        total_kills:SetText( "Total Kills: " .. ( data.glb_kills or 0 ) )
        total_deaths:SetText( "Total Deaths: " .. ( data.glb_deaths or 0 ) )
        total_spawns:SetText( "Total Lambdas Spawned: " .. ( data.glb_initialspawns or 0 ) )
        total_textsize:SetText( "Total Text Sent: " .. string.NiceSize( ( data.glb_textsize or 0 ) ) )

        -- Fallback parameters
        -- Gotta love potentially missing data
        if data.glb_weaponstats then
            for name, wepdata in pairs( data.glb_weaponstats ) do
                data.glb_weaponstats[ name ].kills = data.glb_weaponstats[ name ].kills or 0
                data.glb_weaponstats[ name ].uses = data.glb_weaponstats[ name ].uses or 1
            end
        end

        -- Create the sorted tables
        local top_lambdas = CreateLambdaKillsTable(  data.individual or {} )
        local top_kd_lambdas = CreateLambdaKDTable( data.individual or {} )
        local top_weapons = CreateWeaponsTable( data.glb_weaponstats or {} )
        local effective_weapons = CreateWeaponsTable( data.glb_weaponstats or {}, true )

        -- Update the individual weapon uses
        for k, tbl in pairs( top_weapons ) do
            if weaponuses_lbls[ tbl[ 1 ] ] then
                weaponuses_lbls[ tbl[ 1 ] ]:Remove()
            end
            local lbl = LAMBDAPANELS:CreateLabel( k .. ".      " .. tbl[ 1 ] .. ": " .. ( tbl[ 2 ].uses or 1 ) .. " uses.", uses_scroll, TOP )
            if clrs[ k ] then
                lbl:SetColor( clrs[ k ] )
            end
            weaponuses_lbls[ tbl[ 1 ] ] = lbl
        end

        -- Update the individual weapon kills
        for k, tbl in pairs( effective_weapons ) do
            if weaponkills_lbls[ tbl[ 1 ] ] then
                weaponkills_lbls[ tbl[ 1 ] ]:Remove()
            end
            local lbl = LAMBDAPANELS:CreateLabel( k .. ".      " .. tbl[ 1 ] .. ": " .. ( tbl[ 2 ].kills or 1 ) .. " Kills.", kills_scroll, TOP )
            if clrs[ k ] then
                lbl:SetColor( clrs[ k ] )
            end
            weaponkills_lbls[ tbl[ 1 ] ] = lbl
        end

        -- A bunch of variables with fallbacks. Arceus, this is quite something.
        local first_lambda = top_lambdas[ 1 ] and top_lambdas[ 1 ][ 1 ] or "N/A"
        local second_lambda = top_lambdas[ 2 ] and top_lambdas[ 2 ][ 1 ] or "N/A"
        local third_lambda = top_lambdas[ 3 ] and top_lambdas[ 3 ][ 1 ] or "N/A"
        local first_lambda_count = top_lambdas[ 1 ] and top_lambdas[ 1 ][ 2 ] or "N/A"
        local second_lambda_count = top_lambdas[ 2 ] and top_lambdas[ 2 ][ 2 ] or "N/A"
        local third_lambda_count = top_lambdas[ 3 ] and top_lambdas[ 3 ][ 2 ] or "N/A"

        local first_kd_lambda = top_kd_lambdas[ 1 ] and top_kd_lambdas[ 1 ][ 1 ] or "N/A"
        local second_kd_lambda = top_kd_lambdas[ 2 ] and top_kd_lambdas[ 2 ][ 1 ] or "N/A"
        local third_kd_lambda = top_kd_lambdas[ 3 ] and top_kd_lambdas[ 3 ][ 1 ] or "N/A"
        local first_kd_lambda_count = top_kd_lambdas[ 1 ] and top_kd_lambdas[ 1 ][ 2 ] or "N/A"
        local second_kd_lambda_count = top_kd_lambdas[ 2 ] and top_kd_lambdas[ 2 ][ 2 ] or "N/A"
        local third_kd_lambda_count = top_kd_lambdas[ 3 ] and top_kd_lambdas[ 3 ][ 2 ] or "N/A"

        local first_weapon = top_weapons[ 1 ] and top_weapons[ 1 ][ 1 ] or "N/A"
        local second_weapon = top_weapons[ 2 ] and top_weapons[ 2 ][ 1 ] or "N/A"
        local third_weapon = top_weapons[ 3 ] and top_weapons[ 3 ][ 1 ] or "N/A"
        local first_weapon_count = top_weapons[ 1 ] and top_weapons[ 1 ][ 2 ].uses or "N/A"
        local second_weapon_count = top_weapons[ 2 ] and top_weapons[ 2 ][ 2 ].uses or "N/A"
        local third_weapon_count = top_weapons[ 3 ] and top_weapons[ 3 ][ 2 ].uses or "N/A"

        local first_effective_weapon = effective_weapons[ 1 ] and effective_weapons[ 1 ][ 1 ] or "N/A"
        local second_effective_weapon = effective_weapons[ 2 ] and effective_weapons[ 2 ][ 1 ] or "N/A"
        local third_effective_weapon = effective_weapons[ 3 ] and effective_weapons[ 3 ][ 1 ] or "N/A"
        local first_effective_weapon_count = effective_weapons[ 1 ] and effective_weapons[ 1 ][ 2 ].kills or "N/A"
        local second_effective_weapon_count = effective_weapons[ 2 ] and effective_weapons[ 2 ][ 2 ].kills or "N/A"
        local third_effective_weapon_count = effective_weapons[ 3 ] and effective_weapons[ 3 ][ 2 ].kills or "N/A"

        -- Animate these labels
        HandleText( "Leading Player: ", first_lambda .. " with " .. first_lambda_count .. " kills.", toplambdas_1, no_animation )
        HandleText( "Second Leading Player: ", second_lambda .. " with " .. second_lambda_count .. " kills.", toplambdas_2, no_animation )
        HandleText( "Third Leading Player: ", third_lambda .. " with " .. third_lambda_count .. " kills.", toplambdas_3, no_animation )

        HandleText( "Leading Kill/Death Ratio Player: ", first_kd_lambda .. " with a KD of " .. first_kd_lambda_count, toplambdas_kd_1, no_animation )
        HandleText( "Second Leading Kill/Death Ratio Player: ", second_kd_lambda .. " with a KD of " .. second_kd_lambda_count, toplambdas_kd_2, no_animation )
        HandleText( "Third Leading Kill/Death Ratio Player: ", third_kd_lambda .. " with a KD of " .. third_kd_lambda_count, toplambdas_kd_3, no_animation )

        HandleText( "Most Used Weapon: ", first_weapon .. " with " .. first_weapon_count .. " uses.", usedweapons_1, no_animation )
        HandleText( "Second Most Used Weapon: ", second_weapon .. " with " .. second_weapon_count .. " uses.", usedweapons_2, no_animation )
        HandleText( "Third Most Used Weapon: ", third_weapon .. " with " .. third_weapon_count .. " uses.", usedweapons_3, no_animation )

        HandleText( "Most Effective Weapon: ", first_effective_weapon .. " with " .. first_effective_weapon_count .. " kills.", effectiveweapons_1, no_animation )
        HandleText( "Second Most Effective Weapon: ", second_effective_weapon .. " with " .. second_effective_weapon_count .. " kills.", effectiveweapons_2, no_animation )
        HandleText( "Third Most Effective Weapon: ", third_effective_weapon .. " with " .. third_effective_weapon_count .. " kills.", effectiveweapons_3, no_animation )
        
        curdata = data
    end

    -- Updates the panel's data. This function is a method to refresh_lbl so it can be used further up the function
    function refresh_lbl:UpdateData( no_animation )

        if !LocalPlayer():IsListenServerHost() then
            LAMBDAPANELS:RequestDataFromServer( "lambdaplayers/stats.json", "json", function( data )

                UpdateData( data, no_animation )

            end, true )
        else
            UpdateData( LAMBDAFS:ReadFile( "lambdaplayers/stats.json", "json" ), no_animation )
        end
    end

    refresh_lbl:UpdateData()

end

RegisterLambdaPanel( "Lambda Stats", "Opens a panel that allows you to view various data about the Lambda", OpenStatsPanel )