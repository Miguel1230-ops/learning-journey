-- Controles y guía contextual de la expedición a la Geoda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Controles = require(ReplicatedStorage:WaitForChild("ControlesCombate"))
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")
local cueva = workspace:WaitForChild("CuevaDeLaGeoda")
local guardian = cueva:WaitForChild("Guardian")
local cristal = guardian:WaitForChild("CristalEspalda")
local puerta = cueva:WaitForChild("Ruta"):WaitForChild("PuertaViento")
local accion = ReplicatedStorage:WaitForChild("AccionGeoda")

local CARBON = Color3.fromRGB(17, 39, 53)
local MENTA = Color3.fromRGB(142, 225, 201)
local AMATISTA = Color3.fromRGB(194, 161, 244)
-- Mismas distancias, altura y orientación que valida Guardian.server.luau.
local DISTANCIA_COMETA_MINIMA = 0.2
local DISTANCIA_COMETA = 26
local DISTANCIA_CRISTAL = 8
local LIMITE_DEL_FRENTE = 0.35

local gui = Instance.new("ScreenGui")
gui.Name = "CuevaDeLaGeodaHUD"
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = playerGui

-- El portal está en el refugio, fuera del HUD de la cueva.
local guiPortal = Instance.new("ScreenGui")
guiPortal.Name = "AvisoPortalGeoda"
guiPortal.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
guiPortal.ResetOnSpawn = false
guiPortal.Enabled = false
guiPortal.Parent = playerGui
local cartelPortal = UI.objetivo(guiPortal, {ancho = 330, posicion = UDim2.new(.5, 0, .70, 0)})
cartelPortal.marco.AnchorPoint = Vector2.new(.5, .5)
local avisoPortal = 0
accion.OnClientEvent:Connect(function(evento, mensaje)
	if evento ~= "AvisoPortal" or typeof(mensaje) ~= "string" then return end
	avisoPortal += 1
	local actual = avisoPortal
	cartelPortal:actualizar("Geoda", "Portal de la Geoda", mensaje)
	guiPortal.Enabled = true
	task.delay(3.3, function()
		if actual == avisoPortal then guiPortal.Enabled = false end
	end)
end)

local objetivo = UI.objetivo(gui, {ancho = 322})
local acciones = UI.acciones(gui)

-- La marca sigue al cristal. Sólo aparece durante la apertura real del Guardián.
local marcador = Instance.new("BillboardGui")
marcador.Name = "CristalExpuesto"
marcador.Adornee = cristal
marcador.Size = UDim2.fromOffset(43, 38)
marcador.StudsOffsetWorldSpace = Vector3.new(0, 2.1, 0)
marcador.MaxDistance = 42
marcador.AlwaysOnTop = true
marcador.Enabled = false
marcador.Parent = playerGui
local disco = Instance.new("Frame")
disco.Name = "Abertura"
disco.Position = UDim2.fromOffset(4, 0)
disco.Size = UDim2.fromOffset(34, 34)
disco.BackgroundColor3 = CARBON
disco.BorderSizePixel = 0
disco.Parent = marcador
local curva = Instance.new("UICorner")
curva.CornerRadius = UDim.new(1, 0)
curva.Parent = disco
local anillo = Instance.new("UIStroke")
anillo.Thickness = 2
anillo.Color = AMATISTA
anillo.Parent = disco
UI.icono(disco, "Geoda", 24, AMATISTA, UDim2.fromOffset(5, 5))

local function actualizarPantallas()
	local dentro = jugador:GetAttribute("EnCueva") == true
	if dentro then guiPortal.Enabled = false end
	gui.Enabled = dentro and not jugador:GetAttribute("GeodaPresentando") and not jugador:GetAttribute("BitacoraAbierta")
	if not gui.Enabled then marcador.Enabled = false end
end
jugador:GetAttributeChangedSignal("EnCueva"):Connect(actualizarPantallas)
jugador:GetAttributeChangedSignal("GeodaPresentando"):Connect(actualizarPantallas)
jugador:GetAttributeChangedSignal("BitacoraAbierta"):Connect(actualizarPantallas)
actualizarPantallas()

local function enCombate()
	return cueva:GetAttribute("Fase") == "Combate"
end

local ultimaOrden = -1
local function enviar(tipo)
	if not gui.Enabled then
		return
	end
	local tiempo = os.clock()
	if tiempo - ultimaOrden >= 0.12 then
		ultimaOrden = tiempo
		accion:FireServer(tipo)
	end
end

local function rafaga()
	if enCombate() and (jugador:GetAttribute("PulsoCuevaListoEn") or 0) <= workspace:GetServerTimeNow() then
		enviar("GolpeBaston")
	end
end

