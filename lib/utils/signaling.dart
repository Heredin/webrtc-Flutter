import 'package:flutter_webrtc/webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef OnLocalStream(MediaStream stream);
typedef OnRemoteStream(MediaStream stream);
typedef OnJoined(bool isOk);

class Signaling {
  IO.Socket _socket;
  OnLocalStream onLocalStream;
  OnRemoteStream onRemoteStream;
  OnJoined onJoined;
  RTCPeerConnection _peer;
  String _him;
  MediaStream _localStream;

  init() async {
    MediaStream stream = await navigator.getUserMedia({
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
    _localStream = stream;
    onLocalStream(stream);
    _connect();
  }

  _createPeer() async {
    this._peer = await createPeerConnection({
      "iceServers": [
        {
          "urls": ['stun:stun1.l.google.com:19302']
        }
      ]
    }, {});
    await _peer.addStream(_localStream);
    _peer.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate == null) {
        return;
      }
      print('send the IceCandidate');
      emit('candidate', {"username":_him,"candidate":candidate.toMap()});
    };
    _peer.onAddStream = (MediaStream remoteStream) {
      onRemoteStream(remoteStream);
    };
  }

  _connect() {
    _socket =
        IO.io('https://backend-simple-webrtc.herokuapp.com', <String, dynamic>{
      'transports': ['websocket'],
    });
    _socket.on('on-join', (isOk) {
      print("Unido jejej $isOk");
      onJoined(isOk);
    });

    _socket.on('on-call', (data) async {
      print("En llamada jejej $data");
      //hemos creado el peer para recibir la llamada del otro usuario
      await _createPeer();
      final String username = data['username'];
      _him = username;
      final offer = data['offer'];
      final RTCSessionDescription desc = RTCSessionDescription(offer['sdp'], offer['type']);

      await _peer.setRemoteDescription(desc);
      //aqui espero recibir el audio y el video
      final sdpConstraints = {
        "mandatory": {
          "OfferToReceiveAudio": true,
          "OfferToReceiveVideo": true,
        },
        "optional": [],
      };
      //creando la respuesta del otro usuario
      final RTCSessionDescription answer =
          await _peer.createAnswer(sdpConstraints);
      await _peer.setLocalDescription(answer);
      emit('answer', {"username": _him, "answer": answer.toMap()});
    });
    //capturar la respuesta que me dio  el otro usuario
    _socket.on('on-answer', (answer) {
      print("on-answer $answer");
      final RTCSessionDescription desc =
          RTCSessionDescription(answer['sdp'], answer['type']);
      _peer.setRemoteDescription(desc);
    });

    _socket.on('on-candidate', (data)async {
      print("on-candidate $data");
      final RTCIceCandidate candidate=RTCIceCandidate(data['candidate'],data['sdpMid'],data['sdpMLineIndex']);

      await _peer.addCandidate(candidate);
    });
  }

  emit(String eventName, dynamic data) {
    _socket?.emit(eventName, data);
  }

  call(String username) async {
    _him=username;
    await _createPeer();
    //Aqui le digo a la persona que quiero obtener el audio y video
    final sdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };
    final RTCSessionDescription offer = await _peer.createOffer(sdpConstraints);
    //registrar en el peer
    _peer.setLocalDescription(offer);
    //map me retorna el sdp y type
    emit('call', {"username": username, "offer": offer.toMap()});
  }

  dispose() {
    _socket?.disconnect();
  }
}
