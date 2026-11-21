local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local datos = require(ServerScriptService:WaitForChild("ProgresoDatos"))
local comprar = ServerScriptService:WaitForChild("ComprarMejoraRefugio")
local comprarPlaneador = ServerScriptService:WaitForChild("ComprarPlaneadorRefugio")
local equiparPlaneador = ServerScriptService:WaitForChild("EquiparPlaneadorRefugio")
local remoto = ReplicatedStorage:WaitForChild("AccionRefugio")
local isla = workspace:WaitForChild("IslaDelViento")
local refugio = isla:WaitForChild("RefugioDelViento")
local puntoFarero = refugio:WaitForChild("PuntoFarero")
local zona = refugio:WaitForChild("ZonaEncargo")
local primera = refugio:WaitForChild("ZonaRafaga1")
local segunda = refugio:WaitForChild("ZonaRafaga2")
local vientoVisual = require(ServerScriptService:WaitForChild("VientoVisual"))

local ESPERA_RELEVO = 7
local DURACION_ESCUDO = 2.35
local BARRERA = Color3.fromRGB(130, 207, 255)
local encargos = {}

local function ahora()
	return workspace:GetServerTimeNow()
end

local function crearPrompt(pieza, objeto, accion, alcance)
	local p = Instance.new("ProximityPrompt")
	p.Name = "Accion"
	p.ObjectText = objeto
	p.ActionText = accion
	p.MaxActivationDistance = alcance
	p.RequiresLineOfSight = false
	p.ClickablePrompt = true
	p.Parent = pieza
	return p
end

local hablar = crearPrompt(puntoFarero, "Farero del viento", "Hablar", 8.25)
local inicio = crearPrompt(refugio:WaitForChild("InicioEncargo"), "Relevo de los faroles", "Aceptar encargo", 6.4)
local meta = crearPrompt(refugio:WaitForChild("MetaEncargo"), "Relevo de los faroles", "Entregar encargo", 6.8)
inicio.Enabled = false
meta.Enabled = false

local function raiz(jugador)
	local personaje = jugador.Character
	local h = personaje and personaje:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then
		return personaje:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function enIsla(jugador)
	return not jugador:GetAttribute("EnCueva") and not jugador:GetAttribute("EnMolino")
		and not jugador:GetAttribute("EnFaro")
		and jugador:GetAttribute("FaseNido") ~= "Defensa"
end

local function alAlcance(jugador, p)
	local root = raiz(jugador)
	return enIsla(jugador) and root and (root.Position - p.Parent.Position).Magnitude <= p.MaxActivationDistance + 0.65
end

local function dentro(pieza, posicion, margen)
	local d = pieza.CFrame:PointToObjectSpace(posicion)
	local mitad = pieza.Size * 0.5
	return math.abs(d.X) <= mitad.X + margen and math.abs(d.Y) <= mitad.Y + margen
		and math.abs(d.Z) <= mitad.Z + margen
end

local function limpiar(jugador)
	local encargo = encargos[jugador]
	if encargo and encargo.escudo then
		encargo.escudo:Destroy()
	end
	encargos[jugador] = nil
	jugador:SetAttribute("EnEncargoPedernal", false)
	jugador:SetAttribute("EstadoEncargo", "")
	jugador:SetAttribute("EscudoRefugioHasta", 0)
	jugador:SetAttribute("EscudoRefugioListoEn", 0)
	jugador:SetAttribute("EncargoHasta", 0)
end

local function estado(jugador, encargo, siguiente)
	encargo.fase = siguiente
	jugador:SetAttribute("EstadoEncargo", siguiente)
end

local function puedeAceptar(jugador)
	return jugador:GetAttribute("ProgresoListo") == true and jugador:GetAttribute("MejoraPedernal") == true
		and not jugador:GetAttribute("EncargoPedernal")
end

