local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local Ecodex = require(ReplicatedStorage:WaitForChild("Ecodex"))
local Cabecera = {}

local tinta = Color3.fromRGB(17, 39, 53)
local tintaClara = Color3.fromRGB(38, 64, 74)
local papel = Color3.fromRGB(242, 235, 218)
local oro = Color3.fromRGB(233, 185, 111)
local menta = Color3.fromRGB(142, 225, 201)
local gris = Color3.fromRGB(179, 198, 199)

local function crear(tipo, padre, props)
	local o = Instance.new(tipo)
	for k, v in props do o[k] = v end
	o.Parent = padre
	return o
end

local function pieza(padre, nombre, pos, tam, tono)
	return crear("Frame", padre, {Name = nombre, Position = pos, Size = tam, BorderSizePixel = 0, BackgroundColor3 = tono})
end

local function redondear(objeto, radio)
	crear("UICorner", objeto, {CornerRadius = UDim.new(0, radio)})
end

local function borde(objeto, color, opacidad)
	crear("UIStroke", objeto, {ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = color,
		Thickness = 1, Transparency = opacidad})
end

local function texto(padre, nombre, pos, tam, tono, fuente, medida)
	return crear("TextLabel", padre, {Name = nombre, Position = pos, Size = tam, BackgroundTransparency = 1,
		Font = fuente, TextSize = medida, TextColor3 = tono, Text = "", TextXAlignment = Enum.TextXAlignment.Left})
end

local function centro(padre, nombre, tono, fuente, medida)
	local t = texto(padre, nombre, UDim2.fromOffset(0,0), UDim2.fromScale(1,1), tono, fuente, medida)
	t.TextXAlignment = Enum.TextXAlignment.Center
	return t
end

