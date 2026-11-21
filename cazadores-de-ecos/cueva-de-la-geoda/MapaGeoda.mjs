// Piezas originales y editables en Studio. El mapa empieza en X=264.
const color = {
  suelo: [67, 78, 105],
  roca: [61, 65, 89],
  pizarra: [83, 94, 121],
  profunda: [41, 44, 68],
  lavanda: [185, 157, 245],
  jade: [116, 239, 219],
  cielo: [146, 229, 246],
  oro: [255, 206, 122],
  crema: [234, 223, 184],
  naranja: [255, 138, 102],
  grafito: [32, 32, 48],
};

const material = { liso: 272, neon: 288, roca: 896, pizarra: 800, metal: 1088 };
const esc = (s) => String(s).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
const prop = (tag, nombre, v) => `<${tag} name="${nombre}">${esc(v)}</${tag}>`;
const b = (n, v) => prop("bool", n, v);
const f = (n, v) => prop("float", n, v);
const token = (n, v) => prop("token", n, v);
const xyz = (n, v) => `<Vector3 name="${n}"><X>${v[0]}</X><Y>${v[1]}</Y><Z>${v[2]}</Z></Vector3>`;
const rgb = (n, v) => `<Color3 name="${n}"><R>${v[0]/255}</R><G>${v[1]/255}</G><B>${v[2]/255}</B></Color3>`;
const rad = (a) => a * Math.PI / 180;
const rx = (a) => { const x = rad(a); return [1, 0, 0, 0, Math.cos(x), -Math.sin(x), 0, Math.sin(x), Math.cos(x)]; };
const ry = (a) => { const x = rad(a); return [Math.cos(x), 0, Math.sin(x), 0, 1, 0, -Math.sin(x), 0, Math.cos(x)]; };
const rz = (a) => { const x = rad(a); return [Math.cos(x), -Math.sin(x), 0, Math.sin(x), Math.cos(x), 0, 0, 0, 1]; };
const suma = (a, d) => a.map((v, i) => v + d[i]);
const num = (n) => Math.abs(n) < 1e-9 ? 0 : Number(n.toFixed(7));

function cframe(p, r = [1, 0, 0, 0, 1, 0, 0, 0, 1]) {
  const valores = [...p, ...r];
  const nombres = ["X", "Y", "Z", "R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"];
  const campos = nombres.map((n, i) => `<${n}>${num(valores[i])}</${n}>`).join("");
  return `<CoordinateFrame name="CFrame">${campos}</CoordinateFrame>`;
}

