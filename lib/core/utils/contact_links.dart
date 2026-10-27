/// Builds launchable links for the store's API-provided contact details.
abstract final class ContactLinks {
  static Uri phone(String number) => Uri(scheme: 'tel', path: number.replaceAll(RegExp(r'[^\d+]'), ''));

  /// WhatsApp click-to-chat expects digits only, with country code.
  static Uri whatsapp(String number) => Uri.https('wa.me', '/${number.replaceAll(RegExp(r'\D'), '')}');
}
