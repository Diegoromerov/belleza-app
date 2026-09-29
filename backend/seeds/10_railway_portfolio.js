exports.seed = async function(knex) {
  // Railway demo data - portfolio
  await knex('portfolio_items').whereIn('provider_id', [101, 102, 103, 104, 105]).del();
  
  await knex('portfolio_items').insert([
    { id: 'e1010000-0000-0000-0000-000000000001', provider_id: 101, image_url: 'https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=800', title: 'Balayage Cenizo Premium', category: 'hair' },
    { id: 'e1010000-0000-0000-0000-000000000002', provider_id: 101, image_url: 'https://images.unsplash.com/photo-1492106087820-71f1a00d2b11?q=80&w=800', title: 'Cabello Iluminado Ondas', category: 'hair' },
    { id: 'e1010000-0000-0000-0000-000000000003', provider_id: 101, image_url: 'https://images.unsplash.com/photo-1522337360788-8b13df793f1f?q=80&w=800', title: 'Corte Bob Estilizado', category: 'hair' },
    { id: 'e1010000-0000-0000-0000-000000000004', provider_id: 101, image_url: 'https://images.unsplash.com/photo-1595425970377-c9703cf48b6d?q=80&w=800', title: 'Diseno de Color Fantasia', category: 'hair' },
    { id: 'e1020000-0000-0000-0000-000000000001', provider_id: 102, image_url: 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?q=80&w=800', title: 'Mid Fade Clasico', category: 'hair' },
    { id: 'e1020000-0000-0000-0000-000000000002', provider_id: 102, image_url: 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?q=80&w=800', title: 'Afeitado y Toalla Caliente', category: 'hair' },
    { id: 'e1020000-0000-0000-0000-000000000003', provider_id: 102, image_url: 'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?q=80&w=800', title: 'Pompadour + Perfilado', category: 'hair' },
    { id: 'e1020000-0000-0000-0000-000000000004', provider_id: 102, image_url: 'https://images.unsplash.com/photo-1593702295094-aec22597af65?q=80&w=800', title: 'Degradado Barba Disenada', category: 'hair' },
    { id: 'e1030000-0000-0000-0000-000000000001', provider_id: 103, image_url: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?q=80&w=800', title: 'Maquillaje de Ojos Smokey', category: 'makeup' },
    { id: 'e1030000-0000-0000-0000-000000000002', provider_id: 103, image_url: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?q=80&w=800', title: 'Maquillaje Novia Natural', category: 'makeup' },
    { id: 'e1030000-0000-0000-0000-000000000003', provider_id: 103, image_url: 'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?q=80&w=800', title: 'Maquillaje Glam de Gala', category: 'makeup' },
    { id: 'e1030000-0000-0000-0000-000000000004', provider_id: 103, image_url: 'https://images.unsplash.com/photo-1526045478516-99145907023c?q=80&w=800', title: 'Maquillaje Editorial Color', category: 'makeup' },
    { id: 'e1040000-0000-0000-0000-000000000001', provider_id: 104, image_url: 'https://images.unsplash.com/photo-1604654894610-df63bc536371?q=80&w=800', title: 'Manicura Semipermanente Roja', category: 'nails' },
    { id: 'e1040000-0000-0000-0000-000000000002', provider_id: 104, image_url: 'https://images.unsplash.com/photo-1629732047847-50b7ef46c3bb?q=80&w=800', title: 'Diseno Frances Clasico', category: 'nails' },
    { id: 'e1040000-0000-0000-0000-000000000003', provider_id: 104, image_url: 'https://images.unsplash.com/photo-1607779097040-26e80aa78e66?q=80&w=800', title: 'Unas Nude Minimalistas', category: 'nails' },
    { id: 'e1040000-0000-0000-0000-000000000004', provider_id: 104, image_url: 'https://images.unsplash.com/photo-1632345031435-8797b2d58045?q=80&w=800', title: 'Gel-X Brillo Escarcha', category: 'nails' },
    { id: 'e1050000-0000-0000-0000-000000000001', provider_id: 105, image_url: 'https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?q=80&w=800', title: 'Limpieza Facial Exfoliante', category: 'facials' },
    { id: 'e1050000-0000-0000-0000-000000000002', provider_id: 105, image_url: 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?q=80&w=800', title: 'Aplicacion Mascarilla de Arcilla', category: 'facials' },
    { id: 'e1050000-0000-0000-0000-000000000003', provider_id: 105, image_url: 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?q=80&w=800', title: 'Masaje Facial Relajante', category: 'facials' },
    { id: 'e1050000-0000-0000-0000-000000000004', provider_id: 105, image_url: 'https://images.unsplash.com/photo-1616394584738-fc6e612e71b9?q=80&w=800', title: 'Piel Radiante Post Tratamiento', category: 'facials' }
  ]);
};