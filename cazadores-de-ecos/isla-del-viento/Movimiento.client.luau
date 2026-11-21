-- Controles y movimiento del jugador en la prueba Isla del Viento.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Prompts = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jugador = Players.LocalPlayer
local isla = workspace:WaitForChild("IslaDelViento")
local ruta = isla:WaitForChild("Rutas")
local accion = ReplicatedStorage:WaitForChild("AccionViento")
local Planeadores = require(ReplicatedStorage:WaitForChild("Planeadores"))
local RutaIslas = require(ReplicatedStorage:WaitForChild("RutaIslas"))
local Controles = require(ReplicatedStorage:WaitForChild("ControlesCombate"))
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local accionFaro = ReplicatedStorage:WaitForChild("AccionFaro")
local gui = Instance.new("ScreenGui")
gui.Name = "IslaDelVientoHUD"
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ResetOnSpawn = false
gui.Parent = jugador:WaitForChild("PlayerGui")

local function fueraDelRecorrido()
	return jugador:GetAttribute("EnCueva") or jugador:GetAttribute("EnMolino") or jugador:GetAttribute("EnFaro")
		or jugador:GetAttribute("MolinoPresentando") or jugador:GetAttribute("FaroPresentando")
end

local function verInterfazIsla()
	gui.Enabled = not fueraDelRecorrido() and not jugador:GetAttribute("EnEncargoPedernal")
		and not jugador:GetAttribute("FareroConversando") and not jugador:GetAttribute("BitacoraAbierta")
end
for _, nombre in ipairs({ "EnCueva", "EnMolino", "EnEncargoPedernal", "EnFaro", "FaroPresentando", "MolinoPresentando", "FareroConversando", "BitacoraAbierta" }) do
	jugador:GetAttributeChangedSignal(nombre):Connect(verInterfazIsla)
end
verInterfazIsla()

local objetivo = UI.objetivo(gui)
local acciones = UI.acciones(gui)

-- En el salto de Nimbo el HUD de la isla está oculto; plegar sigue disponible en pantalla táctil.
local controlesFaro = Instance.new("ScreenGui")
controlesFaro.Name = "ControlPlaneoFaro"
controlesFaro.ResetOnSpawn = false
controlesFaro.ScreenInsets = gui.ScreenInsets
controlesFaro.DisplayOrder = 12
controlesFaro.Enabled = false
controlesFaro.Parent = jugador.PlayerGui
local planeoTorre = UI.acciones(controlesFaro)

local root
local humanoide
local vuelo
local planeador
local accionUsadaEnAire = false
local ultimoPulsoLocal = -10
local mostrarHasta = 0
local ABRIR_ALAS = 0.20
local PLEGAR_ALAS = 0.23

local function quitarPlaneador()
	if planeador then
		planeador.modelo:Destroy()
		planeador = nil
	end
end

local function acabarPlaneo(plegar)
	if vuelo then
		vuelo = nil
		jugador:SetAttribute("PlaneandoLocal", false)
	end
	if planeador and plegar then
		planeador.plegando = os.clock()
		planeador.desde = math.clamp((planeador.plegando - planeador.inicio) / ABRIR_ALAS, 0, 1)
	else
		quitarPlaneador()
	end
end

local function leerPersonaje(personaje)
	local parte = personaje:WaitForChild("HumanoidRootPart", 10)
	local controlador = personaje:WaitForChild("Humanoid", 10)
	if personaje ~= jugador.Character then
		return
	end
	acabarPlaneo(false)
	root, humanoide = parte, controlador
	accionUsadaEnAire = false
	jugador:SetAttribute("PlaneandoLocal", false)
end

jugador.CharacterAdded:Connect(leerPersonaje)
jugador.CharacterRemoving:Connect(function(personaje)
	if root and root.Parent == personaje then
		acabarPlaneo(false)
		root, humanoide = nil, nil
	end
end)
if jugador.Character then
	task.spawn(leerPersonaje, jugador.Character)
end

local function horizontal(v)
	return Vector3.new(v.X, 0, v.Z)
end

