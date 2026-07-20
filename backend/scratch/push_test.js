const { exec } = require('child_process');

exec('git push origin main --force', (err, stdout, stderr) => {
  console.log('--- STDOUT ---');
  console.log(stdout);
  console.log('--- STDERR ---');
  console.log(stderr);
  if (err) {
    console.error('Error Code:', err.code);
    console.error(err);
  } else {
    console.log('Success!');
  }
});
