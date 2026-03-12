// lib/utils/invite_utils.dart

import 'package:url_launcher/url_launcher.dart';

class InviteUtils {
  /// Launches WhatsApp to share the invitation message
  static Future<void> sendWhatsAppInvite({
    required String groupName,
    required String inviterName,
  }) async {
    final message =
        "Hey! $inviterName has invited you to join the group '$groupName' on the Casino Split app. Let's track and settle our poker games easily!\nDownload the app here: https://example.com"; // Replace with actual link

    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse("https://wa.me/?text=$encodedMessage");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }
}
