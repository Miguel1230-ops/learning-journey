local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormacionEcos = require(ReplicatedStorage:WaitForChild("FormacionEcos"))

-- El ejemplar que sale del farol pasa directamente a su puesto en la formación.
local LuceroCompaneros = {}
LuceroCompaneros.__index = LuceroCompaneros

function LuceroCompaneros.new(isla, plantilla, farol, muelle, aspas)
	local carpeta = Instance.new("Folder")
	carpeta.Name = "CompanerosLucero"
	carpeta.Parent = isla
	local pared = RaycastParams.new()
	pared.FilterType = Enum.RaycastFilterType.Include
	pared.FilterDescendantsInstances = {farol.Parent:WaitForChild("Torre")}
	pared.RespectCanCollide = true
	local haciaMuelle = (muelle.Position-farol.Position) * Vector3.new(1,0,1)
	local caraAspas = aspas:WaitForChild("Rueda de hierro").Position - aspas:GetPivot().Position
	return setmetatable({
		carpeta = carpeta, plantilla = plantilla, farol = farol, pared = pared,
		haciaMuelle = haciaMuelle.Unit, frenteAspas = (caraAspas*Vector3.new(1,0,1)).Unit,
		ecos = {}, rescates = {},
	}, LuceroCompaneros)
end

function LuceroCompaneros:despertar(p, comienzo)
	self.rescates[p] = {comienzo = comienzo, personaje = p.Character}
end

function LuceroCompaneros:incorporar(p)
	self.rescates[p] = nil
end

function LuceroCompaneros:retirar(p)
	self:incorporar(p)
	local eco = self.ecos[p]
	if eco then
		eco.modelo:Destroy()
		self.ecos[p] = nil
	end
end

local function crear(plantilla, p, pose)
	local modelo = plantilla:Clone()
	modelo.Name = tostring(p.UserId)
	modelo:SetAttribute("Propietario", p.UserId)
	modelo:SetAttribute("Eco", "Lucero")
	modelo:PivotTo(pose)
	local alas = {}
	for _, pieza in modelo:GetDescendants() do
		if pieza:IsA("BasePart") then
			pieza.Anchored = true
			pieza.CanCollide, pieza.CanTouch, pieza.CanQuery, pieza.CastShadow = false, false, false, false
			if pieza.Name == "Pluma larga" or pieza.Name == "Punta de pluma" then
				local original = pose:ToObjectSpace(pieza.CFrame)
				local lado = math.sign(original.X)
				table.insert(alas, {pieza = pieza, origen = original, lado = lado, hombro = CFrame.new(lado * .57, .10, 0)})
			end
		end
	end
	return {modelo = modelo, alas = alas}
end

local function suavizar(t)
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function LuceroCompaneros:poseDeRescate(raiz, destino, edad)
	local lampara = self.farol.Position
	local frente = (raiz.Position-lampara) * Vector3.new(1, 0, 1)
	if frente.Magnitude < .2 then frente = raiz.CFrame.RightVector end
	frente = frente.Unit
	local salida = lampara + self.haciaMuelle*.92 + Vector3.yAxis*.23
	local alto = lampara + self.haciaMuelle*1.72 + Vector3.yAxis*3.35
	local surge = suavizar((edad-.94)/.66)
	local viaje = suavizar((edad-1.75)/1.70)
	local pos = salida:Lerp(alto, surge):Lerp(destino.Position, viaje)
	pos += (self.frenteAspas * 1.3 + Vector3.yAxis * 1.35) * math.sin(math.pi*viaje)
	local giro = CFrame.lookAt(Vector3.zero, frente) * CFrame.Angles(0,0,.12*math.sin(math.pi*viaje))
	return CFrame.new(pos) * giro:Lerp(destino.Rotation, viaje)
end

local function abrirAlas(eco, pose, angulo)
	for _, ala in eco.alas do
		local giro = CFrame.Angles(0, 0, ala.lado * angulo)
		ala.pieza.CFrame = pose * ala.hombro * giro * ala.hombro:Inverse() * ala.origen
	end
end

function LuceroCompaneros:actualizar(p, raiz, tiempo, dt)
	if not raiz or not p:GetAttribute("ProgresoListo") or not p:GetAttribute("Lucero") then
		if self.ecos[p] or self.rescates[p] then self:retirar(p) end
		return
	end
	local rescate = self.rescates[p]
	if rescate and (rescate.personaje ~= p.Character or tiempo > rescate.comienzo + 3.55) then
		self:incorporar(p)
		rescate = nil
	end
	local edad = rescate and tiempo - rescate.comienzo
	if edad and edad < .94 then return end
	local eco = self.ecos[p]
	local actual = if eco and not edad then eco.modelo:GetPivot() else nil
	local destino = FormacionEcos.pose("Lucero", raiz.CFrame, tiempo, actual, 1 - math.exp(-dt * 8))
	-- El puesto izquierdo del avatar puede caer dentro de la torre desde el lado del farol.
	if (raiz.Position - self.farol.Position).Magnitude < 20 then
		local origen = raiz.Position + Vector3.yAxis * 1.2
		local delta = destino.Position - origen
		if delta.Magnitude > .05 then
			local impacto = workspace:Raycast(origen,delta,self.pared)
			if impacto then
				destino = CFrame.new(origen + delta.Unit * math.max(0, impacto.Distance - 1)) * destino.Rotation
			end
		end
	end
	local pose
	if edad then
		pose = self:poseDeRescate(raiz, destino, edad)
	else
		pose = destino
	end
	if not eco then
		eco = crear(self.plantilla, p, pose)
		self.ecos[p] = eco
	end
	eco.modelo:PivotTo(pose)
	if edad then
		local apertura = suavizar((edad-1.02)/.56)
		local aleteo = math.sin((edad-1.5)*8) * apertura * .36
		abrirAlas(eco, pose, -.92 * (1-apertura) + aleteo)
		eco.animandoAlas = true
	elseif eco.animandoAlas then
		abrirAlas(eco, pose, 0)
		eco.animandoAlas = nil
	end
	if not eco.modelo.Parent then eco.modelo.Parent = self.carpeta end
end

return LuceroCompaneros
