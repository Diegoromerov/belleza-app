#!/usr/bin/env node
/**
 * Auditor de corridas de CI por commit — API pública de GitHub, sin token.
 *
 * Uso:  node auditCiRuns.js main
 *       node auditCiRuns.js 8ad61234a
 *       node auditCiRuns.js <sha-de-la-rama-de-mutacion>
 *
 * Qué responde:
 *   - ¿existe el check del PASO DE TESTS y cuál es su conclusión? (el criterio S3 depende de que exista y de que pueda fallar)
 *   - ¿aparecen las 4 suites heredadas de CI-43 como rojas? (para que un rojo nuevo sea atribuible)
 *   - ¿el run tiene jobs o es un workflow inválido (failure sin jobs)?
 *
 * Sin jq, sin PowerShell, sin credenciales. Sólo lectura.
 */
const https = require("https");

const REPO = "Diegoromerov/belleza-app";
const HEREDADAS = ["business.integration", "businessAdminDocs.integration", "businessHardening.integration", "businessSystem.integration"];
const PASOS_CLAVE = ["test", "jest", "prueba", "Preparar el esquema", "RLS"];

function api(path) {
  return new Promise(function (resolve, reject) {
    https.get({ hostname: "api.github.com", path: path, headers: { "User-Agent": "hermes-audit", Accept: "application/vnd.github+json" } }, function (res) {
      let d = "";
      res.on("data", function (c) { d += c; });
      res.on("end", function () {
        if (res.statusCode !== 200) return reject(new Error("HTTP " + res.statusCode + " en " + path + " :: " + d.slice(0, 200)));
        try { resolve(JSON.parse(d)); } catch (e) { reject(e); }
      });
    }).on("error", reject);
  });
}

(async function () {
  const arg = process.argv[2] || "main";
  let sha = arg;
  if (!/^[0-9a-f]{7,40}$/i.test(arg)) {
    const ref = await api("/repos/" + REPO + "/commits/" + arg);
    sha = ref.sha;
    console.log("  ref " + arg + " -> " + sha.slice(0, 12) + "  (" + (ref.commit.message || "").split("\n")[0].slice(0, 70) + ")");
  } else {
    console.log("  commit " + sha.slice(0, 12));
  }

  const data = await api("/repos/" + REPO + "/commits/" + sha + "/check-runs?per_page=100");
  const runs = data.check_runs || [];
  console.log("  check-runs en ese commit: " + runs.length);
  console.log("");

  const pasos = runs.filter(function (r) { return PASOS_CLAVE.some(function (p) { return r.name.toLowerCase().indexOf(p.toLowerCase()) !== -1; }); });
  console.log("  --- pasos clave ---");
  pasos.forEach(function (r) { console.log("     " + r.conclusion.padEnd(9) + " " + r.name.slice(0, 78)); });
  if (!pasos.length) console.log("     (ninguno: puede ser un workflow inválido, failure sin jobs)");

  const tests = runs.filter(function (r) { return /test|prueba/i.test(r.name); });
  console.log("");
  console.log("  --- veredicto sobre el paso de tests (criterio S3) ---");
  if (!tests.length) {
    console.log("     NO HAYCHECK DE TESTS en este commit => el paso no corre => S3 NO es medible con este run");
  } else {
    tests.forEach(function (r) {
      const est = r.conclusion;
      const frase = est === "skipped" ? "SKIPPED: el paso existe pero no ejecuto => S3 NO medible" :
        (est === "success" ? "ejecuto y paso: sirve para A-07 (el gate corre)" :
          (est === "failure" ? "ejecuto y fallo: es el escenario que S3 necesita si el rojo es atribuible" : "conclusion: " + est));
      console.log("     " + r.name.slice(0, 60) + " => " + est + "  :: " + frase);
    });
  }

  console.log("");
  console.log("  --- suites heredadas de CI-43 visibles en las anotaciones ---");
  let tot = 0;
  for (const r of runs) {
    if (!r.output || !r.output.summary) continue;
    const hit = HEREDADAS.filter(function (h) { return r.output.summary.indexOf(h) !== -1; });
    if (hit.length) { console.log("     " + r.name.slice(0, 55) + " => " + hit.join(", ")); tot += hit.length; }
  }
  console.log(tot ? "     (para atribuir un rojo NUEVO, estas 4 tienen que seguir siendo las mismas)" : "     (sin anotaciones con nombres de suite; mirar el log exige sesion)");

  // Las ANOTACIONES si son publicas aunque el log exija sesion: traen archivo:linea del fallo,
  // que es lo que permite decir QUE paso fallo (y por lo tanto si el de tests llego a ejecutar).
  console.log("");
  console.log("  --- anotaciones de los checks rojos (archivo:linea => mensaje) ---");
  for (const r of runs) {
    if (r.conclusion !== "failure") continue;
    try {
      const an = await api("/repos/" + REPO + "/check-runs/" + r.id + "/annotations?per_page=50");
      console.log("     [" + r.name.slice(0, 45) + "] " + (an.length || 0) + " anotacion(es)");
      (an || []).slice(0, 8).forEach(function (a) {
        console.log("        " + (a.path || "?") + ":" + (a.start_line || "?") + " => " + String(a.title || "").slice(0, 45) + " | " + String(a.message || "").replace(/\s+/g, " ").slice(0, 90));
      });
    } catch (e) {
      console.log("     [" + r.name.slice(0, 45) + "] anotaciones no disponibles: " + e.message.slice(0, 60));
    }
  }
  console.log("");
  console.log("  Regla de lectura: si la anotacion apunta a la linea del paso de preparacion de base, los tests quedaron SKIPPED y S3 no es medible con este run.");

})().catch(function (e) { console.error("  ERROR: " + e.message); process.exit(1); });
