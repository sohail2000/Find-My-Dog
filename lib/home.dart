import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  File? _image;
  double? _imageWidth;
  late double _screenWidth;
  final TransformationController _transformationController =
      TransformationController();
  late Animation<double> _imageScaleAnimation;

  @override
  void initState() {
    super.initState();

    loadModel();
  }

  loadModel() async {
    Tflite.close();
    try {
      await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
      );
    } on PlatformException {
      showSnackBar(message: "Failed to load model");
    }
  }

  void showSnackBar({required String message}) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  pickImage(ImageSource imageSource) async {
    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: imageSource);
    if (image == null) {
      return;
    }
    File imageFile = File(image.path);
    predictImage(imageFile);
  }

  predictImage(File image) async {
    FileImage(image)
        .resolve(const ImageConfiguration())
        .addListener((ImageStreamListener((ImageInfo info, bool _) {
          _imageWidth = info.image.width.toDouble();
        })));

    await ssdMobileNet(image);
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path, numResultsPerClass: 1, threshold: 0.5);

    for (var recognition in recognitions!) {
      if ((recognition["detectedClass"] == "cat" ||
              recognition["detectedClass"] == "dog") &&
          recognition["confidenceInClass"] > 0.5) {
        // bounding box coordinates of the detected object
        double left = recognition["rect"]["x"];
        double top = recognition["rect"]["y"];

        // scale factor for the image
        double scale = _imageWidth! / _screenWidth;

        _transformationController.value = Matrix4.identity()
          ..translate(-left * scale, -top * scale)
          ..scale(scale);

        // Animate the scale value from 1.0 to the calculated scale factor
        AnimationController animationController = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 500));
        Animation<double> scaleAnimation =
            Tween<double>(begin: 1.0, end: scale).animate(animationController);
        animationController.forward();
        _imageScaleAnimation = scaleAnimation;
        setState(() {
          _image = image;
          // _imageScaleAnimation = scaleAnimation;
        });

        return;
      }
    }
    showSnackBar(message: "No Cat or Dog Detected");
    setState(() {
      _image = null;
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Find My Dog"),
        backgroundColor: const Color.fromARGB(134, 0, 0, 0),
      ),
      body: _image == null
          ? Center(
              child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      width: 3, color: const Color.fromARGB(134, 0, 0, 0))),
              padding: const EdgeInsets.all(5),
              child: IconButton(
                  onPressed: () {
                    selectImageOption(context, size);
                  },
                  icon: const Icon(Icons.add_a_photo_outlined,
                      color: Color.fromARGB(134, 0, 0, 0))),
            ))
          : InkWell(
              onTap: () => selectImageOption(context, size),
              child: AnimatedBuilder(
                animation: _imageScaleAnimation,
                builder: (BuildContext context, Widget? child) {
                  return Transform.scale(
                    scale: _imageScaleAnimation.value,
                    child: Center(
                      child: InteractiveViewer(
                        alignment: Alignment.center,
                        transformationController: _transformationController,
                        child: Image.file(_image!),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<dynamic> selectImageOption(BuildContext context, Size size) {
    return showDialog(
        context: context,
        builder: ((context) {
          return Center(
            child: SizedBox(
              width: size.width * 0.6,
              height: size.height * 0.2,
              child: Card(
                color: const Color.fromARGB(255, 0, 0, 0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      OutlinedButton(
                          onPressed: () {
                            pickImage(ImageSource.camera);
                            Navigator.pop(context);
                          },
                          child: const Text("Camera")),
                      TextButton(
                          onPressed: () {
                            pickImage(ImageSource.gallery);
                            Navigator.pop(context);
                          },
                          child: const Text("Gallery")),
                    ]),
              ),
            ),
          );
        }));
  }
}
