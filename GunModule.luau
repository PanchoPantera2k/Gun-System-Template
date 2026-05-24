-- Roblox Services
local SS = game:GetService("ServerStorage")

local Gun = {}

Gun.Settings = {
	bloodEffectEnabled = true, -- Disable or Enable the blood effects
	bloodEffectsFolder = SS.Gun.BloodEffects, -- The location of the blood effects folder, Set to nil if you don't want blood effects
	bloodEffectName = "Effect1", -- The name of the normal blood effect in the bloodEffectsFolder
	headshotBloodEffectName = "Effect2", -- The name of the headshot blood effect in the bloodEffectsFolder, it can be the same as the normal one
	bloodEffectDuration = 0.5, -- The duration of the blood effect
	storedSounds = SS.Gun.Sounds, -- The folder with the sounds of the guns
	damageFalloff = true -- Disable or Enable the damage falloff with distance
}

-- DO NOT EDIT
Gun.SettingsType = {
	bloodEffectEnabled = "boolean",
	bloodEffectsFolder = "Instance",
	bloodEffectName = "string",
	bloodEffectDuration = "number",
	headshotBloodEffectName = "string",
	bloodEffectHeadshotDuration = "number",
	storedSounds = "Instance"
}

assert(typeof(Gun.Settings.bloodEffectEnabled) == Gun.SettingsType.bloodEffectEnabled, "Gun.Settings.bloodEffectEnabled must be a boolean value.")
assert(Gun.Settings.bloodEffectEnabled and typeof(Gun.Settings.bloodEffectsFolder) == Gun.SettingsType.bloodEffectsFolder or true, "Gun.Settings.bloodEffectsFolder must be an Instance.")
assert(typeof(Gun.Settings.bloodEffectName) == Gun.SettingsType.bloodEffectName, "Gun.Settings.bloodEffectName must be a string value.")
assert(typeof(Gun.Settings.bloodEffectDuration) == Gun.SettingsType.bloodEffectDuration, "Gun.Settings.bloodEffectDuration must be a number value.")
assert(Gun.Settings.bloodEffectDuration > 0, "Gun.Settings.bloodEffectDuration must be greater than 0.")
assert(typeof(Gun.Settings.headshotBloodEffectName) == Gun.SettingsType.headshotBloodEffectName, "Gun.Settings.headshotBloodEffectName must be a string value.")
assert(typeof(Gun.Settings.storedSounds) == Gun.SettingsType.storedSounds, "Gun.Settings.storedSounds must be an Instance.")

-- gunData template
type gunData = {
	Name: string, -- Name of the gun
	Damage: number, -- Damage per shot
	Range: number, -- Range of the gun
	FireRate: number, -- Wait time between shots
	MagSize: number, -- Max ammo allowed in the mag (the amount you have before having to reload)
	ReloadTime: number, -- Time to reload gun
	AmmoInMag: number, -- The ammo thats already loaded in the gun
	Ammo: number, -- Starting ammo 
	HeadshotMultiplier: number, -- Multipier if the bullet hits the head
	Spread: number, -- How far the bullet can spread away 
	Model: Model -- Model of the gun
}

Gun.__index = Gun

-- Table containg all existing gun objects for all players
Gun.Guns = {}

-- Function to check if the data is correctly setup
local function checkGunData(data:gunData)
	assert(typeof(data) == "table", "Gun data must be a table.")

	assert(typeof(data.Name) == "string", "Name must be a string.")
	assert(typeof(data.MagSize) == "number", "MagSize must be a number.")
	assert(data.MagSize > 0, "MagSize must be greater than 0.")
	assert(math.round(data.MagSize) == data.MagSize, "MagSize must be a whole number.")
	assert(typeof(data.AmmoInMag) == "number", "AmmoInMag must be a number.")
	assert(math.round(data.AmmoInMag) == data.AmmoInMag, "AmmoInMag must be a whole number.")
	assert(typeof(data.Ammo) == "number", "Ammo must be a number.")
	assert(data.Ammo > 0, "Ammo must be greater than 0.")
	assert(math.round(data.Ammo) == data.Ammo, "Ammo must be a whole number.")
	assert(typeof(data.Damage) == "number", "Damage must be a number.")
	assert(data.Damage > 0, "Damage must be greater than 0.")
	assert(typeof(data.Range) == "number", "Range must be a number.")
	assert(data.Range > 0, "Range must be greater than 0.")
	assert(typeof(data.FireRate) == "number", "FireRate must be a number.")
	assert(data.FireRate > 0, "FireRate must be greater than 0.")
	assert(typeof(data.ReloadTime) == "number", "ReloadTime must be a number.")
	assert(data.ReloadTime > 0, "ReloadTime must be greater than 0.")
	assert(typeof(data.HeadshotMultiplier) == "number", "HeadshotMultiplier must be a number.")
	assert(data.HeadshotMultiplier > 0, "HeadshotMultiplier must be greater than 0.")
	assert(typeof(data.Spread) == "number", "Spread must be a number.")

	assert(typeof(data.Model) == "Instance", "Model must be an instance.")
	assert(data.Model:IsA("Model"), "Model in data for: "..data.Name.." gun must be a Model.")
	assert(data.Model.BulletOrigin:FindFirstChild("Sounds"), data.Model.Name.." model must have a Sounds folder.")
