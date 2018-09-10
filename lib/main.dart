import 'package:flutter/material.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lamp/lamp.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'package:image_picker_saver/image_picker_saver.dart';


List<CameraDescription> cameras;

bool lightOn = false;

void main() async{
  SystemChrome.setEnabledSystemUIOverlays([]);
  if(Platform.isAndroid){
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  cameras = await availableCameras();
  runApp(new MaterialApp(
      home: new HomePage()
  ));
}

class HomePage extends StatefulWidget{
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{


  bool bottomBarOpen = false;

  String scanned;

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  QRReaderController qRController;

  void initState(){
    super.initState();
    if(cameras.length>0){
      qRController = new QRReaderController(cameras[0], ResolutionPreset.high, CodeFormat.values, (s){
        if(bottomBarOpen){
          Navigator.of(context).pop();
          bottomBarOpen = false;
        }
        setState((){scanned = s;});
      });
      qRController.initialize().then((n){
        if(!mounted){
          return null;
        }
        setState((){});
        qRController.startScanning();
      });
    }
  }


  @override
  void dispose() {
    qRController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(qrController==null||!qRController.value.isInitialized){
      return new Container(child: new Center(child: new CircularProgressIndicator()));
    }
    if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height){
      return new Scaffold(
        body: new Center(
          child: new Text("Please enter portrait mode")
        )
      );
    }
    return scanned==null?new Scaffold(
      body: new Stack(
        children: [
          //new QRReaderPreview(qRController),
          new Container(color:Colors.black),
          // ignore: conflicting_dart_import
          new Positioned(child: new Image.asset("assets/topLeft.png",width: MediaQuery.of(context).size.width/12),left:MediaQuery.of(context).size.width/6,top:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/topRight.png",width: MediaQuery.of(context).size.width/12),right:MediaQuery.of(context).size.width/6,top:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/bottomLeft.png",width: MediaQuery.of(context).size.width/12),left:MediaQuery.of(context).size.width/6,bottom:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/bottomRight.png",width: MediaQuery.of(context).size.width/12),right:MediaQuery.of(context).size.width/6,bottom:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leading: new IconButton(
              icon: new Icon(lightOn?Icons.flash_off:Icons.flash_on,color: Colors.white),
              onPressed: (){
                if(!lightOn){
                  Lamp.turnOn();
                }else{
                  Lamp.turnOff();
                }
                setState((){lightOn = !lightOn;});
              }
            ),
            actions: [
              new IconButton(
                icon: new Icon(Icons.more_vert),
                onPressed: (){
                  bottomBarOpen = true;
                  showModalBottomSheet(context: context, builder: (context)=> new Container(
                    height: MediaQuery.of(context).size.height/2,
                    child: new Column(
                      children: ["Create a QR code","Decode from an Image","History","Website","Rate us"].map((s)=>new MaterialButton(height:MediaQuery.of(context).size.height/10,child:new Text(s),onPressed:() async{
                        Navigator.of(context).pop();
                        if(s=="Create a QR code"){
                          Navigator.push(context,new MaterialPageRoute(builder: (context) => new CreateACode()));
                        }else if(s=="Decode from a Picture"){

                        }else if(s=="History"){

                        }else if(s=="Website"){
                          const url = 'https://www.platypus.land';
                          if(await canLaunch(url)){
                            await launch(url);
                          }else{
                            throw 'Could not launch $url';
                          }
                        }else if(s=="Rate us"){
                          if(Platform.isIOS){

                          }else if(Platform.isAndroid){

                          }
                        }

                      })).toList()
                    )
                  )).then((v){
                    bottomBarOpen = false;
                  });
                },
              )
            ],
          )
        ]
      )
    ):new Scaffold(
      key: scaffoldKey,
      body: new Container(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            new Padding(padding: EdgeInsets.only(left:30.0,right:30.0),child:new Container(
              padding: EdgeInsets.all(15.0),
              color: Colors.black12,
              child: new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase())?new RichText(text:new TextSpan(
                text: scanned,
                // ignore: conflicting_dart_import
                style: new TextStyle(color: Colors.blue),
                recognizer: new TapGestureRecognizer()..onTap = () async{
                  bool isUrl = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase());
                  String url = isUrl?Uri.encodeFull(scanned).toString():"https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                  bool isHttps = url.length>=8&&url.substring(0,8)=="https://";
                  if(isUrl){
                    if(!isHttps&&(url.length<7||url.substring(0,7)!="http://")){
                      url = "http://"+url;
                    }
                    if(url.length<11+(isHttps?1:0)||url.substring(7+(isHttps?1:0),11+(isHttps?1:0))!="www."){
                      url = (isHttps?"https://":"http://")+"www."+url.substring(7+(isHttps?1:0));
                    }
                  }
                  if(await canLaunch(url)){
                    await launch(url);
                  }else{
                    if(isUrl){
                      String url2 = "https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                      if(await canLaunch(url2)){
                        await launch(url2);
                      }else{
                        throw 'Could not launch $url2';
                      }
                    }
                    throw 'Could not launch $url';
                  }
                }
              )):new Text(scanned,style:new TextStyle(color:Colors.black),maxLines:4,overflow: TextOverflow.ellipsis)
            )),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                new RaisedButton(
                    child: new Text("Copy to clipboard"),
                    onPressed: () async{
                      await Clipboard.setData(new ClipboardData(text:scanned));
                      scaffoldKey.currentState.removeCurrentSnackBar();
                      scaffoldKey.currentState.showSnackBar(new SnackBar(content:new Text("Copied"),duration: new Duration(milliseconds: 500)));
                    }
                ),
                new RaisedButton(
                    child: new Text("Open in browser"),
                    onPressed: () async{
                      bool isUrl = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase());
                      String url = isUrl?Uri.encodeFull(scanned).toString():"https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                      bool isHttps = url.length>=8&&url.substring(0,8)=="https://";
                      if(isUrl){
                        if(!isHttps&&(url.length<7||url.substring(0,7)!="http://")){
                          url = "http://"+url;
                        }
                        if(url.length<11+(isHttps?1:0)||url.substring(7+(isHttps?1:0),11+(isHttps?1:0))!="www."){
                          url = (isHttps?"https://":"http://")+"www."+url.substring(7+(isHttps?1:0));
                        }
                      }
                      if(await canLaunch(url)){
                        await launch(url);
                      }else{
                        if(isUrl){
                          String url2 = "https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                          if(await canLaunch(url2)){
                            await launch(url2);
                          }else{
                            throw 'Could not launch $url2';
                          }
                        }
                        throw 'Could not launch $url';
                      }
                    }
                )
              ]
            ),
            new RaisedButton(
                child: new Text("Done"),
                onPressed: (){
                  setState((){scanned=null;});
                  qRController.startScanning();
                }
            )
          ]
        )
      )
    );
  }
}

