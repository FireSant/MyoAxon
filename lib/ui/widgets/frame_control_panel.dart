import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FrameControlPanel extends StatefulWidget {
  final double fps;
  final VideoPlayerController controller;
  final Function(int frame) onMarkStart;
  final Function(int frame) onMarkEnd;
  final bool isMarkingStart;

  const FrameControlPanel({
    super.key,
    required this.fps,
    required this.controller,
    required this.onMarkStart,
    required this.onMarkEnd,
    required this.isMarkingStart,
  });

  @override
  State<FrameControlPanel> createState() => _FrameControlPanelState();
}

class _FrameControlPanelState extends State<FrameControlPanel> {
  void _step(int delta) {
    final currentPos = widget.controller.value.position;
    final frameTimeMs = 1000 / widget.fps;
    final newPosMs = currentPos.inMilliseconds + (delta * frameTimeMs);
    
    widget.controller.seekTo(Duration(milliseconds: newPosMs.toInt()));
  }

  int _getCurrentFrame() {
    final currentPosMs = widget.controller.value.position.inMilliseconds;
    return (currentPosMs * widget.fps / 1000).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navButton(label: '-10', delta: -10),
              const SizedBox(width: 8),
              _navButton(label: '-1', delta: -1),
              const SizedBox(width: 12),
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                radius: 24,
                child: IconButton(
                  icon: Icon(
                    widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      widget.controller.value.isPlaying
                          ? widget.controller.pause()
                          : widget.controller.play();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              _navButton(label: '+1', delta: 1),
              const SizedBox(width: 8),
              _navButton(label: '+10', delta: 10),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final frame = _getCurrentFrame();
                if (widget.isMarkingStart) {
                  widget.onMarkStart(frame);
                } else {
                  widget.onMarkEnd(frame);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isMarkingStart ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                widget.isMarkingStart ? 'MARCAR INICIO' : 'MARCAR FIN',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({required String label, required int delta}) {
    return SizedBox(
      width: 50,
      child: OutlinedButton(
        onPressed: () => _step(delta),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
