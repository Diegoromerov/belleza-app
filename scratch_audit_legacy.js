// scratch_audit_legacy.js
const { pool } = require('./backend/src/config/db');

async function audit() {
  console.log('=== 1. AUDITORÍA DE TABLAS LEGACY SALON / B2C-SaaS ===');
  const salonTablesRes = await pool.query(`
    SELECT table_name 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
      AND (table_name LIKE '%salon%' OR table_name LIKE '%estab%' OR table_name LIKE '%member%' OR table_name LIKE '%tenant%' OR table_name LIKE '%invit%')
    ORDER BY table_name
  `);
  
  const tables = salonTablesRes.rows.map(r => r.table_name);
  console.log('Tablas detectadas:', tables);

  for (const t of tables) {
    try {
      const countRes = await pool.query(`SELECT COUNT(*)::int as count FROM ${t}`);
      const colsRes = await pool.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '${t}'`);
      const constrRes = await pool.query(`SELECT conname, contype, pg_get_constraintdef(c.oid) as def FROM pg_constraint c WHERE conrelid = '${t}'::regclass`);
      
      console.log(`\n--- TABLA: public.${t} (Filas: ${countRes.rows[0].count}) ---`);
      console.log('Columnas:', colsRes.rows.map(c => `${c.column_name} (${c.data_type})`).join(', '));
      console.log('Constraints:', constrRes.rows.map(c => `${c.conname} [${c.contype}]: ${c.def}`).join(' | '));
    } catch (err) {
      console.log(`Error consultando tabla ${t}:`, err.message);
    }
  }

  console.log('\n=== 2. TABLAS QUE APUNTAN CON FK HACIA SALONES LEGACY ===');
  const fkRefsRes = await pool.query(`
    SELECT
      tc.table_name as referencing_table,
      kcu.column_name as referencing_column,
      ccu.table_name AS referenced_table,
      ccu.column_name AS referenced_column
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND ccu.table_name IN ('salones', 'salon_miembros', 'salon_invitaciones');
  `);
  console.log(fkRefsRes.rows);
}

audit().catch(console.error).finally(() => pool.end());