end

-- Function to add gun to the players gun table
function Gun:AddGun(plr: Player, gun:gunData)
	if not Gun.Guns[plr] then
		Gun.Guns[plr] = {}
	end

	table.insert(Gun.Guns[plr], gun)
end

-- Function to get gun object from given model
function Gun:GetGunFromModel(Model: Model)
	for plr, Table in pairs(Gun.Guns) do
		for _, gun in pairs(Table) do
			if gun.CurrentModel == Model then
				return gun, plr
			end
		end
	end
	
	return nil
end

-- Function to get gun table from the given player
function Gun:GetGunsFromPlayer(plr:Player)
	if Gun.Guns[plr] then
		return Gun.Guns[plr]
	end
	
	return nil
end

-- Function to remove a gun from the gun table
function Gun:RemoveGun(plr: Player, givenGun:gunData)
	if not Gun.Guns[plr] then 
		return
	end
		
	for i, gun in pairs(Gun.Guns[plr]) do
		if gun ~= givenGun then continue end
		if gun.CurrentModel then gun.CurrentModel:Destroy() end
	
		table.remove(Gun.Guns[plr], i)
		break
	end
end

-- Function to remove gun from the given model
function Gun:RemoveGunFromModel(Model:Model)
	local gun, plr = Gun:GetGunFromModel(Model)
	Gun:RemoveGun(plr, gun)
end

-- Function to initiate the gun object, use :Parent to create model
function Gun.New(Data:gunData, Owner:Player)
	checkGunData(Data)
	
	-- Set metatable and all properties
	local self = setmetatable({}, Gun)
	self.Name = Data.Name
	self.MagSize = Data.MagSize
	self.AmmoInMag = Data.AmmoInMag
	self.Ammo = Data.Ammo
	self.Damage = Data.Damage
	self.Range = Data.Range
	self.FireRate = Data.FireRate
	self.ReloadTime = Data.ReloadTime
	self.HeadshotMultiplier = Data.HeadshotMultiplier
	self.Spread = Data.Spread
	
	self.Model = Data.Model
	self.CurrentModel = nil
	
	self.Owner = Owner
	
	self.Reloading = false
	self.LastShot = 0
	self.CanShoot = true
	
	-- Add gun to the gun table
	Gun:AddGun(Owner, self)
	
	-- Return gun object WITHOUT model (Use :Parent)
	return self
end

-- Function to create a model
function Gun:CreateModel(newParent:Model)
	if not self.Model then return end
	if self.CurrentModel then return end
	
	self.CurrentModel = self.Model:Clone()

	self.CurrentModel:SetAttribute("MagSize", self.MagSize)
	self.CurrentModel:SetAttribute("ReloadTime", self.ReloadTime)
	self.CurrentModel:SetAttribute("AmmoInMag", self.AmmoInMag)
	self.CurrentModel:SetAttribute("Ammo", self.Ammo)
	self.CurrentModel:SetAttribute("FireRate", self.FireRate)
	self.CurrentModel:SetAttribute("Damage", self.Damage)
	self.CurrentModel:SetAttribute("Range", self.Range)
	self.CurrentModel:SetAttribute("HeadshotMultiplier", self.HeadshotMultiplier)
	self.CurrentModel:SetAttribute("Spread", self.Spread)
	
	self.CurrentModel:SetAttribute("Reloading", self.Reloading)
	
	self.CurrentModel:SetAttribute("Owner", self.Owner.Name)

	assert(self.CurrentModel:FindFirstChild("BulletOrigin"), "CurrentModel is missing BulletOrigin part.")
	assert(self.CurrentModel:FindFirstChild("Handle"), "CurrentModel is missing Handle part.")
	assert(self.CurrentModel.BulletOrigin:FindFirstChild("Sounds"), "CurrentModel is missing Sounds folder.")

	self.CurrentModel.Parent = newParent
