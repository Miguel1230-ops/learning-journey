-- Las cintas recorren el volumen real que levanta al planeador y se abren hacia la cornisa.
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ruta = workspace:WaitForChild("IslaDelViento"):WaitForChild("Rutas")
local zona = ruta:WaitForChild("ZonaAscenso")
local aro = ruta:WaitForChild("ZonaAro")
local salida = ruta:WaitForChild("AlturaSalida")
local baliza = ruta:WaitForChild("Baliza")
local jugador = Players.LocalPlayer
local cielo = Color3.fromRGB(135, 225, 249)
local hojaClara = Color3.fromRGB(216, 240, 151)
local hojaOscura = Color3.fromRGB(119, 199, 157)
local cintas = {}
local hojas = {}

local function anclar(nombre, punto, direccion)
	local a = Instance.new("Attachment")
	a.Name = nombre
	a.Position = zona.CFrame:PointToObjectSpace(punto)
	a.Axis = zona.CFrame:VectorToObjectSpace(direccion)
	a.Parent = zona
	return a
end

local rumbo = (baliza.Position - salida.Position) * Vector3.new(1, 0, 1)
rumbo = if rumbo.Magnitude > 0.1 then rumbo.Unit else zona.CFrame.RightVector
local lateral = rumbo:Cross(Vector3.yAxis)
local altura = math.max(6, salida.Position.Y - ruta:WaitForChild("CorazonCorriente").Position.Y)
local radio = math.min(zona.Size.X, zona.Size.Z) * 0.33
local tramo = (salida.Position - aro.Position) * Vector3.new(1, 0, 1)
local direccionEntrada = tramo.Unit
local lateralEntrada = direccionEntrada:Cross(Vector3.yAxis)
local baseEntrada = aro.Position + Vector3.yAxis * .4
local finalEntrada = salida.Position - Vector3.yAxis * 4
for _, lado in {-1, 1} do
	local curva = Instance.new("Beam")
	curva.Name = "SendaDeLaBrisa"
	curva.Attachment0 = anclar("SalidaDelAro", baseEntrada + lateralEntrada * lado * radio, direccionEntrada)
	curva.Attachment1 = anclar("EntradaALaColumna", finalEntrada + lateralEntrada * lado * radio, Vector3.yAxis)
	curva.CurveSize0, curva.CurveSize1 = tramo.Magnitude * .45, 4
	curva.Width0, curva.Width1 = .2, .38
	curva.Segments, curva.FaceCamera, curva.LightEmission = 14, true, .8
	curva.Color = ColorSequence.new(cielo, hojaClara)
	curva.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.1, .4),
		NumberSequenceKeypoint.new(.82, .43), NumberSequenceKeypoint.new(1, 1),
	})
	curva.Parent = zona
	table.insert(cintas, curva)
end
for i = 1, 3 do
	local angulo = (i - 1) * math.pi * 2 / 3
	local radial = lateral * math.cos(angulo) + rumbo * math.sin(angulo)
	local desde = salida.Position + radial * radio - Vector3.yAxis * altura
	local hasta = salida.Position + rumbo * (radio + 1) + lateral * math.cos(angulo) * radio * 0.72
	local curva = Instance.new("Beam")
	curva.Name = "CintaDeLaCorriente"
	curva.Attachment0 = anclar("BaseDeLaCinta", desde, Vector3.yAxis)
	curva.Attachment1 = anclar("SalidaDeLaCinta", hasta, rumbo)
	curva.CurveSize0 = altura * 0.8
	curva.CurveSize1 = altura * 0.36
	curva.Width0, curva.Width1 = 0.13, 0.38
	curva.Segments, curva.FaceCamera = 14, true
	curva.LightEmission = 0.65
	curva.Color = ColorSequence.new(cielo, hojaClara)
	curva.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.17, 0.72),
		NumberSequenceKeypoint.new(0.82, 0.60), NumberSequenceKeypoint.new(1, 1),
	})
	curva.Parent = zona
	table.insert(cintas, curva)
end

local function activar()
	local visible = jugador:GetAttribute("Cometa") == true
	for _, cinta in cintas do cinta.Enabled = visible end
	for _, hoja in hojas do hoja.Transparency = if visible then 0.08 else 1 end
end
local hojasColumna = 9
for i = 1, hojasColumna + 5 do
	local hoja = Instance.new("WedgePart")
	hoja.Name = "HojaDeLaCorriente"
	hoja.Size = Vector3.new(0.31, 0.09, if i % 2 == 0 then 0.73 else 0.58)
	hoja.Color = if i % 3 == 0 then hojaClara else hojaOscura
	hoja.Material = Enum.Material.SmoothPlastic
	hoja.Anchored, hoja.CastShadow = true, false
	hoja.CanCollide, hoja.CanTouch, hoja.CanQuery = false, false, false
	hoja.Position = salida.Position
	hoja.Parent = zona
	hojas[i] = hoja
end
activar()
jugador:GetAttributeChangedSignal("Cometa"):Connect(activar)

local acumulado = 0
RunService.Heartbeat:Connect(function(dt)
	if not cintas[1].Enabled then return end
	acumulado += dt
	if acumulado < 1 / 24 then return end
	acumulado = 0
	local camara = workspace.CurrentCamera
	if not camara or (camara.CFrame.Position - zona.Position).Magnitude > 140 then return end
	local t = if GuiService.ReducedMotionEnabled then 0 else workspace:GetServerTimeNow()
	for i, hoja in hojas do
		if i > hojasColumna then
			local u = ((i - hojasColumna) / 5 + t * .47) % 1
			local ondula = math.sin(i * 1.8 + u * 5)
			local pos = baseEntrada:Lerp(finalEntrada, u)
				+ lateralEntrada * ondula * radio * .72 + Vector3.yAxis * math.sin(u * math.pi) * .48
			hoja.CFrame = CFrame.lookAt(pos, pos + direccionEntrada + Vector3.yAxis * .45)
				* CFrame.Angles(0, 0, ondula * .62)
			hoja.Transparency = 1 - math.min(1, u * 9, (1 - u) * 9) * .95
			continue
		end
		local u = (i / hojasColumna + t * 0.45) % 1
		local angulo = i * 2.4 + u * 3.8
		local giro = lateral * math.cos(angulo) + rumbo * math.sin(angulo)
		local apertura = math.clamp((u - 0.68) / 0.32, 0, 1)
		local centro = salida.Position - Vector3.yAxis * altura * (1 - u)
		local pos = centro + giro * radio * (1 - apertura * 0.75) + rumbo * apertura ^ 2 * (radio + 2)
		hoja.CFrame = CFrame.lookAt(pos, pos + giro * 0.4 + Vector3.yAxis * (1 - apertura) + rumbo * apertura)
			* CFrame.Angles(0.3, 0, angulo)
		hoja.Transparency = 1 - math.min(1, u * 12, (1 - u) * 9) * 0.95
	end
end)
