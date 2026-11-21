-- Ejecutar en el servidor de prueba con ProgresoDatos en ServerScriptService.
-- Estas pruebas usan almacenes en memoria y fallos simulados.
local Datos = require(game:GetService("ServerScriptService"):WaitForChild("ProgresoDatos"))

local memoria = Datos.Memoria()
assert(memoria:GetAsync("uno") == nil)
local primerPremio = assert(Datos.Escribir(memoria, "uno", { Pedernal = true, Rebote = true }))
assert(primerPremio.Pedernal and primerPremio.Rebote and primerPremio.TesoroRevelado)
assert(not primerPremio.Cometa, "El acceso de prueba de Geoda no entrega el Eco Cometa.")
primerPremio.Pedernal = false
assert(memoria:GetAsync("uno").Pedernal, "Cambiar el resultado no modifica el perfil guardado.")
assert(Datos.Memoria():GetAsync("uno") == nil, "El modo sesión no persiste entre servidores.")

local mezcla = assert(Datos.Fusionar({
	Cometa = true,
	Vendaval = true,
	Lucero = true,
	PersonalizacionFutura = "ámbar",
	Version = 7,
}, {
	Rebote = true,
	Cometa = false,
	Lucero = false,
	MolinoVista = false,
}))
assert(mezcla.Cometa and mezcla.Vendaval and mezcla.Pedernal and mezcla.Rebote and mezcla.Lucero and mezcla.MolinoVista)
assert(mezcla.PersonalizacionFutura == "ámbar" and mezcla.Version == 7)
assert(Datos.Fusionar("antiguo desconocido", { Lucero = true }) == nil)

local inicio = Datos.Calcular(nil)
assert(inicio.Nivel == 1 and inicio.Experiencia == 0 and inicio.Monedas == 0
	and inicio.XpNivel == 0 and inicio.XpMeta == 100)

local antesDeLucero = { Cometa = true, Pedernal = true }
local temprano = Datos.Calcular(antesDeLucero)
assert(temprano.Nivel == 1 and temprano.Experiencia == 90 and temprano.Monedas == 50)
local puede, motivoTemprano = Datos.PuedeComprarPedernal(antesDeLucero)
assert(not puede and motivoTemprano == "FaltaNivel")

-- Los premios se derivan también al cargar un perfil de la versión anterior.
local perfilAntiguo = { Lucero = true, Version = 1 }
local economiaAntigua = Datos.Calcular(perfilAntiguo)
assert(economiaAntigua.Nivel == 2 and economiaAntigua.Experiencia == 160 and economiaAntigua.Monedas == 100
	and economiaAntigua.XpNivel == 60 and economiaAntigua.XpMeta == 120)
assert(Datos.PuedeComprarPedernal(perfilAntiguo))

local compras = Datos.Memoria()
assert(Datos.Escribir(compras, "compra", perfilAntiguo))
local compraA = compras:GetAsync("compra")
local compraB = compras:GetAsync("compra")
compraA.MejoraPedernal = true
compraB.MejoraPedernal = true
assert(Datos.Escribir(compras, "compra", compraA))
local compraFusionada = assert(Datos.Escribir(compras, "compra", compraB))
assert(compraFusionada.MejoraPedernal and compraFusionada.Version == 3)
assert(Datos.Calcular(compraFusionada).Monedas == 40, "Dos compras simultáneas descuentan un único recibo.")
assert(Datos.RecargaEscudo(compraFusionada) == 2.65 and Datos.RecargaEscudo(perfilAntiguo) == 3.95)
local permitida, motivoRepetido = Datos.PuedeComprarPedernal(compraFusionada)
assert(not permitida and motivoRepetido == "YaComprada")

local encargo = assert(Datos.Escribir(compras, "compra", { EncargoPedernal = true }))
assert(encargo.EncargoPedernal and Datos.Calcular(encargo).Monedas == 65 and Datos.Calcular(encargo).Experiencia == 200)
local completo = Datos.Calcular(assert(Datos.Escribir(compras, "compra", {
	EncargoPedernal = true,
	Vendaval = true,
	Rebote = true,
})))
assert(completo.Nivel == 3 and completo.Experiencia == 250 and completo.Monedas == 90
	and completo.XpNivel == 30 and completo.XpMeta == 140)

local reciboHeredado = Datos.Normalizar({ Lucero = true, EncargoPedernal = true })
assert(reciboHeredado.MejoraPedernal and reciboHeredado.EncargoPedernal)
local reciboInvalido = Datos.Normalizar({ Cometa = true, Pedernal = true, MejoraPedernal = true, EncargoPedernal = true })
assert(not reciboInvalido.MejoraPedernal and not reciboInvalido.EncargoPedernal
	and Datos.Calcular(reciboInvalido).Monedas == 50)

