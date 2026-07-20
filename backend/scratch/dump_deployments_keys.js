const { execSync } = require('child_process');

try {
  const output = execSync('railway deployment list --json', { encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
  const data = JSON.parse(output);
  if (data.length > 0) {
    console.log('Keys of first deployment object:', Object.keys(data[0]));
    console.log('Sample metadata/meta object:', data[0].meta);
    // Let's filter by checking if any key contains service name or id
    console.log('\nChecking all unique serviceIds in deployments:');
    const serviceIds = new Set();
    data.forEach(d => {
      if (d.serviceId) serviceIds.add(d.serviceId);
      if (d.meta?.serviceId) serviceIds.add(d.meta.serviceId);
      if (d.meta?.serviceName) console.log('ServiceName in meta:', d.meta.serviceName);
    });
    console.log(Array.from(serviceIds));
  } else {
    console.log('No deployments found.');
  }
} catch (e) {
  console.error(e);
}
