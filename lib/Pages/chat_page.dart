import "package:chatapp/components/chat_bubble.dart";
import "package:chatapp/components/my_textfield.dart";
import "package:chatapp/service/auth/auth_service.dart";
import "package:chatapp/service/chat/chat_service.dart";
import "package:flutter/material.dart";
import 'package:cloud_firestore/cloud_firestore.dart';


class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  ChatPage({super.key, required this.receiverEmail, required this.receiverID});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService= ChatService();
  final AuthService _authService = AuthService();

  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500),()=> scrollDown()); 
      }
    });

    Future.delayed(const Duration(milliseconds: 500),()=> scrollDown());  
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent, 
      duration: Duration(seconds: 1), 
      curve: Curves.fastOutSlowIn);
  }

  void sendMessage() async{
    if(_messageController.text.isNotEmpty){
      await _chatService.sendMessage(_messageController.text, widget.receiverID);

      _messageController.clear();

      scrollDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverEmail,style: TextStyle(fontSize: 20),),
      backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(),
          ),
          _buildUserInput()
        ]),
    );
  }

  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(senderID, widget.receiverID),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView(
            controller: _scrollController,
            children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
          );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        } else {
          return Center(child: CircularProgressIndicator());
        }
      });
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String,dynamic> data =doc.data() as Map<String,dynamic>;

    bool isCurrent = data["senderID"] == _authService.getCurrentUser()!.uid;

    var alignment = isCurrent ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment ,
      child: ChatBubble(message: data["message"], isCurrentUser: isCurrent),
    ); 
  }

  Widget _buildUserInput(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Row(
        children: [
          Expanded(
            child: MyTextField(
              hintText: "Type a message", 
              obscureText: false, 
              focusNode: myFocusNode,
              controller: _messageController)
      
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle
            ),
            margin: const EdgeInsets.only(right: 25.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_upward,
              color: Colors.white,),
              onPressed: sendMessage,
            ),
          )
        ],
      ),
    );
  }
}