-- Cada jugador abre su propio huevo. El servidor decide y guarda el resultado.
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")

local Eclosion = {}
Eclosion.__index = Eclosion

local dorado = Color3.fromRGB(255, 193, 108)
local menta = Color3.fromRGB(112, 246, 208)
local violeta = Color3.fromRGB(189, 141, 255)
local apagado = Color3.fromRGB(95, 100, 117)
local angulo = math.rad

local function tramo(t, desde, hasta)
	local n = math.clamp((t - desde)/(hasta - desde),0,1)
	return n*n*(3-2*n)
end

function Eclosion.new(ruta, modelos)
	local self = setmetatable({}, Eclosion)
	self.huevo = ruta:WaitForChild("Huevo")
	self.cascara = ruta:WaitForChild("Cascaron")
	self.modelos = modelos
	self.placas, self.bisagras, self.marcas = {}, {}, {}
	for i=1,3 do
		local placa = self.cascara:WaitForChild("Placa"..i)
		self.placas[i], self.bisagras[i] = placa, placa:GetPivot()
		local marca = self.cascara:WaitForChild("Cuenco"):WaitForChild("Marca"..i)
		self.marcas[i] = {pieza=marca, color=marca.Color}
	end
	self.piezas = {}
	for _, pieza in self.cascara:GetDescendants() do
		if pieza:IsA("BasePart") then table.insert(self.piezas,pieza) end
	end
	self.luz = Instance.new("PointLight")
	self.luz.Color, self.luz.Range, self.luz.Brightness = dorado, 9, .52
	self.luz.Parent = self.huevo
	self.briznas = Instance.new("ParticleEmitter")
	self.briznas.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	self.briznas.Rate, self.briznas.LightEmission = 0, .82
	self.briznas.Speed, self.briznas.Lifetime = NumberRange.new(1.5,4), NumberRange.new(.35,.7)
	self.briznas.SpreadAngle, self.briznas.Size = Vector2.new(130,130), NumberSequence.new(.22,0)
	self.briznas.Parent = self.huevo
	self.toque = Instance.new("Sound")
	self.toque.SoundId, self.toque.Volume = "rbxasset://sounds/action_jump_land.mp3", .23
	self.toque.RollOffMaxDistance, self.toque.Parent = 28, self.huevo
	return self
end

function Eclosion:mostrarCascaron(visible)
	if self.visible == visible then return end
	self.visible = visible
	for _, pieza in self.piezas do
		pieza.LocalTransparencyModifier = if visible then 0 else 1
	end
	self.luz.Enabled = visible
end

function Eclosion:estado(fase, marcas, enFaro)
	for i, marca in self.marcas do
		local encendida = bit32.btest(marcas or 0, 2^(i-1))
		marca.pieza.Color = if encendida then marca.color else apagado
		marca.pieza.Material = if encendida then Enum.Material.Neon else Enum.Material.Metal
	end
	if self.escena and (not enFaro or fase == nil or fase=="Balcon" or fase=="Subiendo") then
		self:terminar()
	end
	if not self.escena then self:mostrarCascaron(fase~="Rescatado") end
end

function Eclosion:terminar()
	local toma = self.escena
	if not toma then return end
	self.escena = nil
	toma.cuadro:Disconnect()
	toma.cria:Destroy()
	self.briznas:Clear()
	self.toque:Stop()
	for i,placa in self.placas do placa:PivotTo(self.bisagras[i]) end
	self.luz.Color, self.luz.Brightness = dorado, .52
	local cam = toma.camara
	if cam and workspace.CurrentCamera == cam and cam.CameraType == Enum.CameraType.Scriptable then
		cam.CFrame, cam.Focus = toma.marco, toma.foco
		cam.FieldOfView, cam.CameraType = toma.fov, toma.tipo
	end
end

