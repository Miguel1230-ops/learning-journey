async function mostrarClima() {
    let respuesta = await fetch("https://api.github.com/users/Miguel1230-ops")
    let datos = await respuesta.json()

    let div = document.getElementById("clima")
    div.textContent = "Repositorios de practica activos " + datos.public_repos
}

mostrarClima()