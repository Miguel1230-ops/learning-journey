-- Ejecutar desde el cliente de Studio con un perfil de sesión recién creado.
local p = game.Players.LocalPlayer
assert(game:GetService("RunService"):IsStudio() and p:GetAttribute("ModoGuardado") == "Sesion")
assert(not p:GetAttribute("Cometa") and not p:GetAttribute("VigiasDerrotados"))
local isla = workspace.IslaDelViento
local char = p.Character
local root = char.HumanoidRootPart
local entrada = game.UserInputService:CreateVirtualInput()

local function esperar(condicion, segundos, mensaje)
	local limite = os.clock() + segundos
	repeat
		if condicion() then return end
		task.wait()
	until os.clock() >= limite
	error(mensaje)
end

local function acercarse(posicion, hacia)
	char:PivotTo(CFrame.lookAt(posicion, Vector3.new(hacia.X, posicion.Y, hacia.Z)))
	root.AssemblyLinearVelocity = Vector3.zero
end

local totem = isla.Totem
acercarse(totem.Position + Vector3.new(-2.5, 1.5, 0), totem.Position)
workspace.CurrentCamera.CFrame = CFrame.lookAt(totem.Position + Vector3.new(4, 4, 6), totem.Position)
task.wait(.65)
totem.Accion:InputHoldBegin()
task.wait(totem.Accion.HoldDuration + .15)
totem.Accion:InputHoldEnd()
esperar(function() return p:GetAttribute("FaseNido") == "Defensa" end, 3, "No se inició la defensa")

local function golpear(vigia, vidas, maximas)
	local cartel = vigia.PrimaryPart.Vida
	local texto = cartel:FindFirstChildOfClass("TextLabel")
	esperar(function() return cartel.Enabled end, 3, "No llegó " .. vigia.Name)
	esperar(function()
		return workspace:GetServerTimeNow() > (p:GetAttribute("RafagaListaEn") or 0) + .08
	end, 3, "El bastón no volvió a estar listo")
	local function apuntar()
		local objetivo = vigia:GetPivot().Position
		local lado = Vector3.new(isla.Nido.Base.Position.X - objetivo.X, 0, isla.Nido.Base.Position.Z - objetivo.Z)
		if lado.Magnitude < .1 then lado = Vector3.xAxis end
		acercarse(Vector3.new(objetivo.X, 23.65, objetivo.Z) + lado.Unit * 5, objetivo)
	end
	apuntar()
	task.wait(.18)
	local seguir = game:GetService("RunService").Heartbeat:Connect(apuntar)
	local punto = workspace.CurrentCamera.ViewportSize * .51
	entrada:SendMouseButton(punto, Enum.UserInputType.MouseButton1, true, 0)
	task.wait(.06)
	entrada:SendMouseButton(punto, Enum.UserInputType.MouseButton1, false, 0)
	task.wait(.20)
	seguir:Disconnect()
	if vidas == 0 then
		esperar(function() return not cartel.Enabled end, 2, "Golpe final a " .. vigia.Name)
	else
		local esperado = ("%s  %d/%d"):format(vigia.Name, vidas, maximas)
		esperar(function() return texto.Text == esperado end, 2, "Falta el golpe no letal a " .. vigia.Name)
		local detenido = vigia:GetPivot().Position
		task.wait(.41)
		assert((vigia:GetPivot().Position - detenido).Magnitude < .25, "Se movió durante el aturdimiento")
	end
end

golpear(isla.Vigias.Embestidor, 1, 2)
golpear(isla.Vigias.Embestidor, 0, 2)
golpear(isla.Vigias.Rompenidos, 2, 3)
golpear(isla.Vigias.Rompenidos, 1, 3)
golpear(isla.Vigias.Rompenidos, 0, 3)
esperar(function() return p:GetAttribute("VigiasDerrotados") end, 3, "Falta la victoria")
return "Dos vigías, tres impactos no letales con aturdimiento y victoria."
