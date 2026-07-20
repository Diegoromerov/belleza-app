const { execSync } = require('child_process');

try {
  const output = execSync('railway deployment list --service glowapp-frontend --json', { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
  const data = JSON.parse(output);
  
  console.log(`Found ${data.length} deployments for glowapp-frontend:`);
  
  data.slice(0, 5).forEach(d => {
    console.log(`\n---------------------------------------`);
    console.log(`ID: ${d.id}`);
    console.log(`Status: ${d.status}`);
    console.log(`Created: ${d.createdAt}`);
    console.log(`Commit Hash: ${d.meta?.commitHash}`);
    console.log(`Commit Message: ${d.meta?.commitMessage}`);
    console.log(`Root Directory: ${d.meta?.rootDirectory}`);
    console.log(`Build Command: ${d.meta?.serviceManifest?.build?.buildCommand}`);
    console.log(`Builder: ${d.meta?.serviceManifest?.build?.builder}`);
    console.log(`DockerfilePath: ${d.meta?.serviceManifest?.build?.dockerfilePath}`);
  });
} catch (e) {
  console.error(e);
}
