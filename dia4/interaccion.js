let boton = document.getElementById("btnContacto");
let respuesta = document.getElementById("respuesta");
let inputNombre = document.getElementById("nombreCliente");
let inputNegocio = document.getElementById("negocioCliente");

boton.addEventListener("click", function() {
    let nombre = inputNombre.value;
    let negocio = inputNegocio.value;

    if (nombre === "" || negocio === "") {
        respuesta.textContent = "Por favor, completa tu nombre y negocio";
        respuesta.style.color = "red";
    } else {
        respuesta.textContent = "Gracias " + nombre + ", pronto contactaré a " + negocio;
        respuesta.style.color = "#1a1a2e";
    }
});
