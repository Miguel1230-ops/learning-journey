-- Ejecutar en el servidor de Studio con los dos ModuleScripts instalados.
-- Cada objeto de prueba vive en este modelo temporal.
local ss = game:GetService("ServerScriptService")
local baston = require(ss:WaitForChild("BastonResonancia"))
local viento = require(ss:WaitForChild("VientoVisual"))
local zona = Instance.new("Folder")
zona.Name = "PruebaTemporalBaston"
zona.Parent = workspace
local function parte(padre, nombre)
	local p = Instance.new("Part")
	p.Name, p.Anchored, p.CanCollide, p.Parent = nombre, true, false, padre
	return p
end
local ok, fallo = pcall(function()
	local root = parte(zona,"RaizPrueba")
	root.CFrame = CFrame.lookAt(Vector3.new(0,400,0), Vector3.new(0,400,-1))
	local pos = root.Position
	assert(baston.enArco(root,pos+Vector3.new(0,0,-8),8), "Borde frontal")
	assert(not baston.enArco(root,pos+Vector3.new(0,0,-8.01),8), "Fuera de alcance")
	assert(not baston.enArco(root,pos+Vector3.new(4,0,0),8), "Costado")
	assert(not baston.enArco(root,pos+Vector3.new(0,0,3),8), "Espalda")
	assert(not baston.enArco(root,pos+Vector3.new(0,5.6,-1),8), "Límite vertical")
	for _,r6 in {true,false} do
		local rig = Instance.new("Model")
		rig.Parent = zona
		local torso = parte(rig,if r6 then "Torso" else "UpperTorso")
		local mano = parte(rig,if r6 then "Right Arm" else "RightHand")
		local portador = parte(rig,"HumanoidRootPart")
		parte(rig,"Head")
		local h = Instance.new("Humanoid")
		h.RequiresNeck, h.BreakJointsOnDeath, h.Parent = false, false, rig
		local hombro = Instance.new("Motor6D")
		hombro.Name,hombro.Part0,hombro.Part1,hombro.Parent = if r6 then "Right Shoulder" else "RightShoulder",torso,mano,torso
		local e = assert(baston.equipar(rig))
		assert(baston.equipar(rig)==e and e.juntas[1].motor.Part0==mano and e.juntas[2].motor==hombro)
		assert(e.estela.Attachment0.Parent==e.mango and e.estela.Attachment1.Parent==e.mango)
		local golpes = 0
		local reposo = hombro.C0
		baston.golpear(portador,function() golpes += 1 end)
		task.wait(.65)
		assert(golpes == 1 and not e.estela.Enabled, "Una resolución por ataque")
		assert(hombro.C0:FuzzyEq(reposo,.001), "Regreso del brazo")
		baston.golpear(portador,function() golpes += 1 end)
		baston.quitar(rig)
		task.wait(.27)
		assert(golpes == 1, "Retirarse antes del impacto cancela el ataque")
		assert(not rig:FindFirstChild("BastonDeResonancia"))
		assert(baston.equipar(rig) ~= e, "Puede reequiparse")
		baston.golpear(portador,function() golpes += 1 end)
		h.Health = 0
		task.wait(.31)
		assert(golpes == 1 and not rig:FindFirstChild("BastonDeResonancia"),"Morir cancela el golpe y suelta el bastón")
	end
	local escudo = parte(zona,"Escudo")
	escudo.Size = Vector3.one*6.5
	viento.escudo(escudo)
	assert(escudo:FindFirstChildOfClass("Beam") and escudo.Transparency < .7)
	local rastro = viento.estela(escudo)
	assert(rastro.Attachment0.Parent==escudo and rastro.Attachment1.Parent==escudo)
end)
zona:Destroy()
assert(ok,tostring(fallo))
return "Arco, alcance, agarres R6/R15, estela y escudo verificados."
