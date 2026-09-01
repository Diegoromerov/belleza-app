// backend/src/services/biometric/youcam.client.js
const axios = require('axios');
const https = require('https');
const logger = require('../../config/logger');
const { executeWithResilience } = require('../../services/resilienceService');
const { defaultPolicy } = require('../../services/resiliencePolicy');

const httpsAgent = new https.Agent({
  rejectUnauthorized: process.env.NODE_ENV === 'production' ? true : (process.env.REJECT_UNAUTHORIZED !== 'false'),
});

class YouCamClient {
  constructor() {
    this.apiKey = process.env.YOUCAM_API_KEY || process.env.YOCAM_API_KEY;
    this.baseUrl = 'https://yce-api-01.makeupar.com/s2s/v2.0';
    this.timeout = 15000; // 15 segundos por request individual
    this.pollIntervalMs = 3000; // 3 segundos entre polls
    this.pollTimeoutMs = 60000; // 60 segundos máximo esperando el resultado
  }

  get authHeaders() {
    return {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
    };
  }

  /** Paso 1: solicita un slot de subida y obtiene la URL pre-firmada de S3. */
  async _requestUploadSlot(buffer) {
    const base64Image = buffer.toString('base64');
    return executeWithResilience(async () => {
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
        { headers: this.authHeaders, httpsAgent, timeout: this.timeout }
      );
      return response;
    }, {
      retry: defaultPolicy.retry,
      retryDelay: defaultPolicy.retryDelay,
      timeout: this.timeout,
      circuitBreakerName: 'youcam'
    });
  }

  /** Paso 2: sube la imagen directamente a S3 usando la URL pre-firmada. */
  async _uploadToS3(uploadUrl, uploadHeaders, buffer) {
    await executeWithResilience(async () => {
      await axios.put(uploadUrl, buffer, {
        headers: {
          ...uploadHeaders,
          'Content-Type': uploadHeaders['Content-Type'] || 'image/jpeg',
          'Content-Length': buffer.length,
        },
        httpsAgent,
        timeout: this.timeout,
        maxBodyLength: Infinity,
        maxContentLength: Infinity,
      });
    }, {
      retry: defaultPolicy.retry,
      retryDelay: defaultPolicy.retryDelay,
      timeout: this.timeout,
      circuitBreakerName: 'youcam'
    });
  }

  /** Paso 3: crea la tarea de análisis referenciando el file_id ya subido. */
  async _createAnalysisTask(fileId) {
    const response = await executeWithResilience(async () => {
      return await axios.post(
        `${this.baseUrl}/task/skin-analysis`,
        {
          request_id: 1,
          src_file_id: fileId,
          dst_actions: [
            'hd_moisture',
            'hd_wrinkle',
            'hd_pore',
            'hd_age_spot',
            'hd_texture',
          ],
        },
        { headers: this.authHeaders, httpsAgent, timeout: this.timeout }
      );
    }, {
      retry: defaultPolicy.retry,
      retryDelay: defaultPolicy.retryDelay,
      timeout: this.timeout,
      circuitBreakerName: 'youcam'
    });

    logger.debug('YouCam create task response', { data: response.data });
    const taskId = response.data?.result?.task_id || response.data?.task_id || response.data?.data?.task_id;
    if (!taskId) {
      throw new Error(`YouCam no devolvió un task_id al crear la tarea de análisis. Respuesta: ${JSON.stringify(response.data)}`);
    }
    return taskId;
  }

  /** Paso 4: consulta el resultado con polling hasta que la tarea termine. */
  async _pollTaskResult(taskId) {
    const start = Date.now();

    while (Date.now() - start < this.pollTimeoutMs) {
      const response = await executeWithResilience(async () => {
        return await axios.get(
          `${this.baseUrl}/task/skin-analysis/${taskId}`,
          { headers: this.authHeaders, httpsAgent, timeout: this.timeout }
        );
      }, {
        retry: defaultPolicy.retry,
        retryDelay: defaultPolicy.retryDelay,
        timeout: this.timeout,
        circuitBreakerName: 'youcam'
      });

      const body = response.data;
      const status = body?.data?.task_status || body?.task_status;

      if (status === 'success') {
        return body?.data?.results || body?.results;
      }

      if (status === 'error') {
        throw new Error(`YouCam reportó error en la tarea de análisis: ${JSON.stringify(body)}`);
      }

      // status === 'running' / 'processing' / etc. -> seguimos esperando
      await new Promise((resolve) => setTimeout(resolve, this.pollIntervalMs));
    }

    throw new Error(`YouCam: tiempo de espera agotado consultando el resultado de la tarea ${taskId}.`);
  }

  /** Convierte el array de outputs de YouCam en el plano que usa el resto de la app. */
  _mapResultsToScores(results) {
    const output = results?.output || [];
    const byType = {};
    for (const item of output) {
      byType[item.type] = item;
    }

    const scoreOf = (type, fallback) =>
      byType[type]?.ui_score !== undefined ? byType[type].ui_score : fallback;

    return {
      hydration: scoreOf('hd_moisture', 75),
      wrinkles: scoreOf('hd_wrinkle', 15),
      spots: scoreOf('hd_age_spot', 12),
      pores: scoreOf('hd_pore', 25),
      subtono: byType['skin_type']?.value || 'cálido',
      bioAge: byType['skin_age']?.ui_score || 28,
      raw: results,
    };
  }

  /** Analiza una imagen de rostro y devuelve scores dérmicos.
   * Ejecuta el flujo completo de 4 pasos: upload slot -> subida S3 -> crear tarea -> poll resultado.
   * @param {Buffer|string} image - Imagen en base64 o buffer
   * @returns {Promise<Object>} Scores de piel
   */
  async analyzeFace(image) {
    logger.info('Iniciando análisis facial con YouCam', { imageSize: image.length || 'unknown' });

    if (!this.apiKey || this.apiKey === 'tu_api_key_aqui') {
      throw new Error('YouCam API key no configurada; no se pueden obtener datos biométricos de rostro.');
    }

    try {
      const base64Image = typeof image === 'string' ? image : image.toString('base64');
      const buffer = Buffer.from(base64Image, 'base64');

      // Paso 1: slot de subida
      const { fileId, uploadUrl, uploadHeaders } = await this._requestUploadSlot(buffer);

      // Paso 2: subir a S3
      await this._uploadToS3(uploadUrl, uploadHeaders, buffer);

      // Paso 3: crear tarea de análisis
      const taskId = await this._createAnalysisTask(fileId);

      // Paso 4: poll hasta obtener resultado
      const results = await this._pollTaskResult(taskId);

      logger.info('Análisis YouCam completado exitosamente', { taskId });

      return this._mapResultsToScores(results);
    } catch (error) {
      logger.error('YouCam API error:', error.response?.data || error.message);
      throw new Error(`YouCam failed: ${error.message}`);
    }
  }
}

module.exports = new YouCamClient();