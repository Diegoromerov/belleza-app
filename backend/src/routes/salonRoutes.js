const { wrapRouterAsync } = require('../utils/expressAsync');
const express = require('express');
const router = express.Router();
const {
  createSalon,
  inviteMember,
  acceptInvitation,
  getSalonMembers,
  getMySalon,
  updateMemberRole,
  removeMember,
} = require('../controllers/salonController');
const { authMiddleware } = require('../middleware/auth');
const {
  requireOwnerRole,
  requireSalonAdmin,
  requireSalonRole,
  protectOwnerMember,
  SUB_ROLES,
} = require('../middleware/ownerGuard');

router.get('/my-salon', authMiddleware, getMySalon);
router.post('/create', authMiddleware, createSalon);

// requireSalonAdmin resuelve y valida salon_id del body antes del controlador
// y deja req.salonId / req.salonMembership disponibles (defensa en profundidad:
// salonController.inviteMember conserva su propio chequeo interno).
router.post('/invite', authMiddleware, requireSalonAdmin, inviteMember);

router.post('/accept-invitation', authMiddleware, acceptInvitation);

// Cualquier miembro ACTIVO del salón puede listar el equipo; el salon_id de la
// URL se valida contra salon_miembros y no se toma como verdad del cliente.
router.get(
  '/:salonId/members',
  authMiddleware,
  requireSalonRole(
    SUB_ROLES.DUENO,
    SUB_ROLES.ADMINISTRADOR,
    SUB_ROLES.PRESTADOR_INDEPENDIENTE,
    SUB_ROLES.EMPLEADO,
    SUB_ROLES.RECEPCIONISTA
  ),
  getSalonMembers
);

// Endpoints exclusivos del Propietario (OWNER) para gestión de colaboradores
router.patch(
  '/:salonId/members/:memberId/role',
  authMiddleware,
  requireOwnerRole,
  protectOwnerMember,
  updateMemberRole
);

router.delete(
  '/:salonId/members/:memberId',
  authMiddleware,
  requireOwnerRole,
  protectOwnerMember,
  removeMember
);

wrapRouterAsync(router);
module.exports = router;
