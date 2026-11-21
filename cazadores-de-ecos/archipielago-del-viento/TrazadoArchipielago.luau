-- Pase de construcción del lugar en edición. Las piezas resultantes se guardan en el mapa.
local isla = workspace.IslaDelViento
if isla:FindFirstChild("ObrasDelArchipielago") then return "El trazado ya existe." end
local rutas = isla.Rutas
local obras = Instance.new("Model")
obras.Name = "ObrasDelArchipielago"
local roca = Color3.fromRGB(62, 78, 94)
local cobre = Color3.fromRGB(176, 111, 76)
local madera = Color3.fromRGB(104, 67, 48)
local oro = Color3.fromRGB(255, 201, 104)
local mar = Color3.fromRGB(114, 233, 207)
local pino = Color3.fromRGB(48, 113, 103)
local uva = Color3.fromRGB(155, 124, 202)
local function modelo(nombre, padre)
	local m = Instance.new("Model")
	m.Name, m.Parent = nombre, padre or obras
	return m
end
local function pieza(padre, nombre, tam, marco, color, material, solido, clase)
	local p = Instance.new(clase or "Part")
	p.Name, p.Size, p.CFrame = nombre, tam, marco
	p.Color, p.Material = color, material
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, solido == true, false, solido == true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = padre
	return p
