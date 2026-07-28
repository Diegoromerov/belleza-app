require('dotenv').config({ path: __dirname + '/../.env' });

console.log('YOUCAM_API_KEY from env:', process.env.YOUCAM_API_KEY ? 'SET (' + process.env.YOUCAM_API_KEY.substring(0, 10) + '...)' : 'NOT SET');
console.log('YOCAM_API_KEY from env:', process.env.YOCAM_API_KEY ? 'SET' : 'NOT SET');

const youcamClient = require('../src/services/biometric/youcam.client');
const fs = require('fs');

async function testYouCam() {
  console.log('🧪 Testing YouCam 4-step flow...');
  
  // Read the test image
  const base64Image = fs.readFileSync(__dirname + '/test_face_base64.txt', 'utf8').trim();
  console.log(`📸 Image loaded: ${base64Image.length} chars base64`);
  
  try {
    console.log('\n🚀 Calling analyzeFace()...');
    const start = Date.now();
    const result = await youcamClient.analyzeFace(base64Image);
    const elapsed = Date.now() - start;
    
    console.log(`\n✅ SUCCESS (${elapsed}ms)`);
    console.log('\n📊 Results from YouCam API:');
    console.log('─'.repeat(40));
    console.log(`   hydration: ${result.hydration}`);
    console.log(`   wrinkles:  ${result.wrinkles}`);
    console.log(`   spots:     ${result.spots}`);
    console.log(`   pores:     ${result.pores}`);
    console.log(`   subtono:   ${result.subtono}`);
    console.log(`   bioAge:    ${result.bioAge}`);
    console.log('─'.repeat(40));
    
    // Check if values are NOT the hardcoded defaults
    const defaults = { hydration: 75, wrinkles: 15, spots: 12, pores: 25, subtono: 'cálido', bioAge: 28 };
    const isRealData = result.hydration !== defaults.hydration || 
                       result.wrinkles !== defaults.wrinkles ||
                       result.spots !== defaults.spots ||
                       result.pores !== defaults.pores ||
                       result.subtono !== defaults.subtono ||
                       result.bioAge !== defaults.bioAge;
    
    if (isRealData) {
      console.log('\n🎉 CONFIRMED: Values come from REAL YouCam API response (not hardcoded defaults)!');
    } else {
      console.log('\n⚠️  WARNING: Values match hardcoded defaults. Check if API returned real data.');
    }
    
    // Show raw response structure if available
    if (result.raw) {
      console.log('\n📦 Raw response structure:');
      console.log(JSON.stringify(result.raw, null, 2).substring(0, 2000));
    }
    
  } catch (error) {
    console.error('\n❌ ERROR:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', JSON.stringify(error.response.data, null, 2));
    }
    process.exit(1);
  }
}

testYouCam();