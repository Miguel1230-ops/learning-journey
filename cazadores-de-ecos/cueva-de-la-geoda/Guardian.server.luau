-- La arena y sus objetos pertenecen a quien entra por el portal hasta que termina su visita.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuardianVisual = require(script.Parent:WaitForChild("GuardianVisual"))
local Baston = require(script.Parent:WaitForChild("BastonResonancia"))
local VientoVisual = require(script.Parent:WaitForChild("VientoVisual"))
local ProgresoDatos = require(game:GetService("ServerScriptService"):WaitForChild("ProgresoDatos"))
local FormacionEcos = require(ReplicatedStorage:WaitForChild("FormacionEcos"))

local cueva = workspace:WaitForChild("CuevaDeLaGeoda")
local isla = workspace:WaitForChild("IslaDelViento")
local remoto = ReplicatedStorage:WaitForChild("AccionGeoda")
local guardian = cueva.Guardian
local cristal = guardian.CristalEspalda
local geoda = cueva.Geoda
local cometa = cueva.Cometa
local pedernal = cueva.Pedernal
local ruta = cueva.Ruta
local cristalAlto = cueva.CristalAlto
local MAX_VIDA = 3
local ROCA = Color3.fromRGB(100, 119, 151)
local VERDE = Color3.fromRGB(126, 250, 217)
local ORO = Color3.fromRGB(255, 214, 111)
local CORAL = Color3.fromRGB(255, 116, 96)
local VIOLETA = Color3.fromRGB(190, 131, 255)
local AZUL = Color3.fromRGB(128, 218, 255)
local PISO = 20.09
local DURACION_REVELACION = 3.3
local APERTURA_GEODA = 0.58
local DURACION_INTRO = 4
local PREPARAR_CARGA = 1.4
local PREPARAR_BARRIDO = 0.95
local DURACION_BARRIDO = 0.58

ruta.PuertaViento.Material = Enum.Material.SmoothPlastic
ruta.PuertaViento.Transparency = 0.72

local jugador
local personajeDelTurno
local conexionesDelTurno = {}
local coloresIniciales = { sello = ruta.SelloRebote.Color, baliza = ruta.Baliza.Color }
local fase = "Inicio"
local estado = "Acecha"
local vida = MAX_VIDA
local hazana = false
local selloEncendido = false
local proximo = "Embestida"
local hasta = 0
local siguientePulso = 0
local siguienteOrden = 0
local escudoHasta = 0
local siguienteDisparo = 0
local aviso
local proyectil
local defensaVisual
local puertaAbierta = false
local direccion = -Vector3.xAxis
local posicion = guardian.PrimaryPart.Position
local origenGuardian = posicion
local puntoAlto = cristalAlto.PrimaryPart.Position
local posCometa = cometa:GetPivot()
local posPedernal = pedernal:GetPivot()
local llevaCometa = false
local tienePedernal = false
local tieneRebote = false
local golpeo = false
local distanciaEmbestida = 0
local origenIsla
local revelacion
local revancha = false
local columnaIntacta = true
local inicioAtaque = 0
local direccionInicial = direccion
local direccionSenuelo = direccion
local proximoEscudo = 0
local progresoBarrido = 0

local efectos = Instance.new("Folder")
efectos.Name = "Efectos"
efectos.Parent = cueva

local function reloj()
	return workspace:GetServerTimeNow()
end

local function parte(padre, nombre, tamano, marco, color, forma)
	local p = Instance.new("Part")
	p.Name = nombre
	p.Size = tamano
	p.CFrame = marco
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Shape = forma or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = padre
	return p
end

local function plano(v)
	return Vector3.new(v.X, 0, v.Z)
end

local visual = GuardianVisual.new(guardian, efectos, parte)
visual:mostrarColumna(true)

local function cerca(root, punto, alcance)
	return root and (root.Position - punto).Magnitude <= alcance
end

local function dentro(pos, zona)
	local a = zona.CFrame:PointToObjectSpace(pos)
	local b = zona.Size / 2
	return math.abs(a.X) <= b.X and math.abs(a.Y) <= b.Y and math.abs(a.Z) <= b.Z
end

local function avatar(quien)
	local char = quien and quien.Character
	local h = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and h and h.Health > 0 then
		return root, h
	end
	return nil
end

local function informacion(titulo, pista)
	cueva:SetAttribute("Titulo", titulo)
	cueva:SetAttribute("Pista", pista)
end

local function cambiarFase(nueva, titulo, pista)
	fase = nueva
	cueva:SetAttribute("Fase", nueva)
	informacion(titulo, pista)
end

local function cambiarEstado(nuevo)
	estado = nuevo
	cueva:SetAttribute("EstadoGuardian", nuevo)
	cristal.Color = if nuevo == "Expuesto" then VERDE else ROCA
	cristal.Material = if nuevo == "Expuesto" then Enum.Material.Neon else Enum.Material.Slate
end

local function indicador(padre, nombre, verbo, distancia)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Accion"
	p.ObjectText = nombre
	p.ActionText = verbo
	p.MaxActivationDistance = distancia
	p.ClickablePrompt = true
	p.RequiresLineOfSight = false
	p.Parent = padre
	return p
end

local trial = parte(isla, "PruebaDeLaGeoda", Vector3.new(1.7, 1.8, 1.7),
	CFrame.new(-51, 22.2, 4.55) * CFrame.Angles(0, 0, 0.4), VIOLETA)
