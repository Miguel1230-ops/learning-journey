-- Instalar temporalmente en ServerScriptService y ejecutar en Edit con el LocalScript de pruebas.
-- ExecuteMultiplayerTestAsync(2, "TurnosExpedicionQA") prueba Cueva y Molino.
-- ExecuteMultiplayerTestAsync(2, "TurnosMolinoQA") prueba solo relevo, rescate, ficha y regreso.
-- ExecuteMultiplayerTestAsync(2, "LuceroFormacionQA") comprueba perfiles, aislamiento y reaparición.
-- ExecuteMultiplayerTestAsync(2, "TurnosFaroQA") usa perfiles nuevos con Lucero para el Faro.
-- ExecuteMultiplayerTestAsync(2, "AvisosFaroQA") aísla la luz restaurada y la muerte durante el ascenso.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local pruebas = game:GetService("StudioTestService")
if not game:GetService("RunService"):IsStudio() then return end
local caso = pruebas:GetTestArgs()
if caso ~= "TurnosExpedicionQA" and caso ~= "TurnosFaroQA" and caso ~= "TurnosMolinoQA" and caso ~= "LuceroFormacionQA" and caso ~= "AvisosFaroQA" then return end

local etapa = "iniciar"
local finalizada = false
local function finalizar(mensaje)
	if finalizada then return end
	finalizada = true
	pruebas:EndTest(mensaje)
end
task.delay(160, function() finalizar("FALLO: tiempo total en " .. etapa) end)

local function esperar(nombre, segundos, evaluar)
	etapa = nombre
	local limite = os.clock() + segundos
	repeat
		local valor = evaluar()
		if valor then return valor end
		task.wait(.05)
	until os.clock() >= limite
	local estados = {}
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local r = c and c:FindFirstChild("HumanoidRootPart")
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if r and h then
			local filtro = RaycastParams.new()
			filtro.FilterDescendantsInstances = {c}
			filtro.RespectCanCollide = true
			local suelo = workspace:Raycast(r.Position, -Vector3.yAxis * 20, filtro)
			table.insert(estados, ("%s en %s, suelo %s/%s, Lucero=%s, EnFaro=%s, espera=%s"):format(
				p.Name, tostring(r.Position), h.FloorMaterial.Name, suelo and suelo.Instance.Name or "vacío",
				tostring(p:GetAttribute("Lucero")), tostring(p:GetAttribute("EnFaro")), tostring(p:GetAttribute("EsperaFaro"))))
			table.insert(estados, ("altura %.2f; alcance %.2f; ocupaciones %s/%s/%s; perfil %s"):format(
				suelo and suelo.Distance or -1, h.HipHeight + r.Size.Y/2 + .65,
				tostring(p:GetAttribute("EnCueva")), tostring(p:GetAttribute("EnMolino")),
				tostring(p:GetAttribute("EnEncargoPedernal")), tostring(p:GetAttribute("ProgresoListo"))))
		end
	end
	error("Tiempo agotado en " .. nombre .. " | " .. table.concat(estados, " | "))
end

local canal = Instance.new("RemoteEvent")
canal.Name = "PruebaTurnosExpediciones"
local listos, pendiente = {}, nil
local numero = 0
canal.OnServerEvent:Connect(function(p, id, ok, detalle)
	if id == 0 then listos[p] = true
	elseif pendiente and pendiente.p == p and pendiente.id == id then
		pendiente.respuesta = {ok == true, detalle}
	end
end)
canal.Parent = ReplicatedStorage

local function pedir(p, accion, objeto)
	numero += 1
	pendiente = {p = p, id = numero}
	if objeto and objeto:IsA("ProximityPrompt") then
		local pos = objeto.Parent.Position
		local junto = pos + Vector3.new(-2.5, 2, 1.4)
		p.Character:PivotTo(CFrame.lookAt(junto, Vector3.new(pos.X, junto.Y, pos.Z)))
		p.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	end
	canal:FireClient(p, numero, accion, objeto)
	local descripcion = accion .. " " .. (objeto and objeto.Parent.Name or "") .. " por " .. p.Name
	local respuesta = esperar(descripcion, 12, function() return pendiente.respuesta end)
	pendiente = nil
	assert(respuesta[1], descripcion .. ": " .. tostring(respuesta[2]))
