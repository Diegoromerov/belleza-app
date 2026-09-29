exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('services').del();
  
  // Inserts seed entries
  await knex('services').insert([
    { id: 'a0000000-0000-0000-0000-000000000002', provider_id: 2, name: 'Corte + Lavado', description: 'Incluye diagnóstico capilar', price: 35000.00, duration_minutes: 45, category: 'hair', is_active: true },
    { id: 'a0000000-0000-0000-0000-000000000102', provider_id: 2, name: 'Balayage Completo', description: 'Técnica de iluminación personalizada', price: 120000.00, duration_minutes: 150, category: 'hair', is_active: true },
    { id: 'a0000000-0000-0000-0000-000000000003', provider_id: 3, name: 'Manicura Semipermanente', description: 'Limpieza, limado y esmaltado duradero', price: 25000.00, duration_minutes: 60, category: 'nails', is_active: true },
    { id: 'a0000000-0000-0000-0000-000000000005', provider_id: 5, name: 'Corte de Cabello Premium + Peinado', description: 'Corte personalizado adaptado a tu rostro, lavado orgánico con masaje capilar y cepillado estilizado profesional.', price: 45000.00, duration_minutes: 60, category: 'hair', is_active: true },
    { id: 'a0000000-0000-0000-0000-000000000105', provider_id: 5, name: 'Maquillaje Profesional de Noche', description: 'Maquillaje glam de alta duración para eventos, incluye preparación e hidratación de piel y pestañas por punto.', price: 80000.00, duration_minutes: 90, category: 'makeup', is_active: true },
    { id: 'a0000000-0000-0000-0000-000000000205', provider_id: 5, name: 'Manicura + Pedicura Spa', description: 'Limpieza profunda, exfoliación de sales minerales, esmaltado semipermanente de larga duración y diseños minimalistas a elección.', price: 50000.00, duration_minutes: 80, category: 'nails', is_active: true }
  ]);
};