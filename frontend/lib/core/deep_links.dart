// frontend/lib/core/deep_links.dart
// E-06 (D-GL-027) — Deep links hacia las secciones del salón.
//
// QUÉ CUBRE HOY: el parseo del enlace y el salto a la pestaña correcta, para
//   beautyapp://salon/caja
//   https://glowapp.co/salon?seccion=caja
//   /salon?seccion=caja
//
// QUÉ NO CUBRE TODAVÍA, y por qué: los **App Links https** de verdad necesitan
// `assetlinks.json` con la huella SHA-256 del keystore de Android y
// `apple-app-site-association` con el Team ID de iOS, publicados en el dominio.
// Sin keystore de producción y sin dominio no se puede generar; inventar esos
// archivos daría un enlace que «parece» funcionar y no abre la app. El esquema
// `beautyapp://` en Android necesita además el intent-filter en el manifiesto.
//
// Este archivo es deliberadamente puro: no toca Flutter, así que se prueba sin
// montar la app.

/// Orden de las pestañas del `SalonShell`. Es el contrato con la navegación.
const seccionesSalon = <String>['agenda', 'caja', 'equipo', 'servicios', 'mas'];

/// Alias que la gente escribe de verdad en un enlace.
const _alias = <String, String>{
  'agenda': 'agenda',
  'reservas': 'agenda',
  'citas': 'agenda',
  'caja': 'caja',
  'pagos': 'caja',
  'ingresos': 'caja',
  'equipo': 'equipo',
  'staff': 'equipo',
  'miembros': 'equipo',
  'servicios': 'servicios',
  'catalogo': 'servicios',
  'mas': 'mas',
  'more': 'mas',
  'ajustes': 'mas',
  'config': 'mas',
};

/// Devuelve la sección canónica (`agenda`, `caja`, ...) o `null` si el enlace no
/// identifica una sección del salón.
///
/// Acepta: `beautyapp://salon/caja`, `beautyapp://salon?seccion=caja`,
/// `https://host/salon/caja`, `.../salon?seccion=caja` y `/salon#caja`.
String? seccionDeUri(Uri uri) {
  // 1. Query explícita.
  final porQuery = uri.queryParameters['seccion'] ?? uri.queryParameters['tab'];
  if (porQuery != null && porQuery.isNotEmpty) {
    return _alias[porQuery.toLowerCase()];
  }

  // 2. Fragmento (/salon#caja).
  if (uri.fragment.isNotEmpty && _alias.containsKey(uri.fragment.toLowerCase())) {
    return _alias[uri.fragment.toLowerCase()];
  }

  // 3. Segmentos: [salon, caja]. Se busca el primer segmento conocido después
  //    de `salon`, para tolerar prefijos (/app/salon/caja).
  final segmentos = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  for (var i = 0; i < segmentos.length; i++) {
    final s = segmentos[i].toLowerCase();
    if (s == 'salon' && i + 1 < segmentos.length) {
      return _alias[segmentos[i + 1].toLowerCase()];
    }
    if (_alias.containsKey(s) && (i == 0 || segmentos[i - 1].toLowerCase() == 'salon')) {
      return _alias[s];
    }
  }

  return null;
}

/// Índice de pestaña para `SalonShell.initialIndex`. `null` si no hay sección.
int? indiceDeSeccion(String? seccion) {
  if (seccion == null) return null;
  final i = seccionesSalon.indexOf(seccion);
  return i >= 0 ? i : null;
}

/// Atajo: de un enlace (texto o Uri) al índice de pestaña.
int? indiceDeEnlace(String enlace) {
  final uri = Uri.tryParse(enlace);
  if (uri == null) return null;
  return indiceDeSeccion(seccionDeUri(uri));
}
