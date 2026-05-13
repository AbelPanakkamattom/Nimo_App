import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ===============================================================
/// CONTACT MODEL
/// ===============================================================
class ContactModel {
  final String id;
  final String userId;
  final String contactUserId;
  final String displayName;
  final String contactValue;
  final DateTime createdAt;

  const ContactModel({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.displayName,
    required this.contactValue,
    required this.createdAt,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    final customName =
        map['custom_name']?.toString().trim() ?? '';

    final contactValue =
        map['contact_value']?.toString().trim() ?? '';

    String displayName = customName;

    if (displayName.isEmpty) {
      if (contactValue.isNotEmpty &&
          contactValue.contains('@')) {
        displayName =
            contactValue.split('@').first;
      } else if (contactValue.isNotEmpty) {
        displayName = contactValue;
      } else {
        displayName = 'Unknown';
      }
    }

    return ContactModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      contactUserId:
      map['contact_user_id']?.toString() ?? '',
      displayName: displayName,
      contactValue: contactValue,
      createdAt: DateTime.tryParse(
        map['created_at']?.toString() ?? '',
      ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'contact_user_id': contactUserId,
      'custom_name': displayName,
      'contact_value': contactValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ContactModel copyWith({
    String? id,
    String? userId,
    String? contactUserId,
    String? displayName,
    String? contactValue,
    DateTime? createdAt,
  }) {
    return ContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId:
      contactUserId ?? this.contactUserId,
      displayName:
      displayName ?? this.displayName,
      contactValue:
      contactValue ?? this.contactValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// ===============================================================
/// CONTACT SERVICE
/// ===============================================================
class ContactService {
  ContactService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  /// =============================================================
  /// AUTH
  /// =============================================================
  static User? get currentUser =>
      _supabase.auth.currentUser;

  static bool get isLoggedIn =>
      currentUser != null;

  static String get currentUserId {
    final user = currentUser;

    if (user == null) {
      throw Exception('User not logged in.');
    }

    return user.id;
  }

  static void _ensureLoggedIn() {
    if (!isLoggedIn) {
      throw Exception('User not logged in.');
    }
  }

  /// =============================================================
  /// GET CONTACTS
  /// =============================================================
  static Future<List<ContactModel>> getContacts() async {
    _ensureLoggedIn();

    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', currentUserId)
          .order(
        'created_at',
        ascending: false,
      );

      final contacts = (response as List)
          .map(
            (item) => ContactModel.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      contacts.sort(
            (a, b) => a.displayName
            .toLowerCase()
            .compareTo(
          b.displayName.toLowerCase(),
        ),
      );

      return contacts;
    } catch (e) {
      debugPrint(
        'ContactService.getContacts error: $e',
      );
      rethrow;
    }
  }

  /// =============================================================
  /// WATCH CONTACTS
  /// =============================================================
  static Stream<List<ContactModel>>
  watchContacts() {
    if (!isLoggedIn) {
      return Stream.value(
        <ContactModel>[],
      );
    }

    return _supabase
        .from('contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .map((rows) {
      final contacts = rows
          .map(
            (row) => ContactModel.fromMap(
          Map<String, dynamic>.from(row),
        ),
      )
          .toList();

      contacts.sort(
            (a, b) => a.displayName
            .toLowerCase()
            .compareTo(
          b.displayName.toLowerCase(),
        ),
      );

      return contacts;
    }).handleError((error) {
      debugPrint(
        'ContactService.watchContacts error: $error',
      );

      return <ContactModel>[];
    });
  }

  /// =============================================================
  /// CONTACT EXISTS
  /// =============================================================
  static Future<bool> contactExists(
      String contactUserId,
      ) async {
    _ensureLoggedIn();

    final trimmedId =
    contactUserId.trim();

    if (trimmedId.isEmpty) {
      return false;
    }

    try {
      final response = await _supabase
          .from('contacts')
          .select('id')
          .eq('user_id', currentUserId)
          .eq(
        'contact_user_id',
        trimmedId,
      )
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint(
        'ContactService.contactExists error: $e',
      );

      return false;
    }
  }

  /// =============================================================
  /// GET CONTACT BY USER ID
  /// =============================================================
  static Future<ContactModel?>
  getContactByUserId(
      String contactUserId,
      ) async {
    _ensureLoggedIn();

    final trimmedId =
    contactUserId.trim();

    if (trimmedId.isEmpty) {
      return null;
    }

    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('user_id', currentUserId)
          .eq(
        'contact_user_id',
        trimmedId,
      )
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ContactModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      debugPrint(
        'ContactService.getContactByUserId error: $e',
      );

      return null;
    }
  }

  /// =============================================================
  /// FIND USER BY EMAIL
  /// =============================================================
  static Future<Map<String, dynamic>?>
  findUserByEmail(
      String email,
      ) async {
    _ensureLoggedIn();

    final searchEmail =
    email.trim().toLowerCase();

    if (searchEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    try {
      final results = await _supabase
          .from('profiles')
          .select(
        'id, email, name, avatar_url',
      );

      for (final row in results as List) {
        final map =
        Map<String, dynamic>.from(row);

        final rowEmail =
        (map['email'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (rowEmail == searchEmail) {
          return map;
        }
      }

      debugPrint(
        'No user found for email: $searchEmail',
      );

      return null;
    } catch (e) {
      debugPrint(
        'findUserByEmail error: $e',
      );

      rethrow;
    }
  }

  /// =============================================================
  /// ADD CONTACT BY EMAIL
  /// =============================================================
  static Future<ContactModel>
  addContactByEmail({
    required String email,
    String customName = '',
  }) async {
    _ensureLoggedIn();

    final profile =
    await findUserByEmail(email);

    if (profile == null) {
      throw Exception('User not found.');
    }

    final contactUserId =
        profile['id']?.toString() ?? '';

    final profileEmail =
        profile['email']?.toString() ?? '';

    final profileName =
        profile['name']
            ?.toString()
            .trim() ??
            '';

    if (contactUserId.isEmpty) {
      throw Exception('Invalid user.');
    }

    if (contactUserId == currentUserId) {
      throw Exception(
        'You cannot add yourself.',
      );
    }

    final exists =
    await contactExists(
      contactUserId,
    );

    if (exists) {
      throw Exception(
        'This contact is already saved.',
      );
    }

    final displayName =
    customName.trim().isNotEmpty
        ? customName.trim()
        : (profileName.isNotEmpty
        ? profileName
        : profileEmail
        .split('@')
        .first);

    return addContact(
      contactUserId: contactUserId,
      displayName: displayName,
      contactValue: profileEmail,
    );
  }

  /// =============================================================
  /// ADD CONTACT
  /// =============================================================
  static Future<ContactModel> addContact({
    required String contactUserId,
    required String displayName,
    String contactValue = '',
  }) async {
    _ensureLoggedIn();

    final trimmedUserId =
    contactUserId.trim();

    final trimmedName =
    displayName.trim();

    final trimmedValue =
    contactValue.trim();

    if (trimmedUserId.isEmpty) {
      throw Exception(
        'Contact user ID is required.',
      );
    }

    if (trimmedName.isEmpty) {
      throw Exception(
        'Display name is required.',
      );
    }

    if (trimmedUserId ==
        currentUserId) {
      throw Exception(
        'You cannot add yourself.',
      );
    }

    final exists =
    await contactExists(
      trimmedUserId,
    );

    if (exists) {
      throw Exception(
        'This contact is already saved.',
      );
    }

    try {
      final response = await _supabase
          .from('contacts')
          .insert({
        'user_id': currentUserId,
        'contact_user_id':
        trimmedUserId,
        'custom_name':
        trimmedName,
        'contact_value':
        trimmedValue,
      }).select().single();

      return ContactModel.fromMap(
        Map<String, dynamic>.from(
          response,
        ),
      );
    } catch (e) {
      debugPrint(
        'ContactService.addContact error: $e',
      );

      rethrow;
    }
  }

  /// =============================================================
  /// UPDATE CONTACT NAME
  /// =============================================================
  static Future<void>
  updateContactName({
    required String contactId,
    required String displayName,
  }) async {
    _ensureLoggedIn();

    final trimmedContactId =
    contactId.trim();

    final trimmedName =
    displayName.trim();

    if (trimmedContactId.isEmpty) {
      throw Exception(
        'Contact ID is required.',
      );
    }

    if (trimmedName.isEmpty) {
      throw Exception(
        'Display name is required.',
      );
    }

    try {
      await _supabase
          .from('contacts')
          .update({
        'custom_name':
        trimmedName,
      })
          .eq(
        'id',
        trimmedContactId,
      )
          .eq(
        'user_id',
        currentUserId,
      );
    } catch (e) {
      debugPrint(
        'updateContactName error: $e',
      );

      rethrow;
    }
  }

  /// =============================================================
  /// DELETE CONTACT
  /// =============================================================
  static Future<void>
  deleteContact(
      String contactId,
      ) async {
    _ensureLoggedIn();

    final trimmedContactId =
    contactId.trim();

    if (trimmedContactId.isEmpty) {
      throw Exception(
        'Contact ID is required.',
      );
    }

    try {
      await _supabase
          .from('contacts')
          .delete()
          .eq(
        'id',
        trimmedContactId,
      )
          .eq(
        'user_id',
        currentUserId,
      );
    } catch (e) {
      debugPrint(
        'deleteContact error: $e',
      );

      rethrow;
    }
  }
}