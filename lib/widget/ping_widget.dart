import 'package:dart_ping/dart_ping.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PingWidget extends StatefulWidget {
  final Widget? child;
  const PingWidget({super.key, this.child});

  @override
  State<PingWidget> createState() => _PingWidgetState();
}

class _PingWidgetState extends State<PingWidget> {
  bool poor = false;
  int ms = 0;

  @override
  void initState() {
    final ping = Ping('google.com', count: 100000000000);
    ping.stream.listen((event) {
      if(mounted){
        setState(() {
          ms = event.response?.time?.inMilliseconds ?? 0;
          poor = ms > 100 || ms == 0;
        });
      } else {
        ping.stop();
      }
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      duration: const Duration(milliseconds: 1000), child: buildBody(),);
  }

  Widget buildBody(){
    // if(poor){
    //   return widget.child ?? Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Text('Poor Connection', style: TextStyle(color: context.onSurface?.withOpacity(0.75), fontWeight: FontWeight.w700),)
    //     ],
    //   );
    // }
    return Text('$ms MS',
      key: ValueKey('MS$ms'),
      style: TextStyle(
          color: ms.color, fontWeight: FontWeight.w800, fontSize: 12),);
    if(kDebugMode) {

    }
    // return Container(
    //   key: ValueKey(ms.color),
    //
    //   width: 8,
    //   height: 8,
    //   decoration: BoxDecoration(
    //     shape: BoxShape.circle,
    //     color: ms.color,
    //   ),
    // );
    return const SizedBox.shrink();
  }
}

extension ColorExtension on int {
  Color? get color {
    if(this <= 20){
      return Colors.green.shade800;
    }
    if(this > 20 && this <= 60){
      return Colors.orange.shade800;
    }
    if(this > 60){
      return Colors.red.shade800;
    }
    return null;
  }
}
