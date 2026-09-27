const API_KEY = "TU_API_KEY_AQUI"
 // Pegas tu clave real aquí

async function generarDescripcion() {
    let negocio = document.getElementById("nombreNegocio").value
    let resultado = document.getElementById("resultado")
    
    if (negocio.trim() === "") {
        resultado.textContent = "Por favor escribe el nombre de un negocio."
        return
    }
    
    resultado.textContent = "Pensando descripción con IA... 🤖"
    
    try {
        let respuesta = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + API_KEY,
            {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{
                        parts: [{ text: "Escribe una descripción corta y atractiva (máximo 2 oraciones) para un negocio en Nicaragua llamado " + negocio }]
                    }]
                })
            }
        )
        
        let datos = await respuesta.json()
        console.log("Respuesta de la API:", datos)

        if (datos.error) {
            resultado.textContent = "Error de API: " + datos.error.message
            return
        }
        
        let texto = datos.candidates[0].content.parts[0].text
        resultado.textContent = texto
    } catch (error) {
        console.error(error)
        resultado.textContent = "Ocurrió un error al consultar la IA (revisa F12)."
    }
}

document.getElementById("btnGenerar").addEventListener("click", generarDescripcion)
