local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local isla = workspace:WaitForChild("IslaDelViento")
local faro = isla:WaitForChild("RuinasDelFaro")
local remoto = ReplicatedStorage:WaitForChild("AccionFaro")
local despegue = faro.Despegue
local llegada = faro.Llegada
local plataformas = faro.Plataformas
local losa = plataformas["Plataforma de llegada"]
local espejo = faro.Espejo
local puerta = faro.Puerta
local linterna = faro.Linterna
local veta = faro.Veta
local prisma = faro.Prisma
local oro = Color3.fromRGB(255, 203, 126)
local agua = Color3.fromRGB(141, 232, 218)
local lila = Color3.fromRGB(207, 175, 255)
local fareroPosicion = Vector3.new(85.8, 23.65, -2)
local llegadaRefugio = Vector3.new(82.4, 23.65, 3.1)
local jugador
local visitas = {}
local aproximaciones = {}
local turno = 0
local rastro = false
local lente = false
local abierta = false
local encendido = false
local angulo = 0
local girando = false
local GIRO_ESPEJO = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Las señales y los peldaños de Lucero mantienen su propia lógica de visibilidad.
for _, pieza in plataformas:GetChildren() do
	if pieza:IsA("BasePart") and (pieza.Name:match("^Estratos ") or pieza.Name == "Pilar erosionado"
		or pieza.Name == "Remate antiguo" or pieza.Name == "Roca suspendida") then
		pieza.CanCollide, pieza.CanQuery = true, true
	end
end
local sueloFaro = RaycastParams.new()
sueloFaro.FilterType = Enum.RaycastFilterType.Include
sueloFaro.FilterDescendantsInstances = { plataformas }
sueloFaro.RespectCanCollide = true

local function reloj()
	return workspace:GetServerTimeNow()
end

local function anunciar(titulo, pista)
	faro:SetAttribute("TituloFaro", titulo)
	faro:SetAttribute("PistaFaro", pista)
end

local function interactuar(parte, titulo, accion, alcance)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Accion"
	p.ObjectText = titulo
	p.ActionText = accion
	p.Enabled = false
	p.MaxActivationDistance = alcance
	p.RequiresLineOfSight = false
	p.ClickablePrompt = true
	p.Parent = parte
	return p
end

local girar = interactuar(faro.Girar, "Espejo de Lucero", "Girar espejo", 6)
local montar = interactuar(faro.Montura, "Anclaje del faro", "Montar lente", 5.5)
local recoger = interactuar(prisma, "Prisma", "Tocar cristal", 5.5)
local regreso = interactuar(faro.Regreso, "Refugio del Viento", "Regresar", 6)
local salida = interactuar(faro.SalidaTerraza, "Refugio del Viento", "Regresar", 6)
local pasoTorre = interactuar(faro.Rastro, "Camino de Prisma", "Ir al pie de la torre", 8)
local pasoCamara = interactuar(prisma, "Camino de Prisma", "Ir al pie de la torre", 8)
pasoCamara.Name = "CaminoDePrisma"

local function punto(ubicacion)
	local parte = Instance.new("Part")
	parte.Name = "FinDelHaz"
	parte.Size = Vector3.new(0.17, 0.17, 0.17)
	parte.Position = ubicacion
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanQuery = false
	parte.Transparency = 1
	parte.Parent = faro
	return parte
end

local function crearHaz(desde, hasta, color, ancho, final)
	local a = Instance.new("Attachment")
	a.Parent = desde
	local b = Instance.new("Attachment")
	b.Parent = hasta
	local luz = Instance.new("Beam")
	luz.Attachment0, luz.Attachment1 = a, b
	luz.FaceCamera = true
	luz.Color = ColorSequence.new(color)
	luz.LightEmission = 0.88
	luz.Transparency = NumberSequence.new(0.27, 0.79)
	luz.Width0, luz.Width1 = ancho, final
	luz.Enabled = false
	luz.Parent = desde
	return luz
end

local centro = espejo.PrimaryPart
local haciaLinterna = crearHaz(centro, linterna, oro, 0.6, 0.28)
local haciaVeta = crearHaz(centro, veta, lila, 0.53, 0.34)
local nubes = punto(Vector3.new(96, 32, 101))
local haciaNubes = crearHaz(centro, nubes, agua, 0.46, 0.32)
local entreIslas = crearHaz(linterna, isla:WaitForChild("MolinoDelViento"):WaitForChild("Farol"), oro, 1.72, 5.6)
entreIslas.Name = "HazDelMolino"
local extremoGiro = punto(nubes.Position)
local hazGiro = crearHaz(centro, extremoGiro, agua, 0.48, 0.28)
local destello = Instance.new("PointLight")
destello.Name = "DestelloDeAlineacion"
destello.Range = 12
destello.Brightness = 0
destello.Parent = centro
local clic = Instance.new("Sound")
clic.Name = "ClicDelEspejo"
clic.SoundId = "rbxasset://sounds/volume_slider.ogg"
clic.PlaybackSpeed = 1.18
clic.Volume = 0.55
clic.RollOffMaxDistance = 36
clic.Parent = centro

