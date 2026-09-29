exports.seed = async function(knex) {
  // Railway demo data - schedules
  await knex('perfiles_prestador').where('id', 101).update({
    active_start_hour: 8,
    active_end_hour: 17,
    weekly_schedule: JSON.stringify({
      lunes: { activo: true, inicio: 8, fin: 17 },
      martes: { activo: true, inicio: 8, fin: 17 },
      miercoles: { activo: true, inicio: 8, fin: 17 },
      jueves: { activo: true, inicio: 8, fin: 17 },
      viernes: { activo: true, inicio: 8, fin: 17 },
      sabado: { activo: true, inicio: 8, fin: 14 },
      domingo: { activo: false, inicio: 0, fin: 0 }
    })
  });
  
  await knex('perfiles_prestador').where('id', 102).update({
    active_start_hour: 10,
    active_end_hour: 19,
    weekly_schedule: JSON.stringify({
      lunes: { activo: true, inicio: 10, fin: 19 },
      martes: { activo: true, inicio: 10, fin: 19 },
      miercoles: { activo: true, inicio: 10, fin: 19 },
      jueves: { activo: true, inicio: 10, fin: 19 },
      viernes: { activo: true, inicio: 10, fin: 19 },
      sabado: { activo: true, inicio: 10, fin: 19 },
      domingo: { activo: true, inicio: 10, fin: 16 }
    })
  });
  
  await knex('perfiles_prestador').where('id', 103).update({
    active_start_hour: 7,
    active_end_hour: 15,
    weekly_schedule: JSON.stringify({
      lunes: { activo: false, inicio: 0, fin: 0 },
      martes: { activo: true, inicio: 7, fin: 15 },
      miercoles: { activo: true, inicio: 7, fin: 15 },
      jueves: { activo: true, inicio: 7, fin: 15 },
      viernes: { activo: true, inicio: 7, fin: 15 },
      sabado: { activo: true, inicio: 7, fin: 15 },
      domingo: { activo: false, inicio: 0, fin: 0 }
    })
  });
  
  await knex('perfiles_prestador').where('id', 104).update({
    active_start_hour: 11,
    active_end_hour: 20,
    weekly_schedule: JSON.stringify({
      lunes: { activo: true, inicio: 11, fin: 20 },
      martes: { activo: true, inicio: 11, fin: 20 },
      miercoles: { activo: true, inicio: 11, fin: 20 },
      jueves: { activo: true, inicio: 11, fin: 20 },
      viernes: { activo: true, inicio: 11, fin: 20 },
      sabado: { activo: true, inicio: 9, fin: 17 },
      domingo: { activo: false, inicio: 0, fin: 0 }
    })
  });
  
  await knex('perfiles_prestador').where('id', 105).update({
    active_start_hour: 8,
    active_end_hour: 16,
    weekly_schedule: JSON.stringify({
      lunes: { activo: true, inicio: 8, fin: 16 },
      martes: { activo: true, inicio: 8, fin: 16 },
      miercoles: { activo: true, inicio: 8, fin: 16 },
      jueves: { activo: true, inicio: 8, fin: 16 },
      viernes: { activo: true, inicio: 8, fin: 16 },
      sabado: { activo: true, inicio: 8, fin: 14 },
      domingo: { activo: false, inicio: 0, fin: 0 }
    })
  });
};