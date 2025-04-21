import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gardeniamarket/compound/homescreen/thememanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';
import 'package:share_plus/share_plus.dart';

class EmergencyScreen extends StatelessWidget {
const EmergencyScreen({super.key});

// Updated emergency contacts with provided numbers
static const List<Map<String, dynamic>> emergencyContacts = [
{
'name': 'الإسعاف',
'number': '123',
'icon': FontAwesomeIcons.ambulance,
'color': Colors.redAccent,
'category': 'طوارئ عامة',
},
{
'name': 'الشرطة',
'number': '122',
'icon': FontAwesomeIcons.shieldHalved,
'color': Colors.blueAccent,
'category': 'طوارئ عامة',
},
{
'name': 'شرطة المرور',
'number': '128',
'icon': FontAwesomeIcons.car,
'color': Colors.blueGrey,
'category': 'طوارئ عامة',
},
{
'name': 'المطافئ',
'number': '180',
'icon': FontAwesomeIcons.fireExtinguisher,
'color': Colors.orangeAccent,
'category': 'طوارئ عامة',
},
{
'name': 'طوارئ الغاز',
'number': '0224704649',
'icon': FontAwesomeIcons.fire,
'color': Colors.red,
'category': 'خدمات الكمبوند',
},
{
'name': 'طوارئ الأسانسير',
'number': '01098100113',
'icon': FontAwesomeIcons.elevator,
'color': Colors.grey,
'category': 'خدمات الكمبوند',
},
{
'name': 'شركة مدكور',
'numbers': ['01201322220', '01121023975', '01093738495'],
'icon': FontAwesomeIcons.wrench,
'color': Colors.green,
'category': 'خدمات الكمبوند',
},
{
'name': 'شركة الإدارة',
'number': '15739',
'icon': FontAwesomeIcons.buildingUser,
'color': Colors.purple,
'category': 'خدمات الكمبوند',
},
{
'name': 'طوارئ شركة الإدارة',
'number': '01098100113',
'icon': FontAwesomeIcons.headset,
'color': Colors.purpleAccent,
'category': 'خدمات الكمبوند',
},
];

// App details for sharing
static const String appDetails = '''
📱 حمل تطبيق جاردينيا توداي: https://gardenia.today/
📢 انضم إلى مجموعتنا على الفيسبوك: https://www.facebook.com/groups/1357143922331152
📣 تابع قناتنا على تيليجرام: https://t.me/Gardeniatoday
''';

// Function to launch phone call
Future<void> _makePhoneCall(String phoneNumber, BuildContext context) async {
final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
try {
if (await canLaunchUrl(phoneUri)) {
await launchUrl(phoneUri);
} else {
throw 'Could not launch $phoneNumber';
}
} catch (e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
kIsWeb
? 'الرجاء استخدام هاتفك للاتصال: $phoneNumber'
    : 'فشل في الاتصال: $phoneNumber',
style: GoogleFonts.cairo(color: Colors.white),
textAlign: TextAlign.right,
),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
);
}
}
}

// Function to share contact
void _shareContact(Map<String, dynamic> contact, BuildContext context) {
final theme = ThemeManager().currentTheme;
final contactText = contact.containsKey('numbers')
? '${contact['name']}: ${contact['numbers'].join(', ')}'
    : '${contact['name']}: ${contact['number']}';
final shareText = '$contactText\n\n$appDetails';
Share.share(
shareText,
subject: 'رقم طوارئ: ${contact['name']}',
).then((_) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'تمت المشاركة بنجاح',
style: GoogleFonts.cairo(color: Colors.white),
textAlign: TextAlign.right,
),
backgroundColor: theme.primaryColor,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
);
}
}).catchError((e) {
if (context.mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
'فشل في المشاركة: $e',
style: GoogleFonts.cairo(color: Colors.white),
textAlign: TextAlign.right,
),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
);
}
});
}

// Show dialog for multiple numbers
void _showMultipleNumbersDialog(
BuildContext context, String name, List<String> numbers) {
final theme = ThemeManager().currentTheme;
showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: theme.cardBackground,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
title: Text(
'اتصل بـ $name',
style: GoogleFonts.cairo(
fontSize: 20,
fontWeight: FontWeight.w700,
color: theme.textColor,
),
textAlign: TextAlign.right,
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: numbers
    .asMap()
    .entries
    .map(
(entry) => FadeInUp(
duration: Duration(milliseconds: 300 + (entry.key * 100)),
child: ListTile(
contentPadding: const EdgeInsets.symmetric(horizontal: 8),
leading: FaIcon(
FontAwesomeIcons.phone,
color: theme.primaryColor,
size: 18,
),
title: Text(
entry.value,
style: GoogleFonts.cairo(
fontSize: 16,
color: theme.textColor,
fontWeight: FontWeight.w600,
),
textAlign: TextAlign.right,
),
trailing: IconButton(
icon: FaIcon(
FontAwesomeIcons.shareNodes,
color: theme.primaryColor,
size: 18,
),
onPressed: () {
Navigator.pop(context);
_shareContact(
{
'name': name,
'number': entry.value,
},
context,
);
},
tooltip: 'مشاركة',
),
onTap: () {
Navigator.pop(context);
_makePhoneCall(entry.value, context);
},
),
),
)
    .toList(),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text(
'إلغاء',
style: GoogleFonts.cairo(
fontSize: 14,
color: theme.primaryColor,
fontWeight: FontWeight.w600,
),
),
),
],
),
);
}

