import 'package:flutter/material.dart';
import 'package:fast_qr_reader_view/fast_qr_reader_view.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lamp/lamp.dart';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';


List<CameraDescription> cameras;

bool lightOn = false;

void main() async{
  SystemChrome.setEnabledSystemUIOverlays([]);
  if(Platform.isAndroid){
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown]);
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

  AnimationController animationController;

  Animation<double> verticalPosition;

  void initState(){
    super.initState();

    animationController = new AnimationController(
      vsync: this,
      duration: new Duration(seconds: 3),
    );

    animationController.addListener((){
      setState((){});
    });

    animationController.forward();
    verticalPosition = new Tween<double>(begin: 0.0, end: 300.0).animate(new CurvedAnimation(parent: animationController, curve: Curves.linear))..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          animationController.reverse();
        } else if (state == AnimationStatus.dismissed) {
          animationController.forward();
        }
    });

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

  @override
  void dispose() {
    qRController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    if(!qRController.value.isInitialized){
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
          new QRReaderPreview(qRController),
          //new Positioned(child: new Container(height:MediaQuery.of(context).size.height,width:MediaQuery.of(context).size.width/6,color:Colors.black12),right:0.0),
          //new Positioned(child: new Container(height:MediaQuery.of(context).size.height,width:MediaQuery.of(context).size.width/6,color:Colors.black12),left:0.0),
          //new Positioned(child: new Container(width:MediaQuery.of(context).size.width/1.5+1,height:(MediaQuery.of(context).size.height-MediaQuery.of(context).size.width/1.5)/2,color:Colors.black12),left:MediaQuery.of(context).size.width/6-.5),
          //new Positioned(child: new Container(width:MediaQuery.of(context).size.width/1.5+1,height:(MediaQuery.of(context).size.height-MediaQuery.of(context).size.width/1.5)/2,color:Colors.black12),left:MediaQuery.of(context).size.width/6-.5,bottom:0.0),
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
                    height: MediaQuery.of(context).size.height/3,
                    child: new Column(
                      children: ["Create a QR code","Decode from an Image","Website","Rate us"].map((s)=>new MaterialButton(height:MediaQuery.of(context).size.height/12,child:new Text(s),onPressed:() async{
                        Navigator.of(context).pop();
                        if(s=="Create a QR code"){

                        }else if(s=="Decode from a Picture"){

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
          ),
          new Center(
            child: Stack(
              children: <Widget>[
                new SizedBox(
                  height: MediaQuery.of(context).size.width/1.5,
                  width: MediaQuery.of(context).size.width/1.5,
                  child: new Container(decoration: new BoxDecoration(border: Border.all(color: Colors.white, width: 2.0))),
                ),
                new Positioned(
                  top: verticalPosition.value,
                  child: new Container(
                    width: (MediaQuery.of(context).size.width/1.5),
                    height: 2.0,
                    color: Colors.green,
                  ),
                  left:2.0,
                  right:2.0
                )
              ],
            )
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
                style: new TextStyle(color: Colors.blue),
                recognizer: new TapGestureRecognizer()..onTap = () async{
                  String url = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase())?Uri.encodeFull(scanned).toString():"https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                  if(new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase()) && (url.substring(0,7)!="https://"&&url.substring(0,6)!="http://")){
                    url = "https://"+url;
                  }
                  if(await canLaunch(url)){
                    await launch(url);
                  }else{
                    if(new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase())){
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
                      String url = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase())?Uri.encodeFull(scanned).toString():"https://www.google.com/search?q=${Uri.encodeComponent(scanned)}";
                      if(new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase()) && (url.substring(0,7)!="https://"&&url.substring(0,6)!="http://")){
                        url = "https://"+url;
                      }
                      if(await canLaunch(url)){
                        await launch(url);
                      }else{
                        if(new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(scanned.toLowerCase())){
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
                  new Timer(new Duration(seconds:1),(){qRController.startScanning();});
                }
            )
          ]
        )
      )
    );
  }
}
