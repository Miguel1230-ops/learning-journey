// Geometría editable del taller y la pasarela del Refugio del Viento.
const color = {
  roca: [60, 79, 93],
  pizarra: [79, 102, 117],
  sombra: [38, 52, 68],
  madera: [106, 75, 57],
  nogal: [74, 57, 53],
  cobre: [186, 126, 70],
  bronce: [105, 104, 95],
  oro: [255, 175, 90],
  crema: [255, 224, 158],
  menta: [117, 228, 197],
  verdin: [55, 140, 139],
  verdeNoche: [38, 100, 112],
  marino: [31, 60, 82],
  lino: [228, 217, 181],
  piel: [162, 109, 80],
  barba: [226, 215, 194],
};
const material = { liso: 272, neón: 288, piedra: 800, granito: 832, tabla: 528, metal: 1088, tela: 1312 };
const identidad = [1, 0, 0, 0, 1, 0, 0, 0, 1];
const seguroXml = (s) => String(s).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
const propiedad = (tipo, nombre, s) => `<${tipo} name="${nombre}">${seguroXml(s)}</${tipo}>`;
const xyz = (nombre, [x, y, z]) => `<Vector3 name="${nombre}"><X>${x}</X><Y>${y}</Y><Z>${z}</Z></Vector3>`;
const rgb = (nombre, [r, g, b]) => `<Color3 name="${nombre}"><R>${r / 255}</R><G>${g / 255}</G><B>${b / 255}</B></Color3>`;
const numero = (n) => Math.abs(n) < 1e-8 ? 0 : Number(n.toFixed(7));
const rad = (grados) => grados * Math.PI / 180;

function rotar(eje, grados) {
  const c = Math.cos(rad(grados));
  const s = Math.sin(rad(grados));
  if (eje === "x") {
    return [1, 0, 0, 0, c, -s, 0, s, c];
  }
  if (eje === "y") {
    return [c, 0, s, 0, 1, 0, -s, 0, c];
  }
  return [c, -s, 0, s, c, 0, 0, 0, 1];
}

function marco(posición, giro) {
  const componentes = [...posición, ...giro];
  const nombres = ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"];
  const valores = nombres.map((nombre, i) => `<${nombre}>${numero(componentes[i])}</${nombre}>`).join("");
  return `<CoordinateFrame name="CFrame">${valores}</CoordinateFrame>`;
}

