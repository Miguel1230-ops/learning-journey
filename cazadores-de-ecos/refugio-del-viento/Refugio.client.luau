local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer
local playerGui = jugador:WaitForChild("PlayerGui")
local remoto = ReplicatedStorage:WaitForChild("AccionRefugio")
local Planeadores = require(ReplicatedStorage:WaitForChild("Planeadores"))
local RutaIslas = require(ReplicatedStorage:WaitForChild("RutaIslas"))
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local Ecodex = require(ReplicatedStorage:WaitForChild("Ecodex"))
local Cabecera = require(ReplicatedStorage:WaitForChild("CabeceraExpedicion"))

local NOCHE = Color3.fromRGB(14, 24, 37)
local PANEL = Color3.fromRGB(22, 35, 52)
local TARJETA = Color3.fromRGB(26, 42, 60)
local BORDE = Color3.fromRGB(66, 87, 108)
local PERLA = Color3.fromRGB(250, 248, 237)
local SUAVE = Color3.fromRGB(194, 210, 225)
local ORO = Color3.fromRGB(255, 211, 126)
local MENTA = Color3.fromRGB(142, 243, 209)
local HIELO = Color3.fromRGB(158, 222, 252)
local CORAL = Color3.fromRGB(255, 168, 153)
local PRECIO_ESCUDO = 60
local PRECIO_PLANEADOR = 65
local ventajaVelocidad = math.round((Planeadores.ajustes(true).velocidad / Planeadores.ajustes(false).velocidad - 1) * 100)
local NIVEL_MINIMO = 2
local ALTA = Enum.ContextActionPriority.High.Value + 7

local function crear(clase, padre, atributos)
	local objeto = Instance.new(clase)
	for nombre, valor in pairs(atributos) do
		objeto[nombre] = valor
	end
	objeto.Parent = padre
	return objeto
end

local function contorno(objeto, radio, color)
	crear("UICorner", objeto, { CornerRadius = UDim.new(0, radio) })
	return crear("UIStroke", objeto, {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color = color,
		Transparency = 0.37,
	})
end

local function marco(padre, nombre, posicion, medida, color)
	return crear("Frame", padre, {
		Name = nombre, Position = posicion, Size = medida,
		BackgroundColor3 = color, BorderSizePixel = 0,
	})
end

local function etiqueta(padre, nombre, posicion, medida, texto, color, tamano, negrita)
	return crear("TextLabel", padre, {
		Name = nombre, Position = posicion, Size = medida,
		BackgroundTransparency = 1, Text = texto, TextColor3 = color,
		TextSize = tamano, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
		Font = if negrita then Enum.Font.GothamBold else Enum.Font.GothamMedium,
	})
end

local function boton(padre, nombre, posicion, medida, texto, color)
	local b = crear("TextButton", padre, {
		Name = nombre, Position = posicion, Size = medida, BackgroundColor3 = color,
		Text = texto, TextColor3 = PERLA, TextSize = 14, Font = Enum.Font.GothamBold,
		BorderSizePixel = 0, TextWrapped = true, Selectable = true,
	})
	contorno(b, 10, BORDE)
	return b
end



local function desplazar(padre, nombre)
	local area = crear("ScrollingFrame", padre, {
		Name = nombre, Position = UDim2.fromOffset(13, 120), Size = UDim2.new(1, -26, 1, -132),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
		ScrollBarImageColor3 = BORDE, ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.fromOffset(0, 0),
	})
	crear("UIPadding", area, { PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 9),
		PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 4) })
	return area
end

local gui = crear("ScreenGui", playerGui, {
	Name = "RefugioHUD", ResetOnSpawn = false, DisplayOrder = 18,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
})

local TINTA = Color3.fromRGB(18, 43, 48)
local TURQUESA = Color3.fromRGB(104, 222, 198)
local LATON = Color3.fromRGB(240, 189, 96)

local function degradado(objeto, inicio, fin, angulo)
	crear("UIGradient", objeto, { Color = ColorSequence.new(inicio, fin), Rotation = angulo })
end

local cabecera = Cabecera.crear(gui, jugador)
local progreso, aviso = cabecera.progreso, cabecera.aviso

local menu = marco(gui, "Menu", UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), NOCHE)
menu.BackgroundTransparency = 1
menu.Visible = false
menu.ZIndex = 5
local fondo = crear("TextButton", menu, {
	Name = "Fondo", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NOCHE,
	BackgroundTransparency = 0.29, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	Selectable = false,
})
local panel = marco(menu, "Panel", UDim2.fromScale(0.5, 0.5), UDim2.new(1, -24, 1, -26), NOCHE)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Active = true
panel.ZIndex = 2
contorno(panel, 17, BORDE)
crear("UISizeConstraint", panel, { MaxSize = Vector2.new(836, 500) })
local titulo = etiqueta(panel, "Titulo", UDim2.fromOffset(17, 10), UDim2.new(1, -82, 0, 32), "", PERLA, 23, true)
local subtitulo = etiqueta(panel, "Subtitulo", UDim2.fromOffset(17, 44), UDim2.new(1, -82, 0, 22), "", SUAVE, 13, false)
local cerrar = boton(panel, "Cerrar", UDim2.new(1, -58, 0, 12), UDim2.fromOffset(44, 44), "×", TARJETA)
cerrar.TextSize = 23