local aro = ruta:WaitForChild("ZonaAro")
local columna = ruta:WaitForChild("ZonaAscenso")
local salida = ruta:WaitForChild("AlturaSalida")
local baliza = ruta:WaitForChild("Baliza")
local tramo = horizontal(salida.Position - aro.Position)
local largoTramo = math.max(tramo.Magnitude, 0.01)
local rumboTramo = tramo / largoTramo
local rumboSalida = horizontal(baliza.Position - salida.Position).Unit
local anchoTramo = math.min(columna.Size.X, columna.Size.Z) * 0.5

local function enCorriente(admitirEntrada)
	if not root or not jugador:GetAttribute("Vendaval") then
		return nil
	end
	local pos = root.Position
	local d = columna.CFrame:PointToObjectSpace(pos)
	local t = columna.Size / 2
	if math.abs(d.X) <= t.X and math.abs(d.Y) <= t.Y and math.abs(d.Z) <= t.Z then
		return "Columna"
	end
	if not admitirEntrada or pos.Y < columna.Position.Y - t.Y or pos.Y > salida.Position.Y + 1 then return nil end
	local delta = horizontal(pos - aro.Position)
	local avance = delta:Dot(rumboTramo)
	if avance >= -1 and avance <= largoTramo and (delta - rumboTramo * avance).Magnitude <= anchoTramo then
		return "Entrada", math.clamp(avance / largoTramo, 0, 1)
	end
	local alSalir = horizontal(pos - salida.Position)
	local proyeccion = alSalir:Dot(rumboSalida)
	if pos.Y >= salida.Position.Y - 7 and proyeccion >= 0 and proyeccion <= anchoTramo * 1.66
		and (alSalir - rumboSalida * proyeccion).Magnitude <= anchoTramo then
		return "Columna"
	end
	return nil
end

local function rafaga()
	local fase = jugador:GetAttribute("FaseNido")
	if fase ~= "Inicio" and fase ~= "Perdido" and fase ~= "Defensa" then
		return
	end
	if os.clock() - ultimoPulsoLocal >= 0.17 and (jugador:GetAttribute("RafagaListaEn") or 0) <= workspace:GetServerTimeNow() then
		ultimoPulsoLocal = os.clock()
		accion:FireServer("GolpeBaston")
	end
end
Controles.ataque(function() return gui.Enabled and not fueraDelRecorrido() end, rafaga)

local function fueraDePlaneo()
	local fase = jugador:GetAttribute("RescateNimbo")
	return fueraDelRecorrido() and not (jugador:GetAttribute("EnFaro") and (fase == "Vuelo" or fase == "Caida"))
end

local function iniciarPlaneo(desdeTorre)
	if not jugador:GetAttribute("Cometa") or (not desdeTorre and fueraDelRecorrido())
		or not root or not humanoide or humanoide.Health <= 0 or vuelo then
		return
	end
	local impulso = enCorriente()
	if not desdeTorre and (accionUsadaEnAire or (not impulso and humanoide.FloorMaterial ~= Enum.Material.Air)) then
		mostrarHasta = os.clock() + 1
		return
	end

	local direccion = if desdeTorre then Vector3.xAxis else horizontal(humanoide.MoveDirection)
	if direccion.Magnitude < 0.1 then
		direccion = horizontal(root.CFrame.LookVector)
	end
	if direccion.Magnitude < 0.1 then
		direccion = Vector3.xAxis
	end
	local mejorado = jugador:GetAttribute("PlaneadorEquipado") == "Avanzado" and jugador:GetAttribute("PlaneadorAvanzado") == true
	local ajustes = Planeadores.ajustes(mejorado)
	vuelo = {
		inicio = os.clock(), direccion = direccion.Unit, ajustes = ajustes,
		restante = ajustes.duracion, desdeTorre = desdeTorre == true,
		empujeAlCoronar = if mejorado then 18 else 27,
	}
	quitarPlaneador()
	planeador = Planeadores.crear(mejorado)
	planeador.inicio = vuelo.inicio
	planeador.direccion = vuelo.direccion
	planeador.banco = 0
	Planeadores.colocar(planeador, root.Position, vuelo.direccion, 0, 0)
	planeador.modelo.Parent = workspace
	accionUsadaEnAire = true
	jugador:SetAttribute("PlaneandoLocal", true)
	if not desdeTorre then accion:FireServer("Planeo") end
	if impulso then
		humanoide:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end

