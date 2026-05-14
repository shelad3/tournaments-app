import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place_model.dart';

class PlaceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PlaceModel>> getAllPlaces() =>
      _firestore
          .collection('places')
          .orderBy('name')
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
              .toList());

  Stream<List<PlaceModel>> getPlacesForUser(List<String> placeIds) {
    if (placeIds.isEmpty) return Stream.value([]);
    return _firestore
        .collection('places')
        .where(FieldPath.documentId, whereIn: placeIds)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PlaceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addPlace(PlaceModel place) =>
      _firestore.collection('places').add(place.toMap());

  Future<void> updatePlace(String id, Map<String, dynamic> data) =>
      _firestore.collection('places').doc(id).update(data);

  Future<void> deletePlace(String id) =>
      _firestore.collection('places').doc(id).delete();

  Future<PlaceModel?> getPlace(String id) async {
    final doc = await _firestore.collection('places').doc(id).get();
    if (!doc.exists) return null;
    return PlaceModel.fromMap(doc.data()!, doc.id);
  }
}
