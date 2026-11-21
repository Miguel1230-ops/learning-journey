local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local isla = workspace:WaitForChild("IslaDelViento")
local puente = isla:WaitForChild("ObrasDelArchipielago"):WaitForChild("PuenteLevadizo")
local sinPaso, tablero, cierre = "RescatePendiente", "TableroDelRefugio", "LimiteDelRescate"
for _, nombre in {sinPaso, tablero, cierre} do
	if not PhysicsService:IsCollisionGroupRegistered(nombre) then PhysicsService:RegisterCollisionGroup(nombre) end
end
PhysicsService:CollisionGroupSetCollidable(sinPaso, tablero, false)
PhysicsService:CollisionGroupSetCollidable("Default", cierre, false)
PhysicsService:CollisionGroupSetCollidable(sinPaso, cierre, true)
for _, hoja in {puente.HojaOeste,puente.HojaEste} do
	for _,p in hoja:GetDescendants() do
		if p:IsA("BasePart") then p.CollisionGroup = tablero end
	end
end
local limite = Instance.new("Part")
limite.Name = "LimiteDePaso"
limite.Anchored, limite.CanTouch, limite.CanQuery, limite.Transparency = true, false, false, 1
limite.Size = Vector3.new(2,100,130)
limite.CFrame = CFrame.new(puente.HojaOeste:GetPivot().Position.X + 1.2,30,0)
limite.CollisionGroup, limite.Parent = cierre, puente
-- Los perfiles antiguos con Cometa ya completaron la defensa.
local function tienePaso(p)
	return p:GetAttribute("VigiasDerrotados") or p:GetAttribute("Cometa")
end
local function observar(p)
	local original = setmetatable({}, {__mode="k"})
	local enlace
	local function configurar(obj)
		if not obj:IsA("BasePart") then return end
		if tienePaso(p) then
			if original[obj] then obj.CollisionGroup=original[obj]; original[obj]=nil end
		elseif obj.CollisionGroup~=sinPaso then
			original[obj]=obj.CollisionGroup; obj.CollisionGroup=sinPaso
		end
	end
	local function refrescar()
		if p.Character then for _,pieza in p.Character:GetDescendants() do configurar(pieza) end end
	end
	local function personaje(c)
		if enlace then enlace:Disconnect() end
		enlace=c.DescendantAdded:Connect(configurar)
		refrescar()
	end
	p.CharacterAdded:Connect(personaje)
	p.CharacterRemoving:Connect(function() if enlace then enlace:Disconnect(); enlace=nil end end)
	for _,a in {"VigiasDerrotados","Cometa"} do p:GetAttributeChangedSignal(a):Connect(refrescar) end
	if p.Character then personaje(p.Character) end
end
Players.PlayerAdded:Connect(observar)
for _,p in Players:GetPlayers() do observar(p) end
while task.wait(.2) do
	for _,p in Players:GetPlayers() do
		if p:GetAttribute("ProgresoListo") and not tienePaso(p) then
			local c=p.Character
			local r=c and c:FindFirstChild("HumanoidRootPart")
			if r and r.Position.X>limite.Position.X+2.5 and not p:GetAttribute("EnCueva") and not p:GetAttribute("EnMolino") and not p:GetAttribute("EnFaro") then
				c:PivotTo(isla.Inicio.CFrame + Vector3.yAxis*3.3)
				r.AssemblyLinearVelocity=Vector3.zero
			end
		end
	end
end
