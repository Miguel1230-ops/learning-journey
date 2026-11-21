local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GuiService = game:GetService("GuiService")
local FormacionEcos = require(ReplicatedStorage:WaitForChild("FormacionEcos"))
local Eclosion = require(ReplicatedStorage:WaitForChild("EclosionNimbo"))
local usuario = Players.LocalPlayer
local faro = workspace:WaitForChild("IslaDelViento"):WaitForChild("RuinasDelFaro")
local ruta = faro:WaitForChild("RescateNimbo")
local modelos = ReplicatedStorage:WaitForChild("EcosDelFaro")
local remoto = ReplicatedStorage:WaitForChild("AccionFaro")
local huevo = ruta:WaitForChild("Huevo")
local menta,violeta = Color3.fromRGB(101,255,196),Color3.fromRGB(186,129,255)
local eclosion = Eclosion.new(ruta, modelos)

local salida=Instance.new("Attachment")
salida.Parent=faro.Linterna
local haces={}
local arcos={}
for i=1,3 do
	local aro=ruta.Aros[tostring(i)]
	local fin=Instance.new("Attachment")
	fin.Parent=aro.Centro
	local haz=Instance.new("Beam")
	haz.Attachment0,haz.Attachment1=salida,fin
	haz.Width0,haz.Width1,haz.FaceCamera=.34,.12,true
	haz.Color=ColorSequence.new(({menta,Color3.fromRGB(255,203,126),violeta})[i])
	haz.LightEmission,haz.Transparency,haz.Enabled=1,NumberSequence.new(.4),false
	haz.Parent=salida
	haces[i]=haz
	arcos[i] = {}
	for _,p in aro:GetChildren() do
		if p.Name=="Arco" then table.insert(arcos[i],p) end
	end
end
local subir=ruta.Ascensor:WaitForChild("Subir")
local saltar=ruta.Despegue:WaitForChild("Saltar")
local abrir=huevo:WaitForChild("Abrir")
local volver=ruta.Nido.Salida:WaitForChild("Volver")
local revelados = 0
local turnoSubida = 0
local function actualizar()
	local fase=usuario:GetAttribute("RescateNimbo")
	local visible=usuario:GetAttribute("EnFaro")==true and usuario:GetAttribute("Prisma")==true and usuario:GetAttribute("FaroEncendido")==true
	if not visible then revelados = 0 end
	for i, piezas in arcos do
		local mostrar = visible and i <= revelados
		for _, pieza in piezas do pieza.LocalTransparencyModifier = if mostrar then 0 else 1 end
		haces[i].Enabled = mostrar
	end
	subir.Enabled=visible and (fase==nil or fase=="Balcon")
	saltar.Enabled=visible and fase=="Balcon"
	abrir.Enabled=visible and fase=="Nido"
	volver.Enabled=visible and (fase=="Rescatado" or fase=="Nido")
	eclosion:estado(fase,usuario:GetAttribute("MarcasHuevo"),visible)
end
usuario:GetAttributeChangedSignal("RescateNimbo"):Connect(function()
	local fase = usuario:GetAttribute("RescateNimbo")
	turnoSubida += 1
	if fase == "Subiendo" then
		revelados = 0
		local turno = turnoSubida
		for i = 1, 3 do
			task.delay(i * .47, function()
				if turnoSubida == turno then revelados = i actualizar() end
			end)
		end
		if not GuiService.ReducedMotionEnabled then
			local cam = workspace.CurrentCamera
			local base = ruta.Ascensor.Position
			if cam and cam.CameraType == Enum.CameraType.Custom then
				cam.CFrame = CFrame.lookAt(base + Vector3.new(-3, 7, 11), base + Vector3.new(16, 8, -2))
			end
		end
	elseif fase == "Balcon" then
		revelados = 3
	end
	actualizar()
	if fase ~= "Balcon" or GuiService.ReducedMotionEnabled then return end
	local cam=workspace.CurrentCamera
	if cam and cam.CameraType==Enum.CameraType.Custom then
		local origen=ruta.Despegue.Position
		cam.CFrame=CFrame.lookAt(origen+Vector3.new(-9,7,0),origen+Vector3.new(20,2,0))
	end
end)
for _,a in {"MarcasHuevo","EnFaro","Prisma","FaroEncendido"} do
	usuario:GetAttributeChangedSignal(a):Connect(actualizar)
