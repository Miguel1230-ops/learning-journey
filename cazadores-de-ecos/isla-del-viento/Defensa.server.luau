-- Cazadores de Ecos · Isla del Viento
-- El servidor lleva la pelea y entrega el rescate y la mutación.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local isla = workspace:WaitForChild("IslaDelViento")
local accion = ReplicatedStorage:WaitForChild("AccionViento")
local Planeadores = require(ReplicatedStorage:WaitForChild("Planeadores"))
local FormacionEcos = require(ReplicatedStorage:WaitForChild("FormacionEcos"))
local Baston = require(script.Parent:WaitForChild("BastonResonancia"))
local nido = isla.Nido
local cometa = nido.Cometa
local nucleo = nido.Nucleo
local ruta = isla.Rutas
local efectos = Instance.new("Folder")
efectos.Name = "EfectosDeViento"
efectos.Parent = isla

local VERDE = Color3.fromRGB(120, 255, 219)
local ORO = Color3.fromRGB(255, 211, 125)
local ROJO = Color3.fromRGB(255, 119, 115)
local CIAN = Color3.fromRGB(119, 207, 255)
local CENTRO_NIDO = nido.Base.Position
local VIDA_NIDO = 100
local ALCANCE_BASTON = 8
local RECARGA = 0.97
local PISO = 20.1

local jugador
local fase = "Inicio"
local vidaNido = VIDA_NIDO
local pendientes = 0
local vuelos = {}
local seguidores = {}
local presentes = {}
local plantilla = cometa:Clone()
local partesNido = {}
for _, parte in cometa:GetDescendants() do
	if parte:IsA("BasePart") then partesNido[parte] = parte.Transparency end
end
local companeros = Instance.new("Folder")
companeros.Name = "CompanerosCometa"
companeros.Parent = isla
local avatarReciente

local function ahora()
	return workspace:GetServerTimeNow()
end

local function punto(posicion, nombre, texto, distancia)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Accion"
	p.ObjectText = nombre
	p.ActionText = texto
	p.MaxActivationDistance = distancia
	p.RequiresLineOfSight = false
	p.ClickablePrompt = true
	p.Parent = posicion
	return p
end

local comenzar = punto(isla.Totem, "Nido del Eco Cometa", "Defender nido", 9)
local rescatar = punto(nido.PuntoRescate, "Eco Cometa", "Rescatar", 8.2)
local refugio = punto(ruta.Refugio, "Refugio del viento", "Completar rescate", 9)
local balcon = punto(ruta.Baliza, "Cornisa de los vientos", "Activar baliza", 8)
rescatar.Enabled = false
refugio.Enabled = false
balcon.Enabled = false

local bitacora = require(game.ReplicatedStorage:WaitForChild("BitacoraUI"))
local function cartel(parte, nombre, emblema, tono, altura, distancia)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Size, gui.MaxDistance = "Cartel", UDim2.fromOffset(160, 30), distancia
	gui.StudsOffsetWorldSpace, gui.Parent = Vector3.yAxis * altura, parte
	local sello = bitacora.icono(gui, emblema, 22, tono, UDim2.fromOffset(1,3))
	sello.BackgroundTransparency = 1
	local nombreLugar = Instance.new("TextLabel")
	nombreLugar.BackgroundTransparency, nombreLugar.Font = 1, Enum.Font.GothamBold
	nombreLugar.Size, nombreLugar.Position = UDim2.new(1,-28,1,-4), UDim2.fromOffset(27,0)
	nombreLugar.TextColor3, nombreLugar.TextStrokeTransparency = Color3.fromRGB(255,246,223), .22
	nombreLugar.TextStrokeColor3, nombreLugar.TextXAlignment = Color3.fromRGB(17,39,53), Enum.TextXAlignment.Left
	nombreLugar.TextSize, nombreLugar.Text, nombreLugar.Parent = 13, nombre, gui
	local filete = Instance.new("Frame")
	filete.BorderSizePixel, filete.BackgroundColor3 = 0, tono
	filete.Size, filete.Position, filete.Parent = UDim2.fromOffset(36,1), UDim2.fromOffset(28,25), gui
end
cartel(ruta.PuertaPuente, "Puente al refugio", "Brujula", ORO, 3.7, 47)
cartel(ruta.PuertaPlaneo, "Aro del Viento", "Ala", VERDE, 3.7, 47)
cartel(ruta.CorazonCorriente, "Corriente ascendente", "Viento", CIAN, 3.5, 34)

