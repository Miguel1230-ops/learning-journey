local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local jugador = Players.LocalPlayer
local cueva = workspace:WaitForChild("CuevaDeLaGeoda")
local geoda = cueva:WaitForChild("Geoda")
local ruta = cueva:WaitForChild("Ruta")
local remoto = ReplicatedStorage:WaitForChild("AccionGeoda")
local centro = geoda:WaitForChild("Centro").Position
local brillo = Color3.fromRGB(255, 211, 128)
local blanco = Color3.fromRGB(247, 248, 242)
local hielo = Color3.fromRGB(148, 218, 255)
local noche = Color3.fromRGB(14, 24, 36)
local escena

local function crear(clase, padre, props)
	local objeto = Instance.new(clase)
	for nombre, valor in pairs(props) do
		objeto[nombre] = valor
	end
	objeto.Parent = padre
	return objeto
end

local gui = crear("ScreenGui", jugador:WaitForChild("PlayerGui"), {
	Name = "GeodaPresentacionHUD",
	ResetOnSpawn = false,
	DisplayOrder = 19,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	Enabled = false,
})

local sombra = crear("Frame", gui, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0.36),
	BackgroundColor3 = noche,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})
crear("UIGradient", sombra, {
	Rotation = 90,
	Transparency = NumberSequence.new(1, 0.1),
})

local tarjeta = crear("CanvasGroup", gui, {
	Name = "Descubrimiento",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.new(0.9, 0, 0, 93),
	BackgroundColor3 = noche,
	BackgroundTransparency = 0.04,
	GroupTransparency = 1,
})
crear("UICorner", tarjeta, { CornerRadius = UDim.new(0, 15) })
crear("UISizeConstraint", tarjeta, { MaxSize = Vector2.new(422, 93) })
local borde = crear("UIStroke", tarjeta, { Color = brillo, Transparency = 0.48 })
crear("UIGradient", tarjeta, {
	Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(202, 211, 227)),
	Rotation = 8,
})

local medalla = crear("Frame", tarjeta, {
	Position = UDim2.fromOffset(19, 31),
	Size = UDim2.fromOffset(29, 29),
	BackgroundColor3 = brillo,
	BackgroundTransparency = 0.84,
	Rotation = 45,
	BorderSizePixel = 0,
})
crear("UICorner", medalla, { CornerRadius = UDim.new(0, 5) })
local lineaMedalla = crear("UIStroke", medalla, { Thickness = 1.3, Color = brillo, Transparency = 0.18 })
crear("Frame", medalla, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 10),
	BackgroundColor3 = blanco,
	BackgroundTransparency = 0.13,
	BorderSizePixel = 0,
})

