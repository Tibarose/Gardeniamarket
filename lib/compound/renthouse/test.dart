import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart'; // Add this for Provider
import '../../main.dart';
import '../core/config/supabase_config.dart';

class HelloScreen extends StatefulWidget {
  const HelloScreen({super.key});

  @override
  _HelloScreenState createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  @override
  void initState() {
    super.initState();
    // Show popup after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAndShowPopup();
    });
  }

  Future<void> _fetchAndShowPopup() async {
    try {
      // Access the secondary client via SupabaseConfig
      final supabaseConfig = Provider.of<SupabaseConfig>(context, listen: false);
      final response = await supabaseConfig.secondaryClient
          .from('popups')
          .select('image_url, message')
          .eq('is_active', true);

      if (response.isNotEmpty) {
        // Get the first active popup
        final popup = response[0];
        final imageUrl = popup['image_url'] as String;
        final message = popup['message'] as String;

        // Show the popup dialog
        if (mounted) {
          _showPopupDialog(imageUrl, message);
        }
      }
    } catch (e) {
      // Handle errors (e.g., network issues, invalid query)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching popup: $e')),
        );
      }
    }
  }

  void _showPopupDialog(String imageUrl, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Special Offer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                width: 200,
                height: 100,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello Screen'),
      ),
      body: const Center(
        child: Text(
          'Hello',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}