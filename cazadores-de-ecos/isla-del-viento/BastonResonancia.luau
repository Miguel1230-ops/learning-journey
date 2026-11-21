-- El servidor anima el mismo bastón que ven el atacante y los demás jugadores.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Baston = {}
local equipados = {}
local madera = Color3.fromRGB(91, 65, 54)
local laton = Color3.fromRGB(219, 166, 88)
local luz = Color3.fromRGB(141, 255, 230)
local rad = math.rad

local function pieza(modelo, nombre, medida, marco, material, color)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = nombre, medida, marco
	p.Material, p.Color = material, color
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless = false, false, false, false, true
	p.Parent = modelo
	return p
end

function Baston.equipar(personaje)
	if not personaje then return nil end
	if equipados[personaje] then return equipados[personaje] end
	local mano = personaje:FindFirstChild("RightHand") or personaje:FindFirstChild("Right Arm")
	local torso = personaje:FindFirstChild("UpperTorso") or personaje:FindFirstChild("Torso")
	if not mano or not torso then return nil end
	local modelo = Instance.new("Model")
	modelo.Name = "BastonDeResonancia"
	local agarre = CFrame.new(0, if mano.Name == "Right Arm" then -0.94 else -0.14, -0.15) * CFrame.Angles(rad(-17), 0, rad(-11))
	local mango = pieza(modelo, "Asta", Vector3.new(.19, 4.2, .22), mano.CFrame * agarre, Enum.Material.Wood, madera)
	modelo.PrimaryPart = mango
	local function tallar(nombre, medida, offset, material, color)
		local p = pieza(modelo, nombre, medida, mango.CFrame * offset, material, color)
		local union = Instance.new("WeldConstraint")
		union.Part0, union.Part1, union.Parent = mango, p, p
		return p
	end
	for _,y in {-1.94, -.34, .34, 1.88} do
		tallar("Anillo", Vector3.new(.27,.14,.29), CFrame.new(0,y,0), Enum.Material.Metal, laton)
	end
	for _,lado in {-1,1} do
		tallar("Diapasón", Vector3.new(.11,.70,.17), CFrame.new(lado*.18,2.20,0)*CFrame.Angles(0,0,rad(-lado*24)), Enum.Material.Metal, laton)
	end
	tallar("Geoda", Vector3.new(.41,.54,.41), CFrame.new(0,2.66,0)*CFrame.Angles(0,rad(45),rad(35)), Enum.Material.Neon, luz)
	local raiz, punta = Instance.new("Attachment"), Instance.new("Attachment")
	raiz.Position, punta.Position = Vector3.new(0,.6,0), Vector3.new(0,2.94,0)
	raiz.Parent, punta.Parent = mango, mango
	local estela = Instance.new("Trail")
	estela.Attachment0, estela.Attachment1 = raiz, punta
	estela.Enabled, estela.FaceCamera, estela.LightEmission = false, true, .8
	estela.Lifetime, estela.MinLength = .20, .025
	estela.Color = ColorSequence.new(luz, Color3.fromRGB(244, 212, 122))
	estela.Transparency = NumberSequence.new(.2, 1)
	estela.Parent = mango
	local grip = Instance.new("Motor6D")
	grip.Name, grip.Part0, grip.Part1, grip.C0, grip.Parent = "Empuñadura", mano, mango, agarre, mango
	local hombro = personaje:FindFirstChild("RightShoulder", true) or torso:FindFirstChild("Right Shoulder")
	local cintura = personaje:FindFirstChild("Waist", true)
	local e = {modelo = modelo, mango = mango, estela = estela, juntas = {}, orden = 0}
	for i,j in {grip, hombro, cintura} do
		if j and j:IsA("Motor6D") then e.juntas[i] = {motor=j, base=j.C0} end
	end
	equipados[personaje] = e
	local function limpiar()
		if equipados[personaje] ~= e then return end
		equipados[personaje] = nil
		if e.muerte then e.muerte:Disconnect() end
		for _,j in e.juntas do
			if j.tween then j.tween:Cancel() end
			if j.motor.Parent then j.motor.C0 = j.base end
		end
	end
	e.limpiar = limpiar
	modelo.Destroying:Once(limpiar)
	local humanoide = personaje:FindFirstChildOfClass("Humanoid")
	if humanoide then
		e.muerte = humanoide.Died:Once(function()
			if equipados[personaje] == e then Baston.quitar(personaje) end
		end)
	end
	modelo.Parent = personaje
	return e