local function avatar(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return if h and h.Health > 0 then c:FindFirstChild("HumanoidRootPart") else nil, h
end

local function mover(root, pos, mira)
	root.Parent:PivotTo(CFrame.lookAt(pos, Vector3.new(mira.X, pos.Y, mira.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
end

local function cerca(quien, prompt)
	local visita = visitas[quien]
	local root = avatar(quien)
	return visita and visita == quien.Character and quien:GetAttribute("EnFaro") and root
		and (root.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance + 0.65
end

local escalones = {}
for _, e in faro.Escalones:GetChildren() do
	escalones[e] = {e.Transparency, e.CanCollide}
end
local aspecto = {
	espejo = espejo:GetPivot(), puerta = puerta.CFrame, opacidad = puerta.Transparency,
	linterna = linterna.Color, material = linterna.Material, vidrio = linterna.Transparency,
	prisma = prisma.Color, aro = faro["Aro de la lente"].Color, anclaje = faro["Aro de la lente"].Transparency,
}
local animaciones = {}
local function animar(objeto, info, propiedades)
	local animacion = TweenService:Create(objeto, info, propiedades)
	animaciones[animacion] = true
	animacion.Completed:Once(function() animaciones[animacion] = nil end)
	animacion:Play()
	return animacion
end

local function liberarTurno(p)
	if jugador ~= p then return end
	turno += 1
	jugador = nil
	faro:SetAttribute("TitularExpedicion", nil)
	for animacion in animaciones do animacion:Cancel() end
	table.clear(animaciones)
	rastro, lente, abierta, encendido, girando = false, false, false, false, false
	angulo = 0
	espejo:PivotTo(aspecto.espejo)
	puerta.CFrame, puerta.Transparency, puerta.CanCollide = aspecto.puerta, aspecto.opacidad, true
	linterna.Color, linterna.Material, linterna.Transparency = aspecto.linterna, aspecto.material, aspecto.vidrio
	linterna.Luz.Enabled, veta.Luz.Enabled = false, false
	prisma.Color = aspecto.prisma
	local aro = faro["Aro de la lente"]
	aro.Color, aro.Transparency = aspecto.aro, aspecto.anclaje
	for e, original in escalones do e.Transparency, e.CanCollide = original[1], original[2] end
	haciaLinterna.Enabled, haciaVeta.Enabled, haciaNubes.Enabled = false, false, false
	hazGiro.Enabled, entreIslas.Enabled, entreIslas.Width1 = false, false, 5.6
	destello.Brightness = 0
	clic:Stop()
	faro:SetAttribute("RastroRevelado", false)
	faro:SetAttribute("EspejoGirando", false)
	anunciar("Ruinas del Faro", "Lucero puede iluminar las marcas antiguas.")
end

local function mostrarRastro()
	if rastro then
		return
	end
	rastro = true
	faro:SetAttribute("RastroRevelado", true)
	for _, escalon in faro.Escalones:GetChildren() do
		escalon.CanCollide = true
		animar(escalon, TweenInfo.new(0.35), { Transparency = 0.13 })
	end
	anunciar("El camino de Lucero", "Cruza los escalones de luz y gira el espejo hacia la linterna.")
end

local function encenderLinterna()
	if encendido then
		return
	end
	encendido = true
	linterna.Color = oro
	linterna.Material = Enum.Material.Neon
	linterna.Transparency = 0.08
	linterna.Luz.Enabled = true
	entreIslas.Enabled = true
	animar(entreIslas, TweenInfo.new(0.78), { Width1 = 7.3 })
end

local function abrirCamara()
	if abierta then
		return
	end
	abierta = true
	puerta.CanCollide = false
	veta.Luz.Enabled = true
	animar(puerta, TweenInfo.new(0.65, Enum.EasingStyle.Quint), {
		Position = puerta.Position + Vector3.yAxis * 8.15,
		Transparency = 0.8,
	})
end

local function terminarVisita(p)
	aproximaciones[p] = nil
	p:SetAttribute("EsperaFaro", nil)
	visitas[p] = nil
	if jugador == p then liberarTurno(p) end
	p:SetAttribute("EnFaro", false)
end

local function salir(quien, prompt)
	if cerca(quien, prompt) and (prompt == regreso or rastro or quien:GetAttribute("Prisma")) then
		local root = avatar(quien)
		terminarVisita(quien)
		mover(root, llegadaRefugio, fareroPosicion)
	end
end
regreso.Triggered:Connect(function(quien) salir(quien, regreso) end)
salida.Triggered:Connect(function(quien) salir(quien, salida) end)

-- Los veteranos pueden entrar a la torre desde la losa, o salir de la cámara
-- aunque el turno siguiente ya haya cerrado la puerta y ocultado sus peldaños.
local function caminoDePrisma(p, prompt)
	if not p:GetAttribute("Prisma") or not p:GetAttribute("FaroEncendido") or not cerca(p, prompt) then return end
	local root = avatar(p)
	local rutaNimbo = faro:FindFirstChild("RescateNimbo")
	local ascensor = rutaNimbo and rutaNimbo:FindFirstChild("Ascensor")
	if not ascensor then return end
	mover(root, ascensor.Position + Vector3.new(0, 4, 2), ascensor.Position)
end
pasoTorre.Triggered:Connect(function(p) caminoDePrisma(p, pasoTorre) end)
pasoCamara.Triggered:Connect(function(p) caminoDePrisma(p, pasoCamara) end)

remoto.OnServerEvent:Connect(function(quien, accion)
	if accion ~= "Lucero" or quien ~= jugador or not quien:GetAttribute("EnFaro")
		or not quien:GetAttribute("Lucero") then
		return
	end
	local root = avatar(quien)
	if root and (root.Position - faro.Rastro.Position).Magnitude <= 13 then
		mostrarRastro()
	end
end)

montar.Triggered:Connect(function(quien)
	if quien ~= jugador or lente or not cerca(quien, montar) or not quien:GetAttribute("LenteGeoda") or not rastro then
		return
	end
	lente = true
	local aro = faro["Aro de la lente"]
	aro.Color = lila
	aro.Transparency = 0.05
	anunciar("Lente montada", "Dirige la luz del espejo hacia la veta violeta junto a la cámara.")
end)

girar.Triggered:Connect(function(quien)
	if quien ~= jugador or girando or not cerca(quien, girar) or not rastro then
		return
	end
	girando = true
	faro:SetAttribute("EspejoGirando", true)
	local siguiente = angulo % 3 + 1
	local objetivo = if siguiente == 1 then linterna.Position elseif siguiente == 2 then veta.Position else nubes.Position
	local origen = espejo:GetPivot()
	local destino = CFrame.lookAt(centro.Position, objetivo)
	local objetivoPrevio = if angulo == 1 then linterna.Position elseif angulo == 2 then veta.Position else nubes.Position
	local alcanceInicial = (objetivoPrevio - centro.Position).Magnitude
	local alcanceFinal = (objetivo - centro.Position).Magnitude
	local tono = if siguiente == 1 then oro elseif siguiente == 2 then lila else agua
	local recorrido = Instance.new("NumberValue")
	local miTurno = turno
	local function dibujarGiro(avance)
		if turno ~= miTurno then return end
		local pose = origen:Lerp(destino, avance)
		espejo:PivotTo(pose)
		extremoGiro.Position = pose.Position + pose.LookVector * (alcanceInicial + (alcanceFinal - alcanceInicial) * avance)
	end
	haciaLinterna.Enabled, haciaVeta.Enabled, haciaNubes.Enabled = false, false, false
	dibujarGiro(0)
	hazGiro.Enabled = true
	local cambio = recorrido.Changed:Connect(dibujarGiro)
	local animacion = animar(recorrido, GIRO_ESPEJO, { Value = 1 })
	animacion.Completed:Wait()
	cambio:Disconnect()
	recorrido:Destroy()
	if miTurno ~= turno or quien ~= jugador or not avatar(quien) then return end
	espejo:PivotTo(destino)
	angulo = siguiente
	hazGiro.Enabled = false
	haciaLinterna.Enabled = angulo == 1
	haciaVeta.Enabled = angulo == 2 or (angulo == 1 and quien:GetAttribute("Prisma") == true)
	haciaNubes.Enabled = angulo == 3
	clic:Play()
	if angulo ~= 3 then
		destello.Color = tono
		destello.Brightness = 2.6
		animar(destello, TweenInfo.new(0.24), { Brightness = 0 })
	end
	girando = false
	faro:SetAttribute("EspejoGirando", false)
	if quien.Parent ~= Players then
		return
	end
	if angulo == 1 then
		encenderLinterna()
		quien:SetAttribute("FaroEncendido", true)
		anunciar("¡Faro encendido!", if lente then "La luz del faro también puede abrir la cámara."
			else "El haz llega hasta el molino. La veta violeta esconde otro camino.")
	elseif angulo == 2 then
		if lente and encendido then
			abrirCamara()
			anunciar("La cámara se abrió", "Sigue la luz violeta hasta el cristal de Prisma.")
		else
			anunciar("La veta refleja la luz", if lente then "Enciende la linterna para dar fuerza al haz."
				else "El anclaje pide la lente que guarda el guardián de la Geoda en su revancha.")
		end
	else
		anunciar("Luz hacia las nubes", "Vuelve a girar el espejo para apuntar a otra superficie.")
	end
end)

recoger.Triggered:Connect(function(quien)
	if quien ~= jugador or quien:GetAttribute("Prisma") or not abierta or not lente or not encendido or not cerca(quien, recoger)
		or not quien:GetAttribute("LenteGeoda") or not quien:GetAttribute("FaroEncendido") then
		return
	end
	quien:SetAttribute("Prisma", true)
	liberarTurno(quien)
end)

local function vivoEnRuinas(nuevo)
	nuevo:SetAttribute("EnFaro", false)
	local function restaurar()
		if jugador ~= nuevo then return end
		if nuevo:GetAttribute("Prisma") and nuevo:GetAttribute("FaroEncendido") then
			liberarTurno(nuevo)
		elseif nuevo:GetAttribute("FaroEncendido") then
			encenderLinterna()
		end
	end
	for _, atributo in {"ProgresoRevision", "FaroEncendido", "Prisma"} do
		nuevo:GetAttributeChangedSignal(atributo):Connect(restaurar)
	end
	nuevo.CharacterRemoving:Connect(function() terminarVisita(nuevo) end)
end

local function entrar(p)
	aproximaciones[p] = nil
	p:SetAttribute("EsperaFaro", nil)
	visitas[p] = p.Character
	if not (p:GetAttribute("Prisma") and p:GetAttribute("FaroEncendido")) then
		jugador = p
		turno += 1
		faro:SetAttribute("TitularExpedicion", p.UserId)
		if p:GetAttribute("FaroEncendido") then encenderLinterna() end
		anunciar("Ruinas del Faro", "Acércate a las marcas de la orilla y llama a Lucero.")
	end
	p:SetAttribute("EnFaro", true)
end

local function alturaDePie(root, h)
	if h.RigType == Enum.HumanoidRigType.R6 then
		local pierna = root.Parent:FindFirstChild("Left Leg")
		return root.Size.Y / 2 + (if pierna then pierna.Size.Y else 2)
	end
	return root.Size.Y / 2 + h.HipHeight
end

local function pieEnLaIsla(root, h)
	local relativa = losa.CFrame:PointToObjectSpace(root.Position)
	if math.abs(relativa.X) > losa.Size.X / 2 + 0.8 or math.abs(relativa.Z) > losa.Size.Z / 2 + 0.8
		or relativa.Y < losa.Size.Y / 2 or root.AssemblyLinearVelocity.Y > 3 then
		return false
	end
	-- FloorMaterial solo indica apoyo; los rayos distinguen arriba de un costado y ambas orillas.
	if h.FloorMaterial == Enum.Material.Air then return false end
	local alcance = alturaDePie(root, h) + 0.65
	local lado, frente = root.CFrame.RightVector * 0.58, root.CFrame.LookVector * 0.38
	for _, offset in { Vector3.zero, lado, -lado, frente, -frente } do
		local impacto = workspace:Raycast(root.Position + offset, -Vector3.yAxis * alcance, sueloFaro)
		if impacto and impacto.Normal.Y > 0.7 and impacto.Position.Y >= losa.Position.Y + losa.Size.Y / 2 - 0.3 then
			return true
		end
	end
	return false
end

local secuenciaLlegada = 0
local origenVuelo = despegue.Position
local rumboVuelo = (llegada.Position - origenVuelo) * Vector3.new(1, 0, 1)
local ejeVuelo = rumboVuelo.Unit
local lateralVuelo = ejeVuelo:Cross(Vector3.yAxis)

local function cancelarEspera(p)
	aproximaciones[p] = nil
	if p:GetAttribute("EsperaFaro") then p:SetAttribute("EsperaFaro", nil) end
end

local function devolverAlDespegue(p, root, h)
	local retorno = origenVuelo + Vector3.yAxis * (alturaDePie(root, h) + .3)
	mover(root, retorno, llegada.Position)
	remoto:FireClient(p, "ReintentarLlegada")
end

local function aproximarse(p, root, h, t)
	local desplazamiento = root.Position - origenVuelo
	local avance = desplazamiento:Dot(ejeVuelo)
	local deriva = math.abs(desplazamiento:Dot(lateralVuelo))
	local enTramo = avance >= -3 and avance <= rumboVuelo.Magnitude + llegada.Size.Z * .65
		and deriva <= math.max(llegada.Size.X / 2 + 6, despegue.Size.X / 2)
	local planeando = (p:GetAttribute("PlaneoIslaHasta") or 0) > t
	local a = aproximaciones[p]
	if a and (a.raiz ~= root or (not a.orden and t > a.limite)) then
		cancelarEspera(p)
		a = nil
	end
	if not a then
		if not enTramo or not (planeando or (avance > 2 and h.FloorMaterial == Enum.Material.Air)) then return nil end
		a = {raiz = root, planeo = planeando, limite = t + 12}
		aproximaciones[p] = a
	end
	a.planeo = a.planeo or (enTramo and planeando)
	if a.planeo and enTramo and pieEnLaIsla(root, h) then
		if not a.orden then
			secuenciaLlegada += 1
			a.orden = secuenciaLlegada
		end
		return a.orden
	elseif root.Position.Y < losa.Position.Y - 12 then
		cancelarEspera(p)
		devolverAlDespegue(p, root, h)
	elseif a.orden or (h.FloorMaterial ~= Enum.Material.Air and (not enTramo or avance < rumboVuelo.Magnitude / 2)) then
		cancelarEspera(p)
	end
	return nil
end

anunciar("Ruinas del Faro", "Lucero puede iluminar las marcas antiguas.")
faro:SetAttribute("RastroRevelado", false)
faro:SetAttribute("EspejoGirando", false)
faro:SetAttribute("TitularExpedicion", nil)
Players.PlayerAdded:Connect(vivoEnRuinas)
Players.PlayerRemoving:Connect(terminarVisita)
for _, p in Players:GetPlayers() do vivoEnRuinas(p) end

-- Los accesos y las salidas son personales. El servidor valida cada activación;
-- los clientes muestran sólo los avisos que corresponden a su visita.
regreso.Enabled, salida.Enabled = true, true
pasoTorre.Enabled, pasoCamara.Enabled = true, true
local function habilitar(prompt, disponible)
	if prompt:GetAttribute("Disponible") ~= disponible then
		prompt:SetAttribute("Disponible", disponible)
		prompt.Enabled = disponible
	end
end
while task.wait(.05) do
	local t = reloj()
	local primero, primerOrden
	for _, p in Players:GetPlayers() do
		local root, h = avatar(p)
		local visita = visitas[p]
		local otraZona = p:GetAttribute("EnCueva") or p:GetAttribute("EnMolino") or p:GetAttribute("EnEncargoPedernal")
		if visita then
			if not root or visita ~= p.Character or otraZona or not p:GetAttribute("EnFaro") then
				terminarVisita(p)
			elseif root.Position.Y < losa.Position.Y - 12 then
				terminarVisita(p)
				devolverAlDespegue(p, root, h)
			elseif root.Position.Z < losa.Position.Z - losa.Size.Z / 2 - 8
				or (root.Position - losa.Position).Magnitude > 150 then
				terminarVisita(p)
			end
		elseif root and p:GetAttribute("ProgresoListo") and p:GetAttribute("Lucero") and not otraZona then
			local orden = aproximarse(p, root, h, t)
			if orden then
				if p:GetAttribute("Prisma") and p:GetAttribute("FaroEncendido") then
					entrar(p)
				else
					if not p:GetAttribute("EsperaFaro") then p:SetAttribute("EsperaFaro", true) end
					if not primerOrden or orden < primerOrden then
						primero, primerOrden = p, orden
					end
				end
			end
		elseif aproximaciones[p] then
			cancelarEspera(p)
		end
	end
	if not jugador and primero then entrar(primero) end
	habilitar(girar, jugador ~= nil and rastro and not girando)
	habilitar(montar, jugador ~= nil and rastro and not lente and jugador:GetAttribute("LenteGeoda") == true)
	habilitar(recoger, jugador ~= nil and abierta and not jugador:GetAttribute("Prisma"))
end
