-- Una sola página viva por jugador. El álbum lee los descubrimientos del perfil.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(ReplicatedStorage:WaitForChild("BitacoraUI"))
local Ecodex = {}

local tinta = Color3.fromRGB(17, 39, 53)
local papel = Color3.fromRGB(242, 235, 218)
local lapiz = Color3.fromRGB(68, 81, 83)
local trazo = Color3.fromRGB(162, 158, 134)
local oro = Color3.fromRGB(233, 185, 111)

local ecos = {
	{ nombre = "Cometa", isla = "Isla del Viento", zona = "Viento", icono = "Viento",
		tono = Color3.fromRGB(146, 215, 194), pista = "Defiende el nido de los vigías y acércate al Eco que protegiste.",
		poder = "Despliega las alas cuando saltas. Puedes planear y plegarlas en pleno vuelo.",
		forma = "Vendaval", variante = "Vendaval", secreto = "Busca el aro del viento y atraviésalo planeando.",
		mejora = "Las corrientes de aire ahora te elevan." },
	{ nombre = "Pedernal", isla = "Cueva de la Geoda", zona = "Geoda", icono = "Geoda",
		tono = Color3.fromRGB(194, 161, 244), pista = "Cruza el portal violeta junto al Farero y enfréntate al Guardián de la Geoda.",
		poder = "Invoca su escudo para protegerte de las ráfagas.",
		forma = "Rebote", variante = "Rebote", secreto = "Guía una embestida hacia el cristal alto antes de abrir el tesoro.",
		mejora = "Su escudo devuelve los disparos de viento." },
	{ nombre = "Lucero", isla = "Molino del Viento", zona = "Molino", icono = "Molino",
		tono = Color3.fromRGB(240, 199, 125), pista = "Lleva la chispa al farol del molino. Pedernal puede protegerla del viento.",
		poder = "Su luz revela las marcas antiguas en las ruinas del faro.",
		forma = "Prisma", variante = "Prisma", secreto = "Prueba la lente de la Geoda en el espejo de las ruinas del faro.",
		mejora = "Su luz se divide y revela el camino a la torre." },
	{ nombre = "Nimbo", isla = "Nido de tormenta", zona = "Tormenta", icono = "Nimbo",
		tono = Color3.fromRGB(153, 206, 233), pista = "Desde el balcón de la torre, planea hasta el nido y abre el cascarón.",
		poder = "Vuela a tu lado al explorar el archipiélago.",
		forma = "NimboAurora", variante = "Aurora", secreto = "Un vuelo por los tres aros puede despertar algo distinto en el cascarón.",
		mejora = "Sus alas tornasoladas dejan una estela de luz." },
}

local function dibujar(clase, padre, props)
	local objeto = Instance.new(clase)
	for clave, valor in props do objeto[clave] = valor end
	objeto.Parent = padre
	return objeto
end

local function marco(padre, nombre, medida, tono)
	return dibujar("Frame", padre, {Name = nombre, Size = medida, BorderSizePixel = 0, BackgroundColor3 = tono})
end

local function texto(padre, nombre, fuente, tamano, tono)
	return dibujar("TextLabel", padre, {Name = nombre, Font = fuente, TextSize = tamano,
		TextColor3 = tono, Text = "", TextWrapped = true, BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center})
end

local function caja(objeto, x, y, ancho, alto)
	objeto.Position = UDim2.fromOffset(x, y)
	objeto.Size = UDim2.fromOffset(ancho, alto)
end

local function obtenerModelo(jugador, nombre)
	if nombre == "Nimbo" then
		local modelos = ReplicatedStorage:FindFirstChild("EcosDelFaro")
		return modelos and modelos:FindFirstChild(if jugador:GetAttribute("NimboAurora") then "NimboAurora" else "Nimbo")
	elseif nombre == "Pedernal" then
		return ReplicatedStorage:FindFirstChild("PedernalCompanero")
	elseif nombre == "Lucero" then
		return ReplicatedStorage:FindFirstChild("LuceroCompanero")
	end
	local isla = workspace:FindFirstChild("IslaDelViento")
	local grupo = isla and isla:FindFirstChild("CompanerosCometa")
	local nido = isla and isla:FindFirstChild("Nido")
	return (grupo and grupo:FindFirstChild(tostring(jugador.UserId))) or (nido and nido:FindFirstChild("Cometa"))
end

