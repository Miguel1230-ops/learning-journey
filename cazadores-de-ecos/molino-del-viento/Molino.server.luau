local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local datos = require(ServerScriptService:WaitForChild("ProgresoDatos"))
local VientoVisual = require(ServerScriptService:WaitForChild("VientoVisual"))
local LuceroCompaneros = require(ServerScriptService:WaitForChild("LuceroCompaneros"))
local isla = workspace:WaitForChild("IslaDelViento")
local molino = isla:WaitForChild("MolinoDelViento")
local remoto = ReplicatedStorage:WaitForChild("AccionMolino")
local llegada = molino:WaitForChild("Llegada")
local despegue = molino:WaitForChild("PlayaDespegue")
local zona = molino:WaitForChild("ZonaViento")
local chispa = molino:WaitForChild("Chispa")
local farol = molino:WaitForChild("Farol")
local lucero = molino:WaitForChild("Lucero")
local aspas = molino:WaitForChild("Aspas")
local marcoAspas = aspas:GetPivot()
local marcoChispa = chispa.CFrame
-- La plantilla se replica con su aspecto original, incluso si otro jugador tiene el molino apagado.
if not ReplicatedStorage:FindFirstChild("LuceroCompanero") then
	local plantilla = lucero:Clone()
	plantilla.Name = "LuceroCompanero"
	plantilla.Parent = ReplicatedStorage
end
local companeros = LuceroCompaneros.new(isla, ReplicatedStorage.LuceroCompanero, farol, llegada, aspas)

local ORO = Color3.fromRGB(255, 213, 131)
local MENTA = Color3.fromRGB(149, 244, 224)
local CIELO = Color3.fromRGB(120, 207, 255)
local LLEGADA_DURACION = 6.25
local FINAL_DURACION = 4.45
local ESCUDO_DURACION = 2.35
local efectosViento = Instance.new("Folder")
efectosViento.Name, efectosViento.Parent = "RafagasDelTurno", molino

local luces = {}
for _, hijo in ipairs(molino:WaitForChild("Luces"):GetChildren()) do
	if hijo:IsA("BasePart") then
		table.insert(luces, hijo)
	end
end
table.sort(luces, function(a, b)
	return a.Name < b.Name
end)

local aspectoInicial = {}
for _, pieza in {farol, chispa, table.unpack(luces)} do
	local luz = pieza:FindFirstChildWhichIsA("Light")
	aspectoInicial[pieza] = {
		color = pieza.Color, material = pieza.Material, transparencia = pieza.Transparency,
		luz = luz, encendida = luz and luz.Enabled, tonoLuz = luz and luz.Color,
	}
end
for _, objeto in ipairs(lucero:GetDescendants()) do
	if objeto:IsA("BasePart") then
		objeto.Transparency = 1
		objeto.CanCollide, objeto.CanTouch, objeto.CanQuery, objeto.CastShadow = false, false, false, false
	elseif objeto:IsA("Light") then
		objeto.Enabled = false
	end
end

local fase = "Fuera"
local jugador
local enEspera = {}
local finalistas = {}
local ordenLlegada = 0
local hasta = 0
local escenaDesde = 0
local apagadaHasta = 0
local oleadasDesde = 0
local escudoHasta = 0
local escudoListo = 0
local desgaste = 0
local cruzoProtegido = false
local chispaEnManos = false
local iluminado = false
local origenLuz = 0
local lucesEncendidas = 0
local humanoideTitular
local burbuja
local proximaHebra = 0
local proximoImpacto = 0

local function reloj()
	return workspace:GetServerTimeNow()
end

local function estadoPieza(pieza, brillo, activa)
	pieza.Color = brillo
	pieza.Material = if activa then Enum.Material.Neon else Enum.Material.SmoothPlastic
	local luz = pieza:FindFirstChildWhichIsA("Light")
	if luz then
		luz.Color = brillo
		luz.Enabled = activa
	end
end

local function ponerFase(nueva, pista)
	fase = nueva
	molino:SetAttribute("MolinoFase", nueva)
	molino:SetAttribute("PistaMolino", pista)
