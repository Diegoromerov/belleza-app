exports.seed = async function(knex) {
  // Railway demo data - inserts additional users and providers
  await knex('usuarios').insert([
    { id: 101, email: 'carolina.hair@bellezaapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Carolina Mendoza Rios', phone: '+573****7890', auth_provider: 'LOCAL', provider_id: 'local_carolina', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 102, email: 'santiago.barber@bellezaapp.com', password_hash: '$2b$12$E8mZnP9L4xQwK2j1TvYbUo3BiHk6GmNqPrStUvWxYzAbCdEfGhJ', nombre: 'Santiago Castro Devia', phone: '+573****0123', auth_provider: 'LOCAL', provider_id: 'local_santiago', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 103, email: 'valeria.makeup@bellezaapp.com', password_hash: '$2b$12$V3bNmK8Wz1oPl9R2XqYeOu4AhGj6FkLmNpQrStUvWxYzAbCdEfGhK', nombre: 'Valeria Sofia Tobon', phone: '+573****6789', auth_provider: 'LOCAL', provider_id: 'local_valeria', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 104, email: 'prov_nails_001@bellezaapp.com', password_hash: '$2b$12$B9nKj8Wz3oPl9R1NqYeOu2AhGj4FkLmNpQrStUvWxYzAbCdEfGhL', nombre: 'Ana Silva Torres', phone: '+573****6543', auth_provider: 'LOCAL', provider_id: 'local_ana_silva', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 105, email: 'diana.facials@bellezaapp.com', password_hash: '$2b$12$Z1xCvB9NqWeRtYuIoPaSdFgHjKlZxCvBnMqWeRtYuIoPaSdFgHjK', nombre: 'Diana Marcela Gomez', phone: '+573****3210', auth_provider: 'LOCAL', provider_id: 'local_diana', rol: 'PRESTADOR', onboarding_completo: true },
    { id: 1, email: 'cliente.demo@bellezaapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Cliente Demo', phone: '+573****0001', auth_provider: 'LOCAL', provider_id: 'local_cliente_demo', rol: 'CLIENTE', onboarding_completo: true },
    { id: 200, email: 'salon@beautyapp.com', password_hash: '$2b$12$K7vXbM8Wz2oPl9R1NqYeOu1AhGj5FkLmNpQrStUvWxYzAbCdEfGhI', nombre: 'Dueño Salón Luxe Suite', phone: '+573****8877', auth_provider: 'LOCAL', provider_id: 'local_salon_demo', rol: 'SALON', onboarding_completo: true }
  ])
  .onConflict('id')
  .merge(['nombre', 'phone']);
  
  // Update fotos
  await knex('usuarios').where('id', 101).update({ foto_url: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop' });
  await knex('usuarios').where('id', 102).update({ foto_url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop' });
  await knex('usuarios').where('id', 103).update({ foto_url: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200&auto=format&fit=crop' });
  await knex('usuarios').where('id', 104).update({ foto_url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop' });
  await knex('usuarios').where('id', 105).update({ foto_url: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop' });
};