-- El encuadre conserva al personaje en escena y la conversación en el área segura.
local function construirDialogo()
	local base = marco(menu, "Dialogo", UDim2.new(0.5, 0, 1, -12), UDim2.new(1, -24, 0, 152), Color3.new(1, 1, 1))
	base.AnchorPoint = Vector2.new(0.5, 1)
	base.Visible = false
	base.Active = true
	base.ZIndex = 3
	contorno(base, 15, LATON)
	degradado(base, TINTA, NOCHE, 16)
	crear("UISizeConstraint", base, { MaxSize = Vector2.new(716, 260) })

	local insignia = marco(base, "Farol", UDim2.fromOffset(15, 12), UDim2.fromOffset(32, 32), TINTA)
	contorno(insignia, 8, LATON)
	marco(insignia, "Asa", UDim2.fromOffset(13, 4), UDim2.fromOffset(6, 3), LATON)
	marco(insignia, "Techo", UDim2.fromOffset(9, 9), UDim2.fromOffset(14, 3), LATON)
	local luz = marco(insignia, "Llama", UDim2.fromOffset(12, 14), UDim2.fromOffset(8, 9), ORO)
	contorno(luz, 3, LATON)
	marco(insignia, "Pie", UDim2.fromOffset(10, 25), UDim2.fromOffset(12, 2), LATON)
	local nombre = etiqueta(base, "Nombre", UDim2.fromOffset(57, 11), UDim2.new(1, -120, 0, 33),
		"Farero del Viento", ORO, 20, true)
	nombre.Font = Enum.Font.Bodoni
	local frase = etiqueta(base, "Frase", UDim2.fromOffset(17, 52), UDim2.new(0.54, -29, 1, -64), "", PERLA, 16, false)
	frase.TextYAlignment = Enum.TextYAlignment.Top
	local opciones = marco(base, "Respuestas", UDim2.new(0.54, 0, 0, 52), UDim2.new(0.46, -15, 1, -64), TINTA)
	opciones.BackgroundTransparency = 1
	local function opcion(id, texto, segunda)
		local b = boton(opciones, id, UDim2.new(0, 0, if segunda then 0.5 else 0, if segunda then 2 else 0),
			UDim2.new(1, 0, 0.5, -2), texto, TINTA)
		b.TextXAlignment = Enum.TextXAlignment.Left
		crear("UIPadding", b, { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) })
		return b
	end
	local faro = opcion("Faro", "¿Qué luz viste?", false)
	local mejoras = opcion("Mejoras", "Muéstrame tu equipo", true)
	local seguir = opcion("SeguirSenal", "Seguir la señal", false)
	local volver = opcion("Volver", "Volver a hablar", true)
	local salir = boton(base, "Despedir", UDim2.new(1, -98, 0, 6), UDim2.fromOffset(88, 40), "Hasta luego", PANEL)
	salir.TextSize = 12
	return base, frase, faro, mejoras, seguir, volver, salir
end

local dialogo, fraseFarero, temaFaro, temaMejoras, seguirSenal, volverDeSenal, despedir = construirDialogo()


local verEcos = boton(panel, "VerEcos", UDim2.fromOffset(15, 69), UDim2.new(0.5, -20, 0, 39),
	"Ecodex", TARJETA)
local verPlaneadores = boton(panel, "VerPlaneadores", UDim2.new(0.5, 5, 0, 69), UDim2.new(0.5, -20, 0, 39),
	"Planeadores", TARJETA)
local inventario = desplazar(panel, "Inventario")
local album = Ecodex.crear(inventario, jugador)
album.botones[1].NextSelectionUp = verEcos
verEcos.NextSelectionDown = album.botones[1]

local equipo = desplazar(panel, "Planeadores")
local gridEquipo = crear("UIGridLayout", equipo, {
	CellPadding = UDim2.fromOffset(12, 12), CellSize = UDim2.fromOffset(260, 250),
	FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder,
})
local fichasPlaneadores = {}
for orden, datos in ipairs({
	{ nombre = "Básico", id = "Basico", color = ORO },
	{ nombre = "Avanzado", id = "Avanzado", color = MENTA },
}) do
	local ficha = marco(equipo, datos.id, UDim2.fromOffset(0, 0), UDim2.fromOffset(260, 250), TARJETA)
	ficha.Visible = datos.id == "Basico"
	ficha.LayoutOrder = orden
	contorno(ficha, 13, datos.color)
	local retrato = crear("ViewportFrame", ficha, {
		Name = "Retrato", Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 0, 121),
		BackgroundColor3 = NOCHE, BorderSizePixel = 0, Ambient = Color3.fromRGB(187, 202, 218),
		LightColor = PERLA, LightDirection = Vector3.new(0.35, -1, -0.5),
	})
	crear("UICorner", retrato, { CornerRadius = UDim.new(0, 9) })
	etiqueta(ficha, "Nombre", UDim2.fromOffset(12, 137), UDim2.new(1, -24, 0, 25),
		"Planeador " .. datos.nombre, PERLA, 16, true)
	local estado = etiqueta(ficha, "Estado", UDim2.fromOffset(12, 197), UDim2.new(1, -24, 0, 43),
		"", datos.color, 13, true)
	local detalle = etiqueta(ficha, "Detalle", UDim2.fromOffset(12, 161), UDim2.new(1, -24, 0, 35),
		"", SUAVE, 12, false)
	local accion = "Equipar" .. datos.id
	local elegir = boton(ficha, accion, UDim2.fromOffset(12, 197), UDim2.new(1, -24, 0, 43), "Equipar", datos.color)
	elegir.TextColor3 = NOCHE
	fichasPlaneadores[orden] = { tarjeta = ficha, retrato = retrato, estado = estado, detalle = detalle,
		id = datos.id, accion = accion, elegir = elegir }
end

local tienda = desplazar(panel, "Tienda")
tienda.Position = UDim2.fromOffset(13, 129)
tienda.Size = UDim2.new(1, -26, 1, -141)
tienda.Visible = false
local volverDeTienda = boton(panel, "Volver", UDim2.new(1, -145, 0, 12), UDim2.fromOffset(76, 44), "Volver", TARJETA)
volverDeTienda.Visible = false
local palabrasFarero = etiqueta(panel, "PalabrasFarero", UDim2.fromOffset(17, 72), UDim2.new(1, -34, 0, 52),
	"", PERLA, 14, false)