hablar.Triggered:Connect(function(jugador)
	if alAlcance(jugador, hablar) then
		if jugador:GetAttribute("ProgresoListo") then
			if jugador:GetAttribute("Lucero") then
				jugador:SetAttribute("ConsejoLente", true)
			elseif jugador:GetAttribute("Cometa") and jugador:GetAttribute("Refugio") then
				jugador:SetAttribute("ConsejoGeoda", true)
			end
		end
		remoto:FireClient(jugador, "AbrirTienda")
	end
end)

inicio.Triggered:Connect(function(jugador)
	if encargos[jugador] or not puedeAceptar(jugador) or not alAlcance(jugador, inicio) then
		return
	end
	local encargo = { escudoHasta = 0, recarga = 0, hasta = 0, avatar = jugador.Character }
	encargos[jugador] = encargo
	estado(jugador, encargo, "Primero")
	jugador:SetAttribute("EnEncargoPedernal", true)
end)

meta.Triggered:Connect(function(jugador)
	local encargo = encargos[jugador]
	if not encargo or encargo.fase ~= "Meta" or not alAlcance(jugador, meta) then
		return
	end
	limpiar(jugador)
	jugador:SetAttribute("EncargoPedernal", true)
	remoto:FireClient(jugador, "EncargoCompleto")
end)

local function burbuja(root)
	local p = Instance.new("Part")
	p.Name = "EscudoDelRelevo"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(6.5, 6.5, 6.5)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Transparency = 0.86
	p.Color = BARRERA
	p.Material = Enum.Material.ForceField
	p.Position = root.Position
	p.Parent = refugio
	return p
end

local function activarEscudo(jugador)
	local encargo = encargos[jugador]
	local root = raiz(jugador)
	if not encargo or not root or not enIsla(jugador) or not puedeAceptar(jugador) then
		return
	end
	local t = ahora()
	if t < encargo.recarga then
		return
	end
	if encargo.fase == "Segundo" or encargo.fase == "Reintentar" then
		if (encargo.fase=="Segundo" and t > encargo.hasta) or not dentro(segunda, root.Position, 0.32) then
			return
		end
		estado(jugador, encargo, "Meta")
		jugador:SetAttribute("EncargoHasta", 0)
	elseif encargo.fase == "Primero"
		and dentro(primera, root.Position, 0.32) then
		encargo.hasta = t + ESPERA_RELEVO
		jugador:SetAttribute("EncargoHasta", encargo.hasta)
		estado(jugador, encargo, "Segundo")
	else
		return
	end
	encargo.escudoHasta = t + DURACION_ESCUDO
	encargo.recarga = t + datos.RecargaEscudo({ MejoraPedernal = true })
	jugador:SetAttribute("EscudoRefugioHasta", encargo.escudoHasta)
	jugador:SetAttribute("EscudoRefugioListoEn", encargo.recarga)
	if not encargo.escudo then
		encargo.escudo = burbuja(root)
		vientoVisual.escudo(encargo.escudo)
	end
	vientoVisual.impacto(root.Position, -Vector3.zAxis, "Bloqueo", refugio)
end

local function confirmarCompra(jugador, servicio, evento, numero)
	if not alAlcance(jugador, hablar) then
		remoto:FireClient(jugador, evento, false, "Lejos", nil, numero)
		return
	end
	local ok, codigo = servicio:Invoke(jugador)
	if jugador.Parent == Players then
		remoto:FireClient(jugador, evento, ok, codigo, nil, numero)
	end
end