function Cabecera.crear(gui, jugador)
	local pos = UDim2.fromOffset
	local grupo = pieza(gui, "Progreso", UDim2.new(1,-12,0,9), pos(240,52), tinta)
	grupo.AnchorPoint, grupo.BackgroundTransparency, grupo.Visible = Vector2.new(1,0), 1, false
	local cuerpo = pieza(grupo, "Instrumento", pos(0,2), pos(185,48), tinta)
	redondear(cuerpo, 8)
	borde(cuerpo, gris, .66)
	crear("UIGradient", cuerpo, {Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(194,218,227)), Rotation = 85})
	local escala = crear("UIScale", cuerpo, {Scale = 1})

	local montura = pieza(cuerpo, "Insignia", pos(8,7), pos(34,34), oro)
	redondear(montura, 17)
	local esfera = pieza(montura, "Esmalte", pos(2,2), pos(30,30), tinta)
	redondear(esfera, 15)
	for i = 0, 3 do
		local a = i * math.pi / 2
		local m = pieza(montura, "Marca", pos(16 + math.floor(math.sin(a)*14),16 + math.floor(math.cos(a)*14)),pos(2,3),oro)
		m.Rotation = i*90
	end
	local nivel = centro(esfera, "Nivel", papel, Enum.Font.GothamBold, 17)
	local rango = texto(cuerpo,"NombreRango",pos(49,3),pos(66,17),menta,Enum.Font.GothamBold,10)
	rango.Text = "NIVEL"
	local xp = texto(cuerpo,"XP",pos(49,18),pos(78,17),papel,Enum.Font.GothamMedium,12)
	local carril = pieza(cuerpo,"Avance",pos(49,38),pos(74,3),tintaClara)
	redondear(carril, 2)
	local avance = pieza(carril,"Experiencia",pos(0,0),UDim2.fromScale(0,1),menta)
	redondear(avance, 2)
	pieza(cuerpo,"Division",pos(130,10),pos(1,28),tintaClara)
	UI.icono(cuerpo,"Moneda",17,oro,pos(137,6))
	local saldo = texto(cuerpo,"Monedas",pos(136,23),pos(46,20),papel,Enum.Font.GothamBold,14)
	local bolsa = crear("TextButton", grupo, {Name = "Mochila", Position = UDim2.new(1,-46,0,2),
		Size = pos(46,46), BorderSizePixel = 0, BackgroundColor3 = tinta, Text = "", Selectable = true})
	redondear(bolsa, 11)
	borde(bolsa, oro, .24)
	UI.icono(bolsa, "Mochila", 27, papel, pos(10,8))
	local mando = texto(bolsa, "Mando", UDim2.new(1,-12,1,-14), pos(12,13), menta, Enum.Font.GothamBold, 12)
	mando.Text, mando.Visible = "↑", false

	local aviso = pieza(gui, "Aviso", UDim2.new(1,-12,0,68), pos(258,80), papel)
	aviso.AnchorPoint = Vector2.new(1,0)
	aviso.Visible = false
	redondear(aviso, 7)
	borde(aviso, tinta, .32)
	local vineta = pieza(aviso,"Sello",pos(7,7),pos(52,66),tinta)
	redondear(vineta, 5)
	crear("UIGradient", vineta, {Color = ColorSequence.new(Color3.fromRGB(198,212,217), Color3.new(1,1,1)), Rotation = -60})
	local simbolos = {}
	for _, id in {"Moneda", "Estrella", "Faro", "Chispa"} do
		local s = UI.icono(vineta,id,29,oro,UDim2.fromScale(.5,.5))
		s.AnchorPoint, s.Visible = Vector2.new(.5,.5), false
		simbolos[id] = s
	end
	local retrato = crear("ViewportFrame", vineta, {Name = "RetratoLucero", Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1, Ambient = Color3.fromRGB(160,184,192),
		LightColor = papel, LightDirection = Vector3.new(.45,-1,-.5), Visible = false})
	local tipo = texto(aviso,"Clase",pos(69,8),UDim2.new(1,-79,0,14),tintaClara,Enum.Font.GothamBold,10)
	local titulo = texto(aviso,"Titulo",pos(68,23),UDim2.new(1,-75,0,26),tinta,Enum.Font.Bodoni,21)
	local detalle = texto(aviso,"Detalle",pos(69,51),UDim2.new(1,-77,0,18),tinta,Enum.Font.GothamMedium,12)
	local abrirFicha = crear("TextButton", aviso, {Name = "AbrirFicha", Size = UDim2.fromScale(1,1),
		BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", Selectable = true, Visible = false})
	local destinoAviso = aviso.Position
	local efecto, animacion
	local ultimoAvance

	local function adaptar(ancho)
		local estrecho = ancho < 620
		escala.Scale = if estrecho then .86 else 1
		grupo.Size = pos(if estrecho then 211 else 240, 52)
		grupo.Position = UDim2.new(1,if estrecho then -9 else -13,0,if estrecho then 88 else 9)
		destinoAviso = UDim2.new(1,if estrecho then -9 else -13,0,if estrecho then 141 else 69)
		if efecto then efecto:Cancel() end
		aviso.Position = destinoAviso
	end
	local function actualizar(conMando)
		local listo = jugador:GetAttribute("ProgresoListo") == true
		local exp = jugador:GetAttribute("XpNivel") or 0
		local meta = math.max(1,jugador:GetAttribute("XpMeta") or 100)
		local fraccion = if listo then math.clamp(exp/meta,0,1) else 0
		nivel.Text = if listo then tostring(jugador:GetAttribute("Nivel") or 1) else "…"
		saldo.Text = if listo then tostring(jugador:GetAttribute("Monedas") or 0) else "…"
		xp.Text = if listo then ("%d/%d XP"):format(exp,meta) else ""
		mando.Visible = conMando
		if fraccion ~= ultimoAvance then
			if animacion then animacion:Cancel() end
			local destino = UDim2.fromScale(fraccion,1)
			if ultimoAvance ~= nil and grupo.Visible and not GuiService.ReducedMotionEnabled then
				if fraccion < ultimoAvance then avance.Size = UDim2.fromScale(0,1) end
				animacion = TweenService:Create(avance,TweenInfo.new(.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size = destino})
				animacion:Play()
			else
				avance.Size = destino
			end
			ultimoAvance = fraccion
		end
	end
	local function notificar(noticia)
		if efecto then efecto:Cancel() end
		for id, s in simbolos do s.Visible = id == noticia.icono end
		tipo.Text, titulo.Text, detalle.Text = noticia.clase, noticia.titulo, noticia.detalle
		abrirFicha.Visible = noticia.eco == true
		retrato.Visible = false
		if noticia.eco then
			if not retrato.CurrentCamera then Ecodex.retratoLucero(retrato,jugador) end
			retrato.Visible = retrato.CurrentCamera ~= nil
			simbolos.Chispa.Visible = not retrato.Visible
		end
		aviso.Visible = true
		aviso.Position = destinoAviso
		if not GuiService.ReducedMotionEnabled then
			aviso.Position += pos(14,0)
			efecto = TweenService:Create(aviso,TweenInfo.new(.23,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position = destinoAviso})
			efecto:Play()
		end
	end
	return {progreso = grupo, boton = bolsa, aviso = aviso, abrirFicha = abrirFicha,
		actualizar = actualizar, adaptar = adaptar, notificar = notificar}
end

return Cabecera