palabrasFarero.BackgroundTransparency = 0
palabrasFarero.BackgroundColor3 = NOCHE
contorno(palabrasFarero, 10, LATON)
crear("UIPadding", palabrasFarero, { PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13) })
palabrasFarero.Visible = false
local contenido = marco(tienda, "Contenido", UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 0), TARJETA)
contenido.BackgroundTransparency = 1
local mejoras = {
	{
		nombre = "MejorarPedernal", compra = "ComprarPedernal", atributo = "MejoraPedernal",
		titulo = "Escudo rápido", eco = "Pedernal", precio = PRECIO_ESCUDO, color = HIELO,
		efecto = "El escudo se recarga en 2,65 s en el molino y el relevo de los faroles.",
	},
	{
		nombre = "MejorarPlaneador", compra = "ComprarPlaneador", atributo = "PlaneadorAvanzado",
		titulo = "Planeador avanzado", eco = "Cometa", precio = PRECIO_PLANEADOR, color = MENTA,
		efecto = ("Vuela un %d %% más rápido, gira mejor y planea 0,60 s más que el básico."):format(ventajaVelocidad),
	},
}
for _, mejora in ipairs(mejoras) do
	local tarjeta = marco(contenido, mejora.nombre, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 213), TARJETA)
	contorno(tarjeta, 12, mejora.color)
	local distintivo = marco(tarjeta, "Distintivo", UDim2.fromOffset(16, 13), UDim2.fromOffset(42, 42), PANEL)
	contorno(distintivo, 9, mejora.color)
	tarjeta.BackgroundColor3 = Color3.new(1, 1, 1)
	degradado(tarjeta, TINTA, PANEL, 75)
	if mejora.eco == "Pedernal" then
		local punta = marco(distintivo, "Punta", UDim2.fromOffset(13, 17), UDim2.fromOffset(16, 16), mejora.color)
		punta.Rotation = 45
		local cuerpo = marco(distintivo, "Escudo", UDim2.fromOffset(10, 9), UDim2.fromOffset(22, 17), mejora.color)
		crear("UICorner", cuerpo, { CornerRadius = UDim.new(0, 4) })
		marco(distintivo, "Refuerzo", UDim2.fromOffset(20, 13), UDim2.fromOffset(2, 15), TINTA)
	else
		for _, lado in { -1, 1 } do
			local ala = marco(distintivo, "Ala", UDim2.fromOffset(16 + lado * 6, 12), UDim2.fromOffset(9, 20), mejora.color)
			ala.Rotation = lado * 53
		end
		marco(distintivo, "Quilla", UDim2.fromOffset(20, 15), UDim2.fromOffset(2, 17), ORO)
	end
	etiqueta(tarjeta, "Mejora", UDim2.fromOffset(70, 10), UDim2.new(1, -83, 0, 30),
		mejora.titulo, PERLA, 17, true)
	etiqueta(tarjeta, "Eco", UDim2.fromOffset(70, 39), UDim2.new(1, -83, 0, 19),
		mejora.eco, mejora.color, 13, true)
	local efecto = etiqueta(tarjeta, "Efecto", UDim2.fromOffset(13, 67), UDim2.new(1, -26, 0, 46),
		mejora.efecto, PERLA, 14, false)
	efecto.TextYAlignment = Enum.TextYAlignment.Top
	local comprar = boton(tarjeta, mejora.compra, UDim2.fromOffset(13, 119), UDim2.new(1, -26, 0, 44),
		("Comprar · %d monedas"):format(mejora.precio), PANEL)
	local estado = etiqueta(tarjeta, "CompraEstado", UDim2.fromOffset(13, 167), UDim2.new(1, -26, 0, 35),
		"", SUAVE, 12, false)
	mejora.tarjeta, mejora.boton, mejora.estado = tarjeta, comprar, estado
end

local encargo = UI.objetivo(gui)
encargo.marco.Name = "Encargo"
encargo:visible(false)
local accionesEncargo = UI.acciones(gui)
accionesEncargo:visible(false)

local seleccionAnterior
local pantalla = "Inventario"
local viendoPlaneadores = false
local tomaFarero
local avisoHabilitado
local avisoFarero
local partesOcultas = {}
local CAMARA_FARERO = "EncuadreDelFarero"
local dialogoAutorizado = false
local enAlcance = false
local hastaSolicitud = 0
local solicitud
local numeroSolicitud = 0
local proximoEscudo = 0
local respuestaFarero
local noticias = {}
local toastHasta = 0
local fichaLuceroPendiente = false
local fichaLuceroVista = false
local luceroAntes = jugador:GetAttribute("Lucero") == true
local descuentoXP, descuentoMonedas = 0, 0
local sumarXP, sumarMonedas = 0, 0
local saldoPrevio = jugador:GetAttribute("Monedas") or 0
local xpPrevio = jugador:GetAttribute("Experiencia") or 0
local nivelMostrado = jugador:GetAttribute("Nivel") or 1
local mostrarPremioEn
local premioEncargo = false
local finAnterior
local tiempoTotal = 1

local mensajes = {
	FaltaLente = "Trae la lente de la revancha. El portal está junto a mi puesto.",
	FaltaNivel = "Ven a verme al llegar al nivel 2.",
	FaltaPedernal = "Primero trae a Pedernal. Lo encontrarás en la Cueva de la Geoda.",
	FaltaCometa = "Rescata a Cometa. Cuando pueda ayudarte a planear, ven a verme.",
	FaltaLucero = "Necesito que Lucero te acompañe. Ve por él al Molino del Viento.",
	MonedasInsuficientes = "Te faltan monedas para esta mejora.",
	ProgresoNoListo = "Aún estoy consultando tu progreso.",
	GuardadoNoDisponible = "No pude guardar el cambio. Inténtalo de nuevo en un momento.",
	Comprando = "Espera un momento antes de volver a intentarlo.",
	FaltaPlaneador = "El planeador avanzado se consigue en el taller del Farero.",
	Lejos = "Acércate a mi taller para que podamos hablar.",
}

local function ocupado()
	return jugador:GetAttribute("MolinoPresentando") or jugador:GetAttribute("GeodaPresentando")
		or jugador:GetAttribute("FaroPresentando")
end

local function dispositivo()
	local entrada = UserInputService:GetLastInputType()
	local preferida = UserInputService.PreferredInput
	local mando = entrada.Name:match("^Gamepad") ~= nil or preferida == Enum.PreferredInput.Gamepad
	local tactil = not mando and (entrada == Enum.UserInputType.Touch or preferida == Enum.PreferredInput.Touch)
	return mando, tactil
end

local function cercaDelFarero()
	local personaje = jugador.Character
	local raiz = personaje and personaje:FindFirstChild("HumanoidRootPart")
	local isla = workspace:FindFirstChild("IslaDelViento")
	local refugio = isla and isla:FindFirstChild("RefugioDelViento")
	local punto = refugio and refugio:FindFirstChild("PuntoFarero")
	local prompt = punto and punto:FindFirstChildOfClass("ProximityPrompt")
	return raiz ~= nil and punto ~= nil
		and (raiz.Position - punto.Position).Magnitude <= (if prompt then prompt.MaxActivationDistance + 0.5 else 10)
end



