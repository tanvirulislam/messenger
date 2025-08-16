import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:http/http.dart' as http;

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Private Messenger',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
        brightness: Brightness.dark,
      ),
      // home: QuillToHtmlExample(),
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('data')));
  }
}

class QuillToHtmlExample extends StatefulWidget {
  @override
  _QuillToHtmlExampleState createState() => _QuillToHtmlExampleState();
}

class _QuillToHtmlExampleState extends State<QuillToHtmlExample> {
  QuillController quillController = QuillController.basic();
  bool _isLoading = false;

  // Convert Quill Delta to HTML
  String _convertToHtml() {
    final delta = quillController.document.toDelta();
    final converter = QuillDeltaToHtmlConverter(
      List.castFrom(delta.toJson()),
      ConverterOptions.forEmail(),
    );
    return converter.convert();
  }

  // Send HTML content via POST request
  Future<void> _sendHtmlContent() async {
    if (quillController.document.isEmpty()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter some content')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert Quill content to HTML
      String htmlContent = _convertToHtml();

      print('HTML Content: $htmlContent'); // Debug print

      final url = Uri.parse('https://your-api-endpoint.com/api/content');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          // Add other headers if needed
          // 'Authorization': 'Bearer your-token',
        },
        body: {
          'content': htmlContent,
          // Add other form fields if needed
          // 'title': 'Rich Text Content',
          // 'user_id': '123',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Content submitted successfully!')),
        );
        // Clear the editor if needed
        // quillController.clear();
      } else {
        throw Exception('Failed to submit content: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quill to HTML'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _isLoading ? null : _sendHtmlContent,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quill Toolbar
          QuillSimpleToolbar(
            controller: quillController,
            config: QuillSimpleToolbarConfig(
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showStrikeThrough: true,
              showColorButton: true,
              showBackgroundColorButton: true,
              showHeaderStyle: true,
              showListNumbers: true,
              showListBullets: true,
              showCodeBlock: true,
              showQuote: true,
              showIndent: true,
              showLink: true,
              showUndo: true,
              showRedo: true,
            ),
          ),

          // Quill Editor
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: QuillEditor.basic(
                controller: quillController,
                config: QuillEditorConfig(
                  scrollable: true,
                  placeholder: 'Type something...',
                ),
              ),
            ),
          ),

          // Submit Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendHtmlContent,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Sending...'),
                      ],
                    )
                  : Text('Send as HTML'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // Preview HTML Button (for debugging)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton(
              onPressed: () {
                String html = _convertToHtml();
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Generated HTML'),
                    content: SingleChildScrollView(child: Text(html)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Preview HTML'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    quillController.dispose();
    super.dispose();
  }
}