end

-- Create a blood effect
local function createBloodEffect(raycastInstance:Instance, raycastPosition:Vector3, effectName:string)
	if not Gun.Settings.bloodEffectEnabled then return end
	
	-- Temp holder part
	local holderPart = Instance.new("Part")
	holderPart.Size = Vector3.new(1,1,1)
	holderPart.CanCollide = false
	holderPart.Transparency = 1
	
	local Effect = Gun.Settings.bloodEffectsFolder:FindFirstChild(effectName)
	assert(Effect, "No blood effect named: "..effectName)
	local effectClone =	Effect:Clone()
	effectClone.Parent = holderPart
	
	holderPart.Position = raycastPosition
	
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = holderPart
	weldConstraint.Part1 = raycastInstance
	weldConstraint.Parent = holderPart
	
	game.Debris:AddItem(holderPart, Gun.Settings.bloodEffectDuration)
	
	holderPart.Parent = raycastInstance
end

-- Play a sound from the gun folder and parent it
local function playSound(soundName, model)
	local gun = Gun:GetGunFromModel(model)
	
	local soundsFolder = Gun.Settings.storedSounds[gun.Name]
	assert(soundsFolder, "No sounds folder for gun: "..gun.Name)
	local Sound = soundsFolder[soundName]
	assert(Sound, "No "..soundName.." sound for gun: "..gun.Name)
	local soundClone = Sound:Clone()
	soundClone.Parent = model.BulletOrigin.Sounds
	soundClone:Play()

	soundClone.Ended:Connect(function() 
		soundClone:Destroy()
	end)
end

-- Create a bullet
local function createBullet(targetPos:Vector3)
	local Bullet = Instance.new("Part")
	Bullet.Name = "Bullet"
	Bullet.Size = Vector3.new(0.1, 0.1, 0.1)
	Bullet.Shape = Enum.PartType.Ball
	Bullet.Color = Color3.fromRGB(67, 67, 67)
	Bullet.Material = Enum.Material.Metal
	Bullet.CanCollide = false
	Bullet.Anchored = true
	Bullet.BottomSurface = Enum.SurfaceType.Smooth
	Bullet.TopSurface = Enum.SurfaceType.Smooth
	Bullet.Parent = workspace.Bullets
	Bullet.Position = targetPos
	
	game.Debris:AddItem(Bullet, 15)
end

-- Calculate damage using the distance between the hit object and self
local function calculateDamage(defaultDamage:number, raycastResult:RaycastResult, self)
	if not Gun.Settings.damageFalloff then return defaultDamage end
	local Distance = raycastResult.Distance
	local maxRange = self.Range
	
	if Distance > maxRange then
		return 0
	end
	
	-- Fall off based on distance
	local distanceMultiplier = 1-(Distance/maxRange)
	local Damage = defaultDamage*distanceMultiplier
	
	return Damage
end

-- Function to reload the gun
function Gun:Reload()
	if self.Reloading then return end
	if self.AmmoInMag == self.MagSize then return end
	
	if self.Ammo <= 0 then
		playSound("Empty", self.CurrentModel)
		return
	end
	
	self.CanShoot = false
	self.Reloading = true
	self.CurrentModel:SetAttribute("Reloading", self.Reloading)
	
	playSound("Reloading", self.CurrentModel)
	
	task.delay(self.ReloadTime, function()
		local ammoNeeded = self.MagSize - self.AmmoInMag
		local ammoToLoad = math.min(ammoNeeded, self.Ammo)

		self.AmmoInMag += ammoToLoad
		self.Ammo -= ammoToLoad
		
		self.CanShoot = true
		self.Reloading = false
		self.CurrentModel:SetAttribute("Reloading", self.Reloading)
	end)
end

