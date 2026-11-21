// Piezas originales y editables de la plataforma del molino.
const color = {
  roca: [64, 80, 96],
  sombra: [43, 58, 76],
  pizarra: [79, 105, 119],
  piedra: [113, 144, 147],
  musgo: [75, 134, 118],
  verde: [64, 103, 103],
  madera: [127, 91, 65],
  vigas: [75, 65, 61],
  bronce: [172, 125, 77],
  patina: [49, 103, 112],
  agua: [123, 206, 212],
  tejido: [196, 224, 218],
  crema: [255, 236, 179],
  oro: [255, 201, 101],
  ascua: [241, 149, 71],
  dormida: [94, 137, 145],
  grafito: [29, 43, 56],
};

const material = { liso: 272, neon: 288, metal: 1088, roca: 896, pizarra: 800, madera: 512, tabla: 528 };
const identidad = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const esc = (v) => String(v).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
const prop = (tipo, nombre, v) => `<${tipo} name="${nombre}">${esc(v)}</${tipo}>`;
const b = (n, v) => prop("bool", n, v);
const f = (n, v) => prop("float", n, v);
const token = (n, v) => prop("token", n, v);
const xyz = (n, v) => `<Vector3 name="${n}"><X>${v[0]}</X><Y>${v[1]}</Y><Z>${v[2]}</Z></Vector3>`;
const rgb = (n, v) => `<Color3 name="${n}"><R>${v[0] / 255}</R><G>${v[1] / 255}</G><B>${v[2] / 255}</B></Color3>`;
const rad = (grados) => grados * Math.PI / 180;
const num = (n) => Math.abs(n) < 1e-8 ? 0 : Number(n.toFixed(7));
const suma = (a, d) => a.map((v, i) => v + d[i]);

function rotarY(grados) {
  const a = rad(grados);
  return [Math.cos(a), 0, Math.sin(a), 0, 1, 0, -Math.sin(a), 0, Math.cos(a)];
}

function rotarZ(grados) {
  const a = rad(grados);
  return [Math.cos(a), -Math.sin(a), 0, Math.sin(a), Math.cos(a), 0, 0, 0, 1];
}

function marco(p, giro = identidad) {
  const valores = [...p, ...giro];
  const nombres = ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"];
  return `<CoordinateFrame name="CFrame">${nombres.map((n, i) => `<${n}>${num(valores[i])}</${n}>`).join("")}</CoordinateFrame>`;
}

