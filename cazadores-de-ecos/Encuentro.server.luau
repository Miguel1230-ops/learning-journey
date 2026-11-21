-- Cazadores de Ecos: una expedición de prueba en una sola isla.
-- Los objetos del mapa se pueden mover desde Explorer en Roblox Studio.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local isla = workspace:WaitForChild("IslaDelEco")
local rastros = isla:WaitForChild("Rastros")
local huellas = { rastros.Huella1, rastros.Huella2, rastros.Huella3 }
local escondite = rastros.Escondite
local circulo = isla.CirculoDeCalma
local eco = isla.EcoDeCristal
local nucleo = eco.Nucleo
local luzEco = nucleo.Luz
local pedestal = isla.Pedestal
local escalera = isla.EscaleraSecreta
local jardin = isla.Jardin
local semilla = jardin.Semilla
local refugioEco = isla.Posiciones.Refugio
local salidaEco = isla.Posiciones.Salida

local VERDE = Color3.fromRGB(122, 255, 219)
local ORO = Color3.fromRGB(255, 219, 140)
local LILA = Color3.fromRGB(193, 169, 255)
local RADIO_CIRCULO = circulo.Size.Y / 2
local TIEMPO_CALMA = 2
local INTERVALO = 0.12

local mensajes = {
	Rastreo = { "01    RASTREO", "Sigue las huellas brillantes", "Pasa cerca de cada huella para descubrir la siguiente." },
	Avistamiento = { "02    ENCUENTRO", "Algo se mueve en la cueva", "Acércate para ver qué es." },
	Calma = { "02    ENCUENTRO", "El Eco se escondió", "Sigue el nuevo rastro hasta el círculo." },
	Vinculo = { "03    HALLAZGO", "El Eco de Cristal confía en ti", "Acércate al pedestal y pídele al Eco que revele el camino." },
	Revelando = { "03    HALLAZGO", "El Eco ilumina la roca", "Mira lo que aparece frente a ti." },
	Sube = { "03    HALLAZGO", "Apareció una escalera secreta", "Súbela y examina lo que brilla arriba." },
	Fin = { "EXPEDICIÓN COMPLETA", "Descubriste el Jardín de Estrellas", "Hallazgo registrado: Semilla estelar." },
}

local etapa = "Rastreo"
local siguienteHuella = 1
local segundosQuieto = 0
local jugadorEnCalma
local paneles = {}
local pulsoActual

local function etiqueta(padre, nombre, texto, fuente, tamano, color, y, alto)
	local label = Instance.new("TextLabel")
	label.Name = nombre
	label.BackgroundTransparency = 1
	label.Font = fuente
	label.Text = texto
	label.TextSize = tamano
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Position = UDim2.fromOffset(14, y)
	label.Size = UDim2.new(1, -28, 0, alto)
	label.Parent = padre
	return label
end

local function mostrarObjetivo(pista, fraccion)
	local mensaje = mensajes[etapa]
	for _, panel in pairs(paneles) do
		panel.fase.Text = mensaje[1]
		panel.titulo.Text = mensaje[2]
		panel.pista.Text = pista or mensaje[3]
		panel.barra.Visible = fraccion ~= nil
		panel.llenado.Size = UDim2.fromScale(fraccion or 0, 1)
	end
end

