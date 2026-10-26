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
import '../widgets/layout.dart';
import '../widgets/tr.dart';
import 'referral_screen.dart';

Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// On Home and under every answer: a short way into Get help.
class GetHelpCard extends StatelessWidget {
  const GetHelpCard({super.key, this.situationId, this.summary});

  final String? situationId;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.support_agent, color: scheme.onSecondaryContainer)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.tr('Need someone to help with your case?'),
                      style: theme.textTheme.titleMedium?.copyWith(color: scheme.onSecondaryContainer)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(context.tr('Find legal aid offices near you, or ask a verified organisation for help.'),
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSecondaryContainer)),
            const SizedBox(height: kGap),
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
    final showMap = mapsEnabled && _position != null && (_places?.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Get help'))),
      body: showMap ? _mapLayout(context) : PageBody(maxWidth: 720, children: _content(context)),
    );
  }

  /// A full-width map with the results in a sheet that can be dragged up.
  Widget _mapLayout(BuildContext context) {
    final places = _places!;
    return Stack(
      children: [
        GoogleMap(
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
        DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.15,
          maxChildSize: 0.9,
          builder: (context, controller) => Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            elevation: 1,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const Center(child: _DragHandle()),
                ..._content(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return [
      SectionTitle(context.tr('Legal aid near you')),
      Text(context.tr('Search results from Google Maps. These are not Eddembe partners; please check before you go.'),
          style: muted),
      const SizedBox(height: kGap),
      if (_places == null)
        FilledButton.icon(
          onPressed: _searching ? null : _findNearby,
          icon: _searching
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: Text(context.tr(_searching ? 'Searching near you...' : 'Find legal aid near me')),
        ),
      if (_placesError != null) ...[
        const SizedBox(height: 8),
        Text(context.tr(_placesError!), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _open(_searchInMaps),
          icon: const Icon(Icons.map_outlined),
          label: Text(context.tr('Search in Google Maps instead')),
        ),
      ],
      if (_places != null && _places!.isEmpty) ...[
        Text(context.tr('No legal aid offices were found near you.'), style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _open(_searchInMaps),
          icon: const Icon(Icons.map_outlined),
          label: Text(context.tr('Search in Google Maps')),
        ),
      ],
      if (_places != null)
        for (final p in _places!)
          Card.outlined(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(p.name),
              subtitle: Text(p.address),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.phone != null)
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      tooltip: '${context.tr('Call')} ${p.phone}',
                      onPressed: () => _open('tel:${p.phone!.replaceAll(' ', '')}'),
                    ),
                  if (p.mapsUrl != null)
                    IconButton(
                      icon: const Icon(Icons.directions_outlined),
                      tooltip: context.tr('Directions'),
                      onPressed: () => _open(p.mapsUrl!),
                    ),
                ],
              ),
            ),
          ),
      SectionTitle(context.tr('Verified organisations')),
      Text(context.tr('Checked by the Eddembe team.'), style: muted),
      const SizedBox(height: 8),
      FutureBuilder<List<SupportOrganisation>>(
        future: _verified,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator();
          final orgs = snap.data ?? const [];
          if (orgs.isEmpty) {
            return EmptyState(
              icon: Icons.verified_outlined,
              message: context.tr(
                  'Our team has not added verified organisations yet. Until then, please use the search results above.'),
            );
          }
          return Column(children: [for (final o in orgs) _OrganisationTile(org: o, screen: widget)]);
        },
      ),
      const DisclaimerFooter(),
    ];
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _OrganisationTile extends StatelessWidget {
  const _OrganisationTile({required this.org, required this.screen});

  final SupportOrganisation org;
  final GetHelpScreen screen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(org.name),
              subtitle: Text([
                context.tr(org.type),
                if (org.district != null) org.district!,
                if (org.languages.isNotEmpty) org.languages.join(', '),
              ].join(' · ')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (org.phone != null)
                    IconButton(
                      icon: const Icon(Icons.call_outlined),
                      tooltip: '${context.tr('Call')} ${org.phone}',
                      onPressed: () => _open('tel:${org.phone!.replaceAll(' ', '')}'),
                    ),
                  // Demo organisations have example.org addresses that lead nowhere.
                  if (org.email != null && !org.demo)
                    IconButton(
                      icon: const Icon(Icons.email_outlined),
                      tooltip: context.tr('Email'),
                      onPressed: () => _open('mailto:${org.email}'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (org.demo)
                    Chip(
                      avatar: Icon(Icons.science_outlined, color: scheme.onSecondaryContainer),
                      label: Text(context.tr('Demo · not a real organisation')),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(color: scheme.onSecondaryContainer),
                      backgroundColor: scheme.secondaryContainer,
                      side: BorderSide.none,
                    )
                  else
                    Chip(
                      avatar: Icon(Icons.verified, color: scheme.onTertiaryContainer),
                      label: Text('${context.tr('Verified on')} ${org.verifiedOn}'),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(color: scheme.onTertiaryContainer),
                      backgroundColor: scheme.tertiaryContainer,
                      side: BorderSide.none,
                    ),
                  if (org.sourceUrl.isNotEmpty && !org.demo)
                    TextButton(onPressed: () => _open(org.sourceUrl), child: Text(context.tr('Source'))),
                  if (org.acceptsReferrals)
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReferralScreen(organisation: org, situationId: screen.situationId, summary: screen.summary),
                        ),
                      ),
                      icon: const Icon(Icons.send),
                      label: Text(context.tr('Request help')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
