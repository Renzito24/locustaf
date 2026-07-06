import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_colors.dart';
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
    _geocodingService.dispose();
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
            const SnackBar(content: Text('Habilita la ubicación del dispositivo')),
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
              const SnackBar(content: Text('Permiso de ubicación denegado')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
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
          SnackBar(content: Text('Error al obtener ubicación: $e')),
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
        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar dirección',
            hintText: 'Escribe una dirección para buscar...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
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
        // Suggestions dropdown
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on, size: 18),
                  title: Text(
                    suggestion.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () => _selectSuggestion(suggestion),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        // Map
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
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
                    flags: InteractiveFlag.all,
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
                child: FloatingActionButton.small(
                  heroTag: 'myLocation',
                  onPressed: _isLoadingLocation ? null : _useMyLocation,
                  backgroundColor: Colors.white,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Coordinates display
        if (_marker != null)
          Text(
            'Lat: ${_marker!.latitude.toStringAsFixed(6)}, Lng: ${_marker!.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }
}
