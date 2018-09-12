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
import 'package:share/share.dart';
import 'package:image_picker_saver/image_picker_saver.dart';


List<CameraDescription> cameras;

bool lightOn = false;

List savedCodes;

PersistentData savedInfo = new PersistentData(directory: "saved");

void main() async{
  savedCodes = (await savedInfo.readData());
  savedCodes = savedCodes!=null?savedCodes:new List();
  SystemChrome.setEnabledSystemUIOverlays([]);
  if(Platform.isAndroid){
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  cameras = await availableCameras();
  runApp(new MaterialApp(debugShowCheckedModeBanner: false,home: new HomePage()));
}

class HomePage extends StatefulWidget{
  @override
  HomePageState createState() => new HomePageState();
}

class HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{

  bool bottomBarOpen = false;

  String scanned;

  QRReaderController qRController;

  void initState(){
    super.initState();
    if(cameras.length>0){
      qRController = new QRReaderController(cameras[0], ResolutionPreset.high, CodeFormat.values, (s){
        if(bottomBarOpen){
          Navigator.of(context).pop();
          bottomBarOpen = false;
        }
        qRController.stopScanning();
        setState((){scanned = s;});
        savedCodes.add(s);
        savedInfo.writeData(savedCodes);
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
          qRController!=null&&qRController.value.isInitialized?new QRReaderPreview(qRController):new Container(color:Colors.black,child: new Center(child: new CircularProgressIndicator())),
          // ignore: conflicting_dart_import
          new Positioned(child: new Image.asset("assets/topLeft.png",width: MediaQuery.of(context).size.width/12),left:MediaQuery.of(context).size.width/6,top:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/topRight.png",width: MediaQuery.of(context).size.width/12),right:MediaQuery.of(context).size.width/6,top:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/bottomLeft.png",width: MediaQuery.of(context).size.width/12),left:MediaQuery.of(context).size.width/6,bottom:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new Positioned(child: new Image.asset("assets/bottomRight.png",width: MediaQuery.of(context).size.width/12),right:MediaQuery.of(context).size.width/6,bottom:MediaQuery.of(context).size.height/2-MediaQuery.of(context).size.width/3),
          new AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            leading: new IconButton(
              icon: new Icon(lightOn?Icons.flash_on:Icons.flash_off,color: Colors.white),
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
                      children: ["Create a QR code","Decode from an Image","History","Website","Rate us"].map((s)=>new Container(decoration:new BoxDecoration(border: new Border(bottom:new BorderSide(width:.5,color:Colors.black38))),child:new MaterialButton(minWidth:double.infinity,height:MediaQuery.of(context).size.height/10-.5,child:new Text(s),onPressed:() async{
                        Navigator.of(context).pop();
                        if(s=="Create a QR code"){
                          Navigator.push(context,new MaterialPageRoute(builder: (context) => new CreateACode()));
                        }else if(s=="Decode from a Picture"){

                        }else if(s=="History"){
                          Navigator.push(context,new MaterialPageRoute(builder: (context) => new HistoryPage()));
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

                      }))).toList()
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
      body: new Builder(builder:(context)=>new Container(
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
                    if(await canLaunch(url)){
                      await launch(url);
                      return;
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
                      Scaffold.of(context).removeCurrentSnackBar();
                      Scaffold.of(context).showSnackBar(new SnackBar(content:new Text("Copied"),duration: new Duration(milliseconds: 500)));
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
                        if(await canLaunch(url)){
                          await launch(url);
                          return;
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
            new RaisedButton(child:new Text("Save"),onPressed:(){
              savedCodes.add(scanned);
              savedInfo.writeData(savedCodes);
              Scaffold.of(context).removeCurrentSnackBar();
              Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Saved"),duration: new Duration(milliseconds: 500)));
            }),
            new RaisedButton(
                child: new Text("Done"),
                onPressed: (){
                  setState((){scanned=null;});
                  qRController.startScanning();
                }
            )
          ]
        )
      ))
    );
  }
}

class CreateACode extends StatefulWidget{
  @override
  CreateACodeState createState() => new CreateACodeState();
}

class CreateACodeState extends State<CreateACode>{

  String input = "";

  FocusNode f = new FocusNode();

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
              try{
                RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
                var image = await boundary.toImage();
                ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
                Uint8List pngBytes = byteData.buffer.asUint8List();
                final tempDir = await getTemporaryDirectory();
                final file = await new File('${tempDir.path}/image.png').create();
                await file.writeAsBytes(pngBytes);
                final channel = const MethodChannel('channel:land.platypus.share/share');
                channel.invokeMethod('shareFile', 'image.png');
              }catch(e){
                print(e);
              }
            }
          )
        ]
      ),
      body: new Builder(builder: (context)=>new Container(
        child: new Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children: [
          new Padding(padding: EdgeInsets.only(left:15.0,right:15.0),child:new Container(color:Colors.black12,child:new Padding(padding:EdgeInsets.only(left:5.0),child:new TextField(focusNode: f,inputFormatters: [new LengthLimitingTextInputFormatter(78)],controller: c,decoration: new InputDecoration(hintText:"Data"),onChanged:(s){setState((){input = s;});})))),
          new Center(child:new RepaintBoundary(key:globalKey,child:new QrImage(data:input,size:MediaQuery.of(context).size.height/3))),
          !f.hasFocus?new RaisedButton(child:new Text("Save"),onPressed:(){
            if(input.length>0){
              savedCodes.add(input);
              savedInfo.writeData(savedCodes);
              Scaffold.of(context).removeCurrentSnackBar();
              Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Saved"),duration: new Duration(milliseconds: 500)));
            }else{
              Scaffold.of(context).removeCurrentSnackBar();
              Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Failed: Please enter text"),duration: new Duration(milliseconds: 500)));
            }
          }):new Container(),
        ])
      ))
    );
  }
}