local portal = parte(isla.Rutas, "PortalDeLaGeoda", Vector3.new(1.75, 1.85, 1.75),
	CFrame.new(87.15, 22.25, 9.25) * CFrame.Angles(0, 0, 0.4), VIOLETA)
local atajo = indicador(trial, "Cueva de la Geoda", "Probar con Cometa", 8.0)
local entrada = indicador(portal, "Expedición a la Geoda", "Entrar con Cometa", 7.5)
local reto = indicador(cueva.Totem, "Guardián de la Geoda", "Comenzar desafío", 8.5)
local volver = indicador(cueva.SalidaIsla, "Isla del Viento", "Volver a la isla", 7)
local abrir = indicador(geoda.Punto, "Geoda del guardián", "Abrir geoda", 8.5)
local descubrir = indicador(ruta.Baliza, "Mirador de la Geoda", "Encender baliza", 8.5)
local playa = isla:WaitForChild("MolinoDelViento"):WaitForChild("PlayaDespegue")
local refugioViento = isla:WaitForChild("RefugioDelViento")
local salidaRelevo = refugioViento:WaitForChild("InicioEncargo")
local primeraLuz = refugioViento:WaitForChild("Faro1")
local function faltaRelevo(quien)
	return not quien:GetAttribute("EncargoPedernal") and not quien:GetAttribute("Lucero")
end
local seguirMolino = indicador(ruta.Baliza, "Mirador de la Geoda", "Seguir al Molino", 8.5)
seguirMolino.Name = "SeguirAlMolino"
seguirMolino.Enabled = false
local retornoLente = parte(cueva, "SalidaAlRefugio", Vector3.new(0.8, 2.05, 0.8),
	CFrame.new(346.95, 22.5, 9.1) * CFrame.Angles(0, 0, math.rad(29)), VERDE)
local salidaLente = indicador(retornoLente, "Refugio del Viento", "Volver con la lente", 7.5)
local lente = parte(geoda, "LenteDeLaGeoda", Vector3.new(0.18, 2.12, 2.12), CFrame.new(350, 24.2, 0),
	AZUL, Enum.PartType.Cylinder)
local aroLente = parte(geoda, "BordeDeLaLente", Vector3.new(0.135, 2.42, 2.42), CFrame.new(350.13, 24.2, 0),
	ORO, Enum.PartType.Cylinder)
lente.Transparency = 1
aroLente.Transparency = 1
retornoLente.Transparency = 1
salidaLente.Enabled = false
atajo.Enabled = RunService:IsStudio() and game.GameId == 0 and isla:GetAttribute("AtajosDePrueba") == true
trial.Transparency = if atajo.Enabled then 0 else 1
entrada.Enabled = true
abrir.Enabled = false
descubrir.Enabled = false

local function puedeUsar(quien, p)
	local root = avatar(quien)
	return quien == jugador and quien.Character == personajeDelTurno and quien:GetAttribute("EnCueva") == true
		and p.Enabled and cerca(root, p.Parent.Position, p.MaxActivationDistance + 0.65)
end

local function transparenciaOriginal(objeto)
	local partes = {}
	for _, hijo in ipairs(objeto:GetDescendants()) do
		if hijo:IsA("BasePart") then
			partes[hijo] = hijo.Transparency
		end
	end
	return partes
end

local pedernalPartes = transparenciaOriginal(pedernal)
local plantillaPedernal = pedernal:Clone()
plantillaPedernal.Name = "PedernalCompanero"
plantillaPedernal.Parent = ReplicatedStorage
local cristalPartes = transparenciaOriginal(cristalAlto)
local armadura = transparenciaOriginal(geoda.Caparazon)
local piezasGeoda = {}
for pieza in pairs(armadura) do
	local separacion = plano(pieza.Position - geoda.PrimaryPart.Position)
	piezasGeoda[pieza] = {
		marco = pieza.CFrame,
		direccion = if separacion.Magnitude > 0.1 then separacion.Unit else Vector3.yAxis,
	}
end

local function mostrar(partes, visible)
	for p, t in pairs(partes) do
		p.Transparency = if visible then t else 1
	end
end

local function animarGeoda(tiempo)
	if not revelacion then
		return
	end
	local edad = math.max(0, tiempo - revelacion.inicio)
	if revelacion.nuevo and not revelacion.rocaAbierta then
		local progreso = math.clamp((edad - APERTURA_GEODA) / 0.59, 0, 1)
		local vuelo = 1 - (1 - progreso) ^ 3
		for pieza, datos in pairs(piezasGeoda) do
			if edad < APERTURA_GEODA then
				local temblor = math.sin(edad * 38) * edad * 0.19
				pieza.CFrame = datos.marco + Vector3.new(temblor, 0, -temblor * 0.54)
			else
				local avance = datos.direccion * vuelo * 3.45
				pieza.CFrame = (datos.marco + avance + Vector3.yAxis * math.sin(vuelo * math.pi) * 1.65)
					* CFrame.Angles(vuelo * 0.35, 0, vuelo * 0.5)
				pieza.Transparency = armadura[pieza] + (1 - armadura[pieza]) * progreso
			end
		end
		revelacion.rocaAbierta = progreso >= 1
	end
	if edad >= APERTURA_GEODA then
		if not revelacion.visible then
			mostrar(pedernalPartes, true)
			revelacion.visible = true
		end
		local subida = 1 - (1 - math.clamp((edad - APERTURA_GEODA) / 0.73, 0, 1)) ^ 3
		local altura = -0.95 + subida * 2.52 + math.sin(edad * 4) * 0.12 * subida
		local lugar = posPedernal.Position + Vector3.yAxis * altura
		local frente = CFrame.lookAt(lugar, lugar + Vector3.new(-1, 0, -0.72))
		pedernal:PivotTo(frente * CFrame.Angles(0, (1 - subida) * 0.68, (1 - subida) * 0.13))
	end
	if edad >= DURACION_REVELACION then
		revelacion = nil
	end