ReplicatedStorage:WaitForChild("AccionFaro").OnClientEvent:Connect(function(evento, origen)
	if evento == "ReintentarLlegada" then
		acabarPlaneo(false)
		accionUsadaEnAire = false
		return
	end
	if evento ~= "VueloNimbo" or not root then return end
	if jugador:GetAttribute("RescateNimbo") ~= "Vuelo" then
		local limite = os.clock() + 1
		repeat task.wait() until jugador:GetAttribute("RescateNimbo") == "Vuelo" or os.clock() >= limite
	end
	if jugador:GetAttribute("RescateNimbo") ~= "Vuelo" or not root then return end
	root.Parent:PivotTo(CFrame.lookAt(origen, origen + Vector3.xAxis))
	root.AssemblyLinearVelocity = Vector3.zero
	humanoide:ChangeState(Enum.HumanoidStateType.Freefall)
	iniciarPlaneo(true)
end)

local avisosX = {}
Prompts.PromptShown:Connect(function(p)
	if p.GamepadKeyCode == Enum.KeyCode.ButtonX then avisosX[p] = true end
end)
Prompts.PromptHidden:Connect(function(p) avisosX[p] = nil end)
local function hayInteraccionX()
	for p in avisosX do
		if p.Enabled and p.Parent and p.MaxActivationDistance > 0 then return true end
	end
	return false
end
ContextActionService:BindAction("VientoRafaga", function(_, entrada)
	local fase = jugador:GetAttribute("FaseNido")
	if not gui.Enabled or UIS:GetFocusedTextBox() or (fase ~= "Inicio" and fase ~= "Defensa" and fase ~= "Perdido")
		or (fase ~= "Defensa" and hayInteraccionX()) then return Enum.ContextActionResult.Pass end
	if entrada == Enum.UserInputState.Begin then rafaga() end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.ButtonX)
local function alternarPlaneo()
	if vuelo then
		acabarPlaneo(true)
		if jugador:GetAttribute("EnFaro") then
			accionFaro:FireServer("PlegarNimbo")
		else
			accion:FireServer("PlegarPlaneo")
		end
	elseif not fueraDelRecorrido() then
		iniciarPlaneo(false)
	end
end

