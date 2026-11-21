-- La llama y la chispa reflejan el encargo de este jugador, incluso en una pasarela compartida.
local jugador=game:GetService("Players").LocalPlayer
local GuiService=game:GetService("GuiService")
local refugio=workspace:WaitForChild("IslaDelViento"):WaitForChild("RefugioDelViento")
local inicio=refugio:WaitForChild("InicioEncargo"):WaitForChild("Accion")
local meta=refugio:WaitForChild("MetaEncargo"):WaitForChild("Accion")
local faroles={refugio.Faro1,refugio.Faro2}
local dorado=Color3.fromRGB(255,190,85)
local menta=Color3.fromRGB(144,250,209)
local frio=Color3.fromRGB(110,194,227)
local efectos=Instance.new("Folder",refugio)
efectos.Name="LuzDelRelevo"
local function luz(nombre,dimensiones,color)
	local p=Instance.new("Part")
	p.Name,p.Size,p.Color=nombre,dimensiones,color
	p.Material,p.Shape=Enum.Material.Neon,Enum.PartType.Ball
	p.Anchored,p.CanCollide,p.CanTouch,p.CanQuery,p.CastShadow=true,false,false,false,false
	p.Transparency=1
	p.Parent=efectos
	return p
end
local llamas={}
for i,f in faroles do
	llamas[i]=luz("Mecha",Vector3.new(.38,1.1,.38),dorado)
	llamas[i].CFrame=f.CFrame
end
local chispa=luz("Chispa viajera",Vector3.one*.53,dorado)
local brisas={}
for i=1,5 do brisas[i]=luz("Hebra de viento",Vector3.new(.07,.09,1.7),frio) end
local fase,terminado
local function refrescar()
	fase=jugador:GetAttribute("EstadoEncargo") or ""
	terminado=jugador:GetAttribute("EncargoPedernal")==true
	inicio.Enabled=jugador:GetAttribute("MejoraPedernal")==true and not terminado and fase==""
	meta.Enabled=fase=="Meta"
	for i,f in faroles do
		local encendido=terminado or fase=="Meta" or (i==1 and (fase=="Segundo" or fase=="Reintentar"))
		f.Color=if encendido then menta else dorado
		local l=f:FindFirstChildWhichIsA("Light")
		if l then l.Color=f.Color;l.Brightness=if encendido then 2.2 else .65 end
		llamas[i].Color=f.Color
		llamas[i].Transparency=if encendido or fase~="" then .1 else 1
	end
	chispa.Transparency=if fase=="Segundo" or fase=="Meta" or fase=="Reintentar" then .05 else 1
	for _,b in brisas do b.Transparency=if fase=="Primero" or fase=="Segundo" or fase=="Reintentar" then .4 else 1 end
end
for _,a in {"EstadoEncargo","EncargoPedernal","MejoraPedernal","ProgresoListo"} do jugador:GetAttributeChangedSignal(a):Connect(refrescar) end
refrescar()
while task.wait(.065) do
	if fase=="" then continue end
	local t=workspace:GetServerTimeNow()
	local objetivo=if fase=="Primero" then 1 else 2
	local quieto=GuiService.ReducedMotionEnabled
	for i,f in faroles do
		local angulo=if i==objetivo and fase~="Meta" then (if quieto then .42 else .28+math.sin(t*4)*.25) else 0
		llamas[i].CFrame=CFrame.new(f.Position+Vector3.yAxis*.65)*CFrame.Angles(angulo,0,0)
	end
	local destino=if fase=="Meta" then refugio.MetaEncargo.Position else faroles[2].Position
	local origen=faroles[if fase=="Meta" then 2 else 1].Position
	local u=if quieto then .88 else math.min((t*.57)%1.25,1)
	chispa.Position=origen:Lerp(destino,u)+Vector3.yAxis*(.6+math.sin(u*math.pi)*1.25)
	for i,b in brisas do
		local a=if quieto then i/6 else (t*.9+i*.2)%1
		b.Position=faroles[objetivo].Position+Vector3.new((i-3)*.17,-1.45+math.sin(a*3)*.18,5.8-a*6)
	end
end