end

local function interactuar(pieza, accion, titulo, distancia, tecla)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Accion"
	prompt.ActionText = accion
	prompt.ObjectText = titulo
	prompt.MaxActivationDistance = distancia
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = tecla or Enum.KeyCode.E
	prompt.ClickablePrompt = true
	prompt.Enabled = false
	prompt.Parent = pieza
	return prompt
end

local recoger = interactuar(chispa, "Recoger chispa", "Chispa del molino", 7.5)
local encender = interactuar(farol, "Colocar chispa", "Farol del molino", 7.2)
local salir = interactuar(molino:WaitForChild("Regreso"), "Volver a la plaza", "Isla del Viento", 7.3)

local function avatar(quien)
	local personaje = quien and quien.Character
	local h = personaje and personaje:FindFirstChildOfClass("Humanoid")
	local root = personaje and personaje:FindFirstChild("HumanoidRootPart")
	if root and h and h.Health > 0 then
		return root, h
	end
	return nil, nil
end

local function cerca(quien, prompt)
	local root = avatar(quien)
	return root and prompt.Enabled
		and (root.Position - prompt.Parent.Position).Magnitude <= prompt.MaxActivationDistance + 0.65
end

local function mover(quien, punto, objetivo)
	local root = avatar(quien)
	if root then
		local frente = Vector3.new(objetivo.X, punto.Y, objetivo.Z)
		quien.Character:PivotTo(CFrame.lookAt(punto, frente))
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

local function dentroXZ(pieza, posicion, margen)
	local localPos = pieza.CFrame:PointToObjectSpace(posicion)
	local media = pieza.Size * 0.5
	return math.abs(localPos.X) <= media.X + margen and math.abs(localPos.Z) <= media.Z + margen
end

local function limpiarEscudo()
	escudoHasta, escudoListo = 0, 0
	if jugador then
		jugador:SetAttribute("EscudoMolinoHasta", 0)
		jugador:SetAttribute("EscudoMolinoListoEn", 0)
	end
	if burbuja then
		burbuja:Destroy()
		burbuja = nil
	end
end

local function soltar()
	chispaEnManos = false
	jugador:SetAttribute("LlevaChispa", false)
	chispa.CFrame = marcoChispa
	chispa.Transparency = if iluminado then 1 else 0.04
	estadoPieza(chispa, ORO, not iluminado)
	encender.Enabled = false
end

local function apagarMolino()
	origenLuz, lucesEncendidas = 0, 0
	iluminado = false
	chispa.CFrame = marcoChispa
	aspas:PivotTo(marcoAspas)
	for pieza, aspecto in aspectoInicial do
		pieza.Color, pieza.Material, pieza.Transparency = aspecto.color, aspecto.material, aspecto.transparencia
		if aspecto.luz then
			aspecto.luz.Color, aspecto.luz.Enabled = aspecto.tonoLuz, aspecto.encendida
		end
	end
	molino:SetAttribute("MolinoEncendido", false)
end

local function liberarTurno(conservarLuz)
	if not jugador then return end
	companeros:incorporar(jugador)
	limpiarEscudo()
	jugador:SetAttribute("LlevaChispa", false)
	jugador:SetAttribute("EstadoChispa", "Segura")
	jugador:SetAttribute("FuerzaChispa", 1)
	jugador, humanoideTitular = nil, nil
	hasta, escenaDesde, apagadaHasta, oleadasDesde = 0, 0, 0, 0
	desgaste, proximaHebra, proximoImpacto = 0, 0, 0
	cruzoProtegido, chispaEnManos = false, false
	recoger.Enabled, encender.Enabled = false, false
	efectosViento:ClearAllChildren()
	if not conservarLuz then apagarMolino() end
	molino:SetAttribute("EstadoViento", "Calma")
	ponerFase("Fuera", "")
	molino:SetAttribute("TitularExpedicion", nil)
end