@override
Widget build(BuildContext context) {
final theme = ThemeManager().currentTheme;
final isMobile = MediaQuery.of(context).size.width < 600;

// Group contacts by category
final groupedContacts = <String, List<Map<String, dynamic>>>{};
for (var contact in emergencyContacts) {
final category = contact['category'] as String;
groupedContacts[category] = groupedContacts[category] ?? [];
groupedContacts[category]!.add(contact);
}

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: theme.backgroundColor,
appBar: AppBar(
title: Text(
'أرقام الطوارئ',
style: GoogleFonts.cairo(
fontSize: isMobile ? 22 : 24,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
backgroundColor: Colors.transparent,
flexibleSpace: Container(
decoration: BoxDecoration(
gradient: theme.appBarGradient,
borderRadius: const BorderRadius.vertical(
bottom: Radius.circular(20),
),
),
),
elevation: 0,
leading: IconButton(
icon: const FaIcon(
FontAwesomeIcons.arrowRight,
color: Colors.white,
size: 20,
),
onPressed: () => Navigator.pop(context),
tooltip: 'رجوع',
),
),
body: SafeArea(
child: CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: [
SliverPadding(
padding: const EdgeInsets.all(16.0),
sliver: SliverList(
delegate: SliverChildBuilderDelegate(
(context, index) {
final category = groupedContacts.keys.toList()[index];
final contacts = groupedContacts[category]!;

return FadeInUp(
duration: Duration(milliseconds: 300 + (index * 100)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Padding(
padding: const EdgeInsets.symmetric(vertical: 8.0),
child: Text(
category,
style: GoogleFonts.cairo(
fontSize: 20,
fontWeight: FontWeight.w800,
color: theme.textColor,
),
),
),
...contacts.asMap().entries.map((entry) {
final contact = entry.value;
return Padding(
padding: const EdgeInsets.only(bottom: 12.0),
child: GestureDetector(
onTap: () {
if (contact.containsKey('numbers')) {
_showMultipleNumbersDialog(
context,
contact['name'],
contact['numbers'],
);
} else {
_makePhoneCall(contact['number'], context);
}
},
child: Container(
decoration: BoxDecoration(
color: theme.cardBackground,
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.05),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
child: ClipRRect(
borderRadius: BorderRadius.circular(16),
child: Stack(
children: [
// Gradient overlay for visual depth
Positioned.fill(
child: Container(
decoration: BoxDecoration(
gradient: LinearGradient(
colors: [
contact['color']
    .withOpacity(0.1),
Colors.transparent,
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
),
),
Padding(
padding: const EdgeInsets.all(16.0),
child: Row(
children: [
CircleAvatar(
radius: 28,
backgroundColor: contact['color']
    .withOpacity(0.2),
child: FaIcon(
contact['icon'],
size: 24,
color: contact['color'],
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
contact['name'],
style:
GoogleFonts.cairo(
fontSize: 18,
fontWeight:
FontWeight.w700,
color:
theme.textColor,
),
),
const SizedBox(height: 4),
Text(
contact.containsKey(
'numbers')
? contact['numbers']
    .join(', ')
    : contact['number'],
style:
GoogleFonts.cairo(
fontSize: 14,
color: theme
    .secondaryTextColor,
),
maxLines: 1,
overflow: TextOverflow
    .ellipsis,
),
],
),
),
Row(
children: [
Container(
decoration: BoxDecoration(
gradient:
theme.appBarGradient,
borderRadius:
BorderRadius.circular(
12),
boxShadow: [
BoxShadow(
color: theme
    .primaryColor
    .withOpacity(0.3),
spreadRadius: 1,
blurRadius: 4,
offset: const Offset(
0, 2),
),
],
),
child: IconButton(
icon: const FaIcon(
FontAwesomeIcons.phone,
color: Colors.white,
size: 20,
),
onPressed: () {
if (contact
    .containsKey(
'numbers')) {
_showMultipleNumbersDialog(
context,
contact['name'],
contact['numbers'],
);
} else {
_makePhoneCall(
contact['number'],
context);
}
},
tooltip: 'اتصال',
),
),
const SizedBox(width: 8),
Container(
decoration: BoxDecoration(
gradient:
theme.appBarGradient,
borderRadius:
BorderRadius.circular(
12),
boxShadow: [
BoxShadow(
color: theme
    .primaryColor
    .withOpacity(0.3),
spreadRadius: 1,
blurRadius: 4,
offset: const Offset(
0, 2),
),
],
),
child: IconButton(
icon: const FaIcon(
FontAwesomeIcons
    .shareNodes,
color: Colors.white,
size: 20,
),
onPressed: () =>
_shareContact(
contact, context),
tooltip: 'مشاركة',
),
),
],
),
],
),
),
],
),
),
),
),
);
}),
],
),
);
},
childCount: groupedContacts.length,
),
),
),
],
),
),
),
);
}
}