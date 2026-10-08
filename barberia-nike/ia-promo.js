async function generarPromo() {
    let input = document.getElementById("promoInput")
    let idea = input.value
    let resultado = document.getElementById("resultadoPromo")
    let boton = document.getElementById("btnPromo")

    // Validación local inmediata
    if (idea.trim() === "") {
        resultado.textContent = "Por favor escribe una idea para la promoción."
        return
    }

    if (idea.length > 200) {
        resultado.textContent = "La idea es muy larga (máximo 200 caracteres)."
        return
    }

    // Desactivamos el botón mientras carga
    boton.disabled = true
    boton.textContent = "Generando..."
    resultado.textContent = "Generando anuncio con IA para Barbería Nike... 💈🤖"

    try {
        let respuesta = await fetch("/.netlify/functions/generar", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ idea: idea })
        })

        let datos = await respuesta.json()

        if (!respuesta.ok) {
            resultado.textContent = datos.error || "Ocurrió un error al generar el anuncio."
        } else {
            resultado.textContent = datos.texto
        }
    } catch (error) {
        resultado.textContent = "No se pudo conectar. Revisa tu conexión a internet e intenta de nuevo."
    } finally {
        // Pase lo que pase (éxito o error), reactivamos el botón
        boton.disabled = false
        boton.textContent = "Generar anuncio"
    }
}

document.getElementById("btnPromo").addEventListener("click", generarPromo)