local function prepararChispa()
	hasta = 0
	if iluminado then
		finalistas[jugador] = true
		liberarTurno(true)
	else
		ponerFase("BuscarChispa", "Recoge la chispa. Pedernal puede protegerla en el pasadizo.")
		recoger.Enabled = true
	end
	salir.Enabled = true
end

local function empezarLlegada(t)
	if jugador:GetAttribute("MolinoVista") then
		prepararChispa()
		return
	end
	jugador:SetAttribute("MolinoVista", true)
	escenaDesde = t + 0.20
	hasta = escenaDesde + LLEGADA_DURACION + 0.1
	ponerFase("Llegada", "")
	remoto:FireClient(jugador, "Llegada", escenaDesde, LLEGADA_DURACION)
end

local function iniciarAterrizaje(quien, root, h, t)
	if iluminado then apagarMolino() end
	jugador, humanoideTitular = quien, h
	molino:SetAttribute("TitularExpedicion", quien.UserId)
	jugador:SetAttribute("EnMolino", true)
	jugador:SetAttribute("EstadoChispa", "Segura")
	apagadaHasta = 0
	ponerFase("Aterrizando", "Estás llegando al molino.")
	hasta = t + 0.72
	root.AssemblyLinearVelocity = Vector3.new(0, math.min(root.AssemblyLinearVelocity.Y, -6), 0)
end

local function restaurarPlaza(quien)
	if quien == jugador then liberarTurno() end
	enEspera[quien], finalistas[quien] = nil, nil
	quien:SetAttribute("EsperaMolino", false)
	quien:SetAttribute("EnMolino", false)
	quien:SetAttribute("EstadoChispa", "Segura")
end

local function salirAlRefugio(quien)
	restaurarPlaza(quien)
	local refugio = isla:FindFirstChild("RefugioDelViento")
	local farero = refugio and refugio:FindFirstChild("PuntoFarero")
	local portal = isla.Rutas:FindFirstChild("PortalDeLaGeoda")
	if quien:GetAttribute("Lucero") and farero then
		quien:SetAttribute("Refugio", true)
		if portal and quien:GetAttribute("ConsejoLente") and not quien:GetAttribute("LenteGeoda") then
			mover(quien, portal.Position+Vector3.new(-2.8,1.3,-.4), portal.Position)
		else
			mover(quien, farero.Position+Vector3.new(-3,1.3,2.7), farero.Position)
		end
	else
		mover(quien, despegue.Position + Vector3.new(0, 3.5, -1.05), llegada.Position)
	end
end

salir.Triggered:Connect(function(quien)
	if cerca(quien, salir) and (quien == jugador or finalistas[quien] or enEspera[quien]) then
		salirAlRefugio(quien)
	end
end)

local function tomar(quien)
	if quien ~= jugador or not cerca(quien, recoger) or fase ~= "BuscarChispa" or iluminado then
		return
	end
	recoger.Enabled = false
	chispaEnManos = true
	cruzoProtegido = false
	desgaste = 0
	oleadasDesde = reloj()
	jugador:SetAttribute("LlevaChispa", true)
	jugador:SetAttribute("EstadoChispa", "Segura")
	jugador:SetAttribute("FuerzaChispa", 1)
	ponerFase("Transportar", "Protege la chispa con Pedernal mientras la llevas al farol.")
end
recoger.Triggered:Connect(tomar)

local function despertar(t)
	iluminado = true
	origenLuz = t
	molino:SetAttribute("MolinoEncendido", true)
end

local function premio(quien)
	if quien ~= jugador or not cerca(quien, encender) or fase ~= "Transportar" or not chispaEnManos or not cruzoProtegido then
		return
	end
	escenaDesde = reloj() + 0.20
	hasta = escenaDesde + FINAL_DURACION + 0.10
	despertar(escenaDesde)
	soltar()
	limpiarEscudo()
	ponerFase("Despertar", "")
	companeros:despertar(quien, escenaDesde)
	quien:SetAttribute("Lucero", true)
	remoto:FireClient(quien, "Despertar", escenaDesde, FINAL_DURACION)
end
encender.Triggered:Connect(premio)

