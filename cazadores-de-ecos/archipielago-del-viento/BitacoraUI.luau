-- Piezas del equipo de exploración. Los controladores de cada zona conservan sus acciones.
local Input = game:GetService("UserInputService")
local UI = {}
local tinta = Color3.fromRGB(17, 39, 53)
local papel = Color3.fromRGB(244, 239, 224)
local suave = Color3.fromRGB(201, 216, 214)
local laton = Color3.fromRGB(233, 185, 111)
local menta = Color3.fromRGB(142, 225, 201)
local acentos = {
	Geoda = Color3.fromRGB(201, 172, 254), Prisma = Color3.fromRGB(209, 185, 255),
	Molino = laton, Faro = laton, Chispa = laton, Moneda = laton, Nido = menta,
	Nimbo = Color3.fromRGB(166, 217, 251), Escudo = Color3.fromRGB(162, 221, 254), Viento = menta,
}

-- Trazos en una cuadrícula de 24 puntos. Las siluetas se comparten con la mochila y las marcas en el mundo.
local dibujos = {
	Geoda = {{3,11,8,4,15,2,21,9,18,17,10,22,3,11},{3,11,10,9,15,2},{10,9,10,22},{10,9,17,8,18,17},{17,8,21,9}},
	Molino = {{10,14,8,22,16,22,14,14},{12,12,6,7,4,9,10,13},{12,12,17,5,15,3,11,10},{12,12,19,17,21,15,14,11},{12,12,7,18,9,20,13,14}},
	Faro = {{5,22,19,22},{8,21,10,11,14,11,16,21},{7,10,17,10},{9,9,9,5,15,5,15,9},{7,5,12,2,17,5},{3,6,5,6},{19,6,21,6},{9,17,15,15}},
	Viento = {{2,8,13,8,15,6,14,4,12,4},{4,12,19,12,21,10,21,8},{2,16,14,16,16,18,15,20,12,20}},
	Nimbo = {{3,16,2,13,4,10,7,10,9,6,13,5,16,8,17,10,20,10,22,13,21,16,17,17,7,17,3,16},{9,20,12,18},{14,21,17,19}},
	Nido = {{2,12,6,18,12,21,18,18,22,12,17,14,12,16,7,14,2,12},{4,16,10,18,18,16},{8,13,8,10,10,6,12,5,15,8,16,12}},
	Mochila = {{5,20,4,17,5,9,8,6,16,6,19,9,20,17,19,20,5,20},{9,6,9,4,11,3,13,3,15,4,15,6},{6,10,8,13,16,13,18,10},{9,16,15,16,15,19,9,19,9,16},{11,11,13,11}},
	Moneda = {{12,2,18,4,22,10,21,16,17,21,10,22,4,19,2,12,4,6,8,3,12,2},{12,6,16,12,12,18,8,12,12,6}},
	Brujula = {{12,2,15,9,22,12,15,15,12,22,9,15,2,12,9,9,12,2},{12,5,12,12,17,12}},
	Eco = {{3,8,6,3,10,8,14,8,18,3,21,8,19,16,12,21,5,16,3,8},{7,11,9,12},{17,11,15,12},{10,16,12,17,14,16}},
	Estrella = {{12,2,15,9,22,10,17,15,18,22,12,18,6,22,7,15,2,10,9,9,12,2}},
	Escudo = {{3,5,8,5,12,2,16,5,21,5,20,13,17,18,12,22,7,18,4,13,3,5},{12,7,12,17},{8,10,16,10}},
	Ala = {{2,11,22,3,17,15,12,13,8,19,7,14,2,11},{7,14,22,3},{12,13,22,3}},
	Libro = {{2,5,7,4,12,7,17,4,22,5,22,18,17,17,12,20,7,17,2,18,2,5},{12,7,12,20},{5,8,9,9},{15,9,19,8}},
	Prisma = {{12,2,21,12,12,22,3,12,12,2},{3,12,21,12},{12,2,9,12,12,22},{12,2,15,12,12,22}},
	Cerrar = {{5,5,19,19},{19,5,5,19}},
	Chispa = {{12,2,14,8,19,10,16,13,15,19,12,22,8,20,5,15,6,10,10,12,12,2},{12,14,13,17,11,20}},
	Baston = {{3,21,15,9,14,5,18,2,22,3,21,8,17,11,15,10},{5,18,7,20},{15,6,18,8,20,4}},
	Mano = {{5,13,8,14,8,6,10,5,12,7,12,11,13,9,16,10,18,10,20,12,19,17,15,21,9,20,4,15,5,13}},
	Salto = {{4,19,10,19,14,15,14,5},{9,10,14,5,19,10}},
}
local function crear(clase, padre, propiedades)
	local instancia = Instance.new(clase)
	for clave, valor in propiedades do instancia[clave] = valor end
	instancia.Parent = padre
	return instancia
