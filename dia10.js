fetch("https://api.github.com/users/Miguel1230-ops")
.then(function(respuesta){
return respuesta.json() // Convierte la respuesta del servidor a un objeto de JS
})

.then(function(datos){
    console.log("--- Datos recibidos de GitHub ---")
    console.log(datos)
    console.log("Nombre de usuario: " + datos.login)
    console.log("Repositorios publicos: " + datos.public_repos)
})


async function obtenerDatosGitHub() {
    console.log("--- Obteniendo datos con async/await ---")
    
    // Espera a que fetch traiga la respuesta
    let respuesta = await fetch("https://api.github.com/users/Miguel1230-ops")
    
    // Espera a convertir la respuesta a datos en JSON
    let datos = await respuesta.json()
    
    console.log("Usuario: " + datos.login)
    console.log("Bio: " + datos.bio)
    console.log("Repositorios públicos: " + datos.public_repos)
}

// Llamamos a la función
obtenerDatosGitHub()