end

local function orientar()
	guardian:PivotTo(CFrame.lookAt(posicion, posicion + direccion))
end

local function quitarAviso()
	if aviso then
		aviso:Destroy()
		aviso = nil
	end
end

local function quitarProyectil()
	if proyectil then
		proyectil.pieza:Destroy()
		proyectil = nil
	end
end

local function moverA(quien, destino)
	local char = quien.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		char:PivotTo(destino)
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function restablecerArena()
	revelacion = nil
	quitarAviso()
	quitarProyectil()
	for _, efecto in efectos:GetChildren() do
		if efecto ~= visual.columna and efecto ~= visual.filo then efecto:Destroy() end
	end
	defensaVisual = nil
	escudoHasta, proximoEscudo, siguienteDisparo = 0, 0, 0
	siguientePulso, siguienteOrden, hasta, inicioAtaque = 0, 0, 0, 0
	llevaCometa, tienePedernal, tieneRebote, selloEncendido = false, false, false, false
	revancha, hazana, golpeo, puertaAbierta = false, false, false, false
	vida, columnaIntacta, proximo = MAX_VIDA, true, "Embestida"
	for pieza, datos in piezasGeoda do pieza.CFrame = datos.marco end
	mostrar(armadura, true)
	mostrar(cristalPartes, true)
	mostrar(pedernalPartes, false)
	cometa:PivotTo(posCometa)
	pedernal:PivotTo(posPedernal)
	visual:mostrarColumna(true)
	ruta.PuertaViento.CanCollide, ruta.PuertaViento.Transparency = true, 0.72
	ruta.SelloRebote.Color, ruta.Baliza.Color = coloresIniciales.sello, coloresIniciales.baliza
	cueva:SetAttribute("SelloEncendido", false)
	cueva:SetAttribute("Hazana", false)
	cueva:SetAttribute("VidaGuardian", MAX_VIDA)
	entrada.ActionText, atajo.ActionText = "Entrar con Cometa", "Probar con Cometa"
	reto.ActionText = "Comenzar desafío"
	reto.Enabled = false
	descubrir.Enabled, seguirMolino.Enabled, volver.Enabled = false, false, false
	abrir.ActionText = "Abrir geoda"
	abrir.Enabled = false
	lente.Transparency = 1
	aroLente.Transparency = 1
	retornoLente.Transparency = 1
	salidaLente.Enabled = false
	posicion = origenGuardian
	direccion = -Vector3.xAxis
	orientar()
	visual:pose("Acecha", 0)
	cambiarEstado("Acecha")
	cambiarFase("Inicio", "Cueva de la Geoda", "Acércate al tótem. Cometa conoce el punto débil del guardián.")
end

local function liberar(quien)
	if not quien or jugador ~= quien then return end
	jugador = nil
	for _, conexion in conexionesDelTurno do conexion:Disconnect() end
	table.clear(conexionesDelTurno)
	Baston.quitar(personajeDelTurno)
	personajeDelTurno, origenIsla = nil, nil
	quien:SetAttribute("EnCueva", false)
	for _, atributo in {"PulsoCuevaListoEn", "OrdenCometaListaEn", "EscudoHasta", "EscudoCombateListoEn"} do
		quien:SetAttribute(atributo, 0)
	end
	restablecerArena()
	cueva:SetAttribute("TitularExpedicion", nil)
end

local function actualizarProgreso(quien)
	if jugador ~= quien then return end
	if quien:GetAttribute("Pedernal") and not tienePedernal then
		tienePedernal = true
		mostrar(armadura, false)
		mostrar(pedernalPartes, true)
		reto.ActionText = "Jugar revancha"
	end
	tieneRebote = quien:GetAttribute("Rebote") == true
	selloEncendido = quien:GetAttribute("SelloGeoda") == true
	cueva:SetAttribute("SelloEncendido", selloEncendido)
	ruta.SelloRebote.Color = if selloEncendido then ORO else coloresIniciales.sello
	ruta.Baliza.Color = if quien:GetAttribute("MiradorGeoda") then ORO else coloresIniciales.baliza
end