class HistoryPage extends StatefulWidget{
  @override
  HistoryPageState createState() => new HistoryPageState();
}

class HistoryPageState extends State<HistoryPage>{

  GlobalKey expandedKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
          child: new CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: false,
                  floating: true,
                  flexibleSpace: const FlexibleSpaceBar(
                      title: const Text("History")
                  ),
                ),
                new SliverList(
                  delegate: new SliverChildBuilderDelegate((BuildContext context, int index) {
                        return new Column(children: [new Slidable(
                          delegate: new SlidableScrollDelegate(),
                          key: new ObjectKey(savedCodes.length-index-1),
                          actionExtentRatio: 0.25,
                          child: new Container(
                            height:MediaQuery.of(context).size.height/8,
                            color: Colors.white,
                            child: new MaterialButton(onPressed:() async{
                              Navigator.push(context,new MaterialPageRoute(builder: (context) => new QRView(savedCodes[savedCodes.length-index-1])));
                            },child:new Center(child: new ListTile(
                              leading: new QrImage(data:savedCodes[savedCodes.length-index-1],size:MediaQuery.of(context).size.height/10),
                              title: new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(savedCodes[savedCodes.length-index-1].toLowerCase())?new Text(savedCodes[savedCodes.length-index-1],maxLines: 3,overflow: TextOverflow.ellipsis,style: new TextStyle(color:Colors.blue)):new Text(savedCodes[savedCodes.length-index-1],maxLines: 3,overflow: TextOverflow.ellipsis)
                            )),minWidth: double.infinity),
                          ),
                          actions: <Widget>[
                            new IconSlideAction(
                              caption: 'Share',
                              color: Colors.blue,
                              icon: Icons.share,
                              onTap: () async{
                                showDialog(context:context,builder: (context)=> new AlertDialog(title: new Center(child:new Text("Share")),content: new Center(child:new Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly,children:[new Column(children:[new RepaintBoundary(key:expandedKey,child:new QrImage(data: savedCodes[savedCodes.length-index-1],size:MediaQuery.of(context).size.height/3)),new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(savedCodes[savedCodes.length-index-1].toLowerCase())?new RichText(text:new TextSpan(
                                    text: savedCodes[savedCodes.length-index-1],
                                    // ignore: conflicting_dart_import
                                    style: new TextStyle(color: Colors.blue),
                                    recognizer: new TapGestureRecognizer()..onTap = () async{
                                      bool isUrl = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(savedCodes[savedCodes.length-index-1].toLowerCase());
                                      String url = isUrl?Uri.encodeFull(savedCodes[savedCodes.length-index-1]).toString():"https://www.google.com/search?q=${Uri.encodeComponent(savedCodes[savedCodes.length-index-1])}";
                                      bool isHttps = url.length>=8&&url.substring(0,8)=="https://";
                                      if(isUrl){
                                        if(!isHttps&&(url.length<7||url.substring(0,7)!="http://")){
                                          url = "http://"+url;
                                        }
                                        if(await canLaunch(url)){
                                          await launch(url);
                                          return;
                                        }
                                        if(url.length<11+(isHttps?1:0)||url.substring(7+(isHttps?1:0),11+(isHttps?1:0))!="www."){
                                          url = (isHttps?"https://":"http://")+"www."+url.substring(7+(isHttps?1:0));
                                        }
                                      }
                                      if(await canLaunch(url)){
                                        await launch(url);
                                      }else{
                                        if(isUrl){
                                          String url2 = "https://www.google.com/search?q=${Uri.encodeComponent(savedCodes[savedCodes.length-index-1])}";
                                          if(await canLaunch(url2)){
                                            await launch(url2);
                                          }else{
                                            throw 'Could not launch $url2';
                                          }
                                        }
                                        throw 'Could not launch $url';
                                      }
                                    }
                                )):new Text(savedCodes[savedCodes.length-index-1],style:new TextStyle(color:Colors.black),maxLines:3,overflow: TextOverflow.ellipsis)]),new RaisedButton(onPressed:(){Share.share(savedCodes[savedCodes.length-index-1]);},child: new Text("Share text")),new RaisedButton(onPressed:() async{
                                  try{
                                    RenderRepaintBoundary boundary = expandedKey.currentContext.findRenderObject();
                                    var image = await boundary.toImage();
                                    ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
                                    Uint8List pngBytes = byteData.buffer.asUint8List();
                                    final tempDir = await getTemporaryDirectory();
                                    final file = await new File('${tempDir.path}/image.png').create();
                                    await file.writeAsBytes(pngBytes);
                                    final channel = const MethodChannel('channel:land.platypus.share/share');
                                    channel.invokeMethod('shareFile', 'image.png');
                                  }catch(e){
                                    print(e);
                                  }
                                },child: new Text("Share image")),new RaisedButton(onPressed:(){Navigator.of(context).pop();},child: new Text("Close"))]))));
                              },
                            ),
                            new IconSlideAction(
                              caption: 'Copy',
                              color: Colors.indigo,
                              icon: Icons.archive,
                              onTap: () async{
                                await Clipboard.setData(new ClipboardData(text:savedCodes[savedCodes.length-index-1]));
                                Scaffold.of(context).removeCurrentSnackBar();Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Copied"),duration: new Duration(milliseconds: 500)));
                              },
                            ),
                          ],
                          secondaryActions: [
                            new IconSlideAction(
                              caption: 'Delete',
                              color: Colors.red,
                              icon: Icons.delete,
                              onTap: (){
                                setState((){savedCodes.removeAt(savedCodes.length-index-1);});
                                savedInfo.writeData(savedCodes);
                                Scaffold.of(context).removeCurrentSnackBar();Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Deleted"),duration: new Duration(milliseconds: 500)));
                              },
                            ),
                          ],
                          slideToDismissDelegate: new SlideToDismissDrawerDelegate(
                            onDismissed: (actionType){
                              setState((){savedCodes.removeAt(savedCodes.length-index-1);});
                              savedInfo.writeData(savedCodes);
                              Scaffold.of(context).removeCurrentSnackBar();Scaffold.of(context).showSnackBar(new SnackBar(content: new Text("Deleted"),duration: new Duration(milliseconds: 500)));
                            },
                            dismissThresholds: <SlideActionType, double>{
                              SlideActionType.primary: 1.0,
                              SlideActionType.secondary: .5
                            }
                          ),
                        ),new Container(height:.5,color:Colors.black38)]);
                      },
                      childCount: savedCodes.length
                  ),
                )
              ]
          )
      )
    );
  }
}

