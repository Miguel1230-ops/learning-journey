local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Datos = require(script.Parent:WaitForChild("ProgresoDatos"))
local NOMBRE_ALMACEN = "CazadoresDeEcos_Progreso"
local ESPERA_GUARDADO = 3
local ESPERA_REINTENTO = 22

local enStudio = RunService:IsStudio()
local enExperienciaPublicada = game.GameId > 0 and game.PlaceId > 0
local permiteNube = enExperienciaPublicada and (not enStudio or script:GetAttribute("PermitirNubeEnStudio") == true)
local nube
if permiteNube then
	-- Una prueba de Studio con API habilitada usa un ámbito separado.
	local alcance = if enStudio then "pruebasStudio" else "jugadores"
	local ok, almacen = pcall(DataStoreService.GetDataStore, DataStoreService, NOMBRE_ALMACEN, alcance)
	if ok then
		nube = almacen
	else
		warn("[Cazadores de Ecos] El almacén no está disponible. El progreso dura esta partida.")
	end
end

local memoria = Datos.Memoria()
local sesiones = {}

local function indicar(ficha, estado)
	if ficha.jugador.Parent == Players then
		ficha.jugador:SetAttribute("EstadoGuardado", if ficha.nube then estado else "Sesion")
	end
end

local function publicarEconomia(ficha)
	local jugador = ficha.jugador
	if jugador.Parent ~= Players then
		return
	end
	for atributo, valor in pairs(Datos.Calcular(ficha.avance)) do
		jugador:SetAttribute(atributo, valor)
	end
end

local function aplicar(ficha, datos)
	local combinado = Datos.Fusionar(datos, ficha.avance)
	local cambioVisible = false
	for _, atributo in ipairs(Datos.Claves) do
		if combinado[atributo] then
			ficha.avance[atributo] = true
			if ficha.jugador.Parent == Players and ficha.jugador:GetAttribute(atributo) ~= true then
				ficha.jugador:SetAttribute(atributo, true)
				cambioVisible = true
			end
		end
	end
	if combinado.RevisionEquipo >= (ficha.avance.RevisionEquipo or 0) then
		ficha.avance.RevisionEquipo = combinado.RevisionEquipo
		ficha.avance.PlaneadorEquipado = combinado.PlaneadorEquipado
		if ficha.jugador.Parent == Players then
			ficha.jugador:SetAttribute("PlaneadorEquipado", combinado.PlaneadorEquipado)
		end
	end
	publicarEconomia(ficha)
	if cambioVisible and ficha.jugador.Parent == Players then
		local revision = ficha.jugador:GetAttribute("ProgresoRevision") or 0
		ficha.jugador:SetAttribute("ProgresoRevision", revision + 1)
	end
end

local function guardar(ficha, intentos)
	if ficha.guardando or ficha.comprando or ficha.revision == ficha.guardada then
		return
	end

	ficha.guardando = true
	local revision = ficha.revision
	local datos = table.clone(ficha.avance)
	local guardado, fallo
	for intento = 1, intentos do
		guardado, fallo = Datos.Escribir(ficha.almacen, ficha.clave, datos)
		if guardado then
			break
		end
		if intento < intentos then
			task.wait(intento * 0.7)
		end
	end

	if guardado then
		ficha.guardada = math.max(ficha.guardada, revision)
		ficha.cargaConfirmada = true
		aplicar(ficha, guardado)
		indicar(ficha, if ficha.guardada == ficha.revision then "Guardado" else "SinGuardar")
	else
		indicar(ficha, "Reintentando")
		warn("[Cazadores de Ecos] Falló el guardado del progreso:", fallo)
	end
	ficha.guardando = false
end

local function programarGuardado(ficha, demora)
	if ficha.programada or ficha.cerrando or not ficha.lista or ficha.revision == ficha.guardada then
		return
	end

	ficha.programada = true
	task.delay(demora, function()
		if ficha.cerrando then
			return
		end
		guardar(ficha, 3)
		ficha.programada = false
		local espera = if ficha.jugador:GetAttribute("EstadoGuardado") == "Reintentando"
			then ESPERA_REINTENTO else ESPERA_GUARDADO
		programarGuardado(ficha, espera)
	end)
end

local function anotarCambio(ficha)
	publicarEconomia(ficha)
	indicar(ficha, "SinGuardar")
	programarGuardado(ficha, ESPERA_GUARDADO)
end

local function cargar(ficha)
	local ok, datos
	for intento = 1, 3 do
		if ficha.cerrando then
			return
		end
		ok, datos = pcall(ficha.almacen.GetAsync, ficha.almacen, ficha.clave)
		if ok and (datos == nil or type(datos) == "table") then
			break
		end
		ok = false
		if intento < 3 then
			task.wait(intento * 0.7)
		end
	end

	if ficha.cerrando or ficha.jugador.Parent ~= Players or (ficha.cargaConfirmada and not ok) then
		return
	end
	if ok then
		ficha.cargaConfirmada = true
		aplicar(ficha, datos)
		indicar(ficha, if ficha.revision == ficha.guardada then "Guardado" else "SinGuardar")
	else
		indicar(ficha, "Reintentando")
		task.delay(ESPERA_REINTENTO, function()
			if not ficha.cerrando and not ficha.cargaConfirmada then
				cargar(ficha)
			end
		end)
	end

	ficha.lista = true
	ficha.jugador:SetAttribute("ProgresoListo", true)
	programarGuardado(ficha, ESPERA_GUARDADO)
