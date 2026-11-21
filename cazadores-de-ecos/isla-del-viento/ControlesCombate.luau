-- Observa los clics sin capturar el gesto con el que Roblox gira la cámara.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Controles = {}

local function interfazAbierta()
	local p = Players.LocalPlayer
	local gui = p:FindFirstChildOfClass("PlayerGui")
	local hud = gui and gui:FindFirstChild("RefugioHUD")
	local menu = hud and hud:FindFirstChild("Menu")
	return UIS:GetFocusedTextBox() ~= nil or GuiService.MenuIsOpen or (menu and menu.Visible)
		or p:GetAttribute("GeodaPresentando") or p:GetAttribute("MolinoPresentando")
		or p:GetAttribute("FaroPresentando") or p:GetAttribute("FareroConversando")
end

function Controles.ataque(disponible, golpear)
	UIS.InputBegan:Connect(function(entrada, procesada)
		if entrada.UserInputType == Enum.UserInputType.MouseButton1 and not procesada
			and not interfazAbierta() and disponible() then golpear() end
	end)
end

function Controles.escudoBreve(disponible, proteger)
	local inicio, distancia = nil, 0
	UIS.InputBegan:Connect(function(entrada, procesada)
		if entrada.UserInputType == Enum.UserInputType.MouseButton2 and not procesada
			and not interfazAbierta() and disponible() then
			inicio, distancia = os.clock(), 0
		end
	end)
	UIS.InputChanged:Connect(function(entrada)
		if inicio and entrada.UserInputType == Enum.UserInputType.MouseMovement then
			distancia += Vector2.new(entrada.Delta.X, entrada.Delta.Y).Magnitude
			if distancia > 8 then inicio = nil end
		end
	end)
	UIS.InputEnded:Connect(function(entrada)
		if entrada.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
		local cuando = inicio
		inicio = nil
		if cuando and os.clock() - cuando <= 0.32 and not interfazAbierta() and disponible() then proteger() end
	end)
	UIS.WindowFocusReleased:Connect(function() inicio = nil end)
end

return Controles
