// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

enum ShareIntentAttachmentType { image, video }

enum UploadStatus { enqueued, running, complete, failed, canceled, paused, notFound, waitingToRetry }

class ShareIntentAttachment {
  final int id;
  final String path;
  final ShareIntentAttachmentType type;
  final UploadStatus status;
  final double uploadProgress;
  final int fileLength;

  ShareIntentAttachment({
    required this.path,
    required this.type,
    required this.status,
    required this.uploadProgress,
    required this.fileLength,
  }) : id = path.hashCode;

  File get file => File(path);

  bool get isImage => type == ShareIntentAttachmentType.image;

  bool get isVideo => type == ShareIntentAttachmentType.video;

  String get fileName => p.basename(path);

  String get fileSize {
    const units = ['B', 'KB', 'MB', 'GB'];
    var size = fileLength.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unitIndex]}';
  }

  ShareIntentAttachment copyWith({
    String? path,
    ShareIntentAttachmentType? type,
    UploadStatus? status,
    double? uploadProgress,
    int? fileLength,
  }) {
    return ShareIntentAttachment(
      path: path ?? this.path,
      type: type ?? this.type,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      fileLength: fileLength ?? this.fileLength,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'type': type.index,
      'status': status.index,
      'uploadProgress': uploadProgress,
      'fileLength': fileLength,
    };
  }

  factory ShareIntentAttachment.fromMap(Map<String, dynamic> map) {
    return ShareIntentAttachment(
      path: map['path'] as String,
      type: ShareIntentAttachmentType.values[map['type'] as int],
      status: UploadStatus.values[map['status'] as int],
      uploadProgress: map['uploadProgress'] as double,
      fileLength: map['fileLength'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory ShareIntentAttachment.fromJson(String source) =>
      ShareIntentAttachment.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ShareIntentAttachment(id: $id, path: $path, type: $type, status: $status, uploadProgress: $uploadProgress, fileLength: $fileLength)';
  }

  @override
  bool operator ==(covariant ShareIntentAttachment other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.path == path &&
        other.type == type &&
        other.status == status &&
        other.uploadProgress == uploadProgress &&
        other.fileLength == fileLength;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        path.hashCode ^
        type.hashCode ^
        status.hashCode ^
        uploadProgress.hashCode ^
        fileLength.hashCode;
  }
}
