import 'dart:io';
import 'package:flutter/material.dart';

class CustomImageProvider with ChangeNotifier {
  File? _imageFile;

  File? get imageFile => _imageFile;
  List<String> preDisaster = [];
  List<String> duringDisaster = [];
  List<String> postDisaster = [];
  void setImage(File image) {
    _imageFile = image;
    notifyListeners();
  }

  void clearImage() {
    _imageFile = null;
    notifyListeners();
  }
  void addPreDisaster(String item) {
    if (!preDisaster.contains(item)) {
      preDisaster.add(item);
      notifyListeners();
    }
  }

  void addDuringDisaster(String item) {
    if (!duringDisaster.contains(item)) {
      duringDisaster.add(item);
      notifyListeners();
    }
  }

  void addPostDisaster(String item) {
    if (!postDisaster.contains(item)) {
      postDisaster.add(item);
      notifyListeners();
    }
  }
}
