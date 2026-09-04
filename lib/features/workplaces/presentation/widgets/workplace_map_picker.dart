import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/geocoding_service.dart';

class WorkplaceMapPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final ValueChanged<double>? onLatitudeChanged;
  final ValueChanged<double>? onLongitudeChanged;
  final ValueChanged<String?>? onAddressChanged;

  const WorkplaceMapPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.onLatitudeChanged,
    this.onLongitudeChanged,
    this.onAddressChanged,
  });

  @override
  State<WorkplaceMapPicker> createState() => _WorkplaceMapPickerState();
}

class _WorkplaceMapPickerState extends State<WorkplaceMapPicker> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _geocodingService = GeocodingService();

  LatLng? _center;
  LatLng? _marker;
  List<GeocodingResult> _suggestions = [];
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _marker = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _center = _marker;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _marker = point;
      _center = point;
    });
    widget.onLatitudeChanged?.call(point.latitude);
    widget.onLongitudeChanged?.call(point.longitude);
    _reverseGeocode(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    final address = await _geocodingService.reverse(point.latitude, point.longitude);
    if (mounted) {
      setState(() {});
      widget.onAddressChanged?.call(address);
      if (address != null) {
        _searchController.text = address;
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final results = await _geocodingService.search(query);
    if (mounted) {
      setState(() => _suggestions = results);
    }
  }

  void _selectSuggestion(GeocodingResult result) {
    final point = LatLng(result.lat, result.lng);
    setState(() {
      _marker = point;
      _center = point;
      _suggestions = [];
      _searchController.text = result.displayName;
    });
    widget.onLatitudeChanged?.call(result.lat);
    widget.onLongitudeChanged?.call(result.lng);
    widget.onAddressChanged?.call(result.displayName);
    _mapController.move(point, 15);
  }

  Future<void> _useMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Habilita la ubicación del dispositivo'),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar('Permiso de ubicación denegado'),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppTheme.errorSnackBar('Permiso de ubicación denegado permanentemente'),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final point = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _marker = point;
          _center = point;
        });
        widget.onLatitudeChanged?.call(point.latitude);
        widget.onLongitudeChanged?.call(point.longitude);
        _mapController.move(point, 15);
        _reverseGeocode(point);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al obtener ubicación: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: AppTheme.inputDecoration(
            label: 'Buscar dirección',
            icon: Icons.search,
            hint: 'Escribe una dirección para buscar...',
          ).copyWith(
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textMuted),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _suggestions = []);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            if (value.length >= 3) {
              _searchLocation(value);
            } else {
              setState(() => _suggestions = []);
            }
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.25),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLg)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, size: 18, color: AppColors.gold),
                  title: Text(
                    suggestion.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyMd,
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        if (kIsWeb) ...[
          _buildWebLocationPicker(),
        ] else ...[
          _buildMapLocationPicker(),
        ],
        const SizedBox(height: 8),
        if (_marker != null)
          Text(
            'Lat: ${_marker!.latitude.toStringAsFixed(6)}, Lng: ${_marker!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }

  Widget _buildWebLocationPicker() {
    return Container(
      decoration: AppTheme.cardDecoration(),
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
                  _marker != null
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
              onPressed: _isLoadingLocation ? null : _useMyLocation,
              icon: _isLoadingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.my_location, size: 18),
              label: Text(_isLoadingLocation ? 'Obteniendo...' : 'Usar mi ubicación'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_marker != null)
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
                      'Coordenadas: ${_marker!.latitude.toStringAsFixed(6)}, ${_marker!.longitude.toStringAsFixed(6)}',
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

  Widget _buildMapLocationPicker() {
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
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center ?? const LatLng(-34.6037, -58.3816),
              initialZoom: _marker != null ? 15 : 4,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.locustaf.app',
              ),
              if (_marker != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _marker!,
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
                onPressed: _isLoadingLocation ? null : _useMyLocation,
                icon: _isLoadingLocation
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
