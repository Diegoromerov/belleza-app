# 🔑 Permission Matrix — Matriz Detallada de Permisos

| Dominio | Permiso | CLIENTE | PRESTADOR | ADMIN |
| :--- | :--- | :---: | :---: | :---: |
| **Auth** | `auth.login` | ✅ | ✅ | ✅ |
| **Auth** | `auth.change_password` | ✅ | ✅ | ✅ |
| **Bookings** | `bookings.create` | ✅ | ❌ | ✅ |
| **Bookings** | `bookings.read.own` | ✅ | ✅ | ✅ |
| **Bookings** | `bookings.update.assigned` | ❌ | ✅ | ✅ |
| **Services** | `services.manage.own` | ❌ | ✅ | ✅ |
| **Inventory** | `inventory.pos_checkout` | ❌ | ✅ | ✅ |
| **Academy** | `academy.manage` | ❌ | ❌ | ✅ |
| **Safety** | `safety.trigger_sos` | ✅ | ✅ | ✅ |
