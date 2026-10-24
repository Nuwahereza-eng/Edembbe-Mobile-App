import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../models/records.dart';
import '../services/api_client.dart';
import '../services/app_state.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/tr.dart';
import 'referral_screen.dart';

Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// Shown under every answer: a short way into Get help.
class GetHelpCard extends StatelessWidget {
  const GetHelpCard({super.key, this.situationId, this.summary});

  final String? situationId;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.support_agent, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.tr('Need someone to help with your case?'),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(context.tr('Find legal aid offices near you, or ask a verified organisation for help.'),
                style: TextStyle(fontSize: 15, color: scheme.onPrimaryContainer)),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.place_outlined),
              label: Text(context.tr('Find help near me')),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GetHelpScreen(situationId: situationId, summary: summary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nearby legal aid from live Google Places results (search results, not partners), then the
/// organisations our team has verified, which can receive a referral request.
class GetHelpScreen extends StatefulWidget {
  const GetHelpScreen({super.key, this.situationId, this.summary});

  final String? situationId;
  final String? summary;

  @override
  State<GetHelpScreen> createState() => _GetHelpScreenState();
}

class _GetHelpScreenState extends State<GetHelpScreen> {
  late final Future<List<SupportOrganisation>> _verified;
  bool _searching = false;
  String? _placesError;
  Position? _position;
  List<NearbyPlace>? _places;

  static const _searchInMaps = 'https://www.google.com/maps/search/?api=1&query=legal%20aid%20Uganda';

  @override
  void initState() {
    super.initState();
    _verified = context.read<AppState>().support.verified(situationId: widget.situationId);
  }

  Future<void> _findNearby() async {
    final app = context.read<AppState>();
    setState(() {
      _searching = true;
      _placesError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw ApiException('Please turn on location to find help near you.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw ApiException('Please allow location to find help near you.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 20)),
      );
      final places = await app.api.nearbyLegalAid(position.latitude, position.longitude);
      setState(() {
        _position = position;
        _places = places;
      });
    } on ApiException catch (e) {
      setState(() => _placesError = e.message);
    } catch (e) {
      debugPrint('Nearby search failed: $e');
      setState(() => _placesError = 'We could not search near you right now.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Get help'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(context.tr('Legal aid near you'), style: titleStyle),
            const SizedBox(height: 4),
            Text(
              context.tr('Search results from Google Maps. These are not Eddembe partners; please check before you go.'),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (_places == null)
              FilledButton.icon(
                onPressed: _searching ? null : _findNearby,
                icon: _searching
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(context.tr(_searching ? 'Searching near you...' : 'Find legal aid near me')),
              ),
            if (_placesError != null) ...[
              const SizedBox(height: 8),
              Text(context.tr(_placesError!), style: const TextStyle(fontSize: 14, color: Color(0xFFB3261E))),
              TextButton.icon(
                onPressed: () => _open(_searchInMaps),
                icon: const Icon(Icons.map_outlined),
                label: Text(context.tr('Search in Google Maps instead')),
              ),
            ],
            if (_places != null) ..._results(context),
            const SizedBox(height: 24),
            Text(context.tr('Verified organisations'), style: titleStyle),
            const SizedBox(height: 4),
            Text(context.tr('Checked by the Eddembe team.'), style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 12),
            FutureBuilder<List<SupportOrganisation>>(
              future: _verified,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
                final orgs = snap.data ?? const [];
                if (orgs.isEmpty) {
                  return Text(
                    context.tr('Our team has not added verified organisations yet. Until then, please use the search results above.'),
                    style: const TextStyle(fontSize: 15),
                  );
                }
                return Column(children: [for (final o in orgs) _OrganisationCard(org: o, widget: widget)]);
              },
            ),
            const SizedBox(height: 20),
            const DisclaimerFooter(),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
    final places = _places!;
    if (places.isEmpty) {
      return [
        Text(context.tr('No legal aid offices were found near you.'), style: const TextStyle(fontSize: 15)),
        TextButton.icon(
          onPressed: () => _open(_searchInMaps),
          icon: const Icon(Icons.map_outlined),
          label: Text(context.tr('Search in Google Maps')),
        ),
      ];
    }
    return [
      if (mapsEnabled && _position != null)
        Container(
          height: 260,
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: LatLng(_position!.latitude, _position!.longitude), zoom: 11),
            myLocationEnabled: true,
            markers: {
              for (final p in places)
                Marker(
                  markerId: MarkerId(p.id),
                  position: LatLng(p.lat, p.lng),
                  infoWindow: InfoWindow(title: p.name, snippet: p.address),
                ),
            },
          ),
        ),
      for (final p in places)
        Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(p.address, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                Row(
                  children: [
                    if (p.phone != null)
                      TextButton.icon(
                        onPressed: () => _open('tel:${p.phone!.replaceAll(' ', '')}'),
                        icon: const Icon(Icons.call),
                        label: Text(p.phone!),
                      ),
                    if (p.mapsUrl != null)
                      TextButton.icon(
                        onPressed: () => _open(p.mapsUrl!),
                        icon: const Icon(Icons.directions),
                        label: Text(context.tr('Directions')),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

class _OrganisationCard extends StatelessWidget {
  const _OrganisationCard({required this.org, required this.widget});

  final SupportOrganisation org;
  final GetHelpScreen widget;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Expanded(child: Text(org.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 4),
            Text([context.tr(org.type), if (org.district != null) org.district!].join(' · '),
                style: const TextStyle(fontSize: 14)),
            if (org.address != null) Text(org.address!, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            if (org.languages.isNotEmpty)
              Text('${context.tr('Languages')}: ${org.languages.join(', ')}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              '${context.tr('Verified on')} ${org.verifiedOn} ${context.tr('by')} ${org.verifiedBy}',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            Wrap(
              spacing: 4,
              children: [
                if (org.phone != null)
                  TextButton.icon(
                    onPressed: () => _open('tel:${org.phone!.replaceAll(' ', '')}'),
                    icon: const Icon(Icons.call),
                    label: Text(org.phone!),
                  ),
                if (org.email != null)
                  TextButton.icon(
                    onPressed: () => _open('mailto:${org.email}'),
                    icon: const Icon(Icons.email_outlined),
                    label: Text(context.tr('Email')),
                  ),
                if (org.sourceUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _open(org.sourceUrl),
                    icon: const Icon(Icons.link),
                    label: Text(context.tr('Source')),
                  ),
              ],
            ),
            if (org.acceptsReferrals)
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ReferralScreen(organisation: org, situationId: widget.situationId, summary: widget.summary),
                  ),
                ),
                icon: const Icon(Icons.send),
                label: Text(context.tr('Request help')),
              ),
          ],
        ),
      ),
    );
  }
}
