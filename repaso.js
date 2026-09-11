let age = 15;
let name = "Miguel";
let esProgramador = true;

if (age >= 18) {
  console.log(name + " es mayor de edad");
} else {
  console.log(name + " es menor de edad");
}

function calcularPrecio(paginas, urgente) {
  let precio = 150; 

  if (paginas > 3) {
    precio += 150; 
  }
  if (urgente) { 
    precio *= 1.5; 
  }
  return precio;
}

console.log(calcularPrecio(5, true));

let cliente = { 
  nombre: "Miguel",
  negocio: "Nike's barbery",
  presupuesto: 100,
  ciudad: "Managua"
};

console.log(cliente.nombre);
console.log(cliente.negocio);
console.log(cliente.presupuesto);

let Clientes = [
    {
        nombre: "Miguel",
        negocio: "Michael's company",
        presupuesto: 100
    },
    {
        nombre: "Matthew",
        negocio: "Matthew's airlines",
        presupuesto: 150
    },
    {
        nombre: "Ivonne",
        negocio: "Comideria Ivonne",
        presupuesto: 200
    }
    ]

    for (let x = 0; x < Clientes.length; x++) {
    console.log("Cliente: " + Clientes[x].nombre);
    console.log("Negocio: " + Clientes[x].negocio);
    console.log("Presupuesto: " + Clientes[x].presupuesto);
    console.log("---");
}