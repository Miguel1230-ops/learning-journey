// Lista de precios de la barbería
let precios = [150, 200, 180, 90, 250];

// forEach: solo recorre y muestra en la consola
console.log("--- 1. Recorrido con forEach ---");
precios.forEach(function(precio) {
    console.log("Servicio disponible a: C$ " + precio);
});

// 2. map: Aplica un 10% de descuento (precio *0.9) a todos y crea una lista nueva
console.log("\n--- 2. Lista con Descuento (map) ---");
let preciosConDescuento = precios.map(function(precio) {
    return precio * 0.9;
});
console.log(preciosConDescuento);

// 3. FILTER: filtra solo los servicios premium (mayores a C$150)
console.log("\n--- 3. Servicios Premium (filter) ---");
let serviciosCaros = precios.filter(function(precio) {
    return precio > 150;
});
console.log(serviciosCaros);

// ==========================================
// 4. APLICACIÓN REAL: Lista de Clientes
// ==========================================

let negocios = [
    { nombre: "Carlos", negocio: "Restaurante El Buen Sabor", presupuesto: 120 },
    { nombre: "Lucía", negocio: "Salón Belleza Total", presupuesto: 50 },
    { nombre: "Mateo", negocio: "Barbería Nike", presupuesto: 180 },
    { nombre: "Ivonne", negocio: "Comidería Ivonne", presupuesto: 200 },
    { nombre: "Ana", negocio: "Pulpería La Bendición", presupuesto: 40 }
];

// PASO A: Con FILTER, encontramos solo los clientes con presupuesto mayor a $70 (clientes viables)
let clientesViables = negocios.filter(function(cliente) {
    return cliente.presupuesto > 70;
});

console.log("\n--- Clientes con presupuesto > $70 (filter) ---");
console.log(clientesViables);

// PASO B: Con MAP, transformamos esa lista en mensajes listos para presentar
let resumenClientes = clientesViables.map(function(cliente) {
    return "Cliente: " + cliente.nombre + " (" + cliente.negocio + ") - Presupuesto: $" + cliente.presupuesto;
});

console.log("\n--- Lista formateada con MAP ---");
console.log(resumenClientes);

// PASO C: Con FOREACH, los mostramos uno por uno de forma limpia
console.log("\n--- Presentación Final con FOREACH ---");
resumenClientes.forEach(function(texto) {
    console.log("👉 " + texto);
});