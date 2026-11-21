-- Modelos del rescate y de las dos apariencias del compañero.
local Escena = {}
local azul = Color3.fromRGB(43, 63, 92)
local perla = Color3.fromRGB(250, 233, 199)
local oro = Color3.fromRGB(254, 173, 83)
local menta = Color3.fromRGB(101, 255, 196)
local violeta = Color3.fromRGB(186, 129, 255)
local v = Vector3.new

local function pieza(padre, nombre, pos, tam, color, forma, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position, p.Color = nombre, tam, pos, color
	p.Shape = forma or Enum.PartType.Block
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Parent = padre
	return p
end

local function ovalo(padre, nombre, pos, tam, color, luminoso)
	return pieza(padre, nombre, pos, tam, color, Enum.PartType.Ball, if luminoso then Enum.Material.Neon else nil)
end

local function segmento(padre, nombre, a, b, grosor, color)
	local p = pieza(padre, nombre, (a+b)/2, v(grosor,grosor,(b-a).Magnitude+0.04), color, nil, Enum.Material.Neon)
	p.CFrame = CFrame.lookAt((a+b)/2,b)
	return p
end

local function colaAurora(m, lado, tono)
	local puntos = {
		v(lado * .26, .12, .73), v(lado * .55, .04, 1.45), v(lado * .88, .18, 2.16),
		v(lado * .97, .69, 2.64), v(lado * .80, 1.06, 2.91),
	}
	for i = 1, #puntos - 1 do
		local a, b = puntos[i], puntos[i+1]
		local pluma = ovalo(m, "CintaPolar", (a+b)/2,
			v(.43 - i*.057, .16, (b-a).Magnitude+.25), tono:Lerp(perla, i*.095), i == 4)
		pluma.CFrame = CFrame.lookAt((a+b)/2, b)
		if i == 4 then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = v(-.12,0,0), v(.12,0,0)
			a0.Parent, a1.Parent = pluma, pluma
			local estela = Instance.new("Trail")
			estela.Attachment0, estela.Attachment1 = a0, a1
			estela.Color = ColorSequence.new(tono, perla)
			estela.Lifetime, estela.LightEmission, estela.MinLength = .46, .9, .11
			estela.WidthScale = NumberSequence.new(1,0)
			estela.Transparency = NumberSequence.new(.23,1)
			estela.FaceCamera, estela.Parent = true, pluma
		end
	end
end

function Escena.eco(aurora)
	local m = Instance.new("Model")
	m.Name = if aurora then "NimboAurora" else "Nimbo"
	local plumaje = if aurora then Color3.fromRGB(69, 63, 127) else azul
	m.PrimaryPart = ovalo(m,"Pecho",v(0,0,0),v(1.55,1.45,1.95),plumaje)
	ovalo(m,"Gorguera",v(0,.03,-.64),v(1.32,1.12,.94),if aurora then Color3.fromRGB(186,241,233) else perla)
	ovalo(m,"Cabeza",v(0,.61,-.74),v(1.35,1.14,1.16),plumaje)
	ovalo(m,"Pico",v(0,.46,-1.39),v(.34,.26,.52),oro)
	ovalo(m,"Penacho",v(0,1.15,-.6),v(.28,.69,.34),if aurora then violeta else oro,true).Orientation = v(-24,0,0)
	for _,lado in {-1,1} do
		ovalo(m,"Ojo",v(lado*.42,.69,-1.18),v(.26,.28,.22),perla)
		ovalo(m,"Pupila",v(lado*.43,.70,-1.28),v(.13,.16,.10),azul)
		local ala = Instance.new("Model")
		ala.Name = if lado<0 then "AlaIzquierda" else "AlaDerecha"
		ala.Parent = m
		local tono = if aurora then (if lado<0 then menta else violeta) else oro
		if aurora then
			-- La punta de la media luna sube y barre hacia atrás, visible incluso en el retrato.
			local curva = {v(.46,.13,-.45),v(1.20,.24,-.66),v(1.91,.47,-.33),v(2.40,.74,.47),v(2.46,1.06,1.20)}
			for i = 1, #curva-1 do
				local a = curva[i] * v(lado,1,1)
				local b = curva[i+1] * v(lado,1,1)
				local pluma = ovalo(ala,"Remera", (a+b)/2,
					v(.85-i*.13,.23,(b-a).Magnitude+.49), tono:Lerp(perla,i*.1), i == 4)
				pluma.CFrame = CFrame.lookAt((a+b)/2,b)
			end
			for i = 1, 3 do
				local pluma = ovalo(ala,"Pluma interior",v(lado*(.64+i*.31),.13+i*.08,.10+i*.11),
					v(.46,.23,1.58-i*.17),plumaje:Lerp(tono,.35+i*.12))
				pluma.Orientation = v(0,lado*(13+i*7),lado*9)
			end
			colaAurora(m,lado,tono)
		else
			for i=1,3 do
				local pluma = ovalo(ala,"Pluma",v(lado*(1.38-i*.13),.14+i*.04,-.45+i*.42),v(2.0-i*.16,.2,.64),tono)
				pluma.Orientation = v(0,-lado*(12+i*7),lado*(17-i*3))
			end
		end
		local hombro = pieza(ala,"Hombro",v(lado*.58,.12,0),Vector3.one*.08,perla)
		hombro.Transparency, ala.PrimaryPart = 1, hombro
	end
	if not aurora then ovalo(m,"Cola",v(0,.14,1.15),v(.87,.32,1.14),oro) end
	return m
end

-- Dos cuñas forman cada faceta triangular y comparten sus vértices con la placa vecina.
local function faceta(padre, a, b, c, color)
	local ab, ac, bc = b-a, c-a, c-b
	if ab.Magnitude > math.max(ac.Magnitude, bc.Magnitude) then
		a,c = c,a
	elseif ac.Magnitude > bc.Magnitude then
		a,b = b,a
	end
	ab,ac,bc = b-a,c-a,c-b
	local lateral = ac:Cross(ab).Unit
	local fondo = bc.Unit
	local arriba = fondo:Cross(lateral).Unit
	local alto = math.abs(ab:Dot(arriba))
	local function mitad(centro, largo, eje, z)
		if largo < .015 then return end
		local p = Instance.new("WedgePart")
		p.Name, p.Size = "Nácar", v(.065,alto,largo)
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true,false,false,false
		p.Material, p.Color = Enum.Material.SmoothPlastic, color
		p.CFrame, p.Parent = CFrame.fromMatrix(centro,eje,arriba,z), padre
	end
	mitad((a+b)/2,math.abs(ab:Dot(fondo)),lateral,fondo)
	mitad((a+c)/2,math.abs(ac:Dot(fondo)),-lateral,-fondo)
end

local function crearHuevo(ruta, origen)
	-- El servidor usa esta ancla como ubicación del prompt; las placas se abren en cada cliente.
	local ancla = pieza(ruta,"Huevo",origen,v(1,1,1),perla)
	ancla.Transparency = 1
	local cascara = Instance.new("Model")
	cascara.Name, cascara.Parent = "Cascaron", ruta
	local cuenco = Instance.new("Model")
	cuenco.Name, cuenco.Parent = "Cuenco", cascara
	local lados = 9
	local paleta = {perla, Color3.fromRGB(236,218,193), Color3.fromRGB(220,219,226)}
	local function perfil(i)
		local vertice = i % lados
		local a = vertice*2*math.pi/lados
		local radial = v(math.cos(a),0,math.sin(a))
		return {
			origen-v(0,2,0), origen+radial*1.13-v(0,1.52,0),
			origen+radial*1.62+v(0,if vertice%2 == 0 then .07 else .36,0),
			origen+radial*1.04+v(0,1.30,0), origen+v(0,2.18,0),
		}
	end
	for k=1,3 do
		local placa = Instance.new("Model")
		placa.Name, placa.Parent = "Placa"..k,cascara
		local angulo = (k-0.5)*2*math.pi/3
		local dir = v(math.cos(angulo),0,math.sin(angulo))
		local bisagra = origen+dir*1.45+v(0,.18,0)
		for i=(k-1)*3,k*3-1 do
			local a,b = perfil(i),perfil(i+1)
			local tono=paleta[i%#paleta+1]
			faceta(cuenco,a[1],a[2],b[2],tono)
			faceta(cuenco,a[2],a[3],b[2],tono)
			faceta(cuenco,b[2],a[3],b[3],tono)
			faceta(placa,a[3],a[4],b[3],tono)
			faceta(placa,b[3],a[4],b[4],tono)
			faceta(placa,a[4],a[5],b[4],tono)
			segmento(placa,"Grieta",a[3],b[3],.047,oro)
		end
		local eje = pieza(placa,"Bisagra",bisagra,Vector3.one*.08,perla)
		eje.CFrame = CFrame.lookAt(bisagra,bisagra+dir)
		eje.Transparency, placa.PrimaryPart = 1, eje
	end
	local colores = {menta, oro, violeta}
	for i=1,3 do
		local angulo = math.pi+(i-2)*.53
		local radial = v(math.cos(angulo),0,math.sin(angulo))
		local sitio = origen+radial*1.43-v(0,.57,0)
		local cara = CFrame.lookAt(sitio,sitio+radial)
		local borde = pieza(cuenco,"Engaste",sitio,v(.49,.49,.10),Color3.fromRGB(98,77,73))
		borde.CFrame = cara * CFrame.Angles(0,0,math.pi/4)
		local marca = pieza(cuenco,"Marca"..i,sitio,v(.29,.29,.11),colores[i],nil,Enum.Material.Neon)
		marca.CFrame = borde.CFrame*CFrame.new(0,0,-.07)
	end
	-- Una corona de piedra enlaza la base del cascarón con la nube.
	ovalo(ruta,"Lecho de pizarra",origen-v(0,2.55,0),v(4.9,2.55,4.55),azul)
	for i=1,8 do
		local angulo = i*math.pi/4
		local pluma=ovalo(ruta,"Cáliz del nido",origen+v(math.cos(angulo)*1.63,-1.93,math.sin(angulo)*1.63),v(.58,.39,1.4),if i%2==0 then azul else Color3.fromRGB(110,142,160))
		pluma.CFrame *= CFrame.Angles(0,-angulo,math.rad(17))
	end
	return ancla
end

function Escena.ruta(faro)
	local ruta = Instance.new("Model")
	ruta.Name = "RescateNimbo"
	local function suelo(nombre,pos,tam)
		local p = pieza(ruta,nombre,pos,tam,azul,nil,Enum.Material.Slate)
		p.CanCollide,p.CanQuery = true,true
		return p
	end
	suelo("Balcon",v(106,29.2,88),v(8,.8,7))
	local base = ovalo(ruta,"Ascensor",v(104,18.45,91),v(4.3,.65,4.3),menta,true)
	local salto = ovalo(ruta,"Despegue",v(108,29.68,87),v(3.5,.16,3.5),oro,true)
	local plataforma = suelo("Nido",v(153,20,87),v(14,2,14))
	for i=1,10 do
		local a = i*math.pi/5
		ovalo(ruta,"Nube",plataforma.Position+v(7*math.cos(a),-1+math.sin(i*3),7*math.sin(a)),v(6+i%3,4+i%2,6),if i%2==0 then azul else Color3.fromRGB(96,108,146))
	end
	for i=1,3 do
		segmento(ruta,"Relámpago",v(149+i*2,20,81),v(147+i*2,17,81),.16,violeta)
	end
	local huevo = crearHuevo(ruta,v(153,24.8,87))
	local aros = Instance.new("Folder")
	aros.Name,aros.Parent="Aros",ruta
	for i, centro in {v(119,32,88.5),v(133,29.5,81.3),v(145,27.5,87.8)} do
		local aro = Instance.new("Model")
		aro.Name,aro.Parent = tostring(i),aros
		local origen = pieza(aro,"Centro",centro,Vector3.one*.1,perla)
		origen.Transparency,aro.PrimaryPart = 1,origen
		for j=1,24 do
			local a,b = (j-1)*math.pi/12,j*math.pi/12
			local function punto(t) return centro+v(0,math.cos(t)*4.8,math.sin(t)*4.8) end
			segmento(aro,"Arco",punto(a),punto(b),if j%6==0 then .48 else .2,({menta,oro,violeta})[i])
		end
	end
	ruta.Parent = faro
	return ruta,base,salto,huevo
end

return Escena
