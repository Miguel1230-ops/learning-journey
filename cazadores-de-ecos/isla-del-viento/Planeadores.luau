-- Geometría y ajustes compartidos del planeo.
local Planeadores = {}

local basico = table.freeze({ duracion = 2.45, ventanaServidor = 2.60, giro = 13, velocidad = 27 })
local avanzado = table.freeze({ duracion = 3.05, ventanaServidor = 3.25, giro = 18, velocidad = 36 })

function Planeadores.ajustes(mejorado)
	return if mejorado then avanzado else basico
end

local ROBLE = Color3.fromRGB(99, 67, 48)
local LONA = Color3.fromRGB(247, 198, 105)
local LINO = Color3.fromRGB(253, 229, 168)
local COBRE = Color3.fromRGB(187, 120, 65)
local LATON = Color3.fromRGB(241, 193, 105)
local AZUL = Color3.fromRGB(24, 57, 79)
local ACERO = Color3.fromRGB(52, 82, 102)
local PETROLEO = Color3.fromRGB(28, 112, 127)
local AGUA = Color3.fromRGB(111, 237, 216)

local function pieza(padre, nombre, medida, pose, color, material, clase)
	local p = Instance.new(clase or "Part")
	p.Name = nombre
	p.Size = medida
	p.CFrame = pose
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Parent = padre
	return p
end

local function seccion(padre, nombre)
	local grupo = Instance.new("Model")
	grupo.Name = nombre
	local centro = pieza(grupo, "Bisagra", Vector3.one * 0.1, CFrame.identity, AZUL, Enum.Material.SmoothPlastic)
	centro.Transparency = 1
	grupo.PrimaryPart = centro
	grupo.Parent = padre
	return grupo
end

local function varilla(padre, nombre, a, b, grueso, color, material)
	return pieza(padre, nombre, Vector3.new(grueso, grueso, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b),
		color, material)
end

local function tela(padre, a, b, c, color)
	-- Dos cuñas delgadas unidas por la perpendicular al lado más largo.
	local ab, ac, bc = b - a, c - a, c - b
	if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
		a, c = c, a
	elseif ac:Dot(ac) > bc:Dot(bc) then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local fondo = bc.Unit
	local derecha = ac:Cross(ab).Unit
	local arriba = fondo:Cross(derecha)
	local alto = math.abs(ab:Dot(arriba))
	local anchoB = math.abs(ab:Dot(fondo))
	local anchoC = math.abs(ac:Dot(fondo))
	pieza(padre, "Lona", Vector3.new(0.048, alto, anchoB), CFrame.fromMatrix((a + b) / 2, derecha, arriba, fondo),
		color, Enum.Material.Fabric, "WedgePart")
	pieza(padre, "Lona", Vector3.new(0.048, alto, anchoC), CFrame.fromMatrix((a + c) / 2, -derecha, arriba, -fondo),
		color, Enum.Material.Fabric, "WedgePart")
end

local function crearAla(modelo, lado, mejorado)
	local grupo = seccion(modelo, if lado < 0 then "AlaIzquierda" else "AlaDerecha")
	local nariz = Vector3.new(lado * 0.08, 0, -2.11)
	local borde = Vector3.new(lado * 2.31, 0.17, -0.64)
	local punta = Vector3.new(lado * (if mejorado then 4.78 else 4.08), if mejorado then 0.23 else 0.11, 1.11)
	local pliegue = Vector3.new(lado * 2.11, 0, if mejorado then 1.10 else 1.35)
	local cola = Vector3.new(lado * 0.08, 0.09, 1.78)
	local armazon = if mejorado then ACERO else ROBLE
	local material = if mejorado then Enum.Material.Metal else Enum.Material.Wood
	local acento = if mejorado then AGUA else COBRE

	tela(grupo, nariz, borde, pliegue, if mejorado then PETROLEO else LONA)
	tela(grupo, nariz, pliegue, cola, if mejorado then AZUL else LINO)
	tela(grupo, borde, punta, pliegue, if mejorado then AZUL else LONA)
	varilla(grupo, "Borde frontal", nariz, borde, 0.09, armazon, material)
	varilla(grupo, "Borde frontal", borde, punta, 0.09, armazon, material)
	varilla(grupo, "Dobladillo", punta, pliegue, 0.055, acento, Enum.Material.SmoothPlastic)
	varilla(grupo, "Dobladillo", pliegue, cola, 0.055, acento, Enum.Material.SmoothPlastic)
	varilla(grupo, "Costura", borde, pliegue, 0.044, acento, Enum.Material.Fabric)

	local cinta = (punta - pliegue).Unit * 0.61
	varilla(grupo, "Marca del ala", punta - cinta, punta, 0.095, if mejorado then AGUA else LINO,
		if mejorado then Enum.Material.Neon else Enum.Material.Fabric)
	if mejorado then
		local aleta = punta - cinta * 0.42
		local tope = aleta + Vector3.new(lado * 0.19, 0.49, 0.25)
		tela(grupo, aleta, tope, punta + Vector3.new(0, 0.04, 0.48), PETROLEO)
		varilla(grupo, "Aleta luminosa", aleta, tope, 0.046, AGUA, Enum.Material.Neon)
	end
	return grupo
end

function Planeadores.crear(mejorado)
	local modelo = Instance.new("Model")
	modelo.Name = if mejorado then "PlaneadorAvanzado" else "PlaneadorBasico"
	local cuerpo = seccion(modelo, "Armazon")
	local armazon = if mejorado then ACERO else ROBLE
	local material = if mejorado then Enum.Material.Metal else Enum.Material.Wood
	varilla(cuerpo, "Quilla", Vector3.new(0, 0, -2.20), Vector3.new(0, 0.10, 1.88), 0.13, armazon, material)
	for _, lado in ipairs({ -1, 1 }) do
		varilla(cuerpo, "Soporte", Vector3.new(0, -0.02, -0.67), Vector3.new(lado * 0.79, -1.89, 0.17),
			0.074, armazon, material)
		varilla(cuerpo, "Agarre", Vector3.new(lado * 0.79, -1.89, 0.17), Vector3.new(lado * 0.81, -1.97, -0.34),
			0.15, armazon, material)
	end
	pieza(cuerpo, "Medallón", Vector3.new(0.52, 0.08, 0.52), CFrame.new(0, 0.12, -0.71) * CFrame.Angles(0, math.pi / 4, 0),
		LATON, Enum.Material.Metal)
	pieza(cuerpo, "Insignia", Vector3.new(0.24, 0.079, 0.24), CFrame.new(0, 0.16, -0.71) * CFrame.Angles(0, math.pi / 4, 0),
		if mejorado then AGUA else LINO, if mejorado then Enum.Material.Neon else Enum.Material.SmoothPlastic)
	return { modelo = modelo, cuerpo = cuerpo, izquierda = crearAla(modelo, -1, mejorado), derecha = crearAla(modelo, 1, mejorado) }
end

function Planeadores.colocar(planeador, posicion, direccion, apertura, banco)
	local plegado = 1 - apertura
	local altura = posicion + Vector3.new(0, 3.17 - plegado * 0.97, 0)
	local pose = CFrame.lookAt(altura, altura + direccion) * CFrame.Angles(0, 0, banco)
	local giro = plegado * math.rad(83)
	local inclinacion = plegado * math.rad(14)
	planeador.cuerpo:PivotTo(pose)
	planeador.izquierda:PivotTo(pose * CFrame.Angles(0, giro, inclinacion))
	planeador.derecha:PivotTo(pose * CFrame.Angles(0, -giro, -inclinacion))
end

return Planeadores
