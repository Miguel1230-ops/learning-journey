-- Segunda prueba de Cazadores de Ecos: una expedición individual con botín.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Hallazgos = require(script.Parent.Hallazgos)
local azar = Random.new()

local isla = workspace:WaitForChild("IslaDelEco")
local circulo = isla.CirculoDeCalma
local eco = isla.EcoDeCristal
local nucleo = eco.Nucleo
local pedestal = isla.Pedestal
local escalera = isla.EscaleraSecreta
local semilla = isla.Jardin.Semilla
local plantillaEco = eco:Clone()
local VERDE = Color3.fromRGB(122, 255, 219)
local ORO = Color3.fromRGB(255, 219, 140)
local LILA = Color3.fromRGB(193, 169, 255)
local SUAVE = Color3.fromRGB(218, 229, 241)
local BLANCO = Color3.fromRGB(255, 251, 236)
local TONO_PIEDRA = Color3.fromRGB(77, 92, 125)
local AURORA = Hallazgos.variedades[#Hallazgos.variedades]
local ORIGEN = Vector3.new(22.5, 20.5, -4)

local jugador
local panel
local etapa = "Encuentro"
local quieto = 0
local energia = 0
local coleccion = {}
local cantidad = 0
local repeticion = 0
local mejorIndice = 0
local conMarca = false
local tienePuente = false
local tieneMirador = false
local balizaRecogida = false
local companero

local objetos = Instance.new("Folder")
objetos.Name = "RutaDeHallazgos"
objetos.Parent = isla

local function pieza(nombre, posicion, tamano, color, material, solida)
	local parte = Instance.new("Part")
	parte.Name = nombre
	parte.Position = posicion
	parte.Size = tamano
	parte.Color = color
	parte.Material = material
	parte.Anchored = true
	parte.CanCollide = solida
	parte.CanTouch = false
	parte.CastShadow = solida
	parte.Parent = objetos
	return parte
end

local function accion(parte, nombre, texto, distancia)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Accion"
	prompt.ObjectText = nombre
	prompt.ActionText = texto
	prompt.MaxActivationDistance = distancia
	prompt.RequiresLineOfSight = false
	prompt.ClickablePrompt = true
	prompt.Parent = parte
	return prompt
end

local function escribir(padre, texto, tamano, color, y, alto, negrita)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(14, y)
	label.Size = UDim2.new(1, -28, 0, alto)
	label.Text = texto
	label.TextSize = tamano
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.Font = if negrita then Enum.Font.GothamBold else Enum.Font.GothamMedium
	label.Parent = padre
	return label
end

local function tarjeta(padre, nombre, ancho, alto)
	local frame = Instance.new("Frame")
	frame.Name = nombre
	frame.BackgroundColor3 = Color3.fromRGB(22, 30, 48)
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(1, -32, 0, alto)
	local limite = Instance.new("UISizeConstraint")
	limite.MaxSize = Vector2.new(ancho, alto)
	limite.Parent = frame
	local esquina = Instance.new("UICorner")
	esquina.CornerRadius = UDim.new(0, 12)
	esquina.Parent = frame
	frame.Parent = padre
	return frame
end

local function mostrarObjetivo(titulo, pista)
	if panel then
		panel.titulo.Text = titulo
		panel.pista.Text = pista
	end
end

local function cambiarEtapa(nueva, titulo, pista)
	etapa = nueva
	isla:SetAttribute("Etapa", nueva)
	mostrarObjetivo(titulo, pista)
end

local function actualizarProgreso()
	if not jugador or not panel then
		return
	end
	local mejor = Hallazgos.variedades[mejorIndice]
	panel.progreso.Text = ("%d energía  ·  Colección %d/%d%s"):format(
		energia, cantidad, #Hallazgos.variedades, if mejor then "  ·  " .. Hallazgos.formatoBono(mejor.bono) else ""
	)
	jugador:SetAttribute("Energia", energia)
	jugador:SetAttribute("Coleccion", cantidad)
	jugador:SetAttribute("Expediciones", repeticion)
	jugador:SetAttribute("MejorEco", if mejor then mejor.nombre else "")
	jugador:SetAttribute("BonoEco", if mejor then mejor.bono else 1)
	jugador:SetAttribute("MarcaSolar", conMarca)
	jugador:SetAttribute("PuenteDeMarca", tienePuente)
	jugador:SetAttribute("MiradorDisponible", tieneMirador)
end

local function prepararJugador(nuevo)
	if jugador then
		return
	end
	jugador = nuevo
	local playerGui = nuevo:WaitForChild("PlayerGui", 10)
	if not playerGui or jugador ~= nuevo then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "ExpedicionBotin"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local objetivo = tarjeta(gui, "Objetivo", 356, 103)
	objetivo.Position = UDim2.fromOffset(16, 12)
	escribir(objetivo, "CAZADORES DE ECOS", 10, VERDE, 10, 14, true)
	local titulo = escribir(objetivo, "Acércate al Eco", 17, BLANCO, 25, 23, true)
	local pista = escribir(objetivo, "Mira qué hace al verte.", 13, SUAVE, 48, 32)
	local progreso = escribir(objetivo, "", 11, VERDE, 83, 18, true)

	local resultado = tarjeta(gui, "Hallazgo", 374, 135)
	resultado.AnchorPoint = Vector2.new(0.5, 1)
	resultado.Position = UDim2.new(0.5, 0, 1, -28)
	resultado.Visible = false
	local borde = Instance.new("UIStroke")
	borde.Thickness = 2
	borde.Parent = resultado
	local rango = escribir(resultado, "", 12, VERDE, 11, 18, true)
	local nombre = escribir(resultado, "", 24, BLANCO, 29, 34, true)
	local pago = escribir(resultado, "", 16, BLANCO, 67, 22, true)
	local ventaja = escribir(resultado, "", 13, SUAVE, 92, 38)
	panel = { titulo = titulo, pista = pista, progreso = progreso, resultado = resultado, rango = rango,
		nombre = nombre, pago = pago, ventaja = ventaja, borde = borde }
	actualizarProgreso()
	gui.Parent = playerGui
end

for _, rastro in ipairs(isla.Rastros:GetChildren()) do
	for _, parte in ipairs(rastro:GetChildren()) do
		if parte:IsA("BasePart") then
			parte.Transparency = 1
		end
	end
end

local function rootDelJugador()
	local personaje = jugador and jugador.Character
	local humanoide = personaje and personaje:FindFirstChildOfClass("Humanoid")
	return humanoide and humanoide.Health > 0 and personaje:FindFirstChild("HumanoidRootPart") or nil
end

local function cerca(root, punto, radio)
	return root and (root.Position - punto).Magnitude <= radio
end

local function sobreCirculo(root)
	if not root or math.abs(root.Position.Y - circulo.Position.Y) > 5 then
		return false
	end
	local d = root.Position - circulo.Position
	return Vector2.new(d.X, d.Z).Magnitude < circulo.Size.Y / 2
end

local function moverEco(destino, segundos)
	local trayecto = Instance.new("CFrameValue")
	trayecto.Value = eco:GetPivot()
	local conexion = trayecto.Changed:Connect(function(posicion)
		eco:PivotTo(posicion)
	end)
	local movimiento = TweenService:Create(trayecto, TweenInfo.new(segundos, Enum.EasingStyle.Sine), { Value = destino })
	movimiento.Completed:Once(function()
		conexion:Disconnect()
		trayecto:Destroy()
	end)
	movimiento:Play()
end

local function aparecer(parte)
	parte.CanCollide = true
	TweenService:Create(parte, TweenInfo.new(0.38), { Transparency = 0 }):Play()
end

-- El desvío pide dos saltos. El puente comprado hace más fácil volver por la marca.
for _, z in ipairs({ 17.2, 23.25 }) do
	pieza("EscalonSolar", Vector3.new(21.5, 15.24, z), Vector3.new(5, 1.5, 3.25), TONO_PIEDRA, Enum.Material.Slate, true)
	pieza("BordeSolar", Vector3.new(21.5, 16, z), Vector3.new(4.85, 0.08, 3.12), ORO, Enum.Material.Metal, false)
end
local desvio = pieza("InicioDesvioSolar", Vector3.new(21.5, 16.09, 11.45), Vector3.new(4.7, 0.17, 2.2), ORO, Enum.Material.Neon, false)
local marca = pieza("MarcaSolar", Vector3.new(21.5, 18, 23.25), Vector3.new(1.4, 1.4, 1.4), ORO, Enum.Material.Neon, false)
marca.Orientation = Vector3.new(36, 45, 36)
local puente = pieza("PuenteSolar", Vector3.new(21.5, 15.57, 18.1), Vector3.new(4.4, 0.76, 13.05), LILA, Enum.Material.SmoothPlastic, false)
puente.Transparency = 1
local taller = pieza("Taller", Vector3.new(26.6, 17, 9.4), Vector3.new(1.7, 2, 1.7), LILA, Enum.Material.Slate, true)

local puerto = pieza("Regreso", Vector3.new(101, 27.42, -3.1), Vector3.new(1.1, 1.1, 1.1), VERDE, Enum.Material.Neon, false)
puerto.Orientation = Vector3.new(27, 40, 35)
pieza("AnilloDeRegreso", Vector3.new(101, 26.77, -3.1), Vector3.new(0.15, 3.9, 3.9), VERDE, Enum.Material.SmoothPlastic, false).Shape = Enum.PartType.Cylinder
objetos.AnilloDeRegreso.Orientation = Vector3.new(0, 0, 90)

local mirador = pieza("MiradorDeAurora", Vector3.new(129, 25.25, -10), Vector3.new(18, 2.9, 15), TONO_PIEDRA, Enum.Material.Slate, true)
pieza("SueloDeAurora", mirador.Position + Vector3.new(0, 1.5, 0), Vector3.new(17.8, 0.12, 14.8), Color3.fromRGB(157, 125, 106), Enum.Material.SmoothPlastic, true)
local arco = pieza("PuenteDeAurora", Vector3.new(113, 26.23, -10), Vector3.new(15.8, 0.94, 5.2), AURORA.color, Enum.Material.Neon, false)
arco.Transparency = 1
local baliza = pieza("BalizaDeAurora", Vector3.new(130, 29.1, -10), Vector3.new(2.6, 4.1, 2.6), AURORA.color, Enum.Material.Neon, false)
baliza.Orientation = Vector3.new(12, 45, 12)
for _, z in ipairs({ -14.5, -5.5 }) do
	pieza("CristalDelMirador", Vector3.new(134.4, 28, z), Vector3.new(1.2, 2.8, 1.2), LILA, Enum.Material.Neon, false).Orientation = Vector3.new(14, 45, 28)
end

local accionDesvio = accion(desvio, "Marca solar", "Ver probabilidades", 5.6)
local accionMarca = accion(marca, "Marca solar", "Tomar marca", 4.2)
local accionTaller = accion(taller, "Puente solar · " .. Hallazgos.costoPuente .. " energía", "Construir", 6.2)
local accionPedestal = accion(pedestal, "Eco de Cristal", "Revelar escalera", 8.5)
local accionSemilla = accion(semilla, "Semilla estelar", "Abrir", 8.6)
local accionRegreso = accion(puerto, "Otra expedición", "Volver a la cueva", 7.4)
local accionBaliza = accion(baliza, "Mirador de Aurora", "Tocar baliza", 8)
accionPedestal.Enabled = false
accionSemilla.Enabled = false
accionRegreso.Enabled = false
accionBaliza.Enabled = false

local function probabilidades()
	return ("Aurora: %d%% por el camino directo, %d%% con Marca solar."):format(AURORA.normal, AURORA.solar)
end

local function objetivoDeRuta()
	local pista = if conMarca
		then ("Marca cargada · %d%% de Aurora. Abre la semilla del jardín."):format(AURORA.solar)
		else "Ve al jardín o salta por las piedras doradas para mejorar tus probabilidades."
	cambiarEtapa("Expedicion", "Abre una semilla estelar", pista)
end

local function puntoDeAccion(quien, parte, prompt)
	return quien == jugador and prompt.Enabled and cerca(rootDelJugador(), parte.Position, prompt.MaxActivationDistance + 0.6)
end

accionDesvio.Triggered:Connect(function(quien)
	if puntoDeAccion(quien, desvio, accionDesvio) and (etapa == "Expedicion" or etapa == "Encuentro") then
		mostrarObjetivo("Consigue la marca con dos saltos", probabilidades())
	end
end)

accionMarca.Triggered:Connect(function(quien)
	if conMarca or etapa == "Abriendo" or etapa == "Hallazgo" or not puntoDeAccion(quien, marca, accionMarca) then
		return
	end
	conMarca = true
	accionMarca.Enabled = false
	marca.Color = VERDE
	actualizarProgreso()
	if etapa == "Expedicion" then
		objetivoDeRuta()
	else
		mostrarObjetivo("Marca solar lista", "Acércate al Eco para llegar al jardín.")
	end
end)

accionTaller.Triggered:Connect(function(quien)
	if tienePuente or etapa ~= "Expedicion" or not puntoDeAccion(quien, taller, accionTaller) then
		return
	end
	if energia < Hallazgos.costoPuente then
		mostrarObjetivo("El puente cuesta " .. Hallazgos.costoPuente .. " de energía", ("Te faltan %d. Las semillas siempre dan energía."):format(Hallazgos.costoPuente - energia))
		return
	end
	energia -= Hallazgos.costoPuente
	tienePuente = true
	accionTaller.Enabled = false
	aparecer(puente)
	actualizarProgreso()
	mostrarObjetivo("Puente solar construido", "Ya puedes caminar hasta la marca. Sube al jardín cuando estés listo.")
end)

accionPedestal.Triggered:Connect(function(quien)
	if etapa ~= "Vinculo" or not puntoDeAccion(quien, pedestal, accionPedestal) then
		return
	end
	accionPedestal.Enabled = false
	cambiarEtapa("Revelando", "El Eco abrió el camino", "Mira la escalera frente al pedestal.")
	pedestal.Color = VERDE
	escalera.Rampa.CanCollide = true
	for numero = 1, 11 do
		local peldano = escalera["Peldano" .. numero]
		TweenService:Create(peldano, TweenInfo.new(0.24), { Transparency = 0.05 }):Play()
		TweenService:Create(escalera["Borde" .. numero], TweenInfo.new(0.24), { Transparency = 0 }):Play()
		task.wait(0.045)
	end
	accionSemilla.Enabled = true
	objetivoDeRuta()
end)

local function equipar(hallazgo)
	if companero then
		companero:Destroy()
	end
	companero = plantillaEco:Clone()
	companero.Name = hallazgo.nombre
	companero.Nucleo.Color = hallazgo.color
	companero.Nucleo.Luz.Color = hallazgo.color
	for _, parte in ipairs(companero:GetChildren()) do
		if parte:IsA("BasePart") and parte.Material == Enum.Material.Neon then
			parte.Color = hallazgo.color
		end
	end
	companero:ScaleTo(hallazgo.escala)
	companero:PivotTo(CFrame.new(semilla.Position + Vector3.new(0, 3.4, 4)))
	companero.Parent = objetos
end

local function celebrar(color, cantidadDeChispas)
	for i = 1, cantidadDeChispas do
		local angulo = i * 2 * math.pi / cantidadDeChispas
		local direccion = Vector3.new(math.cos(angulo), 0.45, math.sin(angulo))
		local chispa = pieza("Chispa", semilla.Position, Vector3.new(0.32, 0.32, 0.32), color, Enum.Material.Neon, false)
		local brillo = TweenService:Create(chispa, TweenInfo.new(0.52, Enum.EasingStyle.Quad), {
			Position = chispa.Position + direccion * 5.3,
			Transparency = 1,
		})
		brillo.Completed:Once(function()
			chispa:Destroy()
		end)
		brillo:Play()
	end
end

accionSemilla.Triggered:Connect(function(quien)
	if etapa ~= "Expedicion" or not puntoDeAccion(quien, semilla, accionSemilla) then
		return
	end
	accionSemilla.Enabled = false
	cambiarEtapa("Abriendo", "La semilla se está abriendo…", "Algo empieza a brillar por dentro.")
	semilla.Color = BLANCO
	semilla.Luz.Brightness = 2
	task.wait(0.38)
	if jugador ~= quien then
		return
	end

	local hallazgo, indice = Hallazgos.elegir(azar:NextInteger(1, 100), conMarca)
	local nuevo = not coleccion[indice]
	if nuevo then
		coleccion[indice] = true
		cantidad += 1
	end
	local anterior = Hallazgos.variedades[mejorIndice]
	local bono = if anterior then anterior.bono else 1
	local ganancia = math.floor(hallazgo.energia * bono + 0.5)
	energia += ganancia
	repeticion += 1
	if indice > mejorIndice then
		mejorIndice = indice
		equipar(hallazgo)
	end

	local abrioMirador = hallazgo == AURORA and not tieneMirador
	if abrioMirador then
		tieneMirador = true
		aparecer(arco)
		accionBaliza.Enabled = true
	end
	semilla.Color = hallazgo.color
	semilla.Luz.Color = hallazgo.color
	celebrar(hallazgo.color, if hallazgo == AURORA then 18 else 8)
	jugador:SetAttribute("UltimoEco", hallazgo.nombre)
	jugador:SetAttribute("UltimaGanancia", ganancia)
	actualizarProgreso()

	if panel then
		panel.rango.Text = hallazgo.rareza .. (if nuevo then "   ·   NUEVO" else "")
		panel.rango.TextColor3 = hallazgo.color
		panel.borde.Color = hallazgo.color
		panel.nombre.Text = hallazgo.nombre
		panel.pago.Text = ("+%d energía%s"):format(ganancia, if bono > 1 then "  ·  Bono " .. Hallazgos.formatoBono(bono) else "")
		local mejor = Hallazgos.variedades[mejorIndice]
		panel.ventaja.Text = if abrioMirador then "¡Abrió el Mirador de Aurora!"
			else ("Tu " .. mejor.nombre .. " da " .. Hallazgos.formatoBono(mejor.bono) .. " de energía en futuras expediciones.")
		panel.resultado.Visible = true
	end

	accionRegreso.Enabled = true
	cambiarEtapa("Hallazgo", "¡Hallazgo conseguido!", if abrioMirador
		then "Cruza el puente dorado para visitar el mirador."
		else "Usa la luz verde para volver a la cueva y buscar otro Eco.")
end)

accionBaliza.Triggered:Connect(function(quien)
	if not tieneMirador or balizaRecogida or not puntoDeAccion(quien, baliza, accionBaliza) then
		return
	end
	balizaRecogida = true
	accionBaliza.Enabled = false
	energia += 60
	if panel then
		panel.resultado.Visible = false
	end
	actualizarProgreso()
	mostrarObjetivo("Baliza de Aurora descubierta", "+60 energía. Puedes volver por el mismo puente.")
end)

accionRegreso.Triggered:Connect(function(quien)
	if etapa ~= "Hallazgo" or not puntoDeAccion(quien, puerto, accionRegreso) then
		return
	end
	accionRegreso.Enabled = false
	conMarca = false
	marca.Color = ORO
	accionMarca.Enabled = true
	semilla.Color = VERDE
	semilla.Luz.Color = VERDE
	semilla.Luz.Brightness = 1.2
	if panel then
		panel.resultado.Visible = false
	end
	quien.Character:PivotTo(CFrame.lookAt(ORIGEN, ORIGEN + Vector3.xAxis))
	actualizarProgreso()
	accionSemilla.Enabled = true
	objetivoDeRuta()
end)

isla:SetAttribute("Etapa", etapa)
Players.PlayerAdded:Connect(prepararJugador)
for _, conectado in ipairs(Players:GetPlayers()) do
	task.spawn(prepararJugador, conectado)
end

while true do
	local dt = math.min(task.wait(0.11), 0.2)
	local root = rootDelJugador()
	if etapa == "Encuentro" and cerca(root, nucleo.Position, 7.7) then
		cambiarEtapa("Calma", "El Eco se escondió", "Sigue las huellas hasta el círculo brillante.")
		circulo.Transparency = 0.27
		for _, parte in ipairs(isla.Rastros.Escondite:GetChildren()) do
			if parte:IsA("BasePart") and parte.Name ~= "Marca" then
				parte.Transparency = 0.12
			end
		end
		moverEco(isla.Posiciones.Refugio.CFrame, 0.52)
	elseif etapa == "Calma" then
		if sobreCirculo(root) and root.AssemblyLinearVelocity.Magnitude < 2.2 then
			quieto += dt
			circulo.Color = VERDE
			mostrarObjetivo("Quédate quieto un momento", "El Eco se está acercando…")
			if quieto >= 1.2 then
				cambiarEtapa("Vinculo", "El Eco confía en ti", "Pídele que abra el camino en el pedestal de la cueva.")
				accionPedestal.Enabled = true
				moverEco(isla.Posiciones.Salida.CFrame, 0.65)
			end
		else
			quieto = 0
			circulo.Color = LILA
			mostrarObjetivo("El Eco se escondió", "Párate sobre el círculo y quédate quieto.")
		end
	end
	if root and companero then
		local lado = 3.6 + companero:GetScale()
		local altura = 1.2 + companero:GetScale() * 0.7
		local posicion = root.Position + root.CFrame.RightVector * lado - root.CFrame.LookVector * 1.8
			+ Vector3.new(0, altura + math.sin(os.clock() * 3) * 0.25, 0)
		local mira = root.CFrame.LookVector
		local destino = CFrame.lookAt(posicion, posicion + mira) * CFrame.Angles(0, -math.pi / 2, 0)
		companero:PivotTo(companero:GetPivot():Lerp(destino, 0.44))
	end
end