local puedePlanear, motivoPlaneador = Datos.PuedeComprarPlaneador(nil)
assert(not puedePlanear and motivoPlaneador == "FaltaCometa")
assert(Datos.PuedeComprarPlaneador(perfilAntiguo))

local gastadoEscudo, causaEscudo = Datos.Comprar(compras, "dos productos", perfilAntiguo, "MejoraPedernal")
assert(causaEscudo == "Comprada" and gastadoEscudo.MejoraPedernal and not gastadoEscudo.PlaneadorAvanzado)
local sinFondos, causaSinFondos = Datos.Comprar(compras, "dos productos", perfilAntiguo, "PlaneadorAvanzado")
assert(causaSinFondos == "MonedasInsuficientes" and Datos.Calcular(sinFondos).Monedas == 40)
local conAmbos, causaAmbos = Datos.Comprar(compras, "dos productos", { EncargoPedernal = true }, "PlaneadorAvanzado")
assert(causaAmbos == "Comprada" and conAmbos.EncargoPedernal and conAmbos.MejoraPedernal
	and conAmbos.PlaneadorAvanzado and Datos.Calcular(conAmbos).Monedas == 0)
local compraOtraVez, causaYaTiene = Datos.Comprar(compras, "dos productos", perfilAntiguo, "PlaneadorAvanzado")
assert(causaYaTiene == "YaComprada" and Datos.Calcular(compraOtraVez).Monedas == 0)

-- El recibo y la elección de planeador se guardan independientemente.
assert(conAmbos.PlaneadorEquipado == "Basico", "Comprar no cambia el planeador en uso.")
local equipoAntiguo = Datos.Fusionar({ Lucero = true, PlaneadorAvanzado = true }, {})
assert(equipoAntiguo.PlaneadorEquipado == "Avanzado", "Un comprador antiguo conserva su vuelo.")
assert(Datos.Fusionar({ Cometa = true, PlaneadorEquipado = "Avanzado" }, {}).PlaneadorEquipado == "Basico")
local bloqueado, falta = Datos.Equipar(memoria, "sin compra", { Cometa = true }, "Avanzado")
assert(falta == "FaltaPlaneador" and bloqueado.PlaneadorEquipado == "Basico" and not bloqueado.PlaneadorAvanzado)
local _, sinCometa = Datos.Equipar(memoria, "nuevo", {}, "Basico")
assert(sinCometa == "FaltaCometa")
local _, desconocido = Datos.Equipar(memoria, "nuevo", {}, "Inventado")
assert(desconocido == "PlaneadorDesconocido")
local equipado, acepta = Datos.Equipar(compras, "dos productos", {}, "Avanzado")
assert(acepta == "Equipado" and equipado.PlaneadorEquipado == "Avanzado" and equipado.RevisionEquipo == 1)
assert(compras:GetAsync("dos productos").PlaneadorEquipado == "Avanzado")
local repeticion = assert(Datos.Equipar(compras, "dos productos", {}, "Avanzado"))
assert(repeticion.RevisionEquipo == equipado.RevisionEquipo and Datos.Calcular(repeticion).Monedas == 0)
local preferido = assert(Datos.Equipar(compras, "dos productos", {}, "Basico"))
assert(preferido.PlaneadorEquipado == "Basico" and preferido.RevisionEquipo == 2 and preferido.PlaneadorAvanzado)
local premioTardio = assert(Datos.Escribir(compras, "dos productos", equipado))
assert(premioTardio.PlaneadorEquipado == "Basico" and premioTardio.RevisionEquipo == 2)

-- El primer callback intenta vender el escudo, mientras otro servidor confirma el planeador.
local carrera = {}
function carrera:UpdateAsync(clave, transformar)
	local intentoInicial = transformar(perfilAntiguo)
	assert(intentoInicial.MejoraPedernal)
	local competidor, causaCompetidor = Datos.Comprar(compras, clave, perfilAntiguo, "PlaneadorAvanzado")
	assert(causaCompetidor == "Comprada")
	local ultimo = transformar(competidor)
	return assert(Datos.Escribir(compras, clave, ultimo))
end
local confirmado, excluida = Datos.Comprar(carrera, "compras simultaneas", perfilAntiguo, "MejoraPedernal")
assert(excluida == "MonedasInsuficientes" and confirmado.PlaneadorAvanzado and not confirmado.MejoraPedernal
	and Datos.Calcular(confirmado).Monedas == 35)

local viejaSolicitud = { Lucero = true, MejoraPedernal = true, Version = 2 }
local reconciliada = assert(Datos.Escribir(compras, "compras simultaneas", viejaSolicitud))
assert(reconciliada.PlaneadorAvanzado and not reconciliada.MejoraPedernal and Datos.Calcular(reconciliada).Monedas == 35)