local function entrarCueva(quien, p)
	local root, h = avatar(quien)
	if quien.Parent ~= Players or not p.Enabled or not cerca(root, p.Parent.Position, p.MaxActivationDistance + 0.65)
		or not quien:GetAttribute("ProgresoListo") or quien:GetAttribute("FaseNido") == "Defensa"
		or quien:GetAttribute("EnCueva") or quien:GetAttribute("EnMolino") or quien:GetAttribute("EnFaro")
		or quien:GetAttribute("EnEncargoPedernal") then
		return
	end
	if not quien:GetAttribute("Cometa") and p ~= atajo then
		remoto:FireClient(quien, "AvisoPortal", "Rescata a Cometa antes de entrar a la cueva.")
		return
	end
	if jugador then
		remoto:FireClient(quien, "AvisoPortal", "Hay una expedición en curso. Vuelve al portal cuando quede libre.")
		return
	end
	jugador, personajeDelTurno, origenIsla = quien, quien.Character, root.CFrame
	cueva:SetAttribute("TitularExpedicion", quien.UserId)
	entrada.ActionText, atajo.ActionText = "Consultar expedición en curso", "Consultar expedición en curso"
	llevaCometa = true
	actualizarProgreso(quien)
	reto.Enabled, volver.Enabled = true, true
	descubrir.Enabled = tienePedernal and not quien:GetAttribute("MiradorGeoda")
	if quien:GetAttribute("LenteGeoda") then
		retornoLente.Transparency, salidaLente.Enabled = 0.1, true
		cambiarFase("Revancha", "La lente de la Geoda", "La salida verde te lleva de vuelta al farero.")
	elseif descubrir.Enabled then
		cambiarFase("Salida", "Enciende la baliza", "Usa el escudo de Pedernal para cruzar el pasadizo de viento.")
	end
	local titular = personajeDelTurno
	local function abandonar()
		if personajeDelTurno == titular then liberar(quien) end
	end
	table.insert(conexionesDelTurno, h.Died:Connect(abandonar))
	table.insert(conexionesDelTurno, quien.CharacterRemoving:Connect(function(c)
		if c == titular then abandonar() end
	end))
	table.insert(conexionesDelTurno, quien:GetAttributeChangedSignal("ProgresoRevision"):Connect(function()
		if personajeDelTurno == titular then actualizarProgreso(quien) end
	end))
	quien:SetAttribute("EnCueva", true)
	h.Health = h.MaxHealth
	moverA(quien, cueva.Entrada.CFrame)
	cometa:PivotTo(posCometa)
	if tienePedernal then
		pedernal:PivotTo(cueva.Entrada.CFrame * CFrame.new(-3, 2.4, -1))
		mostrar(pedernalPartes, true)
	end
end

atajo.Triggered:Connect(function(quien)
	entrarCueva(quien, atajo)
end)
entrada.Triggered:Connect(function(quien)
	entrarCueva(quien, entrada)
end)
volver.Triggered:Connect(function(quien)
	if not puedeUsar(quien, volver) then
		return
	end
	local destino = origenIsla or isla.Inicio.CFrame * CFrame.new(0, 3.4, 0)
	liberar(quien)
	moverA(quien, destino)
end)

seguirMolino.Triggered:Connect(function(quien)
	if not puedeUsar(quien, seguirMolino) or fase == "Combate" or fase == "Presentacion"
		or not quien:GetAttribute("MiradorGeoda") or not quien:GetAttribute("Pedernal") then
		return
	end
	liberar(quien)
	local posicion = Vector3.new(playa.Position.X, 23.65, playa.Position.Z - 1.12)
	local llegadaMolino = playa.Parent.Llegada.Position
	local destino = llegadaMolino
	if faltaRelevo(quien) then
		local frente = plano(primeraLuz.Position - salidaRelevo.Position)
		if frente.Magnitude > .01 then frente = frente.Unit end
		posicion = salidaRelevo.Position - frente*2.6 + Vector3.yAxis * 1.1
		destino = primeraLuz.Position
	end
	moverA(quien, CFrame.lookAt(posicion, Vector3.new(destino.X, posicion.Y, destino.Z)))
end)

salidaLente.Triggered:Connect(function(quien)
	if not puedeUsar(quien, salidaLente) or not quien:GetAttribute("LenteGeoda") then
		return
	end
	local refugio = isla:FindFirstChild("RefugioDelViento")
	local farero = refugio and refugio:FindFirstChild("PuntoFarero")
	local llegada = Vector3.new(82.4, 23.65, 3.1)
	local destino = if farero then CFrame.lookAt(llegada, Vector3.new(farero.Position.X, llegada.Y, farero.Position.Z))
		else origenIsla or isla.Inicio.CFrame * CFrame.new(0, 3.4, 0)
	liberar(quien)
	moverA(quien, destino)
end)

local function explosion(centro, tono, radio, tiempo)
	local a = CFrame.new(centro) * CFrame.Angles(0, 0, math.pi / 2)
	local p = parte(efectos, "Pulso", Vector3.new(0.12, 1.5, 1.5), a, tono, Enum.PartType.Cylinder)
	p.Transparency = 0.25
	local tween = TweenService:Create(p, TweenInfo.new(tiempo), {
		Size = Vector3.new(0.12, 2 * radio, 2 * radio),
		Transparency = 1,
	})
	tween.Completed:Once(function()
		p:Destroy()
	end)
	tween:Play()
end

local function entrarEnCombate()
	Baston.equipar(jugador.Character)
	orientar()
	visual:pose("Acecha", 0)
	cambiarEstado("Acecha")
	cambiarFase("Combate", "Guardián de la Geoda", "Guía su carga a la columna agrietada o pide a Cometa que lo distraiga.")
end

