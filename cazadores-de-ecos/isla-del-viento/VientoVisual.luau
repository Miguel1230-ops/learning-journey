local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Visual = {}
local cielo = Color3.fromRGB(137, 227, 255)
local oro = Color3.fromRGB(255, 212, 119)
local coral = Color3.fromRGB(255, 144, 123)

local function anclar(padre, posicion)
	local a = Instance.new("Attachment")
	a.Position, a.Parent = posicion, padre
	return a
end

local function trazo(padre, a, b, color, grosor)
	local linea = Instance.new("Beam")
	linea.Attachment0, linea.Attachment1 = a, b
	linea.Color, linea.Transparency = ColorSequence.new(color), NumberSequence.new(.23)
	linea.FaceCamera, linea.LightEmission = true, .85
	linea.Width0, linea.Width1, linea.Parent = grosor, grosor, padre
	return linea
end

function Visual.escudo(burbuja)
	burbuja.Color, burbuja.Material, burbuja.Transparency = cielo, Enum.Material.ForceField, .54
	local radio = burbuja.Size.X * .49
	for banda = 0,1 do
		local anterior
		for i=0,8 do
			local angulo = i*math.pi/4
			local offset = Vector3.new(math.cos(angulo), math.sin(angulo)*.49*(if banda==0 then 1 else -1),math.sin(angulo)*.87)*radio
			local actual = anclar(burbuja,offset)
			if anterior then trazo(burbuja,anterior,actual,cielo,.075) end
			anterior = actual
		end
	end
end

local function pulso(padre, nombre, centro, color, medida)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = nombre, medida, CFrame.new(centro)
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true,false,false,false,false
	p.Material, p.Color = Enum.Material.Neon,color
	p.Parent = padre
	return p
end

-- La dirección indica el sentido en el que viaja la ráfaga.
function Visual.impacto(centro, direccion, tipo, padre)
	local normal = if direccion.Magnitude > .01 then direccion.Unit else Vector3.zAxis
	local color = if tipo == "Rebote" then oro elseif tipo == "Bloqueo" then cielo else coral
	local lugar = centro - normal*(if tipo == "Daño" then 1 else 3)
	local frente = CFrame.lookAt(lugar,lugar+normal)
	for i=1,6 do
		local angulo = i*math.pi/3
		local radial = frente.RightVector*math.cos(angulo)+frente.UpVector*math.sin(angulo)
		local p = pulso(padre,"AstillaDe"..tipo,lugar+radial*.32,color,Vector3.new(.18,.18,.74))
		p.CFrame=CFrame.lookAt(p.Position,p.Position+radial)
		TweenService:Create(p,TweenInfo.new(.3),{CFrame=p.CFrame+radial*2.3-normal*.65,Transparency=1}):Play()
		Debris:AddItem(p,.34)
	end
end

function Visual.estela(pieza)
	local a,b=anclar(pieza,Vector3.yAxis*.6),anclar(pieza,-Vector3.yAxis*.6)
	local r=Instance.new("Trail")
	r.Name="ColaDelViento"
	r.Attachment0,r.Attachment1=a,b
	r.FaceCamera,r.LightEmission,r.Lifetime=true,.9,.42
	r.Color=ColorSequence.new(pieza.Color,Color3.fromRGB(229,231,255))
	r.Transparency=NumberSequence.new(.12,1)
	r.Parent=pieza
	return r
end

function Visual.avisar(origen, destino, color, padre)
	if (destino-origen).Magnitude < .1 then return end
	local base=CFrame.lookAt(origen,destino)
	local distancia=(destino-origen).Magnitude
	for i=-1,1 do
		local pos=origen+base.RightVector*i*.72+base.UpVector*math.abs(i)*.15
		local cinta=pulso(padre,"HebraDeCorriente",pos,color,Vector3.new(.09,.16,1.55))
		cinta.CFrame=CFrame.lookAt(pos,pos+base.LookVector)
		TweenService:Create(cinta,TweenInfo.new(.45,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=cinta.CFrame+base.LookVector*distancia,Transparency=.96}):Play()
		Debris:AddItem(cinta,.49)
	end
end

return Visual
