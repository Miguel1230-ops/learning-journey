local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Controles = require(ReplicatedStorage:WaitForChild("ControlesCombate"))

local jugador = Players.LocalPlayer
local isla = workspace:WaitForChild("IslaDelViento")
local molino = isla:WaitForChild("MolinoDelViento")
local chispa = molino:WaitForChild("Chispa")
local farol = molino:WaitForChild("Farol")
local zona = molino:WaitForChild("ZonaViento")
local despegue = molino:WaitForChild("PlayaDespegue")
local muelle = molino:WaitForChild("Llegada")
local aspas = molino:WaitForChild("Aspas")
local accion = ReplicatedStorage:WaitForChild("AccionMolino")
local abandonarCola = Instance.new("ProximityPrompt")
abandonarCola.Name = "SalirDeLaEspera"
abandonarCola.ObjectText = "Muelle del Molino"
abandonarCola.ActionText = "Volver al despegue"
abandonarCola.RequiresLineOfSight = false
abandonarCola.MaxActivationDistance = 12
abandonarCola.Enabled = false
abandonarCola.Parent = muelle
abandonarCola.Triggered:Connect(function()
	if jugador:GetAttribute("EsperaMolino") then accion:FireServer("SalirDeLaEspera") end
end)

-- Cada visitante ve las acciones de su turno. El servidor valida de nuevo al interactuar.
local tomar = chispa:WaitForChild("Accion")
local entregar = farol:WaitForChild("Accion")
local volver = molino:WaitForChild("Regreso"):WaitForChild("Accion")
local alcanceTomar, alcanceEntregar, alcanceVolver = tomar.MaxActivationDistance, entregar.MaxActivationDistance, volver.MaxActivationDistance
local function mostrarAcciones()
	local dentro = jugador:GetAttribute("EnMolino") == true
	local propio = dentro and molino:GetAttribute("TitularExpedicion") == jugador.UserId
	tomar.MaxActivationDistance = if propio then alcanceTomar else 0
	entregar.MaxActivationDistance = if propio then alcanceEntregar else 0
	volver.MaxActivationDistance = if dentro and not jugador:GetAttribute("EsperaMolino") then alcanceVolver else 0
	abandonarCola.Enabled = dentro and jugador:GetAttribute("EsperaMolino") == true
end
molino:GetAttributeChangedSignal("TitularExpedicion"):Connect(mostrarAcciones)
jugador:GetAttributeChangedSignal("EnMolino"):Connect(mostrarAcciones)
jugador:GetAttributeChangedSignal("EsperaMolino"):Connect(mostrarAcciones)
mostrarAcciones()

local NOCHE = Color3.fromRGB(15, 26, 40)
local PIZARRA = Color3.fromRGB(54, 75, 97)
local PERLA = Color3.fromRGB(246, 250, 250)
local SUAVE = Color3.fromRGB(192, 210, 224)
local ORO = Color3.fromRGB(255, 201, 111)

local VUELTA = 6.25
local REVELACION = 4.45
local ESCENA_MOVIMIENTO_REDUCIDO = 2.8
local escena
local pendiente

local function crear(clase, padre, props)
	local objeto = Instance.new(clase)
	for nombre, valor in pairs(props) do
		objeto[nombre] = valor
	end
	objeto.Parent = padre
	return objeto
end