local function objetivo(siguiente, titulo, pista)
	fase = siguiente
	isla:SetAttribute("Fase", fase)
	isla:SetAttribute("Titulo", titulo)
	isla:SetAttribute("Pista", pista)
	if jugador then
		jugador:SetAttribute("FaseNido", fase)
		jugador:SetAttribute("TituloNido", titulo)
		jugador:SetAttribute("PistaNido", pista)
	end
end

local function actualizarNido()
	isla:SetAttribute("VidaNido", vidaNido)
	isla:SetAttribute("VigiasActivos", pendientes)
	nucleo.Color = ROJO:Lerp(ORO, vidaNido / VIDA_NIDO)
end

local function personajeActivo(quien)
	local personaje = quien and quien.Character
	local h = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local root = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if h and h.Health > 0 and root then
		return root, h
	end
	return nil
end

local function dentro(posicion, zona)
	local diferencia = zona.CFrame:PointToObjectSpace(posicion)
	local tamano = zona.Size / 2
	return math.abs(diferencia.X) <= tamano.X
		and math.abs(diferencia.Y) <= tamano.Y
		and math.abs(diferencia.Z) <= tamano.Z
end

local function vectorPlano(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function enArena(v)
	return Vector3.new(math.clamp(v.X, -34, 21), v.Y, math.clamp(v.Z, -24, 24))
end

local function cercaDeAccion(quien, p)
	local root = personajeActivo(quien)
	return p.Enabled and root and quien:GetAttribute("ProgresoListo") == true
		and (root.Position - p.Parent.Position).Magnitude <= p.MaxActivationDistance + 0.75
end

local function libreEnIsla(p)
	return not p:GetAttribute("EnCueva") and not p:GetAttribute("EnMolino") and not p:GetAttribute("EnFaro")
		and not p:GetAttribute("EnEncargoPedernal")
end

local function piezaEfecto(nombre, tamano, posicion, tono)
	local parte = Instance.new("Part")
	parte.Name = nombre
	parte.Size = tamano
	parte.CFrame = posicion
	parte.Material = Enum.Material.Neon
	parte.Color = tono
	parte.Anchored = true
	parte.CanCollide = false
	parte.CanTouch = false
	parte.CanQuery = false
	parte.CastShadow = false
	parte.Parent = efectos
	return parte
end

local function disco(nombre, centro, radio, tono)
	local p = piezaEfecto(nombre, Vector3.new(0.09, radio * 2, radio * 2),
		CFrame.new(centro) * CFrame.Angles(0, 0, math.pi / 2), tono)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ficha(modelo, cazador, rapidez, golpes, demora)
	local visibilidad = {}
	for _, parte in ipairs(modelo:GetDescendants()) do
		if parte:IsA("BasePart") then
			visibilidad[parte] = parte.Transparency
		end
	end
	local base = modelo.PrimaryPart
	local gui = Instance.new("BillboardGui")
	gui.Name = "Vida"
	gui.Size = UDim2.fromOffset(104, 35)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.3, 0)
	gui.MaxDistance = 42
	gui.Parent = base
	local texto = Instance.new("TextLabel")
	texto.BackgroundTransparency = 1
	texto.Size = UDim2.fromScale(1, 1)
	texto.Font = Enum.Font.GothamBold
	texto.TextSize = 12
	texto.TextColor3 = Color3.fromRGB(255, 248, 231)
	texto.TextStrokeTransparency = 0.45
	texto.Parent = gui
	return {
		modelo = modelo, original = modelo:GetPivot(), visibilidad = visibilidad, gui = gui, texto = texto,
		cazador = cazador, rapidez = rapidez, maxGolpes = golpes, demora = demora, estado = "Fuera",
		pos = base.Position, frente = -Vector3.xAxis, salud = golpes, hasta = 0, listoEn = 0,
	}
end

local vigias = {
	ficha(isla.Vigias.Embestidor, true, 8.4, 2, 0.25),
	ficha(isla.Vigias.Rompenidos, false, 5.3, 3, 1.3),
}

local function mostrarVigia(v, aparece)
	for parte, transparencia in pairs(v.visibilidad) do
		parte.Transparency = if aparece then transparencia else 1
	end
	v.gui.Enabled = aparece
end

local function quitarAviso(v)
	if v.aviso then
		v.aviso:Destroy()
		v.aviso = nil
	end
end