local function escudo(quien, root, t)
	if fase ~= "Transportar" or not quien:GetAttribute("Pedernal") or t < escudoListo
		or not dentroXZ(zona, root.Position, 8.75) or root.Position.Y > llegada.Position.Y + 11 then
		return
	end
	escudoHasta = t + ESCUDO_DURACION
	escudoListo = t + datos.RecargaEscudo({ MejoraPedernal = quien:GetAttribute("MejoraPedernal") == true })
	quien:SetAttribute("EscudoMolinoHasta", escudoHasta)
	quien:SetAttribute("EscudoMolinoListoEn", escudoListo)
end

remoto.OnServerEvent:Connect(function(quien, accion)
	if accion == "SalirDeLaEspera" then
		local root = avatar(quien)
		if root and enEspera[quien] and dentroXZ(llegada, root.Position, .5)
			and math.abs(root.Position.Y-llegada.Position.Y) < 13.1 then
			salirAlRefugio(quien)
		end
		return
	end
	if quien ~= jugador or not quien:GetAttribute("EnMolino") then
		return
	end
	local root = avatar(quien)
	if not root then
		return
	end
	if accion == "Escudo" then
		escudo(quien, root, reloj())
	elseif (accion == "TerminarLlegada" and fase == "Llegada") or (accion == "TerminarDespertar" and fase == "Despertar") then
		prepararChispa()
	end
end)

local function actualizarEscudo(root, activo)
	if activo then
		if not burbuja then
			burbuja = Instance.new("Part")
			burbuja.Name = "EscudoPedernal"
			burbuja.Shape = Enum.PartType.Ball
			burbuja.Size = Vector3.new(6.8, 6.8, 6.8)
			burbuja.Anchored = true
			burbuja.CanCollide = false
			burbuja.CanTouch = false
			burbuja.CanQuery = false
			burbuja.CastShadow = false
			burbuja.Color = CIELO
			burbuja.Position = root.Position
			VientoVisual.escudo(burbuja)
			burbuja.Parent = molino
		end
		burbuja.Position = root.Position
	elseif burbuja then
		burbuja:Destroy()
		burbuja = nil
	end
end

local function apagarChispa(t)
	soltar()
	limpiarEscudo()
	apagadaHasta = t + 1.45
	salir.Enabled = true
	jugador:SetAttribute("EstadoChispa", "Apagada")
	ponerFase("BuscarChispa", "La chispa volvió a su pedestal. Activa el escudo justo antes de cruzar.")
	local atras = marcoChispa.Position - Vector3.xAxis * 2
	mover(jugador, Vector3.new(atras.X, llegada.Position.Y + 0.95, atras.Z), zona.Position)
end

local function transportar(root, t, dt)
	local enViento = dentroXZ(zona, root.Position, 0)
	local protegido = t < escudoHasta
	local ciclo = (t - oleadasDesde) % 3.7
	local rafaga = ciclo >= 1.43 and ciclo < 2.48
	local aviso = ciclo >= 0.70 and ciclo < 1.43
	local oleada = if rafaga then "Rafaga" elseif aviso then "Aviso" else "Calma"
	molino:SetAttribute("EstadoViento", oleada)
	local viento = -zona.CFrame.RightVector
	if (aviso or rafaga) and t >= proximaHebra then
		proximaHebra = t + (if aviso then .44 else .24)
		local origen = zona.Position - viento * (zona.Size.X * .5) + Vector3.yAxis * .8
		VientoVisual.avisar(origen,origen+viento*zona.Size.X,if aviso then ORO else CIELO,efectosViento)
	end
	if enViento and t >= proximoImpacto then
		proximoImpacto = t + .75
		if protegido then
			VientoVisual.impacto(root.Position,viento,"Bloqueo",efectosViento)
		else
			VientoVisual.avisar(chispa.Position-viento*5,chispa.Position,ORO,efectosViento)
		end
	end

	if protegido and enViento and zona.CFrame:PointToObjectSpace(root.Position).X >= 0 then
		cruzoProtegido = true
	end
	if enViento and not protegido then
		desgaste += dt * (if rafaga then 3.6 else 1.23)
		if desgaste >= 1 then
			apagarChispa(t)
			return
		end
	elseif protegido then
		desgaste = math.max(0, desgaste - dt * 2.7)
	end
	local estado = if protegido then "Protegida" elseif enViento then "En riesgo"
		elseif aviso and dentroXZ(zona, root.Position, 6) then "Alerta" else "Segura"
	jugador:SetAttribute("EstadoChispa", estado)
	jugador:SetAttribute("FuerzaChispa", math.ceil((1 - desgaste) * 25) / 25)
	encender.Enabled = cruzoProtegido
	chispa.CFrame = CFrame.new(root.Position + root.CFrame.LookVector * 1.8 + Vector3.yAxis * (0.58 + math.sin(t * 6) * 0.15))
		* CFrame.Angles(t % 6, t % 6, math.rad(26))
	chispa.Color = if protegido then MENTA else ORO:Lerp(Color3.fromRGB(191, 110, 109), desgaste)
	chispa.Transparency = desgaste * 0.55
	actualizarEscudo(root, protegido)
