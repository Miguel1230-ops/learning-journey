-- Poses del modelo de piedra y efectos dirigidos. El servidor decide los impactos.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Visual = {}
Visual.__index = Visual

local ORO = Color3.fromRGB(255, 191, 99)
local VIOLETA = Color3.fromRGB(202, 149, 255)
local MENTA = Color3.fromRGB(128, 251, 223)
local HIELO = Color3.fromRGB(225, 255, 250)
local ARCILLA = Color3.fromRGB(92, 84, 107)
local rad = math.rad
local brazos = { Hombro = true, Brazo = true, ["Puño"] = true, ["Veta del hombro"] = true }
local cabeza = { Cabeza = true, Cejas = true, ["Mandíbula"] = true, Ojo = true }

local function segmento(a, b)
	return CFrame.lookAt((a + b) / 2, b)
end

function Visual.new(guardian, efectos, parte)
	local self = setmetatable({ guardian = guardian, efectos = efectos, parte = parte, juntas = {} }, Visual)
	local base = guardian:GetPivot()
	for _, pieza in guardian:GetChildren() do
		local esPuno = string.sub(pieza.Name, 1, 2) == "Pu"
		local esBrazo = brazos[pieza.Name] or esPuno
		local esCabeza = cabeza[pieza.Name] or string.sub(pieza.Name, 1, 4) == "Mand"
		if pieza:IsA("BasePart") and (esBrazo or esCabeza) then
			local reposo = base:ToObjectSpace(pieza.CFrame)
			local lado = math.sign(reposo.X)
			local pivote = if esBrazo then Vector3.new(lado * 3.15, 1.2, 0) else Vector3.new(0, 1.95, -0.2)
			local centro = CFrame.new(pivote)
			table.insert(self.juntas, {pieza = pieza, centro = centro, offset = centro:Inverse() * reposo, lado = lado,
				brazo = esBrazo, ojo = pieza.Name == "Ojo" and pieza.Color or nil})
			if esPuno and lado > 0 then
				self.puno = pieza
			end
		end
	end
	local columna = Instance.new("Model")
	columna.Name = "ColumnaAgrietada"
	columna.Parent = efectos
	self.centroColumna = Vector3.new(305, 20.08, 12.5)
	local pie = CFrame.new(self.centroColumna) * CFrame.Angles(0, rad(14), 0)
	for i, nivel in ipairs({
		{Vector3.new(4.2, 1.1, 3.8), CFrame.new(0, 0.55, 0)},
		{Vector3.new(2.9, 5.7, 2.65), CFrame.new(0, 3.85, 0)},
		{Vector3.new(3.3, 1.05, 2.95), CFrame.new(-0.23, 7.1, 0) * CFrame.Angles(0, 0, rad(7))},
	}) do
		local roca = parte(columna, "Estrato" .. i, nivel[1], pie * nivel[2], ARCILLA)
		roca.Material = Enum.Material.Slate
	end
	for _, cara in {-1, 1} do
		local puntos = {Vector3.new(-0.72, 6.7, cara * 1.34), Vector3.new(0.33, 4.9, cara * 1.34),
			Vector3.new(-0.56, 3.8, cara * 1.34), Vector3.new(0.35, 1.08, cara * 1.34)}
		for i = 2, #puntos do
			local anterior, punto = puntos[i - 1], puntos[i]
			local a, b = pie * anterior, pie * punto
			parte(columna, "Grieta", Vector3.new(0.17, 0.14, (b-a).Magnitude), segmento(a,b), ORO)
			a = pie * Vector3.new(cara * 1.46, anterior.Y, anterior.X)
			b = pie * Vector3.new(cara * 1.46, punto.Y, punto.X)
			parte(columna, "Grieta", Vector3.new(0.17, 0.14, (b-a).Magnitude), segmento(a,b), ORO)
		end
	end
	self.columna = columna
	self.filo = parte(efectos, "FiloDelBarrido", Vector3.one, CFrame.new(), VIOLETA)
	self.filo.Transparency = 1
	local rastroA = Instance.new("Attachment")
	local rastroB = Instance.new("Attachment")
	rastroA.Parent = self.filo
	rastroB.Parent = self.filo
	local rastro = Instance.new("Trail")
	rastro.Attachment0, rastro.Attachment1 = rastroA, rastroB
	rastro.Color = ColorSequence.new(VIOLETA, Color3.fromRGB(117, 91, 230))
	rastro.Transparency = NumberSequence.new(0.35, 1)
	rastro.Lifetime = 0.22
	rastro.LightEmission = 0.9
	rastro.Enabled = false
	rastro.Parent = self.filo
	self.rastro, self.rastroA, self.rastroB = rastro, rastroA, rastroB
	return self
end