local function dibujarPlaneadores()
	local tengoBasico = jugador:GetAttribute("Cometa") == true
	local tengoAvanzado = jugador:GetAttribute("PlaneadorAvanzado") == true
	for orden, ficha in ipairs(fichasPlaneadores) do
		local avanzado = orden == 2
		ficha.tarjeta.Visible = not avanzado or tengoAvanzado
		if not ficha.tarjeta.Visible then
			continue
		end
		if not ficha.retrato.CurrentCamera then
			local rig = Planeadores.crear(avanzado)
			Planeadores.colocar(rig, Vector3.zero, -Vector3.zAxis, 1, 0)
			local mundo = crear("WorldModel", ficha.retrato, {})
			rig.modelo.Parent = mundo
			rig.modelo.PrimaryPart = rig.cuerpo.PrimaryPart
			local centro, medida = rig.modelo:GetBoundingBox()
			local foco = centro.Position + Vector3.yAxis * 0.35
			local camara = crear("Camera", ficha.retrato, { FieldOfView = 38 })
			local function encuadrar()
				local tam = ficha.retrato.AbsoluteSize
				local aspecto = math.max(0.5, tam.X / math.max(1, tam.Y))
				local distancia = math.max(medida.X / aspecto, medida.Z) * 1.55 + 0.6
				camara.CFrame = CFrame.lookAt(foco + Vector3.new(0, 0.93, -0.37).Unit * distancia, foco)
			end
			encuadrar()
			ficha.retrato:GetPropertyChangedSignal("AbsoluteSize"):Connect(encuadrar)
			ficha.retrato.CurrentCamera = camara
		end
		local obtenido = if avanzado then tengoAvanzado else tengoBasico
		local equipado = obtenido and ficha.id == (jugador:GetAttribute("PlaneadorEquipado") or "Basico")
		ficha.elegir.Visible = obtenido and not equipado
		ficha.elegir.Active = ficha.elegir.Visible and jugador:GetAttribute("ProgresoListo") == true and not solicitud
		ficha.elegir.Selectable = ficha.elegir.Visible
		ficha.elegir.AutoButtonColor = ficha.elegir.Active
		ficha.elegir.Text = if solicitud == ficha.accion then "Equipando…" else "Equipar"
		ficha.estado.Visible = not ficha.elegir.Visible
		if GuiService.SelectedObject == ficha.elegir and not ficha.elegir.Visible then
			GuiService.SelectedObject = verPlaneadores
		end
		ficha.estado.Text = if equipado then "Equipado" elseif obtenido then "Obtenido" else "Por conseguir"
		ficha.detalle.Text = if avanzado
			then ("Un %d %% más rápido que el básico. Hasta 3,05 s de planeo."):format(ventajaVelocidad)
			else (if obtenido then "Hasta 2,45 s de planeo." else "Rescata a Cometa para desbloquearlo.")
	end
end

local function dibujarProgreso()
	local mando = dispositivo()
	cabecera.actualizar(mando)
end

local function dibujarDialogo()
	local tema = pantalla == "SenalFaro"
	temaFaro.Visible = not tema
	temaMejoras.Visible = not tema
	seguirSenal.Visible = tema and jugador:GetAttribute("Lucero") == true and jugador:GetAttribute("LenteGeoda") == true
	volverDeSenal.Visible = tema
	local puedoEnviar = dialogoAutorizado and enAlcance and jugador:GetAttribute("ProgresoListo")
		and jugador:GetAttribute("Lucero") and jugador:GetAttribute("LenteGeoda") and (jugador:GetAttribute("Nivel") or 1) >= NIVEL_MINIMO
		and not solicitud
	seguirSenal.Active = puedoEnviar == true
	seguirSenal.Selectable = seguirSenal.Active
	seguirSenal.AutoButtonColor = seguirSenal.Active
	seguirSenal.BackgroundColor3 = if seguirSenal.Active then ORO else PANEL
	seguirSenal.TextColor3 = if seguirSenal.Active then NOCHE else SUAVE
	seguirSenal.Text = if solicitud == "PrepararFaro" then "Preparando la salida…" else "Seguir la señal"
	local _, destino = RutaIslas.destino(jugador)
	fraseFarero.Text = respuestaFarero or destino[3]
	temaFaro.Text = if jugador:GetAttribute("LenteGeoda") and jugador:GetAttribute("Lucero") then "Seguir la señal del faro" else "¿Adónde voy ahora?"
end

local function dibujarTienda()
	local listo = jugador:GetAttribute("ProgresoListo") == true
	local escudoEquipado = jugador:GetAttribute("MejoraPedernal") == true
	local planeadorComprado = jugador:GetAttribute("PlaneadorAvanzado") == true
	local planeadorEquipado = planeadorComprado and jugador:GetAttribute("PlaneadorEquipado") == "Avanzado"
	local nivelActual = jugador:GetAttribute("Nivel") or 1
	local monedas = jugador:GetAttribute("Monedas") or 0
	subtitulo.Text = if listo then ("Tu bolsa · %d monedas"):format(monedas) else "Consultando tu progreso…"
	subtitulo.TextColor3 = ORO
	palabrasFarero.Text = respuestaFarero or (if escudoEquipado and planeadorEquipado
		then "Ya equipé a Pedernal con Escudo rápido y a Cometa con el planeador avanzado."
		elseif escudoEquipado then "Pedernal ya tiene Escudo rápido. Si quieres probarlo, acércate al relevo de los faroles."
		elseif planeadorEquipado then "Ya te entregué el planeador avanzado. Salta y activa el planeo para desplegarlo."
		elseif planeadorComprado then "Tu planeador avanzado está listo. Puedes equiparlo aquí o en tu inventario."
		else "Puedo ajustar el escudo de Pedernal o preparar un planeador más ágil para tus viajes.")
	for _, mejora in ipairs(mejoras) do
		local comprada = jugador:GetAttribute(mejora.atributo) == true
		local equipada = comprada and (mejora.compra ~= "ComprarPlaneador" or planeadorEquipado)
		local causa
		if not listo then
			causa = "ProgresoNoListo"
		elseif not jugador:GetAttribute(mejora.eco) then
			causa = if mejora.eco == "Pedernal" then "FaltaPedernal" else "FaltaCometa"
		elseif mejora.eco == "Pedernal" and nivelActual < NIVEL_MINIMO then
			causa = "FaltaNivel"
		elseif not comprada and monedas < mejora.precio then
			causa = "MonedasInsuficientes"
		elseif not dialogoAutorizado or not enAlcance then
			causa = "Lejos"
		end
		local disponible = not equipada and not causa and not solicitud
		local comprar = mejora.boton
		comprar.Active = disponible
		comprar.Selectable = disponible or solicitud == mejora.compra or (comprada and solicitud == "EquiparAvanzado" and mejora.eco == "Cometa")
		if GuiService.SelectedObject == comprar and not comprar.Selectable then
			GuiService.SelectedObject = volverDeTienda
		end
		comprar.AutoButtonColor = disponible
		comprar.BackgroundColor3 = if disponible then mejora.color else PANEL
		comprar.TextColor3 = if disponible then NOCHE else SUAVE
		comprar.Text = if equipada then "Equipado"
			elseif comprada then (if solicitud == "EquiparAvanzado" then "Equipando…" else "Equipar")
			elseif solicitud == mejora.compra then "Comprando…"
			else ("Comprar · %d monedas"):format(mejora.precio)
		mejora.estado.Text = if equipada and mejora.eco == "Pedernal" and not jugador:GetAttribute("EncargoPedernal")
			then "Prueba el escudo en el relevo de los faroles."
			elseif equipada then "Ya forma parte de tu equipo."
			elseif comprada then "Ya es tuyo. Puedes cambiarlo cuando quieras."
			elseif causa == "MonedasInsuficientes" then ("Te faltan %d monedas."):format(mejora.precio - monedas)
			elseif causa then mensajes[causa]
			else ("Te quedarán %d monedas. Compra permanente."):format(monedas - mejora.precio)
	end