end

local function capturar(ficha, nombre)
	if nombre == "MejoraPedernal" or nombre == "PlaneadorAvanzado"
		or (nombre == "EncargoPedernal" and not ficha.avance.MejoraPedernal) then
		return false
	end
	if ficha.avance[nombre] or ficha.jugador:GetAttribute(nombre) ~= true then
		return false
	end
	ficha.avance[nombre] = true
	ficha.revision += 1
	return true
end

local function recibir(jugador)
	if sesiones[jugador] or jugador.Parent ~= Players then
		return
	end

	local almacen = if nube and jugador.UserId > 0 then nube else memoria
	local ficha = {
		jugador = jugador,
		almacen = almacen,
		nube = almacen == nube,
		clave = "jugador:" .. jugador.UserId,
		avance = {},
		observadores = {},
		revision = 0,
		guardada = 0,
	}
	sesiones[jugador] = ficha
	jugador:SetAttribute("ModoGuardado", if ficha.nube then "Nube" else "Sesion")
	jugador:SetAttribute("ProgresoListo", false)
	jugador:SetAttribute("ProgresoRevision", 0)
	indicar(ficha, "Cargando")

	for _, nombre in ipairs(Datos.Claves) do
		if jugador:GetAttribute(nombre) == nil then
			jugador:SetAttribute(nombre, false)
		end
		local function anotar()
			if ficha.cerrando or not capturar(ficha, nombre) then
				return
			end
			anotarCambio(ficha)
		end
		table.insert(ficha.observadores, jugador:GetAttributeChangedSignal(nombre):Connect(anotar))
		anotar()
	end
	publicarEconomia(ficha)
	task.spawn(cargar, ficha)
end

local function tramitar(jugador, opcion, validar, escribir)
	local ficha = sesiones[jugador]
	if not ficha or not ficha.lista or ficha.cerrando or ficha.jugador.Parent ~= Players then
		return false, "ProgresoNoListo"
	end
	if ficha.comprando then
		return false, "Comprando"
	end
	if permiteNube and jugador.UserId > 0 and not ficha.nube then
		return false, "GuardadoNoDisponible"
	end

	local revisionAnterior = ficha.revision
	for _, nombre in ipairs(Datos.Claves) do
		capturar(ficha, nombre)
	end
	if ficha.revision ~= revisionAnterior then
		anotarCambio(ficha)
	end
	local puede, motivo = validar(ficha.avance, opcion)
	if not puede then
		return false, motivo
	end
	if escribir == Datos.Equipar then
		if os.clock() < (ficha.proximoEquipo or 0) then
			return false, "Comprando"
		end
		ficha.proximoEquipo = os.clock() + 0.5
	end

	ficha.comprando = true
	local revision = ficha.revision
	local perfil, resultado = escribir(ficha.almacen, ficha.clave, table.clone(ficha.avance), opcion)
	ficha.comprando = false
	if not perfil then
		indicar(ficha, "Reintentando")
		warn("[Cazadores de Ecos] No se pudo confirmar el cambio de equipo:", resultado)
		return false, "GuardadoNoDisponible"
	end
	ficha.guardada = math.max(ficha.guardada, revision)
	ficha.cargaConfirmada = true
	aplicar(ficha, perfil)
	indicar(ficha, if ficha.guardada == ficha.revision then "Guardado" else "SinGuardar")
	programarGuardado(ficha, ESPERA_GUARDADO)
	return resultado == "Comprada" or resultado == "Equipado", resultado
end

local function publicarCompra(nombre, producto, validar)
	local compra = Instance.new("BindableFunction")
	compra.Name = nombre
	compra.OnInvoke = function(jugador)
		return tramitar(jugador, producto, validar, Datos.Comprar)
	end
	compra.Parent = script.Parent
end

publicarCompra("ComprarMejoraRefugio", "MejoraPedernal", Datos.PuedeComprarPedernal)
publicarCompra("ComprarPlaneadorRefugio", "PlaneadorAvanzado", Datos.PuedeComprarPlaneador)

local equipar = Instance.new("BindableFunction")
equipar.Name = "EquiparPlaneadorRefugio"
equipar.OnInvoke = function(jugador, eleccion)
	return tramitar(jugador, eleccion, Datos.PuedeEquipar, Datos.Equipar)
end
equipar.Parent = script.Parent

local function cerrar(ficha, limite)
	if ficha.cerrando then
		return
	end
	ficha.cerrando = true
	for _, nombre in ipairs(Datos.Claves) do
		capturar(ficha, nombre)
	end
	for _, conexion in ipairs(ficha.observadores) do
		conexion:Disconnect()
	end

	while (ficha.guardando or ficha.comprando) and os.clock() < limite do
		task.wait()
	end
	if os.clock() < limite then
		guardar(ficha, 2)
	end
	sesiones[ficha.jugador] = nil
end

Players.PlayerAdded:Connect(recibir)
Players.PlayerRemoving:Connect(function(jugador)
	local ficha = sesiones[jugador]
	if ficha then
		cerrar(ficha, os.clock() + 12)
	end
end)
for _, jugador in ipairs(Players:GetPlayers()) do
	recibir(jugador)
end

game:BindToClose(function()
	local limite = os.clock() + 24
	for _, ficha in pairs(sesiones) do
		task.spawn(cerrar, ficha, limite)
	end
	while next(sesiones) and os.clock() < limite do
		task.wait()
	end
end)
