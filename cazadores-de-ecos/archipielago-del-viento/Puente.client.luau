local p=game:GetService("Players").LocalPlayer
local TweenService=game:GetService("TweenService")
local isla=workspace:WaitForChild("IslaDelViento")
local puente=isla:WaitForChild("ObrasDelArchipielago"):WaitForChild("PuenteLevadizo")
local oeste,este=puente.HojaOeste,puente.HojaEste
local bases={oeste:GetPivot(),este:GetPivot()}
local avance=Instance.new("NumberValue")
local function dibujar(valor)
	oeste:PivotTo(bases[1]*CFrame.Angles(0,0,math.rad(72*valor)))
	este:PivotTo(bases[2]*CFrame.Angles(0,0,math.rad(-72*valor)))
end
avance.Changed:Connect(dibujar)
local ultimo,animacion
local function actualizar()
	local abierto=p:GetAttribute("VigiasDerrotados")==true or p:GetAttribute("Cometa")==true
	if abierto==ultimo then return end
	if animacion then animacion:Cancel() end
	local objetivo=if abierto then 0 else 1
	if ultimo~=nil and abierto and not game:GetService("GuiService").ReducedMotionEnabled then
		animacion=TweenService:Create(avance,TweenInfo.new(1.35,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Value=objetivo})
		animacion:Play()
	else avance.Value=objetivo; dibujar(objetivo) end
	ultimo=abierto
end
p:GetAttributeChangedSignal("VigiasDerrotados"):Connect(actualizar)
p:GetAttributeChangedSignal("Cometa"):Connect(actualizar)
actualizar()