class QRView extends StatefulWidget{

  String text;

  QRView(this.text);

  @override
  QRViewState createState() => new QRViewState();
}

class QRViewState extends State<QRView>{

  GlobalKey globalKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text("QR Code"),actions: [
          new IconButton(
              icon: new Icon(Icons.share),
              onPressed: () async{
                try{
                  RenderRepaintBoundary boundary = globalKey.currentContext.findRenderObject();
                  var image = await boundary.toImage();
                  ByteData byteData = await image.toByteData(format: ImageByteFormat.png);
                  Uint8List pngBytes = byteData.buffer.asUint8List();
                  final tempDir = await getTemporaryDirectory();
                  final file = await new File('${tempDir.path}/image.png').create();
                  await file.writeAsBytes(pngBytes);
                  final channel = const MethodChannel('channel:land.platypus.share/share');
                  channel.invokeMethod('shareFile', 'image.png');
                }catch(e){
                  print(e);
                }
              }
          )
        ]),
        body: new Builder(builder:(context)=>new Container(
            child: new Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  new Padding(padding: EdgeInsets.only(left:30.0,right:30.0),child:new Container(
                      padding: EdgeInsets.all(15.0),
                      color: Colors.black12,
                      child: new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(widget.text.toLowerCase())?new RichText(text:new TextSpan(
                          text: widget.text,
                          // ignore: conflicting_dart_import
                          style: new TextStyle(color: Colors.blue),
                          recognizer: new TapGestureRecognizer()..onTap = () async{
                            bool isUrl = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(widget.text.toLowerCase());
                            String url = isUrl?Uri.encodeFull(widget.text).toString():"https://www.google.com/search?q=${Uri.encodeComponent(widget.text)}";
                            bool isHttps = url.length>=8&&url.substring(0,8)=="https://";
                            if(isUrl){
                              if(!isHttps&&(url.length<7||url.substring(0,7)!="http://")){
                                url = "http://"+url;
                              }
                              if(await canLaunch(url)){
                                await launch(url);
                                return;
                              }
                              if(url.length<11+(isHttps?1:0)||url.substring(7+(isHttps?1:0),11+(isHttps?1:0))!="www."){
                                url = (isHttps?"https://":"http://")+"www."+url.substring(7+(isHttps?1:0));
                              }
                            }
                            if(await canLaunch(url)){
                              await launch(url);
                            }else{
                              if(isUrl){
                                String url2 = "https://www.google.com/search?q=${Uri.encodeComponent(widget.text)}";
                                if(await canLaunch(url2)){
                                  await launch(url2);
                                }else{
                                  throw 'Could not launch $url2';
                                }
                              }
                              throw 'Could not launch $url';
                            }
                          }
                      )):new Text(widget.text,style:new TextStyle(color:Colors.black),maxLines:4,overflow: TextOverflow.ellipsis)
                  )),
                  new Center(child:new RepaintBoundary(key:globalKey,child:new QrImage(data:widget.text,size:MediaQuery.of(context).size.height/3))),
                  new Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        new RaisedButton(
                            child: new Text("Copy to clipboard"),
                            onPressed: () async{
                              await Clipboard.setData(new ClipboardData(text:widget.text));
                              Scaffold.of(context).removeCurrentSnackBar();
                              Scaffold.of(context).showSnackBar(new SnackBar(content:new Text("Copied"),duration: new Duration(milliseconds: 500)));
                            }
                        ),
                        new RaisedButton(
                            child: new Text("Open in browser"),
                            onPressed: () async{
                              bool isUrl = new RegExp("^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?\$").hasMatch(widget.text.toLowerCase());
                              String url = isUrl?Uri.encodeFull(widget.text).toString():"https://www.google.com/search?q=${Uri.encodeComponent(widget.text)}";
                              bool isHttps = url.length>=8&&url.substring(0,8)=="https://";
                              if(isUrl){
                                if(!isHttps&&(url.length<7||url.substring(0,7)!="http://")){
                                  url = "http://"+url;
                                }
                                if(await canLaunch(url)){
                                  await launch(url);
                                  return;
                                }
                                if(url.length<11+(isHttps?1:0)||url.substring(7+(isHttps?1:0),11+(isHttps?1:0))!="www."){
                                  url = (isHttps?"https://":"http://")+"www."+url.substring(7+(isHttps?1:0));
                                }
                              }
                              if(await canLaunch(url)){
                                await launch(url);
                              }else{
                                if(isUrl){
                                  String url2 = "https://www.google.com/search?q=${Uri.encodeComponent(widget.text)}";
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
                  )
                ]
            )
        ))
    );
  }
}

class PersistentData{

  PersistentData({@required this.directory});

  String directory;

  Future<String> get _localPath async {
    return (await getApplicationDocumentsDirectory()).path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return new File('$path/$directory.txt');
  }

  Future<dynamic> readData() async {
    try {
      final file = await _localFile;
      return json.decode(await file.readAsString());
    } catch (e) {
      return null;
    }
  }

  Future<File> writeData(dynamic data) async {
    final file = await _localFile;
    return file.writeAsString(json.encode(data));
  }

}