// backend/src/services/nodo01Service.js

/**
 * Node Contract — NODO-01-v1.0 Service
 * Node 01: Handover Ingestion & Downstream Adapter
 * 
 * Transport-agnostic, pure in-memory ingestion and semantic adaptation boundary.
 * Ingests HANDOVER-BOUNDARY-CONTRACT-v1.0 payloads, enforces strict semantic isolation
 * (identity != capability != assignment), validates invariants, and produces DOWNSTREAM ADAPTATION RESULT.
 *
 * ZERO DATABASE MUTATIONS / ZERO PRE-NODO-01 SCHEMA MUTATIONS.
 * DEC-SE-001 & DEC-SE-002 REMAIN STRICTLY PENDING.
 */

// Formal Lifecycle State Model (Section 18 of NODO-01-NODE-CONTRACT-v1.0)
const NODE_STATES = Object.freeze({
  NOT_READY: 'NOT_READY',
  READY_TO_RECEIVE: 'READY_TO_RECEIVE',
  RECEIVED: 'RECEIVED',
  VALIDATED: 'VALIDATED',
  ADAPTATION_READY: 'ADAPTATION_READY',
  BLOCKED: 'BLOCKED',
  REJECTED: 'REJECTED',
});

const CONTRACT_VERSION = '1.0.0';
const NODE_ID = 'NODO-01-v1.0';

/**
 * Validates UUID v4 format
 */
const isValidUUID = (uuid) => {
  if (typeof uuid !== 'string') return false;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
};

/**
 * Validates GeoJSON Point
 */
const isValidGeoPoint = (location) => {
  if (!location || typeof location !== 'object') return false;
  if (location.type !== 'Point') return false;
  if (!Array.isArray(location.coordinates) || location.coordinates.length !== 2) return false;
  const [lng, lat] = location.coordinates;
  return typeof lng === 'number' && typeof lat === 'number';
};

/**
 * Ingests and adapts a Handover Boundary Contract v1.0 payload.
 *
 * @param {Object} payload - DTO adhering to HANDOVER-BOUNDARY-CONTRACT-v1.0
 * @param {Object} [securityContext] - Optional server-side active context / user identity
 * @returns {Object} Downstream Adaptation Result with state transition trace
 */