local function etiqueta(padre, nombre, y, tamano, alto, fuerte)
	return crear("TextLabel", padre, {
		Name = nombre,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, y),
		Size = UDim2.new(1, -28, 0, alto),
		Font = if fuerte then Enum.Font.GothamBold else Enum.Font.GothamMedium,
		TextSize = tamano,
		TextColor3 = if fuerte then PERLA else SUAVE,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
end

local gui = crear("ScreenGui", jugador:WaitForChild("PlayerGui"), {
	Name = "MolinoDelVientoHUD",
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	DisplayOrder = 13,
	Enabled = false,
})

local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local ficha = UI.objetivo(gui)
local acciones = UI.acciones(gui)

local function boton(padre, nombre, texto, pos, tamano, tono)
	local b = crear("TextButton", padre, {
		Name = nombre,
		AnchorPoint = Vector2.new(1, 1),
		Position = pos,
		Size = tamano,
		BackgroundColor3 = NOCHE,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Text = texto,
		TextColor3 = tono,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
	})
	crear("UICorner", b, { CornerRadius = UDim.new(0, 11) })
	crear("UIStroke", b, { Color = tono, Transparency = 0.57 })
	return b
end


local cine = crear("ScreenGui", gui.Parent, {
	Name = "MolinoCinematica",
	ResetOnSpawn = false,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	DisplayOrder = 26,
	Enabled = false,
})
local sombra = crear("Frame", cine, {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0.32),
	BackgroundColor3 = NOCHE,
	BorderSizePixel = 0,
	BackgroundTransparency = 1,
})
crear("UIGradient", sombra, { Rotation = 90, Transparency = NumberSequence.new(1, 0.05) })
local letrero = crear("CanvasGroup", cine, {
	Name = "Descubrimiento",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.new(1, -44, 0, 80),
	BackgroundColor3 = NOCHE,
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	GroupTransparency = 1,
})
crear("UISizeConstraint", letrero, { MaxSize = Vector2.new(360, 80) })
for _, x in {0.19, 0.81} do
	crear("Frame", letrero, {AnchorPoint=Vector2.new(.5,.5), Position=UDim2.new(x,0,0,15),
		Size=UDim2.new(.14,0,0,1), BackgroundColor3=ORO, BackgroundTransparency=.32, BorderSizePixel=0})
end
local corona = etiqueta(letrero, "Categoria", 6, 11, 17, true)
local nombre = etiqueta(letrero, "Nombre", 24, 23, 27, true)
local lema = etiqueta(letrero, "Pista", 52, 12, 24, false)
nombre.Font = Enum.Font.Garamond
nombre.TextSize = 31
nombre.TextStrokeTransparency = .5
corona.TextColor3 = ORO
corona.TextXAlignment = Enum.TextXAlignment.Center
nombre.TextXAlignment = Enum.TextXAlignment.Center
lema.TextXAlignment = Enum.TextXAlignment.Center
local omitir = boton(cine, "Omitir", "Omitir escena", UDim2.new(1, -14, 0, 11), UDim2.fromOffset(120, 44), PERLA)
omitir.AnchorPoint = Vector2.new(1, 0)

local function hoy()
	return workspace:GetServerTimeNow()
end

local function avatar()
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	return if personaje then personaje:FindFirstChild("HumanoidRootPart") else nil, humanoide
end

local fichaEntregada = false
local function anunciarRescate()
	if not fichaEntregada then
		fichaEntregada = true
		jugador:SetAttribute("FichaRescateLucero", (jugador:GetAttribute("FichaRescateLucero") or 0) + 1)
	end
end

local function cerrarEscena(completada)
	if not escena then
		return
	end
	local anterior = escena
	escena = nil
	cine.Enabled = false
	jugador:SetAttribute("MolinoPresentando", false)
	if anterior.humanoide and anterior.humanoide.Parent then
		if anterior.humanoide.WalkSpeed == 0 then
			anterior.humanoide.WalkSpeed = anterior.paso
		end
		anterior.humanoide.AutoRotate = anterior.giro
		anterior.humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, anterior.salto)
	end
	if anterior.camara and workspace.CurrentCamera == anterior.camara then
		anterior.camara.CFrame = if completada and anterior.marcoFinal then anterior.marcoFinal else anterior.marco
		anterior.camara.Focus = if completada and anterior.focoFinal then anterior.focoFinal else anterior.foco
		anterior.camara.FieldOfView = anterior.fov
		anterior.camara.CameraType = anterior.tipo
	end
	if anterior.ocultos then
		for pieza, transparencia in anterior.ocultos do
			if pieza.Parent then
				pieza.LocalTransparencyModifier = transparencia
			end
		end
	end
	for objeto, encendido in anterior.efectosOcultos or {} do
		if objeto.Parent then objeto.Enabled = encendido end
	end
	if anterior.arte then
		anterior.arte:Destroy()
	end
	if not anterior.llegada then anunciarRescate() end
