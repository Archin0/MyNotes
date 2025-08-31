import 'package:flutter/material.dart';

class PinPage extends StatefulWidget {
  final Function(bool)? onPinEntered;

  const PinPage({super.key, this.onPinEntered});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> with TickerProviderStateMixin {
  String _enteredPin = '';
  final String _correctPin = '123456';
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
      });

      if (_enteredPin.length == 6) {
        _checkPin();
      }
    }
  }

  void _checkPin() {
    if (_enteredPin == _correctPin) {
      if (widget.onPinEntered != null) {
        widget.onPinEntered!(true);
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      _shakeAnimation();
      setState(() {
        _enteredPin = '';
      });
    }
  }

  void _shakeAnimation() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Widget _buildPinDot(bool filled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.purple : Colors.transparent,
        border: Border.all(color: Colors.purple, width: 2),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () => _onNumberPressed(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.purple),
              const SizedBox(height: 30),
              const Text(
                'Masukkan PIN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PIN Default: 123456',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final offset = _shakeController.value * 10;
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.status == AnimationStatus.forward
                          ? offset
                          : -offset,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        6,
                        (index) => _buildPinDot(index < _enteredPin.length),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              // Number pad
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 70), // Empty space
                      _buildNumberButton('0'),
                      GestureDetector(
                        onTap: _onDeletePressed,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.backspace_outlined,
                              color: Colors.black87,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