export function crearRefugio() {
  let consecutivo = 0;

  function nodo(clase, nombre, propiedades, hijos, id = `RBXRefugioDelViento${++consecutivo}`) {
    const atributos = propiedad("string", "Name", nombre) + propiedades.join("");
    return `<Item class="${clase}" referent="${id}"><Properties>${atributos}</Properties>${hijos.join("\n")}</Item>`;
  }

  function modelo(nombre, hijos, principal) {
    return nodo("Model", nombre, principal ? [propiedad("Ref", "PrimaryPart", principal)] : [], hijos);
  }

  function pieza(nombre, posición, tamaño, opciones = {}) {
    const {
      tono = color.roca, acabado = material.piedra, giro = identidad, sólida = false,
      transparencia = 0, forma = 1, id, hijos = [],
    } = opciones;
    const [r, g, b] = tono;
    return nodo("Part", nombre, [
      marco(posición, giro), xyz("size", tamaño),
      propiedad("Color3uint8", "Color3uint8", 0xff000000 + r * 0x10000 + g * 0x100 + b),
      propiedad("bool", "Anchored", true), propiedad("bool", "CanCollide", sólida),
      propiedad("bool", "CanTouch", false), propiedad("bool", "CanQuery", sólida),
      propiedad("bool", "CastShadow", transparencia < 0.5 && acabado !== material.neón),
      propiedad("float", "Transparency", transparencia), propiedad("token", "Material", acabado),
      propiedad("token", "shape", forma), propiedad("token", "TopSurface", 0), propiedad("token", "BottomSurface", 0),
    ], hijos, id);
  }

  function luz(tono, brillo, alcance) {
    return nodo("PointLight", "Luz", [
      rgb("Color", tono), propiedad("float", "Brightness", brillo),
      propiedad("float", "Range", alcance), propiedad("bool", "Enabled", true),
      propiedad("bool", "Shadows", false),
    ], []);
  }

  const metal = (nombre, posición, tamaño, opciones = {}) => pieza(nombre, posición, tamaño,
    { tono: color.cobre, acabado: material.metal, ...opciones });
  const madera = (nombre, posición, tamaño, opciones = {}) => pieza(nombre, posición, tamaño,
    { tono: color.madera, acabado: material.tabla, ...opciones });
  const redondo = (nombre, posición, tamaño, opciones = {}) => pieza(nombre, posición, tamaño, { forma: 0, ...opciones });
  const invisible = (nombre, posición, tamaño) => pieza(nombre, posición, tamaño, { transparencia: 1 });

  const fareroId = "RBXRefugioDelVientoFareroTorso";
  const farero = [
    pieza("Abrigo", [85.8, 22.02, -3.55], [1.29, 1.61, .80],
      { tono: color.marino, acabado: material.tela, id: fareroId }),
    pieza("Sobrehombros", [85.8, 22.58, -3.57], [1.58, .32, .91],
      { tono: color.verdeNoche, acabado: material.tela }),
    pieza("Pañuelo", [85.8, 22.73, -3.47], [.93, .28, .87],
      { tono: color.menta, acabado: material.tela }),
    pieza("Caída del pañuelo", [85.43, 22.38, -3.095], [.29, .59, .16],
      { tono: color.menta, acabado: material.tela, giro: rotar("z", -19) }),
    pieza("Cinturón", [85.8, 21.51, -3.55], [1.33, .21, .83], { tono: color.nogal, acabado: material.tela }),
    metal("Hebilla", [86.05, 21.53, -3.104], [.29, .26, .08]),
    redondo("Rostro", [85.8, 23.23, -3.54], [1.08, 1.10, 1.06], { tono: color.piel, acabado: material.liso }),
    redondo("Nariz", [85.8, 23.19, -2.995], [.25, .25, .19], { tono: color.piel, acabado: material.liso }),
    redondo("Barba", [85.80, 22.98, -3.227], [.86, .51, .48], { tono: color.barba, acabado: material.liso }),
    pieza("Visera", [85.8, 23.69, -3.302], [1.22, .13, 1.04],
      { tono: color.marino, acabado: material.tela, giro: rotar("x", -5) }),
    redondo("Gorra", [85.8, 23.85, -3.56], [1.08, .47, .89], { tono: color.verdeNoche, acabado: material.tela }),
    metal("Insignia", [85.8, 23.81, -3.11], [.18, .19, .06], { giro: rotar("z", 45) }),
  ];
  for (const s of [-1, 1]) {
    farero.push(
      pieza("Bota", [85.8 + s * .36, 20.24, -3.43], [.52, .46, .84], { tono: color.nogal }),
      pieza("Pierna", [85.8 + s * .35, 20.89, -3.56], [.47, 1.01, .58], { tono: color.sombra, acabado: material.tela }),
      pieza("Manga", [85.8 + s * .79, 22.11, -3.53], [.39, .93, .56],
        { tono: color.marino, acabado: material.tela, giro: rotar("z", s * 12) }),
      redondo("Mano", [85.8 + s * .9, 21.66, -3.42], [.35, .38, .38], { tono: color.piel, acabado: material.liso }),
      redondo("Ojo", [85.8 + s * .22, 23.34, -3.06], [.125, .12, .09], { tono: color.sombra, acabado: material.liso }),
      pieza("Ceja", [85.8 + s * .22, 23.45, -3.075], [.19, .051, .054],
        { tono: color.barba, acabado: material.liso, giro: rotar("z", s * -8) }),
    );
  }

  function farol(nombre, x, y, z, enciende = false) {
    return modelo(nombre, [
      metal("Zócalo", [x, y - .29, z], [.66, .15, .66]),
      pieza("Cristal", [x, y, z], [.46, .57, .46],
        { tono: color.crema, acabado: material.neón, hijos: enciende ? [luz(color.oro, .65, 7)] : [] }),
      metal("Remate", [x, y + .31, z], [.7, .135, .7]),
      ...[-1, 1].flatMap((a) => [-1, 1].map((b) =>
        metal("Guardacristal", [x + a * .25, y, z + b * .25], [.08, .62, .08]))),
    ]);
  }

  const taller = [
    pieza("Umbral del taller", [86, 20.055, -2.8], [9.2, .11, 7.4], { tono: color.pizarra }),
    pieza("Alfombra", [85.75, 20.13, -.44], [4.45, .055, 2.56],
      { tono: color.verdeNoche, acabado: material.tela }),
    pieza("Borde de la alfombra", [85.75, 20.162, .77], [4.42, .02, .12],
      { tono: color.menta, acabado: material.tela }),
    madera("Pared resguardada", [86, 22.04, -6.13], [8.78, 4.0, .28], { tono: color.nogal, sólida: true }),
    pieza("Techo izquierdo", [83.67, 25.69, -2.82], [5.08, .29, 8.22],
      { tono: color.verdeNoche, giro: rotar("z", 20) }),
    pieza("Techo derecho", [88.33, 25.69, -2.82], [5.08, .29, 8.22],
      { tono: color.verdeNoche, giro: rotar("z", -20) }),
    metal("Cumbrera", [86, 26.58, -2.82], [.26, .24, 8.38]),
    madera("Viga frontal", [86, 24.82, .83], [9.29, .27, .34], { tono: color.nogal }),
    madera("Mostrador", [89, 21.07, -1.38], [1.48, 2.06, 2.94], { sólida: true }),
    madera("Cubierta del mostrador", [89, 22.15, -1.38], [1.77, .16, 3.13], { tono: color.nogal }),
    madera("Banco", [82.65, 20.79, -3.22], [1.62, .17, 2.43], { tono: color.nogal, sólida: true }),
    madera("Pata del banco", [82.65, 20.33, -4.12], [.91, .66, .27]),
    madera("Pata del banco", [82.65, 20.33, -2.35], [.91, .66, .27]),
    metal("Insignia del taller", [86, 25.16, 1.02], [1.03, 1.03, .15], { giro: rotar("z", 45) }),
    pieza("Luz de la insignia", [86, 25.16, 1.115], [.44, .44, .065],
      { tono: color.menta, acabado: material.neón, giro: rotar("z", 45) }),
    farol("Farol del mostrador", 89, 22.61, -.43, true),
  ];
  for (const x of [81.63, 90.37]) {
    for (const z of [-6.1, .51]) {
      taller.push(
        pieza("Zapato de piedra", [x, 20.28, z], [.82, .48, .82], { tono: color.pizarra }),
        madera("Pilar del taller", [x, 22.62, z], [.39, 4.34, .39], { tono: color.nogal, sólida: true }),
        metal("Anillo del pilar", [x, 23.75, z], [.47, .14, .47], { tono: color.bronce }),
      );
    }
  }

  const zPasarela = -6.3;
  const pasarela = [
    pieza("Cimiento de la pasarela", [110.6, 19.35, zPasarela], [35.6, 1.3, 8.52], { sólida: true }),
    pieza("Estrato vigía", [110.55, 17.91, zPasarela], [32.8, 1.76, 7.2],
      { tono: color.sombra, acabado: material.granito }),
    pieza("Plataforma de la baliza", [123.8, 19.6, zPasarela], [8.7, .80, 10.35], { sólida: true }),
    pieza("Borde del primer viento", [101.4, 20.105, zPasarela], [5.22, .042, 7.98],
      { tono: color.verdeNoche, acabado: material.metal }),
    pieza("Borde del segundo viento", [113.6, 20.105, zPasarela], [5.22, .042, 7.98],
      { tono: color.verdeNoche, acabado: material.metal }),
    pieza("Descanso", [107.55, 20.105, zPasarela], [3.2, .050, 7.1],
      { tono: color.menta, acabado: material.metal }),
  ];
  for (let fila = 0; fila < 20; fila += 1) {
    const x = 93.37 + fila * 1.76;
    pasarela.push(madera("Tabla de cubierta", [x, 20.051, zPasarela], [1.67, .09, 8.12],
      { tono: fila % 4 === 0 ? color.nogal : color.madera }));
  }
  for (const s of [-1, 1]) {
    const z = zPasarela + s * 4.13;
    pasarela.push(madera("Pasamanos", [110.7, 21.59, z], [34.6, .22, .35],
      { tono: color.nogal, sólida: true }));
    for (const x of [94.5, 98.3, 104.3, 107.6, 110.8, 116.6, 120.2, 125.75]) {
      pasarela.push(
        pieza("Poste de la pasarela", [x, 20.85, z], [.37, 1.7, .37], { tono: color.pizarra, sólida: true }),
        metal("Cubierta de poste", [x, 21.72, z], [.47, .17, .47]),
      );
    }
  }
  pasarela.push(madera("Pasamanos de la baliza", [127.6, 21.58, zPasarela], [.28, .23, 8.33],
    { tono: color.nogal, sólida: true }));

  function arco(x) {
    const armazón = [
      metal("Travesaño de viento", [x, 25.37, zPasarela], [1.03, .36, 8.20], { tono: color.nogal }),
      metal("Suspensión del testigo", [x, 25.71, zPasarela], [.24, .44, .24]),
    ];
    for (const s of [-1, 1]) {
      armazón.push(
        pieza("Puntal del viento", [x, 22.64, zPasarela + 3.99 * s], [.52, 5.27, .51],
          { tono: color.marino, sólida: true }),
        metal("Zuncho de puntal", [x, 23.84, zPasarela + 3.99 * s], [.61, .22, .57]),
        metal("Tirante del arco", [x, 24.96, zPasarela + 3.51 * s], [.27, .23, 1.27],
          { giro: rotar("x", s * 35) }),
        pieza("Veta del viento", [x, 22.57, zPasarela + 3.69 * s], [.11, 1.57, .108],
          { tono: color.menta, acabado: material.neón, transparencia: .17 }),
      );
      for (let i = 0; i < 3; i += 1) {
        armazón.push(metal("Flecha en cubierta", [x - .78 + i * .77, 20.144, zPasarela + s * .39],
          [.10, .052, .96], { tono: color.oro, giro: rotar("y", s * 45) }));
      }
    }
    return modelo("Pórtico de ráfaga", armazón);
  }

  function testigo(nombre, x) {
    return redondo(nombre, [x, 26.15, zPasarela], [.57, .64, .63],
      { tono: color.oro, acabado: material.neón, hijos: [luz(color.oro, .82, 8.3)] });
  }

  const meta = [
    pieza("Peana", [124.98, 20.31, zPasarela], [.81, 3.56, 3.56],
      { forma: 2, giro: rotar("z", 90), tono: color.sombra }),
    metal("Pilar de baliza", [124.98, 21.66, zPasarela], [.50, 2.2, .50], { tono: color.bronce }),
    farol("Baliza de la ruta", 124.98, 23.12, zPasarela, true),
    pieza("Sello de llegada", [122.7, 20.14, zPasarela], [.078, 2.45, 2.45],
      { forma: 2, giro: rotar("z", 90), tono: color.menta, acabado: material.metal }),
  ];

  return modelo("RefugioDelViento", [
    invisible("PuntoFarero", [85.8, 22.65, -2], [.8, .8, .8]),
    invisible("InicioEncargo", [95.4, 22.2, zPasarela], [.75, .75, .75]),
    invisible("ZonaRafaga1", [101.4, 23.1, zPasarela], [5.2, 9, 8]),
    invisible("ZonaRafaga2", [113.6, 23.1, zPasarela], [5.2, 9, 8]),
    invisible("MetaEncargo", [122.7, 22.6, zPasarela], [.75, .75, .75]),
    invisible("ZonaEncargo", [109, 24, zPasarela], [32, 12, 12]),
    testigo("Faro1", 101.4),
    testigo("Faro2", 113.6),
    modelo("Farero", farero, fareroId),
    modelo("Taller", taller),
    modelo("Pasarela", pasarela),
    arco(101.4),
    arco(113.6),
    modelo("Baliza", meta),
  ]);
}
