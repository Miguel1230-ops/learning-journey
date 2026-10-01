const API_KEY = "Tu_API_KEY_AQUI" // Pegas tu clave real para la prueba

async function generarPromo() {
    let idea = document.getElementById("promoInput").value
    let resultado = document.getElementById("resultadoPromo")
    
    if (idea.trim() === "") {
        resultado.textContent = "Por favor escribe una idea para la promoción."
        return
    }
    
    resultado.textContent = "Generando anuncio con IA para Barbería Nike... 💈🤖"
    
    try {
        let respuesta = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + API_KEY,
            {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{
                        parts: [{ text: "Escribe un anuncio de redes sociales muy corto, atractivo y vendedor (máximo 2 oraciones con emojis) para la Barbería Nike en Managua sobre esta promoción: " + idea }]
                    }]
                })
            }
        )
        
        let datos = await respuesta.json()
        
        if (datos.error) {
            resultado.textContent = "Error de API: " + datos.error.message
            return
        }
        
        let texto = datos.candidates[0].content.parts[0].text
        resultado.textContent = texto
    } catch (error) {
        console.error(error)
        resultado.textContent = "Ocurrió un error al conectar con la IA."
    }
}

document.getElementById("btnPromo").addEventListener("click", generarPromo)