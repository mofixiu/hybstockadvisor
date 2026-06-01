// ignore_for_file: use_super_parameters, prefer_const_constructors, must_be_immutable, prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? ontap;
  final String data;
  final Color textcolor, backgroundcolor;
  final double width, height;
  final bool isLoading;

  CustomButton({
    Key? key,
    required this.ontap,
    required this.data,
    required this.textcolor,
    required this.backgroundcolor,
    required this.width,
    required this.height,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = ontap == null || isLoading;
    return InkWell(
      onTap: isLoading ? null : ontap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isDisabled ? backgroundcolor.withOpacity(0.6) : backgroundcolor,  
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(textcolor),
                ),
              )
            : Text(
                textAlign: TextAlign.center,
                data,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: textcolor,
                ),
              ),
      ),
    );
  }
}