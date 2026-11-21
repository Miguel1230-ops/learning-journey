-- LocalScript temporal en StarterPlayerScripts, junto a Turnos.pruebas.server.luau.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if not game:GetService("RunService"):IsStudio() then return end
local canal = ReplicatedStorage:WaitForChild("PruebaTurnosExpediciones", 60)
if not canal then return end
local p = Players.LocalPlayer
local visibles = {}
local prompts = game:GetService("ProximityPromptService")
prompts.PromptShown:Connect(function(prompt) visibles[prompt] = true end)
prompts.PromptHidden:Connect(function(prompt) visibles[prompt] = nil end)

local function ejecutar(accion, objeto)
	local raiz = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	assert(raiz and p:GetAttribute("ModoGuardado") == "Sesion", "Falta personaje de prueba")
	if accion == "activar" or accion == "portalOcupado" then
		assert(objeto and objeto:IsA("ProximityPrompt"), "Falta el prompt")
		local lugar = objeto.Parent.Position
		local posicion = lugar + Vector3.new(-2.5, 2, 1.4)
		p.Character:PivotTo(CFrame.lookAt(posicion, Vector3.new(lugar.X, posicion.Y, lugar.Z)))
		raiz.AssemblyLinearVelocity = Vector3.zero
		workspace.CurrentCamera.CFrame = CFrame.lookAt(lugar + Vector3.new(5, 4, 6), lugar)
		local aviso = false
		local escucha
		if accion == "portalOcupado" then
			escucha = ReplicatedStorage.AccionGeoda.OnClientEvent:Connect(function(tipo)
				if tipo == "AvisoPortal" then aviso = true end
			end)
		end
		task.wait(.65)
		assert(objeto.Enabled, "Prompt deshabilitado: " .. objeto:GetFullName())
		local limite = os.clock()+3
		while not visibles[objeto] and os.clock()<limite do
			workspace.CurrentCamera.CFrame = CFrame.lookAt(lugar + Vector3.new(4, 3, 5), lugar)
			task.wait(.08)
		end
		assert(visibles[objeto], "El cliente no mostró "..objeto:GetFullName().." a "..math.round((raiz.Position-lugar).Magnitude).." studs")
		objeto:InputHoldBegin()
		task.wait(math.max(.18, objeto.HoldDuration + .14))
		objeto:InputHoldEnd()
		if escucha then
			local limite = os.clock() + 4
			repeat task.wait(.05) until aviso or os.clock() >= limite
			escucha:Disconnect()
			assert(aviso, "El segundo jugador no recibió el aviso de ocupación")
		end
	elseif accion == "fichaLucero" then
		local limite = os.clock()+4
		local hud = p.PlayerGui:WaitForChild("RefugioHUD",3)
		repeat task.wait(.04) until (p:GetAttribute("FichaRescateLucero") or 0)>0 or os.clock()>limite
		local ficha = hud:WaitForChild("Aviso"):WaitForChild("AbrirFicha")
		repeat task.wait(.04) until (ficha.Visible and ficha.Parent.Visible) or os.clock()>limite
		assert(p:GetAttribute("FichaRescateLucero")==1 and ficha.Visible and ficha.Parent.Visible, "Falta la ficha única de Lucero")
		assert(not p:GetAttribute("MolinoPresentando"),"La ficha llegó antes de devolver la cámara")
		assert(ficha.Parent.Titulo.Text == "Lucero" and ficha.Parent.Detalle.Text:find("+50 monedas",1,true)
			and ficha.Parent.Detalle.Text:find("+70 EXP",1,true), "Texto incompleto de la ficha")
		local retrato = ficha.Parent.Sello.RetratoLucero
		assert(retrato.Visible and retrato.CurrentCamera, "Falta el retrato de Lucero en la ficha")
	elseif accion == "sinFichaInicial" then
		assert((p:GetAttribute("FichaRescateLucero") or 0)==0 and p:GetAttribute("Lucero"),"La carga del perfil fingió un rescate")
	elseif accion == "escudo" then
		ReplicatedStorage.AccionMolino:FireServer("Escudo")
	elseif accion == "lucero" then
		ReplicatedStorage.AccionFaro:FireServer("Lucero")
	else
		error("Acción desconocida: " .. tostring(accion))
	end
end

canal.OnClientEvent:Connect(function(numero, accion, objeto)
	local ok, mensaje = pcall(ejecutar, accion, objeto)
	canal:FireServer(numero, ok, tostring(mensaje or ""))
end)
canal:FireServer(0, true, "listo")
