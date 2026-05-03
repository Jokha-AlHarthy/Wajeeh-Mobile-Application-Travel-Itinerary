import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import 'package:geocoding/geocoding.dart';
import '../localization/app_localizations.dart';
import '../localization/error_mapper.dart';

class LocationSelectionPage extends StatefulWidget {
  const LocationSelectionPage({super.key});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  GoogleMapController? _mapController;

  LatLng _selectedLocation = const LatLng(23.5880, 58.3829);

  final Set<Marker> _markers = {};

  bool _locationPermissionGranted = false;
  bool _isLoading = true;
  bool _locationInitStarted = false;

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _suggestions = [];
  bool _suggestionsLoading = false;
  int _searchRequestId = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() {
      _locationPermissionGranted = true;
    });

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      if (!mounted) return;

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLocation = userLatLng;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("current"),
            position: userLatLng,
            infoWindow: InfoWindow(title: context.tr("you_are_here")),
          ),
        );
        _isLoading = false;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLatLng, 16),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _setMarker(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("selected"),
          position: position,
        ),
      );
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _suggestions = [];
        _suggestionsLoading = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (!mounted) return;
      final requestId = ++_searchRequestId;
      setState(() => _suggestionsLoading = true);
      final travel = context.read<TravelProvider>();
      final results = await travel.autocompletePlaces(q);
      if (!mounted) return;
      if (requestId != _searchRequestId) return;
      setState(() {
        _suggestions = results;
        _suggestionsLoading = false;
      });
    });
  }

  LatLng? _latLngFromPlace(Map<String, dynamic> place) {
    final loc = place['location'];
    if (loc is! Map) return null;
    final lat = loc['latitude'];
    final lng = loc['longitude'];
    if (lat is! num || lng is! num) return null;
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  Widget _locationSearch(BuildContext context) {
    final theme = Theme.of(context);
    final availableSuggestionHeight = (MediaQuery.of(context).size.height -
            MediaQuery.of(context).viewInsets.bottom) *
        0.28;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: context.tr("search"),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _suggestionsLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_searchController.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                        icon: const Icon(Icons.close),
                      )),
            filled: true,
            fillColor: theme.cardTheme.color ?? Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0C1C3D)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0C1C3D)),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF0C1C3D).withValues(alpha: 0.25)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: availableSuggestionHeight.clamp(140.0, 280.0),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: const Color(0xFF0C1C3D).withValues(alpha: 0.15),
                ),
                itemBuilder: (context, i) {
                  final place = _suggestions[i];
                  final travel = context.read<TravelProvider>();
                  final title = travel.placeName(place);
                  final sub = travel.placeAddress(place);
                  return ListTile(
                    dense: true,
                    title: Text(
                      title,
                      style: const TextStyle(color: Color(0xFF0C1C3D)),
                    ),
                    subtitle: sub.isEmpty
                        ? null
                        : Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFF0C1C3D)),
                          ),
                    onTap: () {
                      final ll = _latLngFromPlace(place);
                      if (ll != null) {
                        _searchController.text = title;
                        _searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
                        _setMarker(ll);
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(ll, 14),
                        );
                      }
                      setState(() => _suggestions = []);
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _googleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _selectedLocation,
        zoom: 14,
      ),
      markers: _markers,
      myLocationEnabled: _locationPermissionGranted,
      myLocationButtonEnabled: _locationPermissionGranted,
      onMapCreated: (controller) {
        _mapController = controller;
        if (!_locationInitStarted) {
          _locationInitStarted = true;
          _initLocation();
        }
      },
      onTap: _setMarker,
    );
  }

  Widget _mapPreviewStack(BuildContext context) {
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        _googleMap(),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF0C1C3D),
            ),
          ),
      ],
    );
    if (Theme.of(context).platform == TargetPlatform.android) {
      return stack;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: stack,
    );
  }

  Future<void> _confirmLocation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      final place = placemarks.first;

      String placeName =
          "${place.locality ?? place.subAdministrativeArea ?? ""}, ${place.country ?? ""}";
      await authProvider.saveLocationWithName(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
        placeName,
      );

      await authProvider.logout();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("location_saved_success"))),
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamed(context, "/login");
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr(mapErrorToKeyFromObject(e)))),
      );
    }
  }

  Future<void> _skip() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.logout();

    Navigator.pushNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight =
        (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) *
            0.30;
    return Scaffold(
      backgroundColor: const Color(0xfff7f1e8),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0C1C3D)),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Image.asset(
                  "images/logo.png",
                  height: 50,
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              context.tr("set_your_location"),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C1C3D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr("set_location_subtitle"),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0C1C3D),
              ),
            ),
            const SizedBox(height: 16),
            _locationSearch(context),
            const SizedBox(height: 16),
            Text(
              context.tr("current_location"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0C1C3D),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: mapHeight.clamp(180.0, 320.0),
              width: double.infinity,
              child: _mapPreviewStack(context),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF0C1C3D),
                ),
                label: Text(
                  context.tr("set_location_on_map"),
                  style: const TextStyle(fontSize: 16, color: Color(0xFF0C1C3D)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0C1C3D)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmLocation,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _skip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C1C3D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.tr("skip_for_now"),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
