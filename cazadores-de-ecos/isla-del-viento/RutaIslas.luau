-- Cada destino se deduce de los hitos del jugador, también al cargar una partida antigua.
local Ruta = {}
local destinos = {
	Aro = {"Aro del Viento", "Salta desde la rampa turquesa y planea a través del aro.", "Cometa siente el viento del aro. Busca la rampa junto al puente levadizo."},
	Cornisa = {"Baliza de la cornisa", "Planea por la espiral azul hacia la baliza.", "Sigue las cintas ascendentes. Enciende la baliza y baja al refugio."},
	Taller = {"Taller del Farero", "Elige el escudo rápido por 60 monedas o sigue hacia el Molino.", "Prueba el escudo en los dos faroles de mi pasarela. En el taller puedo prepararlo para el relevo."},
	Relevo = {"Relevo de los faroles", "Acepta el relevo junto al primer farol. Su chispa te mostrará el camino al Molino.", "Mira la llama. Cuando se incline, cúbrela con Pedernal. Lleva la chispa al segundo farol."},
	Inicio = {"Rescate en la Isla del Viento", "Acércate al tótem para defender el nido y rescatar a Cometa.", "El nido necesita ayuda. Busca el tótem de la Isla del Viento."},
	Refugio = {"Lleva a Cometa al refugio", "Cruza el puente y completa el rescate en la marca del refugio.", "Completa el rescate en la marca junto al puente y ven a verme."},
	Farero = {"Habla con el Farero", "Está bajo el toldo del refugio, junto al portal violeta.", "El viento del Molino te tumbará. Entra en el portal violeta junto a mi puesto y rescata a Pedernal. Su escudo te cubrirá."},
	Geoda = {"Portal de la Geoda", "Encuentra el portal violeta junto al Farero.", "El viento del Molino te tumbará. Entra en el portal violeta junto a mi puesto y rescata a Pedernal. Su escudo te cubrirá."},
	Molino = {"Rumbo al Molino", "Desde la playa de despegue, salta y planea hacia el molino. Lleva a Pedernal.", "Pedernal ya está contigo. Su escudo protegerá la chispa en el Molino."},
	Consulta = {"Vuelve con Lucero al Farero", "El Farero sabe qué falta para explorar las ruinas.", "Lucero puede abrir el Faro, pero el espejo necesita la lente del guardián. El portal de la revancha está aquí al lado."},
	Revancha = {"Recupera la lente", "Entra al portal de la Geoda junto al Farero y gana la revancha.", "Pídele la revancha al guardián. Regresa por la salida verde con la lente."},
	Faro = {"Zarpa hacia las Ruinas", "Habla con el Farero para llegar al punto de despegue.", "¡Traes la lente y a Lucero! Sigue la señal y monta la lente junto al espejo."},
	Nido = {"Nido de tormenta", "Vuelve al Faro con el Farero. Prisma revela los aros que llevan al huevo.", "Prisma ya ilumina el recorrido. El elevador de la torre te llevará hasta el salto."},
	Libre = {"Exploración libre", "Puedes volver a la torre y recorrer los tres aros de Prisma.", "La torre está abierta. Puedes volar de nuevo cuando quieras."},
}
function Ruta.destino(p)
	local id
	if p:GetAttribute("Nimbo") then id = "Libre"
	elseif p:GetAttribute("Prisma") then id = "Nido"
	elseif p:GetAttribute("Lucero") then
		if p:GetAttribute("LenteGeoda") then id = "Faro"
		elseif p:GetAttribute("ConsejoLente") then id = "Revancha"
		else id = "Consulta" end
	elseif p:GetAttribute("Pedernal") then
		if p:GetAttribute("EncargoPedernal") or p:GetAttribute("MolinoVista") then id = "Molino"
		elseif p:GetAttribute("MejoraPedernal") then id = "Relevo"
		elseif (p:GetAttribute("Nivel") or 1) >= 2 and (p:GetAttribute("Monedas") or 0) >= 60 then id = "Taller"
		else id = "Molino" end
	elseif not p:GetAttribute("Cometa") then id = "Inicio"
	elseif not p:GetAttribute("Refugio") and not p:GetAttribute("Vendaval") then id = "Aro"
	elseif not p:GetAttribute("Refugio") and not p:GetAttribute("Cornisa") then id = "Cornisa"
	elseif not p:GetAttribute("Refugio") then id = "Refugio"
	elseif p:GetAttribute("ConsejoGeoda") then id = "Geoda"
	else id = "Farero" end
	return id, destinos[id]
end
return Ruta
