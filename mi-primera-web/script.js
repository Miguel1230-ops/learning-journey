console.log("Página de Miguel cargada")

let servicios = [
    "Automatización de reportes",
    "Páginas web para negocios",
    "Agentes de IA personalizados"
]

console.log("Servicios disponibles:")
for (let i = 0; i < servicios.length; i++) {
    console.log("- " + servicios[i])
}

// Esto calcula cuántos días llevas programando
let fechaInicio = new Date("2026-05-20")
let hoy = new Date()
let diferencia = hoy - fechaInicio
let dias = Math.floor(diferencia / (1000 * 60 * 60 * 24))
console.log("Llevas " + dias + " días programando")