const ingestHandover = (payload, securityContext = {}) => {
  // Trace state lifecycle
  const lifecycle = [NODE_STATES.READY_TO_RECEIVE];

  // 1. Check payload existence
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return {
      success: false,
      node_id: NODE_ID,
      state: NODE_STATES.REJECTED,
      lifecycle: [...lifecycle, NODE_STATES.REJECTED],
      error_code: 'MALFORMED_HANDOVER_PAYLOAD',
      error_message: 'Payload de Handover ausente o con formato invalido.',
      rejection_reasons: ['PAYLOAD_MUST_BE_OBJECT'],
    };
  }

  lifecycle.push(NODE_STATES.RECEIVED);

  const rejectionReasons = [];
  const blockingReasons = [];

  // 2. Contract Version Check
  if (payload.handover_contract_version !== CONTRACT_VERSION) {
    rejectionReasons.push('INVALID_CONTRACT_VERSION: Esperado ' + CONTRACT_VERSION + ', recibido ' + payload.handover_contract_version);
  }

  // 3. Assignment Status Check (Inviolable Invariant: Must strictly be 'NOT_ESTABLISHED')
  if (!payload.assignment || typeof payload.assignment !== 'object') {
    rejectionReasons.push('MISSING_ASSIGNMENT_OBJECT');
  } else if (payload.assignment.status !== 'NOT_ESTABLISHED') {
    rejectionReasons.push('FORBIDDEN_ASSIGNMENT_STATUS: El estado debe ser estrictamente NOT_ESTABLISHED. Recibido: ' + payload.assignment.status);
  }

  // 4. Authorizing Identity Check (R02 - Server-side authority, OWNER or MANAGER)
  const authIdentity = payload.authorizing_identity;
  if (!authIdentity || typeof authIdentity !== 'object') {
    rejectionReasons.push('MISSING_AUTHORIZING_IDENTITY');
  } else {
    const authUserId = authIdentity.user_id;
    const authRole = authIdentity.role;

    if (!authUserId || typeof authUserId !== 'number' || authUserId <= 0) {
      rejectionReasons.push('INVALID_AUTHORIZING_USER_ID');
    }
    if (authRole !== 'OWNER' && authRole !== 'MANAGER') {
      rejectionReasons.push('INSUFFICIENT_AUTHORIZING_ROLE: Se requiere rol OWNER o MANAGER, recibido ' + authRole);
    }

    // Optional cross-validation with server security context if provided
    if (securityContext.userId && securityContext.userId !== authUserId) {
      rejectionReasons.push('IDENTITY_SPOOFING_DETECTED: user_id del payload no coincide con el token de sesion.');
    }
    if (securityContext.role && securityContext.role !== authRole) {
      rejectionReasons.push('ROLE_SPOOFING_DETECTED: rol del payload no coincide con el contexto activo verificado.');
    }
  }

  // 5. Establishment Context Check
  const est = payload.establishment_context;
  if (!est || typeof est !== 'object') {
    rejectionReasons.push('MISSING_ESTABLISHMENT_CONTEXT');
  } else {
    if (!isValidUUID(est.id)) {
      rejectionReasons.push('INVALID_ESTABLISHMENT_ID_UUID');
    }
    if (!est.name || typeof est.name !== 'string' || est.name.trim() === '') {
      rejectionReasons.push('INVALID_ESTABLISHMENT_NAME');
    }
    if (!est.city || typeof est.city !== 'string' || est.city.trim() === '') {
      rejectionReasons.push('INVALID_ESTABLISHMENT_CITY');
    }
    if (!est.address || typeof est.address !== 'string' || est.address.trim() === '') {
      rejectionReasons.push('INVALID_ESTABLISHMENT_ADDRESS');
    }
    if (!isValidGeoPoint(est.location)) {
      rejectionReasons.push('INVALID_ESTABLISHMENT_LOCATION_GEOPOINT');
    }
    if (!est.operating_hours || typeof est.operating_hours !== 'object') {
      rejectionReasons.push('INVALID_ESTABLISHMENT_OPERATING_HOURS');
    }
  }

  // 6. Professional Context Check
  const profContext = payload.professional_context;
  if (!Array.isArray(profContext) || profContext.length === 0) {
    rejectionReasons.push('EMPTY_OR_INVALID_PROFESSIONAL_CONTEXT');
  } else {
    for (let i = 0; i < profContext.length; i++) {
      const prof = profContext[i];
      if (!prof || typeof prof !== 'object') {
        rejectionReasons.push('PROFESSIONAL_INDEX_' + i + '_MALFORMED');
        continue;
      }
      if (!prof.user_id || typeof prof.user_id !== 'number' || prof.user_id <= 0) {
        rejectionReasons.push('PROFESSIONAL_INDEX_' + i + '_INVALID_USER_ID');
      }
      if (!['OWNER', 'MANAGER', 'PROFESSIONAL'].includes(prof.role)) {
        rejectionReasons.push('PROFESSIONAL_INDEX_' + i + '_INVALID_ROLE: ' + prof.role);
      }
      if (prof.status !== 'ACTIVE') {
        rejectionReasons.push('PROFESSIONAL_INDEX_' + i + '_NON_ACTIVE_STATUS: ' + prof.status);
      }
      if (!Array.isArray(prof.capabilities)) {
        rejectionReasons.push('PROFESSIONAL_INDEX_' + i + '_INVALID_CAPABILITIES_ARRAY');
      }
    }
  }

  // 7. Service Offers Check (Boundary & Semantic Integrity: NO provider_id allowed)
  const offers = payload.service_offers;
  if (!Array.isArray(offers)) {
    rejectionReasons.push('INVALID_SERVICE_OFFERS_ARRAY');
  } else {
    for (let i = 0; i < offers.length; i++) {
      const offer = offers[i];
      if (!offer || typeof offer !== 'object') {
        rejectionReasons.push('SERVICE_OFFER_INDEX_' + i + '_MALFORMED');
        continue;
      }

      // R06 & Section 9 Check: Strict rejection if provider_id is present
      if ('provider_id' in offer && offer.provider_id !== undefined && offer.provider_id !== null) {
        rejectionReasons.push('FORBIDDEN_PROVIDER_ID_INJECTION: service_offers[' + i + '] contiene provider_id. Violacion de frontera SaaS.');
      }

      const name = typeof offer.name === 'string' ? offer.name.trim() : '';
      const duration = Number(offer.duration_minutes);
      const price = Number(offer.price);

      if (!name) {
        rejectionReasons.push('SERVICE_OFFER_INDEX_' + i + '_EMPTY_NAME');
      }
      if (isNaN(duration) || duration <= 0) {
        rejectionReasons.push('SERVICE_OFFER_INDEX_' + i + '_INVALID_DURATION: ' + offer.duration_minutes);
      }
      if (isNaN(price) || price < 0) {
        rejectionReasons.push('SERVICE_OFFER_INDEX_' + i + '_INVALID_PRICE: ' + offer.price);
      }
    }
  }

  // If any rejection rule fired, transition to REJECTED
  if (rejectionReasons.length > 0) {
    lifecycle.push(NODE_STATES.REJECTED);
    return {
      success: false,
      node_id: NODE_ID,
      state: NODE_STATES.REJECTED,
      lifecycle,
      error_code: 'HANDOVER_BOUNDARY_REJECTED',
      error_message: 'El payload de Handover no cumple con las invariantes y reglas de NODO-01-v1.0.',
      rejection_reasons: rejectionReasons,
    };
  }

  // If any blocking rule fired, transition to BLOCKED
  if (blockingReasons.length > 0) {
    lifecycle.push(NODE_STATES.BLOCKED);
    return {
      success: false,
      node_id: NODE_ID,
      state: NODE_STATES.BLOCKED,
      lifecycle,
      error_code: 'HANDOVER_BOUNDARY_BLOCKED',
      error_message: 'El payload de Handover fue bloqueado debido a inconsistencias de negocio.',
      blocking_reasons: blockingReasons,
    };
  }

  // All invariants passed -> Transition to VALIDATED
  lifecycle.push(NODE_STATES.VALIDATED);

  // 8. Construct Pure In-Memory DOWNSTREAM ADAPTATION RESULT (R04, R05)
  // Maintains strict semantic isolation: identity != capability != assignment
  const targetEstablishmentDescriptor = {
    id: est.id,
    name: est.name,
    city: est.city,
    address: est.address,
    location: est.location,
    operating_hours: est.operating_hours,
  };

  const eligibleProfessionals = profContext.map((prof) => ({
    user_id: prof.user_id,
    role: prof.role,
    status: prof.status,
    capabilities: [...prof.capabilities],
  }));

  const catalogOfferDescriptors = offers.map((offer) => ({
    name: offer.name.trim(),
    category: offer.category || 'GENERAL',
    duration_minutes: Number(offer.duration_minutes),
    price: Number(offer.price),
    description: offer.description || '',
    is_active: offer.is_active !== undefined ? Boolean(offer.is_active) : true,
  }));

  lifecycle.push(NODE_STATES.ADAPTATION_READY);

  const downstreamAdaptationResult = {
    success: true,
    node_id: NODE_ID,
    state: NODE_STATES.ADAPTATION_READY,
    lifecycle,
    target_establishment_descriptor: targetEstablishmentDescriptor,
    eligible_professionals: eligibleProfessionals,
    catalog_offer_descriptors: catalogOfferDescriptors,
    adaptation_status: 'ADAPTATION_READY',
    pending_decisions: Object.freeze({
      DEC_SE_001: 'PENDING',
      DEC_SE_002: 'PENDING',
    }),
    semantic_declarations: Object.freeze({
      identity_vs_capability_vs_assignment: 'PRESERVED',
      assignment_resolution: 'DEFERRED_TO_DIRECTOR_DEC_SE_001',
      schedule_sync_resolution: 'DEFERRED_TO_DIRECTOR_DEC_SE_002',
      physical_persistence: 'ZERO_MUTATIONS_EXECUTED',
    }),
    audit: {
      source_contract_version: payload.handover_contract_version,
      source_state: payload.source_state || null,
      authorizing_identity: { ...authIdentity },
      assignment_status: payload.assignment.status,
      processed_at: new Date().toISOString(),
    },
  };

  return downstreamAdaptationResult;
};

module.exports = {
  NODE_STATES,
  CONTRACT_VERSION,
  NODE_ID,
  ingestHandover,
};
