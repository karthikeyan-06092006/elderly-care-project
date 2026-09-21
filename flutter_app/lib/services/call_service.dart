import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class CallService {
  static const MethodChannel _channel = MethodChannel('com.elderlycare/phone_call');

  /// Places a direct phone call immediately bypassing the dial pad if possible.
  static Future<void> makeDirectPhoneCall({
    required BuildContext context,
    required String phoneNumber,
    bool isBengali = false,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBengali ? "কোনো ফোন নম্বর পাওয়া যায়নি" : "No valid phone number to call",
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
      return;
    }

    try {
      // 1. Attempt direct native call (Intent.ACTION_CALL)
      final bool? success = await _channel.invokeMethod<bool>('makeDirectCall', {
        'phoneNumber': cleanPhone,
      });

      if (success == true) {
        return;
      }
    } catch (e) {
      debugPrint("Native direct call error: $e. Falling back to url_launcher.");
    }

    // 2. Fallback to url_launcher if platform channel is unavailable
    try {
      final Uri url = Uri.parse('tel:$cleanPhone');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBengali ? "কল করা যাচ্ছে না: $e" : "Could not open dialer: $e",
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }
}
