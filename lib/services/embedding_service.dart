import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EmbeddingService {
  static final EmbeddingService instance = EmbeddingService._internal();
  late Interpreter _interpreter;

  EmbeddingService._internal();

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('models/mobilefacenet.tflite');
  }

  Future<List<double>> getEmbedding(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes)!;
    final resized = img.copyResize(image, width: 112, height: 112);

    final input = List.generate(
      112,
      (y) => List.generate(112, (x) {
        final pixel = resized.getPixel(x, y);
        return [
          (pixel.r - 127.5) / 128.0,
          (pixel.g - 127.5) / 128.0,
          (pixel.b - 127.5) / 128.0,
        ];
      }),
    );

    final output = List.filled(192, 0.0).reshape([1, 192]);

    _interpreter.run([input], output);

    return List<double>.from(output[0]);
  }
}