end

local function marco(padre, nombre, posicion, medida, color)
	return crear("Frame", padre, {Name=nombre, Position=posicion, Size=medida, BorderSizePixel=0,
		BackgroundColor3=color or tinta, BackgroundTransparency=if color then 0 else 1})
end
local function esquina(objeto, radio)
	return crear("UICorner", objeto, {CornerRadius=UDim.new(0,radio)})
end
local function borde(objeto, color, transparencia)
	return crear("UIStroke", objeto, {Color=color, Transparency=transparencia, Thickness=1,
		ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end
local function letra(padre, nombre, pos, medida, fuente, puntos, color)
	return crear("TextLabel",padre,{Name=nombre,Position=pos,Size=medida,Text="",BackgroundTransparency=1,
		Font=fuente,TextSize=puntos,TextColor3=color,TextXAlignment=Enum.TextXAlignment.Left})
end
function UI.icono(padre, nombre, tamano, color, posicion)
	local arte = marco(padre,nombre,posicion or UDim2.fromOffset(0,0),UDim2.fromOffset(tamano,tamano))
	local escala = tamano/24
	for _, trazo in dibujos[nombre] or dibujos.Brujula do
		for i=1,#trazo-2,2 do
			local x,y,x2,y2 = trazo[i],trazo[i+1],trazo[i+2],trazo[i+3]
			local dx,dy = x2-x,y2-y
			local segmento = marco(arte,"Trazo",UDim2.fromOffset((x+x2)*escala/2,(y+y2)*escala/2),
				UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)*escala+0.65,math.max(1.25,1.55*escala)),color or papel)
			segmento.AnchorPoint=Vector2.new(.5,.5)
			segmento.Rotation=math.deg(math.atan2(dy,dx))
		end
	end
	return arte
end

function UI.objetivo(padre, opciones)
	opciones = opciones or {}
	local ancho = opciones.ancho or 348
	local panel = marco(padre,"Objetivo",opciones.posicion or UDim2.fromOffset(13,9),UDim2.new(1,-26,0,76),tinta)
	esquina(panel,8)
	crear("UISizeConstraint",panel,{MaxSize=Vector2.new(ancho,125)})
	crear("UIGradient",panel,{Color=ColorSequence.new(Color3.fromRGB(240,250,255),Color3.fromRGB(171,193,201)),
		Transparency=NumberSequence.new(.03,.22)})
	local ribete=borde(panel,laton,.62)
	local medalla=marco(panel,"Sello",UDim2.fromOffset(13,16),UDim2.fromOffset(36,36),Color3.fromRGB(38,60,72))
	medalla.Rotation=45
	esquina(medalla,6)
	local metal=borde(medalla,laton,.25)
	local eje=marco(panel,"Emblema",UDim2.fromOffset(17,20),UDim2.fromOffset(28,28))
	local titulo=letra(panel,"Titulo",UDim2.fromOffset(62,6),UDim2.new(1,-76,0,24),Enum.Font.GothamBold,17,papel)
	titulo.TextTruncate=Enum.TextTruncate.AtEnd
	local pista=letra(panel,"Pista",UDim2.fromOffset(62,32),UDim2.new(1,-76,0,33),Enum.Font.GothamMedium,13,suave)
	pista.TextWrapped=true
	pista.TextYAlignment=Enum.TextYAlignment.Top
	local detalle=letra(panel,"Estado",UDim2.fromOffset(62,68),UDim2.new(1,-76,0,17),Enum.Font.GothamBold,12,menta)
	detalle.TextTruncate=Enum.TextTruncate.AtEnd
	local linea=marco(panel,"Filete",UDim2.fromOffset(62,30),UDim2.fromOffset(34,1),laton)
	local carril=marco(panel,"Medidor",UDim2.new(0,62,1,-6),UDim2.new(1,-78,0,3),Color3.fromRGB(49,72,81))
	local medida=marco(carril,"Valor",UDim2.fromScale(0,0),UDim2.fromScale(1,1),menta)
	carril.Visible=false
	local simboloAnterior, arte
	local interfaz={marco=panel}
	function interfaz:actualizar(simbolo, nombre, instruccion, estado, fraccion)
		local color=acentos[simbolo] or menta
		if simbolo~=simboloAnterior or not arte then
			if arte then arte:Destroy() end
			arte=UI.icono(eje,simbolo or "Brujula",28,color)
			simboloAnterior=simbolo
			metal.Color,ribete.Color,linea.BackgroundColor3,medida.BackgroundColor3,detalle.TextColor3=color,color,color,color,color
		end
		titulo.Text,pista.Text,detalle.Text=nombre or "",instruccion or "",estado or ""
		detalle.Visible=detalle.Text~=""
		carril.Visible=type(fraccion)=="number"
		if carril.Visible then medida.Size=UDim2.fromScale(math.clamp(fraccion,0,1),1) end
		panel.Size=UDim2.new(1,-26,0,(if detalle.Visible then 90 else 73)+(if carril.Visible then 5 else 0))
	end
	function interfaz:visible(valor) panel.Visible=valor end
	return interfaz
