import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linring_front_flutter/models/chat_model.dart';
import 'package:linring_front_flutter/models/login_info.dart';
import 'package:linring_front_flutter/models/tagset_model.dart';
import 'package:linring_front_flutter/models/user_model.dart';
import 'package:linring_front_flutter/screens/main_screen.dart';
import 'package:linring_front_flutter/screens/report_screen.dart';
import 'package:linring_front_flutter/widgets/custom_appbar.dart';
import 'package:http/http.dart' as http;
import 'package:linring_front_flutter/widgets/custom_outlined_button.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'globals.dart' as globals;

class ChatScreen extends StatefulWidget {
  LoginInfo loginInfo;
  final ChatRoom room;
  ChatScreen({required this.loginInfo, required this.room, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late User opponentUser;
  late Tagset opponentTagset;
  String _enteredMessage = "";
  String ratingScore = "0";
  DateTime? promiseDate;
  late DateTime twoHoursLater;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool afterMeeting = false;
  bool afterPromise = false;
  bool buttonIsActive = false;

  Future<void> _loadMessages() async {
    // Global Variable 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.messages.value = [];
    });

    globals.currentRoom = widget.room;

    String apiAddress = dotenv.get("API_ADDRESS");
    final url =
        Uri.parse('$apiAddress/chat/message?room__id=${widget.room.id}');
    final token = widget.loginInfo.access;
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print(utf8.decode(response.bodyBytes));
    print(response.statusCode);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      // 기존 채팅 불러오기
      globals.messages.value = (body as List<dynamic>)
          .map<Message>((e) => Message.fromJson(e))
          .toList();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 입장 알림 메세지 리스트 맨 앞에 추가
        globals.messages.value.insert(
            0,
            Message(
              id: 0,
              sender: widget.loginInfo.user,
              receiver: opponentUser,
              created: "",
              modified: "",
              message:
                  ' ${widget.room.tag!.place}에서 ${widget.room.tag!.person}랑 ${widget.room.tag!.method}${widget.room.tag!.method == "카페" ? "가기" : "하기"}를 선택한 ${widget.room.relation!.nickname}님이 ${widget.room.tag2!.place}에서 ${widget.room.tag2!.person}랑 ${widget.room.tag2!.method}${widget.room.tag2!.method == "카페" ? "가기" : "하기"}를 선택한 ${widget.room.relation2!.nickname}님에게 채팅을 걸었습니다.',
              isRead: true,
              type: 0,
              args: null,
              room: widget.room.id!,
            ));
        // 역순으로 재배치 + ValueNotifier에 새로운 값 할당(값 변경 인식)
        globals.messages.value = globals.messages.value.reversed.toList();
      });
    } else {
      throw Exception('Failed to load messages.');
    }
  }

  void _createRating() async {
    String apiAddress = dotenv.env['API_ADDRESS'] ?? '';
    final url = Uri.parse('$apiAddress/accounts/rating/update/');
    final token = widget.loginInfo.access;

    String body = jsonEncode({"user": opponentUser.id, "rating": ratingScore});

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );
    debugPrint((response.statusCode).toString());
    debugPrint(body);
    if (response.statusCode == 200) {
      if (!mounted) return;
      afterMeeting = false;
      Navigator.pop(context);
    }
  }

  void _patchReservationTime() async {
    String apiAddress = dotenv.get("API_ADDRESS");
    String? isoFormattedString;
    final url = Uri.parse('$apiAddress/chat/room/${widget.room.id}/');
    final token = widget.loginInfo.access;
    if (promiseDate == null) {
      isoFormattedString = null;
    } else {
      twoHoursLater = promiseDate!.add(const Duration(hours: 2));
      isoFormattedString = formatISOTime(promiseDate!);
    }
    final body = jsonEncode({
      "tagset": widget.room.tag!.id,
      "tagset2": widget.room.tag2!.id,
      "reservation_time": isoFormattedString,
    });
    await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.messages.value.insert(
        0,
        Message(
          id: 0,
          sender: widget.loginInfo.user,
          receiver: opponentUser,
          created: "",
          modified: "",
          message: "",
          isRead: true,
          type: 2,
          args: isoFormattedString,
          room: widget.room.id!,
        ),
      );
      // ValueNotifier의 value 재할당
      globals.messages.value = List.from(globals.messages.value);
    });
  }

  String formatISOTime(DateTime date) {
    var duration = date.timeZoneOffset;
    if (duration.isNegative) {
      return ("${DateFormat("yyyy-MM-ddTHH:mm:ss.mmm").format(date)}-${duration.inHours.toString().padLeft(2, '0')}${(duration.inMinutes - (duration.inHours * 60)).toString().padLeft(2, '0')}");
    } else {
      return ("${DateFormat("yyyy-MM-ddTHH:mm:ss.mmm").format(date)}+${duration.inHours.toString().padLeft(2, '0')}${(duration.inMinutes - (duration.inHours * 60)).toString().padLeft(2, '0')}");
    }
  }

  @override
  void initState() {
    super.initState();
    (widget.loginInfo.user.id == widget.room.relation2!.id)
        ? {
            opponentUser = widget.room.relation!,
            opponentTagset = widget.room.tag!,
          }
        : {
            opponentUser = widget.room.relation2!,
            opponentTagset = widget.room.tag2!,
          };
    globals.opponentUser = opponentUser;

    if (widget.room.reservationTime != null) {
      afterPromise = true;
      promiseDate = widget.room.reservationTime!.add(const Duration(hours: 9));
      print('약속 시간: $promiseDate');
      final twoHoursLater = promiseDate!.add(const Duration(hours: 2));
      print('약속 후 30초 뒤 시간: $twoHoursLater');
      print('현재 시간: ${DateTime.now().toUtc()}');
      var now = DateTime.now().toUtc().add(const Duration(hours: 9));
      //twoHoursLater가 현재 시간보다 이전이면 true를 반환해야함
      if (((twoHoursLater).toLocal()).isBefore(now)) {
        print('afterMeeting : true');
        afterMeeting = true;
      }
    } else {
      afterMeeting = false;
      afterPromise = false;
    }
    _loadMessages().then((value) => setState(() {}));
  }

  void _sendMessage() async {
    FocusScope.of(context).unfocus();
    // 서버에 채팅 메세지 전송 추가
    String apiAddress = dotenv.env['API_ADDRESS'] ?? '';
    final url = Uri.parse('$apiAddress/chat/message/');
    final token = widget.loginInfo.access;

    /*
    (23.11.25)
    _enteredMessage를 그대로 사용할 시,
    globals.messages.value를 업데이트 하는 것보다
    _controller.clear가 먼저 발생하여
    enteredMsg라는 변수에 value copy를 진행하는 것으로 문제 해결
    */
    final enteredMsg = _enteredMessage;

    String body = jsonEncode({
      "message": enteredMsg,
      "is_read": false,
      "type": 1,
      "args": null,
      "room": widget.room.id,
      "sender": widget.loginInfo.user.id,
      "receiver": opponentUser.id,
    });

    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      globals.messages.value.insert(
        0,
        Message(
          id: 0,
          sender: widget.loginInfo.user,
          receiver: opponentUser,
          created: "",
          modified: "",
          message: enteredMsg,
          isRead: true,
          type: 1,
          args: null,
          room: widget.room.id!,
        ),
      );
      globals.messages.value = List.from(globals.messages.value);
    });

    _controller.clear();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _enteredMessage = '';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: CustomAppBar(
            loginInfo: widget.loginInfo,
            title: opponentUser.nickname ?? "LINRING",
            suffix: PopupMenuButton<int>(
              onSelected: (int result) {
                if (result == 1) {
                  _showProfileModal(context);
                } else if (result == 2) {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReportScreen(
                              loginInfo: widget.loginInfo, room: widget.room)));
                } else if (result == 3) {
                  _showBlockModal(context);
                }
              },
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<int>>[
                  const PopupMenuItem<int>(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.add),
                        Text("프로필 확인하기"),
                      ],
                    ),
                  ),
                  const PopupMenuItem<int>(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        Text("신고하기"),
                      ],
                    ),
                  ),
                  const PopupMenuItem<int>(
                    value: 3,
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        Text("차단하기"),
                      ],
                    ),
                  ),
                ];
              },
              child: const Icon(
                Icons.more_vert,
                color: Colors.black,
              ),
            ),
          ),
        ),
        backgroundColor: const Color(0xfffff6f4),
        body: Column(
          children: [
            _matchInfo(),
            _chatContainer(),
            _chatInput(),
          ],
        ),
      ),
    );
  }

  // chat type 0
  Widget _chatEntry(Message message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xfffec2b5)),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(
              text: '알림',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: message.message,
            ),
          ],
        ),
      ),
    );
  }

  // chat type 1
  Widget _chatBubble(Message message, bool isMine) {
    return Container(
      decoration: BoxDecoration(
        color: isMine ? const Color(0xfff3c2b5) : Colors.white,
        border: Border.all(
          width: 2.0,
          color: const Color(0xfff3c2b5),
        ),
        borderRadius: isMine
            ? const BorderRadius.only(
                topLeft: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              )
            : const BorderRadius.only(
                topRight: Radius.circular(30),
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(message.message),
      ),
    );
  }

  // chat type 2
  Widget _timeChat(Message message) {
    DateTime datetime = DateTime.parse(message.args!);
    final promise = DateFormat('M월 d일 (E) H시 m분', 'ko_KR')
        .format(datetime.add(const Duration(hours: 9)));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xfffec2b5)),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Text.rich(
        TextSpan(
          children: <TextSpan>[
            const TextSpan(
              text: '알림',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' $promise로 약속 시간을 정했어요.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatContainer() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // 가상 키보드 unfocusing
          },
          child: Align(
            alignment: Alignment.topCenter,
            child: ValueListenableBuilder<List<Message>>(
              valueListenable: globals.messages,
              builder: (context, List<Message> messages, child) {
                return Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ListView.builder(
                          reverse: true,
                          shrinkWrap: true,
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, int index) {
                            final message = messages[index];
                            bool isMine =
                                message.sender.id == widget.loginInfo.user.id;

                            Widget chatWidget;

                            if (message.type == 0) {
                              chatWidget = Expanded(child: _chatEntry(message));
                            } else if (message.type == 1) {
                              chatWidget = _chatBubble(message, isMine);
                            } else if (message.type == 2 &&
                                message.args != null) {
                              chatWidget = Expanded(child: _timeChat(message));
                            } else {
                              chatWidget = Container();
                            }

                            return Container(
                              margin: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: isMine
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [chatWidget],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // 매칭 정보(태그 정보, 약속 시간 표시)
  Widget _matchInfo() {
    int? birth = opponentUser.birth;
    int? year = 2024 - birth!;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xffc8aaaa),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showProfileModal(context);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xffc8c8c8), width: 0.7)),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/characters/0${opponentUser.profile}.svg',
                          width: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "# ${opponentTagset.place}  # ${opponentTagset.person}  # ${opponentTagset.method}${opponentTagset.method == "카페" ? "가기" : "하기"}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15),
                      ),
                      Text(
                        "${opponentUser.department}  ${opponentUser.studentNumber}학번  $year살  ${opponentUser.gender}자",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(
                  indent: 10,
                  endIndent: 10,
                  thickness: 1,
                  color: Color(0xffc8aaaa),
                ),
                SizedBox(
                  width: 90,
                  child: TextButton(
                    style: ButtonStyle(
                      textStyle: MaterialStateProperty.all<TextStyle?>(
                        const TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      if (afterMeeting) {
                        _showRatingModal(context);
                      } else {
                        await showOmniDateTimePicker(
                          context: context,
                          initialDate: widget.room.reservationTime,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          is24HourMode: false,
                          isShowSeconds: false,
                          minutesInterval: 1,
                          secondsInterval: 1,
                          isForce2Digits: true,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ).then((selectedDate) {
                          if (selectedDate!
                              .difference(DateTime.now())
                              .isNegative) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                    title: const Text(
                                      '약속 시간 정하기 실패',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    content: const Text(
                                      '이미 지난 시간은 약속 시간으로 정할 수 없어요!',
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text(
                                          '확인',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        20,
                                      ),
                                    ));
                              },
                            );
                          } else {
                            promiseDate = selectedDate;
                            print('primiseDate를 selectedDate에 넣었음');
                            afterPromise = true;
                            widget.room.reservationTime = promiseDate!;
                            updateMatchInfo();

                            _patchReservationTime();

                            print('patch 호출 후 print');
                            print(promiseDate);
                          }
                        });
                      }
                    },
                    child: Text(
                      afterMeeting
                          ? "매너평가하기"
                          : afterPromise
                              ? "${promiseDate!.year}-${promiseDate!.month}-${promiseDate!.day}\n${promiseDate!.hour} : ${promiseDate!.minute}"
                              : "약속 시간\n 정하기",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  void updateMatchInfo() {
    setState(() {
      //_matchInfo 함수를 다시 호출해서 화면 갱신
    });
  }

  // bool _buttonIsActive() {
  //   if (ratingScore.isNotEmpty) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  // 채팅 입력창
  Widget _chatInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 60,
            margin: const EdgeInsets.all(30.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xffc8aaaa),
                style: BorderStyle.solid,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onTap: () {
                      //scrollAnimate();
                    },
                    controller: _controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 15),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _enteredMessage = value;
                      });
                    },
                  ),
                ),
                IconButton(
                  highlightColor: Colors.transparent, // 물결 효과 제거
                  splashColor: Colors.transparent, // 물결 효과 제거

                  onPressed: () {
                    _enteredMessage.trim().isEmpty ? null : _sendMessage();
                  },
                  icon: Image.asset(
                    "assets/icons/send_button.png",
                    width: 20,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget image(String asset) {
    return Image.asset(
      asset,
      height: 25,
      width: 25,
    );
  }

  final List<String> remark = [
    '유학생',
    '전과생',
    '편입생',
    '외국인',
    '교환학생',
    '복수전공생',
    '부전공생',
    '휴학생',
  ];
  String getStatesByNumbers(List<int> numbers) {
    List<String> selectedStates = numbers
        .where((number) => number >= 1 && number <= remark.length)
        .map((number) => remark[number - 1])
        .toList();

    return selectedStates.join(', ');
  }

  void _showRatingModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      builder: (BuildContext context) {
        return Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            height: 270,
            child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 20,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '${opponentUser.nickname}님과 잘 만나고 오셨나요?',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '알고리즘 성능 향상을 위해',
                        style: TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '매너평가를 남겨주세요!',
                        style: TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: CustomOutlinedButton(
                        label: '매너평가 남기기',
                        backgroundColor: const Color(0xFFFEC2B5),
                        isActive: true,
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                              context: context,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              builder: (BuildContext context) {
                                return Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 10, 10, 10),
                                    height: 330,
                                    child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                        ),
                                        child: Column(children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const SizedBox(
                                                width: 48,
                                                height: 20,
                                              ),
                                              Text(
                                                "${opponentUser.nickname}님과의 만남 매너 평가",
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 20,
                                          ),
                                          RatingBar(
                                            initialRating: 0,
                                            direction: Axis.horizontal,
                                            allowHalfRating: false,
                                            itemCount: 5,
                                            ratingWidget: RatingWidget(
                                              full: image(
                                                  'assets/images/fullStar.png'),
                                              half: image(
                                                  'assets/images/fullStar.png'),
                                              empty: image(
                                                  'assets/images/empty_Star.png'),
                                            ),
                                            itemPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4.0),
                                            onRatingUpdate: (rating) {
                                              setState(() {
                                                ratingScore =
                                                    (rating.toInt()).toString();
                                                // buttonIsActive =
                                                //     _buttonIsActive();
                                              });
                                            },
                                          ),
                                          const SizedBox(
                                            height: 25,
                                          ),
                                          const Text(
                                            '매너평가 별점을 남겨주세요.',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          const Text(
                                            '상대방은 점수를 알 수 없으니 안심하세요!',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                10, 0, 10, 0),
                                            child: CustomOutlinedButton(
                                              isActive: true,
                                              //buttonIsActive,
                                              backgroundColor:
                                                  const Color(0xFFFEC2B5),
                                              label: '매너평가 남기기',
                                              onPressed: () {
                                                _createRating();
                                                afterPromise = false;
                                                afterMeeting = false;
                                                widget.room.reservationTime =
                                                    null;
                                                promiseDate = null;
                                                _patchReservationTime();
                                              },
                                            ),
                                          )
                                        ])));
                              });
                        },
                      ),
                    )
                  ],
                )));
      },
    );
  }

  void _showProfileModal(BuildContext context) {
    debugPrint(opponentUser.profile.toString());
    int? birth = opponentUser.birth;
    int? year = 2024 - birth!;
    List<int>? selectedNumbers = opponentUser.significant;
    String selectedStatesString = getStatesByNumbers(selectedNumbers!);

    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          height: 300,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 20,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xffc8c8c8), width: 0.7)),
                          child: Center(
                            child: SvgPicture.asset(
                                'assets/images/characters/0${opponentUser.profile}.svg'),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: Text(
                              '${opponentUser.nickname}님',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                text: '${opponentUser.department} ',
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.black),
                              ),
                              TextSpan(
                                text: '${opponentUser.studentNumber}학번',
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.black),
                              ),
                            ])),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: RichText(
                                text: TextSpan(children: [
                              TextSpan(
                                text: '$year살 ',
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.black),
                              ),
                              TextSpan(
                                text: '${opponentUser.gender}자 ',
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.black),
                              ),
                              TextSpan(
                                text: selectedStatesString,
                                style: const TextStyle(
                                    fontSize: 17, color: Colors.black),
                              ),
                            ])),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Text(
                    '"${opponentTagset.introduction}"',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: CustomOutlinedButton(
                    isActive: true,
                    label: '프로필 닫기',
                    backgroundColor: const Color(0xFFFEC2B5),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _BlockUser() async {
    String apiAddress = dotenv.get("API_ADDRESS");
    final url = Uri.parse('$apiAddress/accounts/blockuser/update/');
    final token = widget.loginInfo.access;
    final body = jsonEncode(
        {"user": widget.loginInfo.user.id, "block_user": opponentUser.id});
    await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    // 사용자 차단 field 업데이트 이후에 User 정보 다시 불러오기
    final response = await http.get(
      Uri.parse('$apiAddress/accounts/v2/user/${widget.loginInfo.user.id}/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 불러온 사용자 정보 FlutterSecureStorage에 재할당
    const storage = FlutterSecureStorage();

    String jsonString = jsonEncode({
      "access": widget.loginInfo.access,
      "refresh": widget.loginInfo.refresh,
      "user": jsonDecode(response.body),
    });
    await storage.write(key: 'user', value: jsonString);
    String? res = await storage.read(key: 'user');
    final Map parsed = json.decode(utf8.decode(res!.codeUnits));

    print("==========parsed=======");
    print(parsed);
    print("==========parsed=======");

    final loginInfo = LoginInfo.fromJson(parsed);

    widget.loginInfo = loginInfo;

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MainScreen(widget.loginInfo, 1)));
  }

  void _showBlockModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      builder: (BuildContext context) {
        return Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            height: 270,
            child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          width: 48,
                          height: 20,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '${opponentUser.nickname}님을 차단하시겠어요?',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '${opponentUser.nickname}님과의 채팅방과 채팅내역은 삭제되고,',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        '더 이상 ${opponentUser.nickname}님과 매칭되지 않습니다.',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    const SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: CustomOutlinedButton(
                        label: '차단하기',
                        backgroundColor: const Color.fromARGB(255, 239, 97, 87),
                        isActive: true,
                        onPressed: () {
                          _BlockUser();
                        },
                      ),
                    )
                  ],
                )));
      },
    );
  }
}
