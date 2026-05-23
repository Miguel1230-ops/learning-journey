// ========== DÍA 3 — Objetos ==========

let cliente = {
    nombre: "Carlos",
    negocio: "Restaurante El Buen Sabor",
    problema: "No tiene página web",
    presupuesto: 100,
    ciudad: "Managua"
}

console.log(cliente.nombre)
console.log(cliente.negocio)
console.log("Problema a resolver: " + cliente.problema)
console.log("Puede pagar: $" + cliente.presupuesto)

// ========== Array de objetos + for ==========

let clientes = [
    {
        nombre: "Carlos",
        negocio: "Restaurante",
        presupuesto: 100
    },
    {
        nombre: "María",
        negocio: "Farmacia",
        presupuesto: 75
    },
    {
        nombre: "José",
        negocio: "Academia",
        presupuesto: 150
    }
]

for (let i = 0; i < clientes.length; i++) {
    console.log("Cliente: " + clientes[i].nombre)
    console.log("Negocio: " + clientes[i].negocio)
    console.log("Presupuesto: $" + clientes[i].presupuesto)
    console.log("---")
}

// ========== Función con return — cotizador web ==========

function calcularPrecioWeb(paginas, tieneDiseno, urgente) {
    let precioBase = 75

    if (paginas > 3) {
        precioBase = precioBase + 50
    }

    if (tieneDiseno === true) {
        precioBase = precioBase + 30
    }

    if (urgente === true) {
        precioBase = precioBase * 1.5
    }

    return precioBase
}

console.log(calcularPrecioWeb(2, false, false))
console.log(calcularPrecioWeb(5, true, false))
console.log(calcularPrecioWeb(3, true, true))
