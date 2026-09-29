exports.seed = async function(knex) {
  // Railway demo data - bookings
  await knex('bookings').insert([
    { id: 'b0000000-0000-0000-0000-000000000101', client_id: 1, provider_id: 101, service_id: '00000000-0000-0000-0000-000000000101', scheduled_at: knex.raw("NOW() - INTERVAL '5 days'"), valor_bruto: 320000.00, estado: 'COMPLETADA', pin_verificacion: '1111', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000102', client_id: 1, provider_id: 101, service_id: '00000000-0000-0000-0000-000000000102', scheduled_at: knex.raw("NOW() - INTERVAL '4 days'"), valor_bruto: 65000.00, estado: 'COMPLETADA', pin_verificacion: '2222', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000201', client_id: 1, provider_id: 102, service_id: '00000000-0000-0000-0000-000000000201', scheduled_at: knex.raw("NOW() - INTERVAL '5 days'"), valor_bruto: 45000.00, estado: 'COMPLETADA', pin_verificacion: '3333', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000202', client_id: 1, provider_id: 102, service_id: '00000000-0000-0000-0000-000000000202', scheduled_at: knex.raw("NOW() - INTERVAL '4 days'"), valor_bruto: 50000.00, estado: 'COMPLETADA', pin_verificacion: '4444', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000301', client_id: 1, provider_id: 103, service_id: '00000000-0000-0000-0000-000000000301', scheduled_at: knex.raw("NOW() - INTERVAL '5 days'"), valor_bruto: 140000.00, estado: 'COMPLETADA', pin_verificacion: '5555', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000302', client_id: 1, provider_id: 103, service_id: '00000000-0000-0000-0000-000000000302', scheduled_at: knex.raw("NOW() - INTERVAL '4 days'"), valor_bruto: 280000.00, estado: 'COMPLETADA', pin_verificacion: '6666', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000401', client_id: 1, provider_id: 104, service_id: '00000000-0000-0000-0000-000000000402', scheduled_at: knex.raw("NOW() - INTERVAL '5 days'"), valor_bruto: 55000.00, estado: 'COMPLETADA', pin_verificacion: '7777', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000402', client_id: 1, provider_id: 104, service_id: '00000000-0000-0000-0000-000000000404', scheduled_at: knex.raw("NOW() - INTERVAL '4 days'"), valor_bruto: 120000.00, estado: 'COMPLETADA', pin_verificacion: '8888', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000501', client_id: 1, provider_id: 105, service_id: '00000000-0000-0000-0000-000000000501', scheduled_at: knex.raw("NOW() - INTERVAL '5 days'"), valor_bruto: 95000.00, estado: 'COMPLETADA', pin_verificacion: '9999', payment_status: 'paid' },
    { id: 'b0000000-0000-0000-0000-000000000502', client_id: 1, provider_id: 105, service_id: '00000000-0000-0000-0000-000000000502', scheduled_at: knex.raw("NOW() - INTERVAL '4 days'"), valor_bruto: 120000.00, estado: 'COMPLETADA', pin_verificacion: '0000', payment_status: 'paid' }
  ])
  .onConflict('id')
  .ignore();
};