local function ponerVigia(v)
	v.modelo:PivotTo(CFrame.lookAt(v.pos, v.pos + v.frente))
end

local function rotulo(v, aviso)
	v.texto.Text = aviso or ("%s  %d/%d"):format(v.modelo.Name, v.salud, v.maxGolpes)
end

local function desactivarVigias()
	for _, v in ipairs(vigias) do
		v.estado = "Fuera"
		quitarAviso(v)
		mostrarVigia(v, false)
	end
end

local function prepararDefensa(quien)
	if jugador or quien:GetAttribute("Cometa") or quien:GetAttribute("VigiasDerrotados")
		or not libreEnIsla(quien) or not cercaDeAccion(quien, comenzar) then
		return
	end
	jugador = quien
	isla:SetAttribute("CombatienteNido", quien.UserId)
	avatarReciente = quien.Character
	local _, humanoide = personajeActivo(quien)
	humanoide.Health = humanoide.MaxHealth
	comenzar.Enabled = false
	vidaNido = VIDA_NIDO
	pendientes = #vigias
	local tiempo = ahora()
	for _, barra in nido.Barrera:GetChildren() do
		if barra:IsA("BasePart") then barra.Transparency = 0.5 end
	end
	for _, v in ipairs(vigias) do
		v.pos = v.original.Position
		v.frente = -Vector3.xAxis
		v.salud = v.maxGolpes
		v.estado = "Llegando"
		v.hasta = tiempo + v.demora
		v.listoEn = 0
		v.golpeoNido = false
		v.golpeoJugador = false
		quitarAviso(v)
		ponerVigia(v)
		mostrarVigia(v, false)
	end
	actualizarNido()
	Baston.equipar(quien.Character)
	objetivo("Defensa", "Defiende al Eco Cometa", "Mira al vigía, acércate y golpea con el bastón.")
end
comenzar.Triggered:Connect(prepararDefensa)

local function liberarTurno()
	jugador = nil
	avatarReciente = nil
	fase = "Inicio"
	isla:SetAttribute("Fase", fase)
	isla:SetAttribute("CombatienteNido", nil)
	comenzar.Enabled = false
	for p in presentes do
		if p:GetAttribute("ProgresoListo") and not p:GetAttribute("VigiasDerrotados") and not p:GetAttribute("Cometa") then
			comenzar.Enabled = true
			break
		end
	end
end

local function perder(texto)
	Baston.quitar(jugador and jugador.Character)
	desactivarVigias()
	pendientes = 0
	actualizarNido()
	comenzar.ActionText = "Reintentar defensa"
	comenzar.Enabled = true
	objetivo("Perdido", "El nido necesita otro intento", texto)
	liberarTurno()
end

local function victoria()
	jugador:SetAttribute("VigiasDerrotados", true)
	rescatar.Enabled = true
	nucleo.Color = VERDE
	for _, barra in ipairs(nido.Barrera:GetChildren()) do
		TweenService:Create(barra, TweenInfo.new(0.32), { Transparency = 1 }):Play()
	end
	objetivo("Rescate", "¡Nido a salvo!", "Acércate al nido y rescata al Cometa.")
	liberarTurno()
end

local function danoAlNido(cantidad)
	vidaNido = math.max(0, vidaNido - cantidad)
	actualizarNido()
	if vidaNido == 0 then
		perder("Vuelve al tótem para defenderlo de nuevo.")
	end
end

local function ataquePreparado(v, destino, tiempo)
	v.estado = "Aviso"
	quitarAviso(v)
	local diferencia = vectorPlano(destino - v.pos)
	if diferencia.Magnitude > 0.05 then
		v.frente = diferencia.Unit
	end
	ponerVigia(v)
	if v.cazador then
		v.hasta = tiempo + 0.8
		v.avance = 14
		local inicio = Vector3.new(v.pos.X, PISO, v.pos.Z)
		local centro = inicio + v.frente * (v.avance / 2)
		v.aviso = piezaEfecto("AvisoEmbestida", Vector3.new(6.4, 0.13, v.avance),
			CFrame.lookAt(centro, centro + v.frente), ROJO)
		rotulo(v, "¡EMBESTIDA!")
	else
		v.hasta = tiempo + 0.95
		v.aviso = disco("AvisoAlNido", Vector3.new(CENTRO_NIDO.X, PISO, CENTRO_NIDO.Z), 5.6, ROJO)
		rotulo(v, "¡AL NIDO!")
	end
	v.aviso.Transparency = 0.27
end

