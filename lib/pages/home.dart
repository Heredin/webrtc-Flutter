import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:webrtc/utils/signaling.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RTCVideoRenderer _localRenderer=RTCVideoRenderer();
   Signaling _signaling=Signaling();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _localRenderer.initialize();
    _signaling.init();
    _signaling.onLocalStream=(MediaStream stream){
      _localRenderer.srcObject=stream;
      _localRenderer.mirror=true;
    };
  }
  @override
  void dispose() {
    _signaling.dispose();
    _localRenderer?.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 20,
             bottom: 40,
             child: Transform.scale(
                 scale: 0.3,
               alignment: Alignment.bottomLeft,
               child: ClipRRect(
                 borderRadius:BorderRadius.circular(20.0),
                 child: Container(
                   width: 480,
                   height: 640 ,
                   color: Colors.black12,
                   child: RTCVideoView(
_localRenderer
                   ),
                 ),
               ),),
           )
          ],
        ),
      ),
    );
  }
}