-- Function to shoot a bullet directed towards the mousepos
function Gun:Shoot(plr, mousePosition:Vector3)
	if not self.CanShoot then return end
	if not self.CurrentModel then warn("Cannot shoot gun without model") return end
	if self.AmmoInMag <= 0 then self:Reload() return end
	if self.CurrentModel.Parent ~= self.Owner.Character then return end	
	if self.Owner ~= plr then return end
		
	local currentTime = tick()

	if currentTime - self.LastShot < self.FireRate then
		return
	end

	self.LastShot = currentTime	
	self.CanShoot = false
	self.AmmoInMag -= 1
		
	self.CurrentModel:SetAttribute("AmmoInMag", self.AmmoInMag)
	self.CurrentModel:SetAttribute("Ammo", self.Ammo)	

	task.spawn(function()
		task.wait(self.FireRate)
		self.CanShoot = true
	end)
		
	playSound("Fire", self.CurrentModel)	

	if self._hitCallback then
		if typeof(self._hitCallback) == "function" then
			self._hitCallback(self)
		else
			warn("Callback in Gun:OnShot is not a function")
		end
	end	
		
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {self.CurrentModel.Parent, workspace.Bullets, self.Owner.Character}

	local bulletOrigin = self.CurrentModel:FindFirstChild("BulletOrigin")
	
	if not bulletOrigin then warn("CurrentModel is missing BulletOrigin part.") return end
	
	local Origin = bulletOrigin.Position
	local Direction = (mousePosition - Origin).Unit
 
	local X = (math.random() - 0.5) * self.Spread
	local Y = (math.random() - 0.5) * self.Spread
	local spreadCFrame = CFrame.new(Origin, Origin + Direction) * CFrame.Angles(Y, X, 0)
	local spreadDirection = spreadCFrame.LookVector * 1000

	local raycastResult = workspace:Raycast(Origin, spreadDirection, raycastParams)

	if raycastResult then
		local raycastInstance = raycastResult.Instance
		local Humanoid = (raycastInstance.Parent and raycastInstance.Parent.Parent) and (raycastInstance.Parent:FindFirstChildOfClass("Humanoid") or raycastInstance.Parent.Parent:FindFirstChildOfClass("Humanoid")) or nil

		if not Humanoid or self.Owner.Character:FindFirstChildOfClass("Humanoid") == Humanoid then
			createBullet(raycastResult.Position) 
		else
			if Humanoid.Health <= 0 then return end
			
			local Damage
			local isHeadshot = false

			if raycastInstance.Name == "Head" then
				Damage = calculateDamage(self.Damage * self.HeadshotMultiplier, raycastResult, self)
				Humanoid:TakeDamage(Damage)
				isHeadshot = true
			else
				Damage = calculateDamage(self.Damage, raycastResult, self)
				Humanoid:TakeDamage(Damage)
				isHeadshot = false
			end

			createBloodEffect(raycastInstance, raycastResult.Position, isHeadshot and Gun.Settings.headshotBloodEffectName or Gun.Settings.bloodEffectName)
			
			if self._hitplrCallback then
				if typeof(self._hitplrCallback) == "function" then
					self._hitplrCallback(self, Humanoid, Damage, isHeadshot)
				else
					warn("Callback in Gun:OnHit is not a function")
				end
			end
		end
	end
end

-- Function to connect the gun shooting to a function
function Gun:OnShot(callback)
	self._hitCallback = callback
end

-- Function to connect the gun hitting a player to a function
function Gun:OnHit(callback)
	self._hitplrCallback = callback
end

-- Function to delete the gun and remove it from the retrival system
function Gun:Remove()
	if self.CurrentModel then 
		Gun:RemoveGunFromModel(self.CurrentModel)
	else
		local plr
		
		for curplr, Table in pairs(Gun.Guns) do
			for _, gun in pairs(Table) do
				if gun == self then
					plr = curplr
				end
			end
		end
		
		Gun:RemoveGun(plr, self)
	end
end

-- Function to remove all guns from a player
function Gun:RemoveGunsFromPlayer(plr:Player)
	local Guns = Gun:GetGunsFromPlayer(plr)
	
	if Guns then
		for _, gun in pairs(Guns) do
			if gun then
				gun:Remove()
			end
		end
	end
	
	if Gun.Guns[plr] then
		Gun.Guns[plr] = nil
	end 
end

return Gun