local function comenzar(quien)
	if not puedeUsar(quien, reto) or fase == "Combate" or fase == "Presentacion" or fase == "Gana" or revelacion then
		return
	end
	local _, h = avatar(quien)
	h.Health = h.MaxHealth
	revancha = tienePedernal
	vida = MAX_VIDA
	hazana = false
	proximo = "Embestida"
	columnaIntacta = true
	visual:mostrarColumna(true)
	escudoHasta, proximoEscudo = 0, 0
	quien:SetAttribute("EscudoHasta", 0)
	quien:SetAttribute("EscudoCombateListoEn", 0)
	posicion = origenGuardian
	direccion = -Vector3.xAxis
	orientar()
	quitarAviso()
	quitarProyectil()
	mostrar(cristalPartes, true)
	reto.Enabled = false
	abrir.Enabled = false
	descubrir.Enabled = false
	retornoLente.Transparency = 1
	salidaLente.Enabled = false
	cueva:SetAttribute("VidaGuardian", vida)
	cueva:SetAttribute("Hazana", false)
	if not quien:GetAttribute("VioIntroduccionGeoda") and not revancha then
		quien:SetAttribute("VioIntroduccionGeoda", true)
		inicioAtaque = reloj()
		hasta = inicioAtaque + DURACION_INTRO
		cambiarEstado("Presentacion")
		cambiarFase("Presentacion", "Despierta el guardián", "")
		remoto:FireClient(quien, "IntroduccionGuardian", guardian, inicioAtaque, DURACION_INTRO)
	else
		entrarEnCombate()
	end
end
reto.Triggered:Connect(comenzar)

local function recuperar(duracion)
	quitarAviso()
	cambiarEstado("Recupera")
	visual:pose("Recupera", 0)
	hasta = reloj() + duracion
end

local function mostrarPuntoDebil(mensaje)
	quitarAviso()
	cambiarEstado("Expuesto")
	hasta = reloj() + 3.45
	visual:pose("Expuesto", 1)
	informacion(mensaje or "¡Cristal expuesto!", "Rodéalo, mira el cristal de su espalda y golpéalo con el bastón.")
	visual:esquirlas(cristal.Position, VERDE)
end

local function avisar(destino, tiempo)
	local delta = plano(destino - posicion)
	if delta.Magnitude > 0.1 then
		direccion = delta.Unit
	end
	orientar()
	inicioAtaque = tiempo
	local base = Vector3.new(posicion.X, PISO, posicion.Z)
	if proximo == "Embestida" then
		proximo = "Barrido"
		distanciaEmbestida = 23
		local centro = base + direccion * (distanciaEmbestida / 2)
		aviso = parte(efectos, "LineaDeEmbestida", Vector3.new(1.1, 0.10, distanciaEmbestida),
			CFrame.lookAt(centro, centro + direccion), CORAL)
		cambiarEstado("Aviso")
		aviso.Transparency = 0.38
		informacion("¡Embestida!", "Lleva su carga a la columna dorada o llama a Cometa.")
		hasta = tiempo + PREPARAR_CARGA
	else
		proximo = "Embestida"
		cambiarEstado("PrepararBarrido")
		informacion("¡Barrido de cristal!", "Mira el puño violeta. Salta sobre la hoja o rodea al guardián.")
		hasta = tiempo + PREPARAR_BARRIDO
	end
end

local function limitarArena(p)
	return Vector3.new(math.clamp(p.X, 288.5, 346), p.Y, math.clamp(p.Z, -23.6, 23.6))
end

