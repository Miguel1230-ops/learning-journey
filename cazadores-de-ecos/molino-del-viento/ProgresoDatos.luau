local ProgresoDatos = {}

ProgresoDatos.PrecioMejoraPedernal = 60
ProgresoDatos.PrecioPlaneadorAvanzado = 65

ProgresoDatos.Claves = table.freeze({
	"Cometa",
	"VigiasDerrotados",
	"Vendaval",
	"Refugio",
	"Cornisa",
	"Pedernal",
	"Rebote",
	"TesoroRevelado",
	"MiradorGeoda",
	"SelloGeoda",
	"MolinoVista",
	"Lucero",
	"MejoraPedernal",
	"EncargoPedernal",
	"PlaneadorAvanzado",
	"LenteGeoda",
	"ConsejoGeoda",
	"ConsejoLente",
	"FaroEncendido",
	"Prisma",
	"Nimbo",
	"NimboAurora",
})

local premios = {
	Cometa = { 40, 20 },
	Pedernal = { 50, 30 },
	Lucero = { 70, 50 },
	Vendaval = { 20, 10 },
	Rebote = { 30, 15 },
	FaroEncendido = { 65, 45 },
	Prisma = { 35, 20 },
}

local XP_NIVEL_DOS = 100
local XP_ENCARGO = 40
local MONEDAS_ENCARGO = 25

local function gananciasDeExpedicion(datos)
	local experiencia, monedas = 0, 0
	for nombre, premio in pairs(premios) do
		if datos[nombre] then
			experiencia += premio[1]
			monedas += premio[2]
		end
	end
	return experiencia, monedas
end

local function normalizar(datos, conservarPlaneador)
	local limpio = {}
	for _, nombre in ipairs(ProgresoDatos.Claves) do
		limpio[nombre] = type(datos) == "table" and datos[nombre] == true
	end

	-- Una recompensa del final de la ruta también prueba sus pasos previos.
	limpio.Nimbo = limpio.Nimbo or limpio.NimboAurora
	limpio.Prisma = limpio.Prisma or limpio.Nimbo
	limpio.LenteGeoda = limpio.LenteGeoda or limpio.Prisma
	limpio.FaroEncendido = limpio.FaroEncendido or limpio.Prisma
	limpio.Lucero = limpio.Lucero or limpio.FaroEncendido
	limpio.Vendaval = limpio.Vendaval or limpio.Cornisa
	limpio.Rebote = limpio.Rebote or limpio.SelloGeoda
	limpio.Pedernal = limpio.Pedernal or limpio.Rebote or limpio.TesoroRevelado
		or limpio.MiradorGeoda or limpio.Lucero or limpio.LenteGeoda
	limpio.Cometa = limpio.Cometa or limpio.Vendaval or limpio.Refugio or limpio.Lucero
	limpio.VigiasDerrotados = limpio.VigiasDerrotados or limpio.Cometa
	limpio.TesoroRevelado = limpio.Pedernal
	limpio.MolinoVista = limpio.MolinoVista or limpio.Lucero
	-- El encargo prueba la compra, pero su propio premio no puede financiarla.
	local experiencia, monedas = gananciasDeExpedicion(limpio)
	if limpio.MejoraPedernal or limpio.EncargoPedernal then
		limpio.MejoraPedernal = limpio.Pedernal and experiencia >= XP_NIVEL_DOS
			and monedas >= ProgresoDatos.PrecioMejoraPedernal
		limpio.EncargoPedernal = limpio.EncargoPedernal and limpio.MejoraPedernal
	end
	if limpio.PlaneadorAvanzado then
		local saldo = monedas + (if limpio.EncargoPedernal then MONEDAS_ENCARGO else 0)
			- (if limpio.MejoraPedernal then ProgresoDatos.PrecioMejoraPedernal else 0)
		if not limpio.Cometa or saldo < ProgresoDatos.PrecioPlaneadorAvanzado then
			-- Una escritura de premios no desplaza un recibo confirmado en el almacén.
			if conservarPlaneador and limpio.Cometa and monedas >= ProgresoDatos.PrecioPlaneadorAvanzado then
				limpio.MejoraPedernal = false
				limpio.EncargoPedernal = false
			else
				limpio.PlaneadorAvanzado = false
			end
		end
	end
	return limpio
end

function ProgresoDatos.Normalizar(datos)
	return normalizar(datos, false)
end

function ProgresoDatos.Calcular(datos)
	local limpio = ProgresoDatos.Normalizar(datos)
	local experiencia, monedas = gananciasDeExpedicion(limpio)
	if limpio.EncargoPedernal then
		experiencia += XP_ENCARGO
		monedas += MONEDAS_ENCARGO
	end
	if limpio.MejoraPedernal then
		monedas -= ProgresoDatos.PrecioMejoraPedernal
	end
	if limpio.PlaneadorAvanzado then
		monedas -= ProgresoDatos.PrecioPlaneadorAvanzado
	end

	-- El nivel 2 requiere 100 XP totales. Cada tramo siguiente cuesta 20 XP más.
	local nivel, xpNivel, xpMeta = 1, experiencia, XP_NIVEL_DOS
	while xpNivel >= xpMeta do
		xpNivel -= xpMeta
		nivel += 1
		xpMeta += 20
	end
	return {
		Nivel = nivel,
		Experiencia = experiencia,
		Monedas = monedas,
		XpNivel = xpNivel,
		XpMeta = xpMeta,
	}
end

