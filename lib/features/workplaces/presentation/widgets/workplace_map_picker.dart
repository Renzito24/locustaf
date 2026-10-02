import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/services/geocoding_service.dart';
import 'workplace_map_picker_components.dart';

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
        MapSearchField(
          controller: _searchController,
          hasText: _searchController.text.isNotEmpty,
          onClear: () {
            _searchController.clear();
            setState(() => _suggestions = []);
          },
          onChanged: (value) {
            if (value.length >= 3) {
              _searchLocation(value);
            } else {
              setState(() => _suggestions = []);
            }
          },
        ),
        if (_suggestions.isNotEmpty)
          MapSuggestionsList(
            suggestions: _suggestions,
            onSelect: _selectSuggestion,
          ),
        const SizedBox(height: 12),
        if (kIsWeb) ...[
          WebLocationPickerView(
            marker: _marker,
            isLoadingLocation: _isLoadingLocation,
            onUseMyLocation: _useMyLocation,
          ),
        ] else ...[
          FlutterMapLocationPickerView(
            mapController: _mapController,
            center: _center,
            marker: _marker,
            isLoadingLocation: _isLoadingLocation,
            onMapTap: _onMapTap,
            onUseMyLocation: _useMyLocation,
          ),
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
}
