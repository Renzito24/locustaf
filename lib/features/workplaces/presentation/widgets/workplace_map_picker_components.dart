import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/services/geocoding_service.dart';

class MapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  const MapSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: AppTheme.inputDecoration(
        label: 'Buscar dirección',
        icon: Icons.search,
        hint: 'Escribe una dirección para buscar...',
      ).copyWith(
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textMuted),
                onPressed: onClear,
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }
}

class MapSuggestionsList extends StatelessWidget {
  final List<GeocodingResult> suggestions;
  final ValueChanged<GeocodingResult> onSelect;

  const MapSuggestionsList({
    super.key,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppTheme.radiusLg)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.location_on, size: 18, color: AppColors.gold),
              title: Text(
                suggestion.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodyMd,
              ),
              onTap: () => onSelect(suggestion),
            );
          },
        ),
      ),
    );
  }
}

class WebLocationPickerView extends StatelessWidget {
  final LatLng? marker;
  final bool isLoadingLocation;
  final VoidCallback onUseMyLocation;

  const WebLocationPickerView({
    super.key,
    required this.marker,
    required this.isLoadingLocation,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  marker != null
                      ? 'Ubicación seleccionada'
                      : 'Seleccioná una ubicación',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'En la versión web el mapa no está disponible. Usá el buscador de arriba o el botón para usar tu ubicación actual.',
            style: AppTheme.bodyMd,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoadingLocation ? null : onUseMyLocation,
              icon: isLoadingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(isLoadingLocation ? 'Obteniendo...' : 'Usar mi ubicación'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (marker != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordenadas: ${marker!.latitude.toStringAsFixed(6)}, ${marker!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: AppColors.textWhite, fontSize: 12),
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

class FlutterMapLocationPickerView extends StatelessWidget {
  final MapController mapController;
  final LatLng? center;
  final LatLng? marker;
  final bool isLoadingLocation;
  final Function(TapPosition, LatLng) onMapTap;
  final VoidCallback onUseMyLocation;

  const FlutterMapLocationPickerView({
    super.key,
    required this.mapController,
    required this.center,
    required this.marker,
    required this.isLoadingLocation,
    required this.onMapTap,
    required this.onUseMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: center ?? const LatLng(-34.6037, -58.3816),
              initialZoom: marker != null ? 15 : 4,
              onTap: onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.locustaf.app',
              ),
              if (marker != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: marker!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.error,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: isLoadingLocation ? null : onUseMyLocation,
                icon: isLoadingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      )
                    : const Icon(Icons.my_location, color: AppColors.gold, size: 20),
                tooltip: 'Mi ubicación',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
