// lib/about_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const authorName = 'Roberto Cc';
    const githubUrl = 'https://github.com/marotoweb/cajuscan_app';

    return Scaffold(
      appBar: AppBar(title: const Text('About CajuScan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Author section
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Developed by'),
            subtitle: const Text(authorName),
          ),
          // GitHub section
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source code (GitHub)'),
            subtitle: const Text(githubUrl),
            onTap: () => _launchURL(githubUrl),
            trailing: const Icon(Icons.open_in_new),
          ),
          const Divider(),
          // Terms of use section
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Terms of use and disclaimer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Text(
            'This app is provided "AS IS", without warranties of any kind, express or implied. '
            'By using CajuScan, you agree that you do so at your own risk.\n'
            'The author originally developed this app for personal use and decided to share it free of charge.\n'
            'The author is not responsible for malfunctions, data loss, recording errors, or any other direct or indirect '
            'damages resulting from the use of, or inability to use, this app. '
            'You are solely responsible for verifying the accuracy and compliance of data sent to Cashew.\n'
            'By using this app, you agree to hold the author harmless from any liability related to CajuScan. '
            'If you do not agree to these terms, please do not use this app.\n\n'
            'Thank you for using CajuScan!',
            textAlign: TextAlign.justify,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Version: $_appVersion',
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