end

local function luzLocal(padre, tono, medida, forma)
	return crear("Part", padre, {
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
		Material = Enum.Material.Neon,
		Color = tono,
		Size = medida,
		Shape = forma or Enum.PartType.Block,
		Transparency = 1,
	})
end

local function cometaDeEscena(esc)
	local companeros = isla:FindFirstChild("CompanerosCometa")
	local original = companeros and companeros:FindFirstChild(tostring(jugador.UserId))
	if not original or not original:IsA("Model") or original:GetAttribute("Propietario") ~= jugador.UserId then
		return
	end
	local copia = original:Clone()
	if not copia then
		return
	end
	esc.ocultos, esc.efectosOcultos = {}, {}
	for _, pieza in original:GetDescendants() do
		if pieza:IsA("BasePart") then
			esc.ocultos[pieza] = pieza.LocalTransparencyModifier
			pieza.LocalTransparencyModifier = 1
		elseif pieza:IsA("Light") or pieza:IsA("ParticleEmitter") or pieza:IsA("Trail") or pieza:IsA("Beam") then
			esc.efectosOcultos[pieza] = pieza.Enabled
			pieza.Enabled = false
		end
	end
	for _, pieza in copia:GetDescendants() do
		if pieza:IsA("BasePart") then
			pieza.Anchored = true
			pieza.CanCollide = false
			pieza.CanQuery = false
			pieza.CanTouch = false
			pieza.LocalTransparencyModifier = 0
		end
	end
	copia.Name = "CometaEnVuelo"
	esc.inicioEco = original:GetPivot().Position
	copia:PivotTo(original:GetPivot())
	copia.Parent = esc.arte
	esc.cometa = copia

	local centro = copia.PrimaryPart or copia:FindFirstChild("Nucleo")
	if centro and centro:IsA("BasePart") then
		local izq = crear("Attachment", centro, { Position = Vector3.new(-0.5, 0, 0.75) })
		local der = crear("Attachment", centro, { Position = Vector3.new(0.5, 0, 0.75) })
		crear("Trail", centro, {
			Attachment0 = izq,
			Attachment1 = der,
			Color = ColorSequence.new(PERLA, ORO),
			Transparency = NumberSequence.new(0.17, 1),
			WidthScale = NumberSequence.new(0.9, 0),
			Lifetime = 0.32,
			LightEmission = 0.93,
			FaceCamera = true,
			MinLength = 0.12,
		})
	end
end

local function plano(p)
	return Vector3.new(p.X, 0, p.Z)
end

local function curva(a, b, c, d, t)
	return 0.5 * ((2 * b) + (c - a) * t + (2 * a - 5 * b + 4 * c - d) * t * t
		+ (3 * b - a - 3 * c + d) * t * t * t)
end

