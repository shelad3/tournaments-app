import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/place_service.dart';

class PlaceProvider extends ChangeNotifier {
  final PlaceService _service = PlaceService();

  List<PlaceModel> _allPlaces = [];
  PlaceModel? _selectedPlace;
  bool _isLoading = false;

  List<PlaceModel> get allPlaces => _allPlaces;
  PlaceModel? get selectedPlace => _selectedPlace;
  bool get isLoading => _isLoading;

  void loadAllPlaces() {
    _service.getAllPlaces().listen((places) {
      _allPlaces = places;
      notifyListeners();
    });
  }

  void setSelectedPlace(PlaceModel? place) {
    _selectedPlace = place;
    notifyListeners();
  }

  Future<void> addPlace(PlaceModel place) async {
    _isLoading = true;
    notifyListeners();
    await _service.addPlace(place);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePlace(String id, Map<String, dynamic> data) async {
    await _service.updatePlace(id, data);
  }

  Future<void> deletePlace(String id) async {
    await _service.deletePlace(id);
  }
}