local function prepararJugador(jugador)
	local playerGui = jugador:WaitForChild("PlayerGui", 10)
	if not playerGui or jugador.Parent ~= Players then
		return
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "ExpedicionEco"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local tarjeta = Instance.new("Frame")
	tarjeta.Name = "Objetivo"
	tarjeta.BackgroundColor3 = Color3.fromRGB(23, 32, 49)
	tarjeta.BackgroundTransparency = 0.12
	tarjeta.BorderSizePixel = 0
	tarjeta.Position = UDim2.fromOffset(16, 12)
	tarjeta.Size = UDim2.new(1, -32, 0, 105)
	tarjeta.Parent = gui

	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(340, 105)
	limite.Parent = tarjeta
	local esquinas = Instance.new("UICorner")
	esquinas.CornerRadius = UDim.new(0, 10)
	esquinas.Parent = tarjeta

	local fase = etiqueta(tarjeta, "Fase", "", Enum.Font.GothamBold, 11, VERDE, 10, 15)
	local titulo = etiqueta(tarjeta, "Titulo", "", Enum.Font.GothamBold, 17, Color3.fromRGB(251, 249, 236), 28, 25)
	local pista = etiqueta(tarjeta, "Pista", "", Enum.Font.GothamMedium, 13, Color3.fromRGB(217, 226, 240), 56, 32)

	local barra = Instance.new("Frame")
	barra.Name = "Calma"
	barra.BorderSizePixel = 0
	barra.BackgroundColor3 = Color3.fromRGB(66, 83, 103)
	barra.Position = UDim2.fromOffset(14, 92)
	barra.Size = UDim2.new(1, -28, 0, 5)
	barra.Parent = tarjeta

	local llenado = Instance.new("Frame")
	llenado.Name = "Progreso"
	llenado.BorderSizePixel = 0
	llenado.BackgroundColor3 = VERDE
	llenado.Parent = barra

	paneles[jugador] = { fase = fase, titulo = titulo, pista = pista, barra = barra, llenado = llenado }
	mostrarObjetivo()
	gui.Parent = playerGui
end

local function cambiarEtapa(nuevaEtapa)
	etapa = nuevaEtapa
	isla:SetAttribute("Etapa", etapa)
	mostrarObjetivo()
end

local function mostrarRastro(rastro, opacidad)
	for _, parte in ipairs(rastro:GetChildren()) do
		if parte:IsA("BasePart") and parte.Name ~= "Marca" then
			parte.Transparency = opacidad
		end
	end
end

local function resaltarHuella()
	if pulsoActual then
		pulsoActual:Cancel()
	end
	for numero, huella in ipairs(huellas) do
		local transparencia = if numero < siguienteHuella then 0.72 elseif numero == siguienteHuella then 0.04 else 1
		mostrarRastro(huella, transparencia)
	end

	local actual = huellas[siguienteHuella]
	if actual then
		pulsoActual = TweenService:Create(
			actual.Destello,
			TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.54 }
		)
		pulsoActual:Play()
	end
end