ContextActionService:BindAction("VientoPlano", function(_, estado)
	if UIS:GetFocusedTextBox() or jugador:GetAttribute("BitacoraAbierta")
		or (not vuelo and (not gui.Enabled or not jugador:GetAttribute("Cometa"))) then
		return Enum.ContextActionResult.Pass
	end
	if estado == Enum.UserInputState.Begin then alternarPlaneo() end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
local function mostrarPlegadoTorre()
	controlesFaro.Enabled = UIS.PreferredInput == Enum.PreferredInput.Touch and jugador:GetAttribute("EnFaro") == true
		and jugador:GetAttribute("PlaneandoLocal") == true and not jugador:GetAttribute("BitacoraAbierta")
	if controlesFaro.Enabled then
		planeoTorre:actualizar({{icono = "Ala", texto = "Plegar", tecla = "", activar = alternarPlaneo}})
	end
end
jugador:GetAttributeChangedSignal("EnFaro"):Connect(mostrarPlegadoTorre)
jugador:GetAttributeChangedSignal("PlaneandoLocal"):Connect(mostrarPlegadoTorre)
jugador:GetAttributeChangedSignal("BitacoraAbierta"):Connect(mostrarPlegadoTorre)
UIS:GetPropertyChangedSignal("PreferredInput"):Connect(mostrarPlegadoTorre)
mostrarPlegadoTorre()

RunService.PreSimulation:Connect(function(dt)
	if not root or not humanoide or humanoide.Health <= 0 or fueraDePlaneo() then
		acabarPlaneo(false)
		return
	end
	local enSuelo = humanoide.FloorMaterial ~= Enum.Material.Air
	if not vuelo then
		if enSuelo then
			accionUsadaEnAire = false
		end
		return
	end

	local tiempo = os.clock() - vuelo.inicio
	local elevando, fraccion
	if not vuelo.desdeTorre and not vuelo.corono and root.Position.Y < salida.Position.Y then
		elevando, fraccion = enCorriente(true)
	end
	if not elevando then vuelo.restante -= dt end
	if vuelo.restante <= 0 or (enSuelo and not elevando and tiempo > 0.22) then
		acabarPlaneo(true)
		return
	end

	local velocidad = root.AssemblyLinearVelocity
	local mando = horizontal(humanoide.MoveDirection)
	local banco = 0
	if mando.Magnitude > 0.14 then
		banco = math.clamp(vuelo.direccion:Cross(mando.Unit).Y * 0.26, -0.24, 0.24)
		local giro = vuelo.direccion:Lerp(mando.Unit, math.min(dt * vuelo.ajustes.giro, 1))
		vuelo.direccion = if giro.Magnitude > 0.05 then giro.Unit else mando.Unit
	end

	local movimiento
	local y
	if elevando then
		if not vuelo.sintioCorriente then
			vuelo.sintioCorriente = true
			vuelo.restante = math.max(vuelo.restante, 2)
		end
		-- La brisa empuja en una dirección, así que una desviación lateral sigue siendo una salida real.
		local entrada = elevando == "Entrada"
		local rumbo = if entrada then rumboTramo else rumboSalida
		local empuje = if entrada then 15 else 8
		local sosten = 27
		if entrada then
			local cota = aro.Position.Y + 2 + (salida.Position.Y - aro.Position.Y - 5) * fraccion
			sosten = math.clamp((cota - root.Position.Y) * 3 + 3, 0, 20)
		end
		local previo = vuelo.ascenso or math.clamp(velocidad.Y, -8, 27)
		vuelo.ascenso = previo + math.clamp(sosten - previo, -dt * 72, dt * 96)
		y = vuelo.ascenso
		local corriente = rumbo * empuje + mando * 12
		movimiento = (vuelo.vientoHorizontal or horizontal(velocidad)):Lerp(corriente, 1 - math.exp(-dt * 12))
		vuelo.vientoHorizontal = movimiento
		if mando.Magnitude <= 0.14 then
			local giro = vuelo.direccion:Lerp(rumbo, math.min(dt * 5, 1))
			if giro.Magnitude > 0.05 then vuelo.direccion = giro.Unit end
		end
	else
		y = math.max(velocidad.Y, -4.4)
		if vuelo.ascenso and root.Position.Y >= salida.Position.Y then
			vuelo.corono = true
			-- El ala rápida sale con una trayectoria más rasa sobre la cornisa.
			y = math.min(y, vuelo.empujeAlCoronar)
		end
		vuelo.ascenso = nil
		vuelo.vientoHorizontal = nil
		movimiento = vuelo.direccion * vuelo.ajustes.velocidad
	end
	planeador.banco += (banco - planeador.banco) * math.min(dt * 9, 1)
	planeador.direccion = vuelo.direccion
	root.AssemblyLinearVelocity = Vector3.new(movimiento.X, y, movimiento.Z)
end)

RunService.PreRender:Connect(function()
	if not planeador or not root or fueraDePlaneo() then
		return
	end
	local t = os.clock()
	local apertura = math.clamp((t - planeador.inicio) / ABRIR_ALAS, 0, 1)
	if planeador.plegando then
		apertura = planeador.desde * math.max(0, 1 - (t - planeador.plegando) / PLEGAR_ALAS)
		if apertura <= 0 then
			quitarPlaneador()
			return
		end
	end
	local camara = workspace.CurrentCamera
	local cerca = camara and (camara.CFrame.Position - root.Position).Magnitude < 2.7
	if cerca then
		if planeador.modelo.Parent then
			planeador.modelo.Parent = nil
		end
		return
	end
	Planeadores.colocar(planeador, root.Position, planeador.direccion, apertura * apertura * (3 - 2 * apertura), planeador.banco)
	if not planeador.modelo.Parent then
		planeador.modelo.Parent = workspace
	end
end)

local destino, indicacion
local hito = {
	Inicio = "Nido", Aro = "Ala", Cornisa = "Viento", Refugio = "Brujula",
	Taller = "Escudo", Relevo = "Chispa", Farero = "Faro", Geoda = "Geoda", Molino = "Molino",
	Consulta = "Faro", Revancha = "Geoda", Faro = "Faro", Nido = "Nimbo", Libre = "Brujula",
}
local geoda = Color3.fromRGB(194, 161, 244)
local menta = Color3.fromRGB(142, 225, 201)
local tinta = Color3.fromRGB(17, 39, 53)
local guia = Instance.new("BillboardGui")
guia.Name = "DestinoRuta"
guia.Size = UDim2.fromOffset(42, 46)
guia.StudsOffsetWorldSpace = Vector3.new(0, 3.7, 0)
guia.AlwaysOnTop = true
guia.Enabled = false
guia.Parent = jugador.PlayerGui
local insignia = Instance.new("Frame")
insignia.Name = "Hito"
insignia.AnchorPoint = Vector2.new(.5, 0)
insignia.Position = UDim2.fromScale(.5, 0)
insignia.Size = UDim2.fromOffset(34, 34)
insignia.BackgroundColor3 = tinta
insignia.BorderSizePixel = 0
insignia.Parent = guia
local curva = Instance.new("UICorner")
curva.CornerRadius = UDim.new(1, 0)
curva.Parent = insignia
local bisel = Instance.new("UIStroke")
bisel.Thickness = 1.6
bisel.Parent = insignia
local punta = Instance.new("Frame")
punta.Size = UDim2.fromOffset(5, 5)
punta.Rotation = 45
punta.AnchorPoint = Vector2.new(.5, 0)
punta.Position = UDim2.new(.5, 0, 0, 39)
punta.BorderSizePixel = 0
punta.Parent = guia
local glifo, simboloActual
local function orientarMarca()
if destino == "Inicio" then
		local nido = isla:FindFirstChild("Nido")
		guia.Adornee = if jugador:GetAttribute("FaseNido") == "Rescate" and nido then nido:FindFirstChild("PuntoRescate") else isla:FindFirstChild("Totem")
	elseif destino == "Aro" then guia.Adornee = ruta:FindFirstChild("ZonaAro")
	elseif destino == "Cornisa" then guia.Adornee = ruta:FindFirstChild("Baliza")
	elseif destino == "Refugio" then guia.Adornee = ruta:FindFirstChild("Refugio")
	elseif destino == "Geoda" or destino == "Revancha" then guia.Adornee = ruta:FindFirstChild("PortalDeLaGeoda")
	elseif destino == "Molino" then
		local molino = isla:FindFirstChild("MolinoDelViento")
		guia.Adornee = molino and molino:FindFirstChild("PlayaDespegue")
	elseif destino == "Relevo" or destino == "Taller" or destino == "Farero" or destino == "Consulta" or destino == "Faro" or destino == "Nido" then
		local refugio = isla:FindFirstChild("RefugioDelViento")
		guia.Adornee = refugio and refugio:FindFirstChild(if destino == "Relevo" then "InicioEncargo" else "PuntoFarero")
	else guia.Adornee = nil end
end
local function actualizarRuta()
destino, indicacion = RutaIslas.destino(jugador)
	local simbolo = hito[destino] or "Brujula"
	if simboloActual ~= simbolo then
		simboloActual = simbolo
		if glifo then glifo:Destroy() end
		local tono = if simbolo == "Geoda" then geoda else menta
		glifo = UI.icono(insignia, simbolo, 22, tono, UDim2.fromOffset(6, 6))
		bisel.Color, punta.BackgroundColor3 = tono, tono
	end
	orientarMarca()
end
ruta.ChildAdded:Connect(orientarMarca)
jugador:GetAttributeChangedSignal("FaseNido"):Connect(orientarMarca)
gui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not gui.Enabled then guia.Enabled = false end
end)
for _, atributo in {"Cometa", "Vendaval", "Cornisa", "Refugio", "ConsejoGeoda", "Pedernal", "Lucero",
	"LenteGeoda", "ConsejoLente", "Prisma", "Nimbo", "MejoraPedernal", "EncargoPedernal", "Nivel", "Monedas"} do
	jugador:GetAttributeChangedSignal(atributo):Connect(actualizarRuta)