class CreateACode extends StatefulWidget{
  @override
  CreateACodeState createState() => new CreateACodeState();
}

class CreateACodeState extends State<CreateACode>{

  String input = "";

  TextEditingController c = new TextEditingController();

  GlobalKey globalKey = new GlobalKey();

  @override
  Widget build(BuildContext context){
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("Create a Code"),
        actions: [
          new IconButton(
            icon: new Icon(Icons.share),
            onPressed: () async{
              RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
              var image = await boundary.toImage();
              ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
              Uint8List pngBytes = byteData.buffer.asUint8List();
              final tempDir = await getTemporaryDirectory();
              final file = await new File('${tempDir.path}/image.png').create();
              await file.writeAsBytes(pngBytes);

            }
          )
        ]
      ),
      body: new Container(
        child: new Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children: [
          new Padding(padding: EdgeInsets.only(left:15.0,right:15.0),child:new Container(color:Colors.black12,child:new Padding(padding:EdgeInsets.only(left:5.0),child:new TextField(inputFormatters: [new LengthLimitingTextInputFormatter(78)],controller: c,decoration: new InputDecoration(hintText:"Data"),onChanged:(s){setState((){input = s;});})))),
          new Center(child:new RepaintBoundary(key:globalKey,child:new QrImage(data:input,size:MediaQuery.of(context).size.height/3))),
          new RaisedButton(child:new Text("Save"),onPressed:(){}),
        ])
      )
    );
  }
}