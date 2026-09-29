exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('usuarios').del();
  
  // Inserts seed entries
  await knex('usuarios').insert([
    { id: 1, email: 'admin@beautyapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Admin System', phone: '+573****0000', auth_provider: 'LOCAL', provider_id: 'admin-local', rol: 'ADMIN', onboarding_completo: true },
    { id: 2, email: 'maria@correo.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'María López', phone: '+573****2222', auth_provider: 'LOCAL', provider_id: 'maria-local', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 3, email: 'carlos@correo.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Carlos Ruiz', phone: '+573****4444', auth_provider: 'LOCAL', provider_id: 'carlos-local', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 4, email: 'ana@cliente.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Ana Gómez', phone: '+573****6666', auth_provider: 'LOCAL', provider_id: 'ana-local', rol: 'CLIENTE', onboarding_completo: true },
    { id: 5, email: 'provider@beautyapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Ana Silva Estilista', phone: '+573****6543', auth_provider: 'LOCAL', provider_id: 'local_provider@beautyapp.com', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 6, email: 'miusuario@correo.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Cliente de Prueba', phone: '+573****0001', auth_provider: 'LOCAL', provider_id: 'local_miusuario@correo.com', rol: 'CLIENTE', onboarding_completo: true },
    { id: 7, email: 'salon@beautyapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Dueño Salón Luxe', phone: '+573****8877', auth_provider: 'LOCAL', provider_id: 'local_salon@beautyapp.com', rol: 'SALON', onboarding_completo: true }
  ]);
  
  // Reset the sequence
  await knex.raw("SELECT setval('usuarios_id_seq', 7)");
};