class("TimeOnline")

function TimeOnline:__init()
	SQL:Execute('CREATE TABLE IF NOT EXISTS players (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, steamID VARCHAR UNIQUE, hours INTEGER, minutes INTEGER)')
	self.timeOnline = {}
	Events:Subscribe( "PlayerJoin", self, self.PlayerJoined )
	Events:Subscribe( "PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe( "PostTick", self, self.PostTick )
end

function TimeOnline:PostTick()
	for player in Server:GetPlayers() do
		if self.timeOnline[player:GetId()] ~= nil and self.timeOnline[player:GetId()]:GetSeconds() > 59 then
			player:SetNetworkValue("Minutes", player:GetValue("Minutes") + 1)
			if player:GetValue("Minutes") == 60 then
				player:SetNetworkValue("Hours", player:GetValue("Hours") + 1)
				player:SetNetworkValue("Minutes", 0)
			end
			self.timeOnline[player:GetId()]:Restart()
		end
	end
end

function TimeOnline:PlayerJoined(args)
	self:LoadPlayer(args.player)
	self.timeOnline[args.player:GetId()] = Timer()
end

function TimeOnline:PlayerQuit (args)
	self:SavePlayer(args.player)
	self.timeOnline[args.player:GetId()] = nil
end

function TimeOnline:SavePlayer(player)
  local cmd = SQL:Command('UPDATE players SET hours = ?, minutes = ? WHERE steamID = ?') -- UPDATE
  cmd:Bind(1, player:GetValue("Hours") or 0)
  cmd:Bind(2, player:GetValue("Minutes") or 0)
  cmd:Bind(3, player:GetSteamId().id)
  cmd:Execute()
end

function TimeOnline:LoadPlayer(player)
  local qry = SQL:Query( "SELECT hours, minutes FROM players WHERE steamID = (?) LIMIT 1" )
  qry:Bind( 1, player:GetSteamId().id )
  local result = qry:Execute()
  if #result > 0 then
    local hours = result[1].hours
    local minutes = result[1].minutes
    player:SetNetworkValue("Hours", tonumber(hours))
    player:SetNetworkValue("Minutes", tonumber(minutes))
  else
    local cmd = SQL:Command( "INSERT OR REPLACE INTO players (steamID, hours, minutes) values (?, 0, 0)" )
    cmd:Bind( 1, player:GetSteamId().id )
    cmd:Execute()
    --fetch
    local qry = SQL:Query( "SELECT hours, minutes FROM players WHERE steamID = (?) LIMIT 1" )
    qry:Bind( 1, player:GetSteamId().id )
    local result = qry:Execute()
    if #result > 0 then
      local hours = result[1].hours
      local minutes = result[1].minutes
      player:SetNetworkValue("Hours", tonumber(hours))
      player:SetNetworkValue("Minutes", tonumber(minutes))
    end
  end
end

timeonline = TimeOnline()