local function moverEco(destino, duracion)
	local recorrido = Instance.new("CFrameValue")
	recorrido.Value = eco:GetPivot()
	local conexion = recorrido.Changed:Connect(function(posicion)
		eco:PivotTo(posicion)
	end)
	local viaje = TweenService:Create(
		recorrido,
		TweenInfo.new(duracion, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
		{ Value = destino }
	)
	viaje.Completed:Once(function()
		conexion:Disconnect()
		recorrido:Destroy()
	end)
	viaje:Play()
end

local function centroDelJugador(jugador)
	local personaje = jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if humanoide and humanoide.Health > 0 then
		return personaje:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function estaCerca(root, punto, radio)
	if not root or math.abs(root.Position.Y - punto.Y) > 6 then
		return false
	end
	local diferencia = root.Position - punto
	return Vector2.new(diferencia.X, diferencia.Z).Magnitude <= radio
end

local function asustarEco()
	cambiarEtapa("Calma")
	nucleo.Color = ORO
	luzEco.Color = ORO
	mostrarRastro(escondite, 0.08)
	circulo.Transparency = 0.32
	moverEco(refugioEco.CFrame, 0.62)
end

local function nuevaAccion(objeto, texto, nombre)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Accion"
	prompt.ActionText = texto
	prompt.ObjectText = nombre
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = objeto
	return prompt
end

local accionPedestal = nuevaAccion(pedestal, "Revelar camino", "Eco de Cristal")
local accionSemilla = nuevaAccion(semilla, "Examinar", "Semilla estelar")

local function actualizarCalma(dt)
	local elegido, rootElegido
	for _, jugador in ipairs(Players:GetPlayers()) do
		local root = centroDelJugador(jugador)
		if estaCerca(root, circulo.Position, RADIO_CIRCULO) then
			elegido, rootElegido = jugador, root
			if elegido == jugadorEnCalma then
				break
			end
		end
	end

	if elegido ~= jugadorEnCalma then
		segundosQuieto = 0
		jugadorEnCalma = elegido
	end
	if not rootElegido then
		nucleo.Color = ORO
		luzEco.Color = ORO
		circulo.Color = LILA
		mostrarObjetivo()
		return
	end

	if rootElegido.AssemblyLinearVelocity.Magnitude > 2.2 then
		segundosQuieto = 0
		nucleo.Color = ORO
		luzEco.Color = ORO
		circulo.Color = LILA
		mostrarObjetivo("Quédate quieto sobre el círculo para que se calme.", 0)
		return
	end

	segundosQuieto += dt
	nucleo.Color = VERDE
	luzEco.Color = VERDE
	circulo.Color = VERDE
	mostrarObjetivo("El Eco se está acercando. Mantén la calma…", math.min(segundosQuieto / TIEMPO_CALMA, 1))

	if segundosQuieto >= TIEMPO_CALMA then
		mostrarRastro(escondite, 0.72)
		isla:SetAttribute("EcoEncontrado", true)
		accionPedestal.Enabled = true
		cambiarEtapa("Vinculo")
		moverEco(salidaEco.CFrame, 1)
	end
end

accionPedestal.Triggered:Connect(function(jugador)
	if etapa ~= "Vinculo" or not estaCerca(centroDelJugador(jugador), pedestal.Position, 9) then
		return
	end

	accionPedestal.Enabled = false
	cambiarEtapa("Revelando")
	pedestal.Color = VERDE

	-- El suelo real es una rampa. Los peldaños visibles solo dibujan el camino.
	escalera.Rampa.CanCollide = true
	for numero = 1, 11 do
		local peldano = escalera["Peldano" .. numero]
		TweenService:Create(peldano, TweenInfo.new(0.24), { Transparency = 0.05 }):Play()
		TweenService:Create(escalera["Borde" .. numero], TweenInfo.new(0.24), { Transparency = 0 }):Play()
		task.wait(0.065)
	end

	isla:SetAttribute("EscaleraRevelada", true)
	accionSemilla.Enabled = true
	cambiarEtapa("Sube")
end)

accionSemilla.Triggered:Connect(function(jugador)
	if etapa ~= "Sube" or not estaCerca(centroDelJugador(jugador), semilla.Position, 9) then
		return
	end

	accionSemilla.Enabled = false
	semilla.Color = ORO
	semilla.Luz.Brightness = 2.1
	for _, petalo in ipairs(jardin.Flor:GetChildren()) do
		local direccion = (petalo.Position - semilla.Position) * Vector3.new(1, 0, 1)
		TweenService:Create(petalo, TweenInfo.new(0.55, Enum.EasingStyle.Back), {
			Position = petalo.Position + direccion.Unit * 1.25 + Vector3.new(0, 1.1, 0),
			Color = ORO,
		}):Play()
	end
	isla:SetAttribute("JardinDescubierto", true)
	cambiarEtapa("Fin")
end)

mostrarRastro(escondite, 1)
resaltarHuella()
isla:SetAttribute("HuellasLeidas", 0)
isla:SetAttribute("EcoEncontrado", false)
isla:SetAttribute("EscaleraRevelada", false)
isla:SetAttribute("JardinDescubierto", false)
cambiarEtapa("Rastreo")

Players.PlayerAdded:Connect(prepararJugador)
Players.PlayerRemoving:Connect(function(jugador)
	paneles[jugador] = nil
end)
for _, jugador in ipairs(Players:GetPlayers()) do
	task.spawn(prepararJugador, jugador)
end

-- Los encuentros dependen de lo que haces en la isla, no de una tirada.
while etapa ~= "Fin" do
	local dt = math.min(task.wait(INTERVALO), 0.25)
	if etapa == "Calma" then
		actualizarCalma(dt)
	elseif etapa == "Rastreo" or etapa == "Avistamiento" then
		for _, jugador in ipairs(Players:GetPlayers()) do
			local root = centroDelJugador(jugador)
			if etapa == "Rastreo" and estaCerca(root, huellas[siguienteHuella].Marca.Position, 4.5) then
				isla:SetAttribute("HuellasLeidas", siguienteHuella)
				siguienteHuella += 1
				resaltarHuella()
				if siguienteHuella > #huellas then
					cambiarEtapa("Avistamiento")
				else
					mostrarObjetivo("Huellas leídas: " .. (siguienteHuella - 1) .. " de " .. #huellas .. ".")
				end
				break
			elseif etapa == "Avistamiento" and estaCerca(root, nucleo.Position, 8.5) then
				asustarEco()
				break
			end
		end
	end
end