local function jugarCombate(root, h, dt, tiempo)
	if estado == "Acecha" then
		local d = plano(root.Position - posicion)
		local alcance = if proximo == "Embestida" then 18.5 else 11.2
		if d.Magnitude <= alcance then
			avisar(root.Position, tiempo)
		elseif d.Magnitude > 0.1 then
			direccion = d.Unit
			posicion = limitarArena(posicion + direccion * math.min(d.Magnitude, 10.8 * dt))
			orientar()
		end
	elseif estado == "Aviso" then
		visual:pose(estado, math.clamp((tiempo - inicioAtaque) / PREPARAR_CARGA, 0, 1))
		if tiempo >= hasta then
			quitarAviso()
			golpeo = false
			cambiarEstado("Embestida")
			visual:pose("Embestida", 1)
		end
	elseif estado == "SigueACometa" then
		local progreso = math.clamp((tiempo - inicioAtaque) / 0.68, 0, 1)
		local angulo = math.atan2(direccionInicial:Cross(direccionSenuelo).Y, direccionInicial:Dot(direccionSenuelo))
		direccion = CFrame.fromAxisAngle(Vector3.yAxis, angulo * progreso):VectorToWorldSpace(direccionInicial)
		orientar()
		visual:pose(estado, progreso)
		if progreso >= 1 then mostrarPuntoDebil("¡Cometa apartó su mirada!") end
	elseif estado == "PrepararBarrido" then
		visual:pose(estado, math.clamp((tiempo - inicioAtaque) / PREPARAR_BARRIDO, 0, 1))
		if tiempo >= hasta then
			cambiarEstado("Barrido")
			inicioAtaque, progresoBarrido, golpeo = tiempo, 0, false
		end
	elseif estado == "Barrido" then
		local progreso = math.clamp((tiempo - inicioAtaque) / DURACION_BARRIDO, 0, 1)
		visual:pose(estado, progreso)
		local lado = plano(root.Position - posicion)
		local base = guardian:GetPivot()
		local angulo = math.deg(math.atan2(lado:Dot(base.RightVector), lado:Dot(base.LookVector)))
		-- Recorrer todo el sector desde el último paso evita saltarse al avatar entre cuadros.
		local dentroDelArco = angulo >= visual.inicioBarrido - visual.recorridoBarrido * progreso - 10
			and angulo <= visual.inicioBarrido - visual.recorridoBarrido * progresoBarrido + 10
		local pies = root.Position.Y - h.HipHeight - root.Size.Y * 0.5
		if h.RigType == Enum.HumanoidRigType.R6 then
			local pierna = root.Parent:FindFirstChild("Left Leg")
			pies -= if pierna then pierna.Size.Y else 2
		end
		if not golpeo and lado.Magnitude < 11.35 and dentroDelArco and pies < PISO + 2.3 then
			golpeo = true
			if tiempo >= escudoHasta then
				h:TakeDamage(24)
			else
				VientoVisual.impacto(root.Position, root.Position - posicion, "Bloqueo", efectos)
			end
		end
		progresoBarrido = progreso
		if progreso >= 1 then recuperar(1.12) end
	elseif estado == "Embestida" then
		local avance = math.min(distanciaEmbestida, 36 * dt)
		posicion = limitarArena(posicion + direccion * avance)
		distanciaEmbestida -= avance
		orientar()
		visual:pose("Embestida", 1)
		if columnaIntacta and plano(posicion - visual.centroColumna).Magnitude < 4.1 then
			columnaIntacta = false
			visual:mostrarColumna(false)
			mostrarPuntoDebil("¡La columna quebró su guardia!")
			return
		elseif not hazana and plano(posicion - puntoAlto).Magnitude < 4.9 then
			hazana = true
			cueva:SetAttribute("Hazana", true)
			mostrar(cristalPartes, false)
			visual:esquirlas(puntoAlto, ORO)
			mostrarPuntoDebil("¡Hazaña del cristal alto!")
			return
		end
		if not golpeo and root.Position.Y < 27 and plano(root.Position - posicion).Magnitude < 3.9 then
			golpeo = true
			h:TakeDamage(34)
		end
		if distanciaEmbestida <= 0 then
			recuperar(1.14)
		end
	elseif estado == "Expuesto" and tiempo >= hasta then
		recuperar(0.82)
		informacion("El guardián volvió a cubrirse", "Puedes distraerlo en su próxima embestida.")
	elseif estado == "Recupera" and tiempo >= hasta then
		cambiarEstado("Acecha")
		informacion("Guardián de la Geoda", "Observa sus hombros. Si se inclina, prepara una carga.")
	end
end

local function ganar()
	Baston.quitar(jugador and jugador.Character)
	quitarAviso()
	cambiarEstado("Recupera")
	guardian:PivotTo(CFrame.lookAt(posicion, posicion + direccion) * CFrame.Angles(math.rad(-22), 0, 0))
	local muestraLente = revancha and not jugador:GetAttribute("LenteGeoda")
	abrir.ActionText = if muestraLente then "Recoger lente" elseif revancha then "Canalizar geoda" else "Abrir geoda"
	if muestraLente then
		lente.Transparency = 0.15
		aroLente.Transparency = 0.08
	end
	abrir.Enabled = true
	cambiarFase("Gana", "¡Guardián derrotado!", if muestraLente then "Algo brilla en el pedestal. Acércate para recoger la lente."
		elseif hazana then "La geoda y la hazaña del cristal te esperan."
		else "El tesoro está a salvo. Acércate a la geoda.")
end

local function golpearGuardian(quien, root)
	if jugador ~= quien or personajeDelTurno ~= root.Parent or fase ~= "Combate" or not quien:GetAttribute("EnCueva") then return end
	local lado = plano(root.Position - posicion)
	local acertado = estado == "Expuesto" and Baston.enArco(root, cristal.Position, 8)
		and (lado.Magnitude <= 0.1 or direccion:Dot(lado.Unit) <= 0.35)
	if not acertado then
		if Baston.enArco(root,posicion,9.2) then
			local contacto = posicion + (if lado.Magnitude>.01 then lado.Unit*2.1 else Vector3.zero)
			Baston.impacto(contacto,"Armadura",efectos)
			informacion("El bastón chocó con la armadura", "Rodéalo y apunta al cristal cuando quede expuesto.")
		end
		return
	end
	Baston.impacto(cristal.Position,"Cristal",efectos)
	vida -= 1
	cueva:SetAttribute("VidaGuardian", vida)
	visual:esquirlas(cristal.Position, ORO)
	if vida == 0 then
		ganar()
	else
		recuperar(1.08)
		informacion("¡Rompiste una capa de armadura!", "Quedan " .. vida .. " golpes al cristal.")
	end
end

local function orden(root, tiempo)
	if fase ~= "Combate" or not llevaCometa or tiempo < siguienteOrden then
		return
	end
	local haciaJugador = plano(root.Position - posicion)
	if estado ~= "Aviso" or haciaJugador.Magnitude > 26 or haciaJugador.Magnitude < 0.2 then
		siguienteOrden = tiempo + 0.24
		jugador:SetAttribute("OrdenCometaListaEn", siguienteOrden)
		return
	end
	direccionInicial, direccionSenuelo = direccion, -haciaJugador.Unit
	inicioAtaque = tiempo
	quitarAviso()
	cambiarEstado("SigueACometa")
	informacion("Cometa llama su atención", "Prepárate para golpear el cristal.")
	visual:rafaga(cometa:GetPivot().Position, guardian.Cabeza.Position)
	siguienteOrden = tiempo + 0.75
	jugador:SetAttribute("OrdenCometaListaEn", siguienteOrden)
