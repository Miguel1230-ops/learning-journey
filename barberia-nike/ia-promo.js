async function generarPromo() {
    let idea = document.getElementById("promoInput").value
    let resultado = document.getElementById("resultadoPromo")
    
    if (idea.trim() === "") {
        resultado.textContent = "Por favor escribe una idea para la promoción."
        return
    }
    
    resultado.textContent = "Generando anuncio con IA para Barbería Nike... 💈🤖"
    
    try {
        let respuesta = await fetch("/.netlify/functions/generar", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ idea: idea })
        })
        
        let datos = await respuesta.json()
        
        if (datos.error) {
            resultado.textContent = "Error: " + datos.error
            return
        }
        
        resultado.textContent = datos.texto
    } catch (error) {
        console.error(error)
        resultado.textContent = "Ocurrió un error al conectar con el servidor."
    }
}

document.getElementById("btnPromo").addEventListener("click", generarPromo)