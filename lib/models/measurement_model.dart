import 'dart:convert';

class MeasurementModel {
  final String? lengthMeasure;
  final String? armMeasure;
  final bool optMundo;
  final String? mundoMeasure;
  final String? shoulderMeasure;
  final String? collarMeasure;
  final bool colRegular;
  final bool colFrench;
  final bool colSherwani;
  final String sherwaniType;
  final String? chestMeasure;
  final String? waistMeasure;
  final String? hipMeasure;
  final String? shalwarMeasure;
  final bool shalKanto;
  final bool shalZipPocket;
  final bool shalWidth;
  final String? bottomMeasure;
  final String? plateMeasure;
  final bool optFrontPocket;
  final String? frontPocketMeasure;
  final bool optSidePocket;
  final String cuffType;
  final String? cuffMeasure;
  final String? extraNotes;

  MeasurementModel({
    this.lengthMeasure,
    this.armMeasure,
    this.optMundo = false,
    this.mundoMeasure,
    this.shoulderMeasure,
    this.collarMeasure,
    this.colRegular = false,
    this.colFrench = false,
    this.colSherwani = false,
    this.sherwaniType = 'Half',
    this.chestMeasure,
    this.waistMeasure,
    this.hipMeasure,
    this.shalwarMeasure,
    this.shalKanto = false,
    this.shalZipPocket = false,
    this.shalWidth = false,
    this.bottomMeasure,
    this.plateMeasure,
    this.optFrontPocket = false,
    this.frontPocketMeasure,
    this.optSidePocket = false,
    this.cuffType = 'Round',
    this.cuffMeasure,
    this.extraNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'lengthMeasure': lengthMeasure,
      'armMeasure': armMeasure,
      'optMundo': optMundo,
      'mundoMeasure': mundoMeasure,
      'shoulderMeasure': shoulderMeasure,
      'collarMeasure': collarMeasure,
      'colRegular': colRegular,
      'colFrench': colFrench,
      'colSherwani': colSherwani,
      'sherwaniType': sherwaniType,
      'chestMeasure': chestMeasure,
      'waistMeasure': waistMeasure,
      'hipMeasure': hipMeasure,
      'shalwarMeasure': shalwarMeasure,
      'shalKanto': shalKanto,
      'shalZipPocket': shalZipPocket,
      'shalWidth': shalWidth,
      'bottomMeasure': bottomMeasure,
      'plateMeasure': plateMeasure,
      'optFrontPocket': optFrontPocket,
      'frontPocketMeasure': frontPocketMeasure,
      'optSidePocket': optSidePocket,
      'cuffType': cuffType,
      'cuffMeasure': cuffMeasure,
      'extraNotes': extraNotes,
    };
  }

  factory MeasurementModel.fromMap(Map<String, dynamic> map) {
    return MeasurementModel(
      lengthMeasure: map['lengthMeasure'],
      armMeasure: map['armMeasure'],
      optMundo: map['optMundo'] ?? false,
      mundoMeasure: map['mundoMeasure'],
      shoulderMeasure: map['shoulderMeasure'],
      collarMeasure: map['collarMeasure'],
      colRegular: map['colRegular'] ?? false,
      colFrench: map['colFrench'] ?? false,
      colSherwani: map['colSherwani'] ?? false,
      sherwaniType: map['sherwaniType'] ?? 'Half',
      chestMeasure: map['chestMeasure'],
      waistMeasure: map['waistMeasure'],
      hipMeasure: map['hipMeasure'],
      shalwarMeasure: map['shalwarMeasure'],
      shalKanto: map['shalKanto'] ?? false,
      shalZipPocket: map['shalZipPocket'] ?? false,
      shalWidth: map['shalWidth'] ?? false,
      bottomMeasure: map['bottomMeasure'],
      plateMeasure: map['plateMeasure'],
      optFrontPocket: map['optFrontPocket'] ?? false,
      frontPocketMeasure: map['frontPocketMeasure'],
      optSidePocket: map['optSidePocket'] ?? false,
      cuffType: map['cuffType'] ?? 'Round',
      cuffMeasure: map['cuffMeasure'],
      extraNotes: map['extraNotes'],
    );
  }

  String toJson() => json.encode(toMap());

  List<String> get designOptions {
    List<String> options = [];
    if (optMundo) options.add('Mundo');
    if (mundoMeasure != null && mundoMeasure!.isNotEmpty) options.add('Mundo: $mundoMeasure');
    if (colRegular) options.add('Regular Collar');
    if (colFrench) options.add('French Collar');
    if (colSherwani) options.add('Sherwani Collar ($sherwaniType)');
    if (shalKanto) options.add('Shalwar Kanto');
    if (shalZipPocket) options.add('Shalwar Zip Pocket');
    if (shalWidth) options.add('Shalwar Width');
    if (optFrontPocket) options.add('Front Pocket');
    if (optSidePocket) options.add('Side Pocket');
    options.add('Cuff: $cuffType${cuffMeasure != null && cuffMeasure!.isNotEmpty ? " ($cuffMeasure)" : ""}');
    return options;
  }

  factory MeasurementModel.fromJson(String source) =>
      MeasurementModel.fromMap(json.decode(source));
}
