exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('reviews').del();
  
  // Inserts seed entries
  await knex('reviews').insert([
    { id: 'c0000000-0000-0000-0000-000000000002', booking_id: 'b0000000-0000-0000-0000-000000000002', client_id: 4, provider_id: 2, rating: 5, comment: 'Muy puntual y el corte excelente.' },
    { id: 'c0000000-0000-0000-0000-000000000005', booking_id: 'b0000000-0000-0000-0000-000000000005', client_id: 4, provider_id: 5, rating: 5, comment: '¡Ana es maravillosa! Hizo un trabajo increíble con mi cabello, súper recomendada.' },
    { id: 'c0000000-0000-0000-0000-000000000105', booking_id: 'b0000000-0000-0000-0000-000000000105', client_id: 6, provider_id: 5, rating: 5, comment: 'El maquillaje duró toda la noche y captó exactamente lo que quería. Volveré a reservar.' }
  ]);
};