export function crearMolino() {
  let indice = 0;

  function nodo(clase, nombre, props = [], hijos = [], id = "RBXMolino" + ++indice) {
    const contenido = prop("string", "Name", nombre) + props.join("");
    return `<Item class="${clase}" referent="${id}"><Properties>${contenido}</Properties>${hijos.length ? "\n" + hijos.join("\n") + "\n" : ""}</Item>`;
  }

  const carpeta = (nombre, hijos) => nodo("Folder", nombre, [], hijos);
  const modelo = (nombre, hijos, principal) => nodo("Model", nombre, principal ? [prop("Ref", "PrimaryPart", principal)] : [], hijos);
  const luz = (tono, brillo, rango, encendida = true) => nodo("PointLight", "Luz", [
    rgb("Color", tono), f("Brightness", brillo), f("Range", rango), b("Enabled", encendida), b("Shadows", false),
  ]);

  function pieza(n, p, s, opciones = {}) {
    const c = opciones.c ?? color.roca;
    const solido = opciones.solido ?? false;
    return nodo("Part", n, [
      marco(p, opciones.giro), xyz("size", s), prop("Color3uint8", "Color3uint8", 0xff000000 + c[0] * 0x10000 + c[1] * 0x100 + c[2]),
      b("Anchored", true), b("CanCollide", solido), b("CanTouch", false), b("CanQuery", opciones.consulta ?? solido),
      b("CastShadow", opciones.sombra ?? solido), f("Transparency", opciones.t ?? 0),
      token("Material", opciones.m ?? material.pizarra), token("TopSurface", 0), token("BottomSurface", 0),
      token("shape", opciones.forma ?? 1),
    ], opciones.hijos ?? [], opciones.id);
  }

  const disco = (n, p, diametro, grosor, opciones = {}) => pieza(n, p, [grosor, diametro, diametro],
    { ...opciones, forma: 2, giro: rotarZ(90) });
  const esfera = (n, p, s, opciones = {}) => pieza(n, p, s, { ...opciones, forma: 0 });
  const oculto = (n, p, s) => pieza(n, p, s, { t: 1 });
  const neón = (n, p, s, c, opciones = {}) => pieza(n, p, s, { c, m: material.neon, ...opciones });

  const suelo = [
    pieza("Andén de llegada", [9, 16.45, 63], [22, 3.1, 20], { solido: true }),
    pieza("Plataforma del farol", [43.5, 16.45, 69], [19, 3.1, 18], { solido: true }),
    pieza("Suelo del paso de viento", [27, 16.84, 67.5], [14.25, 2.32, 11], { solido: true, c: color.pizarra }),
    pieza("Estrato de llegada", [8, 13.3, 63.7], [20.7, 3.7, 17], { c: color.sombra, m: material.roca, giro: rotarY(7) }),
    pieza("Estrato del molino", [44.4, 12.72, 68.5], [17.1, 5.5, 15.5], { c: color.sombra, m: material.roca, giro: rotarY(-8) }),
    pieza("Base profunda del molino", [44, 8.6, 69], [11.8, 4.25, 12], { c: color.roca, m: material.roca, giro: rotarY(9) }),
    pieza("Ménsula del paso", [27, 14.26, 68.4], [16, 2.46, 6.8], { c: color.sombra, m: material.roca, giro: rotarY(-3) }),
  ];
  for (let i = 0; i < 8; i++) {
    const x = 20.95 + i * 1.72;
    suelo.push(pieza("Tabla de la pasarela", [x, 18.04, 67.5], [1.42, 0.13, 10.45],
      { c: i % 3 === 0 ? color.madera : color.vigas, m: material.tabla }));
  }

  for (const z of [62.16, 72.84]) {
    suelo.push(
      pieza("Borde del paso", [27, 18.35, z], [14.3, 0.7, 0.35], { solido: true, c: color.sombra, m: material.roca }),
      pieza("Pasamano del paso", [27, 20.12, z], [14.3, 0.17, 0.28], { solido: true, c: color.agua, m: material.metal }),
    );
    for (const x of [19.94, 23.46, 27, 30.54, 34.04]) {
      suelo.push(
        pieza("Pilar del viento", [x, 19.27, z], [0.42, 2.54, 0.42], { solido: true, c: color.roca }),
        pieza("Clavo del pasamano", [x, 20.51, z], [0.33, 0.17, 0.33], { c: color.bronce, m: material.metal }),
      );
    }
  }

  for (const [x, z, angulo] of [[3, 61, -18], [4.2, 55.5, 13], [16.3, 57.6, 5], [16.5, 70.9, -6], [37, 74.1, 16], [50.4, 74.4, -8]]) {
    suelo.push(
      pieza("Placa de musgo", [x, 18.01, z], [3.6, 0.08, 1.6], { c: color.musgo, giro: rotarY(angulo) }),
      pieza("Veta de piedra", [x + 0.45, 18.1, z - 1.23], [1.8, 0.22, 0.62], { c: color.piedra, giro: rotarY(angulo + 37) }),
    );
  }

  const balizas = [];
  for (const [i, z] of [24.9, 26.4, 27.88].entries()) {
    for (const lado of [-1, 1]) {
      balizas.push(neón("Flecha del despegue", [10 + lado * 0.42, 20.078, z], [0.86, 0.045, 0.13],
        i === 2 ? color.crema : color.agua, { giro: rotarY(-lado * 27), t: i * 0.07 }));
    }
  }
  for (const x of [6.2, 13.8]) {
    balizas.push(
      pieza("Hito de despegue", [x, 20.75, 26.65], [0.69, 1.49, 0.69], { c: color.roca, giro: rotarY(45) }),
      neón("Remate de despegue", [x, 21.53, 26.65], [0.43, 0.43, 0.43], color.agua, { giro: rotarZ(45), t: 0.19 }),
    );
  }
  for (const x of [2.4, 17.5]) {
    balizas.push(
      pieza("Mojón de llegada", [x, 19.25, 54.35], [1.05, 2.5, 0.94], { c: color.sombra, giro: rotarY(21) }),
      pieza("Marco de llegada", [x, 20.43, 54.35], [0.94, 0.92, 0.65], { c: color.bronce, giro: rotarZ(45) }),
      neón("Guía de aterrizaje", [x, 20.43, 53.98], [0.61, 0.61, 0.26], color.agua, { giro: rotarZ(45) }),
    );
  }

  const pedestal = [
    disco("Suelo grabado", [10, 18.055, 65], 7.9, 0.07, { c: color.piedra }),
    disco("Grada del pedestal", [10, 18.25, 65], 4.5, 0.46, { c: color.sombra, m: material.roca }),
    disco("Pedestal de la chispa", [10, 18.87, 65], 3.25, 0.86, { c: color.roca, m: material.roca }),
    disco("Aro del pedestal", [10, 19.32, 65], 3.46, 0.12, { c: color.bronce, m: material.metal }),
    disco("Nido de la chispa", [10, 19.46, 65], 2.98, 0.17, { c: color.grafito }),
  ];
  for (let i = 0; i < 9; i++) {
    const a = i * 2 * Math.PI / 9;
    pedestal.push(neón("Marca del nido", [10 + Math.cos(a) * 2.79, 18.113, 65 + Math.sin(a) * 2.79],
      [0.28, 0.034, 0.28], color.dormida, { giro: rotarY(i * 40 + 45), t: 0.35 }));
  }

  const torre = [
    disco("Cimentación del molino", [45, 18.65, 73.25], 13.4, 1.3, { c: color.sombra, m: material.roca, solido: true }),
    disco("Friso inferior", [45, 19.45, 73.25], 12.7, 0.39, { c: color.bronce, m: material.metal }),
    disco("Cuerpo de piedra", [45, 24.62, 73.25], 11.2, 10.0, { c: color.pizarra, m: material.pizarra, solido: true }),
    disco("Friso circular", [45, 28.11, 73.25], 11.37, 0.31, { c: color.verde }),
    disco("Cuerpo alto", [45, 31.38, 73.25], 10.36, 4.3, { c: color.roca, m: material.pizarra, solido: true }),
    disco("Cornisa del molino", [45, 33.6, 73.25], 12.3, 0.62, { c: color.vigas, m: material.madera }),
    disco("Alero", [45, 34.22, 73.25], 13.5, 0.8, { c: color.patina, m: material.metal }),
    disco("Cubierta inferior", [45, 34.88, 73.25], 11.95, 0.72, { c: color.patina, m: material.metal }),
    disco("Cubierta media", [45, 35.51, 73.25], 9.92, 0.67, { c: color.patina, m: material.metal }),
    disco("Cubierta superior", [45, 36.1, 73.25], 8.17, 0.61, { c: color.patina, m: material.metal }),
    disco("Cubierta del pináculo", [45, 36.63, 73.25], 6.15, 0.55, { c: color.verde, m: material.metal }),
    disco("Corona del molino", [45, 37.21, 73.25], 4.25, 0.65, { c: color.bronce, m: material.metal }),
    pieza("Veleta central", [45, 38.55, 73.25], [0.29, 2.26, 0.29], { c: color.bronce, m: material.metal }),
    pieza("Punta de veleta", [44.28, 39.4, 73.25], [1.45, 0.46, 0.2], { c: color.bronce, m: material.metal, giro: rotarZ(18) }),
    pieza("Cola de veleta", [45.73, 39.31, 73.25], [1.34, 0.56, 0.19], { c: color.agua, m: material.metal, giro: rotarZ(-18) }),
    pieza("Placa de la entrada", [45, 21.75, 67.54], [2.67, 4.27, 0.35], { c: color.bronce, m: material.metal }),
    pieza("Portón entablado", [45, 21.76, 67.32], [2.28, 3.88, 0.17], { c: color.madera, m: material.tabla }),
    esfera("Pomo del portón", [45.69, 21.87, 67.17], [0.28, 0.28, 0.24], { c: color.crema, m: material.metal }),
    disco("Umbral del molino", [45, 18.08, 67.05], 4.4, 0.19, { c: color.roca }),
  ];
  for (const [x, y] of [[42.47, 26.4], [47.53, 26.4], [45, 30.5]]) {
    torre.push(
      pieza("Ventana de latón", [x, y, 68], [1.18, 1.7, 0.72], { c: color.bronce, m: material.metal }),
      pieza("Vidrio del molino", [x, y, 67.58], [0.83, 1.28, 0.16], { c: color.dormida, m: material.liso }),
      pieza("Parteluz", [x, y, 67.45], [0.08, 1.29, 0.17], { c: color.sombra }),
    );
  }

  const centroAspas = [45, 31.95, 67.05];
  const aspas = [
    pieza("Eje", centroAspas, [1.55, 1.55, 1.77], { id: "RBXMolinoEje", c: color.bronce, giro: rotarZ(45), m: material.metal }),
    pieza("Rueda de hierro", suma(centroAspas, [0, 0, -0.82]), [2.19, 2.19, 0.32], { c: color.vigas, giro: rotarZ(45) }),
    pieza("Medallón", suma(centroAspas, [0, 0, -1.06]), [1.07, 1.07, 0.29], { c: color.crema, giro: rotarZ(45), m: material.metal }),
  ];
  for (const base of [22.5, 112.5, 202.5, 292.5]) {
    const a = rad(base);
    const pos = (distancia, costado, z) => suma(centroAspas,
      [Math.cos(a) * distancia - Math.sin(a) * costado, Math.sin(a) * distancia + Math.cos(a) * costado, z]);
    aspas.push(
      pieza("Brazo de cedro", pos(4.8, 0, 0), [9, 0.38, 0.49], { c: color.vigas, m: material.madera, giro: rotarZ(base) }),
      pieza("Orilla de la vela", pos(7.27, 1.07, -0.02), [4.37, 0.18, 0.24], { c: color.bronce, m: material.metal, giro: rotarZ(base + 11) }),
      pieza("Vela de lino", pos(7.21, 0.47, 0.06), [4.45, 1.35, 0.19], { c: color.tejido, giro: rotarZ(base + 8), t: 0.04 }),
      pieza("Borde bordado", pos(8.56, 0.97, -0.089), [1.83, 0.21, 0.11], { c: color.agua, giro: rotarZ(base + 11) }),
      pieza("Quilla de la vela", pos(9.25, 0.82, -0.08), [0.25, 2.04, 0.22], { c: color.vigas, giro: rotarZ(base + 9) }),
    );
    for (const d of [5.65, 6.72, 7.79, 8.86]) {
      aspas.push(pieza("Costilla de la vela", pos(d, (d - 4.65) * 0.14, -0.08), [0.12, 1.68, 0.2],
        { c: color.madera, m: material.madera, giro: rotarZ(base + 7) }));
    }
  }

  const marcoFarol = [
    disco("Atril del farol", [39, 18.21, 68], 4.5, 0.41, { c: color.sombra }),
    disco("Columna del farol", [39, 19.04, 68], 1.63, 1.62, { c: color.pizarra, m: material.roca }),
    disco("Plato del farol", [39, 19.91, 68], 2.25, 0.23, { c: color.bronce, m: material.metal }),
    pieza("Capucha del farol", [39, 22.04, 68], [1.91, 0.45, 1.91], { c: color.bronce, m: material.metal, giro: rotarY(45) }),
    pieza("Corona del farol", [39, 22.4, 68], [0.98, 0.33, 0.98], { c: color.patina, m: material.metal, giro: rotarY(45) }),
  ];
  for (const dx of [-0.65, 0.65]) {
    for (const dz of [-0.65, 0.65]) {
      marcoFarol.push(pieza("Marco del farol", [39 + dx, 21, 68 + dz], [0.12, 1.94, 0.12],
        { c: color.bronce, m: material.metal }));
    }
  }

  const anillo = [
    [41.45, 18.26, 71.6], [45.2, 18.26, 63.3], [35.7, 18.26, 67.35],
    [30.7, 20.84, 72.85], [25.2, 20.84, 62.15], [18.75, 18.45, 68.7], [3.66, 18.45, 66.8],
    [-3.8, 20.5, 24.7], [-19.4, 20.5, 25.5], [-31.7, 20.5, 18.4], [-51.5, 20.5, 8.85],
    [-61.75, 20.5, -6.93], [-47.1, 20.5, -7.63], [-34.7, 20.5, -20.7], [-23.5, 20.5, -24.1],
    [-7.55, 20.5, -24.6], [9.3, 20.5, -24.8], [19.7, 20.5, -12.6], [3.25, 20.49, 6.7],
    [16.1, 20.5, 20.8], [27.3, 20.52, 18.38], [39.1, 20.52, 18.38], [52.3, 20.52, 18.38],
    [65.1, 20.52, 18.38], [77.2, 20.5, 20.25], [88.8, 20.5, 11.4],
    [89.4, 20.5, -7.8], [86.4, 33.62, -19.7],
  ];
  const luces = [];
  const soportes = [];
  for (const [i, p] of anillo.entries()) {
    luces.push(neón("Luz" + String(i + 1).padStart(2, "0"), p, [0.39, 0.54, 0.39], color.dormida,
      { giro: rotarZ(25), t: 0.15, hijos: [luz(color.oro, 1.35, 11, false)] }));
    soportes.push(
      pieza("Soporte de luz", suma(p, [0, -0.31, 0]), [0.64, 0.26, 0.64], { c: color.sombra, giro: rotarY(45) }),
      pieza("Aro de latón", suma(p, [0, -0.18, 0]), [0.48, 0.10, 0.48], { c: color.bronce, giro: rotarY(45) }),
    );
  }

  const eco = [39, 24.62, 67.15];
  const lucero = [
    esfera("Cuerpo", eco, [1.7, 1.82, 1.46], { id: "RBXMolinoLucero", c: color.oro, m: material.liso }),
    esfera("Cara", suma(eco, [0, 0.05, -0.6]), [1.37, 1.36, 0.91], { c: color.crema, m: material.liso }),
    pieza("Brillo de la frente", suma(eco, [0, 0.69, -0.62]), [0.31, 0.36, 0.19],
      { c: color.agua, m: material.neon, giro: rotarZ(45) }),
    esfera("Cola de chispa", suma(eco, [0, -0.49, 0.74]), [0.69, 0.61, 0.97], { c: color.ascua, m: material.liso }),
  ];
  for (const lado of [-1, 1]) {
    lucero.push(
      esfera("Ojo", suma(eco, [lado * 0.32, 0.14, -1.025]), [0.23, 0.29, 0.17], { c: color.grafito, m: material.liso }),
      esfera("Reflejo del ojo", suma(eco, [lado * 0.32 - 0.042, 0.21, -1.104]), [0.06, 0.066, 0.05],
        { c: color.crema, m: material.liso }),
      esfera("Mejilla", suma(eco, [lado * 0.46, -0.11, -0.91]), [0.2, 0.12, 0.13], { c: color.ascua, m: material.liso }),
      pieza("Pluma larga", suma(eco, [lado * 0.97, 0.26, 0.04]), [1.06, 0.38, 0.35],
        { c: color.ascua, m: material.liso, giro: rotarZ(lado * 35) }),
      pieza("Punta de pluma", suma(eco, [lado * 1.38, 0.58, 0.03]), [0.46, 0.28, 0.23],
        { c: color.crema, m: material.neon, giro: rotarZ(lado * 48) }),
    );
  }

  return modelo("MolinoDelViento", [
    oculto("PlayaDespegue", [10, 20.15, 25], [6, 0.12, 4]),
    oculto("Llegada", [10, 20.6, 60], [22, 7, 13]),
    oculto("Regreso", [42, 20.5, 64], [0.6, 0.6, 0.6]),
    oculto("ZonaViento", [26.55, 21.5, 67.5], [15.5, 10, 11.6]),
    neón("Chispa", [10, 21, 65], [0.59, 0.73, 0.57], color.oro,
      { giro: rotarZ(45), hijos: [luz(color.oro, 1.32, 8.5)] }),
    neón("Farol", [39, 21, 68], [1.14, 1.41, 1.14], color.dormida,
      { forma: 0, t: 0.25, hijos: [luz(color.oro, 2.5, 21, false)] }),
    modelo("Lucero", lucero, "RBXMolinoLucero"),
    modelo("Aspas", aspas, "RBXMolinoEje"),
    carpeta("Luces", luces),
    carpeta("SoportesDeLuces", soportes),
    modelo("Torre", torre),
    modelo("PasoDelMolino", suelo),
    modelo("FarolAntiguo", marcoFarol),
    modelo("PedestalDeLaChispa", pedestal),
    carpeta("BalizasDeVuelo", balizas),
  ]);
}
