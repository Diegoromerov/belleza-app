# 🧭 Route Map — Catálogo Oficial de Rutas

Todas las rutas web de producción en `admin-dashboard-production-4183.up.railway.app` han sido auditadas y verificadas:

| Ruta | Nombre de Pantalla / Vista | Estado Live | Acceso por Rol | Componente Fuente |
| :--- | :--- | :--- | :--- | :--- |
| `/` | Dashboard Global | **200 OK** | ADMIN / Global | `src/app/page.tsx` |
| `/login` | Iniciar Sesión | **200 OK** | Público | `src/app/(auth)/login/page.tsx` |
| `/register` | Registro de Usuarios | **200 OK** | Público | `src/app/(auth)/register/page.tsx` |
| `/prestador` | Dashboard de Prestador | **200 OK** | PRESTADOR | `src/app/(dashboard)/prestador/page.tsx` |
| `/prestador/citas` | Mis Citas (Prestador) | **200 OK** | PRESTADOR | `src/app/(dashboard)/prestador/citas/page.tsx` |
| `/cliente` | Dashboard de Cliente | **200 OK** | CLIENTE | `src/app/(dashboard)/cliente/page.tsx` |
| `/cliente/citas` | Mis Citas (Cliente) | **200 OK** | CLIENTE | `src/app/(dashboard)/cliente/citas/page.tsx` |
| `/cliente/nueva-cita` | Agendar Nueva Cita | **200 OK** | CLIENTE | `src/app/(dashboard)/cliente/nueva-cita/page.tsx` |
| `/admin/academia` | Academia GlowAdmin | **200 OK** | ADMIN | `src/app/(dashboard)/admin/academia/page.tsx` |
| `/admin/academia/nuevo` | Crear Nuevo Curso | **200 OK** | ADMIN | `src/app/(dashboard)/admin/academia/nuevo/page.tsx` |
| `/admin/academia/[id]` | Editor de Curso & Quizzes | **200 OK** | ADMIN | `src/app/(dashboard)/admin/academia/[id]/page.tsx` |
| `/admin/vto` | Inventario & Vencimientos VTO | **200 OK** | ADMIN / PRESTADOR | `src/app/(dashboard)/admin/vto/page.tsx` |
| `/chat` | Centro de Mensajes & Aura IA | **200 OK** | Todos los Roles | `src/app/(dashboard)/chat/page.tsx` |
| `/perfil` | Mi Perfil de Usuario | **200 OK** | Todos los Roles | `src/app/(dashboard)/perfil/page.tsx` |