end

local function escudo(root, tiempo)
	if not tienePedernal or fase == "Presentacion" or tiempo < escudoHasta then
		return
	end
	if fase == "Combate" then
		if not revancha or tiempo < proximoEscudo then return end
		escudoHasta = tiempo + 1.2
		proximoEscudo = tiempo + ProgresoDatos.RecargaEscudo({MejoraPedernal = jugador:GetAttribute("MejoraPedernal")})
		jugador:SetAttribute("EscudoCombateListoEn", proximoEscudo)
	else
		escudoHasta = tiempo + 3.3
	end
	jugador:SetAttribute("EscudoHasta", escudoHasta)
	if fase == "Salida" then
		informacion("Escudo activo", "Cruza el viento y toca la baliza del mirador.")
	end
end

remoto.OnServerEvent:Connect(function(quien, tipo)
	if quien ~= jugador or not quien:GetAttribute("EnCueva") then
		return
	end
	local root = avatar(quien)
	if root and (root.Position - cueva.Entrada.Position).Magnitude <= 137 then
		local t = reloj()
		if tipo == "OmitirIntroGuardian" and fase == "Presentacion" then
			entrarEnCombate()
		elseif tipo == "GolpeBaston" and fase == "Combate" and t >= siguientePulso then
			siguientePulso = t + .83
			jugador:SetAttribute("PulsoCuevaListoEn",siguientePulso)
			Baston.golpear(root,function() golpearGuardian(quien, root) end)
		elseif tipo == "Cometa" then
			orden(root, t)
		elseif tipo == "Escudo" then
			escudo(root, t)
		end
	end
end)

abrir.Triggered:Connect(function(quien)
	if fase ~= "Gana" or not puedeUsar(quien, abrir) then
		return
	end
	abrir.Enabled = false
	local nuevo = not tienePedernal
	local nuevaMutacion = hazana and not tieneRebote
	tienePedernal = true
	if hazana then
		tieneRebote = true
		quien:SetAttribute("Rebote", true)
	end
	quien:SetAttribute("TesoroRevelado", true)
	quien:SetAttribute("Pedernal", true)
	reto.ActionText = "Jugar revancha"
	reto.Enabled = true
	descubrir.Enabled = not quien:GetAttribute("MiradorGeoda")
	if revancha then
		local nuevaLente = not quien:GetAttribute("LenteGeoda")
		quien:SetAttribute("LenteGeoda", true)
		lente.Transparency = 1
		aroLente.Transparency = 1
		retornoLente.Transparency = 0.1
		salidaLente.Enabled = true
		cambiarFase("Revancha", if nuevaLente then "¡Lente de la Geoda conseguida!" else "¡Revancha ganada!",
			"La salida verde te lleva al farero. Él sabe cómo montar la lente en las ruinas.")
	else
		cambiarFase("Salida", if hazana then "¡Pedernal aprendió Rebote!" else "¡Eco Pedernal rescatado!",
			"Usa su escudo junto al pasadizo de viento para abrirte camino.")
	end
	if nuevo or nuevaMutacion then
		local inicio = reloj() + 0.17
		revelacion = { inicio = inicio, nuevo = nuevo, rocaAbierta = false, visible = false }
		pedernal:PivotTo(posPedernal)
		mostrar(pedernalPartes, false)
		remoto:FireClient(quien, "Revelacion", inicio, nuevaMutacion, APERTURA_GEODA, DURACION_REVELACION)
	else
		explosion(geoda.PrimaryPart.Position, ORO, 9.5, 0.48)
	end
end)

descubrir.Triggered:Connect(function(quien)
	if not tienePedernal or not puedeUsar(quien, descubrir) then
		return
	end
	descubrir.Enabled = false
	ruta.Baliza.Color = ORO
	quien:SetAttribute("MiradorGeoda", true)
	if faltaRelevo(quien) then
		cambiarFase("Final", "Un farol pide ayuda", "La baliza te lleva al primer farol del relevo. Allí puedes probar el escudo de Pedernal.")
	else
		cambiarFase("Final", "El molino se ve desde aquí", "Usa la baliza para seguir al Molino. Desde la playa podrás despegar con Cometa.")
	end
end)

local function mostrarEscudo(root, tiempo)
	local activo = tiempo < escudoHasta
	if activo and not defensaVisual then
		defensaVisual = parte(efectos, "EscudoPedernal", Vector3.new(6.5, 6.5, 6.5),
			CFrame.new(root.Position), AZUL, Enum.PartType.Ball)
		VientoVisual.escudo(defensaVisual)
	elseif not activo and defensaVisual then
		defensaVisual:Destroy()
		defensaVisual = nil
	end
	if defensaVisual then
		defensaVisual.Position = root.Position
	end
end