local function texto(nombre, y, tamano, fuente)
	return crear("TextLabel", tarjeta, {
		Name = nombre,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(65, y),
		Size = UDim2.new(1, -78, 0, tamano + 5),
		Font = fuente,
		TextSize = tamano,
		TextColor3 = blanco,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

local categoria = texto("Categoria", 11, 11, Enum.Font.GothamBold)
local nombre = texto("Nombre", 28, 27, Enum.Font.GothamBold)
local descripcion = texto("Habilidad", 63, 13, Enum.Font.GothamMedium)
descripcion.TextColor3 = Color3.fromRGB(191, 210, 224)

local saltar = crear("TextButton", gui, {
	Name = "Saltar",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 12),
	Size = UDim2.fromOffset(76, 44),
	BackgroundColor3 = noche,
	BackgroundTransparency = 0.19,
	Text = "Saltar",
	TextColor3 = blanco,
	TextSize = 14,
	Font = Enum.Font.GothamMedium,
})
crear("UICorner", saltar, { CornerRadius = UDim.new(0, 11) })
crear("UIStroke", saltar, { Color = blanco, Transparency = 0.75 })

local arte = crear("Folder", workspace, { Name = "EfectosLocalesGeoda" })

local function destello(padre, tono, tamano, forma)
	return crear("Part", padre, {
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Shape = forma or Enum.PartType.Block,
		Color = tono,
		Size = tamano,
		Transparency = 1,
	})
end

local function terminar()
	if not escena then
		return
	end
	local anterior = escena
	escena = nil
	ContextActionService:UnbindAction("SaltarGeoda")
	anterior.avance:Disconnect()
	local camara = anterior.camara
	if camara and workspace.CurrentCamera == camara then
		camara.FieldOfView = anterior.fov
		camara.CFrame = anterior.marco
		camara.Focus = anterior.foco
		camara.CameraType = anterior.tipo
	end
	anterior.arte:Destroy()
	gui.Enabled = false
	jugador:SetAttribute("GeodaPresentando", false)
end

local function saltarEscena()
	if escena and escena.guardian then
		remoto:FireServer("OmitirIntroGuardian")
	end
	terminar()
end

local function abrirEscena(efectos, tono)
	local camara = if GuiService.ReducedMotionEnabled then nil else workspace.CurrentCamera
	local corte = {
		arte = efectos,
		camara = camara,
		fov = camara and camara.FieldOfView,
		marco = camara and camara.CFrame,
		foco = camara and camara.Focus,
		tipo = camara and camara.CameraType,
	}
	escena = corte
	jugador:SetAttribute("GeodaPresentando", true)
	gui.Enabled = true
	sombra.BackgroundTransparency = 1
	tarjeta.GroupTransparency = 1
	categoria.TextColor3 = tono
	borde.Color = tono
	medalla.BackgroundColor3 = tono
	lineaMedalla.Color = tono
	if camara then
		camara.CameraType = Enum.CameraType.Scriptable
	end
	ContextActionService:BindAction("SaltarGeoda", function(_, estado)
		if estado == Enum.UserInputState.Begin then
			saltarEscena()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Return, Enum.KeyCode.ButtonB)
	return corte
end

local function presentarGuardian(guardian, inicio, duracion)
	if guardian ~= cueva:FindFirstChild("Guardian") or not guardian or not guardian.PrimaryPart
		or not jugador:GetAttribute("EnCueva") or workspace:GetServerTimeNow() - inicio >= duracion then
		return
	end
	local cabeza = guardian:FindFirstChild("Cabeza")
	local cristal = guardian:FindFirstChild("CristalEspalda")
	if not cabeza or not cristal then return end
	terminar()
	local efectos = crear("Folder", arte, { Name = "DespertarGuardian" })
	local corte = abrirEscena(efectos, brillo)
	corte.guardian = true
	categoria.Text = "CUEVA DE LA GEODA"
	nombre.Text = "El Guardián"
	descripcion.Text = "Algo respira entre las rocas."
	local base = guardian.PrimaryPart.Position
	local hacia = guardian.PrimaryPart.CFrame.LookVector
	local frente = Vector3.new(hacia.X, 0, hacia.Z).Unit
	local lado = frente:Cross(Vector3.yAxis)
	local ancla = destello(efectos, brillo, Vector3.one * 0.1)
	local luz = crear("PointLight", ancla, { Color = brillo, Range = 11, Brightness = 0 })
	local veta = crear("Highlight", efectos, {
		Adornee = cristal, DepthMode = Enum.HighlightDepthMode.Occluded,
		FillColor = hielo, OutlineColor = blanco, FillTransparency = 1, OutlineTransparency = 1,
	})
	local polvo = crear("ParticleEmitter", ancla, {
		Enabled = false, Rate = 0, Texture = "rbxasset://textures/particles/smoke_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(144, 127, 112), Color3.fromRGB(113, 102, 97)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(0.25, 0.53),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Size = NumberSequence.new(0.4, 2), Lifetime = NumberRange.new(0.45, 0.85),
		Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(42, 42), Drag = 3,
	})
	local polvoEmitido = false
	local camara = corte.camara
	corte.avance = RunService.RenderStepped:Connect(function()
		local t = math.max(0, workspace:GetServerTimeNow() - inicio)
		local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		if t >= duracion or not humanoide or humanoide.Health <= 0 or not jugador:GetAttribute("EnCueva")
			or (camara and workspace.CurrentCamera ~= camara) then
			terminar()
			return
		end
		local giro = math.clamp((t - 1.45) / 1.85, 0, 1)
		giro = giro * giro * (3 - 2 * giro)
		local revelar = math.clamp((t - 0.52) / 0.45, 0, 1)
		local foco = cabeza.Position:Lerp(cristal.Position, giro)
		ancla.Position = foco + frente * (1.9 - giro * 3)
		luz.Color = brillo:Lerp(hielo, giro)
		luz.Brightness = revelar * (1.4 + 0.5 * giro)
		veta.FillTransparency = 1 - giro * 0.35
		veta.OutlineTransparency = 1 - giro * 0.7
		if not polvoEmitido and t >= duracion * 0.65 then
			polvoEmitido = true
			if camara then
				ancla.Position = base + lado * 3.9 - Vector3.yAxis * 2.7
				polvo:Emit(12)
			end
		end
		if camara then
			local angulo = math.rad(20 + 139 * giro)
			local radio = 10.8 + giro * 0.8
			local ojo = base + (frente * math.cos(angulo) + lado * math.sin(angulo)) * radio
				+ Vector3.yAxis * (0.1 + giro * 3.9)
			camara.CFrame = CFrame.lookAt(ojo, foco)
			camara.Focus = CFrame.new(foco)
			camara.FieldOfView = 53 - revelar * 4 + giro * 6
		end
		if giro > 0.64 then descripcion.Text = "Una grieta de luz le recorre la espalda." end
		local opacidad = revelar * math.clamp((duracion - t) / 0.25, 0, 1)
		tarjeta.GroupTransparency = 1 - opacidad
		sombra.BackgroundTransparency = 1 - opacidad * 0.44
	end)
end

local function iniciar(inicio, mutacion, apertura, duracion)
	if not jugador:GetAttribute("EnCueva") or workspace:GetServerTimeNow() - inicio >= duracion then
		return
	end
	terminar()
	local sinMovimiento = GuiService.ReducedMotionEnabled
	local tono = if mutacion then hielo else brillo
	local efectos = crear("Folder", arte, { Name = "Revelacion" })
	local ancla = destello(efectos, tono, Vector3.new(0.1, 0.1, 0.1))
	ancla.Position = centro + Vector3.yAxis * 1.1
	local luz = crear("PointLight", ancla, { Color = tono, Range = 15, Brightness = 0 })
	local pulso = destello(efectos, tono, Vector3.one, Enum.PartType.Cylinder)
	pulso.CFrame = CFrame.new(centro.X, 20.76, centro.Z) * CFrame.Angles(0, 0, math.pi / 2)
	local fragmentos = {}
	if not sinMovimiento then
		for i = 1, 15 do
			fragmentos[i] = destello(efectos, if i % 4 == 0 then blanco else tono,
				Vector3.new(0.12 + (i % 3) * 0.06, 0.18 + (i % 4) * 0.08, 0.13))
		end
	end

	local fragmento, estela, impacto
	if mutacion then
		fragmento = destello(efectos, brillo, Vector3.new(0.31, 0.45, 0.31))
		estela = destello(efectos, tono, Vector3.one)
		impacto = destello(efectos, tono, Vector3.one, Enum.PartType.Ball)
	end

	local corte = abrirEscena(efectos, tono)
	local camara = corte.camara
	categoria.Text = if mutacion then "MUTACIÓN DESCUBIERTA" else "ECO RESCATADO"
	nombre.Text = if mutacion then "Pedernal · Rebote" else "Pedernal"
	descripcion.Text = if mutacion then "Su escudo devuelve el viento." else "Su escudo abre el pasadizo."
	corte.avance = RunService.Heartbeat:Connect(function()
		local edad = math.max(0, workspace:GetServerTimeNow() - inicio)
		local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
		if edad >= duracion or not humanoide or humanoide.Health <= 0
			or not jugador:GetAttribute("EnCueva") or (camara and workspace.CurrentCamera ~= camara) then
			terminar()
			return
		end

		local t = math.clamp((edad - apertura) / 0.86, 0, 1)
		local desenlace = math.clamp((duracion - edad) / 0.27, 0, 1)
		local textoDesde = if mutacion then 1.7 else 1.12
		local entrada = math.clamp((edad - textoDesde) / 0.3, 0, 1)
		tarjeta.GroupTransparency = 1 - entrada * desenlace
		sombra.BackgroundTransparency = 1 - entrada * desenlace * 0.57
		if camara then
			local desliz = 1 - (1 - math.clamp(edad / 2.25, 0, 1)) ^ 2
			local desde = Vector3.new(343.2, 26.8, -7)
			local hasta = Vector3.new(345.4, 26.35, -5.7)
			local objetivo = centro + Vector3.yAxis * (0.85 + t * 1.4)
			camara.CFrame = CFrame.lookAt(desde:Lerp(hasta, desliz), objetivo)
			camara.Focus = CFrame.new(objetivo)
			camara.FieldOfView = 52 - desliz * 4
		end

		local energia = if edad < apertura then edad * 3 else (1 - t) * 4
		luz.Brightness = if sinMovimiento then 0.75 else energia
		if not sinMovimiento and edad >= apertura and t < 1 then
			local diametro = 1.8 + 10.6 * t
			pulso.Size = Vector3.new(0.05, diametro, diametro)
			pulso.Transparency = 0.82 + 0.18 * t
			for i, pieza in ipairs(fragmentos) do
				local a = i * 2.4
				local avance = 1.12 + t * (2 + (i % 4) * 0.66)
				local y = 0.22 + math.sin(t * 2.75) * (1.3 + i % 5 * 0.44)
				pieza.CFrame = CFrame.new(centro + Vector3.new(math.cos(a) * avance, y, math.sin(a) * avance))
					* CFrame.Angles(a + t * 3.6, a / 2, -t * 4)
				pieza.Transparency = math.clamp(t * 1.25, 0, 1)
			end
		else
			pulso.Transparency = 1
			for _, pieza in ipairs(fragmentos) do
				pieza.Transparency = 1
			end
		end

		if fragmento and estela and impacto then
			local punto = centro + Vector3.new(-0.85, 2.67, -0.7)
			local llegada = centro + Vector3.new(-4, 4.2, 0.75)
			local salida = centro + Vector3.new(-0.22, 4.4, -3.6)
			local golpe = edad - 1.43
			local vuelo = math.clamp((edad - 1.12) / 0.31, 0, 1)
			local regreso = math.clamp(golpe / 0.44, 0, 1)
			local hacia = if golpe < 0 then punto else salida
			local pos = if golpe < 0 then llegada:Lerp(punto, vuelo) else punto:Lerp(salida, regreso)
			local anterior = if golpe < 0 then llegada:Lerp(punto, math.max(0, vuelo - 0.22))
				else punto:Lerp(salida, math.max(0, regreso - 0.22))
			local mostrando = not sinMovimiento and edad > 1.13 and edad < 1.87
			fragmento.CFrame = CFrame.lookAt(pos, if (hacia - pos).Magnitude > 0.005 then hacia else pos + Vector3.zAxis)
				* CFrame.Angles(0, math.rad(36), edad * 8)
			fragmento.Color = if golpe < 0 then brillo else tono
			fragmento.Transparency = if mostrando then 0.05 else 1
			local distancia = (pos - anterior).Magnitude
			if mostrando and distancia > 0.025 then
				estela.Size = Vector3.new(0.11, 0.11, distancia)
				estela.CFrame = CFrame.lookAt((pos + anterior) / 2, pos)
			end
			estela.Transparency = if mostrando and distancia > 0.025 then 0.28 else 1
			local radio = math.clamp(golpe / 0.34, 0, 1)
			impacto.Position = punto
			impacto.Size = Vector3.one * (0.32 + radio * 2.2)
			impacto.Transparency = if not sinMovimiento and golpe >= 0 and radio < 1 then 0.5 + radio * 0.5 else 1
		end
	end)
end

remoto.OnClientEvent:Connect(function(evento, a, b, c, d)
	if evento == "Revelacion" then
		iniciar(a, b, c, d)
	elseif evento == "IntroduccionGuardian" then
		presentarGuardian(a, b, c)
	end
end)
saltar.Activated:Connect(saltarEscena)
cueva:GetAttributeChangedSignal("Fase"):Connect(function()
	if escena and escena.guardian and cueva:GetAttribute("Fase") ~= "Presentacion" then terminar() end
end)
jugador.CharacterRemoving:Connect(terminar)

local guia = crear("Folder", arte, { Name = "CorrienteDelMirador" })
local pasos = {
	{ Vector3.new(350.6, 20.16, 4.65), Vector3.new(0.44, 0, 1) },
	{ Vector3.new(352.2, 20.16, 8.2), Vector3.new(0.8, 0, 1) },
	{ Vector3.new(355.4, 20.16, 11.25), Vector3.new(1, 0, 0.57) },
	{ Vector3.new(359.4, 20.16, 13), Vector3.xAxis },
	{ Vector3.new(363, 20.16, 13), Vector3.xAxis },
	{ Vector3.new(370.1, 20.16, 13), Vector3.xAxis },
	{ Vector3.new(378.5, 20.16, 13), Vector3.xAxis },
}
local marcas = {}
for i, paso in ipairs(pasos) do
	local marco = CFrame.lookAt(paso[1], paso[1] + paso[2])
	for _, lado in ipairs({ -1, 1 }) do
		local trazo = destello(guia, hielo, Vector3.new(0.16, 0.043, 0.78))
		trazo.CFrame = marco * CFrame.new(lado * 0.23, 0, 0) * CFrame.Angles(0, lado * math.rad(39), 0)
		marcas[#marcas + 1] = { pieza = trazo, paso = i }
	end
end
local hebras = {}
for i = 1, 12 do
	hebras[i] = destello(guia, hielo, Vector3.new(0.72 + (i % 3) * 0.33, 0.055, 0.055))
end

local guiando = false
local function guiar()
	local fase = cueva:GetAttribute("Fase")
	local mostrar = jugador:GetAttribute("EnCueva") and fase == "Salida" and not escena
	if not mostrar and not guiando then
		return
	end
	guiando = mostrar == true
	local t = workspace:GetServerTimeNow()
	local quieto = GuiService.ReducedMotionEnabled
	for _, marca in ipairs(marcas) do
		marca.pieza.Transparency = if not mostrar then 1 elseif quieto then 0.34
			else 0.36 + math.sin(t * 3.2 - marca.paso * 1.1) * 0.2
	end
	for i, hebra in ipairs(hebras) do
		local progreso = (t * 0.18 + i * 0.194) % 1
		if mostrar and not quieto then
			local z = if i % 2 == 0 then 8.1 else 17.9
			local y = 20.65 + (i % 3) * 0.72
			local x = 356.4 + progreso * (ruta.Baliza.Position.X - 356.4)
			hebra.Position = Vector3.new(x, y, z + math.sin(t * 1.4 + i) * 0.39)
			hebra.Transparency = 0.42 + 0.58 * math.abs(progreso * 2 - 1)
		else
			hebra.Transparency = 1
		end
	end
end

while task.wait(1 / 30) do
	guiar()
end
