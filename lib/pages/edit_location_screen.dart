import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/travel_provider.dart';
import 'package:wajeeh/widgets/app_footer.dart';
import '../localization/app_localizations.dart';
import '../localization/error_mapper.dart';

class EditLocationScreen extends StatefulWidget {
  const EditLocationScreen({super.key});

  @override
  State<EditLocationScreen> createState() => _EditLocationScreenState();
}

class _EditLocationScreenState extends State<EditLocationScreen> {
  GoogleMapController? _mapController;

  LatLng _selectedLocation = const LatLng(23.5880, 58.3829);

  final Set<Marker> _markers = {};

  bool _locationPermissionGranted = false;
  bool _isLoading = true;

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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    _locationPermissionGranted = true;
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

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
  }

  void _setMarker(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _markers.clear();
      _markers.add(
        Marker(markerId: const MarkerId("selected"), position: position),
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
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                // keep dropdown visible when keyboard open
                maxHeight: availableSuggestionHeight.clamp(140.0, 280.0),
              ),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
                itemBuilder: (context, i) {
                  final place = _suggestions[i];
                  final travel = context.read<TravelProvider>();
                  final title = travel.placeName(place);
                  final sub = travel.placeAddress(place);
                  return ListTile(
                    dense: true,
                    title: Text(title),
                    subtitle: sub.isEmpty
                        ? null
                        : Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("location_updated_success"))),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(mapErrorToKeyFromObject(e)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mapHeight =
        (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) *
            0.30;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                Image.asset("images/logo.png", height: 50),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.center,
              child: Text(
                context.tr("edit_your_location"),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDark ? const Color(0xFFF5A623) : null,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr("edit_location_subtitle"),
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF89B0D8)
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _locationSearch(context),
            const SizedBox(height: 16),
            Text(
              context.tr("current_location"),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: mapHeight.clamp(180.0, 320.0),
                width: double.infinity,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation,
                        zoom: 14,
                      ),
                      markers: _markers,
                      myLocationEnabled: _locationPermissionGranted,
                      myLocationButtonEnabled: _locationPermissionGranted,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _initLocation();
                      },
                      onTap: (position) {
                        _setMarker(position);
                      },
                    ),
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.location_on_outlined,
                  color:
                      isDark ? const Color(0xFFF5A623) : theme.colorScheme.primary,
                ),
                label: Text(
                  context.tr("set_location_on_map"),
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? const Color(0xFFF5A623)
                        : theme.colorScheme.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFFF5A623)
                        : theme.colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _confirmLocation,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(currentIndex: 4),
    );
  }
}