end

function Baston.quitar(personaje)
	local e = personaje and equipados[personaje]
	if e then
		e.limpiar()
		e.modelo:Destroy()
	end
end

function Baston.enArco(root, punto, alcance)
	local d = punto - root.Position
	if d.Magnitude > alcance or math.abs(d.Y) > 5.5 then return false end
	local plano = Vector3.new(d.X,0,d.Z)
	local frente = root.CFrame.LookVector * Vector3.new(1,0,1)
	return plano.Magnitude < .65 or (frente.Magnitude > .01 and frente.Unit:Dot(plano.Unit) >= .34)
end

local function postura(e, duracion, giros)
	for i,j in e.juntas do
		if not j.motor.Parent then continue end
		if j.tween then j.tween:Cancel() end
		local r = giros[i] or CFrame.identity
		local destino = CFrame.new(j.base.Position) * r * j.base.Rotation
		j.tween = TweenService:Create(j.motor, TweenInfo.new(duracion,Enum.EasingStyle.Quad,Enum.EasingDirection.Out), {C0=destino})
		j.tween:Play()
	end
end

function Baston.golpear(root, impacto, guardar)
	local personaje = root.Parent
	local e = Baston.equipar(personaje)
	if not e then return end
	e.orden += 1
	local orden = e.orden
	local function vigente()
		local h = personaje:FindFirstChildOfClass("Humanoid")
		return e.modelo.Parent == personaje and root.Parent == personaje and h and h.Health > 0 and e.orden == orden
	end
	postura(e,.11,{CFrame.Angles(rad(-52),0,rad(-38)),CFrame.Angles(rad(73),rad(-33),rad(41)),CFrame.Angles(0,rad(-21),0)})
	task.delay(.11,function()
		if not vigente() then return end
		e.estela.Enabled = true
		postura(e,.16,{CFrame.Angles(rad(-76),0,rad(43)),CFrame.Angles(rad(89),rad(64),rad(-23)),CFrame.Angles(0,rad(30),rad(-5))})
	end)
	task.delay(.20,function()
		if vigente() then impacto() end
	end)
	task.delay(.30,function()
		if not vigente() then return end
		e.estela.Enabled = false
		postura(e,.24,{})
	end)
	if guardar then
		task.delay(1.3,function()
			if vigente() and guardar() then Baston.quitar(personaje) end
		end)
	end
end

function Baston.impacto(punto, tipo, efectos)
	local cristal = tipo == "Cristal"
	local color = if cristal then luz elseif tipo == "Armadura" then laton else Color3.fromRGB(255, 172, 126)
	local chispa = pieza(efectos, "Impacto"..tipo, Vector3.one*.48, CFrame.new(punto), Enum.Material.Neon, color)
	chispa.Anchored, chispa.Shape = true, Enum.PartType.Ball
	local sonido = Instance.new("Sound")
	sonido.SoundId = if cristal then "rbxasset://sounds/volume_slider.ogg" else "rbxasset://sounds/action_jump_land.mp3"
	sonido.Volume, sonido.PlaybackSpeed, sonido.RollOffMaxDistance = .45, if cristal then 1.48 else 1.35, 56
	sonido.Parent = chispa
	sonido:Play()
	TweenService:Create(chispa,TweenInfo.new(.2),{Size=Vector3.one*(if cristal then 2.3 else 1.35),Transparency=1}):Play()
	Debris:AddItem(chispa,1.5)
end

return Baston