function ProgresoDatos.PuedeComprarPedernal(datos)
	local limpio = ProgresoDatos.Normalizar(datos)
	if limpio.MejoraPedernal then
		return false, "YaComprada"
	end
	if not limpio.Pedernal then
		return false, "FaltaPedernal"
	end
	local estado = ProgresoDatos.Calcular(limpio)
	if estado.Nivel < 2 then
		return false, "FaltaNivel"
	end
	if estado.Monedas < ProgresoDatos.PrecioMejoraPedernal then
		return false, "MonedasInsuficientes"
	end
	return true, "Comprada"
end

function ProgresoDatos.PuedeComprarPlaneador(datos)
	local limpio = ProgresoDatos.Normalizar(datos)
	if limpio.PlaneadorAvanzado then
		return false, "YaComprada"
	end
	if not limpio.Cometa then
		return false, "FaltaCometa"
	end
	if ProgresoDatos.Calcular(limpio).Monedas < ProgresoDatos.PrecioPlaneadorAvanzado then
		return false, "MonedasInsuficientes"
	end
	return true, "Comprada"
end

function ProgresoDatos.RecargaEscudo(datos)
	return if type(datos) == "table" and datos.MejoraPedernal == true then 2.65 else 3.95
end

function ProgresoDatos.Fusionar(anterior, ganado)
	if anterior ~= nil and type(anterior) ~= "table" then
		return nil
	end

	local guardado = ProgresoDatos.Normalizar(anterior)
	local conservado = if anterior then table.clone(anterior) else {}
	for _, nombre in ipairs(ProgresoDatos.Claves) do
		conservado[nombre] = conservado[nombre] == true or (type(ganado) == "table" and ganado[nombre] == true)
	end
	for nombre, obtenido in pairs(normalizar(conservado, guardado.PlaneadorAvanzado)) do
		conservado[nombre] = obtenido
	end
	-- Los recibos antiguos equipaban el avanzado automáticamente. Una compra nueva
	-- parte del básico y solo una elección explícita puede cambiarlo.
	local eleccion = if anterior then anterior.PlaneadorEquipado else nil
	local usaAvanzado = eleccion == "Avanzado" or (eleccion == nil and guardado.PlaneadorAvanzado)
	conservado.PlaneadorEquipado = if usaAvanzado and conservado.PlaneadorAvanzado then "Avanzado" else "Basico"
	local revision = conservado.RevisionEquipo
	conservado.RevisionEquipo = if type(revision) == "number" and revision >= 0 and revision < math.huge
		then math.floor(revision) else 0
	local version = conservado.Version
	conservado.Version = if type(version) == "number" and version >= 3 then version else 3
	return conservado
end

local function actualizar(almacen, clave, transformar)
	local ok, resultado = pcall(function()
		return almacen:UpdateAsync(clave, function(anterior, informacionClave)
			local cambiado = transformar(anterior)
			if cambiado and informacionClave then
				return cambiado, informacionClave:GetUserIds(), informacionClave:GetMetadata()
			end
			return cambiado
		end)
	end)
	if ok and type(resultado) == "table" then
		return resultado
	end
	return nil, if ok then "El perfil antiguo tiene un formato desconocido." else resultado
end

function ProgresoDatos.Escribir(almacen, clave, ganado)
	return actualizar(almacen, clave, function(anterior)
		return ProgresoDatos.Fusionar(anterior, ganado)
	end)
end

local validadores = {
	MejoraPedernal = ProgresoDatos.PuedeComprarPedernal,
	PlaneadorAvanzado = ProgresoDatos.PuedeComprarPlaneador,
}

function ProgresoDatos.Comprar(almacen, clave, ganado, producto)
	local validar = assert(validadores[producto], "Producto desconocido")
	local motivo
	local perfil, fallo = actualizar(almacen, clave, function(anterior)
		local cambiado = ProgresoDatos.Fusionar(anterior, ganado)
		if not cambiado then
			return nil
		end
		-- UpdateAsync puede repetir la validación si otro servidor escribe primero.
		local permitido, causa = validar(cambiado)
		motivo = causa
		if permitido then
			cambiado[producto] = true
		end
		return cambiado
	end)
	if not perfil then
		return nil, fallo
	end
	return perfil, motivo
end

function ProgresoDatos.PuedeEquipar(perfil, eleccion)
	if eleccion ~= "Basico" and eleccion ~= "Avanzado" then
		return false, "PlaneadorDesconocido"
	end
	if not perfil.Cometa then
		return false, "FaltaCometa"
	end
	if eleccion == "Avanzado" and not perfil.PlaneadorAvanzado then
		return false, "FaltaPlaneador"
	end
	return true, "Equipado"
end

function ProgresoDatos.Equipar(almacen, clave, ganado, eleccion)
	local motivo
	local perfil, fallo = actualizar(almacen, clave, function(anterior)
		local cambiado = ProgresoDatos.Fusionar(anterior, ganado)
		if not cambiado then
			return nil
		end
		local permitido, causa = ProgresoDatos.PuedeEquipar(cambiado, eleccion)
		motivo = causa
		if permitido and cambiado.PlaneadorEquipado ~= eleccion then
			cambiado.PlaneadorEquipado = eleccion
			cambiado.RevisionEquipo += 1
		end
		return cambiado
	end)
	return perfil, if perfil then motivo else fallo
end

function ProgresoDatos.Memoria()
	local perfiles = {}
	local memoria = {}

	function memoria:GetAsync(clave)
		local perfil = perfiles[clave]
		return if perfil then table.clone(perfil) else nil
	end

	function memoria:UpdateAsync(clave, actualizar)
		local cambiado = actualizar(self:GetAsync(clave))
		if cambiado then
			perfiles[clave] = table.clone(cambiado)
		end
		return cambiado
	end

	return memoria
end

return ProgresoDatos