function Visual:esquirlas(punto, color)
	for i = 1, 7 do
		local angulo = i * math.pi * 2 / 7
		local salida = Vector3.new(math.cos(angulo), 0.65 + (i % 3) * 0.24, math.sin(angulo)).Unit
		local inicio = punto + salida * 0.38
		local final = inicio + salida * (2.2 + i % 3)
		local p = self.parte(self.efectos, "Esquirla", Vector3.new(0.22, 0.33, 0.82),
			CFrame.lookAt(inicio, final), color)
		TweenService:Create(p, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = p.CFrame + (final - inicio), Transparency = 1}):Play()
		Debris:AddItem(p, 0.42)
	end
end

function Visual:mostrarColumna(visible)
	for _, pieza in self.columna:GetChildren() do
		pieza.Transparency = if visible then 0 else 1
		if pieza.Material == Enum.Material.Slate then
			pieza.CanCollide = visible
			pieza.CanQuery = visible
		end
	end
	if not visible then
		self:esquirlas(self.centroColumna + Vector3.yAxis * 4, ORO)
	end
end

function Visual:rafaga(origen, destino)
	local distancia = (destino - origen).Magnitude
	if distancia < 0.15 then return end
	local marco = CFrame.lookAt(origen, destino)
	for i = -1, 1 do
		local inicio = origen + marco.RightVector * i * 0.65
		local fin = destino + marco.RightVector * i * 0.13
		local flecha = self.parte(self.efectos, "LanzaDeViento", Vector3.new(0.22, 0.38, math.min(3.5, distancia * 0.55)),
			CFrame.lookAt(inicio, fin), if i == 0 then HIELO else MENTA)
		TweenService:Create(flecha, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{CFrame = CFrame.lookAt(fin, fin + marco.LookVector), Transparency = 1}):Play()
		Debris:AddItem(flecha, 0.21)
	end
end

-- El mismo arco horizontal se usa para buscar impactos y dibujar la hoja.
Visual.inicioBarrido = 79
Visual.recorridoBarrido = 177
function Visual.direccionBarrido(base, progreso)
	local angulo = rad(Visual.inicioBarrido - Visual.recorridoBarrido * math.clamp(progreso, 0, 1))
	return base.LookVector * math.cos(angulo) + base.RightVector * math.sin(angulo)
end

function Visual:pose(estado, progreso)
	local base = self.guardian:GetPivot()
	local elevacion, torsion, mirada, inclinacion = 0, 0, 0, 0
	local despertar = 0
	if estado == "Presentacion" then
		despertar = math.clamp((progreso - 0.06) / 0.40, 0, 1)
		local levanta = math.clamp(progreso / 0.52, 0, 1)
		local planta = math.clamp((progreso - 0.55) / 0.13, 0, 1)
		elevacion, inclinacion = 80 * levanta * (1 - planta), (1 - progreso) * 25
	elseif estado == "Aviso" or estado == "Embestida" then
		elevacion, inclinacion = -26 * progreso, 24 * progreso
	elseif estado == "PrepararBarrido" then
		elevacion, torsion, mirada = 39 * progreso, -72 * progreso, -20 * progreso
	elseif estado == "Barrido" then
		elevacion, torsion, mirada = 39, -72 + 145 * progreso, -20 + 48 * progreso
	elseif estado == "Expuesto" or estado == "SigueACometa" then
		inclinacion, elevacion = 25, -17
	end
	for _, j in self.juntas do
		local rotacion
		if j.brazo then
			if estado == "Presentacion" and j.lado < 0 then
				rotacion = CFrame.Angles(rad(elevacion * 0.25), 0, rad(-11 * elevacion / 80))
			elseif (estado == "PrepararBarrido" or estado == "Barrido") and j.lado < 0 then
				rotacion = CFrame.Angles(rad(-15), 0, rad(-8))
			else
				rotacion = CFrame.Angles(0, rad(torsion), 0) * CFrame.Angles(rad(elevacion), 0, rad(j.lado * elevacion * 0.58))
			end
		else
			rotacion = CFrame.Angles(rad(inclinacion), rad(mirada), 0)
		end
		j.pieza.CFrame = base * j.centro * rotacion * j.offset
		if j.ojo then
			j.pieza.Color = if estado == "Presentacion" then Color3.fromRGB(49, 39, 41):Lerp(j.ojo, despertar) else j.ojo
		end
	end
	local preparando, barriendo = estado == "PrepararBarrido", estado == "Barrido"
	if preparando or barriendo then
		local direccion = Visual.direccionBarrido(base, if preparando then 0 else progreso)
		local punta = base.Position + direccion * (if preparando then 4.7 + 5.8 * progreso else 10.5) - Vector3.yAxis * 2.1
		local origen = self.puno.Position
		local largo = math.max((punta - origen).Magnitude, 0.1)
		self.filo.Size = Vector3.new(0.58, 0.48, largo)
		self.filo.CFrame = segmento(origen, punta)
		self.filo.Transparency = if preparando then 0.50 - progreso * 0.28 else 0.04
		self.rastroA.Position, self.rastroB.Position = Vector3.new(0,0,largo/2), Vector3.new(0,0,-largo/2)
		self.rastro.Enabled = barriendo
	else
		self.filo.Transparency = 1
		self.rastro.Enabled = false
	end
end

return Visual