local function ilustrar(visor, original, descubierto)
	local copia = original:Clone()
	if not copia then return false end
	for _, pieza in copia:GetDescendants() do
		if pieza:IsA("BasePart") then
			pieza.Anchored = true
			pieza.LocalTransparencyModifier = 0
			-- El Eco del nido se oculta cuando ya hay otro guardián en la isla.
			if original.Name == "Cometa" and pieza.Transparency == 1 then pieza.Transparency = 0 end
			if not descubierto then
				pieza.Color = tinta
				pieza.Material = Enum.Material.SmoothPlastic
				pieza.Reflectance = 0
				if pieza:IsA("MeshPart") then pieza.TextureID = "" end
			end
		elseif pieza:IsA("LuaSourceContainer") or pieza:IsA("LayerCollector") or pieza:IsA("ProximityPrompt")
			or pieza:IsA("Light") or pieza:IsA("ParticleEmitter") or pieza:IsA("Trail") or pieza:IsA("Beam")
			or (not descubierto and (pieza:IsA("Decal") or pieza:IsA("SurfaceAppearance"))) then
			pieza:Destroy()
		elseif not descubierto and pieza:IsA("SpecialMesh") then
			pieza.TextureId = ""
		end
	end
	local mundo = dibujar("WorldModel", visor, {Name = "Ilustracion"})
	copia.Parent = mundo
	copia:PivotTo(CFrame.new())
	local cf, tam = copia:GetBoundingBox()
	local radio = math.max(1, tam.Magnitude * .5)
	local aspecto = visor.AbsoluteSize.X / math.max(visor.AbsoluteSize.Y, 1)
	local distancia = radio / math.sin(math.rad(17)) / math.min(1, math.max(.5, aspecto))
	local ojo = cf.Position + Vector3.new(-.53, .29, -.8).Unit * distancia
	visor.CurrentCamera = dibujar("Camera", visor, {FieldOfView = 34, CFrame = CFrame.lookAt(ojo, cf.Position)})
	return true
end

-- La ficha del rescate y la página del álbum utilizan el mismo retrato.
function Ecodex.retratoLucero(visor, jugador)
	local original = obtenerModelo(jugador, "Lucero")
	return original ~= nil and ilustrar(visor, original, true)
end

