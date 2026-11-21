-- Los cuatro puestos son relativos al rumbo del avatar. Z positivo queda detrás.
local puestos = {
	Cometa = { sitio = Vector3.new(5, 2.1, 1.4), ritmo = 3.5, amplitud = 0.30 },
	Lucero = { sitio = Vector3.new(-4.7, 2.5, 1.8), ritmo = 3.6, amplitud = 0.22 },
	Pedernal = { sitio = Vector3.new(2.2, 0.2, 6.1), ritmo = 2.6, amplitud = 0.14 },
	Nimbo = { sitio = Vector3.new(-2.1, 4.6, 7.8), ritmo = 3, amplitud = 0.32 },
}

local FormacionEcos = {}

function FormacionEcos.pose(nombre, raiz, tiempo, actual, avance)
	local puesto = puestos[nombre]
	local frente = raiz.LookVector * Vector3.new(1, 0, 1)
	if frente.Magnitude < 0.001 then
		frente = Vector3.yAxis:Cross(raiz.RightVector)
	end
	local marco = CFrame.lookAt(raiz.Position, raiz.Position + frente.Unit)
	local desplazamiento = puesto.sitio + Vector3.yAxis * (math.sin(tiempo * puesto.ritmo) * puesto.amplitud)
	if actual then
		-- Interpolar el centro de la formación hace que cada Eco rodee al avatar al girar.
		local centroAnterior = actual * CFrame.new(-desplazamiento)
		if (centroAnterior.Position - raiz.Position).Magnitude < 55 then
			marco = centroAnterior:Lerp(marco, avance)
		end
	end
	return marco * CFrame.new(desplazamiento)
end

return FormacionEcos
