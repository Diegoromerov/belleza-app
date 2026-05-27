// frontend/lib/screens/provider_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
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

  @override
  void initState() { super.initState(); _loadDetails(); }

  Future<void> _loadDetails() async {
    try {
      final data = await ApiService.fetchProviderDetails(widget.providerId);
      setState(() { details = data; isLoading = false; });
    } catch (e) { setState(() => isLoading = false); }
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
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))));
    if (details == null) return Scaffold(appBar: AppBar(title: const Text('Error')), body: const Center(child: Text('❌ No se pudieron cargar los datos')));

    final p = details!['provider'];
    final services = (details!['services'] as List<dynamic>).cast<Map<String, dynamic>>();
    final portfolio = (details!['portfolio'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final reviews = (details!['reviews'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    final hasAvatar = p['avatar_url'] != null && p['avatar_url'].toString().isNotEmpty;
    final initialLetter = (p['full_name'] ?? '?')[0].toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Cabecera de Alto Impacto
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xE6FFFFFF),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
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
                        colors: [Colors.black54, Colors.transparent, Colors.black26],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x29000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFF5EBE6),
                            backgroundImage: hasAvatar ? NetworkImage(p['avatar_url']) : null,
                            child: !hasAvatar
                                ? Text(
                                    initialLetter,
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFC89D93)),
                                  )
                                : null,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        if (p['is_verified'] == true || p['is_verified'] == 'true')
                          const Icon(Icons.verified, color: Color(0xFFC89D93), size: 24),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Rating y localidad
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _num(p['rating_avg']).toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${p['rating_count'] ?? 0} valoraciones)',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Fontibón',
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
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
                                    partnerName: p['business_name'] ?? p['full_name'] ?? 'Prestador',
                                    partnerRole: 'provider',
                                    partnerAvatar: p['avatar_url'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            label: const Text('Chatear'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC89D93),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Sobre nosotros
                    if (p['description'] != null && p['description'].toString().trim().isNotEmpty) ...[
                      const Text(
                        'Sobre nosotros',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['description'],
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Servicios
                    const Text(
                      'Servicios Ofrecidos',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 12),
                    ...services.map((s) => Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    s['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '\$${_num(s['price']).toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFC89D93)),
                                ),
                              ],
                            ),
                            if (s['description'] != null && s['description'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                s['description'],
                                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${s['duration_minutes']} min',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                if (s['category'] != null && s['category'].toString().trim().isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.style_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    s['category'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
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
                    _buildAIBanner(context, p['business_name'] ?? p['full_name'] ?? 'María'),

                    const SizedBox(height: 28),

                    // Portafolio
                    const Text(
                      'Portafolio de Trabajo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
                                Icon(Icons.photo_outlined, color: Colors.grey, size: 30),
                                SizedBox(height: 8),
                                Text(
                                  'Sin imágenes en el portafolio por ahora.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Image.network(item['image_url'], fit: BoxFit.contain),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
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
                                Icon(Icons.rate_review_outlined, color: Colors.grey, size: 30),
                                SizedBox(height: 8),
                                Text(
                                  'Aún sin reseñas.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
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
                              final clientName = r['client_name'] ?? 'Cliente';
                              final rating = r['rating'] ?? 5;
                              final comment = r['comment'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          clientName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (starIdx) => Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: starIdx < rating ? const Color(0xFFD97706) : Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (comment.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        comment,
                                        style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 40),
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(
                providerId: widget.providerId,
                providerName: p['business_name'] ?? p['full_name'] ?? 'Prestador',
                services: services,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC89D93),
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
              colors: [Color(0xFFFFF5F2), Color(0xFFF5EBE6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8D7D3).withOpacity(0.5), width: 1.5),
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
                  const Icon(Icons.auto_awesome, color: Color(0xFFC89D93), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¿Te interesa el trabajo de $providerName?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Pregúntale a nuestra IA si sus estilos van con tu rostro y facciones.',
                style: TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.35),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: isUploading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(color: Color(0xFFC89D93)),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
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
                            final absoluteUrl = await ApiService.uploadImage(bytes, file.name);
                            
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
                                  partnerId: '00000000-0000-0000-0000-000000000000',
                                  partnerName: 'EstiloFonty IA',
                                  partnerRole: 'admin',
                                  partnerAvatar: '',
                                  initialMessage: 'Hola, me interesa saber si el estilo de $providerName va con mi rostro y cabello.',
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
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC89D93),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