local function actualizarSalida(root, h, tiempo, dt)
	local activo = tiempo < escudoHasta
	local d = ruta.PuertaViento.CFrame:PointToObjectSpace(root.Position)
	local cruzando = math.abs(d.X) < 1.5 and math.abs(d.Z) < ruta.PuertaViento.Size.Z / 2 + 1
	puertaAbierta = activo or (puertaAbierta and cruzando)
	ruta.PuertaViento.CanCollide = not puertaAbierta
	ruta.PuertaViento.Transparency = if puertaAbierta then 0.93 else 0.72
	if not proyectil and tiempo >= siguienteDisparo and dentro(root.Position, ruta.ZonaViento) then
		local origen = ruta.PuntoProyectil.Position
		local pieza = parte(efectos, "ProyectilDeViento", Vector3.new(1.6, 1.6, 1.6), CFrame.new(origen),
			VIOLETA, Enum.PartType.Ball)
		local avance = -Vector3.xAxis
		VientoVisual.avisar(origen, origen+avance*10, VIOLETA, efectos)
		proyectil = { pieza = pieza, avanza = avance, reflejado = false, dispara = tiempo+.57, estela = VientoVisual.estela(pieza) }
		siguienteDisparo = tiempo + 2.6
	end
	if not proyectil then
		return
	end

	local p = proyectil.pieza
	if tiempo < proyectil.dispara then
		local carga = 1 - math.clamp((proyectil.dispara-tiempo)/.57,0,1)
		p.Size = Vector3.one * (.45 + 1.15*carga)
		return
	end
	if proyectil.reflejado then
		local delta = ruta.SelloRebote.Position - p.Position
		if delta.Magnitude < 1.55 then
			quitarProyectil()
			if not selloEncendido then
				selloEncendido = true
				cueva:SetAttribute("SelloEncendido", true)
				jugador:SetAttribute("SelloGeoda", true)
				ruta.SelloRebote.Color = ORO
				explosion(ruta.SelloRebote.Position, ORO, 7.5, 0.54)
				informacion("¡Pedernal devolvió el disparo!", "La mutación encendió el sello oculto del mirador.")
			end
			return
		end
		proyectil.avanza = delta.Unit
	end
	p.Position += proyectil.avanza * (if proyectil.reflejado then 26 else 16) * dt
	if not proyectil.reflejado and cerca(root, p.Position, 3.05) then
		VientoVisual.impacto(root.Position,proyectil.avanza,if activo then (if tieneRebote then "Rebote" else "Bloqueo") else "Daño",efectos)
		if activo and tieneRebote then
			proyectil.reflejado = true
			p.Color = ORO
			proyectil.estela.Color = ColorSequence.new(ORO, VERDE)
		else
			if not activo then
				h:TakeDamage(15)
				root:ApplyImpulse(Vector3.new(-19, 5, 0) * root.AssemblyMass)
			end
			quitarProyectil()
		end
	elseif p.Position.X < 350 then
		quitarProyectil()
	end
end

local function acompanar(root)
	local t = reloj()
	if fase == "Combate" and (estado == "SigueACometa" or estado == "Expuesto") then
		local sitio = posicion + direccion * 6 + Vector3.new(0, 3.7, 0)
		cometa:PivotTo(cometa:GetPivot():Lerp(CFrame.lookAt(sitio, posicion), 0.25))
	else
		cometa:PivotTo(FormacionEcos.pose("Cometa", root.CFrame, t, cometa:GetPivot(), 0.28))
	end
	if tienePedernal and not revelacion then
		pedernal:PivotTo(FormacionEcos.pose("Pedernal", root.CFrame, t, pedernal:GetPivot(), 0.28))
	end
end

local function recibir(quien)
	quien:SetAttribute("EnCueva", false)
end

cueva:SetAttribute("MaxVidaGuardian", MAX_VIDA)
cueva:SetAttribute("TitularExpedicion", nil)
restablecerArena()
Players.PlayerAdded:Connect(recibir)
Players.PlayerRemoving:Connect(liberar)
for _, conectado in Players:GetPlayers() do recibir(conectado) end

while true do
	local dt = math.min(task.wait(0.055), 0.115)
	local titular = jugador
	if not titular then continue end
	local root, h = avatar(titular)
	if not root or titular.Character ~= personajeDelTurno or not titular:GetAttribute("EnCueva") then
		liberar(titular)
		continue
	end
	local t = reloj()
	animarGeoda(t)
	seguirMolino.ActionText = if faltaRelevo(titular) then "Ir al relevo del Farero" else "Seguir al Molino"
	seguirMolino.Enabled = not descubrir.Enabled and fase ~= "Combate" and fase ~= "Presentacion" and fase ~= "Gana"
		and titular:GetAttribute("MiradorGeoda") == true and tienePedernal
	if tienePedernal then mostrarEscudo(root, t) end
	if fase == "Presentacion" then
		if t >= hasta then
			entrarEnCombate()
		else
			local progreso = math.clamp((t - inicioAtaque) / DURACION_INTRO, 0, 1)
			local agachado = (1 - math.min(progreso / 0.65, 1)) ^ 2
			local golpe = math.max(0, 1 - math.abs(progreso - 0.68) / 0.12)
			local cuerpo = CFrame.lookAt(posicion, posicion + direccion) * CFrame.new(0, -1.35 * agachado - golpe * 0.54, 0)
			guardian:PivotTo(cuerpo * CFrame.Angles(math.rad(-15 * agachado - 7 * golpe), 0, 0))
			visual:pose("Presentacion", progreso)
		end
	elseif fase == "Combate" then
		jugarCombate(root, h, dt, t)
	elseif tienePedernal then
		actualizarSalida(root, h, t, dt)
	end
	if jugador == titular then acompanar(root) end
end