end

local function actualizarPanel()
	local coleccion = pantalla == "Inventario"
	local intercambio = pantalla == "Mejoras"
	local conversacion = not coleccion and not intercambio
	panel.Visible = not conversacion
	panel.BackgroundColor3 = if intercambio then TINTA else NOCHE
	dialogo.Visible = conversacion
	fondo.BackgroundTransparency = if conversacion then 0.90 else 0.29
	inventario.Visible = coleccion and not viendoPlaneadores
	equipo.Visible = coleccion and viendoPlaneadores
	verEcos.Visible = coleccion
	verPlaneadores.Visible = coleccion
	verEcos.BackgroundColor3 = if viendoPlaneadores then TARJETA else TURQUESA
	verPlaneadores.BackgroundColor3 = if viendoPlaneadores then TURQUESA else TARJETA
	verEcos.TextColor3 = if viendoPlaneadores then PERLA else NOCHE
	verPlaneadores.TextColor3 = if viendoPlaneadores then NOCHE else PERLA
	tienda.Visible = intercambio
	volverDeTienda.Visible = intercambio
	palabrasFarero.Visible = intercambio
	titulo.Text = if coleccion then "Mochila" else "Taller del Farero"
	titulo.Font = Enum.Font.Bodoni
	titulo.Size = UDim2.new(1, if intercambio then -169 else -82, 0, 32)
	if coleccion then
		subtitulo.TextColor3 = SUAVE
		if viendoPlaneadores then
			dibujarPlaneadores()
			subtitulo.Text = respuestaFarero or (if not jugador:GetAttribute("ProgresoListo") then "Cargando el equipo…"
				elseif jugador:GetAttribute("PlaneadorEquipado") == "Avanzado" then "Equipado · Planeador avanzado"
				elseif jugador:GetAttribute("Cometa") then "Equipado · Planeador básico"
				else "Rescata a Cometa para equipar tu primer planeador.")
		else
			subtitulo.Text = if jugador:GetAttribute("ProgresoListo") then album.mostrar() else "Cargando el Ecodex…"
		end
	elseif intercambio then
		dibujarTienda()
	else
		subtitulo.Text = if pantalla == "SenalFaro" then "Las Ruinas del Faro" else ""
		dibujarDialogo()
	end
	dibujarProgreso()
end

local function enfocarAlFarero()
	local isla = workspace:FindFirstChild("IslaDelViento")
	local refugio = isla and isla:FindFirstChild("RefugioDelViento")
	local punto = refugio and refugio:FindFirstChild("PuntoFarero")
	local farero = refugio and refugio:FindFirstChild("Farero")
	local rostroFarero = farero and farero:FindFirstChild("Rostro")
	local prompt = punto and punto:FindFirstChildOfClass("ProximityPrompt")
	if not prompt or not rostroFarero then return end
	if avisoHabilitado == nil then
		avisoFarero = prompt
		avisoHabilitado = avisoFarero.Enabled
		avisoFarero.Enabled = false
		local seguidores = isla:FindFirstChild("CompanerosCometa")
		local propio = seguidores and seguidores:FindFirstChild(tostring(jugador.UserId))
		local nido = isla:FindFirstChild("Nido")
		local cometa = propio or (nido and nido:FindFirstChild("Cometa"))
		local ocultar = if cometa then {cometa} else {}
		if jugador.Character and not GuiService.ReducedMotionEnabled then
			table.insert(ocultar, jugador.Character)
		end
		for _, modelo in ocultar do
			for _, pieza in modelo:GetDescendants() do
				if pieza:IsA("BasePart") then
					partesOcultas[pieza] = pieza.LocalTransparencyModifier
					pieza.LocalTransparencyModifier = 1
				end
			end
		end
	end
	jugador:SetAttribute("FareroConversando", true)
	local camara = workspace.CurrentCamera
	if camara and not tomaFarero and camara.CameraType == Enum.CameraType.Custom and not GuiService.ReducedMotionEnabled then
		local cabeza = rostroFarero.Position
		local raiz = jugador.Character and jugador.Character:FindFirstChild("HumanoidRootPart")
		local lado = if raiz and raiz.Position.X > cabeza.X then -1 else 1
		local mira = cabeza - Vector3.yAxis * 0.85
		tomaFarero = { camara = camara, marco = camara.CFrame, foco = camara.Focus, fov = camara.FieldOfView }
		local plano = CFrame.lookAt(cabeza + Vector3.new(lado * 2.1, 0.55, 6.6), mira)
		camara.CameraType = Enum.CameraType.Scriptable
		RunService:BindToRenderStep(CAMARA_FARERO, Enum.RenderPriority.Camera.Value + 1, function()
			camara.CFrame = plano
			camara.Focus = CFrame.new(mira)
			camara.FieldOfView = 57
		end)
	end
end

