exports.handler = async function(event) {
    if(event.httpMethod !== "POST") {
        return {
            statusCode: 405,
            body: JSON.stringify({ error: "Método no permitido"})

        }
    }
    
    try {
        const body = JSON.parse(event.body || "{}")
        const idea = body.idea

        if (!idea) {
            return {
                statusCode: 400,
                body: JSON.stringify({error: "Por favor proporciona una idea de promoción."})
            }
        }

        const respuesta = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + process.env.GEMINI_API_KEY,
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

    const datos = await respuesta.json()

    if (datos.error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: datos.error.message })
        }
    }

    const texto = datos.candidates[0].content.parts[0].text

    return {
        statusCode: 200,
        headers: {"Content-Type": "application/json" },
        body: JSON.stringify({ texto: texto })
  }
    } catch(error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message || "Error en el servidor"  })
        }
    }
}