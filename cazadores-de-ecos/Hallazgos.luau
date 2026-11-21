-- Una tirada de 1 a 100 elige el hallazgo. La marca solar mejora las probabilidades.
local Hallazgos = {}

Hallazgos.variedades = {
	{ nombre = "Eco de Bruma", rareza = "COMÚN", normal = 64, solar = 43, energia = 12, bono = 1, escala = 0.9, color = Color3.fromRGB(125, 236, 209) },
	{ nombre = "Eco de Chispa", rareza = "RARO", normal = 25, solar = 34, energia = 24, bono = 1.25, escala = 1.18, color = Color3.fromRGB(118, 184, 255) },
	{ nombre = "Eco Prisma", rareza = "ÉPICO", normal = 10, solar = 18, energia = 50, bono = 1.6, escala = 1.55, color = Color3.fromRGB(213, 145, 255) },
	{ nombre = "Eco Aurora", rareza = "LEGENDARIO", normal = 1, solar = 5, energia = 120, bono = 2, escala = 2.35, color = Color3.fromRGB(255, 214, 112) },
}

Hallazgos.costoPuente = 50

function Hallazgos.elegir(tirada, conMarca)
	local acumulado = 0
	for indice, variedad in ipairs(Hallazgos.variedades) do
		acumulado += if conMarca then variedad.solar else variedad.normal
		if tirada <= acumulado then
			return variedad, indice
		end
	end
	error("Las probabilidades de los hallazgos deben sumar 100.")
end

function Hallazgos.formatoBono(bono)
	return ("×%g"):format(bono)
end

return Hallazgos
