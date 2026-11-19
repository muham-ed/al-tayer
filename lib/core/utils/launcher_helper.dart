import 'package:url_launcher/url_launcher.dart';

class LauncherHelper {
  /// الاتصال الهاتفي المباشر برقم العميل أو المندوب
  static Future<bool> makePhoneCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }

  /// فتح محادثة واتساب سريعة بالرقم
  static Future<bool> openWhatsApp({
    required String phone,
    String message = 'السلام عليكم، بخصوص طلبك على تطبيق ع الطاير',
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (cleanPhone.startsWith('01')) {
      cleanPhone = '2$cleanPhone'; // كود مصر
    }
    final uri = Uri.parse(
      'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    } else {
      // البديل في حال عدم فتح التطبيق مباشرة
      final webUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }
}
