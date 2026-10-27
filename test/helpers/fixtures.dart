import 'dart:convert';
import 'dart:io';

/// Loads a captured live API response from `test/fixtures`.
Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync()) as Map<String, dynamic>;

/// The `data` member of a captured envelope.
dynamic fixtureData(String name) => fixture(name)['data'];