local function prepararSalidaAlFaro(jugador)
	local destino = isla:FindFirstChild("RuinasDelFaro")
	local salida = destino and destino:FindFirstChild("Despegue")
	local root = raiz(jugador)
	if not root or not salida or not alAlcance(jugador, hablar) or jugador:GetAttribute("EnEncargoPedernal") then
		remoto:FireClient(jugador, "SalidaAlFaro", false, "Lejos")
		return
	end
	if not jugador:GetAttribute("Lucero") then
		remoto:FireClient(jugador, "SalidaAlFaro", false, "FaltaLucero")
		return
	end
	if (jugador:GetAttribute("Nivel") or 1) < 2 then
		remoto:FireClient(jugador, "SalidaAlFaro", false, "FaltaNivel")
		return
	end
	if not jugador:GetAttribute("LenteGeoda") then
		remoto:FireClient(jugador, "SalidaAlFaro", false, "FaltaLente")
		return
	end
	local desde = Vector3.new(salida.Position.X, 23.65, salida.Position.Z)
	jugador.Character:PivotTo(CFrame.lookAt(desde, desde + Vector3.zAxis))
	root.AssemblyLinearVelocity = Vector3.zero
	remoto:FireClient(jugador, "SalidaAlFaro", true, "Preparada")
end

remoto.OnServerEvent:Connect(function(jugador, mensaje, numero)
	numero = if type(numero) == "number" and numero > 0 and numero < 2^53 then numero else nil
	if mensaje == "ComprarPedernal" then
		confirmarCompra(jugador, comprar, "ResultadoCompra", numero)
	elseif mensaje == "ComprarPlaneador" then
		confirmarCompra(jugador, comprarPlaneador, "ResultadoPlaneador", numero)
	elseif mensaje == "EquiparBasico" or mensaje == "EquiparAvanzado" then
		local eleccion = if mensaje == "EquiparBasico" then "Basico" else "Avanzado"
		local ok, codigo = equiparPlaneador:Invoke(jugador, eleccion)
		if jugador.Parent == Players then
			remoto:FireClient(jugador, "ResultadoEquipo", ok, codigo, mensaje, numero)
		end
	elseif mensaje == "PrepararFaro" then
		prepararSalidaAlFaro(jugador)
	elseif mensaje == "Escudo" then
		activarEscudo(jugador)
	end
end)

if RunService:IsStudio() and game.GameId == 0 and isla:GetAttribute("AtajosDePrueba") == true then
	local p = Instance.new("Part")
	p.Name = "PruebaDelRefugio"
	p.Size = Vector3.new(1.57, 1.78, 1.57)
	p.Color = Color3.fromRGB(128, 255, 207)
	p.Material = Enum.Material.Neon
	p.CFrame = CFrame.new(-53.6, 22.2, 8.25) * CFrame.Angles(0.32, 0, 0.43)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.Parent = isla
	local prueba = crearPrompt(p, "Refugio del Viento", "Probar nivel y tienda", 7)
	prueba.Triggered:Connect(function(jugador)
		local root = raiz(jugador)
		if not root or not alAlcance(jugador, prueba) or not jugador:GetAttribute("ProgresoListo") then
			return
		end
		for _, premio in ipairs({ "Cometa", "Pedernal", "MolinoVista", "Lucero", "Refugio" }) do
			jugador:SetAttribute(premio, true)
		end
		local posicion = Vector3.new(82.4, 23.65, 3.1)
		local frente = Vector3.new(puntoFarero.Position.X, posicion.Y, puntoFarero.Position.Z)
		jugador.Character:PivotTo(CFrame.lookAt(posicion, frente))
		root.AssemblyLinearVelocity = Vector3.zero
	end)
end

Players.PlayerRemoving:Connect(limpiar)
inicio.Enabled, meta.Enabled = true, true
while task.wait(0.07) do
	local t = ahora()
	for _, jugador in ipairs(Players:GetPlayers()) do
		local encargo = encargos[jugador]
		if encargo then
			local root = raiz(jugador)
			if not root or jugador.Character ~= encargo.avatar or not enIsla(jugador)
				or not dentro(zona, root.Position, 8.2) then
				limpiar(jugador)
			else
				if encargo.fase == "Segundo" and t >= encargo.hasta then
					estado(jugador, encargo, "Reintentar")
					jugador:SetAttribute("EncargoHasta", 0)
				end
				if encargo.escudo then
					if t < encargo.escudoHasta then
						encargo.escudo.Position = root.Position
					else
						encargo.escudo:Destroy()
						encargo.escudo = nil
					end
				end
			end
		end
	end
end