end
actualizarRuta()

local function saltar()
	if humanoide and humanoide.Health > 0 then humanoide.Jump = true end
end
local tiempoPantalla = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then
		return
	end
	tiempoPantalla += dt
	if tiempoPantalla < 0.095 then
		return
	end
	tiempoPantalla = 0
	local fase = jugador:GetAttribute("FaseNido") or "Inicio"
	local vida = isla:GetAttribute("VidaNido") or 100
	local quedan = isla:GetAttribute("VigiasActivos") or 0
	local rescatado = jugador:GetAttribute("Cometa")
	local recarga = math.max(0, (jugador:GetAttribute("RafagaListaEn") or 0) - workspace:GetServerTimeNow())
	if not guia.Adornee or not guia.Adornee:IsDescendantOf(isla) then orientarMarca() end
	local distancia = if root and guia.Adornee then (root.Position - guia.Adornee.Position).Magnitude else math.huge
	local hudFaro = jugador.PlayerGui:FindFirstChild("RuinasDelFaroHUD")
	local enDespegueMolino = destino == "Molino" and distancia < 13
	local instruccionesPropias = not enDespegueMolino and not (hudFaro and hudFaro.Enabled)
	local defendiendo = destino == "Inicio" and (fase == "Defensa" or fase == "Rescate" or fase == "Perdido")
	local corriente = rescatado and enCorriente(true)
	local titulo = if defendiendo then jugador:GetAttribute("TituloNido") or indicacion[1] else indicacion[1]
	local pista = if defendiendo then jugador:GetAttribute("PistaNido") or indicacion[2] else indicacion[2]
	local detalle, fraccion
	if fase == "Defensa" then
		detalle = ("%d%% de integridad  ·  %d vigías"):format(vida, quedan)
		fraccion = vida / 100
	elseif vuelo and vuelo.ascenso then
		detalle = "Guía el planeador hacia la cornisa"
	elseif corriente then
		detalle = "Vendaval puede elevarte aquí"
	elseif rescatado and os.clock() < mostrarHasta then
		detalle = "Salta para abrir el planeador"
	end
	objetivo:visible(instruccionesPropias)
	if instruccionesPropias then objetivo:actualizar(simboloActual, titulo, pista, detalle, fraccion) end
	guia.Enabled = instruccionesPropias and guia.Adornee ~= nil and distancia > 8 and fase ~= "Defensa"

	local mando = UIS.PreferredInput == Enum.PreferredInput.Gamepad
	local tactil = UIS.PreferredInput == Enum.PreferredInput.Touch
	local lista = {}
	if fase == "Defensa" or (not rescatado and (fase == "Inicio" or fase == "Perdido") and not (mando and hayInteraccionX())) then
		table.insert(lista, {icono = "Baston", texto = if recarga > 0 then "Recargando" else "Golpear",
			tecla = if tactil then "" elseif mando then "X" else "M1", activar = rafaga,
			progreso = if recarga > 0 then math.clamp(1 - recarga / .97, 0, 1) else nil})
	end
	if rescatado and humanoide and humanoide.Health > 0 then
		local enAire = humanoide.FloorMaterial == Enum.Material.Air
		if vuelo or corriente == "Columna" or (enAire and not accionUsadaEnAire) then
			table.insert(lista, {icono = if corriente and not vuelo then "Viento" else "Ala",
				tecla = if tactil then "" elseif mando then "Y" else "F",
				texto = if vuelo then "Plegar" elseif corriente == "Columna" then "Ascender" else "Planear",
				activar = alternarPlaneo})
		elseif (destino == "Aro" or destino == "Cornisa" or enDespegueMolino or corriente) and not enAire then
			table.insert(lista, {icono = "Salto", texto = "Saltar", activar = saltar,
				tecla = if tactil then "" elseif mando then "A" else "Espacio"})
		end
	end
	acciones:actualizar(lista)
	acciones:visible(#lista > 0)
end)
