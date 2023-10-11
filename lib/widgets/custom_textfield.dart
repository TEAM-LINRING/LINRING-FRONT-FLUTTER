import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final bool obscureText;
  final Text? suffixText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPressed;
  final String? errorText;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    required this.obscureText,
    decoration,
    this.suffixText,
    this.onChanged,
    this.errorText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(30, 5, 30, 5),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
                controller: controller,
                obscureText: obscureText,
                onChanged: onChanged,
                decoration: InputDecoration(
                  errorText: errorText,
                  errorBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(width: 1, color: Color(0xFFC8AAAA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(width: 1, color: Color(0xFFC8AAAA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorStyle: const TextStyle(
                    height: 0,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(20, 40, 0, 0),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(width: 1, color: Color(0xFFC8AAAA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(width: 1, color: Color(0xFFC8AAAA)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: hintText,
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 70.0),
                    child: Align(
                      alignment: Alignment.center,
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      child: suffixText,
                    ),
                  ),
                )),
            if (errorText != null)
              Positioned(
                bottom: -30,
                left: 20,
                child: Text(
                  errorText!,
                  style: const TextStyle(color: Colors.red, height: 0),
                ),
              ),
            if (controller != null)
              Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                width: 1, color: Color(0xFFC8AAAA)))),
                    child: OutlinedButton(
                        onPressed: () {
                          //중복확인 로직으로 변경 필요
                          controller!.clear();
                        },
                        style: OutlinedButton.styleFrom(
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 20)),
                        child: const Text(
                          '중복 확인',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 0),
                        )),
                  )),
          ],
        ));
  }
}
