import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:webrtc/utils/signaling.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _me;
  String _username = '';
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  Signaling _signaling = Signaling();
  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    _signaling.init();
    _signaling.onLocalStream = (MediaStream stream) {
      _localRenderer.srcObject = stream;
      _localRenderer.mirror = true;
    };
    _signaling.onRemoteStream = (MediaStream stream) {
      _remoteRenderer.srcObject = stream;
      //queremos visualizar los datos de video de la otra persona
      _remoteRenderer.mirror=true;
    };
    _signaling.onJoined = (bool isOk) {
      if (isOk) {
        setState(() {
          _me = _username;
        });
      }
    };
  }

  @override
  void dispose() {
    _signaling.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  _inputCall() {
    var username = '';
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            content: CupertinoTextField(
              placeholder: "LLamando a",
              onChanged: (text) => username = text,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                onPressed: () {
                  _signaling.call(username);
                  Navigator.pop(context);
                },
                child: Text('Hablar'),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: _me == null
            ? Padding(
                padding: EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    CupertinoTextField(
                      placeholder: 'Tu Nombre ',
                      textAlign: TextAlign.center,
                      onChanged: (text) => _username = text,
                    ),
                    SizedBox(height: 20),
                    CupertinoButton(
                      child: Text('Unirse'),
                      color: Colors.blue,
                      onPressed: () {
                        if (_username.trim().length == 0) {
                          return;
                        }
                        _signaling.emit('join', _username);
                      },
                    )
                  ],
                ),
              )
            : Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: RTCVideoView(_remoteRenderer),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 40,
                    child: Transform.scale(
                      scale: 0.3,
                      alignment: Alignment.bottomLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          width: 480,
                          height: 640,
                          color: Colors.black12,
                          child: RTCVideoView(_localRenderer),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                      right: 20,
                      bottom: 40,
                      child: CupertinoButton(
                        onPressed: _inputCall,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: Colors.green,
                        child: Text("LLamar"),
                      )
                  )
                ],
              ),
      ),
    );
  }
}
