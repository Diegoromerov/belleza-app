exports.seed = async function(knex) {
  // Railway demo data - services
  await knex('services').insert([
    { id: '00000000-0000-0000-0000-000000000101', provider_id: 101, name: 'Balayage Cenizo + Hidratacion Plex', description: 'Tecnica de iluminacion capilar ceniza con cuidado protector.', price: 320000.00, duration_minutes: 180, category: 'hair', is_active: true },
    { id: '00000000-0000-0000-0000-000000000102', provider_id: 101, name: 'Corte Tendencia + Cepillado', description: 'Corte moderno personalizado.', price: 65000.00, duration_minutes: 60, category: 'hair', is_active: true },
    { id: '00000000-0000-0000-0000-000000000201', provider_id: 102, name: 'Corte Premium + Perfilado de Barba', description: 'Corte y afeitado tradicional.', price: 45000.00, duration_minutes: 50, category: 'hair', is_active: true },
    { id: '00000000-0000-0000-0000-000000000202', provider_id: 102, name: 'Camuflaje de Canas Masculino', description: 'Servicio rapido de cobertura de canas.', price: 50000.00, duration_minutes: 40, category: 'hair', is_active: true },
    { id: '00000000-0000-0000-0000-000000000301', provider_id: 103, name: 'Maquillaje Social Premium', description: 'Maquillaje elegante de larga duracion.', price: 140000.00, duration_minutes: 75, category: 'makeup', is_active: true },
    { id: '00000000-0000-0000-0000-000000000302', provider_id: 103, name: 'Maquillaje de Novia (Con Prueba)', description: 'Maquillaje especial y prueba de estilo.', price: 280000.00, duration_minutes: 120, category: 'makeup', is_active: true },
    { id: '00000000-0000-0000-0000-000000000401', provider_id: 104, name: 'Manicura Tradicional Express', description: 'Cuidado de unas express.', price: 28000.00, duration_minutes: 40, category: 'nails', is_active: true },
    { id: '00000000-0000-0000-0000-000000000402', provider_id: 104, name: 'Manicura Semipermanente Profesional', description: 'Durabilidad garantizada con esmaltado semipermanente.', price: 55000.00, duration_minutes: 60, category: 'nails', is_active: true },
    { id: '00000000-0000-0000-0000-000000000403', provider_id: 104, name: 'Manicura + Pedicura Spa Combo', description: 'Combo completo spa manos y pies.', price: 85000.00, duration_minutes: 90, category: 'nails', is_active: true },
    { id: '00000000-0000-0000-0000-000000000404', provider_id: 104, name: 'Extension de Unas en Gel-X', description: 'Extensiones de unas elegantes.', price: 120000.00, duration_minutes: 100, category: 'nails', is_active: true },
    { id: '00000000-0000-0000-0000-000000000405', provider_id: 104, name: 'Kapping Base Ruber', description: 'Recubrimiento fortalecedor.', price: 75000.00, duration_minutes: 75, category: 'nails', is_active: true },
    { id: '00000000-0000-0000-0000-000000000501', provider_id: 105, name: 'Limpieza Facial Profunda', description: 'Limpieza profunda de impurezas.', price: 95000.00, duration_minutes: 75, category: 'facials', is_active: true },
    { id: '00000000-0000-0000-0000-000000000502', provider_id: 105, name: 'Hidratacion Acido Hialuronico', description: 'Tratamiento facial hidratante intensivo.', price: 120000.00, duration_minutes: 60, category: 'facials', is_active: true }
  ])
  .onConflict('id')
  .merge(['name', 'description', 'price', 'is_active']);
};