// Things the person keeps or sends: letters, referrals, and the organisations and places they can contact.
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is String) return DateTime.tryParse(v);
  return null;
}

class SavedLetter {
  SavedLetter({
    required this.id,
    required this.letterType,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.citations = const [],
  });

  factory SavedLetter.fromJson(String id, Map<String, dynamic> j) => SavedLetter(
        id: id,
        letterType: j['letter_type']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Letter',
        content: j['content']?.toString() ?? '',
        updatedAt: _date(j['updated_at']) ?? DateTime.now(),
        citations: (j['citations'] as List? ?? const []).map((e) => e.toString()).toList(),
      );

  final String id;
  final String letterType;
  final String title;
  final String content;
  final DateTime updatedAt;

  /// "Landlord and Tenant Act, 2022 s.38" style labels of the sections the letter cites.
  final List<String> citations;

  Map<String, dynamic> toJson() => {
        'letter_type': letterType,
        'title': title,
        'content': content,
        'updated_at': updatedAt.toIso8601String(),
        'citations': citations,
      };
}

const List<String> referralStatuses = ['sent', 'seen', 'contacted', 'closed'];

class Referral {
  Referral({
    required this.id,
    required this.organisationId,
    required this.organisationName,
    required this.status,
    required this.createdAt,
    this.situation,
    this.summary,
    this.phone,
  });

  factory Referral.fromFirestore(String id, Map<String, dynamic> j) => Referral(
        id: id,
        organisationId: j['organisation_id']?.toString() ?? '',
        organisationName: j['organisation_name']?.toString() ?? '',
        status: j['status']?.toString() ?? 'sent',
        createdAt: _date(j['created_at']) ?? DateTime.now(),
        situation: j['situation']?.toString(),
        summary: j['summary']?.toString(),
        phone: j['phone']?.toString(),
      );

  final String id;
  final String organisationId;
  final String organisationName;
  final String status;
  final DateTime createdAt;
  final String? situation;
  final String? summary;
  final String? phone;
}

class SupportOrganisation {
  SupportOrganisation({
    required this.id,
    required this.name,
    required this.type,
    required this.languages,
    required this.situations,
    required this.sourceUrl,
    required this.verifiedBy,
    required this.verifiedOn,
    required this.acceptsReferrals,
    this.demo = false,
    this.phone,
    this.email,
    this.address,
    this.district,
  });

  factory SupportOrganisation.fromFirestore(String id, Map<String, dynamic> j) => SupportOrganisation(
        id: id,
        name: j['name']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        phone: j['phone']?.toString(),
        email: j['email']?.toString(),
        address: j['address']?.toString(),
        district: j['district']?.toString(),
        languages: (j['languages'] as List? ?? const []).map((e) => e.toString()).toList(),
        situations: (j['situations'] as List? ?? const []).map((e) => e.toString()).toList(),
        sourceUrl: j['source_url']?.toString() ?? '',
        verifiedBy: j['verified_by']?.toString() ?? '',
        verifiedOn: j['verified_on']?.toString() ?? '',
        acceptsReferrals: j['accepts_referrals'] == true,
        demo: j['demo'] == true,
      );

  final String id;
  final String name;
  final String type;
  final String? phone;
  final String? email;
  final String? address;
  final String? district;
  final List<String> languages;
  final List<String> situations;
  final String sourceUrl;
  final String verifiedBy;
  final String verifiedOn;
  final bool acceptsReferrals;

  /// A made-up organisation for demonstrations (see server/data/demo_support_organisations.csv).
  final bool demo;
}

/// A live Google Places search result. Not a verified partner.
class NearbyPlace {
  NearbyPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    this.phone,
    this.mapsUrl,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> j) => NearbyPlace(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        phone: j['phone']?.toString(),
        mapsUrl: j['maps_url']?.toString(),
      );

  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String? phone;
  final String? mapsUrl;
}

/// A saved chat: the questions asked (or document scanned) and the answers, to reopen later.
class SavedConversation {
  SavedConversation({
    required this.id,
    required this.title,
    required this.isScan,
    required this.turns,
    required this.updatedAt,
    this.situationId,
  });

  factory SavedConversation.fromJson(String id, Map<String, dynamic> j) => SavedConversation(
        id: id,
        title: j['title']?.toString() ?? '',
        isScan: j['is_scan'] == true,
        situationId: j['situation']?.toString(),
        turns: (j['turns'] as List? ?? const []).map((t) => Map<String, dynamic>.from(t as Map)).toList(),
        updatedAt: _date(j['updated_at']) ?? DateTime.now(),
      );

  final String id;

  /// The first question, or the document type for a scan.
  final String title;
  final bool isScan;
  final String? situationId;

  /// Each turn as saved by Turn.toJson.
  final List<Map<String, dynamic>> turns;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'title': title,
        'is_scan': isScan,
        if (situationId != null) 'situation': situationId,
        'turns': turns,
        'updated_at': updatedAt.toIso8601String(),
      };
}