local function actualizarVigia(v, root, humanoide, dt, tiempo)
	if v.estado == "Fuera" or v.estado == "Derrotado" then
		return
	end

	if v.estado == "Llegando" then
		if tiempo >= v.hasta then
			v.estado = "Avanza"
			mostrarVigia(v, true)
			rotulo(v)
		end
		return
	end

	if v.estado == "Aturdido" or v.estado == "Recupera" then
		if tiempo >= v.hasta then
			v.estado = "Avanza"
			rotulo(v)
		end
		return
	end

	if v.estado == "Aviso" then
		if tiempo < v.hasta then
			return
		end
		quitarAviso(v)
		if v.cazador then
			v.estado = "Embestida"
			v.golpeoJugador = false
			v.golpeoNido = false
		else
			v.estado = "Recupera"
			v.hasta = tiempo + 2.4
			danoAlNido(27)
			if vectorPlano(root.Position - CENTRO_NIDO).Magnitude < 5.5 and root.Position.Y < 26 then
				humanoide:TakeDamage(14)
			end
		end
		rotulo(v)
		return
	end

	if v.estado == "Embestida" then
		local paso = math.min(v.avance, 28 * dt)
		v.avance -= paso
		v.pos = enArena(v.pos + v.frente * paso)
		ponerVigia(v)
		if not v.golpeoJugador and vectorPlano(root.Position - v.pos).Magnitude < 3.7 and root.Position.Y < 26 then
			v.golpeoJugador = true
			humanoide:TakeDamage(32)
		end
		if not v.golpeoNido and vectorPlano(CENTRO_NIDO - v.pos).Magnitude < 3.5 then
			v.golpeoNido = true
			danoAlNido(22)
			if fase ~= "Defensa" then
				return
			end
		end
		if v.avance <= 0 then
			v.estado = "Recupera"
			v.hasta = tiempo + 1.38
		end
		return
	end

	local persigue = v.cazador and vectorPlano(root.Position - v.pos).Magnitude < 20 and root.Position.Y < 27
	local destino = if persigue then root.Position else CENTRO_NIDO
	local delta = vectorPlano(destino - v.pos)
	local radio = if v.cazador then 12.5 else 5.3
	if delta.Magnitude <= radio and tiempo >= v.listoEn then
		ataquePreparado(v, destino, tiempo)
	elseif delta.Magnitude > 0.1 then
		v.frente = delta.Unit
		v.pos = enArena(v.pos + v.frente * math.min(v.rapidez * dt, delta.Magnitude))
		ponerVigia(v)
	end
end

local function registrarPlaneo(quien, tipo)
	local vuelo = vuelos[quien]
	if tipo == "PlegarPlaneo" then
		if vuelo then quien:SetAttribute("PlaneoIslaHasta", 0) end
		return
	end
	local personaje = quien.Character
	local h = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local root = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if not root or not h or h.Health <= 0 or not quien:GetAttribute("Cometa")
		or quien:GetAttribute("EnCueva") or quien:GetAttribute("EnMolino") or quien:GetAttribute("EnFaro") then return end
	if not vuelo or vuelo.humanoide ~= h then
		if vuelo then vuelo.suelo:Disconnect() end
		vuelo = { humanoide = h, hasta = 0 }
		vuelos[quien] = vuelo
		vuelo.suelo = h:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
			if h.FloorMaterial ~= Enum.Material.Air then vuelo.hasta = 0 end
		end)
	end
	local tiempo = ahora()
	if tiempo < vuelo.hasta then return end
	local avanzado = quien:GetAttribute("PlaneadorEquipado") == "Avanzado" and quien:GetAttribute("PlaneadorAvanzado") == true
	local ajustes = Planeadores.ajustes(avanzado)
	vuelo.hasta = tiempo + ajustes.ventanaServidor
	quien:SetAttribute("PlaneoIslaHasta", vuelo.hasta)
end

local function golpearVigias(root)
	if fase ~= "Defensa" then
		return
	end
	local tiempo = ahora()
	for _, v in ipairs(vigias) do
		local cerca = Baston.enArco(root,v.pos,ALCANCE_BASTON)
		if cerca and v.estado ~= "Fuera" and v.estado ~= "Llegando" and v.estado ~= "Derrotado" then
			Baston.impacto(v.pos,"Vigia",efectos)
			v.salud -= 1
			quitarAviso(v)
			if v.salud == 0 then
				v.estado = "Derrotado"
				mostrarVigia(v, false)
				pendientes -= 1
			else
				local empuje = vectorPlano(v.pos - root.Position)
				if empuje.Magnitude > 0.1 then
					v.pos = enArena(v.pos + empuje.Unit * 5.2)
				end
				ponerVigia(v)
				v.estado = "Aturdido"
				v.hasta = tiempo + 0.67
				v.listoEn = tiempo + 0.95
				rotulo(v)
			end
		end
	end

	actualizarNido()
	if pendientes == 0 then
		victoria()
		Baston.quitar(root.Parent)
	end
