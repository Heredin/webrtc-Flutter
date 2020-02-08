import 'package:flutter_webrtc/webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef OnLocalStream(MediaStream stream);

class Signaling{
  IO.Socket _socket;
  OnLocalStream onLocalStream;
  init()async{
   MediaStream stream= await navigator.getUserMedia(
        {
          "audio": true,
          "video": {
            "mandatory": {
              "minWidth": '480',
              // Provide your own width, height and frame rate here
              "minHeight": '640',
              "minFrameRate": '30',
            },
            "facingMode": "user",
            "optional": [],
          }
        });
     onLocalStream(stream);
  }

  _connect(){
    _socket = IO.io('https://backend-simple-webrtc.herokuapp.com', <String, dynamic>{
      'transports': ['websocket'],

    });
  }

dispose(){
    _socket?.disconnect();
}
}