end
local function viga(padre, nombre, a, b, ancho, alto, color, material, solido)
	return pieza(padre,nombre,Vector3.new(ancho,alto,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material,solido)
end
local function risca(padre,pos,tam,angulo,tono)
	return pieza(padre,"Estrato",tam,CFrame.new(pos)*CFrame.Angles(0,math.rad(angulo),0),tono or roca,Enum.Material.Slate,true,"WedgePart")
end
local function pilar(padre, base, alto, tono)
	pieza(padre,"Sillar",Vector3.new(2.8,1.3,2.8),CFrame.new(base+Vector3.yAxis*.65),roca,Enum.Material.Slate,true)
	pieza(padre,"Pilar",Vector3.new(1.9,alto,1.9),CFrame.new(base+Vector3.yAxis*(1.3+alto/2)),tono,Enum.Material.WoodPlanks,true)
	pieza(padre,"Capitel",Vector3.new(2.65,.55,2.65),CFrame.new(base+Vector3.yAxis*(alto+1.4)),cobre,Enum.Material.Metal)
end
local function boya(padre,pos,tono)
	pieza(padre,"Soporte",Vector3.new(.7,2.7,.7),CFrame.new(pos+Vector3.yAxis*1.35),madera,Enum.Material.Wood)
	pieza(padre,"Prisma",Vector3.new(.8,1.25,.8),CFrame.new(pos+Vector3.yAxis*3.1)*CFrame.Angles(0,.65,.17),tono,Enum.Material.Neon)
end

-- La playa sigue a la baliza final del relevo. Solo las lámparas del Molino viajan con él.
local molino = isla.MolinoDelViento
local delta = Vector3.new(120,0,-30)
for _, grupo in molino:GetChildren() do
	if grupo:IsA("BasePart") then grupo.CFrame += delta
	elseif grupo:IsA("Model") then grupo:PivotTo(grupo:GetPivot()+delta)
	else
		for _, p in grupo:GetDescendants() do
			if p:IsA("BasePart") and ((grupo.Name ~= "Luces" and grupo.Name ~= "SoportesDeLuces") or p.Position.Z > 50) then
				p.CFrame += delta
			end
		end
	end
end
local muelle=modelo("Muelle del Molino")
pieza(muelle,"Muelle",Vector3.new(12,1.3,8),CFrame.new(129,19.34,-5.1),madera,Enum.Material.WoodPlanks,true)
risca(muelle,Vector3.new(130,15,-5.2),Vector3.new(11,7,8),-14)
for _,x in {126,133} do boya(muelle,Vector3.new(x,20,-7.9),oro) end
-- El arco de la primera bifurcación enmarca tanto el puente como el vuelo de Cometa.
for _,p in rutas:GetChildren() do
	if p:IsA("BasePart") then
		if p.Name=="Lanzadera" or p.Name=="Pista de despegue" or p.Name=="PuertaPlaneo" or p.Name=="Flecha de despegue" then
			p.CFrame=CFrame.new(23,0,3.8)*CFrame.Angles(0,math.rad(23),0)*CFrame.new(-23,0,17)*p.CFrame
		elseif p.Name=="ZonaAro" or p.Name:match("^Aro de viento ") then
			p.CFrame=CFrame.new(47,0,-6.3)*CFrame.Angles(0,math.rad(23),0)*CFrame.new(-47,0,17)*p.CFrame
		end
	end
end
local puente=modelo("PuenteLevadizo")
rutas.PuertaPuente.Transparency,rutas.PuertaPuente.CanCollide,rutas.PuertaPuente.CanQuery=1,false,false
local hojas={modelo("HojaOeste",puente),modelo("HojaEste",puente)}
for _,p in rutas:GetChildren() do
	if not p:IsA("BasePart") then continue end
	local x=p.Position.X
	if p.Name=="Pasamanos" then
		-- Divide la barandilla en cuatro para que el tramo móvil se levante junto a sus tablas.
		local z,y=p.Position.Z,p.Position.Y
		p.Transparency,p.CanCollide,p.CanQuery=1,false,false
		for k,r in {{23.05,30.65},{30.65,46.2},{46.2,61.75},{61.75,69.55}} do
			pieza(if k==2 then hojas[1] elseif k==3 then hojas[2] else puente,"Cable",Vector3.new(r[2]-r[1],.2,.2),CFrame.new((r[1]+r[2])/2,y,z),cobre,Enum.Material.Metal)
		end
	elseif x>30.65 and x<61.75 and (p.Name:match("^Tabla ") or p.Name=="Baranda" or math.abs(p.Position.Z-15.2)<4.4 and p.Size.Magnitude<1.5) then
		p.Parent=if x<=46.21 then hojas[1] else hojas[2]
	end
end
for k,pivote in {30.65,61.75} do
	local h=hojas[k]
	local centro=if k==1 then 38.42 else 53.97
	for _,z in {11.5,18.9} do
		pieza(h,"Viga del tablero",Vector3.new(15.54,.75,.62),CFrame.new(centro,18.91,z),madera,Enum.Material.WoodPlanks,true)
	end
	h.WorldPivot=CFrame.new(pivote,19.35,15.2)
	pilar(puente,Vector3.new(pivote,18.8,9.6),6.4,madera)
	pilar(puente,Vector3.new(pivote,18.8,20.8),6.4,madera)
	for _,z in {9.5,20.9} do
		local lado=if k==1 then -1 else 1
		local extremo=Vector3.new(pivote+lado*3,20.6,z)
		viga(h,"Palanca",Vector3.new(pivote,19.45,z),extremo,.52,.52,cobre,Enum.Material.Metal)
		pieza(h,"Contrapeso",Vector3.new(1.8,2.25,1.65),CFrame.new(extremo),roca,Enum.Material.Slate)
	end
end
local guia=modelo("Arco de los vigías")
for _,z in {-.4,9.1} do pilar(guia,Vector3.new(22,19.95,z),7.65,madera) end
viga(guia,"Dintel",Vector3.new(22,29,-1.6),Vector3.new(22,29,10.3),1.15,1.08,cobre,Enum.Material.Metal)
for j=1,5 do
	local x=3+j*3.5
	pieza(guia,"Piedra de rumbo",Vector3.new(1.74,.12,.63),CFrame.new(x,20.1,5.3)*CFrame.Angles(0,.19,0),mar,Enum.Material.Slate)
end
-- Siluetas reconocibles: cedros vencidos por el viento, contrafuertes minerales y velas del puerto.
local bosque=modelo("Soto del nido")
for j,pos in {Vector3.new(-42,19.95,-8),Vector3.new(-34,19.95,-18),Vector3.new(-27,19.95,-23),Vector3.new(-11,19.95,26),Vector3.new(-18,19.95,24)} do
	local h=5.2+j%3; local cima=pos+Vector3.new(1.7,h,.5)
	viga(bosque,"Tronco",pos,cima,.85,.95,madera,Enum.Material.Wood,true)
	for k=0,2 do
		pieza(bosque,"Copa",Vector3.new(5.6-k,1.4,4.4-k*.6),CFrame.new(cima+Vector3.new(k*.8,k*.9,0))*CFrame.Angles(.08,k*.7,-.12),pino:Lerp(mar,.09*k),Enum.Material.Grass)
	end
end
local puerto=modelo("Velas del refugio")
for j,x in {93,108,120} do
	local z=-11.2
	pilar(puerto,Vector3.new(x,19.8,z),6.3,madera)
	pieza(puerto,"Grímpola",Vector3.new(.16,1.8,4),CFrame.new(x,26.3,z+1.8)*CFrame.Angles(-.12,0,0),if j==1 then oro else mar,Enum.Material.Fabric,false,"WedgePart")
end
local cuevas=modelo("Agujas de la geoda")
for j=1,7 do
	local x=285+j*7.4;local z=if j%2==1 then -23 else 23
	risca(cuevas,Vector3.new(x,22,z),Vector3.new(5,9,7),j*31)
	pieza(cuevas,"Cristal estriado",Vector3.new(1.3,5+j%3,1.5),CFrame.new(x,27,z)*CFrame.Angles(.16,j,.21),uva,Enum.Material.Glass)
end
local ruinas=modelo("Costillas del faro")
for j=1,4 do
	local x=77+j*6.2
	pilar(ruinas,Vector3.new(x,18.15,94.2),4.5+j%2*1.7,roca)
end
for _,r in {{-17,14,22,12},{3,14,-26,10},{82,13,17,9},{132,13,31,9},{151,14,40,12},{83,13,55,10}} do
	risca(obras,Vector3.new(r[1],r[2],r[3]),Vector3.new(r[4],6,9),r[1]%37)
end
obras.Parent=isla
return "Archipiélago construido"
