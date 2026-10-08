exports.handler = async function(event) {
    if(event.httpMethod !== "POST") {
        return {
            statusCode: 405,
            body: JSON.stringify({ error: "Método no permitido"})

        }
    }
    
    try {
        const body = JSON.parse(event.body || "{}")
        const idea = (body.idea || "").trim()

        // 1. Escudo de validación de entrada

        if (idea === "" || idea.length > 200) {
            return {
                statusCode: 400,
                body: JSON.stringify({error: "Por favor proporciona una idea de hasta 200 caracteres."})
            }
        }

        // 2. Llamada a Gemini con limite de tokens para porteger cuota
        const respuesta = await fetch(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=" + process.env.GEMINI_API_KEY,
            {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{
                        parts: [{ text: "Escribe un anuncio de redes sociales muy corto, atractivo y vendedor (máximo 2 oraciones con emojis) para la Barbería Nike en Managua sobre esta promoción: " + idea }]
                    }],
                    generationConfig: {
                        maxOutputTokens: 200
                    }
                })
            }
        )

        if (!respuesta.ok) {
            return {
                statusCode: 502,
                body: JSON.stringify({error: "El servicio de Inteligencia Artificial no respondió. Intenta en un momento"})
            }
        }

    const datos = await respuesta.json()
    const texto = datos.candidates[0].content.parts[0].text

        return {
         statusCode: 200,
         headers: {"Content-Type": "application/json" },
         body: JSON.stringify({ texto: texto })
  }
    } catch(error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Algo salió mal en el servidor, intenta de nuevo"  })
        }
    }
 }