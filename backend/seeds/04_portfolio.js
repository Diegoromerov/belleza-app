exports.seed = async function(knex) {
  // Deletes ALL existing entries
  await knex('portfolio_items').del();
  
  // Inserts seed entries
  await knex('portfolio_items').insert([
    { id: 'f0000000-0000-0000-0000-000000000001', provider_id: 5, image_url: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=600&auto=format&fit=crop', title: 'Rubio Balayage Cenizo', category: 'hair', likes_count: 15 },
    { id: 'f0000000-0000-0000-0000-000000000002', provider_id: 5, image_url: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?q=80&w=600&auto=format&fit=crop', title: 'Maquillaje Glam Noche', category: 'makeup', likes_count: 28 },
    { id: 'f0000000-0000-0000-0000-000000000003', provider_id: 5, image_url: 'https://images.unsplash.com/photo-1604654894610-df49068853b0?q=80&w=600&auto=format&fit=crop', title: 'Uñas Semipermanentes Pastel', category: 'nails', likes_count: 12 }
  ]);
};