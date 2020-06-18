import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/pages/gallary_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'home_page.dart';


// import 'dart:developer';

class ChatPage extends StatefulWidget {
  final SharedPreferences prefs;
  final String chatId;
  final String title;
  final String receiverId;
  ChatPage({this.prefs, this.chatId, this.title, this.receiverId});
  @override
  ChatPageState createState() {
    return new ChatPageState();
  }
}

// List getFlatList(List list) {
//   List internalList = new List();
//   list.forEach((e) {
//     if (e is List) {
//       internalList.addAll(getFlatList(e));
//     } else {
//       internalList.add(e);
//     }
//   });
//   return internalList;
// }

// List flatten(List l, [int level = -1]) {
//   if (0 == level) return l;
//   return l.fold([], (List acc, cur) {
//     if (cur is List) return acc..addAll(flatten(cur, level - 1));
//     return acc..add(cur);
//   });
// }


class ChatPageState extends State<ChatPage> {
  final db = Firestore.instance;
  CollectionReference chatReference;
  //DocumentReference receiverId;
  //DocumentReference documentReference;
  CollectionReference contactsReference;
  final TextEditingController _textController =
      new TextEditingController();
  bool _isWritting = false;
  // bool isSent = false;

  @override
  void initState() {
    super.initState();
    contactsReference = db
        .collection("users")
        .document(widget.receiverId)
        .collection('contacts');
    chatReference =
        db.collection("chats").document(widget.chatId).collection('messages');
    //documentReference = db.collection("chats").document(widget.chatId);
    //receiverId = db.collection("chats").document(widget.chatId);
  }

