exports.seed = async function(knex) {
  // Railway demo data - reviews
  await knex('reviews').insert([
    { booking_id: 'b0000000-0000-0000-0000-000000000101', client_id: 1, provider_id: 101, rating: 5, comment: 'El balayage me quedo increible! Super profesional y el cabello se siente muy hidratado.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000102', client_id: 1, provider_id: 101, rating: 5, comment: 'Me encanto el corte tendencia. Carolina entendio perfectamente lo que queria.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000201', client_id: 1, provider_id: 102, rating: 5, comment: 'Excelente perfilado de barba y el trato premium fue inmejorable.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000202', client_id: 1, provider_id: 102, rating: 4, comment: 'Muy buen trabajo disimulando las canas de forma natural. Rapido y limpio.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000301', client_id: 1, provider_id: 103, rating: 5, comment: 'El maquillaje social me duro toda la noche intacto. Excelente tecnica!' },
    { booking_id: 'b0000000-0000-0000-0000-000000000302', client_id: 1, provider_id: 103, rating: 5, comment: 'La prueba de maquillaje de novia fue perfecta. Valeria es muy atenta y dulce.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000401', client_id: 1, provider_id: 104, rating: 4, comment: 'Muy buen servicio de semipermanente, amplio catalogo de colores.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000402', client_id: 1, provider_id: 104, rating: 5, comment: 'Las extensiones de Gel-X quedaron super naturales y muy resistentes.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000501', client_id: 1, provider_id: 105, rating: 5, comment: 'La limpieza facial profunda fue un spa completo. La piel me quedo hermosa y limpia.' },
    { booking_id: 'b0000000-0000-0000-0000-000000000502', client_id: 1, provider_id: 105, rating: 5, comment: 'Increible hidratacion con acido hialuronico, muy recomendado el servicio a domicilio.' }
  ])
  .onConflict('booking_id')
  .ignore();
  
  // Update ratings
  await knex.raw(`
    UPDATE perfiles_prestador SET 
      rating_avg = (SELECT AVG(rating) FROM reviews WHERE provider_id = perfiles_prestador.id),
      rating_count = (SELECT COUNT(*) FROM reviews WHERE provider_id = perfiles_prestador.id)
    WHERE id IN (101, 102, 103, 104, 105);
  `);
};