local function companero()
	local ahora = workspace:GetServerTimeNow()
	if enCombate() then
		if (jugador:GetAttribute("OrdenCometaListaEn") or 0) <= ahora then
			enviar("Cometa")
		end
	end
end

local function escudoRevancha()
	return jugador:GetAttribute("EnCueva") and gui.Enabled and jugador:GetAttribute("Pedernal") == true
end

local function proteger()
	local ahora = workspace:GetServerTimeNow()
	if escudoRevancha() and (jugador:GetAttribute("EscudoHasta") or 0) <= ahora
		and (not enCombate() or (jugador:GetAttribute("EscudoCombateListoEn") or 0) <= ahora) then
		enviar("Escudo")
	end
end

Controles.ataque(function() return gui.Enabled and enCombate() end, rafaga)
Controles.escudoBreve(escudoRevancha, proteger)

local function vincular(nombre, responder, disponible, ...)
	ContextActionService:BindActionAtPriority(nombre, function(_, entrada)
		if jugador:GetAttribute("EnCueva") ~= true or UserInputService:GetFocusedTextBox() or jugador:GetAttribute("BitacoraAbierta") then
			return Enum.ContextActionResult.Pass
		end
		if jugador:GetAttribute("GeodaPresentando") then
			return Enum.ContextActionResult.Sink
		end
		if not disponible() then
			return Enum.ContextActionResult.Pass
		end
		if entrada == Enum.UserInputState.Begin then
			responder()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value, ...)