end

function UI.acciones(padre)
	local fila=marco(padre,"Acciones",UDim2.new(.5,0,1,-14),UDim2.new(1,-20,0,46))
	fila.AnchorPoint=Vector2.new(.5,1)
	local orden=crear("UIListLayout",fila,{FillDirection=Enum.FillDirection.Horizontal,
		HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,
		Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
	local ranuras={}
	local function ranura(indice)
		local b=crear("TextButton",fila,{Name="Accion"..indice,Text="",AutoButtonColor=false,BackgroundColor3=tinta,
			BackgroundTransparency=.09,BorderSizePixel=0,Size=UDim2.fromOffset(94,44),LayoutOrder=indice,Selectable=false})
		esquina(b,8);borde(b,laton,.55)
		local tecla=letra(b,"Tecla",UDim2.fromOffset(33,4),UDim2.new(1,-37,0,15),Enum.Font.GothamBold,11,laton)
		local titulo=letra(b,"Accion",UDim2.fromOffset(33,18),UDim2.new(1,-36,0,20),Enum.Font.GothamBold,12,papel)
		titulo.TextTruncate=Enum.TextTruncate.AtEnd
		local recarga=marco(b,"Recarga",UDim2.new(0,6,1,-4),UDim2.new(1,-12,0,2),Color3.fromRGB(52,77,83))
		local listo=marco(recarga,"Disponible",UDim2.fromScale(0,0),UDim2.fromScale(1,1),menta)
		local lugar={boton=b,tecla=tecla,titulo=titulo,carril=recarga,listo=listo}
		b.Activated:Connect(function() if lugar.activar then lugar.activar() end end)
		ranuras[indice]=lugar
		return lugar
	end
	local interfaz={marco=fila}
	function interfaz:actualizar(lista)
		local tactil=Input.PreferredInput==Enum.PreferredInput.Touch
		local vista=workspace.CurrentCamera
		local ancho=vista and vista.ViewportSize.X or 800
		local util=if tactil then math.max(94,ancho-145) else ancho-32
		local cantidad=#lista
		local anchoBoton=math.clamp(math.floor((util-5*(cantidad-1))/math.max(cantidad,1)),46,if tactil then 93 else 106)
		local compacto=anchoBoton<78
		orden.HorizontalAlignment=if tactil then Enum.HorizontalAlignment.Right else Enum.HorizontalAlignment.Center
		fila.Position=if tactil then UDim2.new(.5,-6,1,-94) else UDim2.new(.5,0,1,-14)
		for indice,dato in lista do
			local s=ranuras[indice] or ranura(indice)
			s.boton.Visible=true
			s.boton.Size=UDim2.fromOffset(anchoBoton,44)
			s.activar=dato.activar
			s.boton.Active=dato.activar~=nil
			local simbolo=dato.icono or "Brujula"
			if s.simbolo~=simbolo then
				if s.arte then s.arte:Destroy() end
				s.arte=UI.icono(s.boton,simbolo,22,acentos[simbolo] or menta)
				s.simbolo=simbolo
			end
			s.arte.Position=if compacto then UDim2.new(.5,-11,0,3) else UDim2.fromOffset(7,10)
			local leyenda=if tactil then "" else dato.tecla or ""
			s.tecla.Text=leyenda
			s.tecla.Visible=leyenda~="" and not compacto
			s.titulo.Position=if compacto then UDim2.fromOffset(1,24) else UDim2.fromOffset(33,if leyenda=="" then 11 else 18)
			s.titulo.Size=if compacto then UDim2.new(1,-2,0,16) else UDim2.new(1,-36,0,19)
			s.titulo.TextXAlignment=if compacto then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
			s.titulo.Text=if compacto and leyenda~="" then leyenda else dato.texto or ""
			s.carril.Visible=type(dato.progreso)=="number"
			if s.carril.Visible then s.listo.Size=UDim2.fromScale(math.clamp(dato.progreso,0,1),1) end
		end
		for i=cantidad+1,#ranuras do ranuras[i].boton.Visible=false;ranuras[i].activar=nil end
	end
	function interfaz:visible(valor) fila.Visible=valor end
	return interfaz
end

return UI
