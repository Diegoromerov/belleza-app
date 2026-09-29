exports.seed = async function(knex) {
  // Railway demo data - provider profiles
  await knex('perfiles_prestador').insert([
    { id: 101, business_name: 'Carolina Hair Studio', description: 'Especialista en Balayage y Colorimetria Avanzada', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1420,4.6730),4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****7890', documento_titular: '1018333222', rating_avg: 4.8, rating_count: 10, is_active: true },
    { id: 102, business_name: 'Santiago Barber Shop', description: 'Barberia clasica y corte masculino moderno', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1360,4.6750),4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****0123', documento_titular: '1019444333', rating_avg: 4.7, rating_count: 8, is_active: true },
    { id: 103, business_name: 'Valeria Tobon Makeup', description: 'Maquillaje profesional para eventos y novias', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1460,4.6710),4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****6789', documento_titular: '1020555444', rating_avg: 4.9, rating_count: 15, is_active: true },
    { id: 104, business_name: 'Ana Silva Nail Art', description: 'Manicura semipermanente y extensiones de unas', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1385,4.6720),4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****6543', documento_titular: '1021666555', rating_avg: 4.6, rating_count: 6, is_active: true },
    { id: 105, business_name: 'Diana Gomez Estetica', description: 'Tratamientos faciales, hidratacion y limpieza profunda', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1310,4.6780),4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****3210', documento_titular: '1022777666', rating_avg: 4.9, rating_count: 12, is_active: true }
  ])
  .onConflict('id')
  .merge(['business_name', 'description', 'estatus_verificacion', 'is_active']);
};