  List<Widget> generateSenderLayout(DocumentSnapshot documentSnapshot) {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            new Text(documentSnapshot.data['sender_name'],
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: documentSnapshot.data['image_url'] != ''
                  ? InkWell(
                      child: new Container(
                        child: Image.network(
                          documentSnapshot.data['image_url'],
                          fit: BoxFit.fitWidth,
                        ),
                        height: 150,
                        width: 150.0,
                        color: Colors.transparent,
                        padding: EdgeInsets.all(5),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GalleryPage(
                              imagePath: documentSnapshot.data['image_url'],
                            ),
                          ),
                        );
                      },
                    )
                  : new Text(documentSnapshot.data['text']),
            ),
          ],
        ),
      ),
      new Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(left: 8.0),
              child: new CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    new NetworkImage(documentSnapshot.data['profile_photo']),
              )),
        ],
      ),
    ];
  }

  List<Widget> generateReceiverLayout(DocumentSnapshot documentSnapshot) {
    return <Widget>[
      new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new Container(
              margin: const EdgeInsets.only(right: 8.0),
              child: new CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    new NetworkImage(documentSnapshot.data['profile_photo']),
              )),
        ],
      ),
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Text(documentSnapshot.data['sender_name'],
                style: new TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            new Container(
              margin: const EdgeInsets.only(top: 5.0),
              child: documentSnapshot.data['image_url'] != ''
                  ? InkWell(
                      child: new Container(
                        child: Image.network(
                          documentSnapshot.data['image_url'],
                          fit: BoxFit.fitWidth,
                        ),
                        height: 150,
                        width: 150.0,
                        color: Colors.transparent,
                        padding: EdgeInsets.all(5),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GalleryPage(
                              imagePath: documentSnapshot.data['image_url'],
                            ),
                          ),
                        );
                      },
                    )
                  : new Text(documentSnapshot.data['text']),
            ),
          ],
        ),
      ),
    ];
  }

  generateMessages(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data.documents
        .map<Widget>((doc) => Container(
              margin: const EdgeInsets.symmetric(vertical: 10.0),
              child: new Row(
                children: doc.data['sender_id'] != widget.prefs.getString('uid')
                    ? generateReceiverLayout(doc)
                    : generateSenderLayout(doc),
              ),
            ))
        .toList();
  }

  // String retSidVal(String sidVal){
  //   // returns key from the map if present in list to put it as receiver id
  //   var reversed = Glob().recAndSen.map((k, v) => v.contains(sidVal) == true ? MapEntry(v, k) : MapEntry('', ''));
  //   print(reversed);
  //   for(var x in reversed.entries){
  //     print(x.value);
  //   }
      
  //   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: Color.fromRGBO(255, 219, 172, 10),
        leading: BackButton(
          color: Colors.black
        ),
        backgroundColor: Colors.white,
        title: Text(widget.title),
        actions: <Widget>[
          Hero(
          tag: 'logo',
          child: Container(
            height: 40.0,
            child: Image.asset("assets/solar_logo.png"),
          ),
        ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(5),
        child: new Column(
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: chatReference.orderBy('time',descending: true).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return new Text("No Chat");
                return Expanded(
                  child: new ListView(
                    reverse: true,
                    children: generateMessages(snapshot),
                  ),
                );
              },
            ),
            new Divider(height: 1.0),
            new Container(
              decoration: new BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer(),
            ),
            new Builder(builder: (BuildContext context) {
              return new Container(width: 0.0, height: 0.0);
            })
          ],
        ),
      ),
    );
  }

  updateLastMessageTime(CollectionReference contacts)async{
    QuerySnapshot getDocId = await contacts.where('uid', isEqualTo: widget.prefs.getString('uid')).getDocuments();
    contacts.document(getDocId.documents[0].documentID).updateData({'time': FieldValue.serverTimestamp()});
  }

  IconButton getDefaultSendButton() {
    return new IconButton(
      icon: new Icon(Icons.send, color: Colors.red[800],),
      onPressed: (_isWritting)
          ? () => 
          
          
          // [
          // Glob().incrementIssent(),
          // datasnapshot.data gives the receiver id
 
 
          // receiverId.get().then((datasnapshot) async{
          //   if (datasnapshot.exists) {


              // widget.prefs.getString('uid') == datasnapshot.data['contact2'].toString() ? Glob().rId = (datasnapshot.data['contact1'].toString()): Glob().rId = (datasnapshot.data['contact2'].toString());
          
          // Glob().chatID = widget.chatId;
          // print('chatId is => ' + widget.chatId);
          
          // Implementing multiple notification
          // the containsKey and containsValue is used to check whether the key value pair is already present or not so as to keep a key value pair unique
          // widget.prefs.getString('uid') == datasnapshot.data['contact2'].toString() && 
          // (Glob().recAndSen.containsKey(datasnapshot.data['contact1'].toString()) == false || Glob().recAndSen.containsKey(datasnapshot.data['contact2'].toString()) == false) &&
          // (Glob().recAndSen.containsValue(datasnapshot.data['contact1'].toString()) == false || Glob().recAndSen.containsValue(datasnapshot.data['contact2'].toString()) == false)
          // But the problem is the Glob().rId only remains in local machine so the other person will never see a notifcation


          // widget.prefs.getString('uid') == datasnapshot.data['contact2'].toString()
          // ?
          // Glob().recAndSen.update('${datasnapshot.data['contact1'].toString()}', (e) => Glob().addToList(e, datasnapshot.data['contact2'].toString()), ifAbsent: () => ['${(datasnapshot.data['contact2'].toString())}'])
          // :
          // Glob().recAndSen.update('${datasnapshot.data['contact2'].toString()}', (e) => Glob().addToList(e, datasnapshot.data['contact1'].toString()), ifAbsent: () => ['${(datasnapshot.data['contact1'].toString())}']);
          
          // print(Glob().recAndSen);
 
 
          // widget.prefs.getString('uid') == datasnapshot.data['contact2'].toString() ? Glob().sId = datasnapshot.data['contact1'].toString() : Glob().sId = datasnapshot.data['contact2'].toString(); 
          // print('sid is: ' + '${Glob().sId}');

          // Glob().rId = Glob().recAndSen.values.expand((i) => i).toList();
          // retSidVal(widget.prefs.getString('uid'));

          // Glob().rId = Glob().recAndSen.values.expand((i) => i).toList();
          // Glob().rId = flatten(Glob().rId)
          // print('rid is ' + '${Glob().rId}');


          // print("contact 2 is  (rId) => " + '${Glob().rId}');
          // Glob().sId = (datasnapshot.data['contact1'].toString());
              // widget.prefs.getString('uid') == datasnapshot.data['contact2'].toString() ? Glob().sId = (datasnapshot.data['contact2'].toString()): Glob().sId = (datasnapshot.data['contact1'].toString());
              // print("contact 1 is  (sId) => " + Glob().sId);          
         
         
          //   }
          // else{print("No such user");}
          // }
          // ), _sendText(_textController.text),]
          // : null,
          // [contactsReference.where('uid', isEqualTo: widget.prefs.getString('uid')).add({'lastMessageTime': FieldValue.serverTimestamp()}),
          
          [updateLastMessageTime(contactsReference),
          _sendText(_textController.text)] : null
    );
  }

  Widget _buildTextComposer() {
    return new IconTheme(
        data: new IconThemeData(
          color: _isWritting
              ? Theme.of(context).accentColor
              : Theme.of(context).disabledColor,
        ),
        child: new Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: new Row(
            children: <Widget>[
              new Container(
                margin: new EdgeInsets.symmetric(horizontal: 4.0),
                child: new IconButton(
                    icon: new Icon(
                      Icons.photo_camera,
                      color: Colors.grey,
                    ),
                    onPressed: () async {
                      var image = await ImagePicker.pickImage(
                          source: ImageSource.gallery);
                      int timestamp = new DateTime.now().millisecondsSinceEpoch;
                      StorageReference storageReference = FirebaseStorage
                          .instance
                          .ref()
                          .child('chats/img_' + timestamp.toString() + '.jpg');
                      StorageUploadTask uploadTask =
                          storageReference.putFile(image);
                      await uploadTask.onComplete;
                      String fileUrl = await storageReference.getDownloadURL();
                      _sendImage(messageText: null, imageUrl: fileUrl);
                    }),
              ),
              new Flexible(
                child: new TextField(
                  controller: _textController,
                  onChanged: (String messageText) {
                    setState(() {
                      _isWritting = messageText.length > 0;
                    });
                  },
                  onSubmitted: _sendText,
                  decoration:
                      new InputDecoration.collapsed(hintText: "Send a message"),
                ),
              ),
              new Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: getDefaultSendButton(),
              ),
            ],
          ),
        ));
  }

  Future<Null> _sendText(String text) async {
    _textController.clear();
    chatReference.add({
      'text': text,
      'receiver_id': widget.receiverId,
      'sender_id': widget.prefs.getString('uid'),
      'sender_name': widget.prefs.getString('name'),
      'profile_photo': widget.prefs.getString('profile_photo'),
      'image_url': '',
      'time': FieldValue.serverTimestamp(),
      'isSent': 1,
    }).then((documentReference) {
      setState(() {
        _isWritting = false;
      });
    }).catchError((e) {});
  }

  void _sendImage({String messageText, String imageUrl}) {
    chatReference.add({
      'text': messageText,
      'receiver_id': widget.receiverId,
      'sender_id': widget.prefs.getString('uid'),
      'sender_name': widget.prefs.getString('name'),
      'profile_photo': widget.prefs.getString('profile_photo'),
      'image_url': imageUrl,
      'time': FieldValue.serverTimestamp(),
      'isSent': 1,
    });
  }
}
