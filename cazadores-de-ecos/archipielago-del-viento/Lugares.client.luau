local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UI = require(game.ReplicatedStorage:WaitForChild("BitacoraUI"))
local p = Players.LocalPlayer
local isla = workspace:WaitForChild("IslaDelViento")
local lugares = {
	Isla = {"Isla del Viento","Viento",Color3.fromRGB(151,236,209)},
	Geoda = {"Cueva de la Geoda","Geoda",Color3.fromRGB(220,193,255)},
	Molino = {"Molino del Viento","Molino",Color3.fromRGB(255,213,142)},
	Refugio = {"Refugio del Viento","Brujula",Color3.fromRGB(255,213,142)},
	Faro = {"Ruinas del Faro","Faro",Color3.fromRGB(255,221,168)},
	Nido = {"Nido de tormenta","Nimbo",Color3.fromRGB(186,224,255)},
}
local gui = Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder = "NombresDelArchipielago",false,14
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = p:WaitForChild("PlayerGui")
local banda = Instance.new("CanvasGroup")
banda.Name,banda.AnchorPoint,banda.BackgroundTransparency = "NombreDelLugar",Vector2.new(.5,0),1
banda.Size,banda.Visible,banda.Parent = UDim2.new(1,-20,0,78),false,gui
local limite = Instance.new("UISizeConstraint")
limite.MaxSize,limite.Parent = Vector2.new(420,78),banda
local centro = Instance.new("Frame")
centro.AnchorPoint,centro.Position,centro.Size = Vector2.new(.5,0),UDim2.fromScale(.5,0),UDim2.fromOffset(27,27)
centro.BackgroundTransparency,centro.Parent = 1,banda
local titulo=Instance.new("TextLabel")
titulo.Name,titulo.BackgroundTransparency,titulo.TextScaled = "Nombre",1,true
titulo.Font,titulo.TextColor3,titulo.TextStrokeColor3,titulo.TextStrokeTransparency = Enum.Font.Garamond,Color3.fromRGB(255,251,237),Color3.fromRGB(13,27,38),.18
titulo.Size,titulo.Position,titulo.Parent=UDim2.new(1,0,0,41),UDim2.fromOffset(0,26),banda
local maxTexto=Instance.new("UITextSizeConstraint")
maxTexto.MinTextSize,maxTexto.MaxTextSize,maxTexto.Parent=20,38,titulo
local function filete(lado)
	local linea=Instance.new("Frame")
	linea.BorderSizePixel=0
	linea.Size=UDim2.new(.25,0,0,2)
	linea.Position=UDim2.new(.5,lado*23,0,13)
	linea.AnchorPoint=Vector2.new(if lado<0 then 1 else 0,.5)
	linea.Parent=banda
	local gradiente=Instance.new("UIGradient")
	gradiente.Rotation=if lado<0 then 180 else 0
	gradiente.Transparency=NumberSequence.new(.04,1)
	gradiente.Parent=linea
	return linea
end
local izquierdo,derecho=filete(-1),filete(1)
local vistos={}
local arte,visibleHasta,desvanecer
local zonaAnterior,llegada=nil,0
local function lugar(raiz)
	if p:GetAttribute("EnCueva") then return "Geoda" end
	if p:GetAttribute("EnMolino") then return "Molino" end
	if p:GetAttribute("EnFaro") then
		local etapa=p:GetAttribute("RescateNimbo")
		return if etapa=="Nido" or etapa=="Rescatado" or etapa=="Eclosion" then "Nido" else "Faro"
	end
	local refugio=isla:FindFirstChild("RefugioDelViento")
	local farero=refugio and refugio:FindFirstChild("PuntoFarero")
	if farero and (raiz.Position-farero.Position).Magnitude<24 then return "Refugio" end
	local inicio=isla:FindFirstChild("Inicio")
	if inicio and (raiz.Position-inicio.Position).Magnitude<55 then return "Isla" end
	return nil
end
local function ocultar()
	if desvanecer then desvanecer:Cancel();desvanecer=nil end
	banda.Visible=false
	visibleHasta=nil
end
local function presentar(id,ahora)
	local datos=lugares[id]
	if arte then arte:Destroy() end
	arte=UI.icono(centro,datos[2],27,datos[3])
	titulo.Text=datos[1]
	izquierdo.BackgroundColor3,derecho.BackgroundColor3=datos[3],datos[3]
	local cam=workspace.CurrentCamera
	local pequena=cam and (cam.ViewportSize.X<780 or cam.ViewportSize.Y<440)
	banda.Position=if pequena then UDim2.new(.5,0,.43,-30) else UDim2.new(.5,0,0,18)
	banda.GroupTransparency=if GuiService.ReducedMotionEnabled then 0 else 1
	banda.Visible=true
	visibleHasta=ahora+2.3
	if not GuiService.ReducedMotionEnabled then
		desvanecer=TweenService:Create(banda,TweenInfo.new(.25),{GroupTransparency=0})
		desvanecer:Play()
	end
	vistos[id]=true
end
local acumulado=0
RunService.Heartbeat:Connect(function(dt)
	acumulado+=dt
	if acumulado<.14 then return end
	acumulado=0
	local ahora=os.clock()
	local c=p.Character
	local r=c and c:FindFirstChild("HumanoidRootPart")
	local id=if r and p:GetAttribute("ProgresoListo") then lugar(r) else nil
	if id~=zonaAnterior then zonaAnterior,llegada=id,ahora;ocultar() end
	if not id then return end
	if id=="Molino" and p:GetAttribute("MolinoPresentando") then vistos[id]=true end
	if p:GetAttribute("BitacoraAbierta") or p:GetAttribute("MolinoPresentando") or p:GetAttribute("GeodaPresentando")
		or p:GetAttribute("RescateNimbo")=="Eclosion" or p:GetAttribute("FaseNido")=="Defensa" then ocultar();return end
	if not vistos[id] and ahora-llegada>.85 then presentar(id,ahora) end
	if visibleHasta and ahora>=visibleHasta then
		if GuiService.ReducedMotionEnabled or ahora>=visibleHasta+.35 then ocultar()
		elseif banda.GroupTransparency<=.01 then
			desvanecer=TweenService:Create(banda,TweenInfo.new(.28),{GroupTransparency=1})
			desvanecer:Play()
		end
	end
end)
