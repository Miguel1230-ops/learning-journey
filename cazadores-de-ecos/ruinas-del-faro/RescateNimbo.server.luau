local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Escena = require(script.Parent:WaitForChild("EscenaNimbo"))
local faro = workspace:WaitForChild("IslaDelViento"):WaitForChild("RuinasDelFaro")
local remoto = ReplicatedStorage:WaitForChild("AccionFaro")
local ruta, base, salto, huevo = Escena.ruta(faro)
local modelos = Instance.new("Folder")
modelos.Name = "EcosDelFaro"
for _,aurora in {false,true} do
	Escena.eco(aurora).Parent = modelos
end
modelos.Parent = ReplicatedStorage

local function prompt(parte,nombre,accion)
	local p = Instance.new("ProximityPrompt")
	p.Name,p.ObjectText,p.ActionText = nombre,"Nido de tormenta",accion
	p.RequiresLineOfSight,p.MaxActivationDistance = false,6
	p.Parent = parte
	return p
end

local subir = prompt(base,"Subir","Subir a la torre")
local saltar = prompt(salto,"Saltar","Saltar y planear")
local abrir = prompt(huevo,"Abrir","Abrir el cascarón")
local regreso = Instance.new("Attachment")
regreso.Name,regreso.Position,regreso.Parent = "Salida",Vector3.new(4,2,4),ruta.Nido
local volver = prompt(regreso,"Volver","Volver a la torre")
local centro = {}
for i=1,3 do centro[i]=ruta.Aros[tostring(i)].Centro.Position end
local dados = Random.new()
local DURACION_ECLOSION = 3.45
local intentos = {}
local elevaciones = {}
local TweenService = game:GetService("TweenService")

local function retirarElevador(p)
	local viaje = elevaciones[p]
	if not viaje then return end
	elevaciones[p] = nil
	viaje.subida:Cancel()
	viaje.transporte:Cancel()
	if viaje.raiz.Parent then viaje.raiz.Anchored = viaje.anclada end
	viaje.plataforma:Destroy()
end
local function fase(p,estado)
	p:SetAttribute("RescateNimbo",estado)
end
local function limpiar(p)
	retirarElevador(p)
	intentos[p]=nil
	p:SetAttribute("ArosNimbo",0)
	p:SetAttribute("MarcasHuevo",0)
	fase(p,nil)
end
local function raiz(p)
	local c=p.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return if h and h.Health>0 then c:FindFirstChild("HumanoidRootPart") else nil, h
end
local function habilitado(p)
	return p:GetAttribute("EnFaro") and p:GetAttribute("ProgresoListo") and p:GetAttribute("FaroEncendido") and p:GetAttribute("Prisma")
end
local function cerca(p,pos)
	local r=raiz(p)
	return r and habilitado(p) and (r.Position-pos).Magnitude<=7
end
local function mover(p,pos)
	local r=raiz(p)
	if r then
		p.Character:PivotTo(CFrame.lookAt(pos,pos+Vector3.xAxis))
		r.AssemblyLinearVelocity=Vector3.zero
	end
end
local function balcon(p)
	limpiar(p)
	fase(p,"Balcon")
	mover(p,salto.Position+Vector3.new(-1,3.1,0))
