// Extrae de un JSON de jest los tests que fallan: nombre completo + primer renglón del mensaje
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const out = [];
for (const suite of data.testResults) {
  for (const t of suite.assertionResults) {
    if (t.status !== 'passed') {
      const msg = (t.failureMessages[0] || '').split('\n').find(l => l.trim().length > 0) || '';
      out.push(`${t.status} :: ${t.fullName} :: ${msg.trim().slice(0, 140)}`);
    }
  }
}
out.sort();
console.log(out.join('\n'));
console.log(`TOTAL no-passed: ${out.length}`);