export function crearCueva() {
  let siguiente = 0;
  function item(clase, nombre, props = [], hijos = [], id = "RBXGeoda" + ++siguiente) {
    return `<Item class="${clase}" referent="${id}"><Properties>${prop("string", "Name", nombre)}${props.join("")}</Properties>${hijos.length ? "\n" + hijos.join("\n") + "\n" : ""}</Item>`;
  }
  const carpeta = (n, hijos) => item("Folder", n, [], hijos);
  const modelo = (n, hijos, principal) => item("Model", n, principal ? [prop("Ref", "PrimaryPart", principal)] : [], hijos);
  const luz = (c, brillo, rango) => item("PointLight", "Luz", [rgb("Color", c), f("Brightness", brillo), f("Range", rango), b("Shadows", false)]);

  function pieza(n, p, s, opciones = {}) {
    const c = opciones.c ?? color.roca;
    const solido = opciones.solido ?? false;
    const transparencia = opciones.t ?? 0;
    return item("Part", n, [
      cframe(p, opciones.r), xyz("size", s), prop("Color3uint8", "Color3uint8", 0xff000000 + c[0]*0x10000 + c[1]*0x100 + c[2]),
      b("Anchored", true), b("CanCollide", solido), b("CanTouch", false), b("CanQuery", opciones.consulta ?? solido),
      b("CastShadow", opciones.sombra ?? solido), f("Transparency", transparencia), token("Material", opciones.m ?? material.pizarra),
      token("TopSurface", 0), token("BottomSurface", 0),
      ...(opciones.forma === undefined ? [] : [token("shape", opciones.forma)]),
    ], opciones.hijos ?? [], opciones.id);
  }
  const oculto = (n, p, s, opciones = {}) => pieza(n, p, s, { t: 1, ...opciones });
  const brillo = (n, p, s, c, opciones = {}) => pieza(n, p, s, { c, m: material.neon, ...opciones });
  const esfera = (n, p, s, c, opciones = {}) => pieza(n, p, s, { c, m: material.liso, forma: 0, ...opciones });
  const disco = (n, p, d, grosor, opciones = {}) => pieza(n, p, [grosor, d, d], { ...opciones, r: rz(90), forma: 2 });

  const piso = [
    pieza("Suelo de la entrada", [273.95, 18.2, 0], [19.9, 3.6, 24], { c: color.suelo, solido: true }),
    pieza("Suelo del guardián", [318.8, 18.1, 0], [69.8, 3.8, 58], { c: color.suelo, solido: true }),
    pieza("Pasarela del viento", [364.25, 18.35, 13], [21.1, 3.3, 14], { c: color.pizarra, solido: true }),
    pieza("Mirador de la geoda", [384.4, 18.9, 13], [19.2, 2.2, 15], { c: color.suelo, solido: true }),
    pieza("Roca inferior", [318.8, 14.6, -1], [68.7, 4, 55], { c: color.profunda, m: material.roca, r: ry(-1) }),
    pieza("Roca inferior", [317, 10.6, -1], [58, 5.1, 48], { c: color.roca, m: material.roca, r: ry(2) }),
    pieza("Sostén del mirador", [380, 15.0, 13], [24, 5.2, 12], { c: color.profunda, m: material.roca }),
  ];
  for (let x = 274; x <= 300; x += 4.3) {
    piso.push(pieza("Piedra del sendero", [x, 20.046, 0], [2.65, .08, 2.45], { c: [106, 126, 145], r: ry((Math.round(x) % 4 - 2) * 7) }));
  }
  for (let x = 354; x <= 388; x += 4.45) {
    piso.push(pieza("Piedra del mirador", [x, 20.047, 13], [3.22, .08, 4.12], { c: [100, 132, 147], r: ry((Math.round(x) % 3 - 1) * 4) }));
  }
  for (let i = 0; i < 16; i++) {
    const a = i * Math.PI / 8;
    piso.push(pieza("Marca de la arena", [319 + Math.cos(a)*18, 20.074, Math.sin(a)*18], [2.32, .075, .47], { c: [125, 136, 163], m: material.liso, r: ry(-a*180/Math.PI-90) }));
  }

  const muros = [
    pieza("Pared norte", [318.8, 31, -29.4], [69.8, 22, 3.2], { c: color.profunda, m: material.roca, solido: true }),
    pieza("Pared sur", [318.8, 29.6, 29.4], [69.8, 19.2, 3.2], { c: color.profunda, m: material.roca, solido: true }),
    pieza("Fondo del santuario", [353.3, 28, -13.2], [3.0, 16, 28], { c: color.profunda, m: material.roca, solido: true }),
    pieza("Pared del viento norte", [367.25, 26, 5.12], [24.9, 12, 1.5], { c: color.profunda, m: material.roca, solido: true }),
    pieza("Pared del viento sur", [367.25, 26, 20.88], [24.9, 12, 1.5], { c: color.roca, m: material.roca, solido: true }),
    pieza("Límite de la cueva", [280.4, 29, -10.7], [3.9, 18, 5.8], { c: color.roca, solido: true }),
    pieza("Límite de la cueva", [280.4, 29, 10.7], [3.9, 18, 5.8], { c: color.roca, solido: true }),
    pieza("Dintel grande", [282, 38.5, 0], [5.1, 5.5, 26], { c: color.pizarra, m: material.roca, solido: true, r: ry(-4) }),
    pieza("Techo al norte", [315, 41, -24.9], [63, 3.2, 20], { c: color.profunda, m: material.roca, solido: true, r: ry(12) }),
    pieza("Techo al sur", [321, 41.6, 24], [63.2, 4, 22.4], { c: color.roca, m: material.roca, solido: true, r: ry(-8) }),
    pieza("Techo del corredor", [366.5, 33, 13], [24, 2.4, 17.4], { c: color.profunda, m: material.roca, solido: true }),
  ];
  for (const z of [-1, 1]) {
    for (let i = 0; i < 8; i++) {
      const x = 288 + i * 8.32;
      const y = 22 + (i % 3) * .57;
      muros.push(pieza("Estrato visible", [x, y, z*(26.8+(i%3)*.42)], [5.7+(i%3)*.44, 7.35+(i%4)*1.06, 3.35], { c: i % 2 ? color.roca : color.pizarra, m: material.roca, r: rz((i%5-2)*11) }));
      muros.push(pieza("Estalactita", [x+.45, 36.6-(i%3)*.64, z*(21.1+(i%3)*.7)], [1.55, 6.6+(i%4)*1.65, 1.9], { c: color.roca, m: material.roca, r: rz((i%5-2)*6) }));
    }
  }

  function veta(n, p, c, escala, conLuz) {
    return modelo(n, [
      pieza("Base mineral", suma(p, [0, .27, 0]), [2.75*escala, .54, 2.25*escala], { c: color.profunda, m: material.roca, r: ry(25) }),
      brillo("Cristal", suma(p, [0, 1.35*escala, 0]), [.7*escala, 2.16*escala, .77*escala], c, { r: rz(-20), t: .08, hijos: conLuz ? [luz(c, 1.16, 14)] : [] }),
      brillo("Cristal", suma(p, [-.72*escala, .9*escala, .34]), [.53*escala, 1.47*escala, .46*escala], c, { r: rz(23) }),
      brillo("Cristal", suma(p, [.62*escala, .77*escala, -.44]), [.49*escala, 1.19*escala, .46*escala], c, { r: rx(19) }),
    ]);
  }

  const vetas = [
    veta("Vetilla de entrada", [269, 20, 9], color.jade, 1.22, true),
    veta("Veta de entrada", [282, 20, -7.7], color.lavanda, 1.48, true),
    veta("Veta de entrada", [284, 20, 9.8], color.jade, .92, true),
    veta("Veta norte", [296, 20, -24], color.jade, 1.38, true),
    veta("Veta norte", [312, 20, -26], color.lavanda, .96, true),
    veta("Veta norte", [341, 20, -24], color.jade, 1.55, true),
    veta("Veta sur", [299, 20, 24], color.lavanda, 1.55, true),
    veta("Veta sur", [322, 20, 25.4], color.jade, 1.16, true),
    veta("Veta sur", [346.3, 20, 24.4], color.lavanda, 1.62, true),
    veta("Veta santuario", [350.6, 20, -7.2], color.oro, 1.17, true),
    veta("Veta santuario", [350.1, 20, 5.3], color.oro, .9, true),
    veta("Veta del mirador", [386, 20, 8], color.jade, .8, false),
    veta("Veta del mirador", [390.4, 20, 17], color.lavanda, 1.09, true),
  ];

  const g = [318, 24, 0];
  const guardia = [
    pieza("Torso", g, [5.3, 5.1, 3.8], { c: color.roca, m: material.roca, id: "RBXGeodaGuardianPivot", sombra: true }),
    pieza("Pecho", suma(g, [0, .28, -1.78]), [4.7, 3.2, .77], { c: color.pizarra, m: material.roca, r: rz(5) }),
    pieza("Cabeza", suma(g, [0, 3.15, -.48]), [3.55, 2.16, 2.97], { c: color.pizarra, m: material.roca }),
    pieza("Cejas", suma(g, [0, 3.63, -1.98]), [3.28, .53, .52], { c: color.profunda, m: material.roca }),
    pieza("Mandíbula", suma(g, [0, 2.48, -1.91]), [3, .56, .68], { c: color.profunda, m: material.pizarra, r: rz(-5) }),
    brillo("Veta del pecho", suma(g, [0, .47, -2.22]), [.53, 1.54, .20], color.lavanda, { r: rz(40), t: .22 }),
    pieza("Hueco de la espalda", suma(g, [0, .46, 1.97]), [2.68, 2.5, .33], { c: color.grafito, m: material.liso, r: rz(45) }),
    brillo("CristalEspalda", suma(g, [0, .54, 2.19]), [1.56, 1.56, .34], color.jade, { r: rz(45), t: .36 }),
  ];
  for (const lado of [-1, 1]) {
    guardia.push(
      pieza("Hombro", suma(g, [lado*3.2, 1.12, .06]), [2.37, 2.82, 3.14], { c: color.pizarra, m: material.roca, r: rz(lado*17) }),
      pieza("Brazo", suma(g, [lado*3.85, -.79, -.23]), [1.6, 2.51, 2.34], { c: color.roca, m: material.roca, r: rz(lado*10) }),
      pieza("Puño", suma(g, [lado*4.15, -2.15, -.48]), [1.94, 1.5, 2.13], { c: color.pizarra, m: material.roca, r: rz(lado*9) }),
      pieza("Pie", suma(g, [lado*1.51, -2.97, -.61]), [1.9, 1.4, 2.91], { c: color.profunda, m: material.pizarra }),
      brillo("Ojo", suma(g, [lado*.72, 3.23, -1.99]), [.79, .35, .18], color.naranja, { r: rz(lado*15) }),
      brillo("Veta del hombro", suma(g, [lado*3.52, 2.38, .02]), [.41, 1.23, .55], color.lavanda, { r: rz(lado*19), t: .13 }),
    );
  }

  const centro = [350, 23.4, 0];
  const carcasas = [
    pieza("Cara frontal", [348.47, 23.47, 0], [.95, 3.42, 3.34], { c: color.roca, m: material.roca, r: rx(-31) }),
    pieza("Caparazón superior", [350, 24.9, 0], [3.45, 1.63, 3.77], { c: color.profunda, m: material.roca, r: ry(22) }),
    pieza("Caparazón del fondo", [351.34, 23.47, 0], [.88, 3.2, 3.74], { c: color.pizarra, m: material.roca, r: rx(32) }),
    pieza("Caparazón izquierdo", [350, 23.5, -1.52], [3.3, 3.12, .8], { c: color.profunda, m: material.roca, r: rz(24) }),
    pieza("Caparazón derecho", [350, 23.5, 1.52], [3.3, 3.12, .8], { c: color.roca, m: material.roca, r: rz(-14) }),
    brillo("Grieta dorada", [347.98, 23.59, -.23], [.19, 2.56, .17], color.oro, { r: rx(-19) }),
  ];
  const geoda = [
    disco("Base del tesoro", [350, 20.28, 0], 7.15, .55, { c: color.profunda }),
    disco("Sello del tesoro", [350, 20.62, 0], 5.37, .13, { c: color.oro, m: material.metal }),
    oculto("Centro", centro, [.24, .24, .24], { id: "RBXGeodaTesoroPivot" }),
    oculto("Punto", [347.5, 22.4, 0], [1, 1, 1], { consulta: true }),
    carpeta("Caparazon", carcasas),
  ];

  const p = [350, 24.5, 0];
  const pedernal = [
    pieza("Corazon", p, [1.96, 1.58, 1.95], { c: [135, 108, 101], m: material.roca, id: "RBXGeodaPedernalPivot" }),
    esfera("Mejillas", suma(p, [0, .14, -.66]), [1.7, 1.18, 1.2], color.crema),
    brillo("Frente", suma(p, [0, .91, -.08]), [.66, .94, .67], color.oro, { r: rz(33) }),
    brillo("Escama", suma(p, [.41, .43, .85]), [.4, .76, .49], color.lavanda, { r: rz(-16) }),
    brillo("Cola", suma(p, [0, -.29, 1.05]), [.48, .44, .89], color.oro, { r: rx(-18) }),
  ];
  for (const lado of [-1, 1]) {
    pedernal.push(
      pieza("Escudo lateral", suma(p, [lado*1.02, .06, .09]), [.44, 1.34, 1.47], { c: [165, 138, 116], m: material.roca, r: rz(lado*26) }),
      esfera("Ojo", suma(p, [lado*.34, .28, -1.18]), [.18, .26, .18], color.grafito),
      pieza("Pata", suma(p, [lado*.58, -.72, -.26]), [.57, .43, .62], { c: color.roca, m: material.roca }),
    );
  }

  const c = [273, 26, 4];
  const cometa = [
    brillo("Nucleo", c, [1.48, 1.54, 1.47], color.oro, { id: "RBXGeodaCometaPivot", r: rz(30) }),
    esfera("Cara", suma(c, [0, .28, -.84]), [1.24, 1.09, 1.04], [232, 222, 248]),
    brillo("Cola", suma(c, [0, -.33, 1.22]), [.33, .32, 1.35], color.jade, { r: rx(-16) }),
  ];
  for (const lado of [-1, 1]) {
    cometa.push(
      pieza("Ala", suma(c, [lado*1.21, .18, .03]), [1.64, .31, 1.02], { c: color.lavanda, m: material.liso, r: rz(lado*24) }),
      brillo("Punta de ala", suma(c, [lado*1.96, .42, .22]), [.58, .19, .47], color.jade, { r: rz(lado*24) }),
      pieza("Oreja", suma(c, [lado*.38, .89, -.78]), [.29, .64, .3], { c: [238, 220, 245], m: material.liso, r: rz(-lado*24) }),
      esfera("Ojo", suma(c, [lado*.29, .33, -1.27]), [.15, .22, .15], color.grafito),
    );
  }

  const alto = [
    pieza("Soporte", [332, 24, -18], [2.5, 8, 2.5], { c: color.pizarra, m: material.roca, r: ry(26), id: "RBXGeodaAltoPivot" }),
    disco("Marca de piedra", [332, 20.07, -18], 6.4, .12, { c: color.oro, t: .5, m: material.neon }),
    brillo("Alto cristal", [332, 29.38, -18], [1.9, 3.2, 1.95], color.oro, { r: rz(30), hijos: [luz(color.oro, 1.1, 14)] }),
    brillo("Base dorada", [332, 21.35, -18], [2.55, .38, 2.55], color.oro, { r: ry(27) }),
  ];

  const ruta = [
    pieza("PuertaViento", [365, 25.15, 13], [.51, 10.3, 14], { c: color.cielo, m: material.neon, t: .45, solido: true, sombra: false }),
    oculto("PuntoProyectil", [374, 22.4, 13], [.24, .24, .24]),
    brillo("SelloRebote", [376, 24, 13], [.9, 1.18, 1.1], color.lavanda, { r: rz(45) }),
    brillo("Baliza", [387, 22.5, 13], [1.1, 1.7, 1.1], color.oro, { r: rz(32), hijos: [luz(color.oro, 1.35, 12)] }),
    oculto("ZonaViento", [366, 23, 13], [15, 10, 14]),
    disco("Sello del mirador", [387, 20.13, 13], 5.83, .17, { c: color.oro, m: material.metal }),
    pieza("Pilar izquierdo", [389.5, 23.15, 7.35], [1.43, 6.3, 1.43], { c: color.pizarra, r: ry(24) }),
    pieza("Pilar derecho", [389.5, 23.15, 18.65], [1.43, 6.3, 1.43], { c: color.pizarra, r: ry(-24) }),
    brillo("Punta izquierda", [389.5, 26.93, 7.35], [.6, 1.2, .63], color.jade, { r: rz(-21) }),
    brillo("Punta derecha", [389.5, 26.93, 18.65], [.6, 1.2, .63], color.jade, { r: rz(21) }),
  ];
  for (let i = 0; i < 5; i++) {
    const z = 7.6 + i * 2.65;
    ruta.push(brillo("Línea del viento", [364.69, 21.75 + (i%2)*1.8, z], [.19, .23, 1.55], color.cielo, { r: rx((i%2 ? -1 : 1)*37), t: .27 }));
  }

  return modelo("CuevaDeLaGeoda", [
    oculto("Entrada", [272, 23.7, 0], [1, 1, 1], { r: ry(-90) }),
    brillo("Totem", [283, 22.05, 0], [.94, 1.34, .94], color.jade, { r: rz(26), hijos: [luz(color.jade, 1.08, 10)] }),
    disco("Base del tótem", [283, 20.19, 0], 2.9, .38, { c: color.pizarra, m: material.metal }),
    brillo("SalidaIsla", [267, 22.2, -6], [.88, 1.23, .88], color.jade, { r: rz(-30), hijos: [luz(color.jade, .93, 8)] }),
    disco("Base de salida", [267, 20.12, -6], 3.93, .23, { c: color.roca }),
    carpeta("Pisos", piso),
    carpeta("Muros", muros),
    carpeta("Vetas", vetas),
    modelo("Guardian", guardia, "RBXGeodaGuardianPivot"),
    modelo("Geoda", geoda, "RBXGeodaTesoroPivot"),
    modelo("Pedernal", pedernal, "RBXGeodaPedernalPivot"),
    modelo("Cometa", cometa, "RBXGeodaCometaPivot"),
    modelo("CristalAlto", alto, "RBXGeodaAltoPivot"),
    carpeta("Ruta", ruta),
  ]);
}
