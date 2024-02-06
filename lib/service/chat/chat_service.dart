import 'package:chatapp/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  // get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();

        return user;
      }).toList();
    });
  }
  //send message

  Future<void> sendMessage(String message, receiverID) async {
    //get current user
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    //create a new message
    Message newMessage = Message(
      senderID: currentUserID, 
      senderEmail: currentUserEmail,  
      receiverID: receiverID, 
      message: message, 
      timestamp: timestamp);

    //construct chat room Id for two users (sorted to ensure that uniqueness)
    List<String> ids = [currentUserID,receiverID];
    ids.sort();
    String chatRoomId = ids.join("_");

    //add new message to database
    await _firestore
    .collection('chat_room')
    .doc(chatRoomId)
    .collection("messages")
    .add(newMessage.toMap());
  }

  //get messages
  Stream<QuerySnapshot> getMessages(String userID, otherUserID){
    List<String> ids = [userID,otherUserID];
    ids.sort();
    String chatRoomId = ids.join("_");

    return _firestore
      .collection('chat_room')
      .doc(chatRoomId)
      .collection("messages")
      .orderBy("timestamp", descending: false)
      .snapshots();
  }
}
