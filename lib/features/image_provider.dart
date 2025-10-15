import 'dart:io';
import 'package:flutter/material.dart';

class CustomImageProvider with ChangeNotifier {
  File? _imageFile;

  File? get imageFile => _imageFile;

  void setImage(File image) {
    _imageFile = image;
    notifyListeners();
  }

  void clearImage() {
    _imageFile = null;
    notifyListeners();
  }
}