end
vincular("GeodaBaston", rafaga, enCombate, Enum.KeyCode.ButtonX)
vincular("GeodaCompanero", companero, enCombate, Enum.KeyCode.C, Enum.KeyCode.ButtonY)
vincular("GeodaEscudoRevancha", proteger, escudoRevancha, Enum.KeyCode.R, Enum.KeyCode.ButtonL1)
local function plano(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function raizViva()
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if humanoide and humanoide.Health > 0 then
		return personaje:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function posiciones(root)
	local base = guardian.PrimaryPart
	if not root or not base then
		return false, false, false
	end
	local lado = plano(root.Position - base.Position)
	local frente = plano(guardian:GetPivot().LookVector)
	if frente.Magnitude > 0.1 then
		frente = frente.Unit
	end
	local espalda = lado.Magnitude <= 0.1 or frente:Dot(lado.Unit) <= LIMITE_DEL_FRENTE
	return lado.Magnitude >= DISTANCIA_COMETA_MINIMA and lado.Magnitude <= DISTANCIA_COMETA,
		(root.Position - cristal.Position).Magnitude <= DISTANCIA_CRISTAL,
		espalda
end

local transcurrido = 0
RunService.Heartbeat:Connect(function(dt)
	if not gui.Enabled then
		return
	end
	transcurrido += dt
	if transcurrido < 0.065 then
		return
	end
	transcurrido = 0
	local fase = cueva:GetAttribute("Fase") or "Inicio"
	local ataque = cueva:GetAttribute("EstadoGuardian")
	local mensaje = cueva:GetAttribute("Titulo")
	local combate = fase == "Combate"
	local pedernal = jugador:GetAttribute("Pedernal") == true
	local reloj = workspace:GetServerTimeNow()
	local listo = (jugador:GetAttribute("PulsoCuevaListoEn") or 0) <= reloj
	local aliadoListo = (jugador:GetAttribute("OrdenCometaListaEn") or 0) <= reloj
	local escudo = math.max(0, (jugador:GetAttribute("EscudoHasta") or 0) - reloj)
	local recargaEscudo = math.max(0, (jugador:GetAttribute("EscudoCombateListoEn") or 0) - reloj)
	local mando = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
	local tactil = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	local root = raizViva()
	local cometaCerca, cristalCerca, detras = posiciones(root)
	local puedeLlamar = combate and ataque == "Aviso" and cometaCerca and aliadoListo
	local haciaCristal = root and plano(cristal.Position-root.Position)
	local apuntando = haciaCristal and (haciaCristal.Magnitude < .65 or root.CFrame.LookVector:Dot(haciaCristal.Unit) >= .34)
	local puedeGolpear = combate and ataque == "Expuesto" and cristalCerca and detras and apuntando and listo
	local distanciaPuerta = root and puerta.CFrame:PointToObjectSpace(root.Position)
	local juntoViento = distanciaPuerta and math.abs(distanciaPuerta.X) <= 10
		and math.abs(distanciaPuerta.Y) <= 6 and math.abs(distanciaPuerta.Z) <= 8
	local cruzado = distanciaPuerta and distanciaPuerta.X > 4
	local vida = math.clamp(cueva:GetAttribute("VidaGuardian") or 3, 0, 3)

	marcador.Enabled = combate and ataque == "Expuesto"
	anillo.Color = if puedeGolpear then MENTA else AMATISTA

	local titulo = mensaje or "Cueva de la Geoda"
	local pista = cueva:GetAttribute("Pista") or ""
	local simbolo = "Geoda"
	if puedeLlamar then
		simbolo, titulo, pista = "Eco", "Llama a Cometa", "Distrae al Guardián o atrae su carga hacia la columna."
	elseif puedeGolpear then
		simbolo, titulo, pista = "Baston", "Golpea el cristal", "Estás a su espalda. Ataca antes de que se cierre."
	elseif combate and (ataque == "PrepararBarrido" or ataque == "Barrido") then
		if escudo > 0 then
			simbolo, titulo, pista = "Escudo", "Pedernal te cubre", "El escudo detiene la hoja de cristal."
		elseif pedernal and recargaEscudo <= 0 then
			simbolo, titulo, pista = "Escudo", "¡Barrido de cristal!", "Usa el escudo o salta cuando la hoja llegue a tus pies."
		else
			simbolo, titulo, pista = "Salto", "¡Barrido de cristal!", "Observa el puño violeta. Salta la hoja o pasa detrás del Guardián."
		end
	elseif combate and ataque == "Aviso" then
		titulo, pista = "¡Va a cargar!", "Esquiva hacia un lado o llévalo a la columna agrietada."
	elseif combate and ataque == "Embestida" then
		titulo, pista = "Sal de su trayectoria", "Deja pasar la embestida y rodea al Guardián."
	elseif combate and ataque == "SigueACometa" then
		simbolo, titulo, pista = "Eco", "Persigue a Cometa", "Rodea al Guardián mientras se distrae."
	elseif combate and ataque == "Expuesto" then
		if not cristalCerca then
			titulo, pista = "Cristal expuesto", "Acércate a la marca violeta en su espalda."
		elseif not detras then
			titulo, pista = "Rodéalo", "El cristal se abre por la espalda."
		elseif not apuntando then
			titulo, pista = "Apunta al cristal", "Gira hacia la abertura para conectar el golpe."
		else
			simbolo, titulo, pista = "Baston", "Recupera el bastón", "Mantente cerca para poder golpear."
		end
	elseif combate and ataque == "Recupera" and mensaje == "¡Rompiste una capa de armadura!" then
		titulo, pista = "Armadura fracturada", "Toma distancia antes de la siguiente carga."
	elseif combate and mensaje == "El bastón chocó con la armadura" then
		titulo, pista = "El golpe rebotó", "Distráelo para descubrir el cristal de su espalda."
	elseif combate and ataque == "Acecha" then
		titulo, pista = "Atrae al Guardián", "Coloca la columna entre su carga y tu siguiente paso."
	elseif fase == "Salida" then
		if cruzado then
			titulo = if cueva:GetAttribute("SelloEncendido") then "Sello de Rebote encendido" else "Mirador de la Geoda"
			pista = "Sigue el camino y enciende la baliza."
		elseif juntoViento and escudo > 0 then
			simbolo, titulo, pista = "Escudo", "Escudo activo", "Cruza ahora el pasadizo azul."
		else
			simbolo, titulo, pista = "Viento", "Pasadizo de viento", "Sigue la luz azul y levanta el escudo al acercarte."
		end
	end
	local detalle = if combate then ("Guardián de la Geoda   ·   %d/3 cristales"):format(vida) else nil
	objetivo:actualizar(simbolo, titulo, pista, detalle, if combate then vida / 3 else nil)

	local lista = {}
	if combate then
		local recarga = math.max(0, (jugador:GetAttribute("PulsoCuevaListoEn") or 0) - reloj)
		table.insert(lista, {icono = "Baston", texto = if listo then "Golpear" else "Recargando",
			tecla = if tactil then "" elseif mando then "X" else "M1", activar = rafaga,
			progreso = if recarga > 0 then math.clamp(1 - recarga / .83, 0, 1) else nil})
		if ataque == "Aviso" and cometaCerca then
			table.insert(lista, {icono = "Eco", texto = if aliadoListo then "Llamar" else "Recargando",
				tecla = if tactil then "" elseif mando then "Y" else "C", activar = companero})
		end
	end
	if pedernal and (combate or fase == "Salida" or juntoViento) then
		local texto = if escudo > 0 then "Protegido" elseif recargaEscudo > 0 then ("%.1f s"):format(recargaEscudo) else "Escudo"
		table.insert(lista, {icono = "Escudo", texto = texto, activar = proteger,
			tecla = if tactil then "" elseif mando then "L1" else "M2"})
	end
	acciones:actualizar(lista)
	acciones:visible(#lista > 0)
end)