end
actualizar()
remoto.OnClientEvent:Connect(function(evento,aurora,inicio,duracion)
	if evento=="EclosionNimbo" then
		eclosion:iniciar(usuario,aurora,inicio,duracion)
	end
end)

local plantillaPedernal = ReplicatedStorage:WaitForChild("PedernalCompanero")
local equipos = {}

local function retirar(equipo, nombre)
	local eco = equipo[nombre]
	if eco then
		eco.modelo:Destroy()
		equipo[nombre] = nil
	end
end

local function companero(equipo, p, nombre, plantilla)
	local anterior = equipo[nombre]
	if anterior and anterior.plantilla == plantilla then return end
	retirar(equipo,nombre)
	if not plantilla then return end
	local m = plantilla:Clone()
	m.Name = if nombre=="Pedernal" then "PedernalExplorador" else plantilla.Name
	m:SetAttribute("DuenoEco",p.UserId)
	local eco = {modelo=m, plantilla=plantilla}
	if nombre=="Nimbo" then
		eco.alas = {m.AlaIzquierda,m.AlaDerecha}
		local base=m:GetPivot()
		eco.ejes={base:ToObjectSpace(eco.alas[1]:GetPivot()),base:ToObjectSpace(eco.alas[2]:GetPivot())}
	end
	equipo[nombre] = eco
end

local function observar(p)
	if equipos[p] then return end
	local equipo = {conexiones={}}
	equipos[p]=equipo
	local function sincronizar()
		local raiz = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		equipo.raiz=raiz
		local variante=if p:GetAttribute("NimboAurora") then modelos.NimboAurora else modelos.Nimbo
		companero(equipo,p,"Nimbo",if raiz and p:GetAttribute("Nimbo") then variante else nil)
		-- En la cueva el actor del guardián asume la revelación y las órdenes de Pedernal.
		companero(equipo,p,"Pedernal",if raiz and p:GetAttribute("Pedernal") and not p:GetAttribute("EnCueva")
			then plantillaPedernal else nil)
	end
	local function personaje(c)
		if c:WaitForChild("HumanoidRootPart",10) and p.Character==c and equipos[p]==equipo then sincronizar() end
	end
	for _, atributo in {"Nimbo","NimboAurora","Pedernal","EnCueva"} do
		table.insert(equipo.conexiones,p:GetAttributeChangedSignal(atributo):Connect(sincronizar))
	end
	table.insert(equipo.conexiones,p.CharacterAdded:Connect(personaje))
	table.insert(equipo.conexiones,p.CharacterRemoving:Connect(function()
		equipo.raiz=nil
		retirar(equipo,"Nimbo")
		retirar(equipo,"Pedernal")
	end))
	if p.Character then task.spawn(personaje,p.Character) end
end

local function quitar(p)
	local equipo = equipos[p]
	if not equipo then return end
	for _, conexion in equipo.conexiones do conexion:Disconnect() end
	retirar(equipo,"Nimbo")
	retirar(equipo,"Pedernal")
	equipos[p]=nil
end
Players.PlayerAdded:Connect(observar)
Players.PlayerRemoving:Connect(quitar)
for _,p in Players:GetPlayers() do observar(p) end

local function seguir(eco,nombre,raiz,t,dt,visible)
	if not eco then return end
	if not visible then
		if eco.modelo.Parent then eco.modelo.Parent=nil end
		return
	end
	local actual = if eco.modelo.Parent then eco.modelo:GetPivot() else nil
	local pose = FormacionEcos.pose(nombre,raiz.CFrame,t,actual,1-math.exp(-dt*6))
	eco.modelo:PivotTo(pose)
	if eco.alas then
		for i,ala in eco.alas do
			ala:PivotTo(pose*eco.ejes[i]*CFrame.Angles(0,0,(if i==1 then -1 else 1)*math.sin(t*8)*.30))
		end
	end
	if not eco.modelo.Parent then eco.modelo.Parent=workspace end
end

RunService.PreRender:Connect(function(dt)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local t=workspace:GetServerTimeNow()
	for p,equipo in equipos do
		local raiz = equipo.raiz
		if not raiz or not raiz.Parent then continue end
		local cerca = (cam.CFrame.Position-raiz.Position).Magnitude<190
		seguir(equipo.Nimbo,"Nimbo",raiz,t,dt,cerca and (p~=usuario or not eclosion.escena))
		seguir(equipo.Pedernal,"Pedernal",raiz,t,dt,cerca)
	end
end)
