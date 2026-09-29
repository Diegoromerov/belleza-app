exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('perfiles_prestador').del();
  
  // Inserts seed entries
  await knex('perfiles_prestador').insert([
    { id: 2, business_name: 'Studio María Hair', description: 'Especialista en balayage y cortes modernos', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.0817, 4.6097), 4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****2222', documento_titular: '1018222333', rating_avg: 4.8, rating_count: 1, is_active: true },
    { id: 3, business_name: 'Carlos Nails & Spa', description: 'Manicura semipermanente y nail art', is_online: false, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1422, 4.6735), 4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****4444', documento_titular: '1019444555', rating_avg: 4.0, rating_count: 0, is_active: true },
    { id: 5, business_name: 'Ana Silva Premium Beauty', description: 'Estilista profesional certificada con más de 8 años de experiencia en colorimetría, cortes de vanguardia, maquillaje de gala y diseño de cejas. Servicio personalizado a domicilio en Fontibón.', is_online: true, estatus_verificacion: 'APROBADO', ubicacion: knex.raw("ST_SetSRID(ST_MakePoint(-74.1385, 4.6720), 4326)"), metodo_retiro: 'NEQUI', numero_cuenta_nequi: '+573****6543', documento_titular: '1020444555', rating_avg: 4.9, rating_count: 2, is_active: true }
  ]);
};