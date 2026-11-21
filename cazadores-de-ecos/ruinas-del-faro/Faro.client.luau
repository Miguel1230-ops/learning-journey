local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer
local faro = workspace:WaitForChild("IslaDelViento"):WaitForChild("RuinasDelFaro")
local accion = ReplicatedStorage:WaitForChild("AccionFaro")
local refugio = ReplicatedStorage:WaitForChild("AccionRefugio")
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local gui = Instance.new("ScreenGui")
gui.Name = "RuinasDelFaroHUD"
gui.ResetOnSpawn = false
gui.DisplayOrder = 11
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Enabled = false
gui.Parent = jugador:WaitForChild("PlayerGui")
local ficha = UI.objetivo(gui)
local acciones = UI.acciones(gui)

local function raiz()
	local c = jugador.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return if h and h.Health > 0 then c:FindFirstChild("HumanoidRootPart") else nil
end

local function cercaDelRastro(root)
	return root and jugador:GetAttribute("EnFaro") and faro:GetAttribute("TitularExpedicion") == jugador.UserId
		and not faro:GetAttribute("RastroRevelado")
		and (root.Position - faro.Rastro.Position).Magnitude <= 13
end

local espejos = {}
for _, soporte in {faro.Girar, faro.Montura, faro.Prisma} do
	table.insert(espejos, soporte:WaitForChild("Accion"))
end
local accesoLosa = faro.Rastro:WaitForChild("Accion")
local accesoCamara = faro.Prisma:WaitForChild("CaminoDePrisma")
local regreso = faro.Regreso:WaitForChild("Accion")
local salida = faro.SalidaTerraza:WaitForChild("Accion")
local function actualizarAccesos()
	local dentro = jugador:GetAttribute("EnFaro") == true
	local titular = dentro and faro:GetAttribute("TitularExpedicion") == jugador.UserId
	local viaPrisma = dentro and jugador:GetAttribute("Prisma") == true and jugador:GetAttribute("FaroEncendido") == true
	for _, prompt in espejos do
		prompt.Enabled = titular and prompt:GetAttribute("Disponible") == true
	end
	accesoLosa.Enabled, accesoCamara.Enabled = viaPrisma, viaPrisma
	regreso.Enabled = dentro
	salida.Enabled = viaPrisma or (titular and faro:GetAttribute("RastroRevelado") == true)
end
for _, prompt in espejos do
	prompt:GetAttributeChangedSignal("Disponible"):Connect(actualizarAccesos)
	prompt:GetPropertyChangedSignal("Enabled"):Connect(actualizarAccesos)
end
for _, atributo in {"EnFaro", "Prisma", "FaroEncendido"} do
	jugador:GetAttributeChangedSignal(atributo):Connect(actualizarAccesos)
end
faro:GetAttributeChangedSignal("TitularExpedicion"):Connect(actualizarAccesos)
faro:GetAttributeChangedSignal("RastroRevelado"):Connect(actualizarAccesos)
actualizarAccesos()

-- La luz que alguien ya ganó sigue viéndose desde su torre cuando el
-- siguiente turno vuelve a preparar el espejo para otro explorador.
local linterna = faro:WaitForChild("Linterna")
local haz = linterna:WaitForChild("HazDelMolino")
local cristalPropio = linterna:Clone()
cristalPropio:ClearAllChildren()
cristalPropio.Name = "LinternaDescubierta"
cristalPropio.Color = Color3.fromRGB(255, 203, 126)
cristalPropio.Material = Enum.Material.Neon
cristalPropio.Transparency = .08
cristalPropio.CanCollide, cristalPropio.CanQuery, cristalPropio.CanTouch = false, false, false
local luzPropia = linterna:WaitForChild("Luz"):Clone()
luzPropia.Enabled = true
luzPropia.Parent = cristalPropio
local hazPropio = haz:Clone()
hazPropio.Width1, hazPropio.Enabled = 7.3, true
hazPropio.Parent = cristalPropio
local function recordarLinterna()
	local propia = jugador:GetAttribute("FaroEncendido") == true and not haz.Enabled
	linterna.LocalTransparencyModifier = if propia then 1 else 0
	cristalPropio.Parent = if propia then faro else nil
end
jugador:GetAttributeChangedSignal("FaroEncendido"):Connect(recordarLinterna)
haz:GetPropertyChangedSignal("Enabled"):Connect(recordarLinterna)
recordarLinterna()

local function pedirLuz()
	if not cercaDelRastro(raiz()) then
		return false
	end
	accion:FireServer("Lucero")
	return true
end

ContextActionService:BindActionAtPriority("LuzDeLucero", function(_, estado)
	if estado == Enum.UserInputState.Begin and pedirLuz() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.ContextActionPriority.High.Value, Enum.KeyCode.C, Enum.KeyCode.ButtonR1)

