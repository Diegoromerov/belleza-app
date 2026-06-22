// frontend/lib/screens/provider_detail_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../shared/theme.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;
  const ProviderDetailScreen({super.key, required this.providerId});
  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;

  String selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await ApiService.fetchProviderDetails(widget.providerId);
      setState(() {
        details = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  double _num(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  String _getSpecialty(Map<String, dynamic> p, List<Map<String, dynamic>> services) {
    if (p['specialty'] != null && p['specialty'].toString().isNotEmpty) {
      return p['specialty'].toString().toLowerCase();
    }
    if (services.isNotEmpty) {
      final firstCat = (services.first['category'] ?? '').toString().toLowerCase();
      if (firstCat.contains('cabello') || firstCat.contains('pelo') || firstCat.contains('corte')) return 'cabello';
      if (firstCat.contains('uña') || firstCat.contains('unas') || firstCat.contains('manicur') || firstCat.contains('pedicur')) return 'uñas';
      if (firstCat.contains('maquillaje') || firstCat.contains('makeup') || firstCat.contains('ceja') || firstCat.contains('pestaña')) return 'maquillaje';
      if (firstCat.contains('piel') || firstCat.contains('facial') || firstCat.contains('skincare') || firstCat.contains('corporal') || firstCat.contains('masaje')) return 'spa';
      if (firstCat.contains('barber') || firstCat.contains('barba')) return 'barbería';
    }
    final desc = (p['description'] ?? '').toString().toLowerCase();
    if (desc.contains('cabello') || desc.contains('tijera') || desc.contains('corte') || desc.contains('balayage')) return 'cabello';
    if (desc.contains('uña') || desc.contains('unas') || desc.contains('manicur') || desc.contains('pedicur')) return 'uñas';
    if (desc.contains('maquillaje') || desc.contains('makeup') || desc.contains('ceja') || desc.contains('pestaña')) return 'maquillaje';
    if (desc.contains('piel') || desc.contains('facial') || desc.contains('skincare') || desc.contains('masaje')) return 'spa';
    if (desc.contains('barber') || desc.contains('barba')) return 'barbería';
    return 'belleza';
  }

  Color _getSpecialtyColor(String specialty) {
    final Map<String, Color> specialtyColors = {
      'cabello': const Color(0xFF6C3A5A),
      'uñas': const Color(0xFFD4AF37),
      'maquillaje': const Color(0xFFE8A2B6),
      'spa': const Color(0xFF4A9B8E),
      'barbería': const Color(0xFF2F4F4F),
      'belleza': const Color(0xFFC89D93),
    };
    return specialtyColors[specialty] ?? const Color(0xFFC89D93);
  }

  IconData _getSpecialtyIcon(String specialty) {
    final Map<String, IconData> specialtyIcons = {
      'cabello': Icons.content_cut_outlined,
      'uñas': Icons.brush_outlined,
      'maquillaje': Icons.face_outlined,
      'spa': Icons.spa_outlined,
      'barbería': Icons.face_retouching_natural_outlined,
      'belleza': Icons.face_outlined,
    };
    return specialtyIcons[specialty] ?? Icons.face_outlined;
  }

  Widget _buildFallbackCover(Color baseColor, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            baseColor.withOpacity(0.8),
            baseColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 80,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC89D93))));
    if (details == null)
      return Scaffold(
          appBar: AppBar(title: Text('Error')),
          body: Center(child: Text('❌ No se pudieron cargar los datos')));

    final p = details!['provider'];
    final services =
        (details!['services'] as List<dynamic>).cast<Map<String, dynamic>>();
    final portfolio = (details!['portfolio'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final reviews = (details!['reviews'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    final hasAvatar =
        p['avatar_url'] != null && p['avatar_url'].toString().isNotEmpty;
    final initialLetter = (p['full_name'] ?? '?')[0].toUpperCase();

    final specialty = _getSpecialty(p, services);
    final specColor = _getSpecialtyColor(specialty);
    final specIcon = _getSpecialtyIcon(specialty);
    final hasCover = p['cover_url'] != null && p['cover_url'].toString().isNotEmpty;

    final filteredServices = services.where((s) {
      if (selectedCategory == 'Todos') return true;
      final cat = (s['category'] ?? '').toString().toLowerCase();
      bool matchCabello = cat.contains('cabello') ||
          cat.contains('pelo') ||
          cat.contains('corte');
      bool matchUnas = cat.contains('uña') ||
          cat.contains('unas') ||
          cat.contains('manicur') ||
          cat.contains('pedicur');
      bool matchMaquillaje = cat.contains('maquillaje') ||
          cat.contains('makeup') ||
          cat.contains('cejas') ||
          cat.contains('pestaña');
      bool matchPiel = cat.contains('piel') ||
          cat.contains('facial') ||
          cat.contains('skincare') ||
          cat.contains('corporal');
      bool matchBarberia = cat.contains('barber') || cat.contains('barba');
      switch (selectedCategory) {
        case 'Cabello':
          return matchCabello;
        case 'Uñas':
          return matchUnas;
        case 'Maquillaje':
          return matchMaquillaje;
        case 'Cuidado de la piel':
          return matchPiel;
        case 'Barbería':
          return matchBarberia;
        case 'Otros':
          return !matchCabello &&
              !matchUnas &&
              !matchMaquillaje &&
              !matchPiel &&
              !matchBarberia;
        default:
          return false;
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Cabecera de Alto Impacto con Parallax y Desvanecimiento al Desplazar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.surface,
            foregroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.surface.withOpacity(0.9),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  hasCover
                      ? Image.network(
                          p['cover_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackCover(specColor, specIcon);
                          },
                        )
                      : _buildFallbackCover(specColor, specIcon),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Información clave superpuesta en la cabecera
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Avatar con radio 45
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                hasAvatar ? NetworkImage(p['avatar_url']) : null,
                            child: !hasAvatar
                                ? Text(
                                    initialLetter,
                                    style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Detalles de texto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Especialidad con su respectivo tag estético con icono
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: specColor.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      specIcon,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      specialty.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Nombre de negocio / prestador
                              Text(
                                p['business_name'] ?? p['full_name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 1),
                                      blurRadius: 4,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              // Rating y valoraciones
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFBBF24), size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    _num(p['rating_avg']).toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${p['rating_count'] ?? 0} valoraciones)',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 16), // Espaciador superior limpio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Ubicación y Verificación
                      Row(
                        children: [
                          if (p['is_verified'] == true ||
                              p['is_verified'] == 'true') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.verified,
                                      color: AppTheme.primary, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verificado',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 12),
                          ],
                          Icon(Icons.location_on,
                              color: Colors.grey, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Fontibón',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Botones rápidos
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      partnerId: widget.providerId,
                                      partnerName: p['business_name'] ??
                                          p['full_name'] ??
                                          'Prestador',
                                      partnerRole: 'provider',
                                      partnerAvatar: p['avatar_url'],
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18),
                              label: Text('Chatear'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 28),

                      // Sobre nosotros
                      if (p['description'] != null &&
                          p['description'].toString().trim().isNotEmpty) ...[
                        Text(
                          'Sobre nosotros',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5),
                        ),
                        SizedBox(height: 8),
                        Text(
                          p['description'],
                          style: TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87),
                        ),
                        SizedBox(height: 28),
                      ],

                      // Servicios
                      Text(
                        'Servicios Ofrecidos',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 12),

                      // Category Horizontal List Chips Filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            'Todos',
                            'Cabello',
                            'Uñas',
                            'Maquillaje',
                            'Cuidado de la piel',
                            'Barbería',
                            'Otros'
                          ].map((cat) {
                            final isSelected = selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(
                                  right: 8.0, bottom: 8.0),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                selectedColor: AppTheme.primary,
                                backgroundColor:
                                    AppTheme.accent.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    selectedCategory = cat;
                                  });
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 12),

                      if (filteredServices.isEmpty)
                        Container(
                          height: 120,
                          alignment: Alignment.center,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.style_outlined,
                                  color: Colors.grey, size: 30),
                              SizedBox(height: 8),
                              Text(
                                'No hay servicios en esta categoría.',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredServices.map((s) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 12,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s['name'] ?? '',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          '\$${_num(s['price']).toStringAsFixed(0)}',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primary),
                                        ),
                                      ],
                                    ),
                                    if (s['description'] != null &&
                                        s['description']
                                            .toString()
                                            .trim()
                                            .isNotEmpty) ...[
                                      SizedBox(height: 6),
                                      Text(
                                        s['description'],
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            height: 1.4),
                                      ),
                                    ],
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          '${s['duration_minutes']} min',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        if (s['category'] != null &&
                                            s['category']
                                                .toString()
                                                .trim()
                                                .isNotEmpty) ...[
                                          SizedBox(width: 12),
                                          Icon(Icons.style_outlined,
                                              size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(
                                            s['category'],
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      SizedBox(height: 28),

                      // Banner Contextual de IA Ubicuo
                      _buildAIBanner(context,
                          p['business_name'] ?? p['full_name'] ?? 'María'),

                      SizedBox(height: 28),

                      // Portafolio
                      Text(
                        'Portafolio de Trabajo',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 12),
                      portfolio.isEmpty
                          ? Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.photo_outlined,
                                      color: Colors.grey, size: 30),
                                  SizedBox(height: 8),
                                  Text(
                                    'Sin imágenes en el portafolio por ahora.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: portfolio.length,
                              itemBuilder: (context, index) {
                                final item = portfolio[index];
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: EdgeInsets.zero,
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 8, sigmaY: 8),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    Navigator.pop(context),
                                                child: Container(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              ),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: InteractiveViewer(
                                                  panEnabled: true,
                                                  minScale: 0.5,
                                                  maxScale: 4.0,
                                                  child: Image.network(
                                                    item['image_url'],
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 40,
                                                right: 20,
                                                child: ClipOval(
                                                  child: BackdropFilter(
                                                    filter: ImageFilter.blur(
                                                        sigmaX: 5, sigmaY: 5),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.white24,
                                                      child: IconButton(
                                                        icon: Icon(
                                                            Icons.close,
                                                            color:
                                                                Colors.white),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      item['image_url'],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                      SizedBox(height: 28),

                      // Reseñas
                      Text(
                        'Opiniones Recientes',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      SizedBox(height: 12),
                      reviews.isEmpty
                          ? Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.rate_review_outlined,
                                      color: Colors.grey, size: 30),
                                  SizedBox(height: 8),
                                  Text(
                                    'Aún sin reseñas.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              itemBuilder: (context, index) {
                                final r = reviews[index];
                                final clientName =
                                    r['client_name'] ?? 'Cliente';
                                final rating = r['rating'] ?? 5;
                                final comment = r['comment'] ?? '';
                                final clientAvatar = r['client_avatar_url'] ??
                                    r['client_avatar'];
                                final hasClientAvatar = clientAvatar != null &&
                                    clientAvatar.toString().isNotEmpty;
                                final clientInitial = clientName.isNotEmpty
                                    ? clientName[0].toUpperCase()
                                    : '?';
                                final reviewPhotos =
                                    (r['photos'] as List<dynamic>? ?? [])
                                        .cast<String>();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: AppTheme.softShadow,
                                    border: Border.all(
                                        color: AppTheme.accent.withOpacity(0.3), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                AppTheme.accent.withOpacity(0.2),
                                            backgroundImage: hasClientAvatar
                                                ? NetworkImage(clientAvatar)
                                                : null,
                                            child: !hasClientAvatar
                                                ? Text(
                                                    clientInitial,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppTheme.primary,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  clientName,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                SizedBox(height: 2),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (starIdx) => Icon(
                                                      Icons.star_rounded,
                                                      size: 16,
                                                      color: starIdx < rating
                                                          ? AppTheme.primary
                                                          : Colors.grey[200],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (comment.trim().isNotEmpty) ...[
                                        SizedBox(height: 12),
                                        Text(
                                          comment,
                                          style: TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: Colors.black87),
                                        ),
                                      ],
                                      if (reviewPhotos.isNotEmpty) ...[
                                        SizedBox(height: 10),
                                        SizedBox(
                                          height: 60,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: reviewPhotos.length,
                                            itemBuilder: (context, photoIdx) {
                                              final photoUrl =
                                                  reviewPhotos[photoIdx];
                                              return GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      child: BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 8,
                                                                sigmaY: 8),
                                                        child: Stack(
                                                          alignment:
                                                              Alignment.center,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Container(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.85),
                                                                width: double
                                                                    .infinity,
                                                                height: double
                                                                    .infinity,
                                                              ),
                                                            ),
                                                            ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16),
                                                              child:
                                                                  InteractiveViewer(
                                                                panEnabled:
                                                                    true,
                                                                minScale: 0.5,
                                                                maxScale: 4.0,
                                                                child: Image
                                                                    .network(
                                                                  photoUrl,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                ),
                                                              ),
                                                            ),
                                                            Positioned(
                                                              top: 40,
                                                              right: 20,
                                                              child: ClipOval(
                                                                child:
                                                                    BackdropFilter(
                                                                  filter: ImageFilter
                                                                      .blur(
                                                                          sigmaX:
                                                                              5,
                                                                          sigmaY:
                                                                              5),
                                                                  child:
                                                                      CircleAvatar(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .black38,
                                                                    child:
                                                                        IconButton(
                                                                      icon: Icon(
                                                                          Icons
                                                                              .close,
                                                                          color:
                                                                              Colors.white),
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.pop(context),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 8),
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                          photoUrl),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ]),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () async {
            final token = await AuthService.getToken();
            if (token == null) {
              if (context.mounted) {
                Navigator.pushNamed(context, '/login');
              }
              return;
            }
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingScreen(
                    providerId: widget.providerId,
                    providerName:
                        p['business_name'] ?? p['full_name'] ?? 'Prestador',
                    services: services,
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 18),
              SizedBox(width: 8),
              Text(
                'RESERVAR CITA CON PAGO SEGURO (WOMPI)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context, String providerName) {
    bool isUploading = false;
    return StatefulBuilder(
      builder: (context, setBannerState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8F0), Color(0xFFF5E4E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppTheme.primary.withOpacity(0.3), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Te interesa el trabajo de $providerName?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Pregúntale a nuestra IA si sus estilos van con tu rostro y facciones.',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.black87, height: 1.35),
              ),
              SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isUploading
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/ideas');
                        },
                        icon: Icon(Icons.lightbulb_outline, size: 16),
                        label: Text(
                          'Ver Ideas y Visajismo IA',
                          style: TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
