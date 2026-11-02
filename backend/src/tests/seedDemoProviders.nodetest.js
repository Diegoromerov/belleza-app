// Guardas del seed de demostración.
//
// Lo que se prueba NO es que siembre —eso se verifica contra la base—, sino que
// se niegue a hacerlo sin bandera explícita y sin conexión. Un seed que corre
// por accidente contra producción es peor que no tener seed.
const { test } = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

const SCRIPT = path.resolve(__dirname, '../../scripts/seedDemoProviders.js');

function correr(env) {
  // Se parte de un entorno vacío de las variables que importan: heredar el del
  // proceso haría que la prueba pasara o fallara según la máquina.
  const base = { ...process.env };
  delete base.ALLOW_DEMO_SEED;
  delete base.DATABASE_URL;
  return spawnSync(process.execPath, [SCRIPT], {
    env: { ...base, ...env },
    encoding: 'utf8',
  });
}

test('sin ALLOW_DEMO_SEED no escribe nada y sale con 1', () => {
  const r = correr({ DATABASE_URL: 'postgres://no-deberia-usarse' });

  assert.strictEqual(r.status, 1, 'debe fallar cerrado');
  assert.match(r.stderr, /ALLOW_DEMO_SEED=1/);
  assert.doesNotMatch(r.stdout, /creados=/, 'no debe llegar a insertar');
});

test('con la bandera pero sin DATABASE_URL falla en voz alta', () => {
  const r = correr({ ALLOW_DEMO_SEED: '1' });

  assert.strictEqual(r.status, 1);
  assert.match(r.stderr, /DATABASE_URL/);
  assert.doesNotMatch(r.stdout, /creados=/);
});