end

accion.OnServerEvent:Connect(function(quien, tipo)
	if tipo == "Planeo" or tipo == "PlegarPlaneo" then
		registrarPlaneo(quien, tipo)
		return
	end
	local propia = quien:GetAttribute("FaseNido")
	if tipo ~= "GolpeBaston" or not libreEnIsla(quien) or not quien:GetAttribute("ProgresoListo")
		or (propia ~= "Inicio" and propia ~= "Perdido" and not (propia == "Defensa" and quien == jugador)) then return end
	local root = personajeActivo(quien)
	local tiempo = ahora()
	if not root or tiempo < (quien:GetAttribute("RafagaListaEn") or 0) then return end
	quien:SetAttribute("RafagaListaEn",tiempo+RECARGA)
	Baston.golpear(root,function()
		if propia == "Defensa" and quien == jugador and quien.Character == root.Parent then golpearVigias(root) end
	end,function() return quien ~= jugador or fase ~= "Defensa" end)
end)

rescatar.Triggered:Connect(function(quien)
	if quien:GetAttribute("VigiasDerrotados") and not quien:GetAttribute("Cometa")
		and libreEnIsla(quien) and cercaDeAccion(quien, rescatar) then
		quien:SetAttribute("Cometa", true)
	end
end)

refugio.Triggered:Connect(function(quien)
	if quien:GetAttribute("Cometa") and not quien:GetAttribute("Refugio")
		and libreEnIsla(quien) and cercaDeAccion(quien, refugio) then
		quien:SetAttribute("Refugio", true)
	end
end)

balcon.Triggered:Connect(function(quien)
	if quien:GetAttribute("Vendaval") and not quien:GetAttribute("Cornisa")
		and libreEnIsla(quien) and cercaDeAccion(quien, balcon) then
		quien:SetAttribute("Cornisa", true)
	end
end)

local function actualizarPuntos(saliendo)
	local nidoLibre, rescate, vuelta, cornisa, mutada = false, false, false, false, false
	for _, p in Players:GetPlayers() do
		if p == saliendo or not p:GetAttribute("ProgresoListo") then continue end
		local tiene, gano = p:GetAttribute("Cometa"), p:GetAttribute("VigiasDerrotados")
		nidoLibre = nidoLibre or not (tiene or gano)
		rescate = rescate or (not tiene and gano == true)
		vuelta = vuelta or (tiene == true and not p:GetAttribute("Refugio"))
		cornisa = cornisa or (p:GetAttribute("Vendaval") == true and not p:GetAttribute("Cornisa"))
		mutada = mutada or p:GetAttribute("Vendaval") == true
	end
	comenzar.Enabled = not jugador and nidoLibre
	rescatar.Enabled, refugio.Enabled, balcon.Enabled = rescate, vuelta, cornisa
	for parte, original in partesNido do
		parte.Transparency = if nidoLibre or rescate then original else 1
	end
	ruta.CorazonCorriente.Color = if mutada then CIAN else VERDE
end

local function sincronizarCompanero(p)
	local tiene = p:GetAttribute("Cometa")
	local modelo = seguidores[p]
	if not tiene or p:GetAttribute("EnCueva") or not personajeActivo(p) then
		if modelo then modelo:Destroy(); seguidores[p] = nil end
		return
	end
	if not modelo then
		modelo = plantilla:Clone()
		modelo.Name = tostring(p.UserId)
		modelo:SetAttribute("Propietario", p.UserId)
		modelo:PivotTo(FormacionEcos.pose("Cometa", personajeActivo(p).CFrame, ahora()))
		seguidores[p] = modelo
	end
	if p:GetAttribute("Vendaval") and not modelo:GetAttribute("Vendaval") then
		for _, parte in modelo:GetDescendants() do
			if parte:IsA("BasePart") and (parte.Material == Enum.Material.Neon or parte == modelo.PrimaryPart) then
				parte.Color = CIAN
			elseif parte:IsA("Light") then
				parte.Color = CIAN
			end
		end
		modelo:ScaleTo(1.25)
		modelo:SetAttribute("Vendaval", true)
	end
	modelo.Parent = companeros
