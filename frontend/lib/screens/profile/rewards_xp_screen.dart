// lib/screens/profile/rewards_xp_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../services/membership_service.dart';

class RewardsXpScreen extends StatefulWidget {
  const RewardsXpScreen({super.key});

  @override
  State<RewardsXpScreen> createState() => _RewardsXpScreenState();
}

class _RewardsXpScreenState extends State<RewardsXpScreen> {
  bool _isLoading = true;
  String _levelName = 'SOCIO CLUB GLOW';
  int _totalHistoricalXp = 0;
  int _auraCoinsBalance = 0;
  String _nextTierName = 'SOCIO SILVER LUXE';
  int _nextTierRequiredXp = 500;
  double _progressPercentage = 0.0;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadTierProfile();
  }

  Future<void> _loadTierProfile() async {
    setState(() => _isLoading = true);
    final data = await MembershipService.fetchUserTierProfile();
    if (data != null && mounted) {
      setState(() {
        _levelName = data['levelName'] ?? 'SOCIO CLUB GLOW';
        _totalHistoricalXp = data['totalHistoricalXp'] ?? 0;
        _auraCoinsBalance = data['auraCoinsBalance'] ?? 0;

        final nextTier = data['nextTier'];
        if (nextTier != null) {
          _nextTierName = nextTier['levelName'] ?? 'SIGUIENTE NIVEL';
          _nextTierRequiredXp = nextTier['requiredXp'] ?? 500;
          final double progress = (data['totalHistoricalXp'] ?? 0) / _nextTierRequiredXp;
          _progressPercentage = progress.clamp(0.0, 1.0);
        } else {
          _nextTierName = 'NIVEL MÁXIMO CONCIERGE';
          _progressPercentage = 1.0;
        }
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemCoins(int coins) async {
    setState(() => _isRedeeming = true);
    final result = await MembershipService.redeemCoins(coins);
    setState(() => _isRedeeming = false);

    if (mounted) {
      if (result != null && result['success'] == true) {
        final coupon = result['couponCode'];
        final discount = result['discountCop'];
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('✨ Cupón Canjeado con Éxito'),
            content: Text('Tu código de cupón es: $coupon\nValor de Descuento: \$$discount COP'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadTierProfile();
                },
                child: const Text('Entendido'),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Saldo insuficiente de Aura Coins'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'CLUB GLOW LUXE & AURA COINS',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFC5A052)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(LuxeSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TARJETA DORADA DE MEMBRESÍA VIP Y AURA COINS
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(LuxeSpacing.xl),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFAA7C11)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFAA7C11).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _levelName.toUpperCase(),
                                    style: const TextStyle(
                                      fontFamily: 'Didot',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_totalHistoricalXp XP',
                                        style: const TextStyle(
                                          fontFamily: 'Didot',
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Text(
                                        'PUNTOS DE ESTATUS HISTÓRICOS',
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 9,
                                          color: Colors.white70,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$_auraCoinsBalance Coins',
                                        style: const TextStyle(
                                          fontFamily: 'Didot',
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFF4D0),
                                        ),
                                      ),
                                      const Text(
                                        'SALDO CANJEABLE',
                                        style: TextStyle(
                                          fontFamily: 'JetBrainsMono',
                                          fontSize: 9,
                                          color: Colors.white70,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // BARRA DE PROGRESO AL SIGUIENTE NIVEL
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Nivel: $_levelName',
                                        style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 13, color: Colors.white),
                                      ),
                                      Text(
                                        'Siguiente: $_nextTierName',
                                        style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: _progressPercentage,
                                      minHeight: 6,
                                      backgroundColor: Colors.white24,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                                                const SizedBox(height: LuxeSpacing.xxl),

                        // BANNER INFORMATIVO CLARO Y EXPLICATIVO
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFC5A052).withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFC5A052), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '¿Cómo funciona el Club Glow?',
                                    style: TextStyle(
                                      fontFamily: 'Didot',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: LuxeColors.nude900,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10),
                              Text(
                                '💎 Puntos XP (Estatus): Se acumulan históricamente con cada cita y compra. NUNCA caducan ni se reducen al canjear descuentos; determinan tu nivel de membresía (Club ➔ Silver ➔ Gold ➔ Black).\n\n'
                                '🪙 Aura Coins (Saldo Canjeable): Es el saldo de dinero virtual que ganas por cashback e interacciones. Puedes canjearlas en cualquier momento por cupones de descuento en COP.\n\n'
                                '⚡ ¿Cómo ganar más Puntos?\n'
                                '• 1 Cita completada = 50 XP (+10 XP por cada \$50k)\n'
                                '• \$10.000 COP en GlowStore = 10 XP (+25 XP bonus Match Piel)\n'
                                '• Publicar en Instagram/TikTok/FB = 150 XP (Glow Ambassador)\n'
                                '• 1 Diagnóstico biométrico = 20 XP',
                                style: TextStyle(
                                  fontFamily: 'CormorantGaramond',
                                  fontSize: 13,
                                  color: LuxeColors.nude700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: LuxeSpacing.xxl),

                        const Text(
                          'CANJEAR AURA COINS POR DESCUENTOS',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LuxeColors.nude500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildRedeemTile(
                          coins: 100,
                          discountText: '\$5.000 COP de Descuento',
                          onRedeem: () => _redeemCoins(100),
                        ),
                        _buildRedeemTile(
                          coins: 500,
                          discountText: '\$25.000 COP de Descuento',
                          onRedeem: () => _redeemCoins(500),
                        ),
                        _buildRedeemTile(
                          coins: 1000,
                          discountText: '\$55.000 COP (10% Bonus extra)',
                          onRedeem: () => _redeemCoins(1000),
                        ),

                        const SizedBox(height: LuxeSpacing.xxl),

                        const Text(
                          'BENEFICIOS ACTIVOS POR NIVEL',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: LuxeColors.nude500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildBenefitTile(
                          icon: Icons.star_outline,
                          title: 'Cashback en Aura Coins',
                          subtitle: 'Obtén hasta 10% de devolución en compras y citas',
                        ),
                        _buildBenefitTile(
                          icon: Icons.headset_mic_outlined,
                          title: 'Canal Prioritario Concierge',
                          subtitle: 'Soporte VIP por WhatsApp en menos de 15 minutos',
                        ),
                        _buildBenefitTile(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Diagnósticos Facial & Capilar IA',
                          subtitle: 'Seguimiento biométrico inteligente de tu piel',
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildRedeemTile({
    required int coins,
    required String discountText,
    required VoidCallback onRedeem,
  }) {
    final bool canAfford = _auraCoinsBalance >= coins;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: canAfford ? const Color(0xFFC5A052) : LuxeColors.nude200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A052).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFFC5A052), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  discountText,
                  style: const TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Costo: $coins Aura Coins',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 13,
                    color: canAfford ? const Color(0xFFC5A052) : LuxeColors.nude600,
                    fontWeight: canAfford ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canAfford && !_isRedeeming ? onRedeem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A052),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Canjear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LuxeColors.nude200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFC5A052).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFC5A052), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Didot',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: LuxeColors.nude900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 13,
                    color: LuxeColors.nude600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