end
subir.Triggered:Connect(function(p)
	if intentos[p] or elevaciones[p] or not cerca(p,base.Position) then return end
	local r, humanoide = raiz(p)
	if not r then return end
	local plataforma = base:Clone()
	plataforma:ClearAllChildren()
	plataforma.Name = "ElevadorDePrisma"
	plataforma.Color = Color3.fromRGB(165, 165, 255)
	plataforma.Parent = ruta
	local destino = salto.Position + Vector3.new(-1, 0, 0)
	local offset = Vector3.yAxis * (r.Size.Y / 2 + humanoide.HipHeight + .3)
	local origen = CFrame.lookAt(base.Position, base.Position + Vector3.xAxis)
	local llegada = CFrame.lookAt(destino, destino + Vector3.xAxis)
	local tiempo = TweenInfo.new(2.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local anclada = r.Anchored
	r.Anchored = true
	r.CFrame = origen + offset
	local subida = TweenService:Create(plataforma, tiempo, {Position = destino})
	local transporte = TweenService:Create(r, tiempo, {CFrame = llegada + offset})
	local viaje = {raiz = r, anclada = anclada, plataforma = plataforma, subida = subida, transporte = transporte}
	elevaciones[p] = viaje
	fase(p, "Subiendo")
	subida:Play()
	transporte:Play()
	transporte.Completed:Once(function()
		if elevaciones[p] ~= viaje then return end
		if raiz(p) == r and habilitado(p) then balcon(p) else limpiar(p) end
	end)
end)
volver.Triggered:Connect(function(p)
	local estado = p:GetAttribute("RescateNimbo")
	if (estado=="Rescatado" or estado=="Nido") and cerca(p,regreso.WorldPosition) then balcon(p) end
end)
saltar.Triggered:Connect(function(p)
	if p:GetAttribute("RescateNimbo")~="Balcon" or not cerca(p,salto.Position) then return end
	local origen=salto.Position+Vector3.new(3,4,0)
	intentos[p]={avatar=p.Character, anterior=origen, inicio=os.clock(), siguiente=1, aciertos=0, marcas=0}
	mover(p,origen)
	fase(p,"Vuelo")
	remoto:FireClient(p,"VueloNimbo",origen)
end)

remoto.OnServerEvent:Connect(function(p, accion)
	if accion == "PlegarNimbo" and intentos[p] and p:GetAttribute("RescateNimbo") == "Vuelo" then
		fase(p, "Caida")
	end
end)

local function avanzar(p,intento,r,humanoide)
	local actual,anterior=r.Position,intento.anterior
	local edad=os.clock()-intento.inicio
	if actual.Y<16 or edad>8 or (actual-anterior).Magnitude>22 or actual.X>165 or math.abs(actual.Z-87)>20 then
		balcon(p)
		return
	end
	local plegado = p:GetAttribute("RescateNimbo") == "Caida"
	while not plegado and intento.siguiente<=#centro do
		local c=centro[intento.siguiente]
		if actual.X<c.X or actual.X<=anterior.X then break end
		if anterior.X<=c.X then
			local paso=anterior:Lerp(actual,(c.X-anterior.X)/(actual.X-anterior.X))
			if (paso-c).Magnitude<=4.8 then
				intento.aciertos+=1
				intento.marcas=bit32.bor(intento.marcas,2^(intento.siguiente-1))
				p:SetAttribute("ArosNimbo",intento.aciertos)
				p:SetAttribute("MarcasHuevo",intento.marcas)
			end
		end
		intento.siguiente+=1
	end
	intento.anterior=actual
	local sobreNido = ruta.Nido.CFrame:PointToObjectSpace(actual)
	local aterrizo = plegado and math.abs(sobreNido.X) <= ruta.Nido.Size.X/2 and math.abs(sobreNido.Z) <= ruta.Nido.Size.Z/2
		and sobreNido.Y > 0 and sobreNido.Y <= 5 and humanoide.FloorMaterial ~= Enum.Material.Air
	if edad>=.8 and (aterrizo or (not plegado and intento.siguiente==4 and (actual-huevo.Position).Magnitude<=8)) then
		fase(p,"Nido")
		mover(p,huevo.Position+Vector3.new(-3,0,0))
	end
end

abrir.Triggered:Connect(function(p)
	local intento=intentos[p]
	if not intento or p:GetAttribute("RescateNimbo")~="Nido" or not cerca(p,huevo.Position) then return end
	fase(p,"Eclosion")
	local aurora=intento.aciertos==3 and dados:NextInteger(1,5)==1
	p:SetAttribute("UltimaEclosionAurora",nil)
	remoto:FireClient(p,"EclosionNimbo",aurora,workspace:GetServerTimeNow(),DURACION_ECLOSION)
	task.delay(DURACION_ECLOSION,function()
		if intentos[p]~=intento or p.Character~=intento.avatar or p:GetAttribute("RescateNimbo")~="Eclosion"
			or not habilitado(p) or not raiz(p) then return end
		p:SetAttribute("Nimbo",true)
		if aurora then p:SetAttribute("NimboAurora",true) end
		p:SetAttribute("UltimaEclosionAurora",aurora)
		fase(p,"Rescatado")
	end)
end)

local function vigilar(p)
	p.CharacterRemoving:Connect(function() limpiar(p) end)
	p:GetAttributeChangedSignal("EnFaro"):Connect(function()
		if not p:GetAttribute("EnFaro") then limpiar(p) end
	end)
end
Players.PlayerAdded:Connect(vigilar)
for _,p in Players:GetPlayers() do vigilar(p) end
Players.PlayerRemoving:Connect(function(p)
	retirarElevador(p)
	intentos[p] = nil
end)
RunService.Heartbeat:Connect(function()
	for p,intento in intentos do
		local r,humanoide=raiz(p)
		if not r or p.Character~=intento.avatar or not habilitado(p) then
			limpiar(p)
		elseif p:GetAttribute("RescateNimbo")=="Vuelo" or p:GetAttribute("RescateNimbo")=="Caida" then
			avanzar(p,intento,r,humanoide)
		elseif r.Position.Y<16 then
			balcon(p)
		end
	end
end)
