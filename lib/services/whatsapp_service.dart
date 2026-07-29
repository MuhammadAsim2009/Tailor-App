import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../controllers/profile_controller.dart';

class WhatsAppService {
  /// Normalizes phone numbers to standard international format without '+' sign.
  /// E.g., '03001234567' -> '923001234567'
  /// '+923001234567' -> '923001234567'
  static String _formatPhoneNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '92${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Generic launcher for wa.me text messages
  static Future<bool> sendTextMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final formattedNumber = _formatPhoneNumber(phoneNumber);
      final encodedMessage = Uri.encodeComponent(message);
      final url = Uri.parse('https://wa.me/$formattedNumber?text=$encodedMessage');
      
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      return false;
    }
  }

  /// Sends "Order Ready" notification text
  static Future<bool> sendOrderReadyMessage({
    required String phoneNumber,
    required String customerName,
    required String orderId,
  }) async {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    final message = "Dear $customerName! Your order is ready for pickup at $shopName. Thank you!";
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Sends "Order Delivered" notification text
  static Future<bool> sendOrderDeliveredMessage({
    required String phoneNumber,
    required String customerName,
    required double totalAmount,
    required double advancePaid,
  }) async {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    final remainingAmount = totalAmount - advancePaid;
    
    String message = "Dear $customerName! Your order has been delivered successfully from $shopName. Thank you for choosing us!";
    
    if (remainingAmount > 0) {
      message += "\n\nPlease note that you have a pending balance of Rs. ${remainingAmount.toStringAsFixed(0)} for this order. Please clear it as soon as possible.";
    }
    
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Sends payment reminder text
  static Future<bool> sendPaymentReminder({
    required String phoneNumber,
    required String customerName,
    required String orderId,
    required double remainingAmount,
  }) async {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    final message = "Dear $customerName! This is a reminder from $shopName. You have a remaining balance of Rs. ${remainingAmount.toStringAsFixed(0)}. Please clear the dues at your earliest convenience. Thank you!";
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Sends a pickup reminder — tells customer how many pieces remain to collect
  static Future<bool> sendPickupReminder({
    required String phoneNumber,
    required String customerName,
    required String orderId,
    required int remainingPickup,
    required int totalQuantity,
  }) async {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    final message = "Dear $customerName! This is a friendly reminder from $shopName. "
        "Your order has $remainingPickup piece${remainingPickup == 1 ? '' : 's'} remaining to be picked up out of $totalQuantity. "
        "Please visit us at your earliest convenience to collect your order. Thank you!";
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Sends generic payment reminder text
  static Future<bool> sendGeneralPaymentReminder({
    required String phoneNumber,
    required String customerName,
    required double totalPendingAmount,
  }) async {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    final message = "Dear $customerName! This is a gentle reminder from $shopName. "
        "You have a total pending balance of Rs. ${totalPendingAmount.toStringAsFixed(0)}. "
        "Please clear your dues at your earliest convenience. Thank you!";
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  static String buildNewOrderMessage({
    required String customerName,
    required String orderId,
    required double totalAmount,
    required double advancePaid,
  }) {
    final shopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
    return "Dear $customerName!\n"
        "Thank you for placing your order with $shopName.\n"
        "We'll notify you once it's ready!";
  }

  /// Sends new order confirmation text
  static Future<bool> sendNewOrderMessage({
    required String phoneNumber,
    required String customerName,
    required String orderId,
    required double totalAmount,
    required double advancePaid,
  }) async {
    final message = buildNewOrderMessage(
      customerName: customerName,
      orderId: orderId,
      totalAmount: totalAmount,
      advancePaid: advancePaid,
    );
    return sendTextMessage(phoneNumber: phoneNumber, message: message);
  }

  /// Shares the receipt image to WhatsApp with the new order message as caption.
  /// Saves the image bytes to a temp file, then invokes the system share sheet
  /// pre-targeted at WhatsApp.
  static Future<bool> shareReceiptToWhatsApp({
    required Uint8List imageBytes,
    required String customerName,
    required String orderId,
    required double totalAmount,
    required double advancePaid,
  }) async {
    try {
      // Save bytes to a temp file
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/receipt_$orderId.png';
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      final xFile = XFile(filePath, mimeType: 'image/png');

      final shareShopName = ProfileController().profile?.shopName ?? 'Irfan Tailors';
      final result = await Share.shareXFiles(
        [xFile],
        subject: 'Order Receipt - $shareShopName',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
      return false;
    }
  }
}