local function recuperarVista()
	if avisoHabilitado ~= nil then
		if avisoFarero.Parent then avisoFarero.Enabled = avisoHabilitado end
		avisoHabilitado, avisoFarero = nil, nil
		for pieza, opacidad in pairs(partesOcultas) do
			if pieza.Parent then
				pieza.LocalTransparencyModifier = opacidad
			end
		end
		table.clear(partesOcultas)
		jugador:SetAttribute("FareroConversando", false)
	end
	if tomaFarero then
		RunService:UnbindFromRenderStep(CAMARA_FARERO)
		local camara = tomaFarero.camara
		if camara == workspace.CurrentCamera and camara.CameraType == Enum.CameraType.Scriptable then
			camara.CFrame = tomaFarero.marco
			camara.Focus = tomaFarero.foco
			camara.FieldOfView = tomaFarero.fov
			camara.CameraType = Enum.CameraType.Custom
		end
		tomaFarero = nil
	end
end

local function abrir(destino, conFarero)
	if ocupado() then
		return
	end
	if not menu.Visible then
		seleccionAnterior = GuiService.SelectedObject
	end
	if conFarero then
		dialogoAutorizado = true
	end
	if destino == "Inventario" then
		dialogoAutorizado = false
		recuperarVista()
	end
	respuestaFarero = nil
	enAlcance = cercaDelFarero()
	pantalla = destino
	menu.Visible = true
	jugador:SetAttribute("BitacoraAbierta", true)
	progreso.Visible = false
	aviso.Visible = false
	if conFarero then
		enfocarAlFarero()
	end
	actualizarPanel()
	local mando = dispositivo()
	if mando then
		GuiService.SelectedObject = if destino == "Dialogo" then temaFaro
			elseif destino == "Mejoras" then volverDeTienda
			elseif destino == "SenalFaro" and seguirSenal.Active then seguirSenal
			elseif destino == "SenalFaro" then volverDeSenal elseif viendoPlaneadores then verPlaneadores else verEcos
	end
end

local function cerrarPanel()
	if not menu.Visible then
		return
	end
	menu.Visible = false
	jugador:SetAttribute("BitacoraAbierta", false)

	recuperarVista()
	dialogoAutorizado = false
	local seleccionado = GuiService.SelectedObject
	if not seleccionado or seleccionado:IsDescendantOf(panel) or seleccionado:IsDescendantOf(dialogo) then
		GuiService.SelectedObject = if seleccionAnterior and seleccionAnterior.Parent then seleccionAnterior else nil
	end
	seleccionAnterior = nil
end

local function alternar()
	if menu.Visible and pantalla == "Inventario" then
		cerrarPanel()
	else
		abrir("Inventario")
	end
end

local function adaptar()
	local ancho = menu.AbsoluteSize.X
	cabecera.adaptar(ancho)
	local anchoEquipo = equipo.AbsoluteSize.X - 11
	local columnasEquipo = if anchoEquipo >= 430 then 2 else 1
	gridEquipo.FillDirectionMaxCells = columnasEquipo
	gridEquipo.CellSize = UDim2.fromOffset(math.max(0, math.floor((anchoEquipo - (columnasEquipo - 1) * 12) / columnasEquipo)), 250)
	local anchoTienda = tienda.AbsoluteSize.X - 11
	local ladoALado = anchoTienda >= 575
	contenido.Size = UDim2.new(1, -11, 0, if ladoALado then 216 else 443)
	for i, mejora in ipairs(mejoras) do
		mejora.tarjeta.Position = if ladoALado then UDim2.new((i - 1) * 0.5, (i - 1) * 6, 0, 0)
			else UDim2.fromOffset(0, (i - 1) * 225)
		mejora.tarjeta.Size = if ladoALado then UDim2.new(0.5, -6, 0, 213) else UDim2.new(1, 0, 0, 213)
	end
	local estrecho = ancho < 445
	palabrasFarero.TextSize = if estrecho then 13 else 14
	palabrasFarero.Size = UDim2.new(1, -34, 0, if estrecho then 72 else 52)
	tienda.Position = UDim2.fromOffset(13, if estrecho then 149 else 129)
	tienda.Size = UDim2.new(1, -26, 1, if estrecho then -161 else -141)
	local apilado = ancho < 550
	local alto = if apilado then 216 else 152
	dialogo.Size = UDim2.new(1, -24, 0, alto)
	fraseFarero.Size = if apilado then UDim2.new(1, -32, 0, 71) else UDim2.new(0.54, -29, 1, -64)
	fraseFarero.TextSize = if apilado then 14 else 16
	local respuestas = temaMejoras.Parent
	respuestas.Position = if apilado then UDim2.new(0, 15, 1, -98) else UDim2.new(0.54, 0, 0, 52)
	respuestas.Size = if apilado then UDim2.new(1, -30, 0, 88) else UDim2.new(0.46, -15, 1, -64)
end

local function usarEscudo()
	if ocupado() or menu.Visible or not jugador:GetAttribute("EnEncargoPedernal") then
		return false
	end
	local tiempo = workspace:GetServerTimeNow()
	if tiempo >= (jugador:GetAttribute("EscudoRefugioListoEn") or 0) and os.clock() >= proximoEscudo then
		proximoEscudo = os.clock() + 0.2
		remoto:FireServer("Escudo")
	end
	return true
end

require(ReplicatedStorage:WaitForChild("ControlesCombate")).escudoBreve(function()
	return jugador:GetAttribute("EnEncargoPedernal") == true and not menu.Visible and not ocupado()
end, usarEscudo)

local function pedir(accion)
	if solicitud then
		return
	end
	solicitud = accion
	numeroSolicitud += 1
	hastaSolicitud = os.clock() + 4
	respuestaFarero = nil
	actualizarPanel()
	remoto:FireServer(accion, numeroSolicitud)
end

cabecera.boton.Activated:Connect(alternar)
cabecera.abrirFicha.Activated:Connect(function()
	if ocupado() then return end
	viendoPlaneadores = false
	album.mostrar(3)
	abrir("Inventario")
	toastHasta = 0
	aviso.Visible = false
end)
fondo.Activated:Connect(cerrarPanel)
cerrar.Activated:Connect(cerrarPanel)
despedir.Activated:Connect(cerrarPanel)
verEcos.Activated:Connect(function()
	viendoPlaneadores = false
	actualizarPanel()
end)
verPlaneadores.Activated:Connect(function()
	viendoPlaneadores = true
	actualizarPanel()
end)
temaFaro.Activated:Connect(function() abrir("SenalFaro") end)
temaMejoras.Activated:Connect(function() abrir("Mejoras") end)
volverDeSenal.Activated:Connect(function() abrir("Dialogo") end)
volverDeTienda.Activated:Connect(function() abrir("Dialogo") end)
seguirSenal.Activated:Connect(function()
	if seguirSenal.Active then
		pedir("PrepararFaro")
	end
end)
for _, ficha in ipairs(fichasPlaneadores) do
	ficha.elegir.Activated:Connect(function()
		if ficha.elegir.Active then
			pedir(ficha.accion)
		end
	end)