end

local function actualizarMundo(t)
	if not iluminado then
		return
	end
	local edad = t - origenLuz
	if edad < 0 then
		return
	end
	if edad >= 0.16 and lucesEncendidas == 0 then
		estadoPieza(farol, ORO, true)
	end
	local cantidad = math.clamp(math.floor((edad - 0.28) / 0.071) + 1, 0, #luces)
	for i = lucesEncendidas + 1, cantidad do
		estadoPieza(luces[i], ORO, true)
	end
	lucesEncendidas = cantidad
	local giro = if edad < 1.3 then edad * edad * 0.73 else (edad - 0.65) * 1.9
	aspas:PivotTo(marcoAspas * CFrame.Angles(0, 0, -giro))
end

local function registrar(nuevo)
	nuevo:SetAttribute("EnMolino", false)
	nuevo:SetAttribute("EsperaMolino", false)
	nuevo:SetAttribute("LlevaChispa", false)
	nuevo:SetAttribute("EstadoChispa", "Segura")
	nuevo:SetAttribute("FuerzaChispa", 1)
	nuevo:SetAttribute("EscudoMolinoHasta", 0)
	nuevo:SetAttribute("EscudoMolinoListoEn", 0)
	nuevo.CharacterRemoving:Connect(function()
		restaurarPlaza(nuevo)
	end)
end

if RunService:IsStudio() and game.GameId == 0 and isla:GetAttribute("AtajosDePrueba") == true then
	local prueba = Instance.new("Part")
	prueba.Name = "PruebaDelMolino"
	prueba.Anchored = true
	prueba.CanCollide = false
	prueba.CanTouch = false
	prueba.Material = Enum.Material.Neon
	prueba.Color = Color3.fromRGB(255, 160, 83)
	prueba.Size = Vector3.new(1.56, 1.75, 1.56)
	prueba.CFrame = CFrame.new(-50.9, 22.20, -4.9) * CFrame.Angles(0, 0, math.rad(42))
	prueba.Parent = isla
	local ir = interactuar(prueba, "Probar el molino", "Molino del Viento", 7.4)
	ir.Enabled = true
	ir.Triggered:Connect(function(quien)
		if not cerca(quien, ir) or quien:GetAttribute("EnCueva") or not quien:GetAttribute("ProgresoListo")
			or quien:GetAttribute("FaseNido") == "Defensa" then
			return
		end
		quien:SetAttribute("Cometa", true)
		quien:SetAttribute("Pedernal", true)
		local p = despegue.Position
		mover(quien, p + Vector3.new(0,3.5,-1.12), llegada.Position)
	end)
end

ponerFase("Fuera", "")
molino:SetAttribute("EstadoViento", "Calma")
molino:SetAttribute("MolinoEncendido", false)
molino:SetAttribute("TitularExpedicion", nil)
salir.Enabled = true
salir.ActionText = "Salir del molino"
Players.PlayerAdded:Connect(registrar)
Players.PlayerRemoving:Connect(function(p)
	restaurarPlaza(p)
	companeros:retirar(p)
end)
for _, conectado in ipairs(Players:GetPlayers()) do
	registrar(conectado)
end

local function otraExpedicion(p)
	return p:GetAttribute("EnCueva") or p:GetAttribute("EnFaro") or p:GetAttribute("EnEncargoPedernal")
end

local function fueraDelMolino(pos)
	return pos.Y < llegada.Position.Y - 8.6 or (pos - llegada.Position).Magnitude > 65
		or llegada.CFrame:PointToObjectSpace(pos).Z < -14
end

local function recibirAterrizajes(t, dt)
	local elegido, orden
	for _, p in Players:GetPlayers() do
		local r = avatar(p)
		companeros:actualizar(p, r, t, dt)
		if p == jugador then continue end
		if not r or otraExpedicion(p) then
			if finalistas[p] or enEspera[p] then restaurarPlaza(p) end
			continue
		end
		if finalistas[p] then
			if fueraDelMolino(r.Position) then restaurarPlaza(p) end
			continue
		end
		local enMuelle = dentroXZ(llegada, r.Position, .5) and math.abs(r.Position.Y - llegada.Position.Y) < 13.1
		if enEspera[p] then
			if not enMuelle then
				salirAlRefugio(p)
				continue
			end
		elseif enMuelle and not p:GetAttribute("EnMolino") and p:GetAttribute("ProgresoListo")
			and p:GetAttribute("Cometa") and p:GetAttribute("Pedernal") and (p:GetAttribute("PlaneoIslaHasta") or 0) > t then
			p:SetAttribute("EnMolino", true)
			if p:GetAttribute("Lucero") then
				finalistas[p] = true
				mover(p, llegada.Position + Vector3.yAxis * .96, farol.Position)
				continue
			end
			ordenLlegada += 1
			enEspera[p] = ordenLlegada
			if jugador or elegido then
				p:SetAttribute("EsperaMolino", true)
				mover(p, llegada.Position - llegada.CFrame.RightVector * 3.2 + Vector3.yAxis * .96, chispa.Position)
			end
		else
			continue
		end
		if not jugador and (not orden or enEspera[p] < orden) then
			elegido, orden = p, enEspera[p]
		end
	end
	if elegido then
		local r, h = avatar(elegido)
		enEspera[elegido] = nil
		elegido:SetAttribute("EsperaMolino", false)
		iniciarAterrizaje(elegido, r, h, t)
	end
end

while true do
	local dt = math.min(task.wait(0.045), 0.1)
	local t = reloj()
	recibirAterrizajes(t, dt)
	if not jugador then
		if next(finalistas) then
			if not iluminado then
				despertar(t - 4.5)
				chispa.Transparency = 1
				estadoPieza(chispa, ORO, false)
			end
			actualizarMundo(t)
		elseif iluminado then
			apagarMolino()
		end
		continue
	end
	local root, h = avatar(jugador)
	if not root or h ~= humanoideTitular or otraExpedicion(jugador) or not jugador:GetAttribute("EnMolino")
		or fueraDelMolino(root.Position) then
		restaurarPlaza(jugador)
		continue
	end
	actualizarMundo(t)
	if fase == "Aterrizando" then
		if root.Position.Y <= llegada.Position.Y + 2.1 or t >= hasta then
			local p = llegada.Position
			mover(jugador, Vector3.new(p.X, p.Y + 0.96, p.Z), chispa.Position)
			empezarLlegada(t)
		end
	elseif fase == "Llegada" or fase == "Despertar" then
		if t >= hasta then
			prepararChispa()
		end
	elseif fase == "Transportar" then
		transportar(root, t, dt)
	elseif apagadaHasta > 0 and t >= apagadaHasta then
		recoger.Enabled = true
		apagadaHasta = 0
		jugador:SetAttribute("EstadoChispa", "Segura")
	end
	if fase ~= "Transportar" then
		molino:SetAttribute("EstadoViento", "Calma")
	end
end
