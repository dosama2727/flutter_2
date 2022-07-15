import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/const/agora.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  // 컨트롤러 처럼 쓴다.
  RtcEngine? engine;
  int? uid;
  int? otherUid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LIVE'),
      ),
      body: FutureBuilder(
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          print(snapshot.hasData);
          print(snapshot.data);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    renderMainView(),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        color: Colors.grey,
                        height: 160,
                        width: 120,
                        child: renderSubView(),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async{
                  if(engine != null) {
                    await engine!.leaveChannel();
                  }

                  Navigator.of(context).pop();
                },
                child: Text('채널 나가기'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget renderSubView() {
    if (otherUid == null) {
      print('유저 없음');
      return Center(
        child: Text('채널에 유저가 없습니다.', style: TextStyle(color: Colors.red),),
      );
    } else {
      print('유저 있음');
      print('otherUid at renderSubView \n: ${otherUid}');
      print('uid at renderSubView : ${uid}');
      return RtcRemoteView.SurfaceView(
        uid: otherUid!,
        channelId: CHANNEL_NAME,
      );
    }
  }

  Widget renderMainView() {
    if (uid == null) {
      return Center(
        child: Text('채널에 참가해주세요!'),
      );
    } else {
      print('RtcLocalView.SurfaceView');
      return RtcLocalView.SurfaceView();
    }
  }

  Future<bool> init() async {
    final repo = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = repo[Permission.camera];
    final micPermission = repo[Permission.microphone];

    if (cameraPermission != PermissionStatus.granted ||
        micPermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    // rtc엔진 초기화
    if (engine == null) {
      RtcEngineContext context = RtcEngineContext(APP_ID);

      engine = await RtcEngine.createWithContext(context);

      engine!.setEventHandler(
        RtcEngineEventHandler(
          // 내가 채널에 입장했을때!
          joinChannelSuccess: (String channel, int uid, int elapsed) {
            print('채널에 입장했습니다. uid : ${uid}');
            setState(() {
              this.uid = uid;
            });
          },
          // 내가 채널에서 퇴장했을때!
          leaveChannel: (RtcStats state) {
            print('채널 퇴장');
            setState(() {
              uid = null;
            });
          },

          // 상대가 채널에 입장했을때!
          userJoined: (int uid, int elapsed) {
            print('상대가 채널에 입장했습니다.${uid}');
            setState(() {
              otherUid = uid;
            });
          },

          // 상대가 채널에서 퇴장했을때!!
          userOffline: (int uid, UserOfflineReason reason) {
            print('상대가 채널에서 나갔습니다. ${uid}\nreason : ${reason}');
            setState(() {
              otherUid = null;
            });
          },
        ),
      );

      // 비디오 활성화
      await engine!.enableVideo();
      //채널에 들어가기(카톡의 대화방같은거), 실행하는 순간 데이터와 돈이 깍인다.
      await engine!.joinChannel(
        TEMP_TOKEN,
        CHANNEL_NAME,
        null,
        0,
        // 0을 넣어면 아고라에서 알아서 중복되지 않는 인트값을 할당한다
      );
    }

    return true;
  }
}
