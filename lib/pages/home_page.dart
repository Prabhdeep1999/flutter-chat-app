import 'dart:async';
// import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'package:flutter_chat_app/pages/registration_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contact_picker/contact_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'dart:collection';


class Glob {
  //One instance, needs factory 
  static Glob _instance;
  factory Glob() => _instance ??= new Glob._();
  Glob._();

  // int isSent = 0;
  // var recAndSen = new Map<dynamic, List<String>>();
  // var msgCount = new Map<dynamic, int>();
  List rId;

}

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;
  final String chatId;
  HomePage({this.prefs, this.chatId});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
  // showNotification() async{
  //       var scheduledNotificationDateTime = DateTime.now().add(Duration(seconds: 5));
  //       var androidPlatformChannelSpecifics =
  //       new AndroidNotificationDetails('your other channel id',
  //           'your other channel name', 'your other channel description');
  //       var iOSPlatformChannelSpecifics =
  //       new IOSNotificationDetails();
  //       var platformChannelSpecifics = new NotificationDetails(
  //       androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
  //       await flutterLocalNotificationsPlugin.schedule(
  //           0,
  //           'Solar Chat App',
  //           'You might be having new notifications',
  //           scheduledNotificationDateTime,
  //           platformChannelSpecifics);
  //     }


  int _currentIndex = 0;
  String _tabTitle = "Contacts";
  List<Widget> _children = [Container(), Container()];

  final db = Firestore.instance;
  final ContactPicker _contactPicker = new ContactPicker();
  CollectionReference contactsReference;
  DocumentReference profileReference;
  DocumentSnapshot profileSnapshot;
  CollectionReference decrementIsSent;
  var uidAllContacts;

  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final _yourNameController = TextEditingController();
  bool editName = false;
  @override
  void initState() {
    super.initState();
    contactsReference = db
        .collection("users")
        .document(widget.prefs.getString('uid'))
        .collection('contacts');
    profileReference =
        db.collection("users").document(widget.prefs.getString('uid'));

    profileReference.snapshots().listen((querySnapshot) {
      profileSnapshot = querySnapshot;
      widget.prefs.setString('name', profileSnapshot.data["name"]);
      widget.prefs
          .setString('profile_photo', profileSnapshot.data["profile_photo"]);

      setState(() {
        _yourNameController.text = profileSnapshot.data["name"];
      });
    });

  //   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  //   // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  //   var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  //   var initializationSettingsIOS = IOSInitializationSettings(
  //       onDidReceiveLocalNotification: onDidReceiveLocalNotification);
  //   var initializationSettings = InitializationSettings(
  //       initializationSettingsAndroid, initializationSettingsIOS);
  //  //--------------------------------------
  //       showNotification();
        
   }

  // Map notifiedContacts(snapshot){
  //   var ds;
  //   for(int i =0; i < snapshot.data.documents.length; i++){
  //     ds.addAll(snapshot.data.documents.map((doc) => doc));
  //   }
  //   print(ds);
    

  // }

  // int retLenFromMapList(List fromMap){
  //   List<String> ret = new List<String>();
  //   ret = fromMap;
  //   return ret.length;
  // }

  generateContactTab() {
    return Column(
      children: <Widget>[
        StreamBuilder<QuerySnapshot>(
         stream: contactsReference.orderBy('time', descending: true).snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return new Text("No Contacts");
            // notifiedContacts(snapshot);
            // print('[0] is: ' + '${Glob().recAndSen[widget.prefs.getString('uid')]}');
            return Expanded(
              child: new ListView(
                children: generateContactList(snapshot),
              ),
            );
          },
        )
      ],
    );
  }

  Future<void> getProfilePicture() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('profiles/${widget.prefs.getString('uid')}');
    StorageUploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.onComplete;
    print('File Uploaded');
    String fileUrl = await storageReference.getDownloadURL();
    profileReference.updateData({'profile_photo': fileUrl});
  }

  generateProfileTab() {
    return Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (profileSnapshot != null
                ? (profileSnapshot.data['profile_photo'] != null
                    ? InkWell(
                        child: Container(
                          width: 190.0,
                          height: 190.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: NetworkImage(
                                  '${profileSnapshot.data['profile_photo']}'),
                            ),
                          ),
                        ),
                        onTap: () {
                          getProfilePicture();
                        },
                      )
                    : Container())
                : Container()),
            SizedBox(
              height: 20,
            ),
            (!editName && profileSnapshot != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text('${profileSnapshot.data["name"]}'),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            editName = true;
                          });
                        },
                      ),
                    ],
                  )
                : Container()),
            (editName
                ? Form(
                    key: _formStateKey,
                    autovalidate: true,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              EdgeInsets.only(left: 10, right: 10, bottom: 10),
                          child: TextFormField(
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please Enter Name';
                              }
                              if (value.trim() == "")
                                return "Only Space is Not Valid!!!";
                              return null;
                            },
                            controller: _yourNameController,
                            decoration: InputDecoration(
                              focusedBorder: new UnderlineInputBorder(
                                  borderSide: new BorderSide(
                                      width: 2, style: BorderStyle.solid)),
                              labelText: "Your Name",
                              icon: Icon(
                                Icons.verified_user,
                                color: Colors.grey,
                              ),
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container()),
            (editName
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(
                        child: Text(
                          'UPDATE',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          if (_formStateKey.currentState.validate()) {
                            profileReference
                                .updateData({'name': _yourNameController.text});
                            setState(() {
                              editName = false;
                            });
                          }
                        },
                        color: Colors.grey,
                      ),
                      RaisedButton(
                        child: Text('CANCEL'),
                        onPressed: () {
                          setState(() {
                            editName = false;
                          });
                        },
                      )
                    ],
                  )
                : Container())
          ]),
    );
  }

  Future<bool> checkForisSent(String uid) async{
    QuerySnapshot result = await db
      .collection('chats')
      .where('contact1', isEqualTo: uid)
      .where('contact2', isEqualTo: widget.prefs.getString('uid'))
      .getDocuments();
    if(result.documents.length == 0){
    result = await db
        .collection('chats')
        .where('contact2', isEqualTo: uid)
        .where('contact1', isEqualTo: widget.prefs.getString('uid'))
        .getDocuments();
        }
    var dId = result.documents[0].documentID;
    QuerySnapshot newResult = await db
      .collection('chats')
      .document(dId)
      .collection('messages')
      .where('receiver_id', isEqualTo: widget.prefs.getString('uid'))
      .where('isSent', isEqualTo: 1)
      .getDocuments();
    if(newResult.documents.length == 0){
      return false;
    }
    else{
      return true;
    }
    
  }

  generateContactList(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data.documents
        .map<Widget>(
          (doc) => InkWell(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.orange,
                  ),
                ),
              ),

              // (Glob().recAndSen.containsKey(widget.prefs.getString('uid')) == true) checks for whom to show the notification
              // widget.prefs.getSting('uid') is the uid of current user
              // (Glob().recAndSen['${widget.prefs.getString('uid')}'].contains(doc['uid']) == true) checks for in front of which contact notification should be shown
              // doc['uid'] is generated as soon as contact is tapped.

            //   child: ((Glob().recAndSen.containsKey(widget.prefs.getString('uid')) == true) ? ((Glob().recAndSen['${widget.prefs.getString('uid')}'].contains(doc['uid']) == true) ? ListTile(
            //   title: Text(doc["name"]),
            //   subtitle: Text(doc["mobile"]),
            //   trailing: Icon(Icons.message, color: Colors.blue),
            //   )
            //   : 
            //   ListTile(
            //     title: Text(doc["name"]),
            //     subtitle: Text(doc["mobile"]),
            //     trailing: Icon(Icons.chevron_right),
            //   ))
            //   :
            //   ListTile(
            //     title: Text(doc["name"]),
            //     subtitle: Text(doc["mobile"]),
            //     trailing: Icon(Icons.chevron_right, color: Colors.grey,),
            //     )
            //   ),
            // ), 

            // A FutureBuilder had to be used because we cannot use conditional statements with Future<dataType> it needs to be constant
            // so what happens here is checkForIsSent is passed 

            child: FutureBuilder(
              future: checkForisSent(doc['uid']),
              builder: (BuildContext context, AsyncSnapshot<bool> snapshot){
                switch (snapshot.connectionState){
                  case ConnectionState.none: return new ListTile(title: Text('Unable to load this contact'));
                  case ConnectionState.waiting: return new ListTile(title: Text('Loading Contact'));
                  default: 
                    if(snapshot.hasError){
                      return new ListTile(title: Text('Some Error occured'));
                    }
                    if(snapshot.hasData){
                      if(snapshot.data == true){
                        return new ListTile(
                          title: doc['name'] != null ? Text(doc['name']) : Text('Error Loading name'),
                          subtitle: doc['mobile'] != null ? Text(doc['mobile']) : Text('Error Loading number'),
                          trailing: Icon(Icons.message, color: Colors.blue),
                        );
                      }
                      if(snapshot.data == false){
                        return new ListTile(
                          title: doc['name'] != null ? Text(doc['name']) : Text('Error Loading name'),
                          subtitle: doc['mobile'] != null ? Text(doc['mobile']) : Text('Error Loading number'),
                          trailing: Icon(Icons.chevron_right),
                        );
                      }
                      else{
                        return new ListTile(
                          title: Text('Some Error occured'),
                        );
                      }
                    }
                }
              }
              ),
            ),


            onTap: () async {
              // the fist condition is checked whether the user (widget.prefs.getString('uid')) is in dictionary or not which means whether he
              // needs to be shown a notification or not, if not CircularProgressIndicator() is used, if it is there the second condition is
              // Glob().recAndSen[widget.prefs.getString('uid')].length != 0 which checks for an exception case and if length is 0
              // CircularProgressIndicator() is shown else the loop is continued, now comes the main condition the third condition is
              // Glob().recAndSen[widget.prefs.getString('uid')].length >= 2 which checks whether a person need to be shown notification
              // from multiple output or not. If yes, the doc['uid] clicked is removed from the list of contacts and if no that person is popped from the dictionary

                // to put selective conditions on unNotify such that it unNotifies only when appropriate person clicks appropriate name
                // receiever ID to be added through chat_page to help in identifiying receiver and sender

                unNotify(String receiver, String sender)async{
                  // result gets the documents of the chat where sender and receiver are passed

                  QuerySnapshot result = await db
                    .collection('chats')
                    .where('contact1', isEqualTo: sender)
                    .where('contact2', isEqualTo: receiver)
                    .getDocuments();
                  print(result.documents.length);
                  if(result.documents.length == 0){
                  result = await db
                    .collection('chats')
                    .where('contact2', isEqualTo: sender)
                    .where('contact1', isEqualTo: receiver)
                    .getDocuments();
                  }
                  var dID1 = result.documents[0].documentID;
                  // newResult stores the document only new(unseen) messages where isSent == 1

                  QuerySnapshot newResult = await db
                    .collection('chats')
                    .document(dID1)
                    .collection('messages')
                    .where('isSent', isEqualTo: 1)
                    .getDocuments();
                  print(newResult.documents.length);
                  List<String> dID2 = new List<String>();
                  // The below loop updates the value of 1 to 0 indicating message is seen
                  // The reason it is in loop is because there could be multiple messages sent to receiver

                  List<DocumentSnapshot> test = newResult.documents;
                  test.forEach((f) => print('test is: ' + '${f.data['sender_id']}'));
                  // print('testing: ' + test[0].data['sender_id']);

                  for(int i = 0; i < newResult.documents.length; i++){
                    dID2.add(newResult.documents[i].documentID);
                    // this if condition ensures that unNotify will only happen if appropriate person clicks the
                    // person from whom notification is to be received
                    
                    if(test[0]['receiver_id'] == receiver && test[0]['sender_id'] == sender){
                      db.collection('chats').document(dID1).collection('messages').document(dID2[i]).updateData({'isSent': 0});
                    }
                  }
                  print(dID2);
                }

              // Glob().recAndSen.containsKey(widget.prefs.getString('uid')) == true ? Glob().recAndSen[widget.prefs.getString('uid')].length != 0 ? Glob().recAndSen[widget.prefs.getString('uid')].length >= 2 ? Glob().recAndSen[widget.prefs.getString('uid')].remove(doc['uid']) :  Glob().recAndSen.removeWhere((k,v) => k == widget.prefs.getString('uid') && v.contains(doc['uid'])) 
              // : CircularProgressIndicator()
              // : CircularProgressIndicator();
              
              // print('dictionary is: ' + '${Glob().recAndSen}');

              unNotify(widget.prefs.getString('uid'), doc['uid']);

              QuerySnapshot result = await db
                  .collection('chats')
                  .where('contact1', isEqualTo: widget.prefs.getString('uid'))
                  .where('contact2', isEqualTo: doc["uid"])
                  .getDocuments();
              List<DocumentSnapshot> documents = result.documents;
              if (documents.length == 0) {
                result = await db
                    .collection('chats')
                    .where('contact2', isEqualTo: widget.prefs.getString('uid'))
                    .where('contact1', isEqualTo: doc["uid"])
                    .getDocuments();
                documents = result.documents;
                if (documents.length == 0) {
                  await db.collection('chats').add({
                    'contact1': widget.prefs.getString('uid'),
                    'contact2': doc["uid"]
                  }).then((documentReference) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          prefs: widget.prefs,
                          chatId: documentReference.documentID,
                          title: doc["name"],
                          receiverId: doc['uid'],
                        ),
                      ),
                    );
                  }).catchError((e) {print(e);});
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        prefs: widget.prefs,
                        chatId: documents[0].documentID,
                        title: doc["name"],
                        receiverId: doc['uid'],
                      ),
                    ),
                  );
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      prefs: widget.prefs,
                      chatId: documents[0].documentID,
                      title: doc["name"],
                      receiverId: doc['uid'],
                    ),
                  ),
                );
              }
            },
          ),
        )
        .toList();
  }

  openContacts() async {
    Contact contact = await _contactPicker.selectContact();
    if (contact != null) {
      String phoneNumber = contact.phoneNumber.number
          .toString()
          .replaceAll(new RegExp(r"\s\b|\b\s"), "")
          .replaceAll(new RegExp(r'[^\w\s]+'), '');
      if (phoneNumber.length == 10) {
        phoneNumber = '+91$phoneNumber';
      }
      if (phoneNumber.length == 12) {
        phoneNumber = '+$phoneNumber';
      }
      if (phoneNumber.length == 13) {
        DocumentReference mobileRef = db
            .collection("mobiles")
            .document(phoneNumber.replaceAll(new RegExp(r'[^\w\s]+'), ''));
        await mobileRef.get().then((documentReference) {
          if (documentReference.exists) {
            contactsReference.add({
              'uid': documentReference['uid'],
              'name': contact.fullName,
              'mobile': phoneNumber.replaceAll(new RegExp(r'[^\w\s]+'), ''),
            });
          } else {
            print('User Not Registered');
          }
        }).catchError((e) {});
      } else {
        print('Wrong Mobile Number');
      }
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      switch (_currentIndex) {
        case 0:
          _tabTitle = "Contacts";
          break;
        case 1:
          _tabTitle = "Profile";
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _children = [
      generateContactTab(),
      generateProfileTab(),
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: _currentIndex == 0 ? Hero(
              tag: 'logo',
              child: Expanded(
                child: Container(
                  child: Image.asset("assets/solar_logo.png"),
                ),
              )
            )
            :
            Container(),
            centerTitle: true,
            //backgroundColor: Color.fromRGBO(255, 219, 172, 20),
            backgroundColor: Colors.white,
            // backgroundColor: Color.fromRGBO(255, 210, 44, 40),
            // title: Glob().recAndSen.containsKey(widget.prefs.getString('uid')) == true ? Text('${retLenFromMapList(Glob().recAndSen[widget.prefs.getString('uid')])} new messages') : Text(_tabTitle),

            title:  Text(_tabTitle),
            actions: <Widget>[
              (_currentIndex == 0
                  ? Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          color: Colors.red[800],
                          onPressed: () {
                            openContacts();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          color: Colors.red[800],
                          onPressed: () {
                            FirebaseAuth.instance.signOut().then((response) {
                              widget.prefs.remove('is_verified');
                              widget.prefs.remove('mobile_number');
                              widget.prefs.remove('uid');
                              widget.prefs.remove('name');
                              widget.prefs.remove('profile_photo');
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegistrationPage(prefs: widget.prefs),
                                ),
                              );
                            });
                          },
                        )
                      ],
                    )
                  : 
                  Hero(
              tag: 'logo',
              child: Container(
                height: 40.0,
                child: Image.asset("assets/solar_logo.png"),)
                ))
            ],
          ),
          body: _children[_currentIndex],
          backgroundColor: Colors.grey[50],
          bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped, // new
            currentIndex: _currentIndex, // new
            items: [
              new BottomNavigationBarItem(
                //icon: Icon(Icons.mail, color: Color.fromRGBO(255, 219, 172, 20),),
                icon: Icon(Icons.mail, color: Colors.red[800]),
                title: Text('Contacts', style: TextStyle(color: Colors.black),),
              ),
              new BottomNavigationBarItem(
                //icon: Icon(Icons.verified_user, color: Color.fromRGBO(255, 219, 172, 20)),
                icon: Icon(Icons.person_pin, color: Colors.red[800]),
                title: Text('Profile', style: TextStyle(color: Colors.black),),
              )
            ],
          ),
        ),
      ),
    );
  }
}