function Ecodex.crear(area, jugador)
	local seleccion = 1
	local pagina = marco(area, "Pagina", UDim2.fromOffset(0, 0), papel)
	dibujar("UICorner", pagina, {CornerRadius = UDim.new(0, 7)})
	local navegacion = marco(pagina, "Islas", UDim2.fromOffset(0, 0), tinta)
	local botones = {}
	local insignias = {}
	for i, eco in ecos do
		local b = dibujar("TextButton", navegacion, {Name = eco.nombre, Size = UDim2.new(.25, -2, 1, 0),
			Position = UDim2.new((i-1)*.25, 1, 0, 0), BorderSizePixel = 0, Text = eco.zona,
			TextSize = 13, Font = Enum.Font.GothamBold, TextColor3 = papel, Selectable = true})
		botones[i] = b
		local insignia = marco(b, "Insignia", UDim2.fromOffset(25,25), tinta)
		insignia.Position = UDim2.new(0,6,.5,-12)
		dibujar("UICorner", insignia, {CornerRadius = UDim.new(.5,0)})
		UI.icono(insignia, eco.icono, 17, eco.tono, UDim2.fromOffset(4,4))
		insignias[i] = insignia
	end
	local mapa = marco(pagina, "Lamina", UDim2.fromOffset(0, 0), papel)
	mapa.ClipsDescendants = true
	local gradiente = dibujar("UIGradient", mapa, {Rotation = -65})
	for _, medida in {75, 121, 169} do
		local circulo = marco(mapa, "RosaDeLosVientos", UDim2.fromOffset(medida, medida), tinta)
		circulo.AnchorPoint = Vector2.new(.5, .5)
		circulo.Position = UDim2.fromScale(.5, .5)
		circulo.BackgroundTransparency = 1
		dibujar("UICorner", circulo, {CornerRadius = UDim.new(.5, 0)})
		dibujar("UIStroke", circulo, {Thickness = 1, Transparency = .73, Color = tinta})
	end
	local visor = dibujar("ViewportFrame", mapa, {Name = "Retrato", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		Ambient = Color3.fromRGB(181, 194, 201), LightColor = Color3.fromRGB(255, 245, 224),
		LightDirection = Vector3.new(.45, -1, -.5)})
	local sello = UI.icono(mapa, "Eco", 46, tinta)
	sello.AnchorPoint = Vector2.new(.5, .5)
	sello.Position = UDim2.fromScale(.5, .5)
	local origen = texto(pagina, "Isla", Enum.Font.GothamBold, 12, lapiz)
	local nombre = texto(pagina, "Nombre", Enum.Font.Bodoni, 29, tinta)
	local habilidad = texto(pagina, "Descubrimiento", Enum.Font.GothamMedium, 14, tinta)
	local regla = marco(pagina, "Separador", UDim2.fromOffset(0, 1), trazo)
	local variante = texto(pagina, "Variante", Enum.Font.GothamBold, 13, tinta)
	local pista = texto(pagina, "Pista", Enum.Font.GothamMedium, 13, lapiz)
	local reliquia = texto(pagina, "LenteGeoda", Enum.Font.GothamBold, 12, lapiz)
	local actual, vista, ultimaMutacion, ilustrada

	local function adaptar()
		local ancho = math.max(200, area.AbsoluteSize.X - 14)
		local horizontal = ancho >= 510
		local apaisado = horizontal and area.AbsoluteSize.Y < 285
		local margen = if horizontal then 20 else 14
		local anchoMapa = if horizontal then math.floor(ancho * .43) else ancho - margen * 2
		local altoMapa = if apaisado then math.clamp(area.AbsoluteSize.Y - 63, 85, 216) elseif horizontal then 216 else 119
		local x = if horizontal then margen + anchoMapa + 20 else margen
		local y = if horizontal then 62 else 57 + altoMapa + 9
		local textoAncho = ancho - x - margen
		local altoPagina = math.max(64 + altoMapa, y + 239 + (if reliquia.Visible then 24 else 0))
		pagina.Size = UDim2.fromOffset(ancho, altoPagina)
		caja(navegacion, 0, 0, ancho, 44)
		for _, insignia in insignias do insignia.Visible = ancho >= 580 end
		caja(mapa, margen, 57, anchoMapa, altoMapa)
		if apaisado then
			caja(origen, x, 51, textoAncho, 18)
			caja(nombre, x, 70, textoAncho, 29)
			caja(habilidad, x, 101, textoAncho, 36)
			caja(regla, x, 139, textoAncho, 1)
			caja(variante, x, 142, textoAncho, 18)
			caja(pista, x, 163, textoAncho, 43)
			caja(reliquia, x, 208, textoAncho, 28)
			pagina.Size = UDim2.fromOffset(ancho, math.max(altoMapa + 65, if reliquia.Visible then 244 else 212))
			return
		end
		caja(origen, x, y, textoAncho, 20)
		caja(nombre, x, y + 23, textoAncho, 35)
		caja(habilidad, x, y + 63, textoAncho, 50)
		caja(regla, x, y + 118, textoAncho, 1)
		caja(variante, x, y + 129, textoAncho, 21)
		caja(pista, x, y + 153, textoAncho, 60)
		caja(reliquia, x, y + 219, textoAncho, 32)
	end
	local function actualizar()
		local eco = ecos[seleccion]
		local disponible = jugador:GetAttribute(eco.nombre) == true
		local mutada = jugador:GetAttribute(eco.forma) == true
		for i, b in botones do
			b.BackgroundColor3 = if i == seleccion then papel else tinta
			b.TextColor3 = if i == seleccion then tinta else oro
		end
		gradiente.Color = ColorSequence.new(eco.tono, papel)
		origen.Text = eco.isla
		nombre.Text = if disponible then eco.nombre else "Eco desconocido"
		habilidad.Text = if disponible then eco.poder else eco.pista
		variante.Text = if mutada then eco.variante else "Variante por descubrir"
		pista.Text = if mutada then eco.mejora else eco.secreto
		reliquia.Visible = eco.nombre == "Pedernal" and jugador:GetAttribute("LenteGeoda") == true
		reliquia.Text = "Lente de la Geoda · úsala en el espejo del faro."
		adaptar()
		local modelo = obtenerModelo(jugador, eco.nombre)
		if modelo ~= actual or vista ~= disponible or ultimaMutacion ~= mutada then
			actual, vista, ultimaMutacion = modelo, disponible, mutada
			visor:ClearAllChildren()
			ilustrada = modelo and modelo:IsA("Model") and ilustrar(visor, modelo, disponible)
		end
		visor.Visible = ilustrada == true
		sello.Visible = not ilustrada
	end
	for i, b in botones do
		b.Activated:Connect(function()
			seleccion = i
			area.CanvasPosition = Vector2.zero
			actualizar()
		end)
		b.NextSelectionLeft = botones[math.max(1, i-1)]
		b.NextSelectionRight = botones[math.min(#ecos, i+1)]
	end
	area:GetPropertyChangedSignal("AbsoluteSize"):Connect(adaptar)
	local function mostrar(indice)
		if indice then seleccion = indice end
		actualizar()
		local cantidad, variantes = 0, 0
		for _, eco in ecos do
			if jugador:GetAttribute(eco.nombre) then cantidad += 1 end
			if jugador:GetAttribute(eco.forma) then variantes += 1 end
		end
		return ("%d/%d Ecos   ·   %d/%d variantes   ·   %d %%"):format(
			cantidad, #ecos, variantes, #ecos, math.round(100*(cantidad+variantes)/(2*#ecos)))
	end
	return {mostrar = mostrar, botones = botones}
end

return Ecodex
