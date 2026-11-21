-- Prueba de integración para el cliente de Studio, en una sesión local.
-- Preparar un perfil con Cometa junto a la entrada de la cueva, sin un combate activo.
local run = game:GetService("RunService")
assert(run:IsStudio() and run:IsClient())
local p = game.Players.LocalPlayer
assert(p:GetAttribute("ModoGuardado") == "Sesion" and p:GetAttribute("EnCueva"))
local c = workspace.CuevaDeLaGeoda
local g, remoto = c.Guardian,game.ReplicatedStorage.AccionGeoda
local ch = p.Character
local root = ch.HumanoidRootPart
local function colocar(posicion, direccion)
	local horizontal = direccion*Vector3.new(1,0,1)
	ch:PivotTo(CFrame.lookAt(posicion,posicion+horizontal.Unit))
	root.AssemblyLinearVelocity = Vector3.zero
end
local function usar(prompt)
	assert(prompt.Enabled)
	local punto = prompt.Parent.Position
	colocar(punto+Vector3.new(-2.6,1.9,1.2),Vector3.new(2.6,0,-1.2))
	workspace.CurrentCamera.CFrame=CFrame.lookAt(punto+Vector3.new(4,4,6),punto)
	task.wait(.6)
	prompt:InputHoldBegin()
	task.wait(prompt.HoldDuration+.09)
	prompt:InputHoldEnd()
	task.wait(.4)
end
local function cerca(distancia, mirar)
	local f = g:GetPivot()
	local frente = (f.LookVector*Vector3.new(1,0,1)).Unit
	local punto = Vector3.new(f.X,23.25,f.Z)+frente*distancia
	colocar(punto, (f.Position-punto)*(if mirar then 1 else -1))
end
usar(c.Totem.Accion)
if c:GetAttribute("Fase")=="Presentacion" then remoto:FireServer("OmitirIntroGuardian");task.wait(.45) end
assert(c:GetAttribute("Fase")=="Combate" and ch:FindFirstChild("BastonDeResonancia"))
local nulo, aciertos = 0,0
local limite=os.clock()+90
while c:GetAttribute("Fase")=="Combate" and os.clock()<limite do
	local estado = c:GetAttribute("EstadoGuardian")
	if estado=="Acecha" then cerca(7,true)
	elseif estado=="Aviso" then remoto:FireServer("Cometa");task.wait(.18)
	elseif estado=="PrepararBarrido" or estado=="Barrido" then cerca(-7,true)
	elseif estado=="Expuesto" then
		local vida=c:GetAttribute("VidaGuardian")
		if nulo < 3 then
			-- Frente, espalda mirando al exterior, y fuera de alcance, respectivamente.
			local dist = if nulo==0 then 6 elseif nulo==1 then -6 else -17
			cerca(dist,nulo~=1)
			task.wait(.21)
			remoto:FireServer("GolpeBaston")
			task.wait(.97)
			assert(c:GetAttribute("VidaGuardian")==vida, "Se aceptó un golpe inválido "..nulo)
			nulo+=1
		end
		if c:GetAttribute("EstadoGuardian")=="Expuesto" then
			cerca(-6,true)
			task.wait(.20)
			remoto:FireServer("GolpeBaston")
			remoto:FireServer("GolpeBaston")
			task.wait(.49)
			local despues=c:GetAttribute("VidaGuardian")
			assert(vida-despues<=1, "Un clic duplicado causó dos impactos")
			if despues==vida-1 then aciertos+=1 end
		end
	end
	task.wait(.06)
end
assert(c:GetAttribute("Fase")=="Gana" and aciertos==3 and nulo==3,"Resolución incompleta")
assert(not ch:FindFirstChild("BastonDeResonancia"),"Soltar el bastón al ganar")
assert(c.Geoda.Punto.Accion.Enabled,"Falta recompensa del guardián")
return "Victoria con tres golpes válidos, tres rechazos, duplicados ignorados y geoda habilitada."