local respuestaPerdida = {}
function respuestaPerdida:UpdateAsync(clave, transformar)
	compras:UpdateAsync(clave, transformar)
	error("La respuesta se perdió después de escribir")
end
local noConfirmado = Datos.Comprar(respuestaPerdida, "respuesta perdida", perfilAntiguo, "PlaneadorAvanzado")
assert(noConfirmado == nil)
local reintentada, causaConfirmada = Datos.Comprar(compras, "respuesta perdida", perfilAntiguo, "PlaneadorAvanzado")
assert(reintentada.PlaneadorAvanzado and causaConfirmada == "YaComprada" and Datos.Calcular(reintentada).Monedas == 35)
local sinRespuesta = Datos.Equipar(respuestaPerdida, "respuesta perdida", {}, "Avanzado")
assert(sinRespuesta == nil)
local equipoRecuperado, causaEquipo = Datos.Equipar(compras, "respuesta perdida", {}, "Avanzado")
assert(causaEquipo == "Equipado" and equipoRecuperado.PlaneadorEquipado == "Avanzado"
	and equipoRecuperado.RevisionEquipo == 1 and Datos.Calcular(equipoRecuperado).Monedas == 35)

local premioLente = Datos.Calcular({ Lucero = true, LenteGeoda = true })
assert(premioLente.Experiencia == 160 and premioLente.Monedas == 100)
local premioFaro = Datos.Calcular({ Lucero = true, FaroEncendido = true })
assert(premioFaro.Experiencia == 225 and premioFaro.Monedas == 145)
local premioPrisma = assert(Datos.Escribir(compras, "faro", { FaroEncendido = true, Prisma = true, LenteGeoda = true }))
local faroRepetido = assert(Datos.Escribir(compras, "faro", { FaroEncendido = true, Prisma = true, LenteGeoda = true }))
assert(premioPrisma.Prisma and premioPrisma.LenteGeoda and premioPrisma.FaroEncendido and premioPrisma.Lucero)
assert(Datos.Calcular(faroRepetido).Monedas == 165 and Datos.Calcular(faroRepetido).Experiencia == 260)

local transporteFallido = true
local registros = {
	viento = { Cometa = true, Cornisa = true },
	geoda = { Pedernal = true },
}
local usuarios = { 123 }
local metadatos = { origen = "prueba" }
local claveInfo = {}
function claveInfo:GetUserIds()
	return usuarios
end
function claveInfo:GetMetadata()
	return metadatos
end
local remoto = {}
function remoto:UpdateAsync(clave, transformar)
	if clave == "viento" and transporteFallido then
		error("Escritura temporalmente indisponible.")
	end
	local primero = transformar(registros[clave], claveInfo)
	assert(primero, "Debe haber un candidato válido para actualizar.")
	-- Otro servidor desbloqueó la mutación entre intentos de UpdateAsync.
	if clave == "viento" then
		registros.viento.SelloGeoda = true
	end
	local definitivo, ids, info = transformar(registros[clave], claveInfo)
	assert(ids == usuarios and info == metadatos, "Se mantienen asociación y metadatos.")
	registros[clave] = definitivo
	return definitivo
end

local fallo, motivo = Datos.Escribir(remoto, "viento", { Lucero = true })
assert(not fallo and type(motivo) == "string" and registros.viento.Cornisa and not registros.viento.Lucero)
local geoda = assert(Datos.Escribir(remoto, "geoda", { MiradorGeoda = true }))
assert(geoda.Pedernal and geoda.MiradorGeoda and not geoda.Lucero, "El fallo de otro perfil no bloquea su guardado.")
transporteFallido = false
local viento = assert(Datos.Escribir(remoto, "viento", { Lucero = true }))
assert(viento.Cometa and viento.Vendaval and viento.Cornisa and viento.Lucero and viento.SelloGeoda and viento.Rebote)

local perfilAnterior = assert(Datos.Escribir(memoria, "nido", { Prisma = true }))
assert(not perfilAnterior.Nimbo and not perfilAnterior.NimboAurora)
local rescatado = assert(Datos.Escribir(memoria, "nido", { Nimbo = true }))
assert(rescatado.Nimbo and not rescatado.NimboAurora and rescatado.Prisma)
local raro = assert(Datos.Escribir(memoria, "nido", { NimboAurora = true }))
local repetido = assert(Datos.Escribir(memoria, "nido", perfilAnterior))
assert(raro.Nimbo and repetido.Nimbo and repetido.NimboAurora)
assert(Datos.Calcular(repetido).Monedas == Datos.Calcular(perfilAnterior).Monedas)
return "Compras, economía, elección de planeador, perfiles antiguos y persistencia de Nimbo y Aurora verificados."
