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

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFFC89D93))));
    if (details == null)
      return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: const Center(child: Text('❌ No se pudieron cargar los datos')));

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
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.surface,
            foregroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: AppTheme.surface.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=1000&auto=format&fit=crop',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          Colors.black45
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Avatar del prestador posicionado dentro de la cabecera para evitar que quede por debajo
                  Positioned(
                    left: 20,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 4),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppTheme.surface, // Fondo blanco para alto contraste
                        backgroundImage:
                            hasAvatar ? NetworkImage(p['avatar_url']) : null,
                        child: !hasAvatar
                            ? Text(
                                initialLetter,
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16), // Espaciador superior limpio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Nombre y verificado
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p['business_name'] ?? p['full_name'] ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (p['is_verified'] == true ||
                              p['is_verified'] == 'true')
                            const Icon(Icons.verified,
                                color: AppTheme.primary, size: 24),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Rating y localidad
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFD97706), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _num(p['rating_avg']).toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${p['rating_count'] ?? 0} valoraciones)',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Fontibón',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

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
                              icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18),
                              label: const Text('Chatear'),
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
                      const SizedBox(height: 28),

                      // Sobre nosotros
                      if (p['description'] != null &&
                          p['description'].toString().trim().isNotEmpty) ...[
                        const Text(
                          'Sobre nosotros',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p['description'],
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // Servicios
                      const Text(
                        'Servicios Ofrecidos',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 12),

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
                          child: const Column(
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
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                        ),
                                        Text(
                                          '\$${_num(s['price']).toStringAsFixed(0)}',
                                          style: const TextStyle(
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
                                      const SizedBox(height: 6),
                                      Text(
                                        s['description'],
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                            height: 1.4),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
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
                                          const SizedBox(width: 12),
                                          const Icon(Icons.style_outlined,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
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
                      const SizedBox(height: 28),

                      // Banner Contextual de IA Ubicuo
                      _buildAIBanner(context,
                          p['business_name'] ?? p['full_name'] ?? 'María'),

                      const SizedBox(height: 28),

                      // Portafolio
                      const Text(
                        'Portafolio de Trabajo',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),
                      portfolio.isEmpty
                          ? Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: const Column(
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
                                                        icon: const Icon(
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
                      const SizedBox(height: 28),

                      // Reseñas
                      const Text(
                        'Opiniones Recientes',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 12),
                      reviews.isEmpty
                          ? Container(
                              height: 120,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: const Column(
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
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppTheme.primary,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  clientName,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                                const SizedBox(height: 2),
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
                                        const SizedBox(height: 12),
                                        Text(
                                          comment,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              color: Colors.black87),
                                        ),
                                      ],
                                      if (reviewPhotos.isNotEmpty) ...[
                                        const SizedBox(height: 10),
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
                                                                      icon: const Icon(
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
        decoration: const BoxDecoration(
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
          child: const Row(
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
                  const Icon(Icons.auto_awesome,
                      color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Te interesa el trabajo de $providerName?',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pregúntale a nuestra IA si sus estilos van con tu rostro y facciones.',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.black87, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isUploading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(
                              color: AppTheme.primary),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);

                          final XFile? file = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 800,
                            maxHeight: 800,
                            imageQuality: 85,
                          );
                          if (file == null) return;

                          setBannerState(() => isUploading = true);
                          try {
                            final bytes = await file.readAsBytes();
                            final absoluteUrl =
                                await ApiService.uploadImage(bytes, file.name);

                            String relativePath = '';
                            final uri = Uri.tryParse(absoluteUrl);
                            if (uri != null) {
                              relativePath = uri.path;
                            } else {
                              relativePath = absoluteUrl;
                            }

                            setBannerState(() => isUploading = false);

                            navigator.push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  partnerId:
                                      '00000000-0000-0000-0000-000000000000',
                                  partnerName: 'Asistente de Belleza & Tips IA',
                                  partnerRole: 'admin',
                                  partnerAvatar: '',
                                  initialMessage:
                                      'Hola, me interesa saber si el estilo de $providerName va con mi rostro y cabello.',
                                  initialImagePath: relativePath,
                                ),
                              ),
                            );
                          } catch (e) {
                            setBannerState(() => isUploading = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('❌ Error al subir imagen: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: const Text(
                          'Subir mi foto para Análisis Multimodal',
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