end
for _, mejora in ipairs(mejoras) do
	mejora.boton.Activated:Connect(function()
		if mejora.boton.Active then
			if mejora.compra == "ComprarPlaneador" and jugador:GetAttribute("PlaneadorAvanzado") then
				pedir("EquiparAvanzado")
			else
				pedir(mejora.compra)
			end
		end
	end)
end

ContextActionService:BindActionAtPriority("AbrirInventarioEcos", function(_, estado, entrada)
	if ocupado() or UserInputService:GetFocusedTextBox()
		or (entrada.KeyCode == Enum.KeyCode.DPadUp and menu.Visible) then
		return Enum.ContextActionResult.Pass
	end
	if estado == Enum.UserInputState.Begin then
		alternar()
	end
	return Enum.ContextActionResult.Sink
end, false, ALTA, Enum.KeyCode.DPadUp)

ContextActionService:BindActionAtPriority("CerrarInventarioEcos", function(_, estado)
	if not menu.Visible then
		return Enum.ContextActionResult.Pass
	end
	if estado == Enum.UserInputState.Begin then
		cerrarPanel()
	end
	return Enum.ContextActionResult.Sink
end, false, ALTA, Enum.KeyCode.Backspace, Enum.KeyCode.ButtonB)

ContextActionService:BindActionAtPriority("EscudoDelRefugio", function(_, estado)
	if estado == Enum.UserInputState.Begin and usarEscudo() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, ALTA, Enum.KeyCode.ButtonR1)

ContextActionService:BindActionAtPriority("InteraccionesInventarioEcos", function()
	return if menu.Visible then Enum.ContextActionResult.Sink else Enum.ContextActionResult.Pass
end, false, ALTA, Enum.KeyCode.E, Enum.KeyCode.Q, Enum.KeyCode.C, Enum.KeyCode.F,
	Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonR1)

jugador:GetAttributeChangedSignal("FichaRescateLucero"):Connect(function()
	if fichaLuceroVista then return end
	fichaLuceroVista = true
	fichaLuceroPendiente = true
end)

remoto.OnClientEvent:Connect(function(evento, ok, codigo, accion, numero)
	if numero and numero ~= numeroSolicitud then
		return
	end
	if evento == "AbrirTienda" then
		abrir("Dialogo", true)
	elseif evento == "ResultadoCompra" or evento == "ResultadoPlaneador" then
		local planeador = evento == "ResultadoPlaneador"
		local esperada = if planeador then "ComprarPlaneador" else "ComprarPedernal"
		if solicitud == esperada then
			solicitud, hastaSolicitud = nil, 0
		end
		local respuesta
		if ok then
			respuesta = if planeador
				then "Ya es tuyo. Pulsa Equipar cuando quieras probar el planeador avanzado."
				else "¡Listo! El escudo de Pedernal se recupera más rápido. Ahora ve al relevo y enciende los dos faroles."
		elseif codigo == "YaComprada" then
			respuesta = if planeador then "Ya tienes ese planeador. Puedes elegirlo en tu inventario."
				else "Pedernal ya tiene equipado Escudo rápido. Pruébalo en el relevo de los faroles."
		else
			respuesta = mensajes[codigo] or "No pude registrar la compra. Inténtalo otra vez."
		end
		if menu.Visible and pantalla == "Mejoras" then
			respuestaFarero = respuesta
			actualizarPanel()
		end
	elseif evento == "ResultadoEquipo" then
		if solicitud == accion then
			solicitud, hastaSolicitud = nil, 0
		end
		if menu.Visible and (pantalla == "Inventario" or pantalla == "Mejoras") then
			if ok then
				respuestaFarero = if pantalla == "Mejoras" then "Ya está equipado. Lo desplegarás en tu próximo vuelo." else nil
			else
				respuestaFarero = mensajes[codigo] or "No pude cambiar el planeador. Inténtalo de nuevo."
			end
			actualizarPanel()
		end
	elseif evento == "SalidaAlFaro" then
		if solicitud == "PrepararFaro" then
			solicitud, hastaSolicitud = nil, 0
		end
		if ok then
			if pantalla ~= "Inventario" then
				cerrarPanel()
			end
		else
			respuestaFarero = mensajes[codigo] or "Todavía no puedo indicarte la salida."
			if menu.Visible and pantalla == "SenalFaro" then
				actualizarPanel()
			end
		end
	elseif evento == "EncargoCompleto" then
		premioEncargo = true
		mostrarPremioEn = os.clock() + 0.45
	end
end)

local function leerPremio()
	local exp = jugador:GetAttribute("Experiencia") or 0
	local dinero = jugador:GetAttribute("Monedas") or 0
	if jugador:GetAttribute("ProgresoListo") then
		local diferenciaXP = math.max(0, exp - xpPrevio)
		local diferenciaMonedas = math.max(0, dinero - saldoPrevio)
		sumarXP += diferenciaXP
		sumarMonedas += diferenciaMonedas
		if diferenciaXP > 0 or diferenciaMonedas > 0 then
			mostrarPremioEn = os.clock() + 0.45
		end
	end
	xpPrevio, saldoPrevio = exp, dinero
end

