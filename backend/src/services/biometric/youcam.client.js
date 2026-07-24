// backend/src/services/biometric/youcam.client.js
const axios = require('axios');
const https = require('https');

const httpsAgent = new https.Agent({
  rejectUnauthorized: false,
});

class YouCamClient {
  constructor() {
    this.apiKey = process.env.YOUCAM_API_KEY || process.env.YOCAM_API_KEY;
    this.baseUrl = 'https://yce-api-01.makeupar.com/s2s/v2.0'; 
    this.timeout = 15000; // 15 segundos
  }

  /**
   * Analiza una imagen de rostro y devuelve scores dérmicos
   * @param {Buffer|string} image - Imagen en base64 o buffer
   * @returns {Promise<Object>} Scores de piel
   */
  async analyzeFace(image) {
    try {
      const base64Image = typeof image === 'string' ? image : image.toString('base64');
      const buffer = Buffer.from(base64Image, 'base64');

      // Si no hay API key de YouCam configurada, hacemos fallback a una simulación realista
      if (!this.apiKey || this.apiKey === 'tu_api_key_aqui') {
        console.warn('⚠️  YouCam API Key no configurada o por defecto. Retornando simulación de YouCam.');
        return {
          hydration: 68,
          wrinkles: 24,
          spots: 18,
          pores: 32,
          subtono: 'cálido',
          bioAge: 29,
          raw: { mock: true },
        };
      }

      const response = await axios.post(
        `${this.baseUrl}/file/skin-analysis`,
        {
          files: [
            {
              file_name: 'user_face.jpg',
              file_size: buffer.length,
              content_type: 'image/jpeg',
              data: base64Image,
            }
          ]
        },
        {
          headers: {
            'Authorization': `Bearer ${this.apiKey}`,
            'Content-Type': 'application/json',
          },
          httpsAgent,
          timeout: this.timeout,
        }
      );

      const data = response.data?.data || response.data;
      return {
        hydration: data.hydration || 75,
        wrinkles: data.wrinkles || 15,
        spots: data.spots || 12,
        pores: data.pores || 25,
        subtono: data.skin_tone || 'cálido',
        bioAge: data.estimated_age || 28,
        raw: data,
      };
    } catch (error) {
      console.error('YouCam API error:', error.response?.data || error.message);
      throw new Error(`YouCam failed: ${error.message}`);
    }
  }
}

module.exports = new YouCamClient();
