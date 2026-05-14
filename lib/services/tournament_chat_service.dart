import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/forum_message_model.dart';

class TournamentChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference _chatRef(String tournamentId) =>
      _firestore.collection('tournament_chats').doc(tournamentId).collection('messages');

  Stream<List<ForumMessageModel>> getMessages(String tournamentId) =>
      _chatRef(tournamentId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((snap) => snap.docs
              .map((doc) => ForumMessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList());

  Future<void> sendTextMessage({
    required String tournamentId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String text,
  }) =>
      _chatRef(tournamentId).add(ForumMessageModel(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: text,
        type: ForumMessageType.text,
      ).toMap());

  Future<void> sendImageMessage({
    required String tournamentId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required XFile image,
  }) async {
    final ref = _storage.ref().child('tournament_chat_images/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putData(await image.readAsBytes());
    final url = await ref.getDownloadURL();
    await _chatRef(tournamentId).add(ForumMessageModel(
      id: '',
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      imageUrl: url,
      type: ForumMessageType.image,
    ).toMap());
  }
}
