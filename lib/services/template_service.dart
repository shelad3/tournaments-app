import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tournament_template.dart';

class TemplateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<TournamentTemplate>> getTemplates() =>
      _firestore.collection('tournament_templates')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => TournamentTemplate.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());

  Future<void> saveTemplate(TournamentTemplate template) async {
    await _firestore.collection('tournament_templates').add(template.toMap());
  }

  Future<void> deleteTemplate(String id) async {
    await _firestore.collection('tournament_templates').doc(id).delete();
  }
}