end

local function recibeJugador(nuevo)
	if presentes[nuevo] then return end
	presentes[nuevo] = true
	nuevo.RespawnLocation = isla.Inicio
	nuevo:SetAttribute("FaseNido", "Inicio")
	nuevo:SetAttribute("RafagaListaEn", 0)
	nuevo:SetAttribute("PlaneoIslaHasta", 0)
	local function recuperarProgreso()
		if not presentes[nuevo] then return end
		if nuevo:GetAttribute("Cometa") then
			isla.PuntoRetorno.Enabled = true
			nuevo.RespawnLocation = isla.PuntoRetorno
			ruta.PuertaPlaneo.CanCollide, ruta.PuertaPlaneo.Transparency = false, 1
			local siguiente = if nuevo:GetAttribute("Cornisa") then "Cornisa" elseif nuevo:GetAttribute("Refugio") then "Refugio" else "Regreso"
			nuevo:SetAttribute("FaseNido", siguiente)
		elseif nuevo:GetAttribute("VigiasDerrotados") then
			nuevo:SetAttribute("FaseNido", "Rescate")
		end
		if nuevo:GetAttribute("Cornisa") then
			ruta.Baliza.Color = ORO
		end
		sincronizarCompanero(nuevo)
		actualizarPuntos()
	end
	for _, nombre in {"ProgresoListo", "VigiasDerrotados", "Cometa", "Vendaval", "Refugio", "Cornisa", "EnCueva"} do
		nuevo:GetAttributeChangedSignal(nombre):Connect(recuperarProgreso)
	end
	local function cargarAvatar(c)
		if c:WaitForChild("HumanoidRootPart", 10) and c:WaitForChild("Humanoid", 10) and presentes[nuevo] and nuevo.Character == c then
			sincronizarCompanero(nuevo)
		end
	end
	nuevo.CharacterAdded:Connect(cargarAvatar)
	if nuevo.Character then task.spawn(cargarAvatar, nuevo.Character) end
	nuevo.CharacterRemoving:Connect(function()
		if seguidores[nuevo] then seguidores[nuevo]:Destroy(); seguidores[nuevo] = nil end
		if jugador == nuevo then perder("El tótem te permite volver a intentarlo.") end
	end)
	recuperarProgreso()
end

desactivarVigias()
actualizarNido()
objetivo("Inicio", "Rescate en la Isla del Viento", "Acércate al tótem y usa el bastón para defender el nido.")
Players.PlayerAdded:Connect(recibeJugador)
Players.PlayerRemoving:Connect(function(p)
	presentes[p] = nil
	if jugador == p then perder("El tótem está libre.") end
	local vuelo, eco = vuelos[p], seguidores[p]
	if vuelo then vuelo.suelo:Disconnect() end
	if eco then eco:Destroy() end
	vuelos[p], seguidores[p] = nil, nil
	actualizarPuntos(p)
end)
for _, conectado in ipairs(Players:GetPlayers()) do
	recibeJugador(conectado)
end

while true do
	local dt = math.min(task.wait(0.055), 0.12)
	local tiempo = ahora()
	local root, humanoide = personajeActivo(jugador)
	if fase == "Defensa" then
		if not root or (avatarReciente and root.Parent ~= avatarReciente) or not libreEnIsla(jugador)
			or (root.Position - CENTRO_NIDO).Magnitude > 70 then
			perder("El tótem te permite volver a intentarlo.")
		else
			for _, v in ipairs(vigias) do
				actualizarVigia(v, root, humanoide, dt, tiempo)
				if fase ~= "Defensa" then
					break
				end
			end
		end
	end
	avatarReciente = root and root.Parent
	for p, eco in seguidores do
		local raiz = personajeActivo(p)
		if raiz and not p:GetAttribute("EnCueva") then
			if not p:GetAttribute("Vendaval") and libreEnIsla(p) and tiempo < (p:GetAttribute("PlaneoIslaHasta") or 0)
				and dentro(raiz.Position, ruta.ZonaAro) then p:SetAttribute("Vendaval", true) end
			eco:PivotTo(FormacionEcos.pose("Cometa", raiz.CFrame, tiempo, eco:GetPivot(), 1 - math.exp(-dt * 6)))
		end
	end
end