local function actualizarEncargo(ahora)
	local mando = dispositivo()
	local estado = jugador:GetAttribute("EstadoEncargo")
	local fin = jugador:GetAttribute("EncargoHasta") or 0
	local restante = math.max(0, fin - ahora)
	local escudado = (jugador:GetAttribute("EscudoRefugioHasta") or 0) > ahora
	local recarga = math.max(0, (jugador:GetAttribute("EscudoRefugioListoEn") or 0) - ahora)
	local titulo, instruccion, detalle, fraccion
	if estado == "Segundo" then
		if finAnterior ~= fin then
			finAnterior, tiempoTotal = fin, math.max(restante, 1)
		end
		titulo, instruccion = "Segundo farol", "Lleva la chispa al otro farol y protege su llama."
		detalle, fraccion = ("%.0f s para llegar"):format(math.ceil(restante)), restante / tiempoTotal
	elseif estado == "Meta" or estado == "Final" then
		titulo, instruccion = "Faroles encendidos", "Entrega el encargo en la baliza."
	elseif estado == "Reintentar" then
		titulo, instruccion = "Recupera la chispa", "El primer farol sigue encendido. Protege la llama del segundo."
	else
		titulo, instruccion = "Relevo de los faroles", "Llega al primer farol y usa el escudo cuando se incline la llama."
	end
	encargo:actualizar("Faro", titulo, instruccion, detalle, fraccion)
	local acciones = {}
	if estado ~= "Meta" and estado ~= "Final" then
		acciones[1] = {icono = "Escudo", texto = if escudado then "Protegido" elseif recarga > 0 then ("%.1f s"):format(recarga) else "Escudo",
			tecla = if mando then "R1" else "M2", activar = if recarga <= 0 then usarEscudo else nil,
			progreso = if recarga > 0 then 1 - math.clamp(recarga/2.65,0,1) else nil}
	end
	accionesEncargo:actualizar(acciones)
end

for _, nombre in ipairs({ "Experiencia", "Monedas" }) do
	jugador:GetAttributeChangedSignal(nombre):Connect(leerPremio)
end
jugador:GetAttributeChangedSignal("Lucero"):Connect(function()
	local tiene = jugador:GetAttribute("Lucero") == true
	if tiene and not luceroAntes and jugador:GetAttribute("ProgresoListo") and jugador:GetAttribute("EnMolino") then
		descuentoXP, descuentoMonedas = 70, 50
	end
	luceroAntes = tiene
end)
jugador:GetAttributeChangedSignal("ProgresoListo"):Connect(function()
	luceroAntes = jugador:GetAttribute("Lucero") == true
	xpPrevio = jugador:GetAttribute("Experiencia") or 0
	saldoPrevio = jugador:GetAttribute("Monedas") or 0
	nivelMostrado = jugador:GetAttribute("Nivel") or 1
end)

for _, nombre in ipairs({ "Nivel", "XpNivel", "XpMeta", "Monedas", "Cometa", "Vendaval", "Pedernal", "Rebote",
	"Lucero", "Prisma", "Nimbo", "NimboAurora", "LenteGeoda", "MejoraPedernal", "EncargoPedernal", "PlaneadorAvanzado",
	"PlaneadorEquipado", "ProgresoListo" }) do
	jugador:GetAttributeChangedSignal(nombre):Connect(function()
		if menu.Visible then
			actualizarPanel()
		else
			dibujarProgreso()
		end
	end)
end
menu:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptar)
inventario:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptar)
equipo:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptar)
tienda:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptar)
UserInputService.LastInputTypeChanged:Connect(dibujarProgreso)
UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(dibujarProgreso)
jugador.CharacterRemoving:Connect(cerrarPanel)
adaptar()
actualizarPanel()

local refresco = 0
RunService.Heartbeat:Connect(function(dt)
	refresco += dt
	if refresco < 0.09 then
		return
	end
	refresco = 0

	local ahora = os.clock()
	local presenta = ocupado()
	local enEncargo = jugador:GetAttribute("EnEncargoPedernal") == true
	local humanoide = jugador.Character and jugador.Character:FindFirstChildOfClass("Humanoid")
	local vivo = humanoide ~= nil and humanoide.Health > 0
	if presenta or not vivo then
		cerrarPanel()
	end
	progreso.Visible = not presenta and not menu.Visible and vivo
	local presentaEncargo = enEncargo and progreso.Visible
	encargo:visible(presentaEncargo)
	accionesEncargo:visible(presentaEncargo)
	if presentaEncargo then actualizarEncargo(workspace:GetServerTimeNow()) end
	if solicitud and ahora >= hastaSolicitud then
		solicitud, hastaSolicitud = nil, 0
		if menu.Visible then
			actualizarPanel()
		end
	end
	if menu.Visible and pantalla ~= "Inventario" and dialogoAutorizado then
		local cerca = cercaDelFarero()
		if not cerca then
			cerrarPanel()
		elseif cerca ~= enAlcance then
			enAlcance = cerca
			actualizarPanel()
		end
	end
	if mostrarPremioEn and ahora >= mostrarPremioEn then
		local actual = jugador:GetAttribute("Nivel") or 1
		-- La ficha del despertar ya incluye sus monedas y EXP. Conserva cualquier otro premio simultáneo.
		local incluidoXP = math.min(sumarXP, descuentoXP)
		local incluidoMonedas = math.min(sumarMonedas, descuentoMonedas)
		sumarXP, sumarMonedas = sumarXP - incluidoXP, sumarMonedas - incluidoMonedas
		descuentoXP, descuentoMonedas = descuentoXP - incluidoXP, descuentoMonedas - incluidoMonedas
		local importes = {}
		if sumarMonedas > 0 then table.insert(importes, ("+%d monedas"):format(sumarMonedas)) end
		if sumarXP > 0 then table.insert(importes, ("+%d EXP"):format(sumarXP)) end
		if #importes > 0 or premioEncargo then
			local subio = actual > nivelMostrado
			table.insert(noticias, {icono = if premioEncargo then "Faro" elseif subio then "Estrella" else "Moneda",
				clase = if premioEncargo then "RELEVO DE LOS FAROLES" elseif subio then "RANGO DE EXPLORACIÓN" else "EXPEDICIÓN",
				titulo = if premioEncargo then "Encargo completado" elseif subio then ("Nivel %d"):format(actual) else "Recompensa recibida",
				detalle = if #importes > 0 then table.concat(importes, "  ·  ") else "Los dos faroles están encendidos."})
		end
		premioEncargo, mostrarPremioEn, nivelMostrado = false, nil, actual
		sumarXP, sumarMonedas = 0, 0
	end
	if progreso.Visible and fichaLuceroPendiente then
		fichaLuceroPendiente = false
		cabecera.notificar({clase = "RESCATADO  ·  VER ECODEX  ›", icono = "Chispa", titulo = "Lucero",
			detalle = "+50 monedas  ·  +70 EXP", eco = true})
		toastHasta = ahora + 7
	elseif progreso.Visible and #noticias > 0 and ahora >= toastHasta then
		cabecera.notificar(table.remove(noticias, 1))
		toastHasta = ahora + 4
	end
	aviso.Visible = progreso.Visible and ahora < toastHasta
end)