function Eclosion:iniciar(p, aurora, inicio, duracion)
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if not root or not p:GetAttribute("EnFaro") or workspace:GetServerTimeNow()-inicio>=duracion then return end
	self:terminar()
	self:mostrarCascaron(true)
	local quieto = GuiService.ReducedMotionEnabled
	local cam = if quieto then nil else workspace.CurrentCamera
	local cria = self.modelos[if aurora then "NimboAurora" else "Nimbo"]:Clone()
	local alas = {cria.AlaIzquierda,cria.AlaDerecha}
	local ejeAlas = {cria:GetPivot():ToObjectSpace(alas[1]:GetPivot()),cria:GetPivot():ToObjectSpace(alas[2]:GetPivot())}
	local toma = {
		cria=cria, camara=cam, marco=cam and cam.CFrame, fov=cam and cam.FieldOfView,
		foco=cam and cam.Focus, tipo=cam and cam.CameraType,
	}
	self.escena = toma
	if cam then cam.CameraType=Enum.CameraType.Scriptable end
	local centro = self.huevo.Position
	local lateral = (root.Position-centro) * Vector3.new(1,0,1)
	local frente = if lateral.Magnitude>.01 then lateral.Unit else -Vector3.xAxis
	local derecha = frente:Cross(Vector3.yAxis)
	local golpe, eclosiono, ultimoTam = 0, false, 0
	self.briznas.Color = if aurora then ColorSequence.new(menta,violeta) else ColorSequence.new(dorado)
	toma.cuadro = RunService.PreRender:Connect(function()
		local edad = workspace:GetServerTimeNow()-inicio
		local humanoide = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
		if edad>=duracion or not humanoide or humanoide.Health<=0 or not p:GetAttribute("EnFaro")
			or (cam and workspace.CurrentCamera~=cam) then
			self:terminar()
			self:mostrarCascaron(p:GetAttribute("RescateNimbo")~="Rescatado" and edad<duracion)
			return
		end
		local t = math.clamp(edad/duracion,0,1)
		if golpe<2 and t>=(if golpe==0 then .10 else .25) then
			golpe+=1
			self.toque.PlaybackSpeed = if golpe==1 then 1.6 else 1.94
			self.toque.TimePosition=0
			self.toque:Play()
		end
		local apertura = if quieto then (if t<.34 then 0 else 1) else tramo(t,.28,.66)
		local vibracion = if quieto then 0 else math.sin(t*88) * (1-tramo(t,.25,.42)) * tramo(t,.05,.12)
		for i, placa in self.placas do
			placa:PivotTo(self.bisagras[i] * CFrame.new(0,-.48*apertura,-.28*apertura)
				* CFrame.Angles(angulo(-87*apertura+2.8*vibracion),0,0))
		end
		if t>=.33 and not eclosiono then
			eclosiono = true
			if not quieto then self.briznas:Emit(if aurora then 22 else 12) end
		end
		local color = if aurora then menta:Lerp(violeta, tramo(t,.34,.64)) else dorado
		self.luz.Color = color
		self.luz.Brightness = .55 + (if quieto then .6 else 1.7) * apertura
		local salto = tramo(t,.31,.69)
		local final = tramo(t,.82,1)
		if eclosiono then
			local tam = if quieto then .81 else .43+.40*salto+.17*final
			if math.abs(tam-ultimoTam)>.012 then cria:ScaleTo(tam) ultimoTam=tam end
			local llegada = centro + frente*.75 + Vector3.yAxis*.84
			local pos = centro:Lerp(llegada,salto) + Vector3.yAxis *
				(if quieto then .5 else -.72*(1-salto)+math.sin(salto*math.pi)*1.65)
			-- La cola de Aurora asoma primero. El pico levanta la tapa antes de abrir las alas.
			local eje = CFrame.lookAt(pos,pos+frente) * CFrame.Angles(angulo(if quieto then 0 else -40*(1-salto)),0,0)
			if not quieto then
				local destino = root.CFrame * CFrame.new(-2.1,4.6,7.8)
				eje = eje:Lerp(destino,final)
			end
			cria:PivotTo(eje)
			local despliegue = if quieto then 1 else tramo(t,.49,.78)
			for i,ala in alas do
				local offset = ejeAlas[i]
				local batir = if quieto then 0 else math.sin(final*math.pi*2)*12
				local giro = (if i==1 then -1 else 1)*(63*(1-despliegue)+batir)
				ala:PivotTo(eje * (CFrame.new(offset.Position*ultimoTam)*offset.Rotation) * CFrame.Angles(0,0,angulo(giro)))
			end
			if not cria.Parent then cria.Parent = workspace end
		end
		if cam then
			local foco = centro + Vector3.yAxis*(.20+.75*salto)
			local ojo = centro + frente*7.55 + derecha*4.75 + Vector3.yAxis*(2.50+.5*salto)
			cam.CFrame, cam.Focus = CFrame.lookAt(ojo,foco), CFrame.new(foco)
			cam.FieldOfView=49+4*salto
		end
	end)
end

return Eclosion