local function muestrear(paradas, t)
	for i = 1, #paradas - 1 do
		local b = paradas[i]
		local c = paradas[i + 1]
		if t <= c[1] or i == #paradas - 1 then
			local a = paradas[math.max(1, i - 1)]
			local d = paradas[math.min(i + 2, #paradas)]
			local u = math.clamp((t - b[1]) / (c[1] - b[1]), 0, 1)
			return curva(a[2], b[2], c[2], d[2], u), curva(a[3], b[3], c[3], d[3], u),
				b[4] + (c[4] - b[4]) * u, b[5] + (c[5] - b[5]) * u
		end
	end
end

local function escala(u)
	u = math.clamp(u, 0, 1)
	return u * u * (3 - 2 * u)
end

local function vueltaDeIsla(esc, root)
	local puerto, semilla = muelle.Position, chispa.Position
	local eje = aspas:GetPivot().Position
	local ejePlano = plano(eje - semilla)
	local ancho = math.clamp(ejePlano.Magnitude, 18, 48)
	local frente = if ejePlano.Magnitude > .1 then ejePlano.Unit else muelle.CFrame.RightVector
	local rueda = aspas:FindFirstChild("Rueda de hierro")
	local normal = rueda and plano(rueda.Position - eje)
	local lado = if normal and normal.Magnitude > .01 then normal.Unit else frente:Cross(Vector3.yAxis)
	local altura = Vector3.yAxis
	local centro = Vector3.new((semilla.X + eje.X)/2, semilla.Y, (semilla.Z + eje.Z)/2)
	esc.percha = semilla - frente * 1.6 + altura * 1.35
	local haciaChispa = plano(semilla-root.Position)
	local rumbo = if haciaChispa.Magnitude > .05 then haciaChispa.Unit else frente
	local distancia = (esc.marco.Position - esc.foco.Position).Magnitude
	local foco = root.Position + altura*1.5
	local elevacion = math.clamp(-esc.marco.LookVector.Y, -.15, .55)
	local vista = rumbo * math.sqrt(1-elevacion*elevacion) - altura*elevacion
	esc.focoFinal = CFrame.new(foco)
	esc.marcoFinal = CFrame.lookAt(foco - vista * distancia, foco - vista * distancia + vista)
	esc.pasoEco = puerto + frente*5 + lado*2 + altura*3.8
	local cruce = eje + lado*4.8 + altura*.65
	esc.rutaEco = {
		{0, root.Position+altura*2}, {.85, esc.pasoEco},
		{2.10, cruce-frente*7-altura*.9}, {2.86, cruce+frente*2+altura*.55},
		{3.43, cruce+frente*4+lado*4+altura*1.35},
		{4.28, centro+lado*6+altura*6}, {5.05, esc.percha}, {5.55, esc.percha},
	}
	esc.adelante = frente
	return {
		{ 0, esc.marco.Position, esc.foco.Position, esc.fov, 0 },
		{ .85, puerto-frente*4+lado*12+altura*5, esc.pasoEco, 56,-.012 },
		{ 2.10, centro+lado*20+altura*11, cruce-frente*6, 59,-.018 },
		{ 2.86, eje-frente*2+lado*23+altura*4, eje+altura*.65, 59,-.018 },
		{ 3.43, eje+frente*6+lado*22+altura*6, cruce+frente*2, 62,0 },
		{ 4.28, centro+frente*(ancho*.16)+lado*18+altura*10, centro+lado*3+altura*4, 59,.015 },
		{ 5.05, semilla-frente*6+lado*10+altura*5, semilla+altura*.9, 49,.008 },
		{ 5.55, semilla-frente*7+lado*9+altura*4.4, semilla+altura*.65, 49,0 },
		{ esc.duracion, esc.marcoFinal.Position, esc.marcoFinal.Position + esc.marcoFinal.LookVector * math.max(distancia, 1), esc.fov, 0 },
	}
end

local function muestraEco(esc, t)
	local ruta = esc.rutaEco
	ruta[1][2] = esc.inicioEco
	for indice = 1, #ruta-1 do
		local a, b = ruta[indice], ruta[indice+1]
		if t <= b[1] then
			local u = math.clamp((t-a[1])/(b[1]-a[1]), 0, 1)
			if indice == #ruta-1 then return esc.percha end
			return curva(ruta[math.max(1,indice-1)][2], a[2], b[2], ruta[math.min(#ruta,indice+2)][2], u)
		end
	end
	return esc.percha
end

local function chispasDeRecompensa(esc)
	local apunta = farol.Position
	local rueda = aspas:FindFirstChild("Rueda de hierro")
	local normal = rueda and plano(rueda.Position - aspas:GetPivot().Position)
	local frente = if normal and normal.Magnitude > .01 then normal.Unit else Vector3.new(0,0,-1)
	local lado = frente:Cross(Vector3.yAxis)
	if lado:Dot(muelle.Position-apunta) < 0 then lado = -lado end
	esc.vista = (frente*.78 + lado*.85).Unit
	local derecha = esc.vista:Cross(Vector3.yAxis)
	esc.grietas = {}
	local superficieFarol = apunta + esc.vista*.71
	local trazos = {
		{0,.04,-.17,.19,.23}, {-.17,.19,-.11,.48,.34},
		{-.17,.19,-.38,.22,.53}, {0,.04,.24,-.13,.60},
		{.24,-.13,.33,-.38,.73}, {0,.04,.10,.34,.80},
	}
	for _, trazo in trazos do
		local a = superficieFarol + derecha*trazo[1] + Vector3.yAxis*trazo[2]
		local b = superficieFarol + derecha*trazo[3] + Vector3.yAxis*trazo[4]
		local linea = luzLocal(esc.arte, PERLA, Vector3.new(.045,.045,(b-a).Magnitude))
		linea.CFrame = CFrame.lookAt((a+b)/2,b)
		table.insert(esc.grietas,{linea,trazo[5]})
	end
	esc.pulso = luzLocal(esc.arte, ORO, Vector3.one, Enum.PartType.Ball)
	esc.pulso.Position = superficieFarol
	esc.brillo = crear("PointLight", esc.pulso, { Color = ORO, Range = 22, Brightness = 0 })
	esc.particulas = {}
	for i = 1, 18 do
		local tono = if i % 4 == 0 then PERLA else ORO
		esc.particulas[i] = luzLocal(esc.arte, tono, Vector3.new(0.14, 0.34 + (i % 3) * 0.14, 0.13))
	end

	esc.faros = {}
	local luces = molino:FindFirstChild("Luces")
	if not luces then
		return
	end
	local recorrido = luces:GetChildren()
	table.sort(recorrido, function(a, b)
		return a.Name < b.Name
	end)
	for _, faro in recorrido do
		if faro:IsA("BasePart") then
			local pulso = luzLocal(esc.arte, ORO, Vector3.one, Enum.PartType.Ball)
			pulso.Position = faro.Position
			esc.faros[#esc.faros + 1] = pulso
		end
	end
end

local function imagen(esc, origen, objetivoCam, fov, rotacion)
	local camara = esc.camara
	if (origen - objetivoCam).Magnitude < 0.2 then
		objetivoCam = origen + esc.marco.LookVector
	end
	camara.CFrame = CFrame.lookAt(origen, objetivoCam) * CFrame.Angles(0, 0, rotacion)
	camara.Focus = CFrame.new(objetivoCam)
	camara.FieldOfView = fov
end

local function pintarLlegada(esc, t)
	local pos, meta, fov, giro = muestrear(esc.paradas, t)
	imagen(esc, pos, meta, fov, giro)
	local retorno = escala((t - 5.55) / math.max(.1, esc.duracion - 5.55))
	if retorno > 0 then
		esc.camara.CFrame = esc.camara.CFrame:Lerp(esc.marcoFinal, retorno)
		esc.camara.Focus = esc.camara.Focus:Lerp(esc.focoFinal, retorno)
	end
	if not esc.cometa and t >= (esc.reintentoEco or 0) then
		esc.reintentoEco = t + .24
		cometaDeEscena(esc)
	end
	if not esc.cometa then
		return
	end
	local vuelo = muestraEco(esc, t)
	local tangente = muestraEco(esc, t+.05) - vuelo
	local companeros = isla:FindFirstChild("CompanerosCometa")
	local original = companeros and companeros:FindFirstChild(tostring(jugador.UserId))
	if original then vuelo = vuelo:Lerp(original:GetPivot().Position, retorno) end
	vuelo += Vector3.yAxis * math.sin(t*4) * .19 * (1-retorno)
	local frente = if tangente.Magnitude > .02 then tangente.Unit else esc.adelante
	local orientacion = CFrame.lookAt(vuelo, vuelo+frente) * CFrame.Angles(0,0,math.sin(t*3.1)*.13)
	if original and retorno > 0 then orientacion = orientacion:Lerp(original:GetPivot(), retorno) end
	esc.cometa:PivotTo(orientacion)
end

local function pintarPremio(esc, t)
	local centro = farol.Position
	local carpeta = isla:FindFirstChild("CompanerosLucero")
	local lucero = carpeta and carpeta:FindFirstChild(tostring(jugador.UserId))
	local eco = if lucero then lucero:GetPivot().Position else centro + Vector3.yAxis * 2
	local propietario = esc.raiz.Position + Vector3.yAxis * 1.15
	local seguir, abrir = escala((t-.90)/.85), escala((t-1.65)/1.7)
	local mirada = (centro + Vector3.yAxis*.18):Lerp(eco,seguir):Lerp(propietario:Lerp(eco,.60),abrir)
	local base = centro + esc.vista*7.8 + Vector3.yAxis*1.8
	local alto = mirada + esc.vista*(8.5+3*abrir) + Vector3.yAxis*(2+1.2*abrir)
	local corte = math.clamp((t - .92) / 1.05, 0, 1)
	local entrada = escala(t/.30)
	local pos = esc.marco.Position:Lerp(base:Lerp(alto,seguir),entrada)
	local objetivo = esc.foco.Position:Lerp(mirada,entrada)
	imagen(esc, pos, objetivo, esc.fov+(43+9*abrir-esc.fov)*entrada, 0)
	local retorno = escala((t - (esc.duracion-.55))/.55)
	if retorno > 0 then
		esc.camara.CFrame = esc.camara.CFrame:Lerp(esc.marco, retorno)
		esc.camara.Focus = esc.camara.Focus:Lerp(esc.foco, retorno)
		esc.camara.FieldOfView += (esc.fov-esc.camara.FieldOfView)*retorno
	end
	local latido = math.max(0,1-math.abs(t-.23)/.13,1-math.abs(t-.59)/.15)
	esc.pulso.Size = Vector3.one * (if t < .92 then .25+latido*.8 else .35+corte*3)
	esc.pulso.Transparency = if t < .92 then 1-latido*.48 else .65+corte*.35
	esc.brillo.Brightness = .3 + latido*1.3 + math.sin(corte*math.pi)*1.6
	for _, trazo in esc.grietas do
		trazo[1].Transparency = if t < trazo[2] then 1 else .06 + .94*escala((t-.93)/.27)
	end
	for i, pieza in esc.particulas do
		local a = i * 2.4
		local r = 0.3 + corte * (2.0 + i % 4 * 0.9)
		local y = math.sin(corte * 2.54) * (1 + (i % 5) * 0.75)
		pieza.CFrame = CFrame.new(centro + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
			* CFrame.Angles(a, t * 2 + a / 2, t * 4)
		pieza.Transparency = if t < .92 then 1 else math.min(1, corte * 1.36)
	end
	for i, orbe in esc.faros do
		local onda = math.clamp((t - .93 - i * (1.36 / #esc.faros)) / 0.65, 0, 1)
		orbe.Size = Vector3.one * (0.25 + onda * 3.3)
		orbe.Transparency = if onda <= 0 then 1 else 0.51 + onda * 0.49
	end
end

local function iniciarEscena(evento, comienzo, duracionServidor)
	if not jugador:GetAttribute("EnMolino") or jugador:GetAttribute("EnCueva") then
		return
	end
	cerrarEscena()
	local llegada = evento == "Llegada"
	local reducir = GuiService.ReducedMotionEnabled
	local duracion = if llegada then VUELTA else REVELACION
	if typeof(duracionServidor) == "number" then
		duracion = math.clamp(duracionServidor, if llegada then 5.95 else 2.5, 8)
	end
	if reducir then
		duracion = math.min(duracion, ESCENA_MOVIMIENTO_REDUCIDO)
	end
	local root, humanoide = avatar()
	if not root or not humanoide or humanoide.Health <= 0 or hoy() - comienzo >= duracion then
		return
	end
	local camara = if reducir then nil else workspace.CurrentCamera
	local esc = {
		llegada = llegada,
		comienzo = comienzo,
		duracion = duracion,
		camara = camara,
		raiz = root,
	}
	escena = esc
	if camara then
		esc.marco = camara.CFrame
		esc.foco = camara.Focus
		esc.fov = camara.FieldOfView
		esc.tipo = camara.CameraType
		esc.humanoide = humanoide
		esc.paso = humanoide.WalkSpeed
		esc.giro = humanoide.AutoRotate
		esc.salto = humanoide:GetStateEnabled(Enum.HumanoidStateType.Jumping)
		humanoide.WalkSpeed = 0
		humanoide.AutoRotate = false
		humanoide:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		root.AssemblyLinearVelocity = Vector3.new(0, math.min(root.AssemblyLinearVelocity.Y, 0), 0)
		esc.arte = crear("Folder", workspace, { Name = "CinematicaMolinoLocal" })
		camara.CameraType = Enum.CameraType.Scriptable
		if llegada then
			esc.paradas = vueltaDeIsla(esc, root)
			cometaDeEscena(esc)
		else
			chispasDeRecompensa(esc)
		end
	end
	jugador:SetAttribute("MolinoPresentando", true)
	gui.Enabled = false
	letrero.Visible = llegada
	corona.Text = "ARCHIPIÉLAGO DEL VIENTO"
	nombre.Text = "Molino del Viento"
	lema.Text = "Cometa encontró una chispa viva."
	letrero.GroupTransparency = 1
	sombra.BackgroundTransparency = 1
	cine.Enabled = true
end

local function terminarEscena()
	accion:FireServer(if escena.llegada then "TerminarLlegada" else "TerminarDespertar")
	cerrarEscena(true)
end

local function omitirEscena()
	if not escena then
		return false
	end
	terminarEscena()
	return true
end

local function usarEscudo()
	if not escena and jugador:GetAttribute("EnMolino") and jugador:GetAttribute("Pedernal")
		and jugador:GetAttribute("LlevaChispa") and (jugador:GetAttribute("EscudoMolinoListoEn") or 0) <= hoy() then
		accion:FireServer("Escudo")
		return true
	end
	return false
end

Controles.escudoBreve(function() return jugador:GetAttribute("EnMolino") and not escena end, usarEscudo)
ContextActionService:BindActionAtPriority("MolinoEscudo", function(_, entrada)
	if entrada == Enum.UserInputState.Begin and usarEscudo() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonR1)
ContextActionService:BindActionAtPriority("MolinoOmitir", function(_, entrada)
	if entrada == Enum.UserInputState.Begin and omitirEscena() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.ButtonB)
omitir.Activated:Connect(omitirEscena)
local function interrumpirEscena()
	if pendiente and pendiente.evento == "Despertar" then anunciarRescate() end
	pendiente = nil
	cerrarEscena()
end
jugador.CharacterRemoving:Connect(interrumpirEscena)
jugador:GetAttributeChangedSignal("EnMolino"):Connect(function()
	if not jugador:GetAttribute("EnMolino") then
		interrumpirEscena()
	end
end)
accion.OnClientEvent:Connect(function(evento, comienzo, duracion)
	if (evento == "Llegada" or evento == "Despertar") and typeof(comienzo) == "number" then
		pendiente = { evento = evento, comienzo = comienzo, duracion = duracion }
	end
end)

local function cercaDelViento(posicion)
	local d = zona.CFrame:PointToObjectSpace(posicion)
	local mitad = zona.Size * 0.5 + Vector3.new(5, 3, 5)
	return math.abs(d.X) <= mitad.X and math.abs(d.Y) <= mitad.Y and math.abs(d.Z) <= mitad.Z
end

local function mostrarMision()
	local root, humanoide = avatar()
	local dentro = jugador:GetAttribute("EnMolino") == true
	local completado = jugador:GetAttribute("Lucero") == true
	local despegando = root and not completado and jugador:GetAttribute("Pedernal") and jugador:GetAttribute("Cometa")
		and (root.Position - despegue.Position).Magnitude < 13
	gui.Enabled = root ~= nil and humanoide ~= nil and humanoide.Health > 0 and not jugador:GetAttribute("EnCueva")
		and not jugador:GetAttribute("BitacoraAbierta") and (dentro or despegando == true)
	if not gui.Enabled then return end

	local titulo, pista, estado = "Molino del Viento", "Recoge la chispa del pedestal junto al muelle.", nil
	local icono, carga = "Molino", nil
	local botones = {}
	if not dentro then
		titulo, pista = "Despegue hacia el molino", "Salta desde la playa y planea hasta el muelle de las aspas."
	elseif jugador:GetAttribute("EsperaMolino") then
		titulo, pista = "Turno en el muelle", "Otro explorador lleva la chispa. Espera aquí o vuelve al despegue."
	elseif completado then
		titulo, pista = "El molino volvió a girar", "Vuelve al refugio con Lucero y visita al Farero."
		if jugador:GetAttribute("EstadoGuardado")=="Reintentando" then estado="Guardado pendiente" end
	elseif jugador:GetAttribute("LlevaChispa") then
		icono,titulo,pista = "Chispa","La chispa del molino","Cruza el pasadizo y coloca la chispa en el farol."
		carga = math.clamp(jugador:GetAttribute("FuerzaChispa") or 1,0,1)
		local t=hoy()
		local protegido=(jugador:GetAttribute("EscudoMolinoHasta") or 0)>t
		local recarga=math.max(0,(jugador:GetAttribute("EscudoMolinoListoEn") or 0)-t)
		local viento=molino:GetAttribute("EstadoViento")
		if protegido then estado="Pedernal protege la chispa"
		elseif cercaDelViento(root.Position) and (viento=="Aviso" or viento=="Rafaga") then estado="¡Ráfaga! Cubre la chispa con el escudo"
		else estado=("Luz de la chispa · %d%%"):format(math.round(carga*100)) end
		botones[1]={icono="Escudo",tecla=if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then "R1" else "M2",
			texto=if protegido then "Activo" elseif recarga>0 then ("%.1f s"):format(recarga) else "Escudo",activar=usarEscudo}
	elseif jugador:GetAttribute("EstadoChispa")=="Apagada" then
		titulo,pista="La chispa se apagó","Recógela otra vez en el pedestal. Pedernal puede protegerla."
	end
	ficha:actualizar(icono,titulo,pista,estado,carga)
	acciones:actualizar(botones)
end

local relojHud = 0
RunService.PreRender:Connect(function(dt)
	if pendiente then
		if hoy() - pendiente.comienzo > 1.75 then
			if pendiente.evento == "Despertar" then anunciarRescate() end
			pendiente = nil
		elseif jugador:GetAttribute("EnMolino") and molino:GetAttribute("TitularExpedicion") == jugador.UserId then
			local solicitud = pendiente
			pendiente = nil
			local bien, fallo = pcall(iniciarEscena, solicitud.evento, solicitud.comienzo, solicitud.duracion)
			if not bien then
				cerrarEscena()
				warn(fallo)
			end
			if solicitud.evento == "Despertar" and not escena then anunciarRescate() end
		end
	end
	if escena then
		local esc = escena
		local t = math.max(0, hoy() - esc.comienzo)
		local _, humanoide = avatar()
		if not humanoide or humanoide.Health <= 0 or jugador:GetAttribute("EnCueva")
			or (esc.camara and workspace.CurrentCamera ~= esc.camara) then
			cerrarEscena()
		elseif t >= esc.duracion then
			terminarEscena()
		else
			local entrada = if not esc.camara then 0 elseif esc.llegada then 4.78 else 1.22
			local visible = escala((t - entrada) / 0.28) * escala((esc.duracion - t) / 0.2)
			letrero.GroupTransparency = 1 - visible
			sombra.BackgroundTransparency = if esc.llegada then 1 - visible * .8 else 1
			if esc.camara then
				if esc.llegada then
					pintarLlegada(esc, t)
				else
					pintarPremio(esc, t)
				end
			end
			return
		end
	end
	relojHud += dt
	if relojHud >= 0.07 then
		relojHud = 0
		mostrarMision()
	end
end)
