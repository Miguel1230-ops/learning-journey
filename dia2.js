// --- Mis datos ---
let nombre = "Miguel"
let edad = 15
let esProgramador = true
let dinero = 0

console.log("Me llamo " + nombre + " y tengo " + edad + " años")
console.log("¿Programador?", esProgramador)

// --- Edad ---
if (edad >= 18) {
    console.log("Eres mayor de edad")
} else {
    console.log("Eres menor de edad")
}

// --- Meta del millón ---
if (dinero >= 1000000) {
    console.log("Eres millonario")
} else {
    console.log("Sigues luchando por la meta. Vas en: $" + dinero)
}

// --- Función ---
function saludarCliente(nombreDueño, nombreNegocio) {
    console.log("Hola " + nombreDueño + ", puedo ayudar a " + nombreNegocio + " con automatización")
}

// --- Lista de negocios ---
let negocios = ["Hospitales", "Academias", "Iglesias", "Restaurantes", "Farmacias"]

let duenos = ["Dr. López", "Prof. García", "Pastor Ruiz", "Carlos", "María"]

// --- Recorrer y saludar ---
for (let x = 0; x < negocios.length; x++) {
    console.log("Posible cliente: " + negocios[x])
    saludarCliente(duenos[x], negocios[x])
}
