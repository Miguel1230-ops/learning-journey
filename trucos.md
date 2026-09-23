function nombre(dato) {
  // qué hace
  return resultado
}

-------
array

let lista = ["a", "b"]
lista[0]
lista.push("c")
lista.length

-------
HTML minimo

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title></title>
  <link rel="stylesheet" href="estilos.css">
</head>
<body>
</body>
</html>

-------
flex

.contenedor {
  display: flex;
  flex-direction: row;      /* eje principal: → o ↓ */
  justify-content: ...;    /* reparte en el eje principal */
  align-items: ...;        /* alinea en el eje cruzado */
  gap: 16px;
}

--------
Leyes fundamentales de CSS
────────────────────────────────────────────┐
│ 1. MODELO DE CAJA (Box Model)                             │
│    Todo elemento HTML es una caja con 4 capas:            │
│    Contenido ➔ Padding ➔ Borde ➔ Margen                    │
├───────────────────────────────────────────────────────────┤
│ 2. LA CASCADA Y ESPECIFICIDAD                             │
│    El sistema de puntos que decide qué regla gana         │
│    cuando dos estilos se contradicen.                     │
├───────────────────────────────────────────────────────────┤
│ 3. EL FLUJO Y POSICIONAMIENTO (Display & Flexbox)         │
│    Cómo viajan los elementos: ¿en bloque (uno debajo de   │
│    otro) o en línea (uno al lado de otro)?                │
└───────────────────────────────────────────────────────────┘

🥊 width vs padding: ¿Cuál es la diferencia?
Imagina una caja de zapatos con un par de tenis adentro:

width (El tamaño del contenido):
Es el tamaño únicamente de los tenis (el texto).
Determina cuándo el texto tiene que saltar a la siguiente línea porque ya no cabe a lo ancho.
padding (El espacio de aire / relleno interno):
Es el espacio que hay entre los tenis y las paredes de la caja.
Evita que el texto choque y quede aplastado contra el borde negro.

width: Controla el ancho del texto.
padding: Controla el espacio interno alrededor del texto para que no choque con el borde.

 El Desempate: La Especificidad (Los Rangos de Poder)
Pero, ¿qué pasa si las reglas usan selectores diferentes? Ahí entra el sistema de jerarquías. No todas las reglas tienen el mismo peso:

Selector	En CSS	Nivel de Poder	Analogía
Etiqueta	p { ... }	🥉 1 punto	"Un mensaje para todos los ciudadanos"
Clase	.especial { ... }	🥈 10 puntos	"Una orden para los policías del grupo"
ID	#unico { ... }	🥇 100 puntos	"Una orden directa del Presidente con nombre y DNI"

📌 Regla de oro: El que tiene más puntos de poder SIEMPRE GANA, sin importar si está arriba o abajo en el archivo CSS.