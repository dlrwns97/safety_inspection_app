import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: DefectInputPanel(),
        ),
      ),
    );
  }
}

class DefectInputPanel extends StatefulWidget {
  const DefectInputPanel({super.key});

  @override
  State<DefectInputPanel> createState() => _DefectInputPanelState();
}

class _DefectInputPanelState extends State<DefectInputPanel> {
  late final TextEditingController _widthController;
  late final TextEditingController _lengthController;
  late final TextEditingController _otherController;
  late final FocusNode _widthFocusNode;
  late final FocusNode _lengthFocusNode;
  late final FocusNode _otherFocusNode;

  String _widthValue = '';
  String _lengthValue = '';
  String _otherValue = '';

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController();
    _lengthController = TextEditingController();
    _otherController = TextEditingController();
    _widthFocusNode = FocusNode();
    _lengthFocusNode = FocusNode();
    _otherFocusNode = FocusNode();

    _widthFocusNode.addListener(() {
      if (!_widthFocusNode.hasFocus) {
        final currentValue = _widthController.text;
        if (_widthValue != currentValue) {
          _widthValue = currentValue;
        }
      }
    });
    _lengthFocusNode.addListener(() {
      if (!_lengthFocusNode.hasFocus) {
        final currentValue = _lengthController.text;
        if (_lengthValue != currentValue) {
          _lengthValue = currentValue;
        }
      }
    });
    _otherFocusNode.addListener(() {
      if (!_otherFocusNode.hasFocus) {
        final currentValue = _otherController.text;
        if (_otherValue != currentValue) {
          _otherValue = currentValue;
        }
      }
    });
  }

  @override
  void dispose() {
    _widthController.dispose();
    _lengthController.dispose();
    _otherController.dispose();
    _widthFocusNode.dispose();
    _lengthFocusNode.dispose();
    _otherFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crack Defect Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LabeledTextField(
          label: 'Width (mm)',
          controller: _widthController,
          focusNode: _widthFocusNode,
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            if (_widthValue != value) {
              _widthValue = value;
            }
          },
        ),
        const SizedBox(height: 12),
        LabeledTextField(
          label: 'Length (mm)',
          controller: _lengthController,
          focusNode: _lengthFocusNode,
          keyboardType: TextInputType.number,
          onSubmitted: (value) {
            if (_lengthValue != value) {
              _lengthValue = value;
            }
          },
        ),
        const SizedBox(height: 12),
        OtherTextField(
          label: 'Other details',
          controller: _otherController,
          focusNode: _otherFocusNode,
          visible: false,
          onSubmitted: (value) {
            if (_otherValue != value) {
              _otherValue = value;
            }
          },
        ),
      ],
    );
  }
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.keyboardType,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class OtherTextField extends StatelessWidget {
  const OtherTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.visible,
    this.keyboardType,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool visible;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      child: LabeledTextField(
        label: label,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
