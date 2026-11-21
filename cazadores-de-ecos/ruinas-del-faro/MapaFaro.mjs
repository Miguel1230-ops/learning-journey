// Piezas editables del faro y de su cámara en Roblox Studio.
const roca = [66, 86, 108];
const pizarra = [35, 52, 76];
const losa = [104, 128, 151];
const cobre = [188, 126, 86];
const oro = [255, 203, 126];
const agua = [141, 232, 218];
const lila = [196, 164, 252];
const cristal = [100, 183, 231];
const matriz = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const material = { liso: 272, neón: 288, piedra: 800, metal: 1088 };
const ejes = ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"];
const prop = (tipo, nombre, valor) =>
  `<${tipo} name="${nombre}">${String(valor).replaceAll("&", "&amp;").replaceAll("<", "&lt;")}</${tipo}>`;

function rz(grados) {
  const a = grados * Math.PI / 180;
  return [Math.cos(a), -Math.sin(a), 0, Math.sin(a), Math.cos(a), 0, 0, 0, 1];
}

export function crearFaro() {
  let contador = 0;

  function nodo(clase, nombre, props, hijos = [], ref = `RBXRuinasFaro${++contador}`) {
    return `<Item class="${clase}" referent="${ref}"><Properties>${prop("string", "Name", nombre)}${props.join("")}</Properties>${hijos.join("\n")}</Item>`;
  }

  function pieza(nombre, pos, medida, opciones = {}) {
    const {
      color = roca, tipo = material.piedra, solido = false, opacidad = 0,
      rotacion = matriz, forma = 1, hijos = [], ref,
    } = opciones;
    const [r, g, b] = color;
    const marco = [...pos, ...rotacion].map((v, i) => `<${ejes[i]}>${Number(v.toFixed(7))}</${ejes[i]}>`).join("");
    const dimension = medida.map((v, i) => `<${ejes[i]}>${v}</${ejes[i]}>`).join("");
    return nodo("Part", nombre, [
      `<CoordinateFrame name="CFrame">${marco}</CoordinateFrame>`,
      `<Vector3 name="size">${dimension}</Vector3>`,
      prop("Color3uint8", "Color3uint8", 0xff000000 + r * 0x10000 + g * 0x100 + b),
      prop("bool", "Anchored", true), prop("bool", "CanCollide", solido),
      prop("bool", "CanTouch", false), prop("bool", "CanQuery", solido),
      prop("bool", "CastShadow", opacidad < 0.9 && tipo !== material.neón),
      prop("float", "Transparency", opacidad), prop("token", "Material", tipo),
      prop("token", "shape", forma), prop("token", "TopSurface", 0), prop("token", "BottomSurface", 0),
    ], hijos, ref);
  }

  function luz([r, g, b], brillo, alcance, activa = false) {
    return nodo("PointLight", "Luz", [
      `<Color3 name="Color"><R>${r / 255}</R><G>${g / 255}</G><B>${b / 255}</B></Color3>`,
      prop("float", "Brightness", brillo), prop("float", "Range", alcance), prop("bool", "Enabled", activa),
    ]);
  }

  const metal = (nombre, pos, tam, ops = {}) => pieza(nombre, pos, tam, { color: cobre, tipo: material.metal, ...ops });
  const brillo = (nombre, pos, tam, ops = {}) => pieza(nombre, pos, tam, { color: agua, tipo: material.neón, ...ops });
  const marcador = (nombre, pos, tam = [0.4, 0.4, 0.4]) => pieza(nombre, pos, tam, { opacidad: 1 });
  const carpeta = (nombre, hijos) => nodo("Folder", nombre, [], hijos);
  const disco = (nombre, p, diametro, ancho, opciones = {}) =>
    pieza(nombre, p, [ancho, diametro, diametro], { forma: 2, rotacion: rz(90), ...opciones });

  const plataformas = [
    pieza("Plataforma de llegada", [87, 16.7, 52], [22, 2.6, 16], { solido: true }),
    pieza("Estratos de llegada", [87, 13.35, 52], [18.8, 4.25, 12.5], { color: pizarra, solido: true }),
    pieza("Terraza de la linterna", [91, 16.7, 85], [34, 2.6, 22], { solido: true }),
    pieza("Estratos de la terraza", [91, 13.35, 85], [30.5, 4.15, 19.8], { color: pizarra, solido: true }),
    pieza("Roca suspendida", [91.5, 10.5, 85], [23, 2.1, 17.3], { color: roca, solido: true }),
    pieza("Suelo de la cámara", [68.5, 16.8, 85], [11.9, 2.4, 11.1], { color: pizarra, solido: true }),
    disco("Sello de llegada", [87, 18.07, 52.8], 6.4, 0.14, { color: losa, tipo: material.metal }),
    disco("Sello del espejo", [92, 18.08, 86], 5.1, 0.16, { color: cobre, tipo: material.metal }),
  ];
  for (const lado of [-1, 1]) {
    for (let i = 0; i < 4; i++) {
      const x = 87 + lado * (7.6 + (i % 2) * 1.5);
      const z = 45.2 + 4.15 * i;
      plataformas.push(pieza("Pilar erosionado", [x, 19.55 + i * 0.16, z], [1.53, 3.1 + i * 0.32, 1.62], { color: pizarra, solido: true }));
      plataformas.push(metal("Remate antiguo", [x, 21.15 + i * 0.32, z], [1.77, 0.14, 1.8], { solido: true }));
    }
  }

  const pasos = [62.36, 66.98, 71.62].map((z, i) =>
    pieza(`Peldaño${i + 1}`, [87 + (i % 2) * 0.4, 17.67, z], [6.85, 0.66, 4.78],
      { color: agua, tipo: material.neón, opacidad: 1 }));
  const reflejo = "RBXRuinasFaroPivoteEspejo";
  const espejo = nodo("Model", "Espejo", [prop("Ref", "PrimaryPart", reflejo)], [
    pieza("Centro", [92, 21.85, 86], [0.18, 0.18, 0.18], { opacidad: 1, ref: reflejo }),
    metal("Marco del espejo", [92, 21.85, 86.24], [3.55, 3.25, 0.24], { rotacion: rz(45) }),
    brillo("Espejo pulido", [92, 21.85, 86.03], [3.16, 2.86, 0.16], { color: cristal, rotacion: rz(45), opacidad: 0.3 }),
    brillo("Marca central", [92, 21.85, 85.92], [0.31, 0.34, 0.09], { color: oro, rotacion: rz(45) }),
  ]);
  const torre = [
    disco("Zócalo del faro", [101, 18.35, 88], 8.6, 0.7, { color: pizarra }),
    disco("Torre de roca", [101, 23.45, 88], 6.3, 10.15, { color: roca }),
    disco("Banda inferior", [101, 19.52, 88], 6.52, 0.25, { color: cobre, tipo: material.metal }),
    disco("Anillo alto", [101, 27.45, 88], 6.57, 0.31, { color: losa }),
    disco("Balcón de la linterna", [101, 29.0, 88], 9.08, 0.5, { color: pizarra }),
    disco("Corona del faro", [101, 34.55, 88], 8.32, 0.55, { color: cobre, tipo: material.metal }),
    disco("Techo del faro", [101, 35.09, 88], 6.75, 0.58, { color: pizarra }),
    disco("Cúpula", [101, 35.66, 88], 4.6, 0.65, { color: roca }),
    metal("Aguja", [101, 36.72, 88], [0.29, 2.19, 0.29]),
    pieza("Ventanilla", [97.94, 24.35, 88], [0.16, 2.15, 0.91], { color: cristal, tipo: material.liso, opacidad: 0.3 }),
  ];
  for (let i = 0; i < 8; i++) {
    const a = i * Math.PI / 4;
    const p = [101 + Math.cos(a) * 2.76, 31.74, 88 + Math.sin(a) * 2.76];
    torre.push(metal("Nervadura", p, [0.22, 5.1, 0.22]));
  }

  const camara = [
    pieza("Muro exterior", [62.9, 22.05, 85], [0.95, 8.1, 11.5], { color: pizarra, solido: true }),
    pieza("Muro norte", [68.45, 22.05, 79.35], [11.3, 8.1, 0.9], { color: pizarra, solido: true }),
    pieza("Muro sur", [68.45, 22.05, 90.65], [11.3, 8.1, 0.9], { color: pizarra, solido: true }),
    pieza("Cubierta de la cámara", [68.55, 26.46, 85], [11.95, 0.9, 12], { color: roca, solido: true }),
    metal("Umbral de bronce", [74.3, 18.13, 85], [1.24, 0.25, 10.5]),
    metal("Dintel de la cámara", [74.3, 25.75, 85], [1.3, 0.45, 10.4]),
    disco("Pedestal de Prisma", [67.3, 18.65, 85], 4.1, 1.3, { color: roca }),
    disco("Aro de Prisma", [67.3, 19.35, 85], 3.45, 0.23, { color: cobre, tipo: material.metal }),
    brillo("Cristal de la cámara", [68.8, 21.85, 81.2], [0.61, 2.43, 0.55], { color: lila, rotacion: rz(-22), hijos: [luz(lila, 0.8, 10, true)] }),
    brillo("Cristal de la cámara", [68.1, 21.45, 88.8], [0.73, 1.62, 0.64], { color: agua, rotacion: rz(24) }),
  ];

  return nodo("Model", "RuinasDelFaro", [], [
    marcador("Despegue", [86.6, 20.12, 19.3], [6.5, 0.2, 5.45]),
    marcador("Llegada", [87, 20.6, 53], [21.5, 7, 16]),
    marcador("Rastro", [87, 20.55, 57.5]),
    marcador("Girar", [92, 20.5, 84.55]),
    marcador("Montura", [86.2, 20.5, 90.8]),
    marcador("Regreso", [80.8, 20.6, 49.4]),
    marcador("SalidaTerraza", [105, 20.55, 78.9]),
    brillo("Guía de despegue", [86.6, 20.07, 20.4], [4.75, 0.08, 1.18], { opacidad: 0.39 }),
    brillo("Guía de salida", [80.8, 20.58, 49.4], [0.44, 0.83, 0.44], { color: oro, rotacion: rz(37) }),
    brillo("Guía de salida", [105, 20.53, 78.9], [0.44, 0.83, 0.44], { color: oro, rotacion: rz(37) }),
    brillo("Veta", [74.77, 22.1, 85], [0.52, 1.91, 1.18], { color: lila, opacidad: 0.25, hijos: [luz(lila, 1.8, 13)] }),
    brillo("Linterna", [101, 31.98, 88], [3.06, 3.35, 3.09], { color: cristal, tipo: material.liso, forma: 0, opacidad: 0.27, hijos: [luz(oro, 3, 37)] }),
    pieza("Puerta", [74.32, 22, 85], [0.47, 8, 10.28], { color: lila, tipo: material.liso, solido: true, opacidad: 0.49 }),
    brillo("Prisma", [67.3, 21.5, 85], [1.69, 2.12, 1.33], { color: lila, rotacion: rz(43), hijos: [luz(lila, 2.3, 17, true)] }),
    metal("Anclaje para la lente", [86.2, 20.5, 90.8], [2.25, 1.9, 0.66]),
    brillo("Aro de la lente", [86.2, 20.55, 90.35], [1.3, 1.27, 0.35], { color: oro, opacidad: 0.45, rotacion: rz(45) }),
    metal("Pie del espejo", [92, 19.17, 86], [1.12, 2.25, 1.1]),
    espejo, carpeta("Escalones", pasos), carpeta("Plataformas", plataformas),
    carpeta("Torre", torre), carpeta("Camara", camara),
  ]);
}
