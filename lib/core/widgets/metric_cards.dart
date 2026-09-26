import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_card.dart';

/// Dato estático de una tarjeta de métrica.
class MetricCardData {
  const MetricCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

/// Grilla responsiva de tarjetas de métricas que nunca desborda en vertical.
///
/// Calcula el ancho de cada tarjeta según el ancho disponible (4/2/1 columnas,
/// igual que el diseño previo) pero deja que su altura sea la del contenido
/// (Wrap + altura intrínseca), evitando los `BOTTOM OVERFLOWED` que generaba
/// la implementación previa con `GridView.count` + `childAspectRatio` fija
/// dentro de una `Column` no scrolleable. (Fase B — B1/B2)
class MetricCardsGrid extends StatelessWidget {
  const MetricCardsGrid({
    super.key,
    required this.cards,
    this.spacing = 16,
  });

  final List<MetricCardData> cards;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= 800
            ? 4
            : width >= 500
                ? 2
                : 1;
        final cardWidth = width == double.infinity
            ? double.infinity
            : (width - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _MetricCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withValues(alpha: 0.15),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
                Text(
                  data.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
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