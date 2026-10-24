let clientes = [
    {
        nombre: "Carlos",
        negocio: "toluca bar",
        presupuesto: 100
    },
    
    {
        nombre: "Rodrigo",
        negocio: "farmalab",
        presupuesto: 200
    },
   
    {
        nombre: "Ivonne",
        negocio: "Ivonne's restaurant",
        prespuesto: 70
    },
    
    {
        nombre: "Miguel",
        negocio: "Code & more",
        presupuesto: 50
    }
];

let clientesViables = clientes.filter(function(cliente) {
    return cliente.presupuesto > 70;
});
console.log(clientesViables);

let resumenClientes = clientesViables.map(function(cliente) {
    return "Cliente: " + cliente.nombre + " (" + cliente.negocio + ") - Presupuesto: $" + cliente.presupuesto;
});
console.log(resumenClientes);

resumenClientes.forEach(function(texto) {
    console.log("👉 " + texto);
});