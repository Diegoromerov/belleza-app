exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('bookings').del();
  
  // Inserts seed entries
  await knex('bookings').insert([
    { id: 'b0000000-0000-0000-0000-000000000002', client_id: 4, provider_id: 2, service_id: 'a0000000-0000-0000-0000-000000000002', scheduled_at: new Date('2026-05-25T15:00:00Z'), valor_bruto: 35000.00, estado: 'COMPLETADA', pin_verificacion: '4821' },
    { id: 'b0000000-0000-0000-0000-000000000005', client_id: 4, provider_id: 5, service_id: 'a0000000-0000-0000-0000-000000000005', scheduled_at: new Date('2026-05-20T10:00:00Z'), valor_bruto: 45000.00, estado: 'COMPLETADA', pin_verificacion: '1122' },
    { id: 'b0000000-0000-0000-0000-000000000105', client_id: 6, provider_id: 5, service_id: 'a0000000-0000-0000-0000-000000000105', scheduled_at: new Date('2026-05-22T18:00:00Z'), valor_bruto: 80000.00, estado: 'COMPLETADA', pin_verificacion: '3344' }
  ]);
};