local despegueHasta = 0
local reintento = false
accion.OnClientEvent:Connect(function(evento)
	if evento == "ReintentarLlegada" then
		reintento = true
		despegueHasta = os.clock() + 12
	end
end)
refugio.OnClientEvent:Connect(function(evento, ok)
	if evento ~= "SalidaAlFaro" or not ok then
		return
	end
	reintento = false
	despegueHasta = os.clock() + 12
	task.delay(0.15, function()
		local root = raiz()
		local cam = workspace.CurrentCamera
		if root and cam and (root.Position - faro.Despegue.Position).Magnitude < 8 then
			local rumbo = (faro.Llegada.Position - faro.Despegue.Position) * Vector3.new(1, 0, 1)
			if rumbo.Magnitude > 0.1 then
				cam.CFrame = CFrame.lookAt(root.Position + Vector3.yAxis * 5.85 - rumbo.Unit * 13, faro.Llegada.Position + Vector3.yAxis * 2)
			end
		end
	end)
end)

local transcurrido = 0
RunService.Heartbeat:Connect(function(dt)
	transcurrido += dt
	if transcurrido < 0.09 then
		return
	end
	transcurrido = 0
	local root = raiz()
	local dentro = jugador:GetAttribute("EnFaro") == true
	local espera = jugador:GetAttribute("EsperaFaro") == true and not dentro
	local cercaSalida = root and os.clock() < despegueHasta and (root.Position - faro.Despegue.Position).Magnitude < 16
	gui.Enabled = root ~= nil and not jugador:GetAttribute("BitacoraAbierta") and jugador:GetAttribute("RescateNimbo") ~= "Eclosion" and (dentro or espera or cercaSalida == true)
	if not gui.Enabled then
		return
	end
	local mando = UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
	local tactil = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	local titulo, pista
	titulo = if dentro then faro:GetAttribute("TituloFaro") or "Ruinas del Faro"
		elseif reintento then "Vuelve a probar el vuelo" else "Despegue hacia el faro"
	pista = if dentro then faro:GetAttribute("PistaFaro") or ""
		else if tactil then "Salta y toca Planeo. Aterriza sobre la losa entre los pilares."
		elseif mando then "Salta y pulsa Y. Aterriza sobre la losa entre los pilares."
		else "Salta y pulsa F. Aterriza sobre la losa entre los pilares."
	acciones:actualizar(if dentro and cercaDelRastro(root) then {
		{icono="Chispa", tecla=if mando then "R1" else "C", texto="Iluminar", activar=pedirLuz},
	} else {})
	if espera then
		titulo = "El espejo está ocupado"
		pista = "Quédate en la losa. El espejo será tuyo cuando quede libre."
		ficha:actualizar("Faro", titulo, pista)
		return
	end
	local etapa = jugador:GetAttribute("RescateNimbo")
	if dentro and etapa then
		local aros = jugador:GetAttribute("ArosNimbo") or 0
		if etapa == "Subiendo" then
			titulo, pista = "Elevador de Prisma", "Mira los tres aros. El huevo está en la nube más allá del último."
		elseif etapa == "Caida" then
			titulo, pista = "Alas plegadas", "Aterriza en el nido o vuelve a intentarlo desde el balcón."
		elseif etapa == "Balcon" then
			titulo, pista = "Nido de tormenta", "Lánzate desde el borde dorado. Tres aros dan una oportunidad de Aurora (20 %)."
		elseif etapa == "Vuelo" then
			titulo = ("Aros de Prisma   %d / 3"):format(aros)
			pista = if tactil then "Dirige el planeador. Toca Plegar para cerrar las alas."
				elseif mando then "Dirige el planeador. Pulsa Y para plegar las alas."
				else "Dirige el planeador con WASD. Pulsa F para plegar las alas."
		elseif etapa == "Nido" then
			titulo = if aros == 3 then "¡Tres aros de Prisma!" else "Llegaste al nido"
			pista = "Acércate al huevo para abrir el cascarón."
		elseif etapa == "Eclosion" then
			titulo, pista = "El cascarón se mueve…", "Algo está a punto de salir."
		elseif etapa == "Rescatado" then
			titulo = if jugador:GetAttribute("UltimaEclosionAurora") then "Nimbo Aurora" else "Nimbo, Eco de tormenta"
			pista = "Ya vuela contigo. Usa la salida del nido para volver a la torre."
		end
	elseif dentro and jugador:GetAttribute("Prisma") and jugador:GetAttribute("FaroEncendido") then
		titulo, pista = "El huevo de la tormenta", "Desde el cristal o las marcas de la orilla, usa Camino de Prisma para llegar al elevador."
	end
	local icono = if etapa then "Nimbo" elseif jugador:GetAttribute("Prisma") and dentro then "Prisma" else "Faro"
	ficha:actualizar(icono, titulo, pista, nil, if etapa=="Vuelo" then (jugador:GetAttribute("ArosNimbo") or 0)/3 else nil)
end)
