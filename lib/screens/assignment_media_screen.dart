import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class MediaPickerPanel extends StatefulWidget {
  final ValueChanged<List<String>> onChanged;
  const MediaPickerPanel({super.key, required this.onChanged});
  @override State<MediaPickerPanel> createState() => _MediaPickerPanelState();
}

class _MediaPickerPanelState extends State<MediaPickerPanel> {
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();
  final List<String> _files = [];
  bool _recording = false;

  void _notify() => widget.onChanged(List<String>.from(_files));

  Future<void> pickImages() async {
    final images = await _picker.pickMultiImage(imageQuality: 88);
    for (final x in images) { if (!_files.contains(x.path)) _files.add(x.path); }
    setState(() {}); _notify();
  }

  Future<void> pickVideo() async {
    final x = await _picker.pickVideo(source: ImageSource.gallery);
    if (x != null) { _files.add(x.path); setState(() {}); _notify(); }
  }

  Future<void> toggleVoice() async {
    if (_recording) {
      final path = await _recorder.stop();
      if (path != null) _files.add(path);
      setState(() => _recording = false); _notify();
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اجازه استفاده از میکروفون داده نشد')));
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/nexa_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _recording = true);
  }

  @override void dispose() { _recorder.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Wrap(spacing: 8, runSpacing: 8, children: [
      OutlinedButton.icon(onPressed: pickImages, icon: const Icon(Icons.photo_library_outlined), label: const Text('عکس')),
      OutlinedButton.icon(onPressed: pickVideo, icon: const Icon(Icons.video_library_outlined), label: const Text('فیلم')),
      OutlinedButton.icon(onPressed: toggleVoice, icon: Icon(_recording ? Icons.stop_circle_outlined : Icons.mic_none_rounded), label: Text(_recording ? 'پایان ویس' : 'ویس')),
    ]),
    if (_files.isNotEmpty) ...[
      const SizedBox(height: 8),
      ..._files.asMap().entries.map((e) => ListTile(dense: true, leading: const Icon(Icons.attach_file), title: Text(e.value.split(RegExp(r'[\\/]')).last, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () { _files.removeAt(e.key); setState(() {}); _notify(); })) ),
    ],
  ]);
}

class AssignmentMediaList extends StatelessWidget {
  final List attachments;
  final int attemptNumber;
  final ValueChanged<dynamic>? onDelete;
  const AssignmentMediaList({super.key, required this.attachments, this.attemptNumber = 1, this.onDelete});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: attachments.map<Widget>((a) => FutureBuilder<String>(
    future: ApiService.mediaUrl(a['file_path'] ?? ''),
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox(height: 20, child: LinearProgressIndicator());
      final url = snap.data!; final type = a['media_type'];
      if (type == 'image') return Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(url, height: 190, fit: BoxFit.cover))), if (onDelete != null) IconButton(tooltip: 'حذف و نگه‌داری در بایگانی', icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => onDelete!(a))]));
      return Row(children: [Expanded(child: ListTile(leading: Icon(type == 'video' ? Icons.play_circle_fill : type == 'audio' ? Icons.mic : Icons.attach_file), title: Text(type == 'video' ? 'مشاهده فیلم' : type == 'audio' ? 'پخش ویس${attemptNumber > 1 ? ' (${attemptNumber - 1})' : ''}' : 'باز کردن فایل'), onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication))), if (onDelete != null) IconButton(tooltip: 'حذف و نگه‌داری در بایگانی', icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => onDelete!(a))]);
    },
  )).toList());
}