end

local function personaje(p)
	local c = p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	return c and h and h.Health > 0 and c:FindFirstChild("HumanoidRootPart")
end

local function situar(p, posicion)
	local raiz = assert(personaje(p), "Falta el personaje de " .. p.Name)
	p.Character:PivotTo(CFrame.new(posicion))
	raiz.AssemblyLinearVelocity = Vector3.zero
	return raiz
end

local function turno(modelo, p)
	local esperado = if p then p.UserId else nil
	esperar("turno " .. modelo.Name .. " para " .. tostring(esperado), 8, function()
		return modelo:GetAttribute("TitularExpedicion") == esperado
	end)
end

local function companeroDe(p, isla)
	local companeros = isla:FindFirstChild("CompanerosLucero")
	return companeros and companeros:FindFirstChild(tostring(p.UserId))
end

local function luceroCerca(p, isla)
	local eco = companeroDe(p, isla)
	local raiz = personaje(p)
	local cuerpo = eco and eco:FindFirstChild("Cuerpo")
	return cuerpo and cuerpo.Transparency < 1 and raiz and eco:GetAttribute("Propietario") == p.UserId
		and (eco:GetPivot().Position-raiz.Position).Magnitude<10
end

local function probarFormacion(a,b,isla)
	a:SetAttribute("Lucero",true)
	esperar("compañero solo para el primer perfil",6,function() return luceroCerca(a,isla) end)
	assert(not companeroDe(b,isla) and #isla.CompanerosLucero:GetChildren()==1)
	local primero=companeroDe(a,isla)
	b:SetAttribute("Lucero",true)
	esperar("segundo compañero visible",6,function() return luceroCerca(b,isla) end)
	local segundo=companeroDe(b,isla)
	assert(primero~=segundo and #isla.CompanerosLucero:GetChildren()==2)
	situar(b,isla.RefugioDelViento.PuntoFarero.Position+Vector3.new(-3,3,2))
	esperar("cada compañero sigue a su dueño",6,function()
		return (personaje(a).Position-personaje(b).Position).Magnitude>60 and luceroCerca(a,isla) and luceroCerca(b,isla)
	end)
	local anterior=a.Character
	anterior:FindFirstChildOfClass("Humanoid").Health=0
	esperar("retirada al morir",5,function() return not companeroDe(a,isla) and companeroDe(b,isla)==segundo end)
	esperar("recuperación al reaparecer",14,function() return a.Character~=anterior and luceroCerca(a,isla) end)
	assert(companeroDe(a,isla)~=primero and companeroDe(b,isla)==segundo and #isla.CompanerosLucero:GetChildren()==2)
	pedir(a,"sinFichaInicial")
	pedir(b,"sinFichaInicial")
	return "OK: dos perfiles con Lucero, dos modelos visibles exclusivos; el segundo viaja al refugio, el primero muere y reaparece con su propio compañero; ninguna ficha de rescate por cargar progreso."
end

local function probarCueva(a, b, isla)
	local cueva = workspace.CuevaDeLaGeoda
	local portal = isla.Rutas.PortalDeLaGeoda.Accion
	turno(cueva, nil)
	pedir(a, "activar", portal)
	turno(cueva, a)
	pedir(b, "portalOcupado", portal)
	assert(a:GetAttribute("EnCueva") and not b:GetAttribute("EnCueva"))
	local anterior = a.Character
	anterior:FindFirstChildOfClass("Humanoid").Health = 0
	turno(cueva, nil)
	pedir(b, "activar", portal)
	turno(cueva, b)
	pedir(b, "activar", cueva.SalidaIsla.Accion)
	turno(cueva, nil)
	assert(not b:GetAttribute("EnCueva"))
	esperar("reaparición del primero", 14, function() return a.Character ~= anterior and personaje(a) end)
end

local function probarMolino(a,b,isla)
	local molino = isla.MolinoDelViento
	local origenChispa = molino.Chispa.CFrame
	turno(molino,nil)
	local function llegar(p, lateral)
		p:SetAttribute("Pedernal", true)
		-- Coloca el planeador ya en su último tramo. La detección de llegada, el turno y los premios son del juego.
		p:SetAttribute("PlaneoIslaHasta", workspace:GetServerTimeNow() + 2.6)
		situar(p, molino.Llegada.Position + Vector3.new(lateral, 5, 0))
	end
	llegar(a, 3)
	turno(molino, a)
	esperar("chispa disponible", 12, function() return molino.Chispa.Accion.Enabled end)
	pedir(a, "activar", molino.Chispa.Accion)
	esperar("primero transporta", 4, function() return a:GetAttribute("LlevaChispa") end)
	llegar(b, -3)
	esperar("segundo espera en el muelle", 5, function() return b:GetAttribute("EsperaMolino") end)
	assert(molino:GetAttribute("TitularExpedicion") == a.UserId and not b:GetAttribute("LlevaChispa"))
	assert(not a:GetAttribute("Lucero") and not b:GetAttribute("Lucero"))
	-- Ambos perfiles son exclusivos de esta sesión de Studio. El segundo permanece conectado.
	a:Kick("Desconexión programada durante la prueba del relevo")
	esperar("desconexión real del portador", 7, function() return a.Parent ~= Players end)
	turno(molino, b)
	esperar("chispa vuelve al pedestal", 12, function() return molino.Chispa.Accion.Enabled end)
	assert((molino.Chispa.Position - origenChispa.Position).Magnitude < .15)
	assert(not molino:GetAttribute("MolinoEncendido") and not b:GetAttribute("EsperaMolino"))
	local saldo = b:GetAttribute("Monedas")
	assert(type(saldo) == "number")
	pedir(b, "activar", molino.Chispa.Accion)
	esperar("segundo transporta", 4, function() return b:GetAttribute("LlevaChispa") end)
	situar(b, molino.ZonaViento.CFrame:PointToWorldSpace(Vector3.new(1.2, 1.25, 0)))
	pedir(b, "escudo")
	esperar("cruce protegido", 3, function() return molino.Farol.Accion.Enabled end)
	pedir(b, "activar", molino.Farol.Accion)
	esperar("Lucero y premio", 5, function() return b:GetAttribute("Lucero") and b:GetAttribute("Monedas") == saldo + 50 end)
	turno(molino, nil)
	esperar("Lucero ocupa su lugar junto al ganador",5,function() return luceroCerca(b,isla) end)
	local companero = companeroDe(b,isla)
	pedir(b, "fichaLucero")
	pedir(b, "activar", molino.Regreso.Accion)
	esperar("salida con Lucero", 4, function() return not b:GetAttribute("EnMolino") end)
	esperar("el mismo Lucero acompaña al refugio",5,function() return luceroCerca(b,isla) and companeroDe(b,isla)==companero end)
	llegar(b, 0)
	esperar("revisita al molino", 5, function() return b:GetAttribute("EnMolino") end)
	assert(not molino:GetAttribute("TitularExpedicion") and not molino.Chispa.Accion.Enabled)
	assert(b:GetAttribute("Monedas") == saldo + 50, "Se duplicó el premio al regresar")
	return "Molino recuperado tras desconexión con chispa; rescate, ficha tras devolver cámara, +50 monedas, mismo Lucero en refugio y revisita sin duplicados."
end

local function verificarAvisos(a,b,isla,aterrizar)
	local f = isla.RuinasDelFaro
	local luz, haz = f.Linterna.Luz, f.Linterna.HazDelMolino
	-- El titular espera en la losa mientras el otro cliente prueba el elevador.
	-- El servidor lo colocó allí y mantiene la simulación física de ese avatar.
	local raizTitular = assert(personaje(a), "Falta el titular en la losa")
	raizTitular:SetNetworkOwner(nil)
	assert(not a:GetAttribute("FaroEncendido") and not luz.Enabled and not haz.Enabled)
	local marcador = a:GetAttribute("ProgresoRevision")
	local cambios = 0
	local revision = a:GetAttributeChangedSignal("ProgresoRevision"):Connect(function() cambios += 1 end)
	a:SetAttribute("FaroEncendido",true)
	esperar("la luz y el haz se restauran sin girar el espejo",4,function() return luz.Enabled and haz.Enabled end)
	revision:Disconnect()
	assert(cambios==0 and a:GetAttribute("ProgresoRevision")==marcador, "La revisión de progreso cambió durante la prueba aislada")
	assert(not f:GetAttribute("RastroRevelado") and not b:GetAttribute("FaroEncendido"))

	b:SetAttribute("FaroEncendido",true)
	b:SetAttribute("Prisma",true)
	aterrizar(b,-3)
	esperar("visitante con Prisma",5,function() return b:GetAttribute("EnFaro") end)
	local torre = f.RescateNimbo
	local anterior = b.Character
	local raiz = anterior.HumanoidRootPart
	local anclada = raiz.Anchored
	local murio, liberada, altura
	local escuchar = b:GetAttributeChangedSignal("RescateNimbo"):Connect(function()
		if b:GetAttribute("RescateNimbo")~="Subiendo" or murio then return end
		local plataforma = torre:FindFirstChild("ElevadorDePrisma")
		if not plataforma then return end
		local base = torre.Ascensor.Position.Y
		local limite = os.clock()+1.7
		repeat task.wait(.04) until plataforma.Position.Y > base+.3 or os.clock()>=limite
		if b:GetAttribute("RescateNimbo")~="Subiendo" or not raiz.Anchored then return end
		altura = plataforma.Position.Y-base
		if altura<=.3 or plataforma.Position.Y>=torre.Despegue.Position.Y-.1 then return end
		plataforma.Destroying:Once(function() liberada = raiz.Anchored==anclada end)
		murio = true
		anterior:FindFirstChildOfClass("Humanoid").Health=0
	end)
	pedir(b,"activar",torre.Ascensor.Subir)
	esperar("muerte con el elevador ya en movimiento",4,function() return murio end)
	escuchar:Disconnect()
	esperar("limpieza de elevador y estado",6,function()
		return liberada and torre:FindFirstChild("ElevadorDePrisma")==nil
			and b:GetAttribute("RescateNimbo")==nil and not b:GetAttribute("EnFaro")
	end)
	esperar("reaparición tras caída en la torre",14,function() return b.Character~=anterior and personaje(b) end)
	assert(b:GetAttribute("Prisma") and b:GetAttribute("FaroEncendido") and not personaje(b).Anchored)
	aterrizar(b,-3)
	esperar("regreso tras muerte durante ascenso",5,function() return b:GetAttribute("EnFaro") end)
	pedir(b,"activar",torre.Ascensor.Subir)
	esperar("nuevo ascenso completado",6,function() return b:GetAttribute("RescateNimbo")=="Balcon" end)
	assert(not personaje(b).Anchored and not torre:FindFirstChild("ElevadorDePrisma"))
	local titular = f:GetAttribute("TitularExpedicion")
	assert(titular == a.UserId and a:GetAttribute("EnFaro"),
		("Turno después de la subida: esperado %s, actual %s, EnFaro=%s, posición del titular=%s"):format(
			tostring(a.UserId), tostring(titular), tostring(a:GetAttribute("EnFaro")), tostring(raizTitular.Position)))
	raizTitular:SetNetworkOwnershipAuto()
	return ("OK: FaroEncendido restauró linterna y haz con 0 cambios de ProgresoRevision (revisión %s). Muerte a %.2f studs de ascenso, avatar liberado, elevador retirado, progreso conservado y siguiente ascenso llegó al balcón."):format(tostring(marcador),altura)
end

local function probarFaro(a, b, isla)
	local f = isla.RuinasDelFaro
	esperar("inicio del controlador del Faro", 10, function()
		return f:GetAttribute("RastroRevelado") ~= nil and f.Prisma:FindFirstChild("CaminoDePrisma")
	end)
	local losa = f.Plataformas["Plataforma de llegada"]
	local function aterrizar(p, lateral)
		local pos = losa.Position + Vector3.new(lateral, 10, 0)
		local raiz = situar(p, pos)
		raiz.Anchored = true
		-- Los dos clientes pueden seguir cargando el mapa. Mantener el vuelo vigente
		-- mientras se sostiene al personaje y empezar la ventana de caída al soltarlo.
		local hasta = os.clock() + .4
		repeat
			p:SetAttribute("PlaneoIslaHasta", workspace:GetServerTimeNow() + 3)
			task.wait(.05)
		until os.clock() >= hasta
		assert(not p:GetAttribute("EnFaro") and f:GetAttribute("TitularExpedicion") ~= p.UserId, "Entrada antes de aterrizar")
		p:SetAttribute("PlaneoIslaHasta", workspace:GetServerTimeNow() + 3)
		raiz.Anchored = false
		-- La prueba colocó el personaje desde el servidor: que también simule la
		-- caída antes de devolver el mando evita interpolar desde el spawn lejano.
		raiz:SetNetworkOwner(nil)
		esperar("contacto físico en la losa de " .. p.Name, 6, function()
			return raiz.Parent:FindFirstChildOfClass("Humanoid").FloorMaterial ~= Enum.Material.Air
				and math.abs(raiz.Position.Y-losa.Position.Y) < 7
		end)
		raiz:SetNetworkOwnershipAuto()
	end
	for _, p in {a, b} do p:SetAttribute("Lucero", true) end
	turno(f, nil)
	aterrizar(a, 3)
	turno(f, a)
	if caso == "AvisosFaroQA" then return verificarAvisos(a,b,isla,aterrizar) end
	esperar("companeros personales con progreso cargado",5,function() return luceroCerca(a,isla) and luceroCerca(b,isla) end)
	assert(companeroDe(a,isla)~=companeroDe(b,isla) and not f:FindFirstChild("LuceroExplorador"))
	local luceroPrimero=companeroDe(a,isla)
	situar(a, f.Rastro.Position + Vector3.new(-2, 2, 0))
	pedir(a, "lucero")
	esperar("rastro del primer jugador", 4, function() return f:GetAttribute("RastroRevelado") end)
	pedir(a, "activar", f.Girar.Accion)
	esperar("primero enciende el faro", 4, function() return a:GetAttribute("FaroEncendido") end)
	aterrizar(b, -3)
	esperar("segundo espera en la losa", 5, function() return b:GetAttribute("EsperaFaro") end)
	assert(f:GetAttribute("TitularExpedicion") == a.UserId and not b:GetAttribute("EnFaro"))
	assert(not b:GetAttribute("FaroEncendido") and not b:GetAttribute("Prisma"))
	local anterior = a.Character
	anterior:FindFirstChildOfClass("Humanoid").Health = 0
	turno(f, b)
	assert(b:GetAttribute("EnFaro") and not b:GetAttribute("EsperaFaro"))
	assert(not f:GetAttribute("RastroRevelado") and not f.Girar.Accion.Enabled, "El segundo heredó el espejo")
	assert(f.Puerta.CanCollide and not f.Linterna.Luz.Enabled, "El segundo heredó la luz o la cámara del primero")
	assert(not b:GetAttribute("FaroEncendido") and not b:GetAttribute("Prisma"))
	b:SetAttribute("LenteGeoda", true)
	situar(b, f.Rastro.Position + Vector3.new(-2, 2, 0))
	pedir(b, "lucero")
	esperar("rastro del segundo jugador", 4, function() return f.Montura.Accion.Enabled end)
	pedir(b, "activar", f.Montura.Accion)
	pedir(b, "activar", f.Girar.Accion)
	esperar("segundo enciende su faro", 4, function() return b:GetAttribute("FaroEncendido") end)
	pedir(b, "activar", f.Girar.Accion)
	esperar("cámara abierta", 4, function() return f.Prisma.Accion.Enabled end)
	esperar("reaparición en el faro", 12, function() return a.Character ~= anterior and personaje(a) end)
	esperar("Lucero reaparece con su propietario",6,function() return luceroCerca(a,isla) and companeroDe(a,isla)~=luceroPrimero end)
	aterrizar(a, 3)
	esperar("reingreso del primero en espera", 5, function() return a:GetAttribute("EsperaFaro") end)
	pedir(b, "activar", f.Prisma.Accion)
	turno(f, a)
	assert(a:GetAttribute("EnFaro") and b:GetAttribute("EnFaro") and b:GetAttribute("Prisma"))
	assert(not a:GetAttribute("Prisma") and not f:GetAttribute("RastroRevelado") and f.Puerta.CanCollide)
	assert(f.Linterna.Luz.Enabled, "No se restauró la linterna del jugador que vuelve")
	pedir(b, "activar", f.Prisma.CaminoDePrisma)
	local torre = f.RescateNimbo
	esperar("paso personal al pie de la torre", 4, function()
		return (personaje(b).Position - torre.Ascensor.Position).Magnitude < 7
	end)
	pedir(b, "activar", torre.Ascensor.Subir)
	esperar("jugador con Prisma llega al balcón", 5, function() return b:GetAttribute("RescateNimbo") == "Balcon" end)
	pedir(b, "activar", f.Regreso.Accion)
	esperar("salida del visitante con Prisma", 4, function() return not b:GetAttribute("EnFaro") end)
	assert(a:GetAttribute("EnFaro") and f:GetAttribute("TitularExpedicion") == a.UserId)
	pedir(a, "activar", f.Regreso.Accion)
	turno(f, nil)
	assert(not a:GetAttribute("EnFaro"))
	return "OK: dos Luceros visibles y de propietarios distintos, sin duplicado en el Faro; Lucero reaparece junto al jugador. Relevo por muerte y Prisma, luz restaurada y acceso a la torre durante el turno ajeno."
end

local ok, mensaje = xpcall(function()
	local pareja = esperar("dos clientes y perfiles", 65, function()
		local jugadores = Players:GetPlayers()
		if #jugadores ~= 2 then return end
		for _, p in jugadores do
			if not listos[p] or not p:GetAttribute("ProgresoListo") or not personaje(p) then return end
		end
		return jugadores
	end)
	for _, p in pareja do
		assert(p:GetAttribute("ModoGuardado") == "Sesion", "Esta prueba requiere perfiles temporales")
		assert(not p:GetAttribute("Cometa") and not p:GetAttribute("Lucero"), "Se necesitan perfiles nuevos")
	end
	for _, p in pareja do p:SetAttribute("Cometa", true) end
	local isla = workspace.IslaDelViento
	if caso == "LuceroFormacionQA" then return probarFormacion(pareja[1],pareja[2],isla) end
	if caso == "TurnosFaroQA" or caso=="AvisosFaroQA" then return probarFaro(pareja[1], pareja[2], isla) end
	if caso == "TurnosMolinoQA" then return "OK: " .. probarMolino(pareja[1],pareja[2],isla) end
	probarCueva(pareja[1], pareja[2], isla)
	return "OK: Cueva ocupada y liberada al morir; " .. probarMolino(pareja[1],pareja[2],isla)
end, debug.traceback)
finalizar(if ok then mensaje else "FALLO en " .. etapa .. ": " .. tostring(mensaje))
