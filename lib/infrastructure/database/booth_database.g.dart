// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booth_database.dart';

// ignore_for_file: type=lint
class BoothProfiles extends Table
    with TableInfo<BoothProfiles, BoothProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BoothProfiles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(name)) BETWEEN 1 AND 40)',
  );
  late final GeneratedColumnWithTypeConverter<PorcelainThemeProfile, String>
  themeProfile = GeneratedColumn<String>(
    'theme_profile',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (theme_profile IN (\'porcelainStudio\', \'lightOak\', \'darkroomWalnut\'))',
  ).withConverter<PorcelainThemeProfile>(BoothProfiles.$converterthemeProfile);
  late final GeneratedColumnWithTypeConverter<ContrastPreference, String>
  contrastPreference =
      GeneratedColumn<String>(
        'contrast_preference',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (contrast_preference IN (\'system\', \'standard\', \'high\'))',
      ).withConverter<ContrastPreference>(
        BoothProfiles.$convertercontrastPreference,
      );
  late final GeneratedColumnWithTypeConverter<MotionPreference, String>
  motionPreference = GeneratedColumn<String>(
    'motion_preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (motion_preference IN (\'system\', \'reduced\'))',
  ).withConverter<MotionPreference>(BoothProfiles.$convertermotionPreference);
  late final GeneratedColumnWithTypeConverter<CameraLens, String>
  defaultLens = GeneratedColumn<String>(
    'default_lens',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (default_lens IN (\'front\', \'back\', \'external\'))',
  ).withConverter<CameraLens>(BoothProfiles.$converterdefaultLens);
  static const VerificationMeta _defaultMirrorPreviewMeta =
      const VerificationMeta('defaultMirrorPreview');
  late final GeneratedColumn<bool> defaultMirrorPreview = GeneratedColumn<bool>(
    'default_mirror_preview',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (default_mirror_preview IN (0, 1))',
  );
  static const VerificationMeta _defaultMirrorOutputMeta =
      const VerificationMeta('defaultMirrorOutput');
  late final GeneratedColumn<bool> defaultMirrorOutput = GeneratedColumn<bool>(
    'default_mirror_output',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (default_mirror_output IN (0, 1))',
  );
  late final GeneratedColumnWithTypeConverter<
    GuestOrientationPreference,
    String
  >
  defaultOrientation =
      GeneratedColumn<String>(
        'default_orientation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (default_orientation IN (\'portrait\', \'landscape\'))',
      ).withConverter<GuestOrientationPreference>(
        BoothProfiles.$converterdefaultOrientation,
      );
  late final GeneratedColumnWithTypeConverter<OutputFormat, String>
  defaultOutputFormat = GeneratedColumn<String>(
    'default_output_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (default_output_format IN (\'jpeg\', \'png\'))',
  ).withConverter<OutputFormat>(BoothProfiles.$converterdefaultOutputFormat);
  static const VerificationMeta _defaultJpegQualityMeta =
      const VerificationMeta('defaultJpegQuality');
  late final GeneratedColumn<int> defaultJpegQuality = GeneratedColumn<int>(
    'default_jpeg_quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (default_jpeg_quality BETWEEN 80 AND 100)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    themeProfile,
    contrastPreference,
    motionPreference,
    defaultLens,
    defaultMirrorPreview,
    defaultMirrorOutput,
    defaultOrientation,
    defaultOutputFormat,
    defaultJpegQuality,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'booth_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoothProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_mirror_preview')) {
      context.handle(
        _defaultMirrorPreviewMeta,
        defaultMirrorPreview.isAcceptableOrUnknown(
          data['default_mirror_preview']!,
          _defaultMirrorPreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultMirrorPreviewMeta);
    }
    if (data.containsKey('default_mirror_output')) {
      context.handle(
        _defaultMirrorOutputMeta,
        defaultMirrorOutput.isAcceptableOrUnknown(
          data['default_mirror_output']!,
          _defaultMirrorOutputMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultMirrorOutputMeta);
    }
    if (data.containsKey('default_jpeg_quality')) {
      context.handle(
        _defaultJpegQualityMeta,
        defaultJpegQuality.isAcceptableOrUnknown(
          data['default_jpeg_quality']!,
          _defaultJpegQualityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultJpegQualityMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoothProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoothProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      themeProfile: BoothProfiles.$converterthemeProfile.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_profile'],
        )!,
      ),
      contrastPreference: BoothProfiles.$convertercontrastPreference.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}contrast_preference'],
        )!,
      ),
      motionPreference: BoothProfiles.$convertermotionPreference.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}motion_preference'],
        )!,
      ),
      defaultLens: BoothProfiles.$converterdefaultLens.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}default_lens'],
        )!,
      ),
      defaultMirrorPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}default_mirror_preview'],
      )!,
      defaultMirrorOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}default_mirror_output'],
      )!,
      defaultOrientation: BoothProfiles.$converterdefaultOrientation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}default_orientation'],
        )!,
      ),
      defaultOutputFormat: BoothProfiles.$converterdefaultOutputFormat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}default_output_format'],
        )!,
      ),
      defaultJpegQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_jpeg_quality'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  BoothProfiles createAlias(String alias) {
    return BoothProfiles(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PorcelainThemeProfile, String, String>
  $converterthemeProfile = themeProfileByName;
  static JsonTypeConverter2<ContrastPreference, String, String>
  $convertercontrastPreference = const EnumNameConverter<ContrastPreference>(
    ContrastPreference.values,
  );
  static JsonTypeConverter2<MotionPreference, String, String>
  $convertermotionPreference = const EnumNameConverter<MotionPreference>(
    MotionPreference.values,
  );
  static JsonTypeConverter2<CameraLens, String, String> $converterdefaultLens =
      const EnumNameConverter<CameraLens>(CameraLens.values);
  static JsonTypeConverter2<GuestOrientationPreference, String, String>
  $converterdefaultOrientation =
      const EnumNameConverter<GuestOrientationPreference>(
        GuestOrientationPreference.values,
      );
  static JsonTypeConverter2<OutputFormat, String, String>
  $converterdefaultOutputFormat = const EnumNameConverter<OutputFormat>(
    OutputFormat.values,
  );
  @override
  bool get dontWriteConstraints => true;
}

class BoothProfileRow extends DataClass implements Insertable<BoothProfileRow> {
  final String id;
  final String name;

  /// Mapped explicitly: SQLite reads any type name containing "INT" (as in
  /// "PorcelainThemeProfile") as an integer, so ENUMNAME would store indexes.
  final PorcelainThemeProfile themeProfile;
  final ContrastPreference contrastPreference;
  final MotionPreference motionPreference;
  final CameraLens defaultLens;
  final bool defaultMirrorPreview;
  final bool defaultMirrorOutput;
  final GuestOrientationPreference defaultOrientation;
  final OutputFormat defaultOutputFormat;
  final int defaultJpegQuality;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BoothProfileRow({
    required this.id,
    required this.name,
    required this.themeProfile,
    required this.contrastPreference,
    required this.motionPreference,
    required this.defaultLens,
    required this.defaultMirrorPreview,
    required this.defaultMirrorOutput,
    required this.defaultOrientation,
    required this.defaultOutputFormat,
    required this.defaultJpegQuality,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['theme_profile'] = Variable<String>(
        BoothProfiles.$converterthemeProfile.toSql(themeProfile),
      );
    }
    {
      map['contrast_preference'] = Variable<String>(
        BoothProfiles.$convertercontrastPreference.toSql(contrastPreference),
      );
    }
    {
      map['motion_preference'] = Variable<String>(
        BoothProfiles.$convertermotionPreference.toSql(motionPreference),
      );
    }
    {
      map['default_lens'] = Variable<String>(
        BoothProfiles.$converterdefaultLens.toSql(defaultLens),
      );
    }
    map['default_mirror_preview'] = Variable<bool>(defaultMirrorPreview);
    map['default_mirror_output'] = Variable<bool>(defaultMirrorOutput);
    {
      map['default_orientation'] = Variable<String>(
        BoothProfiles.$converterdefaultOrientation.toSql(defaultOrientation),
      );
    }
    {
      map['default_output_format'] = Variable<String>(
        BoothProfiles.$converterdefaultOutputFormat.toSql(defaultOutputFormat),
      );
    }
    map['default_jpeg_quality'] = Variable<int>(defaultJpegQuality);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BoothProfilesCompanion toCompanion(bool nullToAbsent) {
    return BoothProfilesCompanion(
      id: Value(id),
      name: Value(name),
      themeProfile: Value(themeProfile),
      contrastPreference: Value(contrastPreference),
      motionPreference: Value(motionPreference),
      defaultLens: Value(defaultLens),
      defaultMirrorPreview: Value(defaultMirrorPreview),
      defaultMirrorOutput: Value(defaultMirrorOutput),
      defaultOrientation: Value(defaultOrientation),
      defaultOutputFormat: Value(defaultOutputFormat),
      defaultJpegQuality: Value(defaultJpegQuality),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BoothProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoothProfileRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      themeProfile: BoothProfiles.$converterthemeProfile.fromJson(
        serializer.fromJson<String>(json['theme_profile']),
      ),
      contrastPreference: BoothProfiles.$convertercontrastPreference.fromJson(
        serializer.fromJson<String>(json['contrast_preference']),
      ),
      motionPreference: BoothProfiles.$convertermotionPreference.fromJson(
        serializer.fromJson<String>(json['motion_preference']),
      ),
      defaultLens: BoothProfiles.$converterdefaultLens.fromJson(
        serializer.fromJson<String>(json['default_lens']),
      ),
      defaultMirrorPreview: serializer.fromJson<bool>(
        json['default_mirror_preview'],
      ),
      defaultMirrorOutput: serializer.fromJson<bool>(
        json['default_mirror_output'],
      ),
      defaultOrientation: BoothProfiles.$converterdefaultOrientation.fromJson(
        serializer.fromJson<String>(json['default_orientation']),
      ),
      defaultOutputFormat: BoothProfiles.$converterdefaultOutputFormat.fromJson(
        serializer.fromJson<String>(json['default_output_format']),
      ),
      defaultJpegQuality: serializer.fromJson<int>(
        json['default_jpeg_quality'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'theme_profile': serializer.toJson<String>(
        BoothProfiles.$converterthemeProfile.toJson(themeProfile),
      ),
      'contrast_preference': serializer.toJson<String>(
        BoothProfiles.$convertercontrastPreference.toJson(contrastPreference),
      ),
      'motion_preference': serializer.toJson<String>(
        BoothProfiles.$convertermotionPreference.toJson(motionPreference),
      ),
      'default_lens': serializer.toJson<String>(
        BoothProfiles.$converterdefaultLens.toJson(defaultLens),
      ),
      'default_mirror_preview': serializer.toJson<bool>(defaultMirrorPreview),
      'default_mirror_output': serializer.toJson<bool>(defaultMirrorOutput),
      'default_orientation': serializer.toJson<String>(
        BoothProfiles.$converterdefaultOrientation.toJson(defaultOrientation),
      ),
      'default_output_format': serializer.toJson<String>(
        BoothProfiles.$converterdefaultOutputFormat.toJson(defaultOutputFormat),
      ),
      'default_jpeg_quality': serializer.toJson<int>(defaultJpegQuality),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BoothProfileRow copyWith({
    String? id,
    String? name,
    PorcelainThemeProfile? themeProfile,
    ContrastPreference? contrastPreference,
    MotionPreference? motionPreference,
    CameraLens? defaultLens,
    bool? defaultMirrorPreview,
    bool? defaultMirrorOutput,
    GuestOrientationPreference? defaultOrientation,
    OutputFormat? defaultOutputFormat,
    int? defaultJpegQuality,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BoothProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    themeProfile: themeProfile ?? this.themeProfile,
    contrastPreference: contrastPreference ?? this.contrastPreference,
    motionPreference: motionPreference ?? this.motionPreference,
    defaultLens: defaultLens ?? this.defaultLens,
    defaultMirrorPreview: defaultMirrorPreview ?? this.defaultMirrorPreview,
    defaultMirrorOutput: defaultMirrorOutput ?? this.defaultMirrorOutput,
    defaultOrientation: defaultOrientation ?? this.defaultOrientation,
    defaultOutputFormat: defaultOutputFormat ?? this.defaultOutputFormat,
    defaultJpegQuality: defaultJpegQuality ?? this.defaultJpegQuality,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BoothProfileRow copyWithCompanion(BoothProfilesCompanion data) {
    return BoothProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      themeProfile: data.themeProfile.present
          ? data.themeProfile.value
          : this.themeProfile,
      contrastPreference: data.contrastPreference.present
          ? data.contrastPreference.value
          : this.contrastPreference,
      motionPreference: data.motionPreference.present
          ? data.motionPreference.value
          : this.motionPreference,
      defaultLens: data.defaultLens.present
          ? data.defaultLens.value
          : this.defaultLens,
      defaultMirrorPreview: data.defaultMirrorPreview.present
          ? data.defaultMirrorPreview.value
          : this.defaultMirrorPreview,
      defaultMirrorOutput: data.defaultMirrorOutput.present
          ? data.defaultMirrorOutput.value
          : this.defaultMirrorOutput,
      defaultOrientation: data.defaultOrientation.present
          ? data.defaultOrientation.value
          : this.defaultOrientation,
      defaultOutputFormat: data.defaultOutputFormat.present
          ? data.defaultOutputFormat.value
          : this.defaultOutputFormat,
      defaultJpegQuality: data.defaultJpegQuality.present
          ? data.defaultJpegQuality.value
          : this.defaultJpegQuality,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoothProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('themeProfile: $themeProfile, ')
          ..write('contrastPreference: $contrastPreference, ')
          ..write('motionPreference: $motionPreference, ')
          ..write('defaultLens: $defaultLens, ')
          ..write('defaultMirrorPreview: $defaultMirrorPreview, ')
          ..write('defaultMirrorOutput: $defaultMirrorOutput, ')
          ..write('defaultOrientation: $defaultOrientation, ')
          ..write('defaultOutputFormat: $defaultOutputFormat, ')
          ..write('defaultJpegQuality: $defaultJpegQuality, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    themeProfile,
    contrastPreference,
    motionPreference,
    defaultLens,
    defaultMirrorPreview,
    defaultMirrorOutput,
    defaultOrientation,
    defaultOutputFormat,
    defaultJpegQuality,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoothProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.themeProfile == this.themeProfile &&
          other.contrastPreference == this.contrastPreference &&
          other.motionPreference == this.motionPreference &&
          other.defaultLens == this.defaultLens &&
          other.defaultMirrorPreview == this.defaultMirrorPreview &&
          other.defaultMirrorOutput == this.defaultMirrorOutput &&
          other.defaultOrientation == this.defaultOrientation &&
          other.defaultOutputFormat == this.defaultOutputFormat &&
          other.defaultJpegQuality == this.defaultJpegQuality &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BoothProfilesCompanion extends UpdateCompanion<BoothProfileRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<PorcelainThemeProfile> themeProfile;
  final Value<ContrastPreference> contrastPreference;
  final Value<MotionPreference> motionPreference;
  final Value<CameraLens> defaultLens;
  final Value<bool> defaultMirrorPreview;
  final Value<bool> defaultMirrorOutput;
  final Value<GuestOrientationPreference> defaultOrientation;
  final Value<OutputFormat> defaultOutputFormat;
  final Value<int> defaultJpegQuality;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BoothProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.themeProfile = const Value.absent(),
    this.contrastPreference = const Value.absent(),
    this.motionPreference = const Value.absent(),
    this.defaultLens = const Value.absent(),
    this.defaultMirrorPreview = const Value.absent(),
    this.defaultMirrorOutput = const Value.absent(),
    this.defaultOrientation = const Value.absent(),
    this.defaultOutputFormat = const Value.absent(),
    this.defaultJpegQuality = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoothProfilesCompanion.insert({
    required String id,
    required String name,
    required PorcelainThemeProfile themeProfile,
    required ContrastPreference contrastPreference,
    required MotionPreference motionPreference,
    required CameraLens defaultLens,
    required bool defaultMirrorPreview,
    required bool defaultMirrorOutput,
    required GuestOrientationPreference defaultOrientation,
    required OutputFormat defaultOutputFormat,
    required int defaultJpegQuality,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       themeProfile = Value(themeProfile),
       contrastPreference = Value(contrastPreference),
       motionPreference = Value(motionPreference),
       defaultLens = Value(defaultLens),
       defaultMirrorPreview = Value(defaultMirrorPreview),
       defaultMirrorOutput = Value(defaultMirrorOutput),
       defaultOrientation = Value(defaultOrientation),
       defaultOutputFormat = Value(defaultOutputFormat),
       defaultJpegQuality = Value(defaultJpegQuality),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BoothProfileRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? themeProfile,
    Expression<String>? contrastPreference,
    Expression<String>? motionPreference,
    Expression<String>? defaultLens,
    Expression<bool>? defaultMirrorPreview,
    Expression<bool>? defaultMirrorOutput,
    Expression<String>? defaultOrientation,
    Expression<String>? defaultOutputFormat,
    Expression<int>? defaultJpegQuality,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (themeProfile != null) 'theme_profile': themeProfile,
      if (contrastPreference != null) 'contrast_preference': contrastPreference,
      if (motionPreference != null) 'motion_preference': motionPreference,
      if (defaultLens != null) 'default_lens': defaultLens,
      if (defaultMirrorPreview != null)
        'default_mirror_preview': defaultMirrorPreview,
      if (defaultMirrorOutput != null)
        'default_mirror_output': defaultMirrorOutput,
      if (defaultOrientation != null) 'default_orientation': defaultOrientation,
      if (defaultOutputFormat != null)
        'default_output_format': defaultOutputFormat,
      if (defaultJpegQuality != null)
        'default_jpeg_quality': defaultJpegQuality,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoothProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<PorcelainThemeProfile>? themeProfile,
    Value<ContrastPreference>? contrastPreference,
    Value<MotionPreference>? motionPreference,
    Value<CameraLens>? defaultLens,
    Value<bool>? defaultMirrorPreview,
    Value<bool>? defaultMirrorOutput,
    Value<GuestOrientationPreference>? defaultOrientation,
    Value<OutputFormat>? defaultOutputFormat,
    Value<int>? defaultJpegQuality,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BoothProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      themeProfile: themeProfile ?? this.themeProfile,
      contrastPreference: contrastPreference ?? this.contrastPreference,
      motionPreference: motionPreference ?? this.motionPreference,
      defaultLens: defaultLens ?? this.defaultLens,
      defaultMirrorPreview: defaultMirrorPreview ?? this.defaultMirrorPreview,
      defaultMirrorOutput: defaultMirrorOutput ?? this.defaultMirrorOutput,
      defaultOrientation: defaultOrientation ?? this.defaultOrientation,
      defaultOutputFormat: defaultOutputFormat ?? this.defaultOutputFormat,
      defaultJpegQuality: defaultJpegQuality ?? this.defaultJpegQuality,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (themeProfile.present) {
      map['theme_profile'] = Variable<String>(
        BoothProfiles.$converterthemeProfile.toSql(themeProfile.value),
      );
    }
    if (contrastPreference.present) {
      map['contrast_preference'] = Variable<String>(
        BoothProfiles.$convertercontrastPreference.toSql(
          contrastPreference.value,
        ),
      );
    }
    if (motionPreference.present) {
      map['motion_preference'] = Variable<String>(
        BoothProfiles.$convertermotionPreference.toSql(motionPreference.value),
      );
    }
    if (defaultLens.present) {
      map['default_lens'] = Variable<String>(
        BoothProfiles.$converterdefaultLens.toSql(defaultLens.value),
      );
    }
    if (defaultMirrorPreview.present) {
      map['default_mirror_preview'] = Variable<bool>(
        defaultMirrorPreview.value,
      );
    }
    if (defaultMirrorOutput.present) {
      map['default_mirror_output'] = Variable<bool>(defaultMirrorOutput.value);
    }
    if (defaultOrientation.present) {
      map['default_orientation'] = Variable<String>(
        BoothProfiles.$converterdefaultOrientation.toSql(
          defaultOrientation.value,
        ),
      );
    }
    if (defaultOutputFormat.present) {
      map['default_output_format'] = Variable<String>(
        BoothProfiles.$converterdefaultOutputFormat.toSql(
          defaultOutputFormat.value,
        ),
      );
    }
    if (defaultJpegQuality.present) {
      map['default_jpeg_quality'] = Variable<int>(defaultJpegQuality.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoothProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('themeProfile: $themeProfile, ')
          ..write('contrastPreference: $contrastPreference, ')
          ..write('motionPreference: $motionPreference, ')
          ..write('defaultLens: $defaultLens, ')
          ..write('defaultMirrorPreview: $defaultMirrorPreview, ')
          ..write('defaultMirrorOutput: $defaultMirrorOutput, ')
          ..write('defaultOrientation: $defaultOrientation, ')
          ..write('defaultOutputFormat: $defaultOutputFormat, ')
          ..write('defaultJpegQuality: $defaultJpegQuality, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Events extends Table with TableInfo<Events, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Events(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _boothProfileIdMeta = const VerificationMeta(
    'boothProfileId',
  );
  late final GeneratedColumn<String> boothProfileId = GeneratedColumn<String>(
    'booth_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES booth_profiles(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(trim(title)) BETWEEN 1 AND 80)',
  );
  late final GeneratedColumnWithTypeConverter<CalendarDate?, String> eventDate =
      GeneratedColumn<String>(
        'event_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (event_date IS NULL OR event_date GLOB \'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\')',
      ).withConverter<CalendarDate?>(Events.$convertereventDaten);
  static const VerificationMeta _venueMeta = const VerificationMeta('venue');
  late final GeneratedColumn<String> venue = GeneratedColumn<String>(
    'venue',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (venue IS NULL OR length(venue) <= 80)',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (notes IS NULL OR length(notes) <= 1000)',
  );
  late final GeneratedColumnWithTypeConverter<EventStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (status IN (\'draft\', \'active\', \'archived\'))',
      ).withConverter<EventStatus>(Events.$converterstatus);
  late final GeneratedColumnWithTypeConverter<CameraLens, String> lens =
      GeneratedColumn<String>(
        'lens',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (lens IN (\'front\', \'back\', \'external\'))',
      ).withConverter<CameraLens>(Events.$converterlens);
  static const VerificationMeta _mirrorPreviewMeta = const VerificationMeta(
    'mirrorPreview',
  );
  late final GeneratedColumn<bool> mirrorPreview = GeneratedColumn<bool>(
    'mirror_preview',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mirror_preview IN (0, 1))',
  );
  static const VerificationMeta _mirrorOutputMeta = const VerificationMeta(
    'mirrorOutput',
  );
  late final GeneratedColumn<bool> mirrorOutput = GeneratedColumn<bool>(
    'mirror_output',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mirror_output IN (0, 1))',
  );
  late final GeneratedColumnWithTypeConverter<
    GuestOrientationPreference,
    String
  >
  guestOrientation = GeneratedColumn<String>(
    'guest_orientation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (guest_orientation IN (\'portrait\', \'landscape\'))',
  ).withConverter<GuestOrientationPreference>(Events.$converterguestOrientation);
  static const VerificationMeta _shotCountMeta = const VerificationMeta(
    'shotCount',
  );
  late final GeneratedColumn<int> shotCount = GeneratedColumn<int>(
    'shot_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (shot_count BETWEEN 1 AND 4)',
  );
  static const VerificationMeta _countdownSecondsMeta = const VerificationMeta(
    'countdownSeconds',
  );
  late final GeneratedColumn<int> countdownSeconds = GeneratedColumn<int>(
    'countdown_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (countdown_seconds BETWEEN 2 AND 10)',
  );
  static const VerificationMeta _shotIntervalSecondsMeta =
      const VerificationMeta('shotIntervalSeconds');
  late final GeneratedColumn<int> shotIntervalSeconds = GeneratedColumn<int>(
    'shot_interval_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (shot_interval_seconds BETWEEN 1 AND 10)',
  );
  late final GeneratedColumnWithTypeConverter<RetakePolicy, String>
  retakePolicy = GeneratedColumn<String>(
    'retake_policy',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (retake_policy IN (\'none\', \'perShot\', \'wholeSession\'))',
  ).withConverter<RetakePolicy>(Events.$converterretakePolicy);
  static const VerificationMeta _retakeLimitMeta = const VerificationMeta(
    'retakeLimit',
  );
  late final GeneratedColumn<int> retakeLimit = GeneratedColumn<int>(
    'retake_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _welcomeTitleMeta = const VerificationMeta(
    'welcomeTitle',
  );
  late final GeneratedColumn<String> welcomeTitle = GeneratedColumn<String>(
    'welcome_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (welcome_title IS NULL OR length(welcome_title) <= 60)',
  );
  static const VerificationMeta _welcomeMessageMeta = const VerificationMeta(
    'welcomeMessage',
  );
  late final GeneratedColumn<String> welcomeMessage = GeneratedColumn<String>(
    'welcome_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (welcome_message IS NULL OR length(welcome_message) <= 200)',
  );
  static const VerificationMeta _consentTextMeta = const VerificationMeta(
    'consentText',
  );
  late final GeneratedColumn<String> consentText = GeneratedColumn<String>(
    'consent_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (consent_text IS NULL OR length(consent_text) <= 400)',
  );
  static const VerificationMeta _guestChoosesTemplateMeta =
      const VerificationMeta('guestChoosesTemplate');
  late final GeneratedColumn<bool> guestChoosesTemplate = GeneratedColumn<bool>(
    'guest_chooses_template',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (guest_chooses_template IN (0, 1))',
  );
  static const VerificationMeta _finishTimeoutSecondsMeta =
      const VerificationMeta('finishTimeoutSeconds');
  late final GeneratedColumn<int> finishTimeoutSeconds = GeneratedColumn<int>(
    'finish_timeout_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (finish_timeout_seconds BETWEEN 10 AND 120)',
  );
  late final GeneratedColumnWithTypeConverter<PorcelainThemeProfile?, String>
  themeOverride = GeneratedColumn<String>(
    'theme_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (theme_override IS NULL OR theme_override IN (\'porcelainStudio\', \'lightOak\', \'darkroomWalnut\'))',
  ).withConverter<PorcelainThemeProfile?>(Events.$converterthemeOverriden);
  late final GeneratedColumnWithTypeConverter<OutputFormat, String>
  outputFormat = GeneratedColumn<String>(
    'output_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (output_format IN (\'jpeg\', \'png\'))',
  ).withConverter<OutputFormat>(Events.$converteroutputFormat);
  static const VerificationMeta _jpegQualityMeta = const VerificationMeta(
    'jpegQuality',
  );
  late final GeneratedColumn<int> jpegQuality = GeneratedColumn<int>(
    'jpeg_quality',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (jpeg_quality BETWEEN 80 AND 100)',
  );
  late final GeneratedColumnWithTypeConverter<RetentionMode, String>
  retentionMode = GeneratedColumn<String>(
    'retention_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (retention_mode IN (\'keepUntilDeleted\', \'deleteAfterDays\'))',
  ).withConverter<RetentionMode>(Events.$converterretentionMode);
  static const VerificationMeta _retentionDaysMeta = const VerificationMeta(
    'retentionDays',
  );
  late final GeneratedColumn<int> retentionDays = GeneratedColumn<int>(
    'retention_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boothProfileId,
    title,
    eventDate,
    venue,
    notes,
    status,
    lens,
    mirrorPreview,
    mirrorOutput,
    guestOrientation,
    shotCount,
    countdownSeconds,
    shotIntervalSeconds,
    retakePolicy,
    retakeLimit,
    welcomeTitle,
    welcomeMessage,
    consentText,
    guestChoosesTemplate,
    finishTimeoutSeconds,
    themeOverride,
    outputFormat,
    jpegQuality,
    retentionMode,
    retentionDays,
    createdAt,
    updatedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('booth_profile_id')) {
      context.handle(
        _boothProfileIdMeta,
        boothProfileId.isAcceptableOrUnknown(
          data['booth_profile_id']!,
          _boothProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boothProfileIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('venue')) {
      context.handle(
        _venueMeta,
        venue.isAcceptableOrUnknown(data['venue']!, _venueMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('mirror_preview')) {
      context.handle(
        _mirrorPreviewMeta,
        mirrorPreview.isAcceptableOrUnknown(
          data['mirror_preview']!,
          _mirrorPreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mirrorPreviewMeta);
    }
    if (data.containsKey('mirror_output')) {
      context.handle(
        _mirrorOutputMeta,
        mirrorOutput.isAcceptableOrUnknown(
          data['mirror_output']!,
          _mirrorOutputMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mirrorOutputMeta);
    }
    if (data.containsKey('shot_count')) {
      context.handle(
        _shotCountMeta,
        shotCount.isAcceptableOrUnknown(data['shot_count']!, _shotCountMeta),
      );
    } else if (isInserting) {
      context.missing(_shotCountMeta);
    }
    if (data.containsKey('countdown_seconds')) {
      context.handle(
        _countdownSecondsMeta,
        countdownSeconds.isAcceptableOrUnknown(
          data['countdown_seconds']!,
          _countdownSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_countdownSecondsMeta);
    }
    if (data.containsKey('shot_interval_seconds')) {
      context.handle(
        _shotIntervalSecondsMeta,
        shotIntervalSeconds.isAcceptableOrUnknown(
          data['shot_interval_seconds']!,
          _shotIntervalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shotIntervalSecondsMeta);
    }
    if (data.containsKey('retake_limit')) {
      context.handle(
        _retakeLimitMeta,
        retakeLimit.isAcceptableOrUnknown(
          data['retake_limit']!,
          _retakeLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retakeLimitMeta);
    }
    if (data.containsKey('welcome_title')) {
      context.handle(
        _welcomeTitleMeta,
        welcomeTitle.isAcceptableOrUnknown(
          data['welcome_title']!,
          _welcomeTitleMeta,
        ),
      );
    }
    if (data.containsKey('welcome_message')) {
      context.handle(
        _welcomeMessageMeta,
        welcomeMessage.isAcceptableOrUnknown(
          data['welcome_message']!,
          _welcomeMessageMeta,
        ),
      );
    }
    if (data.containsKey('consent_text')) {
      context.handle(
        _consentTextMeta,
        consentText.isAcceptableOrUnknown(
          data['consent_text']!,
          _consentTextMeta,
        ),
      );
    }
    if (data.containsKey('guest_chooses_template')) {
      context.handle(
        _guestChoosesTemplateMeta,
        guestChoosesTemplate.isAcceptableOrUnknown(
          data['guest_chooses_template']!,
          _guestChoosesTemplateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_guestChoosesTemplateMeta);
    }
    if (data.containsKey('finish_timeout_seconds')) {
      context.handle(
        _finishTimeoutSecondsMeta,
        finishTimeoutSeconds.isAcceptableOrUnknown(
          data['finish_timeout_seconds']!,
          _finishTimeoutSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_finishTimeoutSecondsMeta);
    }
    if (data.containsKey('jpeg_quality')) {
      context.handle(
        _jpegQualityMeta,
        jpegQuality.isAcceptableOrUnknown(
          data['jpeg_quality']!,
          _jpegQualityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jpegQualityMeta);
    }
    if (data.containsKey('retention_days')) {
      context.handle(
        _retentionDaysMeta,
        retentionDays.isAcceptableOrUnknown(
          data['retention_days']!,
          _retentionDaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      boothProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booth_profile_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      eventDate: Events.$convertereventDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}event_date'],
        ),
      ),
      venue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venue'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: Events.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      lens: Events.$converterlens.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lens'],
        )!,
      ),
      mirrorPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mirror_preview'],
      )!,
      mirrorOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mirror_output'],
      )!,
      guestOrientation: Events.$converterguestOrientation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}guest_orientation'],
        )!,
      ),
      shotCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_count'],
      )!,
      countdownSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}countdown_seconds'],
      )!,
      shotIntervalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_interval_seconds'],
      )!,
      retakePolicy: Events.$converterretakePolicy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}retake_policy'],
        )!,
      ),
      retakeLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retake_limit'],
      )!,
      welcomeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}welcome_title'],
      ),
      welcomeMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}welcome_message'],
      ),
      consentText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_text'],
      ),
      guestChoosesTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}guest_chooses_template'],
      )!,
      finishTimeoutSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finish_timeout_seconds'],
      )!,
      themeOverride: Events.$converterthemeOverriden.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}theme_override'],
        ),
      ),
      outputFormat: Events.$converteroutputFormat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}output_format'],
        )!,
      ),
      jpegQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jpeg_quality'],
      )!,
      retentionMode: Events.$converterretentionMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}retention_mode'],
        )!,
      ),
      retentionDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retention_days'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  Events createAlias(String alias) {
    return Events(attachedDatabase, alias);
  }

  static TypeConverter<CalendarDate, String> $convertereventDate =
      const CalendarDateConverter();
  static TypeConverter<CalendarDate?, String?> $convertereventDaten =
      NullAwareTypeConverter.wrap($convertereventDate);
  static JsonTypeConverter2<EventStatus, String, String> $converterstatus =
      const EnumNameConverter<EventStatus>(EventStatus.values);
  static JsonTypeConverter2<CameraLens, String, String> $converterlens =
      const EnumNameConverter<CameraLens>(CameraLens.values);
  static JsonTypeConverter2<GuestOrientationPreference, String, String>
  $converterguestOrientation =
      const EnumNameConverter<GuestOrientationPreference>(
        GuestOrientationPreference.values,
      );
  static JsonTypeConverter2<RetakePolicy, String, String>
  $converterretakePolicy = const EnumNameConverter<RetakePolicy>(
    RetakePolicy.values,
  );
  static JsonTypeConverter2<PorcelainThemeProfile, String, String>
  $converterthemeOverride = themeProfileByName;
  static JsonTypeConverter2<PorcelainThemeProfile?, String?, String?>
  $converterthemeOverriden = JsonTypeConverter2.asNullable(
    $converterthemeOverride,
  );
  static JsonTypeConverter2<OutputFormat, String, String>
  $converteroutputFormat = const EnumNameConverter<OutputFormat>(
    OutputFormat.values,
  );
  static JsonTypeConverter2<RetentionMode, String, String>
  $converterretentionMode = const EnumNameConverter<RetentionMode>(
    RetentionMode.values,
  );
  @override
  List<String> get customConstraints => const [
    'CHECK((retake_policy = \'none\' AND retake_limit = 0)OR(retake_policy <> \'none\' AND retake_limit BETWEEN 1 AND 5))',
    'CHECK((retention_mode = \'keepUntilDeleted\' AND retention_days IS NULL)OR(retention_mode = \'deleteAfterDays\' AND retention_days BETWEEN 1 AND 365))',
    'CHECK((status = \'archived\')=(archived_at IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String id;
  final String boothProfileId;
  final String title;
  final CalendarDate? eventDate;
  final String? venue;
  final String? notes;
  final EventStatus status;
  final CameraLens lens;
  final bool mirrorPreview;
  final bool mirrorOutput;
  final GuestOrientationPreference guestOrientation;
  final int shotCount;
  final int countdownSeconds;
  final int shotIntervalSeconds;
  final RetakePolicy retakePolicy;
  final int retakeLimit;
  final String? welcomeTitle;
  final String? welcomeMessage;
  final String? consentText;
  final bool guestChoosesTemplate;
  final int finishTimeoutSeconds;
  final PorcelainThemeProfile? themeOverride;
  final OutputFormat outputFormat;
  final int jpegQuality;
  final RetentionMode retentionMode;
  final int? retentionDays;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  const EventRow({
    required this.id,
    required this.boothProfileId,
    required this.title,
    this.eventDate,
    this.venue,
    this.notes,
    required this.status,
    required this.lens,
    required this.mirrorPreview,
    required this.mirrorOutput,
    required this.guestOrientation,
    required this.shotCount,
    required this.countdownSeconds,
    required this.shotIntervalSeconds,
    required this.retakePolicy,
    required this.retakeLimit,
    this.welcomeTitle,
    this.welcomeMessage,
    this.consentText,
    required this.guestChoosesTemplate,
    required this.finishTimeoutSeconds,
    this.themeOverride,
    required this.outputFormat,
    required this.jpegQuality,
    required this.retentionMode,
    this.retentionDays,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['booth_profile_id'] = Variable<String>(boothProfileId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || eventDate != null) {
      map['event_date'] = Variable<String>(
        Events.$convertereventDaten.toSql(eventDate),
      );
    }
    if (!nullToAbsent || venue != null) {
      map['venue'] = Variable<String>(venue);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['status'] = Variable<String>(Events.$converterstatus.toSql(status));
    }
    {
      map['lens'] = Variable<String>(Events.$converterlens.toSql(lens));
    }
    map['mirror_preview'] = Variable<bool>(mirrorPreview);
    map['mirror_output'] = Variable<bool>(mirrorOutput);
    {
      map['guest_orientation'] = Variable<String>(
        Events.$converterguestOrientation.toSql(guestOrientation),
      );
    }
    map['shot_count'] = Variable<int>(shotCount);
    map['countdown_seconds'] = Variable<int>(countdownSeconds);
    map['shot_interval_seconds'] = Variable<int>(shotIntervalSeconds);
    {
      map['retake_policy'] = Variable<String>(
        Events.$converterretakePolicy.toSql(retakePolicy),
      );
    }
    map['retake_limit'] = Variable<int>(retakeLimit);
    if (!nullToAbsent || welcomeTitle != null) {
      map['welcome_title'] = Variable<String>(welcomeTitle);
    }
    if (!nullToAbsent || welcomeMessage != null) {
      map['welcome_message'] = Variable<String>(welcomeMessage);
    }
    if (!nullToAbsent || consentText != null) {
      map['consent_text'] = Variable<String>(consentText);
    }
    map['guest_chooses_template'] = Variable<bool>(guestChoosesTemplate);
    map['finish_timeout_seconds'] = Variable<int>(finishTimeoutSeconds);
    if (!nullToAbsent || themeOverride != null) {
      map['theme_override'] = Variable<String>(
        Events.$converterthemeOverriden.toSql(themeOverride),
      );
    }
    {
      map['output_format'] = Variable<String>(
        Events.$converteroutputFormat.toSql(outputFormat),
      );
    }
    map['jpeg_quality'] = Variable<int>(jpegQuality);
    {
      map['retention_mode'] = Variable<String>(
        Events.$converterretentionMode.toSql(retentionMode),
      );
    }
    if (!nullToAbsent || retentionDays != null) {
      map['retention_days'] = Variable<int>(retentionDays);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      boothProfileId: Value(boothProfileId),
      title: Value(title),
      eventDate: eventDate == null && nullToAbsent
          ? const Value.absent()
          : Value(eventDate),
      venue: venue == null && nullToAbsent
          ? const Value.absent()
          : Value(venue),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      lens: Value(lens),
      mirrorPreview: Value(mirrorPreview),
      mirrorOutput: Value(mirrorOutput),
      guestOrientation: Value(guestOrientation),
      shotCount: Value(shotCount),
      countdownSeconds: Value(countdownSeconds),
      shotIntervalSeconds: Value(shotIntervalSeconds),
      retakePolicy: Value(retakePolicy),
      retakeLimit: Value(retakeLimit),
      welcomeTitle: welcomeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(welcomeTitle),
      welcomeMessage: welcomeMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(welcomeMessage),
      consentText: consentText == null && nullToAbsent
          ? const Value.absent()
          : Value(consentText),
      guestChoosesTemplate: Value(guestChoosesTemplate),
      finishTimeoutSeconds: Value(finishTimeoutSeconds),
      themeOverride: themeOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(themeOverride),
      outputFormat: Value(outputFormat),
      jpegQuality: Value(jpegQuality),
      retentionMode: Value(retentionMode),
      retentionDays: retentionDays == null && nullToAbsent
          ? const Value.absent()
          : Value(retentionDays),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      id: serializer.fromJson<String>(json['id']),
      boothProfileId: serializer.fromJson<String>(json['booth_profile_id']),
      title: serializer.fromJson<String>(json['title']),
      eventDate: serializer.fromJson<CalendarDate?>(json['event_date']),
      venue: serializer.fromJson<String?>(json['venue']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: Events.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      lens: Events.$converterlens.fromJson(
        serializer.fromJson<String>(json['lens']),
      ),
      mirrorPreview: serializer.fromJson<bool>(json['mirror_preview']),
      mirrorOutput: serializer.fromJson<bool>(json['mirror_output']),
      guestOrientation: Events.$converterguestOrientation.fromJson(
        serializer.fromJson<String>(json['guest_orientation']),
      ),
      shotCount: serializer.fromJson<int>(json['shot_count']),
      countdownSeconds: serializer.fromJson<int>(json['countdown_seconds']),
      shotIntervalSeconds: serializer.fromJson<int>(
        json['shot_interval_seconds'],
      ),
      retakePolicy: Events.$converterretakePolicy.fromJson(
        serializer.fromJson<String>(json['retake_policy']),
      ),
      retakeLimit: serializer.fromJson<int>(json['retake_limit']),
      welcomeTitle: serializer.fromJson<String?>(json['welcome_title']),
      welcomeMessage: serializer.fromJson<String?>(json['welcome_message']),
      consentText: serializer.fromJson<String?>(json['consent_text']),
      guestChoosesTemplate: serializer.fromJson<bool>(
        json['guest_chooses_template'],
      ),
      finishTimeoutSeconds: serializer.fromJson<int>(
        json['finish_timeout_seconds'],
      ),
      themeOverride: Events.$converterthemeOverriden.fromJson(
        serializer.fromJson<String?>(json['theme_override']),
      ),
      outputFormat: Events.$converteroutputFormat.fromJson(
        serializer.fromJson<String>(json['output_format']),
      ),
      jpegQuality: serializer.fromJson<int>(json['jpeg_quality']),
      retentionMode: Events.$converterretentionMode.fromJson(
        serializer.fromJson<String>(json['retention_mode']),
      ),
      retentionDays: serializer.fromJson<int?>(json['retention_days']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      archivedAt: serializer.fromJson<DateTime?>(json['archived_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'booth_profile_id': serializer.toJson<String>(boothProfileId),
      'title': serializer.toJson<String>(title),
      'event_date': serializer.toJson<CalendarDate?>(eventDate),
      'venue': serializer.toJson<String?>(venue),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(
        Events.$converterstatus.toJson(status),
      ),
      'lens': serializer.toJson<String>(Events.$converterlens.toJson(lens)),
      'mirror_preview': serializer.toJson<bool>(mirrorPreview),
      'mirror_output': serializer.toJson<bool>(mirrorOutput),
      'guest_orientation': serializer.toJson<String>(
        Events.$converterguestOrientation.toJson(guestOrientation),
      ),
      'shot_count': serializer.toJson<int>(shotCount),
      'countdown_seconds': serializer.toJson<int>(countdownSeconds),
      'shot_interval_seconds': serializer.toJson<int>(shotIntervalSeconds),
      'retake_policy': serializer.toJson<String>(
        Events.$converterretakePolicy.toJson(retakePolicy),
      ),
      'retake_limit': serializer.toJson<int>(retakeLimit),
      'welcome_title': serializer.toJson<String?>(welcomeTitle),
      'welcome_message': serializer.toJson<String?>(welcomeMessage),
      'consent_text': serializer.toJson<String?>(consentText),
      'guest_chooses_template': serializer.toJson<bool>(guestChoosesTemplate),
      'finish_timeout_seconds': serializer.toJson<int>(finishTimeoutSeconds),
      'theme_override': serializer.toJson<String?>(
        Events.$converterthemeOverriden.toJson(themeOverride),
      ),
      'output_format': serializer.toJson<String>(
        Events.$converteroutputFormat.toJson(outputFormat),
      ),
      'jpeg_quality': serializer.toJson<int>(jpegQuality),
      'retention_mode': serializer.toJson<String>(
        Events.$converterretentionMode.toJson(retentionMode),
      ),
      'retention_days': serializer.toJson<int?>(retentionDays),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'archived_at': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  EventRow copyWith({
    String? id,
    String? boothProfileId,
    String? title,
    Value<CalendarDate?> eventDate = const Value.absent(),
    Value<String?> venue = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    EventStatus? status,
    CameraLens? lens,
    bool? mirrorPreview,
    bool? mirrorOutput,
    GuestOrientationPreference? guestOrientation,
    int? shotCount,
    int? countdownSeconds,
    int? shotIntervalSeconds,
    RetakePolicy? retakePolicy,
    int? retakeLimit,
    Value<String?> welcomeTitle = const Value.absent(),
    Value<String?> welcomeMessage = const Value.absent(),
    Value<String?> consentText = const Value.absent(),
    bool? guestChoosesTemplate,
    int? finishTimeoutSeconds,
    Value<PorcelainThemeProfile?> themeOverride = const Value.absent(),
    OutputFormat? outputFormat,
    int? jpegQuality,
    RetentionMode? retentionMode,
    Value<int?> retentionDays = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => EventRow(
    id: id ?? this.id,
    boothProfileId: boothProfileId ?? this.boothProfileId,
    title: title ?? this.title,
    eventDate: eventDate.present ? eventDate.value : this.eventDate,
    venue: venue.present ? venue.value : this.venue,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    lens: lens ?? this.lens,
    mirrorPreview: mirrorPreview ?? this.mirrorPreview,
    mirrorOutput: mirrorOutput ?? this.mirrorOutput,
    guestOrientation: guestOrientation ?? this.guestOrientation,
    shotCount: shotCount ?? this.shotCount,
    countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    shotIntervalSeconds: shotIntervalSeconds ?? this.shotIntervalSeconds,
    retakePolicy: retakePolicy ?? this.retakePolicy,
    retakeLimit: retakeLimit ?? this.retakeLimit,
    welcomeTitle: welcomeTitle.present ? welcomeTitle.value : this.welcomeTitle,
    welcomeMessage: welcomeMessage.present
        ? welcomeMessage.value
        : this.welcomeMessage,
    consentText: consentText.present ? consentText.value : this.consentText,
    guestChoosesTemplate: guestChoosesTemplate ?? this.guestChoosesTemplate,
    finishTimeoutSeconds: finishTimeoutSeconds ?? this.finishTimeoutSeconds,
    themeOverride: themeOverride.present
        ? themeOverride.value
        : this.themeOverride,
    outputFormat: outputFormat ?? this.outputFormat,
    jpegQuality: jpegQuality ?? this.jpegQuality,
    retentionMode: retentionMode ?? this.retentionMode,
    retentionDays: retentionDays.present
        ? retentionDays.value
        : this.retentionDays,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      id: data.id.present ? data.id.value : this.id,
      boothProfileId: data.boothProfileId.present
          ? data.boothProfileId.value
          : this.boothProfileId,
      title: data.title.present ? data.title.value : this.title,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      venue: data.venue.present ? data.venue.value : this.venue,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      lens: data.lens.present ? data.lens.value : this.lens,
      mirrorPreview: data.mirrorPreview.present
          ? data.mirrorPreview.value
          : this.mirrorPreview,
      mirrorOutput: data.mirrorOutput.present
          ? data.mirrorOutput.value
          : this.mirrorOutput,
      guestOrientation: data.guestOrientation.present
          ? data.guestOrientation.value
          : this.guestOrientation,
      shotCount: data.shotCount.present ? data.shotCount.value : this.shotCount,
      countdownSeconds: data.countdownSeconds.present
          ? data.countdownSeconds.value
          : this.countdownSeconds,
      shotIntervalSeconds: data.shotIntervalSeconds.present
          ? data.shotIntervalSeconds.value
          : this.shotIntervalSeconds,
      retakePolicy: data.retakePolicy.present
          ? data.retakePolicy.value
          : this.retakePolicy,
      retakeLimit: data.retakeLimit.present
          ? data.retakeLimit.value
          : this.retakeLimit,
      welcomeTitle: data.welcomeTitle.present
          ? data.welcomeTitle.value
          : this.welcomeTitle,
      welcomeMessage: data.welcomeMessage.present
          ? data.welcomeMessage.value
          : this.welcomeMessage,
      consentText: data.consentText.present
          ? data.consentText.value
          : this.consentText,
      guestChoosesTemplate: data.guestChoosesTemplate.present
          ? data.guestChoosesTemplate.value
          : this.guestChoosesTemplate,
      finishTimeoutSeconds: data.finishTimeoutSeconds.present
          ? data.finishTimeoutSeconds.value
          : this.finishTimeoutSeconds,
      themeOverride: data.themeOverride.present
          ? data.themeOverride.value
          : this.themeOverride,
      outputFormat: data.outputFormat.present
          ? data.outputFormat.value
          : this.outputFormat,
      jpegQuality: data.jpegQuality.present
          ? data.jpegQuality.value
          : this.jpegQuality,
      retentionMode: data.retentionMode.present
          ? data.retentionMode.value
          : this.retentionMode,
      retentionDays: data.retentionDays.present
          ? data.retentionDays.value
          : this.retentionDays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('id: $id, ')
          ..write('boothProfileId: $boothProfileId, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('venue: $venue, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('lens: $lens, ')
          ..write('mirrorPreview: $mirrorPreview, ')
          ..write('mirrorOutput: $mirrorOutput, ')
          ..write('guestOrientation: $guestOrientation, ')
          ..write('shotCount: $shotCount, ')
          ..write('countdownSeconds: $countdownSeconds, ')
          ..write('shotIntervalSeconds: $shotIntervalSeconds, ')
          ..write('retakePolicy: $retakePolicy, ')
          ..write('retakeLimit: $retakeLimit, ')
          ..write('welcomeTitle: $welcomeTitle, ')
          ..write('welcomeMessage: $welcomeMessage, ')
          ..write('consentText: $consentText, ')
          ..write('guestChoosesTemplate: $guestChoosesTemplate, ')
          ..write('finishTimeoutSeconds: $finishTimeoutSeconds, ')
          ..write('themeOverride: $themeOverride, ')
          ..write('outputFormat: $outputFormat, ')
          ..write('jpegQuality: $jpegQuality, ')
          ..write('retentionMode: $retentionMode, ')
          ..write('retentionDays: $retentionDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    boothProfileId,
    title,
    eventDate,
    venue,
    notes,
    status,
    lens,
    mirrorPreview,
    mirrorOutput,
    guestOrientation,
    shotCount,
    countdownSeconds,
    shotIntervalSeconds,
    retakePolicy,
    retakeLimit,
    welcomeTitle,
    welcomeMessage,
    consentText,
    guestChoosesTemplate,
    finishTimeoutSeconds,
    themeOverride,
    outputFormat,
    jpegQuality,
    retentionMode,
    retentionDays,
    createdAt,
    updatedAt,
    archivedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.id == this.id &&
          other.boothProfileId == this.boothProfileId &&
          other.title == this.title &&
          other.eventDate == this.eventDate &&
          other.venue == this.venue &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.lens == this.lens &&
          other.mirrorPreview == this.mirrorPreview &&
          other.mirrorOutput == this.mirrorOutput &&
          other.guestOrientation == this.guestOrientation &&
          other.shotCount == this.shotCount &&
          other.countdownSeconds == this.countdownSeconds &&
          other.shotIntervalSeconds == this.shotIntervalSeconds &&
          other.retakePolicy == this.retakePolicy &&
          other.retakeLimit == this.retakeLimit &&
          other.welcomeTitle == this.welcomeTitle &&
          other.welcomeMessage == this.welcomeMessage &&
          other.consentText == this.consentText &&
          other.guestChoosesTemplate == this.guestChoosesTemplate &&
          other.finishTimeoutSeconds == this.finishTimeoutSeconds &&
          other.themeOverride == this.themeOverride &&
          other.outputFormat == this.outputFormat &&
          other.jpegQuality == this.jpegQuality &&
          other.retentionMode == this.retentionMode &&
          other.retentionDays == this.retentionDays &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> id;
  final Value<String> boothProfileId;
  final Value<String> title;
  final Value<CalendarDate?> eventDate;
  final Value<String?> venue;
  final Value<String?> notes;
  final Value<EventStatus> status;
  final Value<CameraLens> lens;
  final Value<bool> mirrorPreview;
  final Value<bool> mirrorOutput;
  final Value<GuestOrientationPreference> guestOrientation;
  final Value<int> shotCount;
  final Value<int> countdownSeconds;
  final Value<int> shotIntervalSeconds;
  final Value<RetakePolicy> retakePolicy;
  final Value<int> retakeLimit;
  final Value<String?> welcomeTitle;
  final Value<String?> welcomeMessage;
  final Value<String?> consentText;
  final Value<bool> guestChoosesTemplate;
  final Value<int> finishTimeoutSeconds;
  final Value<PorcelainThemeProfile?> themeOverride;
  final Value<OutputFormat> outputFormat;
  final Value<int> jpegQuality;
  final Value<RetentionMode> retentionMode;
  final Value<int?> retentionDays;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.boothProfileId = const Value.absent(),
    this.title = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.venue = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.lens = const Value.absent(),
    this.mirrorPreview = const Value.absent(),
    this.mirrorOutput = const Value.absent(),
    this.guestOrientation = const Value.absent(),
    this.shotCount = const Value.absent(),
    this.countdownSeconds = const Value.absent(),
    this.shotIntervalSeconds = const Value.absent(),
    this.retakePolicy = const Value.absent(),
    this.retakeLimit = const Value.absent(),
    this.welcomeTitle = const Value.absent(),
    this.welcomeMessage = const Value.absent(),
    this.consentText = const Value.absent(),
    this.guestChoosesTemplate = const Value.absent(),
    this.finishTimeoutSeconds = const Value.absent(),
    this.themeOverride = const Value.absent(),
    this.outputFormat = const Value.absent(),
    this.jpegQuality = const Value.absent(),
    this.retentionMode = const Value.absent(),
    this.retentionDays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String boothProfileId,
    required String title,
    this.eventDate = const Value.absent(),
    this.venue = const Value.absent(),
    this.notes = const Value.absent(),
    required EventStatus status,
    required CameraLens lens,
    required bool mirrorPreview,
    required bool mirrorOutput,
    required GuestOrientationPreference guestOrientation,
    required int shotCount,
    required int countdownSeconds,
    required int shotIntervalSeconds,
    required RetakePolicy retakePolicy,
    required int retakeLimit,
    this.welcomeTitle = const Value.absent(),
    this.welcomeMessage = const Value.absent(),
    this.consentText = const Value.absent(),
    required bool guestChoosesTemplate,
    required int finishTimeoutSeconds,
    this.themeOverride = const Value.absent(),
    required OutputFormat outputFormat,
    required int jpegQuality,
    required RetentionMode retentionMode,
    this.retentionDays = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       boothProfileId = Value(boothProfileId),
       title = Value(title),
       status = Value(status),
       lens = Value(lens),
       mirrorPreview = Value(mirrorPreview),
       mirrorOutput = Value(mirrorOutput),
       guestOrientation = Value(guestOrientation),
       shotCount = Value(shotCount),
       countdownSeconds = Value(countdownSeconds),
       shotIntervalSeconds = Value(shotIntervalSeconds),
       retakePolicy = Value(retakePolicy),
       retakeLimit = Value(retakeLimit),
       guestChoosesTemplate = Value(guestChoosesTemplate),
       finishTimeoutSeconds = Value(finishTimeoutSeconds),
       outputFormat = Value(outputFormat),
       jpegQuality = Value(jpegQuality),
       retentionMode = Value(retentionMode),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventRow> custom({
    Expression<String>? id,
    Expression<String>? boothProfileId,
    Expression<String>? title,
    Expression<String>? eventDate,
    Expression<String>? venue,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? lens,
    Expression<bool>? mirrorPreview,
    Expression<bool>? mirrorOutput,
    Expression<String>? guestOrientation,
    Expression<int>? shotCount,
    Expression<int>? countdownSeconds,
    Expression<int>? shotIntervalSeconds,
    Expression<String>? retakePolicy,
    Expression<int>? retakeLimit,
    Expression<String>? welcomeTitle,
    Expression<String>? welcomeMessage,
    Expression<String>? consentText,
    Expression<bool>? guestChoosesTemplate,
    Expression<int>? finishTimeoutSeconds,
    Expression<String>? themeOverride,
    Expression<String>? outputFormat,
    Expression<int>? jpegQuality,
    Expression<String>? retentionMode,
    Expression<int>? retentionDays,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boothProfileId != null) 'booth_profile_id': boothProfileId,
      if (title != null) 'title': title,
      if (eventDate != null) 'event_date': eventDate,
      if (venue != null) 'venue': venue,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (lens != null) 'lens': lens,
      if (mirrorPreview != null) 'mirror_preview': mirrorPreview,
      if (mirrorOutput != null) 'mirror_output': mirrorOutput,
      if (guestOrientation != null) 'guest_orientation': guestOrientation,
      if (shotCount != null) 'shot_count': shotCount,
      if (countdownSeconds != null) 'countdown_seconds': countdownSeconds,
      if (shotIntervalSeconds != null)
        'shot_interval_seconds': shotIntervalSeconds,
      if (retakePolicy != null) 'retake_policy': retakePolicy,
      if (retakeLimit != null) 'retake_limit': retakeLimit,
      if (welcomeTitle != null) 'welcome_title': welcomeTitle,
      if (welcomeMessage != null) 'welcome_message': welcomeMessage,
      if (consentText != null) 'consent_text': consentText,
      if (guestChoosesTemplate != null)
        'guest_chooses_template': guestChoosesTemplate,
      if (finishTimeoutSeconds != null)
        'finish_timeout_seconds': finishTimeoutSeconds,
      if (themeOverride != null) 'theme_override': themeOverride,
      if (outputFormat != null) 'output_format': outputFormat,
      if (jpegQuality != null) 'jpeg_quality': jpegQuality,
      if (retentionMode != null) 'retention_mode': retentionMode,
      if (retentionDays != null) 'retention_days': retentionDays,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? boothProfileId,
    Value<String>? title,
    Value<CalendarDate?>? eventDate,
    Value<String?>? venue,
    Value<String?>? notes,
    Value<EventStatus>? status,
    Value<CameraLens>? lens,
    Value<bool>? mirrorPreview,
    Value<bool>? mirrorOutput,
    Value<GuestOrientationPreference>? guestOrientation,
    Value<int>? shotCount,
    Value<int>? countdownSeconds,
    Value<int>? shotIntervalSeconds,
    Value<RetakePolicy>? retakePolicy,
    Value<int>? retakeLimit,
    Value<String?>? welcomeTitle,
    Value<String?>? welcomeMessage,
    Value<String?>? consentText,
    Value<bool>? guestChoosesTemplate,
    Value<int>? finishTimeoutSeconds,
    Value<PorcelainThemeProfile?>? themeOverride,
    Value<OutputFormat>? outputFormat,
    Value<int>? jpegQuality,
    Value<RetentionMode>? retentionMode,
    Value<int?>? retentionDays,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      boothProfileId: boothProfileId ?? this.boothProfileId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      lens: lens ?? this.lens,
      mirrorPreview: mirrorPreview ?? this.mirrorPreview,
      mirrorOutput: mirrorOutput ?? this.mirrorOutput,
      guestOrientation: guestOrientation ?? this.guestOrientation,
      shotCount: shotCount ?? this.shotCount,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      shotIntervalSeconds: shotIntervalSeconds ?? this.shotIntervalSeconds,
      retakePolicy: retakePolicy ?? this.retakePolicy,
      retakeLimit: retakeLimit ?? this.retakeLimit,
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      consentText: consentText ?? this.consentText,
      guestChoosesTemplate: guestChoosesTemplate ?? this.guestChoosesTemplate,
      finishTimeoutSeconds: finishTimeoutSeconds ?? this.finishTimeoutSeconds,
      themeOverride: themeOverride ?? this.themeOverride,
      outputFormat: outputFormat ?? this.outputFormat,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      retentionMode: retentionMode ?? this.retentionMode,
      retentionDays: retentionDays ?? this.retentionDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (boothProfileId.present) {
      map['booth_profile_id'] = Variable<String>(boothProfileId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<String>(
        Events.$convertereventDaten.toSql(eventDate.value),
      );
    }
    if (venue.present) {
      map['venue'] = Variable<String>(venue.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        Events.$converterstatus.toSql(status.value),
      );
    }
    if (lens.present) {
      map['lens'] = Variable<String>(Events.$converterlens.toSql(lens.value));
    }
    if (mirrorPreview.present) {
      map['mirror_preview'] = Variable<bool>(mirrorPreview.value);
    }
    if (mirrorOutput.present) {
      map['mirror_output'] = Variable<bool>(mirrorOutput.value);
    }
    if (guestOrientation.present) {
      map['guest_orientation'] = Variable<String>(
        Events.$converterguestOrientation.toSql(guestOrientation.value),
      );
    }
    if (shotCount.present) {
      map['shot_count'] = Variable<int>(shotCount.value);
    }
    if (countdownSeconds.present) {
      map['countdown_seconds'] = Variable<int>(countdownSeconds.value);
    }
    if (shotIntervalSeconds.present) {
      map['shot_interval_seconds'] = Variable<int>(shotIntervalSeconds.value);
    }
    if (retakePolicy.present) {
      map['retake_policy'] = Variable<String>(
        Events.$converterretakePolicy.toSql(retakePolicy.value),
      );
    }
    if (retakeLimit.present) {
      map['retake_limit'] = Variable<int>(retakeLimit.value);
    }
    if (welcomeTitle.present) {
      map['welcome_title'] = Variable<String>(welcomeTitle.value);
    }
    if (welcomeMessage.present) {
      map['welcome_message'] = Variable<String>(welcomeMessage.value);
    }
    if (consentText.present) {
      map['consent_text'] = Variable<String>(consentText.value);
    }
    if (guestChoosesTemplate.present) {
      map['guest_chooses_template'] = Variable<bool>(
        guestChoosesTemplate.value,
      );
    }
    if (finishTimeoutSeconds.present) {
      map['finish_timeout_seconds'] = Variable<int>(finishTimeoutSeconds.value);
    }
    if (themeOverride.present) {
      map['theme_override'] = Variable<String>(
        Events.$converterthemeOverriden.toSql(themeOverride.value),
      );
    }
    if (outputFormat.present) {
      map['output_format'] = Variable<String>(
        Events.$converteroutputFormat.toSql(outputFormat.value),
      );
    }
    if (jpegQuality.present) {
      map['jpeg_quality'] = Variable<int>(jpegQuality.value);
    }
    if (retentionMode.present) {
      map['retention_mode'] = Variable<String>(
        Events.$converterretentionMode.toSql(retentionMode.value),
      );
    }
    if (retentionDays.present) {
      map['retention_days'] = Variable<int>(retentionDays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('boothProfileId: $boothProfileId, ')
          ..write('title: $title, ')
          ..write('eventDate: $eventDate, ')
          ..write('venue: $venue, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('lens: $lens, ')
          ..write('mirrorPreview: $mirrorPreview, ')
          ..write('mirrorOutput: $mirrorOutput, ')
          ..write('guestOrientation: $guestOrientation, ')
          ..write('shotCount: $shotCount, ')
          ..write('countdownSeconds: $countdownSeconds, ')
          ..write('shotIntervalSeconds: $shotIntervalSeconds, ')
          ..write('retakePolicy: $retakePolicy, ')
          ..write('retakeLimit: $retakeLimit, ')
          ..write('welcomeTitle: $welcomeTitle, ')
          ..write('welcomeMessage: $welcomeMessage, ')
          ..write('consentText: $consentText, ')
          ..write('guestChoosesTemplate: $guestChoosesTemplate, ')
          ..write('finishTimeoutSeconds: $finishTimeoutSeconds, ')
          ..write('themeOverride: $themeOverride, ')
          ..write('outputFormat: $outputFormat, ')
          ..write('jpegQuality: $jpegQuality, ')
          ..write('retentionMode: $retentionMode, ')
          ..write('retentionDays: $retentionDays, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AppSettings extends Table with TableInfo<AppSettings, AppSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppSettings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _boothProfileIdMeta = const VerificationMeta(
    'boothProfileId',
  );
  late final GeneratedColumn<String> boothProfileId = GeneratedColumn<String>(
    'booth_profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES booth_profiles(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _setupCompletedAtMeta = const VerificationMeta(
    'setupCompletedAt',
  );
  late final GeneratedColumn<DateTime> setupCompletedAt =
      GeneratedColumn<DateTime>(
        'setup_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _boothEventIdMeta = const VerificationMeta(
    'boothEventId',
  );
  late final GeneratedColumn<String> boothEventId = GeneratedColumn<String>(
    'booth_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES events(id)ON DELETE SET NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    boothProfileId,
    setupCompletedAt,
    boothEventId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('booth_profile_id')) {
      context.handle(
        _boothProfileIdMeta,
        boothProfileId.isAcceptableOrUnknown(
          data['booth_profile_id']!,
          _boothProfileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boothProfileIdMeta);
    }
    if (data.containsKey('setup_completed_at')) {
      context.handle(
        _setupCompletedAtMeta,
        setupCompletedAt.isAcceptableOrUnknown(
          data['setup_completed_at']!,
          _setupCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('booth_event_id')) {
      context.handle(
        _boothEventIdMeta,
        boothEventId.isAcceptableOrUnknown(
          data['booth_event_id']!,
          _boothEventIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      boothProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booth_profile_id'],
      )!,
      setupCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}setup_completed_at'],
      ),
      boothEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booth_event_id'],
      ),
    );
  }

  @override
  AppSettings createAlias(String alias) {
    return AppSettings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppSettingsRow extends DataClass implements Insertable<AppSettingsRow> {
  final int id;
  final String boothProfileId;

  /// Null until first-run setup finishes.
  final DateTime? setupCompletedAt;

  /// The event Booth Mode is running; null while the Studio is in use.
  final String? boothEventId;
  const AppSettingsRow({
    required this.id,
    required this.boothProfileId,
    this.setupCompletedAt,
    this.boothEventId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['booth_profile_id'] = Variable<String>(boothProfileId);
    if (!nullToAbsent || setupCompletedAt != null) {
      map['setup_completed_at'] = Variable<DateTime>(setupCompletedAt);
    }
    if (!nullToAbsent || boothEventId != null) {
      map['booth_event_id'] = Variable<String>(boothEventId);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      boothProfileId: Value(boothProfileId),
      setupCompletedAt: setupCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(setupCompletedAt),
      boothEventId: boothEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(boothEventId),
    );
  }

  factory AppSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      boothProfileId: serializer.fromJson<String>(json['booth_profile_id']),
      setupCompletedAt: serializer.fromJson<DateTime?>(
        json['setup_completed_at'],
      ),
      boothEventId: serializer.fromJson<String?>(json['booth_event_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'booth_profile_id': serializer.toJson<String>(boothProfileId),
      'setup_completed_at': serializer.toJson<DateTime?>(setupCompletedAt),
      'booth_event_id': serializer.toJson<String?>(boothEventId),
    };
  }

  AppSettingsRow copyWith({
    int? id,
    String? boothProfileId,
    Value<DateTime?> setupCompletedAt = const Value.absent(),
    Value<String?> boothEventId = const Value.absent(),
  }) => AppSettingsRow(
    id: id ?? this.id,
    boothProfileId: boothProfileId ?? this.boothProfileId,
    setupCompletedAt: setupCompletedAt.present
        ? setupCompletedAt.value
        : this.setupCompletedAt,
    boothEventId: boothEventId.present ? boothEventId.value : this.boothEventId,
  );
  AppSettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      boothProfileId: data.boothProfileId.present
          ? data.boothProfileId.value
          : this.boothProfileId,
      setupCompletedAt: data.setupCompletedAt.present
          ? data.setupCompletedAt.value
          : this.setupCompletedAt,
      boothEventId: data.boothEventId.present
          ? data.boothEventId.value
          : this.boothEventId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsRow(')
          ..write('id: $id, ')
          ..write('boothProfileId: $boothProfileId, ')
          ..write('setupCompletedAt: $setupCompletedAt, ')
          ..write('boothEventId: $boothEventId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, boothProfileId, setupCompletedAt, boothEventId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingsRow &&
          other.id == this.id &&
          other.boothProfileId == this.boothProfileId &&
          other.setupCompletedAt == this.setupCompletedAt &&
          other.boothEventId == this.boothEventId);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingsRow> {
  final Value<int> id;
  final Value<String> boothProfileId;
  final Value<DateTime?> setupCompletedAt;
  final Value<String?> boothEventId;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.boothProfileId = const Value.absent(),
    this.setupCompletedAt = const Value.absent(),
    this.boothEventId = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String boothProfileId,
    this.setupCompletedAt = const Value.absent(),
    this.boothEventId = const Value.absent(),
  }) : boothProfileId = Value(boothProfileId);
  static Insertable<AppSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? boothProfileId,
    Expression<DateTime>? setupCompletedAt,
    Expression<String>? boothEventId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (boothProfileId != null) 'booth_profile_id': boothProfileId,
      if (setupCompletedAt != null) 'setup_completed_at': setupCompletedAt,
      if (boothEventId != null) 'booth_event_id': boothEventId,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? boothProfileId,
    Value<DateTime?>? setupCompletedAt,
    Value<String?>? boothEventId,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      boothProfileId: boothProfileId ?? this.boothProfileId,
      setupCompletedAt: setupCompletedAt ?? this.setupCompletedAt,
      boothEventId: boothEventId ?? this.boothEventId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (boothProfileId.present) {
      map['booth_profile_id'] = Variable<String>(boothProfileId.value);
    }
    if (setupCompletedAt.present) {
      map['setup_completed_at'] = Variable<DateTime>(setupCompletedAt.value);
    }
    if (boothEventId.present) {
      map['booth_event_id'] = Variable<String>(boothEventId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('boothProfileId: $boothProfileId, ')
          ..write('setupCompletedAt: $setupCompletedAt, ')
          ..write('boothEventId: $boothEventId')
          ..write(')'))
        .toString();
  }
}

class OperatorAccess extends Table
    with TableInfo<OperatorAccess, OperatorAccessRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OperatorAccess(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _recoveryVerifierMeta = const VerificationMeta(
    'recoveryVerifier',
  );
  late final GeneratedColumn<String> recoveryVerifier = GeneratedColumn<String>(
    'recovery_verifier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _pinFailuresMeta = const VerificationMeta(
    'pinFailures',
  );
  late final GeneratedColumn<int> pinFailures = GeneratedColumn<int>(
    'pin_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (pin_failures >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _pinLastFailureAtMeta = const VerificationMeta(
    'pinLastFailureAt',
  );
  late final GeneratedColumn<DateTime> pinLastFailureAt =
      GeneratedColumn<DateTime>(
        'pin_last_failure_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _recoveryFailuresMeta = const VerificationMeta(
    'recoveryFailures',
  );
  late final GeneratedColumn<int> recoveryFailures = GeneratedColumn<int>(
    'recovery_failures',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (recovery_failures >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _recoveryLastFailureAtMeta =
      const VerificationMeta('recoveryLastFailureAt');
  late final GeneratedColumn<DateTime> recoveryLastFailureAt =
      GeneratedColumn<DateTime>(
        'recovery_last_failure_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recoveryVerifier,
    pinFailures,
    pinLastFailureAt,
    recoveryFailures,
    recoveryLastFailureAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'operator_access';
  @override
  VerificationContext validateIntegrity(
    Insertable<OperatorAccessRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('recovery_verifier')) {
      context.handle(
        _recoveryVerifierMeta,
        recoveryVerifier.isAcceptableOrUnknown(
          data['recovery_verifier']!,
          _recoveryVerifierMeta,
        ),
      );
    }
    if (data.containsKey('pin_failures')) {
      context.handle(
        _pinFailuresMeta,
        pinFailures.isAcceptableOrUnknown(
          data['pin_failures']!,
          _pinFailuresMeta,
        ),
      );
    }
    if (data.containsKey('pin_last_failure_at')) {
      context.handle(
        _pinLastFailureAtMeta,
        pinLastFailureAt.isAcceptableOrUnknown(
          data['pin_last_failure_at']!,
          _pinLastFailureAtMeta,
        ),
      );
    }
    if (data.containsKey('recovery_failures')) {
      context.handle(
        _recoveryFailuresMeta,
        recoveryFailures.isAcceptableOrUnknown(
          data['recovery_failures']!,
          _recoveryFailuresMeta,
        ),
      );
    }
    if (data.containsKey('recovery_last_failure_at')) {
      context.handle(
        _recoveryLastFailureAtMeta,
        recoveryLastFailureAt.isAcceptableOrUnknown(
          data['recovery_last_failure_at']!,
          _recoveryLastFailureAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OperatorAccessRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OperatorAccessRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      recoveryVerifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_verifier'],
      ),
      pinFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pin_failures'],
      )!,
      pinLastFailureAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pin_last_failure_at'],
      ),
      recoveryFailures: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovery_failures'],
      )!,
      recoveryLastFailureAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recovery_last_failure_at'],
      ),
    );
  }

  @override
  OperatorAccess createAlias(String alias) {
    return OperatorAccess(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class OperatorAccessRow extends DataClass
    implements Insertable<OperatorAccessRow> {
  final int id;
  final String? recoveryVerifier;
  final int pinFailures;
  final DateTime? pinLastFailureAt;
  final int recoveryFailures;
  final DateTime? recoveryLastFailureAt;
  const OperatorAccessRow({
    required this.id,
    this.recoveryVerifier,
    required this.pinFailures,
    this.pinLastFailureAt,
    required this.recoveryFailures,
    this.recoveryLastFailureAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || recoveryVerifier != null) {
      map['recovery_verifier'] = Variable<String>(recoveryVerifier);
    }
    map['pin_failures'] = Variable<int>(pinFailures);
    if (!nullToAbsent || pinLastFailureAt != null) {
      map['pin_last_failure_at'] = Variable<DateTime>(pinLastFailureAt);
    }
    map['recovery_failures'] = Variable<int>(recoveryFailures);
    if (!nullToAbsent || recoveryLastFailureAt != null) {
      map['recovery_last_failure_at'] = Variable<DateTime>(
        recoveryLastFailureAt,
      );
    }
    return map;
  }

  OperatorAccessCompanion toCompanion(bool nullToAbsent) {
    return OperatorAccessCompanion(
      id: Value(id),
      recoveryVerifier: recoveryVerifier == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryVerifier),
      pinFailures: Value(pinFailures),
      pinLastFailureAt: pinLastFailureAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinLastFailureAt),
      recoveryFailures: Value(recoveryFailures),
      recoveryLastFailureAt: recoveryLastFailureAt == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryLastFailureAt),
    );
  }

  factory OperatorAccessRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OperatorAccessRow(
      id: serializer.fromJson<int>(json['id']),
      recoveryVerifier: serializer.fromJson<String?>(json['recovery_verifier']),
      pinFailures: serializer.fromJson<int>(json['pin_failures']),
      pinLastFailureAt: serializer.fromJson<DateTime?>(
        json['pin_last_failure_at'],
      ),
      recoveryFailures: serializer.fromJson<int>(json['recovery_failures']),
      recoveryLastFailureAt: serializer.fromJson<DateTime?>(
        json['recovery_last_failure_at'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'recovery_verifier': serializer.toJson<String?>(recoveryVerifier),
      'pin_failures': serializer.toJson<int>(pinFailures),
      'pin_last_failure_at': serializer.toJson<DateTime?>(pinLastFailureAt),
      'recovery_failures': serializer.toJson<int>(recoveryFailures),
      'recovery_last_failure_at': serializer.toJson<DateTime?>(
        recoveryLastFailureAt,
      ),
    };
  }

  OperatorAccessRow copyWith({
    int? id,
    Value<String?> recoveryVerifier = const Value.absent(),
    int? pinFailures,
    Value<DateTime?> pinLastFailureAt = const Value.absent(),
    int? recoveryFailures,
    Value<DateTime?> recoveryLastFailureAt = const Value.absent(),
  }) => OperatorAccessRow(
    id: id ?? this.id,
    recoveryVerifier: recoveryVerifier.present
        ? recoveryVerifier.value
        : this.recoveryVerifier,
    pinFailures: pinFailures ?? this.pinFailures,
    pinLastFailureAt: pinLastFailureAt.present
        ? pinLastFailureAt.value
        : this.pinLastFailureAt,
    recoveryFailures: recoveryFailures ?? this.recoveryFailures,
    recoveryLastFailureAt: recoveryLastFailureAt.present
        ? recoveryLastFailureAt.value
        : this.recoveryLastFailureAt,
  );
  OperatorAccessRow copyWithCompanion(OperatorAccessCompanion data) {
    return OperatorAccessRow(
      id: data.id.present ? data.id.value : this.id,
      recoveryVerifier: data.recoveryVerifier.present
          ? data.recoveryVerifier.value
          : this.recoveryVerifier,
      pinFailures: data.pinFailures.present
          ? data.pinFailures.value
          : this.pinFailures,
      pinLastFailureAt: data.pinLastFailureAt.present
          ? data.pinLastFailureAt.value
          : this.pinLastFailureAt,
      recoveryFailures: data.recoveryFailures.present
          ? data.recoveryFailures.value
          : this.recoveryFailures,
      recoveryLastFailureAt: data.recoveryLastFailureAt.present
          ? data.recoveryLastFailureAt.value
          : this.recoveryLastFailureAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OperatorAccessRow(')
          ..write('id: $id, ')
          ..write('recoveryVerifier: $recoveryVerifier, ')
          ..write('pinFailures: $pinFailures, ')
          ..write('pinLastFailureAt: $pinLastFailureAt, ')
          ..write('recoveryFailures: $recoveryFailures, ')
          ..write('recoveryLastFailureAt: $recoveryLastFailureAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recoveryVerifier,
    pinFailures,
    pinLastFailureAt,
    recoveryFailures,
    recoveryLastFailureAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperatorAccessRow &&
          other.id == this.id &&
          other.recoveryVerifier == this.recoveryVerifier &&
          other.pinFailures == this.pinFailures &&
          other.pinLastFailureAt == this.pinLastFailureAt &&
          other.recoveryFailures == this.recoveryFailures &&
          other.recoveryLastFailureAt == this.recoveryLastFailureAt);
}

class OperatorAccessCompanion extends UpdateCompanion<OperatorAccessRow> {
  final Value<int> id;
  final Value<String?> recoveryVerifier;
  final Value<int> pinFailures;
  final Value<DateTime?> pinLastFailureAt;
  final Value<int> recoveryFailures;
  final Value<DateTime?> recoveryLastFailureAt;
  const OperatorAccessCompanion({
    this.id = const Value.absent(),
    this.recoveryVerifier = const Value.absent(),
    this.pinFailures = const Value.absent(),
    this.pinLastFailureAt = const Value.absent(),
    this.recoveryFailures = const Value.absent(),
    this.recoveryLastFailureAt = const Value.absent(),
  });
  OperatorAccessCompanion.insert({
    this.id = const Value.absent(),
    this.recoveryVerifier = const Value.absent(),
    this.pinFailures = const Value.absent(),
    this.pinLastFailureAt = const Value.absent(),
    this.recoveryFailures = const Value.absent(),
    this.recoveryLastFailureAt = const Value.absent(),
  });
  static Insertable<OperatorAccessRow> custom({
    Expression<int>? id,
    Expression<String>? recoveryVerifier,
    Expression<int>? pinFailures,
    Expression<DateTime>? pinLastFailureAt,
    Expression<int>? recoveryFailures,
    Expression<DateTime>? recoveryLastFailureAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recoveryVerifier != null) 'recovery_verifier': recoveryVerifier,
      if (pinFailures != null) 'pin_failures': pinFailures,
      if (pinLastFailureAt != null) 'pin_last_failure_at': pinLastFailureAt,
      if (recoveryFailures != null) 'recovery_failures': recoveryFailures,
      if (recoveryLastFailureAt != null)
        'recovery_last_failure_at': recoveryLastFailureAt,
    });
  }

  OperatorAccessCompanion copyWith({
    Value<int>? id,
    Value<String?>? recoveryVerifier,
    Value<int>? pinFailures,
    Value<DateTime?>? pinLastFailureAt,
    Value<int>? recoveryFailures,
    Value<DateTime?>? recoveryLastFailureAt,
  }) {
    return OperatorAccessCompanion(
      id: id ?? this.id,
      recoveryVerifier: recoveryVerifier ?? this.recoveryVerifier,
      pinFailures: pinFailures ?? this.pinFailures,
      pinLastFailureAt: pinLastFailureAt ?? this.pinLastFailureAt,
      recoveryFailures: recoveryFailures ?? this.recoveryFailures,
      recoveryLastFailureAt:
          recoveryLastFailureAt ?? this.recoveryLastFailureAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (recoveryVerifier.present) {
      map['recovery_verifier'] = Variable<String>(recoveryVerifier.value);
    }
    if (pinFailures.present) {
      map['pin_failures'] = Variable<int>(pinFailures.value);
    }
    if (pinLastFailureAt.present) {
      map['pin_last_failure_at'] = Variable<DateTime>(pinLastFailureAt.value);
    }
    if (recoveryFailures.present) {
      map['recovery_failures'] = Variable<int>(recoveryFailures.value);
    }
    if (recoveryLastFailureAt.present) {
      map['recovery_last_failure_at'] = Variable<DateTime>(
        recoveryLastFailureAt.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OperatorAccessCompanion(')
          ..write('id: $id, ')
          ..write('recoveryVerifier: $recoveryVerifier, ')
          ..write('pinFailures: $pinFailures, ')
          ..write('pinLastFailureAt: $pinLastFailureAt, ')
          ..write('recoveryFailures: $recoveryFailures, ')
          ..write('recoveryLastFailureAt: $recoveryLastFailureAt')
          ..write(')'))
        .toString();
  }
}

class Templates extends Table with TableInfo<Templates, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Templates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(trim(display_name)) BETWEEN 1 AND 80)',
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (category IS NULL OR length(category) <= 40)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    category,
    createdAt,
    updatedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  Templates createAlias(String alias) {
    return Templates(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final String id;
  final String displayName;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  const TemplateRow({
    required this.id,
    required this.displayName,
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      category: serializer.fromJson<String?>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      archivedAt: serializer.fromJson<DateTime?>(json['archived_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'display_name': serializer.toJson<String>(displayName),
      'category': serializer.toJson<String?>(category),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'archived_at': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  TemplateRow copyWith({
    String? id,
    String? displayName,
    Value<String?> category = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => TemplateRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    category: category.present ? category.value : this.category,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, category, createdAt, updatedAt, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.category == this.category &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.archivedAt == this.archivedAt);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String?> category;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    required String id,
    required String displayName,
    this.category = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String?>? category,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TemplateRevisions extends Table
    with TableInfo<TemplateRevisions, TemplateRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TemplateRevisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES templates(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _revisionNumberMeta = const VerificationMeta(
    'revisionNumber',
  );
  late final GeneratedColumn<int> revisionNumber = GeneratedColumn<int>(
    'revision_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (revision_number >= 1)',
  );
  static const VerificationMeta _documentSchemaVersionMeta =
      const VerificationMeta('documentSchemaVersion');
  late final GeneratedColumn<int> documentSchemaVersion = GeneratedColumn<int>(
    'document_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (document_schema_version >= 1)',
  );
  static const VerificationMeta _manifestPathMeta = const VerificationMeta(
    'manifestPath',
  );
  late final GeneratedColumn<String> manifestPath = GeneratedColumn<String>(
    'manifest_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(manifest_path) BETWEEN 1 AND 255 AND manifest_path NOT LIKE \'/%\' AND manifest_path NOT LIKE \'%..%\' AND instr(manifest_path, char(92)) = 0)',
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(checksum) = 64)',
  );
  static const VerificationMeta _pageWidthPxMeta = const VerificationMeta(
    'pageWidthPx',
  );
  late final GeneratedColumn<int> pageWidthPx = GeneratedColumn<int>(
    'page_width_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (page_width_px BETWEEN 1 AND 20000)',
  );
  static const VerificationMeta _pageHeightPxMeta = const VerificationMeta(
    'pageHeightPx',
  );
  late final GeneratedColumn<int> pageHeightPx = GeneratedColumn<int>(
    'page_height_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (page_height_px BETWEEN 1 AND 20000)',
  );
  static const VerificationMeta _photoSlotCountMeta = const VerificationMeta(
    'photoSlotCount',
  );
  late final GeneratedColumn<int> photoSlotCount = GeneratedColumn<int>(
    'photo_slot_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (photo_slot_count BETWEEN 0 AND 8)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    revisionNumber,
    documentSchemaVersion,
    manifestPath,
    checksum,
    pageWidthPx,
    pageHeightPx,
    photoSlotCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('revision_number')) {
      context.handle(
        _revisionNumberMeta,
        revisionNumber.isAcceptableOrUnknown(
          data['revision_number']!,
          _revisionNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_revisionNumberMeta);
    }
    if (data.containsKey('document_schema_version')) {
      context.handle(
        _documentSchemaVersionMeta,
        documentSchemaVersion.isAcceptableOrUnknown(
          data['document_schema_version']!,
          _documentSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentSchemaVersionMeta);
    }
    if (data.containsKey('manifest_path')) {
      context.handle(
        _manifestPathMeta,
        manifestPath.isAcceptableOrUnknown(
          data['manifest_path']!,
          _manifestPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_manifestPathMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('page_width_px')) {
      context.handle(
        _pageWidthPxMeta,
        pageWidthPx.isAcceptableOrUnknown(
          data['page_width_px']!,
          _pageWidthPxMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pageWidthPxMeta);
    }
    if (data.containsKey('page_height_px')) {
      context.handle(
        _pageHeightPxMeta,
        pageHeightPx.isAcceptableOrUnknown(
          data['page_height_px']!,
          _pageHeightPxMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pageHeightPxMeta);
    }
    if (data.containsKey('photo_slot_count')) {
      context.handle(
        _photoSlotCountMeta,
        photoSlotCount.isAcceptableOrUnknown(
          data['photo_slot_count']!,
          _photoSlotCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoSlotCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateId, revisionNumber},
  ];
  @override
  TemplateRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRevisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      revisionNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_number'],
      )!,
      documentSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}document_schema_version'],
      )!,
      manifestPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}manifest_path'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      pageWidthPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_width_px'],
      )!,
      pageHeightPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_height_px'],
      )!,
      photoSlotCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_slot_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  TemplateRevisions createAlias(String alias) {
    return TemplateRevisions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(template_id, revision_number)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TemplateRevisionRow extends DataClass
    implements Insertable<TemplateRevisionRow> {
  final String id;
  final String templateId;
  final int revisionNumber;
  final int documentSchemaVersion;
  final String manifestPath;
  final String checksum;
  final int pageWidthPx;
  final int pageHeightPx;
  final int photoSlotCount;
  final DateTime createdAt;
  const TemplateRevisionRow({
    required this.id,
    required this.templateId,
    required this.revisionNumber,
    required this.documentSchemaVersion,
    required this.manifestPath,
    required this.checksum,
    required this.pageWidthPx,
    required this.pageHeightPx,
    required this.photoSlotCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['revision_number'] = Variable<int>(revisionNumber);
    map['document_schema_version'] = Variable<int>(documentSchemaVersion);
    map['manifest_path'] = Variable<String>(manifestPath);
    map['checksum'] = Variable<String>(checksum);
    map['page_width_px'] = Variable<int>(pageWidthPx);
    map['page_height_px'] = Variable<int>(pageHeightPx);
    map['photo_slot_count'] = Variable<int>(photoSlotCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TemplateRevisionsCompanion toCompanion(bool nullToAbsent) {
    return TemplateRevisionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      revisionNumber: Value(revisionNumber),
      documentSchemaVersion: Value(documentSchemaVersion),
      manifestPath: Value(manifestPath),
      checksum: Value(checksum),
      pageWidthPx: Value(pageWidthPx),
      pageHeightPx: Value(pageHeightPx),
      photoSlotCount: Value(photoSlotCount),
      createdAt: Value(createdAt),
    );
  }

  factory TemplateRevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRevisionRow(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['template_id']),
      revisionNumber: serializer.fromJson<int>(json['revision_number']),
      documentSchemaVersion: serializer.fromJson<int>(
        json['document_schema_version'],
      ),
      manifestPath: serializer.fromJson<String>(json['manifest_path']),
      checksum: serializer.fromJson<String>(json['checksum']),
      pageWidthPx: serializer.fromJson<int>(json['page_width_px']),
      pageHeightPx: serializer.fromJson<int>(json['page_height_px']),
      photoSlotCount: serializer.fromJson<int>(json['photo_slot_count']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'template_id': serializer.toJson<String>(templateId),
      'revision_number': serializer.toJson<int>(revisionNumber),
      'document_schema_version': serializer.toJson<int>(documentSchemaVersion),
      'manifest_path': serializer.toJson<String>(manifestPath),
      'checksum': serializer.toJson<String>(checksum),
      'page_width_px': serializer.toJson<int>(pageWidthPx),
      'page_height_px': serializer.toJson<int>(pageHeightPx),
      'photo_slot_count': serializer.toJson<int>(photoSlotCount),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  TemplateRevisionRow copyWith({
    String? id,
    String? templateId,
    int? revisionNumber,
    int? documentSchemaVersion,
    String? manifestPath,
    String? checksum,
    int? pageWidthPx,
    int? pageHeightPx,
    int? photoSlotCount,
    DateTime? createdAt,
  }) => TemplateRevisionRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    revisionNumber: revisionNumber ?? this.revisionNumber,
    documentSchemaVersion: documentSchemaVersion ?? this.documentSchemaVersion,
    manifestPath: manifestPath ?? this.manifestPath,
    checksum: checksum ?? this.checksum,
    pageWidthPx: pageWidthPx ?? this.pageWidthPx,
    pageHeightPx: pageHeightPx ?? this.pageHeightPx,
    photoSlotCount: photoSlotCount ?? this.photoSlotCount,
    createdAt: createdAt ?? this.createdAt,
  );
  TemplateRevisionRow copyWithCompanion(TemplateRevisionsCompanion data) {
    return TemplateRevisionRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      revisionNumber: data.revisionNumber.present
          ? data.revisionNumber.value
          : this.revisionNumber,
      documentSchemaVersion: data.documentSchemaVersion.present
          ? data.documentSchemaVersion.value
          : this.documentSchemaVersion,
      manifestPath: data.manifestPath.present
          ? data.manifestPath.value
          : this.manifestPath,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      pageWidthPx: data.pageWidthPx.present
          ? data.pageWidthPx.value
          : this.pageWidthPx,
      pageHeightPx: data.pageHeightPx.present
          ? data.pageHeightPx.value
          : this.pageHeightPx,
      photoSlotCount: data.photoSlotCount.present
          ? data.photoSlotCount.value
          : this.photoSlotCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRevisionRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('revisionNumber: $revisionNumber, ')
          ..write('documentSchemaVersion: $documentSchemaVersion, ')
          ..write('manifestPath: $manifestPath, ')
          ..write('checksum: $checksum, ')
          ..write('pageWidthPx: $pageWidthPx, ')
          ..write('pageHeightPx: $pageHeightPx, ')
          ..write('photoSlotCount: $photoSlotCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    revisionNumber,
    documentSchemaVersion,
    manifestPath,
    checksum,
    pageWidthPx,
    pageHeightPx,
    photoSlotCount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRevisionRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.revisionNumber == this.revisionNumber &&
          other.documentSchemaVersion == this.documentSchemaVersion &&
          other.manifestPath == this.manifestPath &&
          other.checksum == this.checksum &&
          other.pageWidthPx == this.pageWidthPx &&
          other.pageHeightPx == this.pageHeightPx &&
          other.photoSlotCount == this.photoSlotCount &&
          other.createdAt == this.createdAt);
}

class TemplateRevisionsCompanion extends UpdateCompanion<TemplateRevisionRow> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<int> revisionNumber;
  final Value<int> documentSchemaVersion;
  final Value<String> manifestPath;
  final Value<String> checksum;
  final Value<int> pageWidthPx;
  final Value<int> pageHeightPx;
  final Value<int> photoSlotCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TemplateRevisionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.revisionNumber = const Value.absent(),
    this.documentSchemaVersion = const Value.absent(),
    this.manifestPath = const Value.absent(),
    this.checksum = const Value.absent(),
    this.pageWidthPx = const Value.absent(),
    this.pageHeightPx = const Value.absent(),
    this.photoSlotCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateRevisionsCompanion.insert({
    required String id,
    required String templateId,
    required int revisionNumber,
    required int documentSchemaVersion,
    required String manifestPath,
    required String checksum,
    required int pageWidthPx,
    required int pageHeightPx,
    required int photoSlotCount,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       revisionNumber = Value(revisionNumber),
       documentSchemaVersion = Value(documentSchemaVersion),
       manifestPath = Value(manifestPath),
       checksum = Value(checksum),
       pageWidthPx = Value(pageWidthPx),
       pageHeightPx = Value(pageHeightPx),
       photoSlotCount = Value(photoSlotCount),
       createdAt = Value(createdAt);
  static Insertable<TemplateRevisionRow> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<int>? revisionNumber,
    Expression<int>? documentSchemaVersion,
    Expression<String>? manifestPath,
    Expression<String>? checksum,
    Expression<int>? pageWidthPx,
    Expression<int>? pageHeightPx,
    Expression<int>? photoSlotCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (revisionNumber != null) 'revision_number': revisionNumber,
      if (documentSchemaVersion != null)
        'document_schema_version': documentSchemaVersion,
      if (manifestPath != null) 'manifest_path': manifestPath,
      if (checksum != null) 'checksum': checksum,
      if (pageWidthPx != null) 'page_width_px': pageWidthPx,
      if (pageHeightPx != null) 'page_height_px': pageHeightPx,
      if (photoSlotCount != null) 'photo_slot_count': photoSlotCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<int>? revisionNumber,
    Value<int>? documentSchemaVersion,
    Value<String>? manifestPath,
    Value<String>? checksum,
    Value<int>? pageWidthPx,
    Value<int>? pageHeightPx,
    Value<int>? photoSlotCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TemplateRevisionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      revisionNumber: revisionNumber ?? this.revisionNumber,
      documentSchemaVersion:
          documentSchemaVersion ?? this.documentSchemaVersion,
      manifestPath: manifestPath ?? this.manifestPath,
      checksum: checksum ?? this.checksum,
      pageWidthPx: pageWidthPx ?? this.pageWidthPx,
      pageHeightPx: pageHeightPx ?? this.pageHeightPx,
      photoSlotCount: photoSlotCount ?? this.photoSlotCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (revisionNumber.present) {
      map['revision_number'] = Variable<int>(revisionNumber.value);
    }
    if (documentSchemaVersion.present) {
      map['document_schema_version'] = Variable<int>(
        documentSchemaVersion.value,
      );
    }
    if (manifestPath.present) {
      map['manifest_path'] = Variable<String>(manifestPath.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (pageWidthPx.present) {
      map['page_width_px'] = Variable<int>(pageWidthPx.value);
    }
    if (pageHeightPx.present) {
      map['page_height_px'] = Variable<int>(pageHeightPx.value);
    }
    if (photoSlotCount.present) {
      map['photo_slot_count'] = Variable<int>(photoSlotCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('revisionNumber: $revisionNumber, ')
          ..write('documentSchemaVersion: $documentSchemaVersion, ')
          ..write('manifestPath: $manifestPath, ')
          ..write('checksum: $checksum, ')
          ..write('pageWidthPx: $pageWidthPx, ')
          ..write('pageHeightPx: $pageHeightPx, ')
          ..write('photoSlotCount: $photoSlotCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Assets extends Table with TableInfo<Assets, AssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Assets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 64 AND id NOT GLOB \'*[^0-9a-f]*\')',
  );
  late final GeneratedColumnWithTypeConverter<AssetMediaType, String>
  mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (media_type IN (\'png\', \'jpeg\', \'ttf\', \'otf\'))',
  ).withConverter<AssetMediaType>(Assets.$convertermediaType);
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (relative_path = \'assets/\' || id || \'.\' || CASE media_type WHEN \'png\' THEN \'png\' WHEN \'jpeg\' THEN \'jpg\' WHEN \'ttf\' THEN \'ttf\' WHEN \'otf\' THEN \'otf\' END)',
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_length BETWEEN 1 AND 52428800)',
  );
  static const VerificationMeta _widthPxMeta = const VerificationMeta(
    'widthPx',
  );
  late final GeneratedColumn<int> widthPx = GeneratedColumn<int>(
    'width_px',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (width_px IS NULL OR width_px BETWEEN 1 AND 12000)',
  );
  static const VerificationMeta _heightPxMeta = const VerificationMeta(
    'heightPx',
  );
  late final GeneratedColumn<int> heightPx = GeneratedColumn<int>(
    'height_px',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (height_px IS NULL OR height_px BETWEEN 1 AND 12000)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (display_name IS NULL OR length(display_name) BETWEEN 1 AND 120)',
  );
  late final GeneratedColumnWithTypeConverter<AssetOrigin, String>
  origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (origin IN (\'imported\', \'package\', \'bundled\'))',
  ).withConverter<AssetOrigin>(Assets.$converterorigin);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mediaType,
    relativePath,
    byteLength,
    widthPx,
    heightPx,
    displayName,
    origin,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('width_px')) {
      context.handle(
        _widthPxMeta,
        widthPx.isAcceptableOrUnknown(data['width_px']!, _widthPxMeta),
      );
    }
    if (data.containsKey('height_px')) {
      context.handle(
        _heightPxMeta,
        heightPx.isAcceptableOrUnknown(data['height_px']!, _heightPxMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mediaType: Assets.$convertermediaType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}media_type'],
        )!,
      ),
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      widthPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_px'],
      ),
      heightPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_px'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      origin: Assets.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Assets createAlias(String alias) {
    return Assets(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AssetMediaType, String, String>
  $convertermediaType = const EnumNameConverter<AssetMediaType>(
    AssetMediaType.values,
  );
  static JsonTypeConverter2<AssetOrigin, String, String> $converterorigin =
      const EnumNameConverter<AssetOrigin>(AssetOrigin.values);
  @override
  List<String> get customConstraints => const [
    'CHECK((media_type IN (\'png\', \'jpeg\'))=(width_px IS NOT NULL AND height_px IS NOT NULL))',
    'CHECK(media_type IN (\'png\', \'jpeg\') OR byte_length <= 20971520)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AssetRow extends DataClass implements Insertable<AssetRow> {
  final String id;
  final AssetMediaType mediaType;
  final String relativePath;
  final int byteLength;
  final int? widthPx;
  final int? heightPx;
  final String? displayName;
  final AssetOrigin origin;
  final DateTime createdAt;
  const AssetRow({
    required this.id,
    required this.mediaType,
    required this.relativePath,
    required this.byteLength,
    this.widthPx,
    this.heightPx,
    this.displayName,
    required this.origin,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['media_type'] = Variable<String>(
        Assets.$convertermediaType.toSql(mediaType),
      );
    }
    map['relative_path'] = Variable<String>(relativePath);
    map['byte_length'] = Variable<int>(byteLength);
    if (!nullToAbsent || widthPx != null) {
      map['width_px'] = Variable<int>(widthPx);
    }
    if (!nullToAbsent || heightPx != null) {
      map['height_px'] = Variable<int>(heightPx);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    {
      map['origin'] = Variable<String>(Assets.$converterorigin.toSql(origin));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      mediaType: Value(mediaType),
      relativePath: Value(relativePath),
      byteLength: Value(byteLength),
      widthPx: widthPx == null && nullToAbsent
          ? const Value.absent()
          : Value(widthPx),
      heightPx: heightPx == null && nullToAbsent
          ? const Value.absent()
          : Value(heightPx),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      origin: Value(origin),
      createdAt: Value(createdAt),
    );
  }

  factory AssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetRow(
      id: serializer.fromJson<String>(json['id']),
      mediaType: Assets.$convertermediaType.fromJson(
        serializer.fromJson<String>(json['media_type']),
      ),
      relativePath: serializer.fromJson<String>(json['relative_path']),
      byteLength: serializer.fromJson<int>(json['byte_length']),
      widthPx: serializer.fromJson<int?>(json['width_px']),
      heightPx: serializer.fromJson<int?>(json['height_px']),
      displayName: serializer.fromJson<String?>(json['display_name']),
      origin: Assets.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'media_type': serializer.toJson<String>(
        Assets.$convertermediaType.toJson(mediaType),
      ),
      'relative_path': serializer.toJson<String>(relativePath),
      'byte_length': serializer.toJson<int>(byteLength),
      'width_px': serializer.toJson<int?>(widthPx),
      'height_px': serializer.toJson<int?>(heightPx),
      'display_name': serializer.toJson<String?>(displayName),
      'origin': serializer.toJson<String>(
        Assets.$converterorigin.toJson(origin),
      ),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  AssetRow copyWith({
    String? id,
    AssetMediaType? mediaType,
    String? relativePath,
    int? byteLength,
    Value<int?> widthPx = const Value.absent(),
    Value<int?> heightPx = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    AssetOrigin? origin,
    DateTime? createdAt,
  }) => AssetRow(
    id: id ?? this.id,
    mediaType: mediaType ?? this.mediaType,
    relativePath: relativePath ?? this.relativePath,
    byteLength: byteLength ?? this.byteLength,
    widthPx: widthPx.present ? widthPx.value : this.widthPx,
    heightPx: heightPx.present ? heightPx.value : this.heightPx,
    displayName: displayName.present ? displayName.value : this.displayName,
    origin: origin ?? this.origin,
    createdAt: createdAt ?? this.createdAt,
  );
  AssetRow copyWithCompanion(AssetsCompanion data) {
    return AssetRow(
      id: data.id.present ? data.id.value : this.id,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      widthPx: data.widthPx.present ? data.widthPx.value : this.widthPx,
      heightPx: data.heightPx.present ? data.heightPx.value : this.heightPx,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      origin: data.origin.present ? data.origin.value : this.origin,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetRow(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('relativePath: $relativePath, ')
          ..write('byteLength: $byteLength, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('displayName: $displayName, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mediaType,
    relativePath,
    byteLength,
    widthPx,
    heightPx,
    displayName,
    origin,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRow &&
          other.id == this.id &&
          other.mediaType == this.mediaType &&
          other.relativePath == this.relativePath &&
          other.byteLength == this.byteLength &&
          other.widthPx == this.widthPx &&
          other.heightPx == this.heightPx &&
          other.displayName == this.displayName &&
          other.origin == this.origin &&
          other.createdAt == this.createdAt);
}

class AssetsCompanion extends UpdateCompanion<AssetRow> {
  final Value<String> id;
  final Value<AssetMediaType> mediaType;
  final Value<String> relativePath;
  final Value<int> byteLength;
  final Value<int?> widthPx;
  final Value<int?> heightPx;
  final Value<String?> displayName;
  final Value<AssetOrigin> origin;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.displayName = const Value.absent(),
    this.origin = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required AssetMediaType mediaType,
    required String relativePath,
    required int byteLength,
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.displayName = const Value.absent(),
    required AssetOrigin origin,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mediaType = Value(mediaType),
       relativePath = Value(relativePath),
       byteLength = Value(byteLength),
       origin = Value(origin),
       createdAt = Value(createdAt);
  static Insertable<AssetRow> custom({
    Expression<String>? id,
    Expression<String>? mediaType,
    Expression<String>? relativePath,
    Expression<int>? byteLength,
    Expression<int>? widthPx,
    Expression<int>? heightPx,
    Expression<String>? displayName,
    Expression<String>? origin,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaType != null) 'media_type': mediaType,
      if (relativePath != null) 'relative_path': relativePath,
      if (byteLength != null) 'byte_length': byteLength,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (displayName != null) 'display_name': displayName,
      if (origin != null) 'origin': origin,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<AssetMediaType>? mediaType,
    Value<String>? relativePath,
    Value<int>? byteLength,
    Value<int?>? widthPx,
    Value<int?>? heightPx,
    Value<String?>? displayName,
    Value<AssetOrigin>? origin,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      relativePath: relativePath ?? this.relativePath,
      byteLength: byteLength ?? this.byteLength,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      displayName: displayName ?? this.displayName,
      origin: origin ?? this.origin,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(
        Assets.$convertermediaType.toSql(mediaType.value),
      );
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (widthPx.present) {
      map['width_px'] = Variable<int>(widthPx.value);
    }
    if (heightPx.present) {
      map['height_px'] = Variable<int>(heightPx.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        Assets.$converterorigin.toSql(origin.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('relativePath: $relativePath, ')
          ..write('byteLength: $byteLength, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('displayName: $displayName, ')
          ..write('origin: $origin, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TemplateRevisionAssets extends Table
    with TableInfo<TemplateRevisionAssets, TemplateRevisionAssetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TemplateRevisionAssets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateRevisionIdMeta =
      const VerificationMeta('templateRevisionId');
  late final GeneratedColumn<String> templateRevisionId =
      GeneratedColumn<String>(
        'template_revision_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES template_revisions(id)ON DELETE CASCADE',
      );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES assets(id)ON DELETE RESTRICT',
  );
  @override
  List<GeneratedColumn> get $columns => [templateRevisionId, assetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_revision_assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRevisionAssetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_revision_id')) {
      context.handle(
        _templateRevisionIdMeta,
        templateRevisionId.isAcceptableOrUnknown(
          data['template_revision_id']!,
          _templateRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateRevisionIdMeta);
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateRevisionId, assetId};
  @override
  TemplateRevisionAssetRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRevisionAssetRow(
      templateRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_revision_id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
    );
  }

  @override
  TemplateRevisionAssets createAlias(String alias) {
    return TemplateRevisionAssets(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(template_revision_id, asset_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TemplateRevisionAssetRow extends DataClass
    implements Insertable<TemplateRevisionAssetRow> {
  final String templateRevisionId;
  final String assetId;
  const TemplateRevisionAssetRow({
    required this.templateRevisionId,
    required this.assetId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_revision_id'] = Variable<String>(templateRevisionId);
    map['asset_id'] = Variable<String>(assetId);
    return map;
  }

  TemplateRevisionAssetsCompanion toCompanion(bool nullToAbsent) {
    return TemplateRevisionAssetsCompanion(
      templateRevisionId: Value(templateRevisionId),
      assetId: Value(assetId),
    );
  }

  factory TemplateRevisionAssetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRevisionAssetRow(
      templateRevisionId: serializer.fromJson<String>(
        json['template_revision_id'],
      ),
      assetId: serializer.fromJson<String>(json['asset_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'template_revision_id': serializer.toJson<String>(templateRevisionId),
      'asset_id': serializer.toJson<String>(assetId),
    };
  }

  TemplateRevisionAssetRow copyWith({
    String? templateRevisionId,
    String? assetId,
  }) => TemplateRevisionAssetRow(
    templateRevisionId: templateRevisionId ?? this.templateRevisionId,
    assetId: assetId ?? this.assetId,
  );
  TemplateRevisionAssetRow copyWithCompanion(
    TemplateRevisionAssetsCompanion data,
  ) {
    return TemplateRevisionAssetRow(
      templateRevisionId: data.templateRevisionId.present
          ? data.templateRevisionId.value
          : this.templateRevisionId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRevisionAssetRow(')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('assetId: $assetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(templateRevisionId, assetId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRevisionAssetRow &&
          other.templateRevisionId == this.templateRevisionId &&
          other.assetId == this.assetId);
}

class TemplateRevisionAssetsCompanion
    extends UpdateCompanion<TemplateRevisionAssetRow> {
  final Value<String> templateRevisionId;
  final Value<String> assetId;
  final Value<int> rowid;
  const TemplateRevisionAssetsCompanion({
    this.templateRevisionId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateRevisionAssetsCompanion.insert({
    required String templateRevisionId,
    required String assetId,
    this.rowid = const Value.absent(),
  }) : templateRevisionId = Value(templateRevisionId),
       assetId = Value(assetId);
  static Insertable<TemplateRevisionAssetRow> custom({
    Expression<String>? templateRevisionId,
    Expression<String>? assetId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateRevisionId != null)
        'template_revision_id': templateRevisionId,
      if (assetId != null) 'asset_id': assetId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateRevisionAssetsCompanion copyWith({
    Value<String>? templateRevisionId,
    Value<String>? assetId,
    Value<int>? rowid,
  }) {
    return TemplateRevisionAssetsCompanion(
      templateRevisionId: templateRevisionId ?? this.templateRevisionId,
      assetId: assetId ?? this.assetId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateRevisionId.present) {
      map['template_revision_id'] = Variable<String>(templateRevisionId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRevisionAssetsCompanion(')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('assetId: $assetId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TemplateDrafts extends Table
    with TableInfo<TemplateDrafts, TemplateDraftRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TemplateDrafts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES templates(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _baseRevisionIdMeta = const VerificationMeta(
    'baseRevisionId',
  );
  late final GeneratedColumn<String> baseRevisionId = GeneratedColumn<String>(
    'base_revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES template_revisions(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _documentMeta = const VerificationMeta(
    'document',
  );
  late final GeneratedColumn<String> document = GeneratedColumn<String>(
    'document',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(document) BETWEEN 2 AND 1048576)',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    templateId,
    baseRevisionId,
    document,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateDraftRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('base_revision_id')) {
      context.handle(
        _baseRevisionIdMeta,
        baseRevisionId.isAcceptableOrUnknown(
          data['base_revision_id']!,
          _baseRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseRevisionIdMeta);
    }
    if (data.containsKey('document')) {
      context.handle(
        _documentMeta,
        document.isAcceptableOrUnknown(data['document']!, _documentMeta),
      );
    } else if (isInserting) {
      context.missing(_documentMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {templateId};
  @override
  TemplateDraftRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateDraftRow(
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      baseRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_revision_id'],
      )!,
      document: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  TemplateDrafts createAlias(String alias) {
    return TemplateDrafts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class TemplateDraftRow extends DataClass
    implements Insertable<TemplateDraftRow> {
  final String templateId;
  final String baseRevisionId;
  final String document;
  final DateTime updatedAt;
  const TemplateDraftRow({
    required this.templateId,
    required this.baseRevisionId,
    required this.document,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['template_id'] = Variable<String>(templateId);
    map['base_revision_id'] = Variable<String>(baseRevisionId);
    map['document'] = Variable<String>(document);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TemplateDraftsCompanion toCompanion(bool nullToAbsent) {
    return TemplateDraftsCompanion(
      templateId: Value(templateId),
      baseRevisionId: Value(baseRevisionId),
      document: Value(document),
      updatedAt: Value(updatedAt),
    );
  }

  factory TemplateDraftRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateDraftRow(
      templateId: serializer.fromJson<String>(json['template_id']),
      baseRevisionId: serializer.fromJson<String>(json['base_revision_id']),
      document: serializer.fromJson<String>(json['document']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'template_id': serializer.toJson<String>(templateId),
      'base_revision_id': serializer.toJson<String>(baseRevisionId),
      'document': serializer.toJson<String>(document),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TemplateDraftRow copyWith({
    String? templateId,
    String? baseRevisionId,
    String? document,
    DateTime? updatedAt,
  }) => TemplateDraftRow(
    templateId: templateId ?? this.templateId,
    baseRevisionId: baseRevisionId ?? this.baseRevisionId,
    document: document ?? this.document,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  TemplateDraftRow copyWithCompanion(TemplateDraftsCompanion data) {
    return TemplateDraftRow(
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      baseRevisionId: data.baseRevisionId.present
          ? data.baseRevisionId.value
          : this.baseRevisionId,
      document: data.document.present ? data.document.value : this.document,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateDraftRow(')
          ..write('templateId: $templateId, ')
          ..write('baseRevisionId: $baseRevisionId, ')
          ..write('document: $document, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(templateId, baseRevisionId, document, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateDraftRow &&
          other.templateId == this.templateId &&
          other.baseRevisionId == this.baseRevisionId &&
          other.document == this.document &&
          other.updatedAt == this.updatedAt);
}

class TemplateDraftsCompanion extends UpdateCompanion<TemplateDraftRow> {
  final Value<String> templateId;
  final Value<String> baseRevisionId;
  final Value<String> document;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TemplateDraftsCompanion({
    this.templateId = const Value.absent(),
    this.baseRevisionId = const Value.absent(),
    this.document = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateDraftsCompanion.insert({
    required String templateId,
    required String baseRevisionId,
    required String document,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : templateId = Value(templateId),
       baseRevisionId = Value(baseRevisionId),
       document = Value(document),
       updatedAt = Value(updatedAt);
  static Insertable<TemplateDraftRow> custom({
    Expression<String>? templateId,
    Expression<String>? baseRevisionId,
    Expression<String>? document,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (templateId != null) 'template_id': templateId,
      if (baseRevisionId != null) 'base_revision_id': baseRevisionId,
      if (document != null) 'document': document,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateDraftsCompanion copyWith({
    Value<String>? templateId,
    Value<String>? baseRevisionId,
    Value<String>? document,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TemplateDraftsCompanion(
      templateId: templateId ?? this.templateId,
      baseRevisionId: baseRevisionId ?? this.baseRevisionId,
      document: document ?? this.document,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (baseRevisionId.present) {
      map['base_revision_id'] = Variable<String>(baseRevisionId.value);
    }
    if (document.present) {
      map['document'] = Variable<String>(document.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateDraftsCompanion(')
          ..write('templateId: $templateId, ')
          ..write('baseRevisionId: $baseRevisionId, ')
          ..write('document: $document, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EventTemplates extends Table
    with TableInfo<EventTemplates, EventTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EventTemplates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES events(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _templateRevisionIdMeta =
      const VerificationMeta('templateRevisionId');
  late final GeneratedColumn<String> templateRevisionId =
      GeneratedColumn<String>(
        'template_revision_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES template_revisions(id)ON DELETE RESTRICT',
      );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (position BETWEEN 0 AND 11)',
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (is_default IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    templateRevisionId,
    position,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('template_revision_id')) {
      context.handle(
        _templateRevisionIdMeta,
        templateRevisionId.isAcceptableOrUnknown(
          data['template_revision_id']!,
          _templateRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateRevisionIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, templateRevisionId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {eventId, position},
  ];
  @override
  EventTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventTemplateRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      templateRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_revision_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  EventTemplates createAlias(String alias) {
    return EventTemplates(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(event_id, template_revision_id)',
    'UNIQUE(event_id, position)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class EventTemplateRow extends DataClass
    implements Insertable<EventTemplateRow> {
  final String eventId;
  final String templateRevisionId;
  final int position;
  final bool isDefault;
  const EventTemplateRow({
    required this.eventId,
    required this.templateRevisionId,
    required this.position,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['template_revision_id'] = Variable<String>(templateRevisionId);
    map['position'] = Variable<int>(position);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  EventTemplatesCompanion toCompanion(bool nullToAbsent) {
    return EventTemplatesCompanion(
      eventId: Value(eventId),
      templateRevisionId: Value(templateRevisionId),
      position: Value(position),
      isDefault: Value(isDefault),
    );
  }

  factory EventTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventTemplateRow(
      eventId: serializer.fromJson<String>(json['event_id']),
      templateRevisionId: serializer.fromJson<String>(
        json['template_revision_id'],
      ),
      position: serializer.fromJson<int>(json['position']),
      isDefault: serializer.fromJson<bool>(json['is_default']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'event_id': serializer.toJson<String>(eventId),
      'template_revision_id': serializer.toJson<String>(templateRevisionId),
      'position': serializer.toJson<int>(position),
      'is_default': serializer.toJson<bool>(isDefault),
    };
  }

  EventTemplateRow copyWith({
    String? eventId,
    String? templateRevisionId,
    int? position,
    bool? isDefault,
  }) => EventTemplateRow(
    eventId: eventId ?? this.eventId,
    templateRevisionId: templateRevisionId ?? this.templateRevisionId,
    position: position ?? this.position,
    isDefault: isDefault ?? this.isDefault,
  );
  EventTemplateRow copyWithCompanion(EventTemplatesCompanion data) {
    return EventTemplateRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      templateRevisionId: data.templateRevisionId.present
          ? data.templateRevisionId.value
          : this.templateRevisionId,
      position: data.position.present ? data.position.value : this.position,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventTemplateRow(')
          ..write('eventId: $eventId, ')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('position: $position, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(eventId, templateRevisionId, position, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventTemplateRow &&
          other.eventId == this.eventId &&
          other.templateRevisionId == this.templateRevisionId &&
          other.position == this.position &&
          other.isDefault == this.isDefault);
}

class EventTemplatesCompanion extends UpdateCompanion<EventTemplateRow> {
  final Value<String> eventId;
  final Value<String> templateRevisionId;
  final Value<int> position;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const EventTemplatesCompanion({
    this.eventId = const Value.absent(),
    this.templateRevisionId = const Value.absent(),
    this.position = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventTemplatesCompanion.insert({
    required String eventId,
    required String templateRevisionId,
    required int position,
    required bool isDefault,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       templateRevisionId = Value(templateRevisionId),
       position = Value(position),
       isDefault = Value(isDefault);
  static Insertable<EventTemplateRow> custom({
    Expression<String>? eventId,
    Expression<String>? templateRevisionId,
    Expression<int>? position,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (templateRevisionId != null)
        'template_revision_id': templateRevisionId,
      if (position != null) 'position': position,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventTemplatesCompanion copyWith({
    Value<String>? eventId,
    Value<String>? templateRevisionId,
    Value<int>? position,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return EventTemplatesCompanion(
      eventId: eventId ?? this.eventId,
      templateRevisionId: templateRevisionId ?? this.templateRevisionId,
      position: position ?? this.position,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (templateRevisionId.present) {
      map['template_revision_id'] = Variable<String>(templateRevisionId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventTemplatesCompanion(')
          ..write('eventId: $eventId, ')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('position: $position, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class OriginalPhotos extends Table
    with TableInfo<OriginalPhotos, OriginalPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OriginalPhotos(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) BETWEEN 1 AND 64 AND id NOT GLOB \'*[^0-9A-Za-z-]*\')',
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (relative_path = \'originals/\' || id || \'.jpg\')',
  );
  static const VerificationMeta _widthPxMeta = const VerificationMeta(
    'widthPx',
  );
  late final GeneratedColumn<int> widthPx = GeneratedColumn<int>(
    'width_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (width_px BETWEEN 1 AND 20000)',
  );
  static const VerificationMeta _heightPxMeta = const VerificationMeta(
    'heightPx',
  );
  late final GeneratedColumn<int> heightPx = GeneratedColumn<int>(
    'height_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (height_px BETWEEN 1 AND 20000)',
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_length BETWEEN 1 AND 104857600)',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sha256) = 64 AND sha256 NOT GLOB \'*[^0-9a-f]*\')',
  );
  late final GeneratedColumnWithTypeConverter<CameraLens, String> lens =
      GeneratedColumn<String>(
        'lens',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (lens IN (\'front\', \'back\', \'external\'))',
      ).withConverter<CameraLens>(OriginalPhotos.$converterlens);
  static const VerificationMeta _sensorOrientationMeta = const VerificationMeta(
    'sensorOrientation',
  );
  late final GeneratedColumn<int> sensorOrientation = GeneratedColumn<int>(
    'sensor_orientation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (sensor_orientation IN (0, 90, 180, 270))',
  );
  late final GeneratedColumnWithTypeConverter<CaptureOrientation, String>
  deviceOrientation =
      GeneratedColumn<String>(
        'device_orientation',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (device_orientation IN (\'portraitUp\', \'landscapeLeft\', \'portraitDown\', \'landscapeRight\', \'unknown\'))',
      ).withConverter<CaptureOrientation>(
        OriginalPhotos.$converterdeviceOrientation,
      );
  static const VerificationMeta _exifOrientationMeta = const VerificationMeta(
    'exifOrientation',
  );
  late final GeneratedColumn<int> exifOrientation = GeneratedColumn<int>(
    'exif_orientation',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (exif_orientation IS NULL OR exif_orientation BETWEEN 1 AND 8)',
  );
  static const VerificationMeta _mirrorPreviewMeta = const VerificationMeta(
    'mirrorPreview',
  );
  late final GeneratedColumn<bool> mirrorPreview = GeneratedColumn<bool>(
    'mirror_preview',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mirror_preview IN (0, 1))',
  );
  static const VerificationMeta _mirrorOutputMeta = const VerificationMeta(
    'mirrorOutput',
  );
  late final GeneratedColumn<bool> mirrorOutput = GeneratedColumn<bool>(
    'mirror_output',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mirror_output IN (0, 1))',
  );
  late final GeneratedColumnWithTypeConverter<CaptureOrigin, String>
  origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (origin IN (\'diagnostics\', \'session\', \'legacy\'))',
  ).withConverter<CaptureOrigin>(OriginalPhotos.$converterorigin);
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _committedAtMeta = const VerificationMeta(
    'committedAt',
  );
  late final GeneratedColumn<DateTime> committedAt = GeneratedColumn<DateTime>(
    'committed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    relativePath,
    widthPx,
    heightPx,
    byteLength,
    sha256,
    lens,
    sensorOrientation,
    deviceOrientation,
    exifOrientation,
    mirrorPreview,
    mirrorOutput,
    origin,
    capturedAt,
    committedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'original_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<OriginalPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('width_px')) {
      context.handle(
        _widthPxMeta,
        widthPx.isAcceptableOrUnknown(data['width_px']!, _widthPxMeta),
      );
    } else if (isInserting) {
      context.missing(_widthPxMeta);
    }
    if (data.containsKey('height_px')) {
      context.handle(
        _heightPxMeta,
        heightPx.isAcceptableOrUnknown(data['height_px']!, _heightPxMeta),
      );
    } else if (isInserting) {
      context.missing(_heightPxMeta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('sensor_orientation')) {
      context.handle(
        _sensorOrientationMeta,
        sensorOrientation.isAcceptableOrUnknown(
          data['sensor_orientation']!,
          _sensorOrientationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sensorOrientationMeta);
    }
    if (data.containsKey('exif_orientation')) {
      context.handle(
        _exifOrientationMeta,
        exifOrientation.isAcceptableOrUnknown(
          data['exif_orientation']!,
          _exifOrientationMeta,
        ),
      );
    }
    if (data.containsKey('mirror_preview')) {
      context.handle(
        _mirrorPreviewMeta,
        mirrorPreview.isAcceptableOrUnknown(
          data['mirror_preview']!,
          _mirrorPreviewMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mirrorPreviewMeta);
    }
    if (data.containsKey('mirror_output')) {
      context.handle(
        _mirrorOutputMeta,
        mirrorOutput.isAcceptableOrUnknown(
          data['mirror_output']!,
          _mirrorOutputMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mirrorOutputMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('committed_at')) {
      context.handle(
        _committedAtMeta,
        committedAt.isAcceptableOrUnknown(
          data['committed_at']!,
          _committedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_committedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OriginalPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OriginalPhotoRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      widthPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_px'],
      )!,
      heightPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_px'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      lens: OriginalPhotos.$converterlens.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}lens'],
        )!,
      ),
      sensorOrientation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sensor_orientation'],
      )!,
      deviceOrientation: OriginalPhotos.$converterdeviceOrientation.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}device_orientation'],
        )!,
      ),
      exifOrientation: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exif_orientation'],
      ),
      mirrorPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mirror_preview'],
      )!,
      mirrorOutput: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}mirror_output'],
      )!,
      origin: OriginalPhotos.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      committedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}committed_at'],
      )!,
    );
  }

  @override
  OriginalPhotos createAlias(String alias) {
    return OriginalPhotos(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CameraLens, String, String> $converterlens =
      const EnumNameConverter<CameraLens>(CameraLens.values);
  static JsonTypeConverter2<CaptureOrientation, String, String>
  $converterdeviceOrientation = const EnumNameConverter<CaptureOrientation>(
    CaptureOrientation.values,
  );
  static JsonTypeConverter2<CaptureOrigin, String, String> $converterorigin =
      const EnumNameConverter<CaptureOrigin>(CaptureOrigin.values);
  @override
  bool get dontWriteConstraints => true;
}

class OriginalPhotoRow extends DataClass
    implements Insertable<OriginalPhotoRow> {
  final String id;
  final String relativePath;
  final int widthPx;
  final int heightPx;
  final int byteLength;
  final String sha256;
  final CameraLens lens;
  final int sensorOrientation;
  final CaptureOrientation deviceOrientation;
  final int? exifOrientation;
  final bool mirrorPreview;
  final bool mirrorOutput;
  final CaptureOrigin origin;
  final DateTime capturedAt;
  final DateTime committedAt;
  const OriginalPhotoRow({
    required this.id,
    required this.relativePath,
    required this.widthPx,
    required this.heightPx,
    required this.byteLength,
    required this.sha256,
    required this.lens,
    required this.sensorOrientation,
    required this.deviceOrientation,
    this.exifOrientation,
    required this.mirrorPreview,
    required this.mirrorOutput,
    required this.origin,
    required this.capturedAt,
    required this.committedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['relative_path'] = Variable<String>(relativePath);
    map['width_px'] = Variable<int>(widthPx);
    map['height_px'] = Variable<int>(heightPx);
    map['byte_length'] = Variable<int>(byteLength);
    map['sha256'] = Variable<String>(sha256);
    {
      map['lens'] = Variable<String>(OriginalPhotos.$converterlens.toSql(lens));
    }
    map['sensor_orientation'] = Variable<int>(sensorOrientation);
    {
      map['device_orientation'] = Variable<String>(
        OriginalPhotos.$converterdeviceOrientation.toSql(deviceOrientation),
      );
    }
    if (!nullToAbsent || exifOrientation != null) {
      map['exif_orientation'] = Variable<int>(exifOrientation);
    }
    map['mirror_preview'] = Variable<bool>(mirrorPreview);
    map['mirror_output'] = Variable<bool>(mirrorOutput);
    {
      map['origin'] = Variable<String>(
        OriginalPhotos.$converterorigin.toSql(origin),
      );
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['committed_at'] = Variable<DateTime>(committedAt);
    return map;
  }

  OriginalPhotosCompanion toCompanion(bool nullToAbsent) {
    return OriginalPhotosCompanion(
      id: Value(id),
      relativePath: Value(relativePath),
      widthPx: Value(widthPx),
      heightPx: Value(heightPx),
      byteLength: Value(byteLength),
      sha256: Value(sha256),
      lens: Value(lens),
      sensorOrientation: Value(sensorOrientation),
      deviceOrientation: Value(deviceOrientation),
      exifOrientation: exifOrientation == null && nullToAbsent
          ? const Value.absent()
          : Value(exifOrientation),
      mirrorPreview: Value(mirrorPreview),
      mirrorOutput: Value(mirrorOutput),
      origin: Value(origin),
      capturedAt: Value(capturedAt),
      committedAt: Value(committedAt),
    );
  }

  factory OriginalPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OriginalPhotoRow(
      id: serializer.fromJson<String>(json['id']),
      relativePath: serializer.fromJson<String>(json['relative_path']),
      widthPx: serializer.fromJson<int>(json['width_px']),
      heightPx: serializer.fromJson<int>(json['height_px']),
      byteLength: serializer.fromJson<int>(json['byte_length']),
      sha256: serializer.fromJson<String>(json['sha256']),
      lens: OriginalPhotos.$converterlens.fromJson(
        serializer.fromJson<String>(json['lens']),
      ),
      sensorOrientation: serializer.fromJson<int>(json['sensor_orientation']),
      deviceOrientation: OriginalPhotos.$converterdeviceOrientation.fromJson(
        serializer.fromJson<String>(json['device_orientation']),
      ),
      exifOrientation: serializer.fromJson<int?>(json['exif_orientation']),
      mirrorPreview: serializer.fromJson<bool>(json['mirror_preview']),
      mirrorOutput: serializer.fromJson<bool>(json['mirror_output']),
      origin: OriginalPhotos.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
      capturedAt: serializer.fromJson<DateTime>(json['captured_at']),
      committedAt: serializer.fromJson<DateTime>(json['committed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'relative_path': serializer.toJson<String>(relativePath),
      'width_px': serializer.toJson<int>(widthPx),
      'height_px': serializer.toJson<int>(heightPx),
      'byte_length': serializer.toJson<int>(byteLength),
      'sha256': serializer.toJson<String>(sha256),
      'lens': serializer.toJson<String>(
        OriginalPhotos.$converterlens.toJson(lens),
      ),
      'sensor_orientation': serializer.toJson<int>(sensorOrientation),
      'device_orientation': serializer.toJson<String>(
        OriginalPhotos.$converterdeviceOrientation.toJson(deviceOrientation),
      ),
      'exif_orientation': serializer.toJson<int?>(exifOrientation),
      'mirror_preview': serializer.toJson<bool>(mirrorPreview),
      'mirror_output': serializer.toJson<bool>(mirrorOutput),
      'origin': serializer.toJson<String>(
        OriginalPhotos.$converterorigin.toJson(origin),
      ),
      'captured_at': serializer.toJson<DateTime>(capturedAt),
      'committed_at': serializer.toJson<DateTime>(committedAt),
    };
  }

  OriginalPhotoRow copyWith({
    String? id,
    String? relativePath,
    int? widthPx,
    int? heightPx,
    int? byteLength,
    String? sha256,
    CameraLens? lens,
    int? sensorOrientation,
    CaptureOrientation? deviceOrientation,
    Value<int?> exifOrientation = const Value.absent(),
    bool? mirrorPreview,
    bool? mirrorOutput,
    CaptureOrigin? origin,
    DateTime? capturedAt,
    DateTime? committedAt,
  }) => OriginalPhotoRow(
    id: id ?? this.id,
    relativePath: relativePath ?? this.relativePath,
    widthPx: widthPx ?? this.widthPx,
    heightPx: heightPx ?? this.heightPx,
    byteLength: byteLength ?? this.byteLength,
    sha256: sha256 ?? this.sha256,
    lens: lens ?? this.lens,
    sensorOrientation: sensorOrientation ?? this.sensorOrientation,
    deviceOrientation: deviceOrientation ?? this.deviceOrientation,
    exifOrientation: exifOrientation.present
        ? exifOrientation.value
        : this.exifOrientation,
    mirrorPreview: mirrorPreview ?? this.mirrorPreview,
    mirrorOutput: mirrorOutput ?? this.mirrorOutput,
    origin: origin ?? this.origin,
    capturedAt: capturedAt ?? this.capturedAt,
    committedAt: committedAt ?? this.committedAt,
  );
  OriginalPhotoRow copyWithCompanion(OriginalPhotosCompanion data) {
    return OriginalPhotoRow(
      id: data.id.present ? data.id.value : this.id,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      widthPx: data.widthPx.present ? data.widthPx.value : this.widthPx,
      heightPx: data.heightPx.present ? data.heightPx.value : this.heightPx,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      lens: data.lens.present ? data.lens.value : this.lens,
      sensorOrientation: data.sensorOrientation.present
          ? data.sensorOrientation.value
          : this.sensorOrientation,
      deviceOrientation: data.deviceOrientation.present
          ? data.deviceOrientation.value
          : this.deviceOrientation,
      exifOrientation: data.exifOrientation.present
          ? data.exifOrientation.value
          : this.exifOrientation,
      mirrorPreview: data.mirrorPreview.present
          ? data.mirrorPreview.value
          : this.mirrorPreview,
      mirrorOutput: data.mirrorOutput.present
          ? data.mirrorOutput.value
          : this.mirrorOutput,
      origin: data.origin.present ? data.origin.value : this.origin,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      committedAt: data.committedAt.present
          ? data.committedAt.value
          : this.committedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OriginalPhotoRow(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('byteLength: $byteLength, ')
          ..write('sha256: $sha256, ')
          ..write('lens: $lens, ')
          ..write('sensorOrientation: $sensorOrientation, ')
          ..write('deviceOrientation: $deviceOrientation, ')
          ..write('exifOrientation: $exifOrientation, ')
          ..write('mirrorPreview: $mirrorPreview, ')
          ..write('mirrorOutput: $mirrorOutput, ')
          ..write('origin: $origin, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('committedAt: $committedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    relativePath,
    widthPx,
    heightPx,
    byteLength,
    sha256,
    lens,
    sensorOrientation,
    deviceOrientation,
    exifOrientation,
    mirrorPreview,
    mirrorOutput,
    origin,
    capturedAt,
    committedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OriginalPhotoRow &&
          other.id == this.id &&
          other.relativePath == this.relativePath &&
          other.widthPx == this.widthPx &&
          other.heightPx == this.heightPx &&
          other.byteLength == this.byteLength &&
          other.sha256 == this.sha256 &&
          other.lens == this.lens &&
          other.sensorOrientation == this.sensorOrientation &&
          other.deviceOrientation == this.deviceOrientation &&
          other.exifOrientation == this.exifOrientation &&
          other.mirrorPreview == this.mirrorPreview &&
          other.mirrorOutput == this.mirrorOutput &&
          other.origin == this.origin &&
          other.capturedAt == this.capturedAt &&
          other.committedAt == this.committedAt);
}

class OriginalPhotosCompanion extends UpdateCompanion<OriginalPhotoRow> {
  final Value<String> id;
  final Value<String> relativePath;
  final Value<int> widthPx;
  final Value<int> heightPx;
  final Value<int> byteLength;
  final Value<String> sha256;
  final Value<CameraLens> lens;
  final Value<int> sensorOrientation;
  final Value<CaptureOrientation> deviceOrientation;
  final Value<int?> exifOrientation;
  final Value<bool> mirrorPreview;
  final Value<bool> mirrorOutput;
  final Value<CaptureOrigin> origin;
  final Value<DateTime> capturedAt;
  final Value<DateTime> committedAt;
  final Value<int> rowid;
  const OriginalPhotosCompanion({
    this.id = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.lens = const Value.absent(),
    this.sensorOrientation = const Value.absent(),
    this.deviceOrientation = const Value.absent(),
    this.exifOrientation = const Value.absent(),
    this.mirrorPreview = const Value.absent(),
    this.mirrorOutput = const Value.absent(),
    this.origin = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.committedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OriginalPhotosCompanion.insert({
    required String id,
    required String relativePath,
    required int widthPx,
    required int heightPx,
    required int byteLength,
    required String sha256,
    required CameraLens lens,
    required int sensorOrientation,
    required CaptureOrientation deviceOrientation,
    this.exifOrientation = const Value.absent(),
    required bool mirrorPreview,
    required bool mirrorOutput,
    required CaptureOrigin origin,
    required DateTime capturedAt,
    required DateTime committedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       relativePath = Value(relativePath),
       widthPx = Value(widthPx),
       heightPx = Value(heightPx),
       byteLength = Value(byteLength),
       sha256 = Value(sha256),
       lens = Value(lens),
       sensorOrientation = Value(sensorOrientation),
       deviceOrientation = Value(deviceOrientation),
       mirrorPreview = Value(mirrorPreview),
       mirrorOutput = Value(mirrorOutput),
       origin = Value(origin),
       capturedAt = Value(capturedAt),
       committedAt = Value(committedAt);
  static Insertable<OriginalPhotoRow> custom({
    Expression<String>? id,
    Expression<String>? relativePath,
    Expression<int>? widthPx,
    Expression<int>? heightPx,
    Expression<int>? byteLength,
    Expression<String>? sha256,
    Expression<String>? lens,
    Expression<int>? sensorOrientation,
    Expression<String>? deviceOrientation,
    Expression<int>? exifOrientation,
    Expression<bool>? mirrorPreview,
    Expression<bool>? mirrorOutput,
    Expression<String>? origin,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? committedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (relativePath != null) 'relative_path': relativePath,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (byteLength != null) 'byte_length': byteLength,
      if (sha256 != null) 'sha256': sha256,
      if (lens != null) 'lens': lens,
      if (sensorOrientation != null) 'sensor_orientation': sensorOrientation,
      if (deviceOrientation != null) 'device_orientation': deviceOrientation,
      if (exifOrientation != null) 'exif_orientation': exifOrientation,
      if (mirrorPreview != null) 'mirror_preview': mirrorPreview,
      if (mirrorOutput != null) 'mirror_output': mirrorOutput,
      if (origin != null) 'origin': origin,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (committedAt != null) 'committed_at': committedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OriginalPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? relativePath,
    Value<int>? widthPx,
    Value<int>? heightPx,
    Value<int>? byteLength,
    Value<String>? sha256,
    Value<CameraLens>? lens,
    Value<int>? sensorOrientation,
    Value<CaptureOrientation>? deviceOrientation,
    Value<int?>? exifOrientation,
    Value<bool>? mirrorPreview,
    Value<bool>? mirrorOutput,
    Value<CaptureOrigin>? origin,
    Value<DateTime>? capturedAt,
    Value<DateTime>? committedAt,
    Value<int>? rowid,
  }) {
    return OriginalPhotosCompanion(
      id: id ?? this.id,
      relativePath: relativePath ?? this.relativePath,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      byteLength: byteLength ?? this.byteLength,
      sha256: sha256 ?? this.sha256,
      lens: lens ?? this.lens,
      sensorOrientation: sensorOrientation ?? this.sensorOrientation,
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      exifOrientation: exifOrientation ?? this.exifOrientation,
      mirrorPreview: mirrorPreview ?? this.mirrorPreview,
      mirrorOutput: mirrorOutput ?? this.mirrorOutput,
      origin: origin ?? this.origin,
      capturedAt: capturedAt ?? this.capturedAt,
      committedAt: committedAt ?? this.committedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (widthPx.present) {
      map['width_px'] = Variable<int>(widthPx.value);
    }
    if (heightPx.present) {
      map['height_px'] = Variable<int>(heightPx.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (lens.present) {
      map['lens'] = Variable<String>(
        OriginalPhotos.$converterlens.toSql(lens.value),
      );
    }
    if (sensorOrientation.present) {
      map['sensor_orientation'] = Variable<int>(sensorOrientation.value);
    }
    if (deviceOrientation.present) {
      map['device_orientation'] = Variable<String>(
        OriginalPhotos.$converterdeviceOrientation.toSql(
          deviceOrientation.value,
        ),
      );
    }
    if (exifOrientation.present) {
      map['exif_orientation'] = Variable<int>(exifOrientation.value);
    }
    if (mirrorPreview.present) {
      map['mirror_preview'] = Variable<bool>(mirrorPreview.value);
    }
    if (mirrorOutput.present) {
      map['mirror_output'] = Variable<bool>(mirrorOutput.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        OriginalPhotos.$converterorigin.toSql(origin.value),
      );
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (committedAt.present) {
      map['committed_at'] = Variable<DateTime>(committedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OriginalPhotosCompanion(')
          ..write('id: $id, ')
          ..write('relativePath: $relativePath, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('byteLength: $byteLength, ')
          ..write('sha256: $sha256, ')
          ..write('lens: $lens, ')
          ..write('sensorOrientation: $sensorOrientation, ')
          ..write('deviceOrientation: $deviceOrientation, ')
          ..write('exifOrientation: $exifOrientation, ')
          ..write('mirrorPreview: $mirrorPreview, ')
          ..write('mirrorOutput: $mirrorOutput, ')
          ..write('origin: $origin, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('committedAt: $committedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PendingOriginalCommits extends Table
    with TableInfo<PendingOriginalCommits, PendingOriginalCommitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PendingOriginalCommits(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) BETWEEN 1 AND 64 AND id NOT GLOB \'*[^0-9A-Za-z-]*\')',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sha256) = 64 AND sha256 NOT GLOB \'*[^0-9a-f]*\')',
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_length >= 1)',
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(metadata) BETWEEN 2 AND 65536)',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sha256,
    byteLength,
    metadata,
    startedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_original_commits';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOriginalCommitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    } else if (isInserting) {
      context.missing(_metadataMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOriginalCommitRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOriginalCommitRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  PendingOriginalCommits createAlias(String alias) {
    return PendingOriginalCommits(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PendingOriginalCommitRow extends DataClass
    implements Insertable<PendingOriginalCommitRow> {
  final String id;
  final String sha256;
  final int byteLength;
  final String metadata;
  final DateTime startedAt;
  const PendingOriginalCommitRow({
    required this.id,
    required this.sha256,
    required this.byteLength,
    required this.metadata,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sha256'] = Variable<String>(sha256);
    map['byte_length'] = Variable<int>(byteLength);
    map['metadata'] = Variable<String>(metadata);
    map['started_at'] = Variable<DateTime>(startedAt);
    return map;
  }

  PendingOriginalCommitsCompanion toCompanion(bool nullToAbsent) {
    return PendingOriginalCommitsCompanion(
      id: Value(id),
      sha256: Value(sha256),
      byteLength: Value(byteLength),
      metadata: Value(metadata),
      startedAt: Value(startedAt),
    );
  }

  factory PendingOriginalCommitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOriginalCommitRow(
      id: serializer.fromJson<String>(json['id']),
      sha256: serializer.fromJson<String>(json['sha256']),
      byteLength: serializer.fromJson<int>(json['byte_length']),
      metadata: serializer.fromJson<String>(json['metadata']),
      startedAt: serializer.fromJson<DateTime>(json['started_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sha256': serializer.toJson<String>(sha256),
      'byte_length': serializer.toJson<int>(byteLength),
      'metadata': serializer.toJson<String>(metadata),
      'started_at': serializer.toJson<DateTime>(startedAt),
    };
  }

  PendingOriginalCommitRow copyWith({
    String? id,
    String? sha256,
    int? byteLength,
    String? metadata,
    DateTime? startedAt,
  }) => PendingOriginalCommitRow(
    id: id ?? this.id,
    sha256: sha256 ?? this.sha256,
    byteLength: byteLength ?? this.byteLength,
    metadata: metadata ?? this.metadata,
    startedAt: startedAt ?? this.startedAt,
  );
  PendingOriginalCommitRow copyWithCompanion(
    PendingOriginalCommitsCompanion data,
  ) {
    return PendingOriginalCommitRow(
      id: data.id.present ? data.id.value : this.id,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOriginalCommitRow(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('byteLength: $byteLength, ')
          ..write('metadata: $metadata, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sha256, byteLength, metadata, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOriginalCommitRow &&
          other.id == this.id &&
          other.sha256 == this.sha256 &&
          other.byteLength == this.byteLength &&
          other.metadata == this.metadata &&
          other.startedAt == this.startedAt);
}

class PendingOriginalCommitsCompanion
    extends UpdateCompanion<PendingOriginalCommitRow> {
  final Value<String> id;
  final Value<String> sha256;
  final Value<int> byteLength;
  final Value<String> metadata;
  final Value<DateTime> startedAt;
  final Value<int> rowid;
  const PendingOriginalCommitsCompanion({
    this.id = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.metadata = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingOriginalCommitsCompanion.insert({
    required String id,
    required String sha256,
    required int byteLength,
    required String metadata,
    required DateTime startedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sha256 = Value(sha256),
       byteLength = Value(byteLength),
       metadata = Value(metadata),
       startedAt = Value(startedAt);
  static Insertable<PendingOriginalCommitRow> custom({
    Expression<String>? id,
    Expression<String>? sha256,
    Expression<int>? byteLength,
    Expression<String>? metadata,
    Expression<DateTime>? startedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sha256 != null) 'sha256': sha256,
      if (byteLength != null) 'byte_length': byteLength,
      if (metadata != null) 'metadata': metadata,
      if (startedAt != null) 'started_at': startedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingOriginalCommitsCompanion copyWith({
    Value<String>? id,
    Value<String>? sha256,
    Value<int>? byteLength,
    Value<String>? metadata,
    Value<DateTime>? startedAt,
    Value<int>? rowid,
  }) {
    return PendingOriginalCommitsCompanion(
      id: id ?? this.id,
      sha256: sha256 ?? this.sha256,
      byteLength: byteLength ?? this.byteLength,
      metadata: metadata ?? this.metadata,
      startedAt: startedAt ?? this.startedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOriginalCommitsCompanion(')
          ..write('id: $id, ')
          ..write('sha256: $sha256, ')
          ..write('byteLength: $byteLength, ')
          ..write('metadata: $metadata, ')
          ..write('startedAt: $startedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CaptureSessions extends Table
    with TableInfo<CaptureSessions, CaptureSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaptureSessions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES events(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sequence >= 1)',
  );
  static const VerificationMeta _templateRevisionIdMeta =
      const VerificationMeta('templateRevisionId');
  late final GeneratedColumn<String> templateRevisionId =
      GeneratedColumn<String>(
        'template_revision_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES template_revisions(id)ON DELETE RESTRICT',
      );
  static const VerificationMeta _plannedShotsMeta = const VerificationMeta(
    'plannedShots',
  );
  late final GeneratedColumn<int> plannedShots = GeneratedColumn<int>(
    'planned_shots',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (planned_shots BETWEEN 1 AND 4)',
  );
  static const VerificationMeta _planJsonMeta = const VerificationMeta(
    'planJson',
  );
  late final GeneratedColumn<String> planJson = GeneratedColumn<String>(
    'plan_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (length(plan_json) BETWEEN 2 AND 65536)',
  );
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (status IN (\'capturing\', \'reviewing\', \'rendering\', \'completed\', \'abandoned\', \'failed\'))',
      ).withConverter<SessionStatus>(CaptureSessions.$converterstatus);
  late final GeneratedColumnWithTypeConverter<SessionEndReason?, String>
  endReason = GeneratedColumn<String>(
    'end_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (end_reason IS NULL OR end_reason IN (\'interrupted\', \'timedOut\', \'operatorExit\', \'problem\', \'renderFailed\'))',
  ).withConverter<SessionEndReason?>(CaptureSessions.$converterendReasonn);
  static const VerificationMeta _renderAttemptsMeta = const VerificationMeta(
    'renderAttempts',
  );
  late final GeneratedColumn<int> renderAttempts = GeneratedColumn<int>(
    'render_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (render_attempts >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _outputIdMeta = const VerificationMeta(
    'outputId',
  );
  late final GeneratedColumn<String> outputId = GeneratedColumn<String>(
    'output_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (output_id IS NULL OR length(output_id) = 36)',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    sequence,
    templateRevisionId,
    plannedShots,
    planJson,
    status,
    endReason,
    renderAttempts,
    outputId,
    startedAt,
    updatedAt,
    endedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capture_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptureSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('template_revision_id')) {
      context.handle(
        _templateRevisionIdMeta,
        templateRevisionId.isAcceptableOrUnknown(
          data['template_revision_id']!,
          _templateRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateRevisionIdMeta);
    }
    if (data.containsKey('planned_shots')) {
      context.handle(
        _plannedShotsMeta,
        plannedShots.isAcceptableOrUnknown(
          data['planned_shots']!,
          _plannedShotsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedShotsMeta);
    }
    if (data.containsKey('plan_json')) {
      context.handle(
        _planJsonMeta,
        planJson.isAcceptableOrUnknown(data['plan_json']!, _planJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_planJsonMeta);
    }
    if (data.containsKey('render_attempts')) {
      context.handle(
        _renderAttemptsMeta,
        renderAttempts.isAcceptableOrUnknown(
          data['render_attempts']!,
          _renderAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('output_id')) {
      context.handle(
        _outputIdMeta,
        outputId.isAcceptableOrUnknown(data['output_id']!, _outputIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {eventId, sequence},
  ];
  @override
  CaptureSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptureSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      templateRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_revision_id'],
      )!,
      plannedShots: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_shots'],
      )!,
      planJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_json'],
      )!,
      status: CaptureSessions.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      endReason: CaptureSessions.$converterendReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}end_reason'],
        ),
      ),
      renderAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}render_attempts'],
      )!,
      outputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
    );
  }

  @override
  CaptureSessions createAlias(String alias) {
    return CaptureSessions(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
  static JsonTypeConverter2<SessionEndReason, String, String>
  $converterendReason = const EnumNameConverter<SessionEndReason>(
    SessionEndReason.values,
  );
  static JsonTypeConverter2<SessionEndReason?, String?, String?>
  $converterendReasonn = JsonTypeConverter2.asNullable($converterendReason);
  @override
  List<String> get customConstraints => const [
    'CHECK((status IN (\'completed\', \'abandoned\', \'failed\'))=(ended_at IS NOT NULL))',
    'CHECK((status = \'completed\')=(output_id IS NOT NULL))',
    'CHECK((status IN (\'abandoned\', \'failed\'))=(end_reason IS NOT NULL))',
    'UNIQUE(event_id, sequence)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaptureSessionRow extends DataClass
    implements Insertable<CaptureSessionRow> {
  final String id;
  final String eventId;
  final int sequence;
  final String templateRevisionId;
  final int plannedShots;
  final String planJson;
  final SessionStatus status;
  final SessionEndReason? endReason;
  final int renderAttempts;
  final String? outputId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? endedAt;
  const CaptureSessionRow({
    required this.id,
    required this.eventId,
    required this.sequence,
    required this.templateRevisionId,
    required this.plannedShots,
    required this.planJson,
    required this.status,
    this.endReason,
    required this.renderAttempts,
    this.outputId,
    required this.startedAt,
    required this.updatedAt,
    this.endedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['event_id'] = Variable<String>(eventId);
    map['sequence'] = Variable<int>(sequence);
    map['template_revision_id'] = Variable<String>(templateRevisionId);
    map['planned_shots'] = Variable<int>(plannedShots);
    map['plan_json'] = Variable<String>(planJson);
    {
      map['status'] = Variable<String>(
        CaptureSessions.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<String>(
        CaptureSessions.$converterendReasonn.toSql(endReason),
      );
    }
    map['render_attempts'] = Variable<int>(renderAttempts);
    if (!nullToAbsent || outputId != null) {
      map['output_id'] = Variable<String>(outputId);
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    return map;
  }

  CaptureSessionsCompanion toCompanion(bool nullToAbsent) {
    return CaptureSessionsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      sequence: Value(sequence),
      templateRevisionId: Value(templateRevisionId),
      plannedShots: Value(plannedShots),
      planJson: Value(planJson),
      status: Value(status),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
      renderAttempts: Value(renderAttempts),
      outputId: outputId == null && nullToAbsent
          ? const Value.absent()
          : Value(outputId),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
    );
  }

  factory CaptureSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptureSessionRow(
      id: serializer.fromJson<String>(json['id']),
      eventId: serializer.fromJson<String>(json['event_id']),
      sequence: serializer.fromJson<int>(json['sequence']),
      templateRevisionId: serializer.fromJson<String>(
        json['template_revision_id'],
      ),
      plannedShots: serializer.fromJson<int>(json['planned_shots']),
      planJson: serializer.fromJson<String>(json['plan_json']),
      status: CaptureSessions.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      endReason: CaptureSessions.$converterendReasonn.fromJson(
        serializer.fromJson<String?>(json['end_reason']),
      ),
      renderAttempts: serializer.fromJson<int>(json['render_attempts']),
      outputId: serializer.fromJson<String?>(json['output_id']),
      startedAt: serializer.fromJson<DateTime>(json['started_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
      endedAt: serializer.fromJson<DateTime?>(json['ended_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'event_id': serializer.toJson<String>(eventId),
      'sequence': serializer.toJson<int>(sequence),
      'template_revision_id': serializer.toJson<String>(templateRevisionId),
      'planned_shots': serializer.toJson<int>(plannedShots),
      'plan_json': serializer.toJson<String>(planJson),
      'status': serializer.toJson<String>(
        CaptureSessions.$converterstatus.toJson(status),
      ),
      'end_reason': serializer.toJson<String?>(
        CaptureSessions.$converterendReasonn.toJson(endReason),
      ),
      'render_attempts': serializer.toJson<int>(renderAttempts),
      'output_id': serializer.toJson<String?>(outputId),
      'started_at': serializer.toJson<DateTime>(startedAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
      'ended_at': serializer.toJson<DateTime?>(endedAt),
    };
  }

  CaptureSessionRow copyWith({
    String? id,
    String? eventId,
    int? sequence,
    String? templateRevisionId,
    int? plannedShots,
    String? planJson,
    SessionStatus? status,
    Value<SessionEndReason?> endReason = const Value.absent(),
    int? renderAttempts,
    Value<String?> outputId = const Value.absent(),
    DateTime? startedAt,
    DateTime? updatedAt,
    Value<DateTime?> endedAt = const Value.absent(),
  }) => CaptureSessionRow(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    sequence: sequence ?? this.sequence,
    templateRevisionId: templateRevisionId ?? this.templateRevisionId,
    plannedShots: plannedShots ?? this.plannedShots,
    planJson: planJson ?? this.planJson,
    status: status ?? this.status,
    endReason: endReason.present ? endReason.value : this.endReason,
    renderAttempts: renderAttempts ?? this.renderAttempts,
    outputId: outputId.present ? outputId.value : this.outputId,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
  );
  CaptureSessionRow copyWithCompanion(CaptureSessionsCompanion data) {
    return CaptureSessionRow(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      templateRevisionId: data.templateRevisionId.present
          ? data.templateRevisionId.value
          : this.templateRevisionId,
      plannedShots: data.plannedShots.present
          ? data.plannedShots.value
          : this.plannedShots,
      planJson: data.planJson.present ? data.planJson.value : this.planJson,
      status: data.status.present ? data.status.value : this.status,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
      renderAttempts: data.renderAttempts.present
          ? data.renderAttempts.value
          : this.renderAttempts,
      outputId: data.outputId.present ? data.outputId.value : this.outputId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureSessionRow(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('sequence: $sequence, ')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('plannedShots: $plannedShots, ')
          ..write('planJson: $planJson, ')
          ..write('status: $status, ')
          ..write('endReason: $endReason, ')
          ..write('renderAttempts: $renderAttempts, ')
          ..write('outputId: $outputId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('endedAt: $endedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    sequence,
    templateRevisionId,
    plannedShots,
    planJson,
    status,
    endReason,
    renderAttempts,
    outputId,
    startedAt,
    updatedAt,
    endedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureSessionRow &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.sequence == this.sequence &&
          other.templateRevisionId == this.templateRevisionId &&
          other.plannedShots == this.plannedShots &&
          other.planJson == this.planJson &&
          other.status == this.status &&
          other.endReason == this.endReason &&
          other.renderAttempts == this.renderAttempts &&
          other.outputId == this.outputId &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.endedAt == this.endedAt);
}

class CaptureSessionsCompanion extends UpdateCompanion<CaptureSessionRow> {
  final Value<String> id;
  final Value<String> eventId;
  final Value<int> sequence;
  final Value<String> templateRevisionId;
  final Value<int> plannedShots;
  final Value<String> planJson;
  final Value<SessionStatus> status;
  final Value<SessionEndReason?> endReason;
  final Value<int> renderAttempts;
  final Value<String?> outputId;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> endedAt;
  final Value<int> rowid;
  const CaptureSessionsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.templateRevisionId = const Value.absent(),
    this.plannedShots = const Value.absent(),
    this.planJson = const Value.absent(),
    this.status = const Value.absent(),
    this.endReason = const Value.absent(),
    this.renderAttempts = const Value.absent(),
    this.outputId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaptureSessionsCompanion.insert({
    required String id,
    required String eventId,
    required int sequence,
    required String templateRevisionId,
    required int plannedShots,
    required String planJson,
    required SessionStatus status,
    this.endReason = const Value.absent(),
    this.renderAttempts = const Value.absent(),
    this.outputId = const Value.absent(),
    required DateTime startedAt,
    required DateTime updatedAt,
    this.endedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       eventId = Value(eventId),
       sequence = Value(sequence),
       templateRevisionId = Value(templateRevisionId),
       plannedShots = Value(plannedShots),
       planJson = Value(planJson),
       status = Value(status),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<CaptureSessionRow> custom({
    Expression<String>? id,
    Expression<String>? eventId,
    Expression<int>? sequence,
    Expression<String>? templateRevisionId,
    Expression<int>? plannedShots,
    Expression<String>? planJson,
    Expression<String>? status,
    Expression<String>? endReason,
    Expression<int>? renderAttempts,
    Expression<String>? outputId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (sequence != null) 'sequence': sequence,
      if (templateRevisionId != null)
        'template_revision_id': templateRevisionId,
      if (plannedShots != null) 'planned_shots': plannedShots,
      if (planJson != null) 'plan_json': planJson,
      if (status != null) 'status': status,
      if (endReason != null) 'end_reason': endReason,
      if (renderAttempts != null) 'render_attempts': renderAttempts,
      if (outputId != null) 'output_id': outputId,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaptureSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? eventId,
    Value<int>? sequence,
    Value<String>? templateRevisionId,
    Value<int>? plannedShots,
    Value<String>? planJson,
    Value<SessionStatus>? status,
    Value<SessionEndReason?>? endReason,
    Value<int>? renderAttempts,
    Value<String?>? outputId,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? endedAt,
    Value<int>? rowid,
  }) {
    return CaptureSessionsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sequence: sequence ?? this.sequence,
      templateRevisionId: templateRevisionId ?? this.templateRevisionId,
      plannedShots: plannedShots ?? this.plannedShots,
      planJson: planJson ?? this.planJson,
      status: status ?? this.status,
      endReason: endReason ?? this.endReason,
      renderAttempts: renderAttempts ?? this.renderAttempts,
      outputId: outputId ?? this.outputId,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      endedAt: endedAt ?? this.endedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (templateRevisionId.present) {
      map['template_revision_id'] = Variable<String>(templateRevisionId.value);
    }
    if (plannedShots.present) {
      map['planned_shots'] = Variable<int>(plannedShots.value);
    }
    if (planJson.present) {
      map['plan_json'] = Variable<String>(planJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        CaptureSessions.$converterstatus.toSql(status.value),
      );
    }
    if (endReason.present) {
      map['end_reason'] = Variable<String>(
        CaptureSessions.$converterendReasonn.toSql(endReason.value),
      );
    }
    if (renderAttempts.present) {
      map['render_attempts'] = Variable<int>(renderAttempts.value);
    }
    if (outputId.present) {
      map['output_id'] = Variable<String>(outputId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaptureSessionsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('sequence: $sequence, ')
          ..write('templateRevisionId: $templateRevisionId, ')
          ..write('plannedShots: $plannedShots, ')
          ..write('planJson: $planJson, ')
          ..write('status: $status, ')
          ..write('endReason: $endReason, ')
          ..write('renderAttempts: $renderAttempts, ')
          ..write('outputId: $outputId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SessionPhotos extends Table
    with TableInfo<SessionPhotos, SessionPhotoRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SessionPhotos(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES capture_sessions(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _shotIndexMeta = const VerificationMeta(
    'shotIndex',
  );
  late final GeneratedColumn<int> shotIndex = GeneratedColumn<int>(
    'shot_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (shot_index BETWEEN 0 AND 3)',
  );
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (attempt >= 1)',
  );
  static const VerificationMeta _roundMeta = const VerificationMeta('round');
  late final GeneratedColumn<int> round = GeneratedColumn<int>(
    'round',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (round >= 0 AND round < attempt)',
  );
  static const VerificationMeta _slotIndexMeta = const VerificationMeta(
    'slotIndex',
  );
  late final GeneratedColumn<int> slotIndex = GeneratedColumn<int>(
    'slot_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (slot_index BETWEEN 0 AND 7)',
  );
  static const VerificationMeta _originalIdMeta = const VerificationMeta(
    'originalId',
  );
  late final GeneratedColumn<String> originalId = GeneratedColumn<String>(
    'original_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE REFERENCES original_photos(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    shotIndex,
    attempt,
    round,
    slotIndex,
    originalId,
    capturedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionPhotoRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('shot_index')) {
      context.handle(
        _shotIndexMeta,
        shotIndex.isAcceptableOrUnknown(data['shot_index']!, _shotIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_shotIndexMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('round')) {
      context.handle(
        _roundMeta,
        round.isAcceptableOrUnknown(data['round']!, _roundMeta),
      );
    } else if (isInserting) {
      context.missing(_roundMeta);
    }
    if (data.containsKey('slot_index')) {
      context.handle(
        _slotIndexMeta,
        slotIndex.isAcceptableOrUnknown(data['slot_index']!, _slotIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIndexMeta);
    }
    if (data.containsKey('original_id')) {
      context.handle(
        _originalIdMeta,
        originalId.isAcceptableOrUnknown(data['original_id']!, _originalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_originalIdMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, shotIndex, attempt};
  @override
  SessionPhotoRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionPhotoRow(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      shotIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shot_index'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      round: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round'],
      )!,
      slotIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot_index'],
      )!,
      originalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_id'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  SessionPhotos createAlias(String alias) {
    return SessionPhotos(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(session_id, shot_index, attempt)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SessionPhotoRow extends DataClass implements Insertable<SessionPhotoRow> {
  final String sessionId;
  final int shotIndex;
  final int attempt;
  final int round;
  final int slotIndex;
  final String originalId;
  final DateTime capturedAt;
  const SessionPhotoRow({
    required this.sessionId,
    required this.shotIndex,
    required this.attempt,
    required this.round,
    required this.slotIndex,
    required this.originalId,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['shot_index'] = Variable<int>(shotIndex);
    map['attempt'] = Variable<int>(attempt);
    map['round'] = Variable<int>(round);
    map['slot_index'] = Variable<int>(slotIndex);
    map['original_id'] = Variable<String>(originalId);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  SessionPhotosCompanion toCompanion(bool nullToAbsent) {
    return SessionPhotosCompanion(
      sessionId: Value(sessionId),
      shotIndex: Value(shotIndex),
      attempt: Value(attempt),
      round: Value(round),
      slotIndex: Value(slotIndex),
      originalId: Value(originalId),
      capturedAt: Value(capturedAt),
    );
  }

  factory SessionPhotoRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionPhotoRow(
      sessionId: serializer.fromJson<String>(json['session_id']),
      shotIndex: serializer.fromJson<int>(json['shot_index']),
      attempt: serializer.fromJson<int>(json['attempt']),
      round: serializer.fromJson<int>(json['round']),
      slotIndex: serializer.fromJson<int>(json['slot_index']),
      originalId: serializer.fromJson<String>(json['original_id']),
      capturedAt: serializer.fromJson<DateTime>(json['captured_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'session_id': serializer.toJson<String>(sessionId),
      'shot_index': serializer.toJson<int>(shotIndex),
      'attempt': serializer.toJson<int>(attempt),
      'round': serializer.toJson<int>(round),
      'slot_index': serializer.toJson<int>(slotIndex),
      'original_id': serializer.toJson<String>(originalId),
      'captured_at': serializer.toJson<DateTime>(capturedAt),
    };
  }

  SessionPhotoRow copyWith({
    String? sessionId,
    int? shotIndex,
    int? attempt,
    int? round,
    int? slotIndex,
    String? originalId,
    DateTime? capturedAt,
  }) => SessionPhotoRow(
    sessionId: sessionId ?? this.sessionId,
    shotIndex: shotIndex ?? this.shotIndex,
    attempt: attempt ?? this.attempt,
    round: round ?? this.round,
    slotIndex: slotIndex ?? this.slotIndex,
    originalId: originalId ?? this.originalId,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  SessionPhotoRow copyWithCompanion(SessionPhotosCompanion data) {
    return SessionPhotoRow(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      shotIndex: data.shotIndex.present ? data.shotIndex.value : this.shotIndex,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      round: data.round.present ? data.round.value : this.round,
      slotIndex: data.slotIndex.present ? data.slotIndex.value : this.slotIndex,
      originalId: data.originalId.present
          ? data.originalId.value
          : this.originalId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionPhotoRow(')
          ..write('sessionId: $sessionId, ')
          ..write('shotIndex: $shotIndex, ')
          ..write('attempt: $attempt, ')
          ..write('round: $round, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('originalId: $originalId, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    shotIndex,
    attempt,
    round,
    slotIndex,
    originalId,
    capturedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionPhotoRow &&
          other.sessionId == this.sessionId &&
          other.shotIndex == this.shotIndex &&
          other.attempt == this.attempt &&
          other.round == this.round &&
          other.slotIndex == this.slotIndex &&
          other.originalId == this.originalId &&
          other.capturedAt == this.capturedAt);
}

class SessionPhotosCompanion extends UpdateCompanion<SessionPhotoRow> {
  final Value<String> sessionId;
  final Value<int> shotIndex;
  final Value<int> attempt;
  final Value<int> round;
  final Value<int> slotIndex;
  final Value<String> originalId;
  final Value<DateTime> capturedAt;
  final Value<int> rowid;
  const SessionPhotosCompanion({
    this.sessionId = const Value.absent(),
    this.shotIndex = const Value.absent(),
    this.attempt = const Value.absent(),
    this.round = const Value.absent(),
    this.slotIndex = const Value.absent(),
    this.originalId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionPhotosCompanion.insert({
    required String sessionId,
    required int shotIndex,
    required int attempt,
    required int round,
    required int slotIndex,
    required String originalId,
    required DateTime capturedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       shotIndex = Value(shotIndex),
       attempt = Value(attempt),
       round = Value(round),
       slotIndex = Value(slotIndex),
       originalId = Value(originalId),
       capturedAt = Value(capturedAt);
  static Insertable<SessionPhotoRow> custom({
    Expression<String>? sessionId,
    Expression<int>? shotIndex,
    Expression<int>? attempt,
    Expression<int>? round,
    Expression<int>? slotIndex,
    Expression<String>? originalId,
    Expression<DateTime>? capturedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (shotIndex != null) 'shot_index': shotIndex,
      if (attempt != null) 'attempt': attempt,
      if (round != null) 'round': round,
      if (slotIndex != null) 'slot_index': slotIndex,
      if (originalId != null) 'original_id': originalId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionPhotosCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? shotIndex,
    Value<int>? attempt,
    Value<int>? round,
    Value<int>? slotIndex,
    Value<String>? originalId,
    Value<DateTime>? capturedAt,
    Value<int>? rowid,
  }) {
    return SessionPhotosCompanion(
      sessionId: sessionId ?? this.sessionId,
      shotIndex: shotIndex ?? this.shotIndex,
      attempt: attempt ?? this.attempt,
      round: round ?? this.round,
      slotIndex: slotIndex ?? this.slotIndex,
      originalId: originalId ?? this.originalId,
      capturedAt: capturedAt ?? this.capturedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (shotIndex.present) {
      map['shot_index'] = Variable<int>(shotIndex.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (round.present) {
      map['round'] = Variable<int>(round.value);
    }
    if (slotIndex.present) {
      map['slot_index'] = Variable<int>(slotIndex.value);
    }
    if (originalId.present) {
      map['original_id'] = Variable<String>(originalId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionPhotosCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('shotIndex: $shotIndex, ')
          ..write('attempt: $attempt, ')
          ..write('round: $round, ')
          ..write('slotIndex: $slotIndex, ')
          ..write('originalId: $originalId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SessionOutputs extends Table
    with TableInfo<SessionOutputs, SessionOutputRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SessionOutputs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES capture_sessions(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (relative_path = \'outputs/\' || id || CASE format WHEN \'jpeg\' THEN \'.jpg\' ELSE \'.png\' END)',
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(sha256) = 64 AND sha256 NOT GLOB \'*[^0-9a-f]*\')',
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_length >= 1)',
  );
  static const VerificationMeta _widthPxMeta = const VerificationMeta(
    'widthPx',
  );
  late final GeneratedColumn<int> widthPx = GeneratedColumn<int>(
    'width_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (width_px BETWEEN 1 AND 20000)',
  );
  static const VerificationMeta _heightPxMeta = const VerificationMeta(
    'heightPx',
  );
  late final GeneratedColumn<int> heightPx = GeneratedColumn<int>(
    'height_px',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (height_px BETWEEN 1 AND 20000)',
  );
  late final GeneratedColumnWithTypeConverter<OutputFormat, String> format =
      GeneratedColumn<String>(
        'format',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (format IN (\'jpeg\', \'png\'))',
      ).withConverter<OutputFormat>(SessionOutputs.$converterformat);
  static const VerificationMeta _renderVersionMeta = const VerificationMeta(
    'renderVersion',
  );
  late final GeneratedColumn<int> renderVersion = GeneratedColumn<int>(
    'render_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (render_version >= 1)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<SessionOutputOrigin, String>
  origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'session\' CHECK (origin IN (\'session\', \'rerender\'))',
    defaultValue: const CustomExpression('\'session\''),
  ).withConverter<SessionOutputOrigin>(SessionOutputs.$converterorigin);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    relativePath,
    sha256,
    byteLength,
    widthPx,
    heightPx,
    format,
    renderVersion,
    createdAt,
    origin,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_outputs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionOutputRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('width_px')) {
      context.handle(
        _widthPxMeta,
        widthPx.isAcceptableOrUnknown(data['width_px']!, _widthPxMeta),
      );
    } else if (isInserting) {
      context.missing(_widthPxMeta);
    }
    if (data.containsKey('height_px')) {
      context.handle(
        _heightPxMeta,
        heightPx.isAcceptableOrUnknown(data['height_px']!, _heightPxMeta),
      );
    } else if (isInserting) {
      context.missing(_heightPxMeta);
    }
    if (data.containsKey('render_version')) {
      context.handle(
        _renderVersionMeta,
        renderVersion.isAcceptableOrUnknown(
          data['render_version']!,
          _renderVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_renderVersionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionOutputRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionOutputRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      widthPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_px'],
      )!,
      heightPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_px'],
      )!,
      format: SessionOutputs.$converterformat.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}format'],
        )!,
      ),
      renderVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}render_version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      origin: SessionOutputs.$converterorigin.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}origin'],
        )!,
      ),
    );
  }

  @override
  SessionOutputs createAlias(String alias) {
    return SessionOutputs(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OutputFormat, String, String> $converterformat =
      const EnumNameConverter<OutputFormat>(OutputFormat.values);
  static JsonTypeConverter2<SessionOutputOrigin, String, String>
  $converterorigin = const EnumNameConverter<SessionOutputOrigin>(
    SessionOutputOrigin.values,
  );
  @override
  bool get dontWriteConstraints => true;
}

class SessionOutputRow extends DataClass
    implements Insertable<SessionOutputRow> {
  final String id;
  final String sessionId;
  final String relativePath;
  final String sha256;
  final int byteLength;
  final int widthPx;
  final int heightPx;
  final OutputFormat format;
  final int renderVersion;
  final DateTime createdAt;
  final SessionOutputOrigin origin;
  const SessionOutputRow({
    required this.id,
    required this.sessionId,
    required this.relativePath,
    required this.sha256,
    required this.byteLength,
    required this.widthPx,
    required this.heightPx,
    required this.format,
    required this.renderVersion,
    required this.createdAt,
    required this.origin,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['relative_path'] = Variable<String>(relativePath);
    map['sha256'] = Variable<String>(sha256);
    map['byte_length'] = Variable<int>(byteLength);
    map['width_px'] = Variable<int>(widthPx);
    map['height_px'] = Variable<int>(heightPx);
    {
      map['format'] = Variable<String>(
        SessionOutputs.$converterformat.toSql(format),
      );
    }
    map['render_version'] = Variable<int>(renderVersion);
    map['created_at'] = Variable<DateTime>(createdAt);
    {
      map['origin'] = Variable<String>(
        SessionOutputs.$converterorigin.toSql(origin),
      );
    }
    return map;
  }

  SessionOutputsCompanion toCompanion(bool nullToAbsent) {
    return SessionOutputsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      relativePath: Value(relativePath),
      sha256: Value(sha256),
      byteLength: Value(byteLength),
      widthPx: Value(widthPx),
      heightPx: Value(heightPx),
      format: Value(format),
      renderVersion: Value(renderVersion),
      createdAt: Value(createdAt),
      origin: Value(origin),
    );
  }

  factory SessionOutputRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionOutputRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      relativePath: serializer.fromJson<String>(json['relative_path']),
      sha256: serializer.fromJson<String>(json['sha256']),
      byteLength: serializer.fromJson<int>(json['byte_length']),
      widthPx: serializer.fromJson<int>(json['width_px']),
      heightPx: serializer.fromJson<int>(json['height_px']),
      format: SessionOutputs.$converterformat.fromJson(
        serializer.fromJson<String>(json['format']),
      ),
      renderVersion: serializer.fromJson<int>(json['render_version']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      origin: SessionOutputs.$converterorigin.fromJson(
        serializer.fromJson<String>(json['origin']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'session_id': serializer.toJson<String>(sessionId),
      'relative_path': serializer.toJson<String>(relativePath),
      'sha256': serializer.toJson<String>(sha256),
      'byte_length': serializer.toJson<int>(byteLength),
      'width_px': serializer.toJson<int>(widthPx),
      'height_px': serializer.toJson<int>(heightPx),
      'format': serializer.toJson<String>(
        SessionOutputs.$converterformat.toJson(format),
      ),
      'render_version': serializer.toJson<int>(renderVersion),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'origin': serializer.toJson<String>(
        SessionOutputs.$converterorigin.toJson(origin),
      ),
    };
  }

  SessionOutputRow copyWith({
    String? id,
    String? sessionId,
    String? relativePath,
    String? sha256,
    int? byteLength,
    int? widthPx,
    int? heightPx,
    OutputFormat? format,
    int? renderVersion,
    DateTime? createdAt,
    SessionOutputOrigin? origin,
  }) => SessionOutputRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    relativePath: relativePath ?? this.relativePath,
    sha256: sha256 ?? this.sha256,
    byteLength: byteLength ?? this.byteLength,
    widthPx: widthPx ?? this.widthPx,
    heightPx: heightPx ?? this.heightPx,
    format: format ?? this.format,
    renderVersion: renderVersion ?? this.renderVersion,
    createdAt: createdAt ?? this.createdAt,
    origin: origin ?? this.origin,
  );
  SessionOutputRow copyWithCompanion(SessionOutputsCompanion data) {
    return SessionOutputRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      widthPx: data.widthPx.present ? data.widthPx.value : this.widthPx,
      heightPx: data.heightPx.present ? data.heightPx.value : this.heightPx,
      format: data.format.present ? data.format.value : this.format,
      renderVersion: data.renderVersion.present
          ? data.renderVersion.value
          : this.renderVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      origin: data.origin.present ? data.origin.value : this.origin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionOutputRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('relativePath: $relativePath, ')
          ..write('sha256: $sha256, ')
          ..write('byteLength: $byteLength, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('format: $format, ')
          ..write('renderVersion: $renderVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    relativePath,
    sha256,
    byteLength,
    widthPx,
    heightPx,
    format,
    renderVersion,
    createdAt,
    origin,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionOutputRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.relativePath == this.relativePath &&
          other.sha256 == this.sha256 &&
          other.byteLength == this.byteLength &&
          other.widthPx == this.widthPx &&
          other.heightPx == this.heightPx &&
          other.format == this.format &&
          other.renderVersion == this.renderVersion &&
          other.createdAt == this.createdAt &&
          other.origin == this.origin);
}

class SessionOutputsCompanion extends UpdateCompanion<SessionOutputRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> relativePath;
  final Value<String> sha256;
  final Value<int> byteLength;
  final Value<int> widthPx;
  final Value<int> heightPx;
  final Value<OutputFormat> format;
  final Value<int> renderVersion;
  final Value<DateTime> createdAt;
  final Value<SessionOutputOrigin> origin;
  final Value<int> rowid;
  const SessionOutputsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.format = const Value.absent(),
    this.renderVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionOutputsCompanion.insert({
    required String id,
    required String sessionId,
    required String relativePath,
    required String sha256,
    required int byteLength,
    required int widthPx,
    required int heightPx,
    required OutputFormat format,
    required int renderVersion,
    required DateTime createdAt,
    this.origin = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       relativePath = Value(relativePath),
       sha256 = Value(sha256),
       byteLength = Value(byteLength),
       widthPx = Value(widthPx),
       heightPx = Value(heightPx),
       format = Value(format),
       renderVersion = Value(renderVersion),
       createdAt = Value(createdAt);
  static Insertable<SessionOutputRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? relativePath,
    Expression<String>? sha256,
    Expression<int>? byteLength,
    Expression<int>? widthPx,
    Expression<int>? heightPx,
    Expression<String>? format,
    Expression<int>? renderVersion,
    Expression<DateTime>? createdAt,
    Expression<String>? origin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (relativePath != null) 'relative_path': relativePath,
      if (sha256 != null) 'sha256': sha256,
      if (byteLength != null) 'byte_length': byteLength,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (format != null) 'format': format,
      if (renderVersion != null) 'render_version': renderVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (origin != null) 'origin': origin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionOutputsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? relativePath,
    Value<String>? sha256,
    Value<int>? byteLength,
    Value<int>? widthPx,
    Value<int>? heightPx,
    Value<OutputFormat>? format,
    Value<int>? renderVersion,
    Value<DateTime>? createdAt,
    Value<SessionOutputOrigin>? origin,
    Value<int>? rowid,
  }) {
    return SessionOutputsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      relativePath: relativePath ?? this.relativePath,
      sha256: sha256 ?? this.sha256,
      byteLength: byteLength ?? this.byteLength,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      format: format ?? this.format,
      renderVersion: renderVersion ?? this.renderVersion,
      createdAt: createdAt ?? this.createdAt,
      origin: origin ?? this.origin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (widthPx.present) {
      map['width_px'] = Variable<int>(widthPx.value);
    }
    if (heightPx.present) {
      map['height_px'] = Variable<int>(heightPx.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(
        SessionOutputs.$converterformat.toSql(format.value),
      );
    }
    if (renderVersion.present) {
      map['render_version'] = Variable<int>(renderVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(
        SessionOutputs.$converterorigin.toSql(origin.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionOutputsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('relativePath: $relativePath, ')
          ..write('sha256: $sha256, ')
          ..write('byteLength: $byteLength, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('format: $format, ')
          ..write('renderVersion: $renderVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('origin: $origin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExportBatches extends Table
    with TableInfo<ExportBatches, ExportBatchRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExportBatches(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  late final GeneratedColumnWithTypeConverter<ShareOutcome, String> outcome =
      GeneratedColumn<String>(
        'outcome',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (outcome IN (\'shared\', \'unknown\'))',
      ).withConverter<ShareOutcome>(ExportBatches.$converteroutcome);
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (destination IS NULL OR length(destination) BETWEEN 1 AND 200)',
  );
  static const VerificationMeta _fileCountMeta = const VerificationMeta(
    'fileCount',
  );
  late final GeneratedColumn<int> fileCount = GeneratedColumn<int>(
    'file_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (file_count >= 1)',
  );
  static const VerificationMeta _failureCountMeta = const VerificationMeta(
    'failureCount',
  );
  late final GeneratedColumn<int> failureCount = GeneratedColumn<int>(
    'failure_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (failure_count >= 0)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    outcome,
    destination,
    fileCount,
    failureCount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportBatchRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    }
    if (data.containsKey('file_count')) {
      context.handle(
        _fileCountMeta,
        fileCount.isAcceptableOrUnknown(data['file_count']!, _fileCountMeta),
      );
    } else if (isInserting) {
      context.missing(_fileCountMeta);
    }
    if (data.containsKey('failure_count')) {
      context.handle(
        _failureCountMeta,
        failureCount.isAcceptableOrUnknown(
          data['failure_count']!,
          _failureCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_failureCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExportBatchRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportBatchRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      outcome: ExportBatches.$converteroutcome.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}outcome'],
        )!,
      ),
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      ),
      fileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_count'],
      )!,
      failureCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failure_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  ExportBatches createAlias(String alias) {
    return ExportBatches(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ShareOutcome, String, String> $converteroutcome =
      const EnumNameConverter<ShareOutcome>(ShareOutcome.values);
  @override
  bool get dontWriteConstraints => true;
}

class ExportBatchRow extends DataClass implements Insertable<ExportBatchRow> {
  final String id;
  final ShareOutcome outcome;
  final String? destination;
  final int fileCount;
  final int failureCount;
  final DateTime createdAt;
  const ExportBatchRow({
    required this.id,
    required this.outcome,
    this.destination,
    required this.fileCount,
    required this.failureCount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['outcome'] = Variable<String>(
        ExportBatches.$converteroutcome.toSql(outcome),
      );
    }
    if (!nullToAbsent || destination != null) {
      map['destination'] = Variable<String>(destination);
    }
    map['file_count'] = Variable<int>(fileCount);
    map['failure_count'] = Variable<int>(failureCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ExportBatchesCompanion toCompanion(bool nullToAbsent) {
    return ExportBatchesCompanion(
      id: Value(id),
      outcome: Value(outcome),
      destination: destination == null && nullToAbsent
          ? const Value.absent()
          : Value(destination),
      fileCount: Value(fileCount),
      failureCount: Value(failureCount),
      createdAt: Value(createdAt),
    );
  }

  factory ExportBatchRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportBatchRow(
      id: serializer.fromJson<String>(json['id']),
      outcome: ExportBatches.$converteroutcome.fromJson(
        serializer.fromJson<String>(json['outcome']),
      ),
      destination: serializer.fromJson<String?>(json['destination']),
      fileCount: serializer.fromJson<int>(json['file_count']),
      failureCount: serializer.fromJson<int>(json['failure_count']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'outcome': serializer.toJson<String>(
        ExportBatches.$converteroutcome.toJson(outcome),
      ),
      'destination': serializer.toJson<String?>(destination),
      'file_count': serializer.toJson<int>(fileCount),
      'failure_count': serializer.toJson<int>(failureCount),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  ExportBatchRow copyWith({
    String? id,
    ShareOutcome? outcome,
    Value<String?> destination = const Value.absent(),
    int? fileCount,
    int? failureCount,
    DateTime? createdAt,
  }) => ExportBatchRow(
    id: id ?? this.id,
    outcome: outcome ?? this.outcome,
    destination: destination.present ? destination.value : this.destination,
    fileCount: fileCount ?? this.fileCount,
    failureCount: failureCount ?? this.failureCount,
    createdAt: createdAt ?? this.createdAt,
  );
  ExportBatchRow copyWithCompanion(ExportBatchesCompanion data) {
    return ExportBatchRow(
      id: data.id.present ? data.id.value : this.id,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      fileCount: data.fileCount.present ? data.fileCount.value : this.fileCount,
      failureCount: data.failureCount.present
          ? data.failureCount.value
          : this.failureCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchRow(')
          ..write('id: $id, ')
          ..write('outcome: $outcome, ')
          ..write('destination: $destination, ')
          ..write('fileCount: $fileCount, ')
          ..write('failureCount: $failureCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, outcome, destination, fileCount, failureCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportBatchRow &&
          other.id == this.id &&
          other.outcome == this.outcome &&
          other.destination == this.destination &&
          other.fileCount == this.fileCount &&
          other.failureCount == this.failureCount &&
          other.createdAt == this.createdAt);
}

class ExportBatchesCompanion extends UpdateCompanion<ExportBatchRow> {
  final Value<String> id;
  final Value<ShareOutcome> outcome;
  final Value<String?> destination;
  final Value<int> fileCount;
  final Value<int> failureCount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ExportBatchesCompanion({
    this.id = const Value.absent(),
    this.outcome = const Value.absent(),
    this.destination = const Value.absent(),
    this.fileCount = const Value.absent(),
    this.failureCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportBatchesCompanion.insert({
    required String id,
    required ShareOutcome outcome,
    this.destination = const Value.absent(),
    required int fileCount,
    required int failureCount,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       outcome = Value(outcome),
       fileCount = Value(fileCount),
       failureCount = Value(failureCount),
       createdAt = Value(createdAt);
  static Insertable<ExportBatchRow> custom({
    Expression<String>? id,
    Expression<String>? outcome,
    Expression<String>? destination,
    Expression<int>? fileCount,
    Expression<int>? failureCount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (outcome != null) 'outcome': outcome,
      if (destination != null) 'destination': destination,
      if (fileCount != null) 'file_count': fileCount,
      if (failureCount != null) 'failure_count': failureCount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportBatchesCompanion copyWith({
    Value<String>? id,
    Value<ShareOutcome>? outcome,
    Value<String?>? destination,
    Value<int>? fileCount,
    Value<int>? failureCount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ExportBatchesCompanion(
      id: id ?? this.id,
      outcome: outcome ?? this.outcome,
      destination: destination ?? this.destination,
      fileCount: fileCount ?? this.fileCount,
      failureCount: failureCount ?? this.failureCount,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(
        ExportBatches.$converteroutcome.toSql(outcome.value),
      );
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (fileCount.present) {
      map['file_count'] = Variable<int>(fileCount.value);
    }
    if (failureCount.present) {
      map['failure_count'] = Variable<int>(failureCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchesCompanion(')
          ..write('id: $id, ')
          ..write('outcome: $outcome, ')
          ..write('destination: $destination, ')
          ..write('fileCount: $fileCount, ')
          ..write('failureCount: $failureCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExportBatchItems extends Table
    with TableInfo<ExportBatchItems, ExportBatchItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExportBatchItems(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES export_batches(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES capture_sessions(id)ON DELETE CASCADE',
  );
  late final GeneratedColumnWithTypeConverter<ExportFileKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (kind IN (\'finished\', \'original\'))',
      ).withConverter<ExportFileKind>(ExportBatchItems.$converterkind);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(source_id) BETWEEN 1 AND 64)',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(file_name) BETWEEN 5 AND 120)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    sessionId,
    kind,
    sourceId,
    fileName,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'export_batch_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExportBatchItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId, kind, sourceId};
  @override
  ExportBatchItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExportBatchItemRow(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      kind: ExportBatchItems.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
    );
  }

  @override
  ExportBatchItems createAlias(String alias) {
    return ExportBatchItems(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExportFileKind, String, String> $converterkind =
      const EnumNameConverter<ExportFileKind>(ExportFileKind.values);
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(batch_id, kind, source_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ExportBatchItemRow extends DataClass
    implements Insertable<ExportBatchItemRow> {
  final String batchId;
  final String sessionId;
  final ExportFileKind kind;
  final String sourceId;
  final String fileName;
  const ExportBatchItemRow({
    required this.batchId,
    required this.sessionId,
    required this.kind,
    required this.sourceId,
    required this.fileName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['session_id'] = Variable<String>(sessionId);
    {
      map['kind'] = Variable<String>(
        ExportBatchItems.$converterkind.toSql(kind),
      );
    }
    map['source_id'] = Variable<String>(sourceId);
    map['file_name'] = Variable<String>(fileName);
    return map;
  }

  ExportBatchItemsCompanion toCompanion(bool nullToAbsent) {
    return ExportBatchItemsCompanion(
      batchId: Value(batchId),
      sessionId: Value(sessionId),
      kind: Value(kind),
      sourceId: Value(sourceId),
      fileName: Value(fileName),
    );
  }

  factory ExportBatchItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExportBatchItemRow(
      batchId: serializer.fromJson<String>(json['batch_id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      kind: ExportBatchItems.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      sourceId: serializer.fromJson<String>(json['source_id']),
      fileName: serializer.fromJson<String>(json['file_name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batch_id': serializer.toJson<String>(batchId),
      'session_id': serializer.toJson<String>(sessionId),
      'kind': serializer.toJson<String>(
        ExportBatchItems.$converterkind.toJson(kind),
      ),
      'source_id': serializer.toJson<String>(sourceId),
      'file_name': serializer.toJson<String>(fileName),
    };
  }

  ExportBatchItemRow copyWith({
    String? batchId,
    String? sessionId,
    ExportFileKind? kind,
    String? sourceId,
    String? fileName,
  }) => ExportBatchItemRow(
    batchId: batchId ?? this.batchId,
    sessionId: sessionId ?? this.sessionId,
    kind: kind ?? this.kind,
    sourceId: sourceId ?? this.sourceId,
    fileName: fileName ?? this.fileName,
  );
  ExportBatchItemRow copyWithCompanion(ExportBatchItemsCompanion data) {
    return ExportBatchItemRow(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      kind: data.kind.present ? data.kind.value : this.kind,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchItemRow(')
          ..write('batchId: $batchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('sourceId: $sourceId, ')
          ..write('fileName: $fileName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(batchId, sessionId, kind, sourceId, fileName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExportBatchItemRow &&
          other.batchId == this.batchId &&
          other.sessionId == this.sessionId &&
          other.kind == this.kind &&
          other.sourceId == this.sourceId &&
          other.fileName == this.fileName);
}

class ExportBatchItemsCompanion extends UpdateCompanion<ExportBatchItemRow> {
  final Value<String> batchId;
  final Value<String> sessionId;
  final Value<ExportFileKind> kind;
  final Value<String> sourceId;
  final Value<String> fileName;
  final Value<int> rowid;
  const ExportBatchItemsCompanion({
    this.batchId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.kind = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExportBatchItemsCompanion.insert({
    required String batchId,
    required String sessionId,
    required ExportFileKind kind,
    required String sourceId,
    required String fileName,
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       sessionId = Value(sessionId),
       kind = Value(kind),
       sourceId = Value(sourceId),
       fileName = Value(fileName);
  static Insertable<ExportBatchItemRow> custom({
    Expression<String>? batchId,
    Expression<String>? sessionId,
    Expression<String>? kind,
    Expression<String>? sourceId,
    Expression<String>? fileName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (sessionId != null) 'session_id': sessionId,
      if (kind != null) 'kind': kind,
      if (sourceId != null) 'source_id': sourceId,
      if (fileName != null) 'file_name': fileName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExportBatchItemsCompanion copyWith({
    Value<String>? batchId,
    Value<String>? sessionId,
    Value<ExportFileKind>? kind,
    Value<String>? sourceId,
    Value<String>? fileName,
    Value<int>? rowid,
  }) {
    return ExportBatchItemsCompanion(
      batchId: batchId ?? this.batchId,
      sessionId: sessionId ?? this.sessionId,
      kind: kind ?? this.kind,
      sourceId: sourceId ?? this.sourceId,
      fileName: fileName ?? this.fileName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        ExportBatchItems.$converterkind.toSql(kind.value),
      );
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExportBatchItemsCompanion(')
          ..write('batchId: $batchId, ')
          ..write('sessionId: $sessionId, ')
          ..write('kind: $kind, ')
          ..write('sourceId: $sourceId, ')
          ..write('fileName: $fileName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PendingFileDeletions extends Table
    with TableInfo<PendingFileDeletions, PendingFileDeletionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PendingFileDeletions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(relative_path) BETWEEN 3 AND 255 AND relative_path NOT LIKE \'/%\' AND relative_path NOT LIKE \'%..%\' AND instr(relative_path, char(92)) = 0)',
  );
  static const VerificationMeta _queuedAtMeta = const VerificationMeta(
    'queuedAt',
  );
  late final GeneratedColumn<DateTime> queuedAt = GeneratedColumn<DateTime>(
    'queued_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [relativePath, queuedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_file_deletions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingFileDeletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('queued_at')) {
      context.handle(
        _queuedAtMeta,
        queuedAt.isAcceptableOrUnknown(data['queued_at']!, _queuedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queuedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {relativePath};
  @override
  PendingFileDeletionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingFileDeletionRow(
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      queuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}queued_at'],
      )!,
    );
  }

  @override
  PendingFileDeletions createAlias(String alias) {
    return PendingFileDeletions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PendingFileDeletionRow extends DataClass
    implements Insertable<PendingFileDeletionRow> {
  final String relativePath;
  final DateTime queuedAt;
  const PendingFileDeletionRow({
    required this.relativePath,
    required this.queuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['relative_path'] = Variable<String>(relativePath);
    map['queued_at'] = Variable<DateTime>(queuedAt);
    return map;
  }

  PendingFileDeletionsCompanion toCompanion(bool nullToAbsent) {
    return PendingFileDeletionsCompanion(
      relativePath: Value(relativePath),
      queuedAt: Value(queuedAt),
    );
  }

  factory PendingFileDeletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingFileDeletionRow(
      relativePath: serializer.fromJson<String>(json['relative_path']),
      queuedAt: serializer.fromJson<DateTime>(json['queued_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'relative_path': serializer.toJson<String>(relativePath),
      'queued_at': serializer.toJson<DateTime>(queuedAt),
    };
  }

  PendingFileDeletionRow copyWith({String? relativePath, DateTime? queuedAt}) =>
      PendingFileDeletionRow(
        relativePath: relativePath ?? this.relativePath,
        queuedAt: queuedAt ?? this.queuedAt,
      );
  PendingFileDeletionRow copyWithCompanion(PendingFileDeletionsCompanion data) {
    return PendingFileDeletionRow(
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      queuedAt: data.queuedAt.present ? data.queuedAt.value : this.queuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingFileDeletionRow(')
          ..write('relativePath: $relativePath, ')
          ..write('queuedAt: $queuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(relativePath, queuedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFileDeletionRow &&
          other.relativePath == this.relativePath &&
          other.queuedAt == this.queuedAt);
}

class PendingFileDeletionsCompanion
    extends UpdateCompanion<PendingFileDeletionRow> {
  final Value<String> relativePath;
  final Value<DateTime> queuedAt;
  final Value<int> rowid;
  const PendingFileDeletionsCompanion({
    this.relativePath = const Value.absent(),
    this.queuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingFileDeletionsCompanion.insert({
    required String relativePath,
    required DateTime queuedAt,
    this.rowid = const Value.absent(),
  }) : relativePath = Value(relativePath),
       queuedAt = Value(queuedAt);
  static Insertable<PendingFileDeletionRow> custom({
    Expression<String>? relativePath,
    Expression<DateTime>? queuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (relativePath != null) 'relative_path': relativePath,
      if (queuedAt != null) 'queued_at': queuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingFileDeletionsCompanion copyWith({
    Value<String>? relativePath,
    Value<DateTime>? queuedAt,
    Value<int>? rowid,
  }) {
    return PendingFileDeletionsCompanion(
      relativePath: relativePath ?? this.relativePath,
      queuedAt: queuedAt ?? this.queuedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (queuedAt.present) {
      map['queued_at'] = Variable<DateTime>(queuedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingFileDeletionsCompanion(')
          ..write('relativePath: $relativePath, ')
          ..write('queuedAt: $queuedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class EventDeliveryOptions extends Table
    with TableInfo<EventDeliveryOptions, EventDeliverySettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  EventDeliveryOptions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY REFERENCES events(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (enabled IN (0, 1))',
  );
  static const VerificationMeta _offlineQueueMeta = const VerificationMeta(
    'offlineQueue',
  );
  late final GeneratedColumn<bool> offlineQueue = GeneratedColumn<bool>(
    'offline_queue',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (offline_queue IN (0, 1))',
  );
  static const VerificationMeta _linkDaysMeta = const VerificationMeta(
    'linkDays',
  );
  late final GeneratedColumn<int> linkDays = GeneratedColumn<int>(
    'link_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (link_days BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _sendLimitMeta = const VerificationMeta(
    'sendLimit',
  );
  late final GeneratedColumn<int> sendLimit = GeneratedColumn<int>(
    'send_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (send_limit BETWEEN 1 AND 10000)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    enabled,
    offlineQueue,
    linkDays,
    sendLimit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_delivery_options';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventDeliverySettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    } else if (isInserting) {
      context.missing(_enabledMeta);
    }
    if (data.containsKey('offline_queue')) {
      context.handle(
        _offlineQueueMeta,
        offlineQueue.isAcceptableOrUnknown(
          data['offline_queue']!,
          _offlineQueueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_offlineQueueMeta);
    }
    if (data.containsKey('link_days')) {
      context.handle(
        _linkDaysMeta,
        linkDays.isAcceptableOrUnknown(data['link_days']!, _linkDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_linkDaysMeta);
    }
    if (data.containsKey('send_limit')) {
      context.handle(
        _sendLimitMeta,
        sendLimit.isAcceptableOrUnknown(data['send_limit']!, _sendLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_sendLimitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  EventDeliverySettingsRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventDeliverySettingsRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      offlineQueue: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}offline_queue'],
      )!,
      linkDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}link_days'],
      )!,
      sendLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_limit'],
      )!,
    );
  }

  @override
  EventDeliveryOptions createAlias(String alias) {
    return EventDeliveryOptions(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class EventDeliverySettingsRow extends DataClass
    implements Insertable<EventDeliverySettingsRow> {
  final String eventId;
  final bool enabled;
  final bool offlineQueue;
  final int linkDays;
  final int sendLimit;
  const EventDeliverySettingsRow({
    required this.eventId,
    required this.enabled,
    required this.offlineQueue,
    required this.linkDays,
    required this.sendLimit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['enabled'] = Variable<bool>(enabled);
    map['offline_queue'] = Variable<bool>(offlineQueue);
    map['link_days'] = Variable<int>(linkDays);
    map['send_limit'] = Variable<int>(sendLimit);
    return map;
  }

  EventDeliveryOptionsCompanion toCompanion(bool nullToAbsent) {
    return EventDeliveryOptionsCompanion(
      eventId: Value(eventId),
      enabled: Value(enabled),
      offlineQueue: Value(offlineQueue),
      linkDays: Value(linkDays),
      sendLimit: Value(sendLimit),
    );
  }

  factory EventDeliverySettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventDeliverySettingsRow(
      eventId: serializer.fromJson<String>(json['event_id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      offlineQueue: serializer.fromJson<bool>(json['offline_queue']),
      linkDays: serializer.fromJson<int>(json['link_days']),
      sendLimit: serializer.fromJson<int>(json['send_limit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'event_id': serializer.toJson<String>(eventId),
      'enabled': serializer.toJson<bool>(enabled),
      'offline_queue': serializer.toJson<bool>(offlineQueue),
      'link_days': serializer.toJson<int>(linkDays),
      'send_limit': serializer.toJson<int>(sendLimit),
    };
  }

  EventDeliverySettingsRow copyWith({
    String? eventId,
    bool? enabled,
    bool? offlineQueue,
    int? linkDays,
    int? sendLimit,
  }) => EventDeliverySettingsRow(
    eventId: eventId ?? this.eventId,
    enabled: enabled ?? this.enabled,
    offlineQueue: offlineQueue ?? this.offlineQueue,
    linkDays: linkDays ?? this.linkDays,
    sendLimit: sendLimit ?? this.sendLimit,
  );
  EventDeliverySettingsRow copyWithCompanion(
    EventDeliveryOptionsCompanion data,
  ) {
    return EventDeliverySettingsRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      offlineQueue: data.offlineQueue.present
          ? data.offlineQueue.value
          : this.offlineQueue,
      linkDays: data.linkDays.present ? data.linkDays.value : this.linkDays,
      sendLimit: data.sendLimit.present ? data.sendLimit.value : this.sendLimit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventDeliverySettingsRow(')
          ..write('eventId: $eventId, ')
          ..write('enabled: $enabled, ')
          ..write('offlineQueue: $offlineQueue, ')
          ..write('linkDays: $linkDays, ')
          ..write('sendLimit: $sendLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(eventId, enabled, offlineQueue, linkDays, sendLimit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventDeliverySettingsRow &&
          other.eventId == this.eventId &&
          other.enabled == this.enabled &&
          other.offlineQueue == this.offlineQueue &&
          other.linkDays == this.linkDays &&
          other.sendLimit == this.sendLimit);
}

class EventDeliveryOptionsCompanion
    extends UpdateCompanion<EventDeliverySettingsRow> {
  final Value<String> eventId;
  final Value<bool> enabled;
  final Value<bool> offlineQueue;
  final Value<int> linkDays;
  final Value<int> sendLimit;
  final Value<int> rowid;
  const EventDeliveryOptionsCompanion({
    this.eventId = const Value.absent(),
    this.enabled = const Value.absent(),
    this.offlineQueue = const Value.absent(),
    this.linkDays = const Value.absent(),
    this.sendLimit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventDeliveryOptionsCompanion.insert({
    required String eventId,
    required bool enabled,
    required bool offlineQueue,
    required int linkDays,
    required int sendLimit,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       enabled = Value(enabled),
       offlineQueue = Value(offlineQueue),
       linkDays = Value(linkDays),
       sendLimit = Value(sendLimit);
  static Insertable<EventDeliverySettingsRow> custom({
    Expression<String>? eventId,
    Expression<bool>? enabled,
    Expression<bool>? offlineQueue,
    Expression<int>? linkDays,
    Expression<int>? sendLimit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (enabled != null) 'enabled': enabled,
      if (offlineQueue != null) 'offline_queue': offlineQueue,
      if (linkDays != null) 'link_days': linkDays,
      if (sendLimit != null) 'send_limit': sendLimit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventDeliveryOptionsCompanion copyWith({
    Value<String>? eventId,
    Value<bool>? enabled,
    Value<bool>? offlineQueue,
    Value<int>? linkDays,
    Value<int>? sendLimit,
    Value<int>? rowid,
  }) {
    return EventDeliveryOptionsCompanion(
      eventId: eventId ?? this.eventId,
      enabled: enabled ?? this.enabled,
      offlineQueue: offlineQueue ?? this.offlineQueue,
      linkDays: linkDays ?? this.linkDays,
      sendLimit: sendLimit ?? this.sendLimit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (offlineQueue.present) {
      map['offline_queue'] = Variable<bool>(offlineQueue.value);
    }
    if (linkDays.present) {
      map['link_days'] = Variable<int>(linkDays.value);
    }
    if (sendLimit.present) {
      map['send_limit'] = Variable<int>(sendLimit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventDeliveryOptionsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('enabled: $enabled, ')
          ..write('offlineQueue: $offlineQueue, ')
          ..write('linkDays: $linkDays, ')
          ..write('sendLimit: $sendLimit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeliveryPairings extends Table
    with TableInfo<DeliveryPairings, DeliveryPairingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeliveryPairings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _baseUrlMeta = const VerificationMeta(
    'baseUrl',
  );
  late final GeneratedColumn<String> baseUrl = GeneratedColumn<String>(
    'base_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(base_url) BETWEEN 9 AND 200 AND(base_url LIKE \'https://%\' OR base_url LIKE \'http://127.0.0.1:%\' OR base_url LIKE \'http://localhost:%\'))',
  );
  static const VerificationMeta _boothIdMeta = const VerificationMeta(
    'boothId',
  );
  late final GeneratedColumn<String> boothId = GeneratedColumn<String>(
    'booth_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(booth_id) = 36)',
  );
  static const VerificationMeta _boothNameMeta = const VerificationMeta(
    'boothName',
  );
  late final GeneratedColumn<String> boothName = GeneratedColumn<String>(
    'booth_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(booth_name) BETWEEN 1 AND 40)',
  );
  static const VerificationMeta _brandNameMeta = const VerificationMeta(
    'brandName',
  );
  late final GeneratedColumn<String> brandName = GeneratedColumn<String>(
    'brand_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(brand_name) BETWEEN 1 AND 40)',
  );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  late final GeneratedColumn<DateTime> pairedAt = GeneratedColumn<DateTime>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (paused IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _capabilitiesJsonMeta = const VerificationMeta(
    'capabilitiesJson',
  );
  late final GeneratedColumn<String> capabilitiesJson = GeneratedColumn<String>(
    'capabilities_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (capabilities_json IS NULL OR length(capabilities_json) <= 8192)',
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  late final GeneratedColumn<DateTime> checkedAt = GeneratedColumn<DateTime>(
    'checked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    baseUrl,
    boothId,
    boothName,
    brandName,
    pairedAt,
    paused,
    capabilitiesJson,
    checkedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_pairings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryPairingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_url')) {
      context.handle(
        _baseUrlMeta,
        baseUrl.isAcceptableOrUnknown(data['base_url']!, _baseUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_baseUrlMeta);
    }
    if (data.containsKey('booth_id')) {
      context.handle(
        _boothIdMeta,
        boothId.isAcceptableOrUnknown(data['booth_id']!, _boothIdMeta),
      );
    } else if (isInserting) {
      context.missing(_boothIdMeta);
    }
    if (data.containsKey('booth_name')) {
      context.handle(
        _boothNameMeta,
        boothName.isAcceptableOrUnknown(data['booth_name']!, _boothNameMeta),
      );
    } else if (isInserting) {
      context.missing(_boothNameMeta);
    }
    if (data.containsKey('brand_name')) {
      context.handle(
        _brandNameMeta,
        brandName.isAcceptableOrUnknown(data['brand_name']!, _brandNameMeta),
      );
    } else if (isInserting) {
      context.missing(_brandNameMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    if (data.containsKey('capabilities_json')) {
      context.handle(
        _capabilitiesJsonMeta,
        capabilitiesJson.isAcceptableOrUnknown(
          data['capabilities_json']!,
          _capabilitiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryPairingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryPairingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      baseUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_url'],
      )!,
      boothId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booth_id'],
      )!,
      boothName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}booth_name'],
      )!,
      brandName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand_name'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paired_at'],
      )!,
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      capabilitiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capabilities_json'],
      ),
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}checked_at'],
      ),
    );
  }

  @override
  DeliveryPairings createAlias(String alias) {
    return DeliveryPairings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DeliveryPairingRow extends DataClass
    implements Insertable<DeliveryPairingRow> {
  final int id;
  final String baseUrl;
  final String boothId;
  final String boothName;
  final String brandName;
  final DateTime pairedAt;
  final bool paused;

  /// The service's last answer about this booth (readiness, sender
  /// identity, privacy and terms addresses, limits), so the consent screen
  /// can be shown while offline; and when it was received.
  final String? capabilitiesJson;
  final DateTime? checkedAt;
  const DeliveryPairingRow({
    required this.id,
    required this.baseUrl,
    required this.boothId,
    required this.boothName,
    required this.brandName,
    required this.pairedAt,
    required this.paused,
    this.capabilitiesJson,
    this.checkedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_url'] = Variable<String>(baseUrl);
    map['booth_id'] = Variable<String>(boothId);
    map['booth_name'] = Variable<String>(boothName);
    map['brand_name'] = Variable<String>(brandName);
    map['paired_at'] = Variable<DateTime>(pairedAt);
    map['paused'] = Variable<bool>(paused);
    if (!nullToAbsent || capabilitiesJson != null) {
      map['capabilities_json'] = Variable<String>(capabilitiesJson);
    }
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<DateTime>(checkedAt);
    }
    return map;
  }

  DeliveryPairingsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryPairingsCompanion(
      id: Value(id),
      baseUrl: Value(baseUrl),
      boothId: Value(boothId),
      boothName: Value(boothName),
      brandName: Value(brandName),
      pairedAt: Value(pairedAt),
      paused: Value(paused),
      capabilitiesJson: capabilitiesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(capabilitiesJson),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
    );
  }

  factory DeliveryPairingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryPairingRow(
      id: serializer.fromJson<int>(json['id']),
      baseUrl: serializer.fromJson<String>(json['base_url']),
      boothId: serializer.fromJson<String>(json['booth_id']),
      boothName: serializer.fromJson<String>(json['booth_name']),
      brandName: serializer.fromJson<String>(json['brand_name']),
      pairedAt: serializer.fromJson<DateTime>(json['paired_at']),
      paused: serializer.fromJson<bool>(json['paused']),
      capabilitiesJson: serializer.fromJson<String?>(json['capabilities_json']),
      checkedAt: serializer.fromJson<DateTime?>(json['checked_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'base_url': serializer.toJson<String>(baseUrl),
      'booth_id': serializer.toJson<String>(boothId),
      'booth_name': serializer.toJson<String>(boothName),
      'brand_name': serializer.toJson<String>(brandName),
      'paired_at': serializer.toJson<DateTime>(pairedAt),
      'paused': serializer.toJson<bool>(paused),
      'capabilities_json': serializer.toJson<String?>(capabilitiesJson),
      'checked_at': serializer.toJson<DateTime?>(checkedAt),
    };
  }

  DeliveryPairingRow copyWith({
    int? id,
    String? baseUrl,
    String? boothId,
    String? boothName,
    String? brandName,
    DateTime? pairedAt,
    bool? paused,
    Value<String?> capabilitiesJson = const Value.absent(),
    Value<DateTime?> checkedAt = const Value.absent(),
  }) => DeliveryPairingRow(
    id: id ?? this.id,
    baseUrl: baseUrl ?? this.baseUrl,
    boothId: boothId ?? this.boothId,
    boothName: boothName ?? this.boothName,
    brandName: brandName ?? this.brandName,
    pairedAt: pairedAt ?? this.pairedAt,
    paused: paused ?? this.paused,
    capabilitiesJson: capabilitiesJson.present
        ? capabilitiesJson.value
        : this.capabilitiesJson,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
  );
  DeliveryPairingRow copyWithCompanion(DeliveryPairingsCompanion data) {
    return DeliveryPairingRow(
      id: data.id.present ? data.id.value : this.id,
      baseUrl: data.baseUrl.present ? data.baseUrl.value : this.baseUrl,
      boothId: data.boothId.present ? data.boothId.value : this.boothId,
      boothName: data.boothName.present ? data.boothName.value : this.boothName,
      brandName: data.brandName.present ? data.brandName.value : this.brandName,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      paused: data.paused.present ? data.paused.value : this.paused,
      capabilitiesJson: data.capabilitiesJson.present
          ? data.capabilitiesJson.value
          : this.capabilitiesJson,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryPairingRow(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('boothId: $boothId, ')
          ..write('boothName: $boothName, ')
          ..write('brandName: $brandName, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('paused: $paused, ')
          ..write('capabilitiesJson: $capabilitiesJson, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    baseUrl,
    boothId,
    boothName,
    brandName,
    pairedAt,
    paused,
    capabilitiesJson,
    checkedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryPairingRow &&
          other.id == this.id &&
          other.baseUrl == this.baseUrl &&
          other.boothId == this.boothId &&
          other.boothName == this.boothName &&
          other.brandName == this.brandName &&
          other.pairedAt == this.pairedAt &&
          other.paused == this.paused &&
          other.capabilitiesJson == this.capabilitiesJson &&
          other.checkedAt == this.checkedAt);
}

class DeliveryPairingsCompanion extends UpdateCompanion<DeliveryPairingRow> {
  final Value<int> id;
  final Value<String> baseUrl;
  final Value<String> boothId;
  final Value<String> boothName;
  final Value<String> brandName;
  final Value<DateTime> pairedAt;
  final Value<bool> paused;
  final Value<String?> capabilitiesJson;
  final Value<DateTime?> checkedAt;
  const DeliveryPairingsCompanion({
    this.id = const Value.absent(),
    this.baseUrl = const Value.absent(),
    this.boothId = const Value.absent(),
    this.boothName = const Value.absent(),
    this.brandName = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.paused = const Value.absent(),
    this.capabilitiesJson = const Value.absent(),
    this.checkedAt = const Value.absent(),
  });
  DeliveryPairingsCompanion.insert({
    this.id = const Value.absent(),
    required String baseUrl,
    required String boothId,
    required String boothName,
    required String brandName,
    required DateTime pairedAt,
    this.paused = const Value.absent(),
    this.capabilitiesJson = const Value.absent(),
    this.checkedAt = const Value.absent(),
  }) : baseUrl = Value(baseUrl),
       boothId = Value(boothId),
       boothName = Value(boothName),
       brandName = Value(brandName),
       pairedAt = Value(pairedAt);
  static Insertable<DeliveryPairingRow> custom({
    Expression<int>? id,
    Expression<String>? baseUrl,
    Expression<String>? boothId,
    Expression<String>? boothName,
    Expression<String>? brandName,
    Expression<DateTime>? pairedAt,
    Expression<bool>? paused,
    Expression<String>? capabilitiesJson,
    Expression<DateTime>? checkedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseUrl != null) 'base_url': baseUrl,
      if (boothId != null) 'booth_id': boothId,
      if (boothName != null) 'booth_name': boothName,
      if (brandName != null) 'brand_name': brandName,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (paused != null) 'paused': paused,
      if (capabilitiesJson != null) 'capabilities_json': capabilitiesJson,
      if (checkedAt != null) 'checked_at': checkedAt,
    });
  }

  DeliveryPairingsCompanion copyWith({
    Value<int>? id,
    Value<String>? baseUrl,
    Value<String>? boothId,
    Value<String>? boothName,
    Value<String>? brandName,
    Value<DateTime>? pairedAt,
    Value<bool>? paused,
    Value<String?>? capabilitiesJson,
    Value<DateTime?>? checkedAt,
  }) {
    return DeliveryPairingsCompanion(
      id: id ?? this.id,
      baseUrl: baseUrl ?? this.baseUrl,
      boothId: boothId ?? this.boothId,
      boothName: boothName ?? this.boothName,
      brandName: brandName ?? this.brandName,
      pairedAt: pairedAt ?? this.pairedAt,
      paused: paused ?? this.paused,
      capabilitiesJson: capabilitiesJson ?? this.capabilitiesJson,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseUrl.present) {
      map['base_url'] = Variable<String>(baseUrl.value);
    }
    if (boothId.present) {
      map['booth_id'] = Variable<String>(boothId.value);
    }
    if (boothName.present) {
      map['booth_name'] = Variable<String>(boothName.value);
    }
    if (brandName.present) {
      map['brand_name'] = Variable<String>(brandName.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<DateTime>(pairedAt.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (capabilitiesJson.present) {
      map['capabilities_json'] = Variable<String>(capabilitiesJson.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<DateTime>(checkedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryPairingsCompanion(')
          ..write('id: $id, ')
          ..write('baseUrl: $baseUrl, ')
          ..write('boothId: $boothId, ')
          ..write('boothName: $boothName, ')
          ..write('brandName: $brandName, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('paused: $paused, ')
          ..write('capabilitiesJson: $capabilitiesJson, ')
          ..write('checkedAt: $checkedAt')
          ..write(')'))
        .toString();
  }
}

class DeliveryIntents extends Table
    with TableInfo<DeliveryIntents, DeliveryIntentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeliveryIntents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (length(id) = 36)',
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES capture_sessions(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(event_id) = 36)',
  );
  static const VerificationMeta _outputIdMeta = const VerificationMeta(
    'outputId',
  );
  late final GeneratedColumn<String> outputId = GeneratedColumn<String>(
    'output_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(output_id) = 36)',
  );
  static const VerificationMeta _phoneLast4Meta = const VerificationMeta(
    'phoneLast4',
  );
  late final GeneratedColumn<String> phoneLast4 = GeneratedColumn<String>(
    'phone_last4',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(phone_last4) = 4 AND phone_last4 NOT GLOB \'*[^0-9]*\')',
  );
  static const VerificationMeta _phoneStoredMeta = const VerificationMeta(
    'phoneStored',
  );
  late final GeneratedColumn<bool> phoneStored = GeneratedColumn<bool>(
    'phone_stored',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (phone_stored IN (0, 1))',
  );
  static const VerificationMeta _consentTextVersionMeta =
      const VerificationMeta('consentTextVersion');
  late final GeneratedColumn<String> consentTextVersion =
      GeneratedColumn<String>(
        'consent_text_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (length(consent_text_version) BETWEEN 1 AND 32)',
      );
  static const VerificationMeta _consentTextDigestMeta = const VerificationMeta(
    'consentTextDigest',
  );
  late final GeneratedColumn<String> consentTextDigest =
      GeneratedColumn<String>(
        'consent_text_digest',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (length(consent_text_digest) = 64 AND consent_text_digest NOT GLOB \'*[^0-9a-f]*\')',
      );
  static const VerificationMeta _consentAcceptedAtMeta = const VerificationMeta(
    'consentAcceptedAt',
  );
  late final GeneratedColumn<DateTime> consentAcceptedAt =
      GeneratedColumn<DateTime>(
        'consent_accepted_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(locale) BETWEEN 2 AND 5)',
  );
  static const VerificationMeta _linkDaysMeta = const VerificationMeta(
    'linkDays',
  );
  late final GeneratedColumn<int> linkDays = GeneratedColumn<int>(
    'link_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (link_days BETWEEN 1 AND 30)',
  );
  static const VerificationMeta _sendLimitMeta = const VerificationMeta(
    'sendLimit',
  );
  late final GeneratedColumn<int> sendLimit = GeneratedColumn<int>(
    'send_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (send_limit BETWEEN 1 AND 10000)',
  );
  static const VerificationMeta _queueAllowedMeta = const VerificationMeta(
    'queueAllowed',
  );
  late final GeneratedColumn<bool> queueAllowed = GeneratedColumn<bool>(
    'queue_allowed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (queue_allowed IN (0, 1))',
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL UNIQUE CHECK (length(idempotency_key) BETWEEN 16 AND 64)',
  );
  late final GeneratedColumnWithTypeConverter<DeliveryIntentState, String>
  state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (state IN (\'queued\', \'handingOver\', \'handedOver\', \'finished\'))',
  ).withConverter<DeliveryIntentState>(DeliveryIntents.$converterstate);
  late final GeneratedColumnWithTypeConverter<DeliveryPhase?, String>
  localOutcome = GeneratedColumn<String>(
    'local_outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (local_outcome IS NULL OR local_outcome IN (\'failed\', \'expired\', \'canceled\'))',
  ).withConverter<DeliveryPhase?>(DeliveryIntents.$converterlocalOutcomen);
  static const VerificationMeta _remoteJobIdMeta = const VerificationMeta(
    'remoteJobId',
  );
  late final GeneratedColumn<String> remoteJobId = GeneratedColumn<String>(
    'remote_job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (remote_job_id IS NULL OR length(remote_job_id) = 36)',
  );
  static const VerificationMeta _remoteStatusMeta = const VerificationMeta(
    'remoteStatus',
  );
  late final GeneratedColumn<String> remoteStatus = GeneratedColumn<String>(
    'remote_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (remote_status IS NULL OR remote_status IN (\'queued\', \'uploading\', \'submitting\', \'submitted\', \'sent\', \'delivered\', \'failed\', \'unknown\', \'expired\', \'canceled\'))',
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  late final GeneratedColumn<DateTime> remoteUpdatedAt =
      GeneratedColumn<DateTime>(
        'remote_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (last_error_code IS NULL OR length(last_error_code) BETWEEN 2 AND 64)',
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (attempt_count >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _retryAtMeta = const VerificationMeta(
    'retryAt',
  );
  late final GeneratedColumn<DateTime> retryAt = GeneratedColumn<DateTime>(
    'retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _historyJsonMeta = const VerificationMeta(
    'historyJson',
  );
  late final GeneratedColumn<String> historyJson = GeneratedColumn<String>(
    'history_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (length(history_json) BETWEEN 2 AND 8192)',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    eventId,
    outputId,
    phoneLast4,
    phoneStored,
    consentTextVersion,
    consentTextDigest,
    consentAcceptedAt,
    locale,
    linkDays,
    sendLimit,
    queueAllowed,
    idempotencyKey,
    state,
    localOutcome,
    remoteJobId,
    remoteStatus,
    remoteUpdatedAt,
    lastErrorCode,
    attemptCount,
    retryAt,
    expiresAt,
    historyJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_intents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryIntentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('output_id')) {
      context.handle(
        _outputIdMeta,
        outputId.isAcceptableOrUnknown(data['output_id']!, _outputIdMeta),
      );
    } else if (isInserting) {
      context.missing(_outputIdMeta);
    }
    if (data.containsKey('phone_last4')) {
      context.handle(
        _phoneLast4Meta,
        phoneLast4.isAcceptableOrUnknown(data['phone_last4']!, _phoneLast4Meta),
      );
    } else if (isInserting) {
      context.missing(_phoneLast4Meta);
    }
    if (data.containsKey('phone_stored')) {
      context.handle(
        _phoneStoredMeta,
        phoneStored.isAcceptableOrUnknown(
          data['phone_stored']!,
          _phoneStoredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_phoneStoredMeta);
    }
    if (data.containsKey('consent_text_version')) {
      context.handle(
        _consentTextVersionMeta,
        consentTextVersion.isAcceptableOrUnknown(
          data['consent_text_version']!,
          _consentTextVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentTextVersionMeta);
    }
    if (data.containsKey('consent_text_digest')) {
      context.handle(
        _consentTextDigestMeta,
        consentTextDigest.isAcceptableOrUnknown(
          data['consent_text_digest']!,
          _consentTextDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentTextDigestMeta);
    }
    if (data.containsKey('consent_accepted_at')) {
      context.handle(
        _consentAcceptedAtMeta,
        consentAcceptedAt.isAcceptableOrUnknown(
          data['consent_accepted_at']!,
          _consentAcceptedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentAcceptedAtMeta);
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    } else if (isInserting) {
      context.missing(_localeMeta);
    }
    if (data.containsKey('link_days')) {
      context.handle(
        _linkDaysMeta,
        linkDays.isAcceptableOrUnknown(data['link_days']!, _linkDaysMeta),
      );
    } else if (isInserting) {
      context.missing(_linkDaysMeta);
    }
    if (data.containsKey('send_limit')) {
      context.handle(
        _sendLimitMeta,
        sendLimit.isAcceptableOrUnknown(data['send_limit']!, _sendLimitMeta),
      );
    } else if (isInserting) {
      context.missing(_sendLimitMeta);
    }
    if (data.containsKey('queue_allowed')) {
      context.handle(
        _queueAllowedMeta,
        queueAllowed.isAcceptableOrUnknown(
          data['queue_allowed']!,
          _queueAllowedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_queueAllowedMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('remote_job_id')) {
      context.handle(
        _remoteJobIdMeta,
        remoteJobId.isAcceptableOrUnknown(
          data['remote_job_id']!,
          _remoteJobIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_status')) {
      context.handle(
        _remoteStatusMeta,
        remoteStatus.isAcceptableOrUnknown(
          data['remote_status']!,
          _remoteStatusMeta,
        ),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('retry_at')) {
      context.handle(
        _retryAtMeta,
        retryAt.isAcceptableOrUnknown(data['retry_at']!, _retryAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('history_json')) {
      context.handle(
        _historyJsonMeta,
        historyJson.isAcceptableOrUnknown(
          data['history_json']!,
          _historyJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeliveryIntentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryIntentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      outputId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_id'],
      )!,
      phoneLast4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_last4'],
      )!,
      phoneStored: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}phone_stored'],
      )!,
      consentTextVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_text_version'],
      )!,
      consentTextDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_text_digest'],
      )!,
      consentAcceptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}consent_accepted_at'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      linkDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}link_days'],
      )!,
      sendLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_limit'],
      )!,
      queueAllowed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}queue_allowed'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      state: DeliveryIntents.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      localOutcome: DeliveryIntents.$converterlocalOutcomen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}local_outcome'],
        ),
      ),
      remoteJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_job_id'],
      ),
      remoteStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_status'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remote_updated_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      retryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}retry_at'],
      ),
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
      historyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}history_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  DeliveryIntents createAlias(String alias) {
    return DeliveryIntents(attachedDatabase, alias);
  }

  static JsonTypeConverter2<DeliveryIntentState, String, String>
  $converterstate = deliveryIntentStateByName;
  static JsonTypeConverter2<DeliveryPhase, String, String>
  $converterlocalOutcome = const EnumNameConverter<DeliveryPhase>(
    DeliveryPhase.values,
  );
  static JsonTypeConverter2<DeliveryPhase?, String?, String?>
  $converterlocalOutcomen = JsonTypeConverter2.asNullable(
    $converterlocalOutcome,
  );
  @override
  List<String> get customConstraints => const [
    'CHECK((state = \'finished\')=(local_outcome IS NOT NULL OR remote_status IN (\'delivered\', \'failed\', \'expired\', \'canceled\') OR last_error_code = \'NO_LONGER_AT_SERVICE\'))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DeliveryIntentRow extends DataClass
    implements Insertable<DeliveryIntentRow> {
  final String id;
  final String sessionId;
  final String eventId;
  final String outputId;
  final String phoneLast4;
  final bool phoneStored;
  final String consentTextVersion;
  final String consentTextDigest;
  final DateTime consentAcceptedAt;
  final String locale;
  final int linkDays;
  final int sendLimit;

  /// Whether the event allowed waiting for a connection when the guest
  /// asked (otherwise a request that cannot go at once is not kept).
  final bool queueAllowed;
  final String idempotencyKey;

  /// Mapped explicitly: "DeliveryIntentState" contains "INT" (see
  /// booth_profiles.theme_profile).
  final DeliveryIntentState state;
  final DeliveryPhase? localOutcome;
  final String? remoteJobId;
  final String? remoteStatus;
  final DateTime? remoteUpdatedAt;
  final String? lastErrorCode;
  final int attemptCount;
  final DateTime? retryAt;
  final DateTime expiresAt;
  final String historyJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeliveryIntentRow({
    required this.id,
    required this.sessionId,
    required this.eventId,
    required this.outputId,
    required this.phoneLast4,
    required this.phoneStored,
    required this.consentTextVersion,
    required this.consentTextDigest,
    required this.consentAcceptedAt,
    required this.locale,
    required this.linkDays,
    required this.sendLimit,
    required this.queueAllowed,
    required this.idempotencyKey,
    required this.state,
    this.localOutcome,
    this.remoteJobId,
    this.remoteStatus,
    this.remoteUpdatedAt,
    this.lastErrorCode,
    required this.attemptCount,
    this.retryAt,
    required this.expiresAt,
    required this.historyJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['event_id'] = Variable<String>(eventId);
    map['output_id'] = Variable<String>(outputId);
    map['phone_last4'] = Variable<String>(phoneLast4);
    map['phone_stored'] = Variable<bool>(phoneStored);
    map['consent_text_version'] = Variable<String>(consentTextVersion);
    map['consent_text_digest'] = Variable<String>(consentTextDigest);
    map['consent_accepted_at'] = Variable<DateTime>(consentAcceptedAt);
    map['locale'] = Variable<String>(locale);
    map['link_days'] = Variable<int>(linkDays);
    map['send_limit'] = Variable<int>(sendLimit);
    map['queue_allowed'] = Variable<bool>(queueAllowed);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    {
      map['state'] = Variable<String>(
        DeliveryIntents.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || localOutcome != null) {
      map['local_outcome'] = Variable<String>(
        DeliveryIntents.$converterlocalOutcomen.toSql(localOutcome),
      );
    }
    if (!nullToAbsent || remoteJobId != null) {
      map['remote_job_id'] = Variable<String>(remoteJobId);
    }
    if (!nullToAbsent || remoteStatus != null) {
      map['remote_status'] = Variable<String>(remoteStatus);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || retryAt != null) {
      map['retry_at'] = Variable<DateTime>(retryAt);
    }
    map['expires_at'] = Variable<DateTime>(expiresAt);
    map['history_json'] = Variable<String>(historyJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeliveryIntentsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryIntentsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      eventId: Value(eventId),
      outputId: Value(outputId),
      phoneLast4: Value(phoneLast4),
      phoneStored: Value(phoneStored),
      consentTextVersion: Value(consentTextVersion),
      consentTextDigest: Value(consentTextDigest),
      consentAcceptedAt: Value(consentAcceptedAt),
      locale: Value(locale),
      linkDays: Value(linkDays),
      sendLimit: Value(sendLimit),
      queueAllowed: Value(queueAllowed),
      idempotencyKey: Value(idempotencyKey),
      state: Value(state),
      localOutcome: localOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(localOutcome),
      remoteJobId: remoteJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteJobId),
      remoteStatus: remoteStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteStatus),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      attemptCount: Value(attemptCount),
      retryAt: retryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(retryAt),
      expiresAt: Value(expiresAt),
      historyJson: Value(historyJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeliveryIntentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryIntentRow(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['session_id']),
      eventId: serializer.fromJson<String>(json['event_id']),
      outputId: serializer.fromJson<String>(json['output_id']),
      phoneLast4: serializer.fromJson<String>(json['phone_last4']),
      phoneStored: serializer.fromJson<bool>(json['phone_stored']),
      consentTextVersion: serializer.fromJson<String>(
        json['consent_text_version'],
      ),
      consentTextDigest: serializer.fromJson<String>(
        json['consent_text_digest'],
      ),
      consentAcceptedAt: serializer.fromJson<DateTime>(
        json['consent_accepted_at'],
      ),
      locale: serializer.fromJson<String>(json['locale']),
      linkDays: serializer.fromJson<int>(json['link_days']),
      sendLimit: serializer.fromJson<int>(json['send_limit']),
      queueAllowed: serializer.fromJson<bool>(json['queue_allowed']),
      idempotencyKey: serializer.fromJson<String>(json['idempotency_key']),
      state: DeliveryIntents.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      localOutcome: DeliveryIntents.$converterlocalOutcomen.fromJson(
        serializer.fromJson<String?>(json['local_outcome']),
      ),
      remoteJobId: serializer.fromJson<String?>(json['remote_job_id']),
      remoteStatus: serializer.fromJson<String?>(json['remote_status']),
      remoteUpdatedAt: serializer.fromJson<DateTime?>(
        json['remote_updated_at'],
      ),
      lastErrorCode: serializer.fromJson<String?>(json['last_error_code']),
      attemptCount: serializer.fromJson<int>(json['attempt_count']),
      retryAt: serializer.fromJson<DateTime?>(json['retry_at']),
      expiresAt: serializer.fromJson<DateTime>(json['expires_at']),
      historyJson: serializer.fromJson<String>(json['history_json']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
      updatedAt: serializer.fromJson<DateTime>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'session_id': serializer.toJson<String>(sessionId),
      'event_id': serializer.toJson<String>(eventId),
      'output_id': serializer.toJson<String>(outputId),
      'phone_last4': serializer.toJson<String>(phoneLast4),
      'phone_stored': serializer.toJson<bool>(phoneStored),
      'consent_text_version': serializer.toJson<String>(consentTextVersion),
      'consent_text_digest': serializer.toJson<String>(consentTextDigest),
      'consent_accepted_at': serializer.toJson<DateTime>(consentAcceptedAt),
      'locale': serializer.toJson<String>(locale),
      'link_days': serializer.toJson<int>(linkDays),
      'send_limit': serializer.toJson<int>(sendLimit),
      'queue_allowed': serializer.toJson<bool>(queueAllowed),
      'idempotency_key': serializer.toJson<String>(idempotencyKey),
      'state': serializer.toJson<String>(
        DeliveryIntents.$converterstate.toJson(state),
      ),
      'local_outcome': serializer.toJson<String?>(
        DeliveryIntents.$converterlocalOutcomen.toJson(localOutcome),
      ),
      'remote_job_id': serializer.toJson<String?>(remoteJobId),
      'remote_status': serializer.toJson<String?>(remoteStatus),
      'remote_updated_at': serializer.toJson<DateTime?>(remoteUpdatedAt),
      'last_error_code': serializer.toJson<String?>(lastErrorCode),
      'attempt_count': serializer.toJson<int>(attemptCount),
      'retry_at': serializer.toJson<DateTime?>(retryAt),
      'expires_at': serializer.toJson<DateTime>(expiresAt),
      'history_json': serializer.toJson<String>(historyJson),
      'created_at': serializer.toJson<DateTime>(createdAt),
      'updated_at': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeliveryIntentRow copyWith({
    String? id,
    String? sessionId,
    String? eventId,
    String? outputId,
    String? phoneLast4,
    bool? phoneStored,
    String? consentTextVersion,
    String? consentTextDigest,
    DateTime? consentAcceptedAt,
    String? locale,
    int? linkDays,
    int? sendLimit,
    bool? queueAllowed,
    String? idempotencyKey,
    DeliveryIntentState? state,
    Value<DeliveryPhase?> localOutcome = const Value.absent(),
    Value<String?> remoteJobId = const Value.absent(),
    Value<String?> remoteStatus = const Value.absent(),
    Value<DateTime?> remoteUpdatedAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    int? attemptCount,
    Value<DateTime?> retryAt = const Value.absent(),
    DateTime? expiresAt,
    String? historyJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DeliveryIntentRow(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    eventId: eventId ?? this.eventId,
    outputId: outputId ?? this.outputId,
    phoneLast4: phoneLast4 ?? this.phoneLast4,
    phoneStored: phoneStored ?? this.phoneStored,
    consentTextVersion: consentTextVersion ?? this.consentTextVersion,
    consentTextDigest: consentTextDigest ?? this.consentTextDigest,
    consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
    locale: locale ?? this.locale,
    linkDays: linkDays ?? this.linkDays,
    sendLimit: sendLimit ?? this.sendLimit,
    queueAllowed: queueAllowed ?? this.queueAllowed,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    state: state ?? this.state,
    localOutcome: localOutcome.present ? localOutcome.value : this.localOutcome,
    remoteJobId: remoteJobId.present ? remoteJobId.value : this.remoteJobId,
    remoteStatus: remoteStatus.present ? remoteStatus.value : this.remoteStatus,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    attemptCount: attemptCount ?? this.attemptCount,
    retryAt: retryAt.present ? retryAt.value : this.retryAt,
    expiresAt: expiresAt ?? this.expiresAt,
    historyJson: historyJson ?? this.historyJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeliveryIntentRow copyWithCompanion(DeliveryIntentsCompanion data) {
    return DeliveryIntentRow(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      outputId: data.outputId.present ? data.outputId.value : this.outputId,
      phoneLast4: data.phoneLast4.present
          ? data.phoneLast4.value
          : this.phoneLast4,
      phoneStored: data.phoneStored.present
          ? data.phoneStored.value
          : this.phoneStored,
      consentTextVersion: data.consentTextVersion.present
          ? data.consentTextVersion.value
          : this.consentTextVersion,
      consentTextDigest: data.consentTextDigest.present
          ? data.consentTextDigest.value
          : this.consentTextDigest,
      consentAcceptedAt: data.consentAcceptedAt.present
          ? data.consentAcceptedAt.value
          : this.consentAcceptedAt,
      locale: data.locale.present ? data.locale.value : this.locale,
      linkDays: data.linkDays.present ? data.linkDays.value : this.linkDays,
      sendLimit: data.sendLimit.present ? data.sendLimit.value : this.sendLimit,
      queueAllowed: data.queueAllowed.present
          ? data.queueAllowed.value
          : this.queueAllowed,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      state: data.state.present ? data.state.value : this.state,
      localOutcome: data.localOutcome.present
          ? data.localOutcome.value
          : this.localOutcome,
      remoteJobId: data.remoteJobId.present
          ? data.remoteJobId.value
          : this.remoteJobId,
      remoteStatus: data.remoteStatus.present
          ? data.remoteStatus.value
          : this.remoteStatus,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      retryAt: data.retryAt.present ? data.retryAt.value : this.retryAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      historyJson: data.historyJson.present
          ? data.historyJson.value
          : this.historyJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryIntentRow(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventId: $eventId, ')
          ..write('outputId: $outputId, ')
          ..write('phoneLast4: $phoneLast4, ')
          ..write('phoneStored: $phoneStored, ')
          ..write('consentTextVersion: $consentTextVersion, ')
          ..write('consentTextDigest: $consentTextDigest, ')
          ..write('consentAcceptedAt: $consentAcceptedAt, ')
          ..write('locale: $locale, ')
          ..write('linkDays: $linkDays, ')
          ..write('sendLimit: $sendLimit, ')
          ..write('queueAllowed: $queueAllowed, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('state: $state, ')
          ..write('localOutcome: $localOutcome, ')
          ..write('remoteJobId: $remoteJobId, ')
          ..write('remoteStatus: $remoteStatus, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('retryAt: $retryAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('historyJson: $historyJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sessionId,
    eventId,
    outputId,
    phoneLast4,
    phoneStored,
    consentTextVersion,
    consentTextDigest,
    consentAcceptedAt,
    locale,
    linkDays,
    sendLimit,
    queueAllowed,
    idempotencyKey,
    state,
    localOutcome,
    remoteJobId,
    remoteStatus,
    remoteUpdatedAt,
    lastErrorCode,
    attemptCount,
    retryAt,
    expiresAt,
    historyJson,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryIntentRow &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.eventId == this.eventId &&
          other.outputId == this.outputId &&
          other.phoneLast4 == this.phoneLast4 &&
          other.phoneStored == this.phoneStored &&
          other.consentTextVersion == this.consentTextVersion &&
          other.consentTextDigest == this.consentTextDigest &&
          other.consentAcceptedAt == this.consentAcceptedAt &&
          other.locale == this.locale &&
          other.linkDays == this.linkDays &&
          other.sendLimit == this.sendLimit &&
          other.queueAllowed == this.queueAllowed &&
          other.idempotencyKey == this.idempotencyKey &&
          other.state == this.state &&
          other.localOutcome == this.localOutcome &&
          other.remoteJobId == this.remoteJobId &&
          other.remoteStatus == this.remoteStatus &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.attemptCount == this.attemptCount &&
          other.retryAt == this.retryAt &&
          other.expiresAt == this.expiresAt &&
          other.historyJson == this.historyJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeliveryIntentsCompanion extends UpdateCompanion<DeliveryIntentRow> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> eventId;
  final Value<String> outputId;
  final Value<String> phoneLast4;
  final Value<bool> phoneStored;
  final Value<String> consentTextVersion;
  final Value<String> consentTextDigest;
  final Value<DateTime> consentAcceptedAt;
  final Value<String> locale;
  final Value<int> linkDays;
  final Value<int> sendLimit;
  final Value<bool> queueAllowed;
  final Value<String> idempotencyKey;
  final Value<DeliveryIntentState> state;
  final Value<DeliveryPhase?> localOutcome;
  final Value<String?> remoteJobId;
  final Value<String?> remoteStatus;
  final Value<DateTime?> remoteUpdatedAt;
  final Value<String?> lastErrorCode;
  final Value<int> attemptCount;
  final Value<DateTime?> retryAt;
  final Value<DateTime> expiresAt;
  final Value<String> historyJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeliveryIntentsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.outputId = const Value.absent(),
    this.phoneLast4 = const Value.absent(),
    this.phoneStored = const Value.absent(),
    this.consentTextVersion = const Value.absent(),
    this.consentTextDigest = const Value.absent(),
    this.consentAcceptedAt = const Value.absent(),
    this.locale = const Value.absent(),
    this.linkDays = const Value.absent(),
    this.sendLimit = const Value.absent(),
    this.queueAllowed = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.state = const Value.absent(),
    this.localOutcome = const Value.absent(),
    this.remoteJobId = const Value.absent(),
    this.remoteStatus = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.retryAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.historyJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryIntentsCompanion.insert({
    required String id,
    required String sessionId,
    required String eventId,
    required String outputId,
    required String phoneLast4,
    required bool phoneStored,
    required String consentTextVersion,
    required String consentTextDigest,
    required DateTime consentAcceptedAt,
    required String locale,
    required int linkDays,
    required int sendLimit,
    required bool queueAllowed,
    required String idempotencyKey,
    required DeliveryIntentState state,
    this.localOutcome = const Value.absent(),
    this.remoteJobId = const Value.absent(),
    this.remoteStatus = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.retryAt = const Value.absent(),
    required DateTime expiresAt,
    this.historyJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       eventId = Value(eventId),
       outputId = Value(outputId),
       phoneLast4 = Value(phoneLast4),
       phoneStored = Value(phoneStored),
       consentTextVersion = Value(consentTextVersion),
       consentTextDigest = Value(consentTextDigest),
       consentAcceptedAt = Value(consentAcceptedAt),
       locale = Value(locale),
       linkDays = Value(linkDays),
       sendLimit = Value(sendLimit),
       queueAllowed = Value(queueAllowed),
       idempotencyKey = Value(idempotencyKey),
       state = Value(state),
       expiresAt = Value(expiresAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeliveryIntentRow> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? eventId,
    Expression<String>? outputId,
    Expression<String>? phoneLast4,
    Expression<bool>? phoneStored,
    Expression<String>? consentTextVersion,
    Expression<String>? consentTextDigest,
    Expression<DateTime>? consentAcceptedAt,
    Expression<String>? locale,
    Expression<int>? linkDays,
    Expression<int>? sendLimit,
    Expression<bool>? queueAllowed,
    Expression<String>? idempotencyKey,
    Expression<String>? state,
    Expression<String>? localOutcome,
    Expression<String>? remoteJobId,
    Expression<String>? remoteStatus,
    Expression<DateTime>? remoteUpdatedAt,
    Expression<String>? lastErrorCode,
    Expression<int>? attemptCount,
    Expression<DateTime>? retryAt,
    Expression<DateTime>? expiresAt,
    Expression<String>? historyJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (eventId != null) 'event_id': eventId,
      if (outputId != null) 'output_id': outputId,
      if (phoneLast4 != null) 'phone_last4': phoneLast4,
      if (phoneStored != null) 'phone_stored': phoneStored,
      if (consentTextVersion != null)
        'consent_text_version': consentTextVersion,
      if (consentTextDigest != null) 'consent_text_digest': consentTextDigest,
      if (consentAcceptedAt != null) 'consent_accepted_at': consentAcceptedAt,
      if (locale != null) 'locale': locale,
      if (linkDays != null) 'link_days': linkDays,
      if (sendLimit != null) 'send_limit': sendLimit,
      if (queueAllowed != null) 'queue_allowed': queueAllowed,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (state != null) 'state': state,
      if (localOutcome != null) 'local_outcome': localOutcome,
      if (remoteJobId != null) 'remote_job_id': remoteJobId,
      if (remoteStatus != null) 'remote_status': remoteStatus,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (retryAt != null) 'retry_at': retryAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (historyJson != null) 'history_json': historyJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryIntentsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? eventId,
    Value<String>? outputId,
    Value<String>? phoneLast4,
    Value<bool>? phoneStored,
    Value<String>? consentTextVersion,
    Value<String>? consentTextDigest,
    Value<DateTime>? consentAcceptedAt,
    Value<String>? locale,
    Value<int>? linkDays,
    Value<int>? sendLimit,
    Value<bool>? queueAllowed,
    Value<String>? idempotencyKey,
    Value<DeliveryIntentState>? state,
    Value<DeliveryPhase?>? localOutcome,
    Value<String?>? remoteJobId,
    Value<String?>? remoteStatus,
    Value<DateTime?>? remoteUpdatedAt,
    Value<String?>? lastErrorCode,
    Value<int>? attemptCount,
    Value<DateTime?>? retryAt,
    Value<DateTime>? expiresAt,
    Value<String>? historyJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeliveryIntentsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      eventId: eventId ?? this.eventId,
      outputId: outputId ?? this.outputId,
      phoneLast4: phoneLast4 ?? this.phoneLast4,
      phoneStored: phoneStored ?? this.phoneStored,
      consentTextVersion: consentTextVersion ?? this.consentTextVersion,
      consentTextDigest: consentTextDigest ?? this.consentTextDigest,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      locale: locale ?? this.locale,
      linkDays: linkDays ?? this.linkDays,
      sendLimit: sendLimit ?? this.sendLimit,
      queueAllowed: queueAllowed ?? this.queueAllowed,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      state: state ?? this.state,
      localOutcome: localOutcome ?? this.localOutcome,
      remoteJobId: remoteJobId ?? this.remoteJobId,
      remoteStatus: remoteStatus ?? this.remoteStatus,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      attemptCount: attemptCount ?? this.attemptCount,
      retryAt: retryAt ?? this.retryAt,
      expiresAt: expiresAt ?? this.expiresAt,
      historyJson: historyJson ?? this.historyJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (outputId.present) {
      map['output_id'] = Variable<String>(outputId.value);
    }
    if (phoneLast4.present) {
      map['phone_last4'] = Variable<String>(phoneLast4.value);
    }
    if (phoneStored.present) {
      map['phone_stored'] = Variable<bool>(phoneStored.value);
    }
    if (consentTextVersion.present) {
      map['consent_text_version'] = Variable<String>(consentTextVersion.value);
    }
    if (consentTextDigest.present) {
      map['consent_text_digest'] = Variable<String>(consentTextDigest.value);
    }
    if (consentAcceptedAt.present) {
      map['consent_accepted_at'] = Variable<DateTime>(consentAcceptedAt.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (linkDays.present) {
      map['link_days'] = Variable<int>(linkDays.value);
    }
    if (sendLimit.present) {
      map['send_limit'] = Variable<int>(sendLimit.value);
    }
    if (queueAllowed.present) {
      map['queue_allowed'] = Variable<bool>(queueAllowed.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        DeliveryIntents.$converterstate.toSql(state.value),
      );
    }
    if (localOutcome.present) {
      map['local_outcome'] = Variable<String>(
        DeliveryIntents.$converterlocalOutcomen.toSql(localOutcome.value),
      );
    }
    if (remoteJobId.present) {
      map['remote_job_id'] = Variable<String>(remoteJobId.value);
    }
    if (remoteStatus.present) {
      map['remote_status'] = Variable<String>(remoteStatus.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<DateTime>(remoteUpdatedAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (retryAt.present) {
      map['retry_at'] = Variable<DateTime>(retryAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (historyJson.present) {
      map['history_json'] = Variable<String>(historyJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryIntentsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('eventId: $eventId, ')
          ..write('outputId: $outputId, ')
          ..write('phoneLast4: $phoneLast4, ')
          ..write('phoneStored: $phoneStored, ')
          ..write('consentTextVersion: $consentTextVersion, ')
          ..write('consentTextDigest: $consentTextDigest, ')
          ..write('consentAcceptedAt: $consentAcceptedAt, ')
          ..write('locale: $locale, ')
          ..write('linkDays: $linkDays, ')
          ..write('sendLimit: $sendLimit, ')
          ..write('queueAllowed: $queueAllowed, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('state: $state, ')
          ..write('localOutcome: $localOutcome, ')
          ..write('remoteJobId: $remoteJobId, ')
          ..write('remoteStatus: $remoteStatus, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('retryAt: $retryAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('historyJson: $historyJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DeliveryRemoteRevocations extends Table
    with TableInfo<DeliveryRemoteRevocations, DeliveryRemoteRevocationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DeliveryRemoteRevocations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteJobIdMeta = const VerificationMeta(
    'remoteJobId',
  );
  late final GeneratedColumn<String> remoteJobId = GeneratedColumn<String>(
    'remote_job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY CHECK (length(remote_job_id) = 36)',
  );
  static const VerificationMeta _requestedAtMeta = const VerificationMeta(
    'requestedAt',
  );
  late final GeneratedColumn<DateTime> requestedAt = GeneratedColumn<DateTime>(
    'requested_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [remoteJobId, requestedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'delivery_remote_revocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeliveryRemoteRevocationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_job_id')) {
      context.handle(
        _remoteJobIdMeta,
        remoteJobId.isAcceptableOrUnknown(
          data['remote_job_id']!,
          _remoteJobIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteJobIdMeta);
    }
    if (data.containsKey('requested_at')) {
      context.handle(
        _requestedAtMeta,
        requestedAt.isAcceptableOrUnknown(
          data['requested_at']!,
          _requestedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_requestedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteJobId};
  @override
  DeliveryRemoteRevocationRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeliveryRemoteRevocationRow(
      remoteJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_job_id'],
      )!,
      requestedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}requested_at'],
      )!,
    );
  }

  @override
  DeliveryRemoteRevocations createAlias(String alias) {
    return DeliveryRemoteRevocations(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DeliveryRemoteRevocationRow extends DataClass
    implements Insertable<DeliveryRemoteRevocationRow> {
  final String remoteJobId;
  final DateTime requestedAt;
  const DeliveryRemoteRevocationRow({
    required this.remoteJobId,
    required this.requestedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_job_id'] = Variable<String>(remoteJobId);
    map['requested_at'] = Variable<DateTime>(requestedAt);
    return map;
  }

  DeliveryRemoteRevocationsCompanion toCompanion(bool nullToAbsent) {
    return DeliveryRemoteRevocationsCompanion(
      remoteJobId: Value(remoteJobId),
      requestedAt: Value(requestedAt),
    );
  }

  factory DeliveryRemoteRevocationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeliveryRemoteRevocationRow(
      remoteJobId: serializer.fromJson<String>(json['remote_job_id']),
      requestedAt: serializer.fromJson<DateTime>(json['requested_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remote_job_id': serializer.toJson<String>(remoteJobId),
      'requested_at': serializer.toJson<DateTime>(requestedAt),
    };
  }

  DeliveryRemoteRevocationRow copyWith({
    String? remoteJobId,
    DateTime? requestedAt,
  }) => DeliveryRemoteRevocationRow(
    remoteJobId: remoteJobId ?? this.remoteJobId,
    requestedAt: requestedAt ?? this.requestedAt,
  );
  DeliveryRemoteRevocationRow copyWithCompanion(
    DeliveryRemoteRevocationsCompanion data,
  ) {
    return DeliveryRemoteRevocationRow(
      remoteJobId: data.remoteJobId.present
          ? data.remoteJobId.value
          : this.remoteJobId,
      requestedAt: data.requestedAt.present
          ? data.requestedAt.value
          : this.requestedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryRemoteRevocationRow(')
          ..write('remoteJobId: $remoteJobId, ')
          ..write('requestedAt: $requestedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(remoteJobId, requestedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveryRemoteRevocationRow &&
          other.remoteJobId == this.remoteJobId &&
          other.requestedAt == this.requestedAt);
}

class DeliveryRemoteRevocationsCompanion
    extends UpdateCompanion<DeliveryRemoteRevocationRow> {
  final Value<String> remoteJobId;
  final Value<DateTime> requestedAt;
  final Value<int> rowid;
  const DeliveryRemoteRevocationsCompanion({
    this.remoteJobId = const Value.absent(),
    this.requestedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeliveryRemoteRevocationsCompanion.insert({
    required String remoteJobId,
    required DateTime requestedAt,
    this.rowid = const Value.absent(),
  }) : remoteJobId = Value(remoteJobId),
       requestedAt = Value(requestedAt);
  static Insertable<DeliveryRemoteRevocationRow> custom({
    Expression<String>? remoteJobId,
    Expression<DateTime>? requestedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (remoteJobId != null) 'remote_job_id': remoteJobId,
      if (requestedAt != null) 'requested_at': requestedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeliveryRemoteRevocationsCompanion copyWith({
    Value<String>? remoteJobId,
    Value<DateTime>? requestedAt,
    Value<int>? rowid,
  }) {
    return DeliveryRemoteRevocationsCompanion(
      remoteJobId: remoteJobId ?? this.remoteJobId,
      requestedAt: requestedAt ?? this.requestedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteJobId.present) {
      map['remote_job_id'] = Variable<String>(remoteJobId.value);
    }
    if (requestedAt.present) {
      map['requested_at'] = Variable<DateTime>(requestedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeliveryRemoteRevocationsCompanion(')
          ..write('remoteJobId: $remoteJobId, ')
          ..write('requestedAt: $requestedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BoothDatabase extends GeneratedDatabase {
  _$BoothDatabase(QueryExecutor e) : super(e);
  $BoothDatabaseManager get managers => $BoothDatabaseManager(this);
  late final BoothProfiles boothProfiles = BoothProfiles(this);
  late final Events events = Events(this);
  late final AppSettings appSettings = AppSettings(this);
  late final OperatorAccess operatorAccess = OperatorAccess(this);
  late final Templates templates = Templates(this);
  late final TemplateRevisions templateRevisions = TemplateRevisions(this);
  late final Trigger templateRevisionsAreImmutable = Trigger(
    'CREATE TRIGGER template_revisions_are_immutable BEFORE UPDATE ON template_revisions BEGIN SELECT RAISE (ABORT, \'template revisions are immutable\');END',
    'template_revisions_are_immutable',
  );
  late final Assets assets = Assets(this);
  late final Trigger assetContentIsImmutable = Trigger(
    'CREATE TRIGGER asset_content_is_immutable BEFORE UPDATE OF id, media_type, relative_path, byte_length, width_px, height_px, origin, created_at ON assets BEGIN SELECT RAISE (ABORT, \'assets are immutable\');END',
    'asset_content_is_immutable',
  );
  late final TemplateRevisionAssets templateRevisionAssets =
      TemplateRevisionAssets(this);
  late final Index templateRevisionAssetsByAsset = Index(
    'template_revision_assets_by_asset',
    'CREATE INDEX template_revision_assets_by_asset ON template_revision_assets (asset_id)',
  );
  late final TemplateDrafts templateDrafts = TemplateDrafts(this);
  late final Index eventsByStatus = Index(
    'events_by_status',
    'CREATE INDEX events_by_status ON events (status, updated_at)',
  );
  late final EventTemplates eventTemplates = EventTemplates(this);
  late final Index eventTemplatesOneDefault = Index(
    'event_templates_one_default',
    'CREATE UNIQUE INDEX event_templates_one_default ON event_templates (event_id) WHERE is_default = 1',
  );
  late final Index eventTemplatesByRevision = Index(
    'event_templates_by_revision',
    'CREATE INDEX event_templates_by_revision ON event_templates (template_revision_id)',
  );
  late final OriginalPhotos originalPhotos = OriginalPhotos(this);
  late final Index originalPhotosByTime = Index(
    'original_photos_by_time',
    'CREATE INDEX original_photos_by_time ON original_photos (captured_at)',
  );
  late final Trigger originalPhotosAreImmutable = Trigger(
    'CREATE TRIGGER original_photos_are_immutable BEFORE UPDATE ON original_photos BEGIN SELECT RAISE (ABORT, \'originals are immutable\');END',
    'original_photos_are_immutable',
  );
  late final PendingOriginalCommits pendingOriginalCommits =
      PendingOriginalCommits(this);
  late final CaptureSessions captureSessions = CaptureSessions(this);
  late final Index captureSessionsByEvent = Index(
    'capture_sessions_by_event',
    'CREATE INDEX capture_sessions_by_event ON capture_sessions (event_id, started_at)',
  );
  late final Trigger captureSessionPlansAreImmutable = Trigger(
    'CREATE TRIGGER capture_session_plans_are_immutable BEFORE UPDATE OF id, event_id, sequence, template_revision_id, planned_shots, plan_json, started_at ON capture_sessions BEGIN SELECT RAISE (ABORT, \'a session is frozen to its plan\');END',
    'capture_session_plans_are_immutable',
  );
  late final Trigger finishedSessionsAreImmutable = Trigger(
    'CREATE TRIGGER finished_sessions_are_immutable BEFORE UPDATE ON capture_sessions WHEN OLD.status IN (\'completed\', \'abandoned\', \'failed\') BEGIN SELECT RAISE (ABORT, \'a finished session never changes\');END',
    'finished_sessions_are_immutable',
  );
  late final SessionPhotos sessionPhotos = SessionPhotos(this);
  late final Trigger sessionPhotosAreImmutable = Trigger(
    'CREATE TRIGGER session_photos_are_immutable BEFORE UPDATE ON session_photos BEGIN SELECT RAISE (ABORT, \'session photos are immutable\');END',
    'session_photos_are_immutable',
  );
  late final SessionOutputs sessionOutputs = SessionOutputs(this);
  late final Index sessionOutputsBySession = Index(
    'session_outputs_by_session',
    'CREATE INDEX session_outputs_by_session ON session_outputs (session_id, created_at)',
  );
  late final Trigger sessionOutputsAreImmutable = Trigger(
    'CREATE TRIGGER session_outputs_are_immutable BEFORE UPDATE ON session_outputs BEGIN SELECT RAISE (ABORT, \'finished photos are immutable\');END',
    'session_outputs_are_immutable',
  );
  late final ExportBatches exportBatches = ExportBatches(this);
  late final ExportBatchItems exportBatchItems = ExportBatchItems(this);
  late final Index exportBatchItemsBySession = Index(
    'export_batch_items_by_session',
    'CREATE INDEX export_batch_items_by_session ON export_batch_items (session_id)',
  );
  late final PendingFileDeletions pendingFileDeletions = PendingFileDeletions(
    this,
  );
  late final EventDeliveryOptions eventDeliveryOptions = EventDeliveryOptions(
    this,
  );
  late final DeliveryPairings deliveryPairings = DeliveryPairings(this);
  late final DeliveryIntents deliveryIntents = DeliveryIntents(this);
  late final Index deliveryIntentsBySession = Index(
    'delivery_intents_by_session',
    'CREATE INDEX delivery_intents_by_session ON delivery_intents (session_id)',
  );
  late final Index deliveryIntentsByState = Index(
    'delivery_intents_by_state',
    'CREATE INDEX delivery_intents_by_state ON delivery_intents (state, retry_at)',
  );
  late final Index deliveryIntentsByEvent = Index(
    'delivery_intents_by_event',
    'CREATE INDEX delivery_intents_by_event ON delivery_intents (event_id, created_at)',
  );
  late final DeliveryRemoteRevocations deliveryRemoteRevocations =
      DeliveryRemoteRevocations(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    boothProfiles,
    events,
    appSettings,
    operatorAccess,
    templates,
    templateRevisions,
    templateRevisionsAreImmutable,
    assets,
    assetContentIsImmutable,
    templateRevisionAssets,
    templateRevisionAssetsByAsset,
    templateDrafts,
    eventsByStatus,
    eventTemplates,
    eventTemplatesOneDefault,
    eventTemplatesByRevision,
    originalPhotos,
    originalPhotosByTime,
    originalPhotosAreImmutable,
    pendingOriginalCommits,
    captureSessions,
    captureSessionsByEvent,
    captureSessionPlansAreImmutable,
    finishedSessionsAreImmutable,
    sessionPhotos,
    sessionPhotosAreImmutable,
    sessionOutputs,
    sessionOutputsBySession,
    sessionOutputsAreImmutable,
    exportBatches,
    exportBatchItems,
    exportBatchItemsBySession,
    pendingFileDeletions,
    eventDeliveryOptions,
    deliveryPairings,
    deliveryIntents,
    deliveryIntentsBySession,
    deliveryIntentsByState,
    deliveryIntentsByEvent,
    deliveryRemoteRevocations,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_settings', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'template_revisions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'assets',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'template_revisions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('template_revision_assets', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('template_drafts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'template_revisions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('template_drafts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_templates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'original_photos',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'capture_sessions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'capture_sessions',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_photos',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_outputs',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'export_batches',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('export_batch_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'capture_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('export_batch_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_delivery_options', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'capture_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('delivery_intents', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $BoothProfilesCreateCompanionBuilder = BoothProfilesCompanion Function({
  required String id,
  required String name,
  required PorcelainThemeProfile themeProfile,
  required ContrastPreference contrastPreference,
  required MotionPreference motionPreference,
  required CameraLens defaultLens,
  required bool defaultMirrorPreview,
  required bool defaultMirrorOutput,
  required GuestOrientationPreference defaultOrientation,
  required OutputFormat defaultOutputFormat,
  required int defaultJpegQuality,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $BoothProfilesUpdateCompanionBuilder = BoothProfilesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<PorcelainThemeProfile> themeProfile,
  Value<ContrastPreference> contrastPreference,
  Value<MotionPreference> motionPreference,
  Value<CameraLens> defaultLens,
  Value<bool> defaultMirrorPreview,
  Value<bool> defaultMirrorOutput,
  Value<GuestOrientationPreference> defaultOrientation,
  Value<OutputFormat> defaultOutputFormat,
  Value<int> defaultJpegQuality,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $BoothProfilesReferences
    extends BaseReferences<_$BoothDatabase, BoothProfiles, BoothProfileRow> {
  $BoothProfilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Events, List<EventRow>> _eventsRefsTable(
    _$BoothDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'booth_profiles__id__events__booth_profile_id',
  );

  $EventsProcessedTableManager get eventsRefs {
    final manager = $EventsTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.boothProfileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AppSettings, List<AppSettingsRow>>
  _appSettingsRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: 'booth_profiles__id__app_settings__booth_profile_id',
  );

  $AppSettingsProcessedTableManager get appSettingsRefs {
    final manager = $AppSettingsTableManager(
      $_db,
      $_db.appSettings,
    ).filter((f) => f.boothProfileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $BoothProfilesFilterComposer
    extends Composer<_$BoothDatabase, BoothProfiles> {
  $BoothProfilesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PorcelainThemeProfile,
    PorcelainThemeProfile,
    String
  >
  get themeProfile => $composableBuilder(
    column: $table.themeProfile,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<ContrastPreference, ContrastPreference, String>
  get contrastPreference => $composableBuilder(
    column: $table.contrastPreference,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<MotionPreference, MotionPreference, String>
  get motionPreference => $composableBuilder(
    column: $table.motionPreference,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<CameraLens, CameraLens, String>
  get defaultLens => $composableBuilder(
    column: $table.defaultLens,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get defaultMirrorPreview => $composableBuilder(
    column: $table.defaultMirrorPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get defaultMirrorOutput => $composableBuilder(
    column: $table.defaultMirrorOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    GuestOrientationPreference,
    GuestOrientationPreference,
    String
  >
  get defaultOrientation => $composableBuilder(
    column: $table.defaultOrientation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<OutputFormat, OutputFormat, String>
  get defaultOutputFormat => $composableBuilder(
    column: $table.defaultOutputFormat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get defaultJpegQuality => $composableBuilder(
    column: $table.defaultJpegQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventsRefs(
    Expression<bool> Function($EventsFilterComposer f) f,
  ) {
    final $EventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.boothProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($AppSettingsFilterComposer f) f,
  ) {
    final $AppSettingsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.boothProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BoothProfilesOrderingComposer
    extends Composer<_$BoothDatabase, BoothProfiles> {
  $BoothProfilesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeProfile => $composableBuilder(
    column: $table.themeProfile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contrastPreference => $composableBuilder(
    column: $table.contrastPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motionPreference => $composableBuilder(
    column: $table.motionPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultLens => $composableBuilder(
    column: $table.defaultLens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get defaultMirrorPreview => $composableBuilder(
    column: $table.defaultMirrorPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get defaultMirrorOutput => $composableBuilder(
    column: $table.defaultMirrorOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultOrientation => $composableBuilder(
    column: $table.defaultOrientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultOutputFormat => $composableBuilder(
    column: $table.defaultOutputFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultJpegQuality => $composableBuilder(
    column: $table.defaultJpegQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $BoothProfilesAnnotationComposer
    extends Composer<_$BoothDatabase, BoothProfiles> {
  $BoothProfilesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PorcelainThemeProfile, String>
  get themeProfile => $composableBuilder(
    column: $table.themeProfile,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ContrastPreference, String>
  get contrastPreference => $composableBuilder(
    column: $table.contrastPreference,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MotionPreference, String>
  get motionPreference => $composableBuilder(
    column: $table.motionPreference,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CameraLens, String> get defaultLens =>
      $composableBuilder(
        column: $table.defaultLens,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get defaultMirrorPreview => $composableBuilder(
    column: $table.defaultMirrorPreview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get defaultMirrorOutput => $composableBuilder(
    column: $table.defaultMirrorOutput,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GuestOrientationPreference, String>
  get defaultOrientation => $composableBuilder(
    column: $table.defaultOrientation,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OutputFormat, String>
  get defaultOutputFormat => $composableBuilder(
    column: $table.defaultOutputFormat,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultJpegQuality => $composableBuilder(
    column: $table.defaultJpegQuality,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($EventsAnnotationComposer a) f,
  ) {
    final $EventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.boothProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($AppSettingsAnnotationComposer a) f,
  ) {
    final $AppSettingsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.boothProfileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $BoothProfilesTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          BoothProfiles,
          BoothProfileRow,
          $BoothProfilesFilterComposer,
          $BoothProfilesOrderingComposer,
          $BoothProfilesAnnotationComposer,
          $BoothProfilesCreateCompanionBuilder,
          $BoothProfilesUpdateCompanionBuilder,
          (BoothProfileRow, $BoothProfilesReferences),
          BoothProfileRow,
          PrefetchHooks Function({bool eventsRefs, bool appSettingsRefs})
        > {
  $BoothProfilesTableManager(_$BoothDatabase db, BoothProfiles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $BoothProfilesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $BoothProfilesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $BoothProfilesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<PorcelainThemeProfile> themeProfile =
                    const Value.absent(),
                Value<ContrastPreference> contrastPreference =
                    const Value.absent(),
                Value<MotionPreference> motionPreference = const Value.absent(),
                Value<CameraLens> defaultLens = const Value.absent(),
                Value<bool> defaultMirrorPreview = const Value.absent(),
                Value<bool> defaultMirrorOutput = const Value.absent(),
                Value<GuestOrientationPreference> defaultOrientation =
                    const Value.absent(),
                Value<OutputFormat> defaultOutputFormat = const Value.absent(),
                Value<int> defaultJpegQuality = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoothProfilesCompanion(
                id: id,
                name: name,
                themeProfile: themeProfile,
                contrastPreference: contrastPreference,
                motionPreference: motionPreference,
                defaultLens: defaultLens,
                defaultMirrorPreview: defaultMirrorPreview,
                defaultMirrorOutput: defaultMirrorOutput,
                defaultOrientation: defaultOrientation,
                defaultOutputFormat: defaultOutputFormat,
                defaultJpegQuality: defaultJpegQuality,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required PorcelainThemeProfile themeProfile,
                required ContrastPreference contrastPreference,
                required MotionPreference motionPreference,
                required CameraLens defaultLens,
                required bool defaultMirrorPreview,
                required bool defaultMirrorOutput,
                required GuestOrientationPreference defaultOrientation,
                required OutputFormat defaultOutputFormat,
                required int defaultJpegQuality,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => BoothProfilesCompanion.insert(
                id: id,
                name: name,
                themeProfile: themeProfile,
                contrastPreference: contrastPreference,
                motionPreference: motionPreference,
                defaultLens: defaultLens,
                defaultMirrorPreview: defaultMirrorPreview,
                defaultMirrorOutput: defaultMirrorOutput,
                defaultOrientation: defaultOrientation,
                defaultOutputFormat: defaultOutputFormat,
                defaultJpegQuality: defaultJpegQuality,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<BoothProfiles, BoothProfileRow>(table),
                  $BoothProfilesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventsRefs = false, appSettingsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventsRefs) db.events,
                    if (appSettingsRefs) db.appSettings,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventsRefs)
                        await $_getPrefetchedData<
                          BoothProfileRow,
                          BoothProfiles,
                          EventRow
                        >(
                          currentTable: table,
                          referencedTable: $BoothProfilesReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $BoothProfilesReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boothProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (appSettingsRefs)
                        await $_getPrefetchedData<
                          BoothProfileRow,
                          BoothProfiles,
                          AppSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $BoothProfilesReferences
                              ._appSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $BoothProfilesReferences(
                                db,
                                table,
                                p0,
                              ).appSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boothProfileId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $BoothProfilesProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      BoothProfiles,
      BoothProfileRow,
      $BoothProfilesFilterComposer,
      $BoothProfilesOrderingComposer,
      $BoothProfilesAnnotationComposer,
      $BoothProfilesCreateCompanionBuilder,
      $BoothProfilesUpdateCompanionBuilder,
      (BoothProfileRow, $BoothProfilesReferences),
      BoothProfileRow,
      PrefetchHooks Function({bool eventsRefs, bool appSettingsRefs})
    >;
typedef $EventsCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  required String boothProfileId,
  required String title,
  Value<CalendarDate?> eventDate,
  Value<String?> venue,
  Value<String?> notes,
  required EventStatus status,
  required CameraLens lens,
  required bool mirrorPreview,
  required bool mirrorOutput,
  required GuestOrientationPreference guestOrientation,
  required int shotCount,
  required int countdownSeconds,
  required int shotIntervalSeconds,
  required RetakePolicy retakePolicy,
  required int retakeLimit,
  Value<String?> welcomeTitle,
  Value<String?> welcomeMessage,
  Value<String?> consentText,
  required bool guestChoosesTemplate,
  required int finishTimeoutSeconds,
  Value<PorcelainThemeProfile?> themeOverride,
  required OutputFormat outputFormat,
  required int jpegQuality,
  required RetentionMode retentionMode,
  Value<int?> retentionDays,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $EventsUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<String> boothProfileId,
  Value<String> title,
  Value<CalendarDate?> eventDate,
  Value<String?> venue,
  Value<String?> notes,
  Value<EventStatus> status,
  Value<CameraLens> lens,
  Value<bool> mirrorPreview,
  Value<bool> mirrorOutput,
  Value<GuestOrientationPreference> guestOrientation,
  Value<int> shotCount,
  Value<int> countdownSeconds,
  Value<int> shotIntervalSeconds,
  Value<RetakePolicy> retakePolicy,
  Value<int> retakeLimit,
  Value<String?> welcomeTitle,
  Value<String?> welcomeMessage,
  Value<String?> consentText,
  Value<bool> guestChoosesTemplate,
  Value<int> finishTimeoutSeconds,
  Value<PorcelainThemeProfile?> themeOverride,
  Value<OutputFormat> outputFormat,
  Value<int> jpegQuality,
  Value<RetentionMode> retentionMode,
  Value<int?> retentionDays,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $EventsReferences
    extends BaseReferences<_$BoothDatabase, Events, EventRow> {
  $EventsReferences(super.$_db, super.$_table, super.$_typedResult);

  static BoothProfiles _boothProfileIdTable(_$BoothDatabase db) => db
      .boothProfiles
      .createAlias('events__booth_profile_id__booth_profiles__id');

  $BoothProfilesProcessedTableManager get boothProfileId {
    final $_column = $_itemColumn<String>('booth_profile_id')!;

    final manager = $BoothProfilesTableManager(
      $_db,
      $_db.boothProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boothProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<AppSettings, List<AppSettingsRow>>
  _appSettingsRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.appSettings,
    aliasName: 'events__id__app_settings__booth_event_id',
  );

  $AppSettingsProcessedTableManager get appSettingsRefs {
    final manager = $AppSettingsTableManager(
      $_db,
      $_db.appSettings,
    ).filter((f) => f.boothEventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appSettingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<EventTemplates, List<EventTemplateRow>>
  _eventTemplatesRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTemplates,
    aliasName: 'events__id__event_templates__event_id',
  );

  $EventTemplatesProcessedTableManager get eventTemplatesRefs {
    final manager = $EventTemplatesTableManager(
      $_db,
      $_db.eventTemplates,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaptureSessions, List<CaptureSessionRow>>
  _captureSessionsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.captureSessions,
        aliasName: 'events__id__capture_sessions__event_id',
      );

  $CaptureSessionsProcessedTableManager get captureSessionsRefs {
    final manager = $CaptureSessionsTableManager(
      $_db,
      $_db.captureSessions,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _captureSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    EventDeliveryOptions,
    List<EventDeliverySettingsRow>
  >
  _eventDeliveryOptionsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.eventDeliveryOptions,
        aliasName: 'events__id__event_delivery_options__event_id',
      );

  $EventDeliveryOptionsProcessedTableManager get eventDeliveryOptionsRefs {
    final manager = $EventDeliveryOptionsTableManager(
      $_db,
      $_db.eventDeliveryOptions,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _eventDeliveryOptionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $EventsFilterComposer extends Composer<_$BoothDatabase, Events> {
  $EventsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CalendarDate?, CalendarDate, String>
  get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventStatus, EventStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<CameraLens, CameraLens, String> get lens =>
      $composableBuilder(
        column: $table.lens,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    GuestOrientationPreference,
    GuestOrientationPreference,
    String
  >
  get guestOrientation => $composableBuilder(
    column: $table.guestOrientation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get shotCount => $composableBuilder(
    column: $table.shotCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get countdownSeconds => $composableBuilder(
    column: $table.countdownSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shotIntervalSeconds => $composableBuilder(
    column: $table.shotIntervalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetakePolicy, RetakePolicy, String>
  get retakePolicy => $composableBuilder(
    column: $table.retakePolicy,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retakeLimit => $composableBuilder(
    column: $table.retakeLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentText => $composableBuilder(
    column: $table.consentText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get guestChoosesTemplate => $composableBuilder(
    column: $table.guestChoosesTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishTimeoutSeconds => $composableBuilder(
    column: $table.finishTimeoutSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PorcelainThemeProfile?,
    PorcelainThemeProfile,
    String
  >
  get themeOverride => $composableBuilder(
    column: $table.themeOverride,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<OutputFormat, OutputFormat, String>
  get outputFormat => $composableBuilder(
    column: $table.outputFormat,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get jpegQuality => $composableBuilder(
    column: $table.jpegQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RetentionMode, RetentionMode, String>
  get retentionMode => $composableBuilder(
    column: $table.retentionMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  $BoothProfilesFilterComposer get boothProfileId {
    final $BoothProfilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesFilterComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> appSettingsRefs(
    Expression<bool> Function($AppSettingsFilterComposer f) f,
  ) {
    final $AppSettingsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.boothEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsFilterComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventTemplatesRefs(
    Expression<bool> Function($EventTemplatesFilterComposer f) f,
  ) {
    final $EventTemplatesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTemplates,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventTemplatesFilterComposer(
            $db: $db,
            $table: $db.eventTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> captureSessionsRefs(
    Expression<bool> Function($CaptureSessionsFilterComposer f) f,
  ) {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventDeliveryOptionsRefs(
    Expression<bool> Function($EventDeliveryOptionsFilterComposer f) f,
  ) {
    final $EventDeliveryOptionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventDeliveryOptions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventDeliveryOptionsFilterComposer(
            $db: $db,
            $table: $db.eventDeliveryOptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $EventsOrderingComposer extends Composer<_$BoothDatabase, Events> {
  $EventsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venue => $composableBuilder(
    column: $table.venue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lens => $composableBuilder(
    column: $table.lens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guestOrientation => $composableBuilder(
    column: $table.guestOrientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotCount => $composableBuilder(
    column: $table.shotCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get countdownSeconds => $composableBuilder(
    column: $table.countdownSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shotIntervalSeconds => $composableBuilder(
    column: $table.shotIntervalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retakePolicy => $composableBuilder(
    column: $table.retakePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retakeLimit => $composableBuilder(
    column: $table.retakeLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentText => $composableBuilder(
    column: $table.consentText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get guestChoosesTemplate => $composableBuilder(
    column: $table.guestChoosesTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishTimeoutSeconds => $composableBuilder(
    column: $table.finishTimeoutSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeOverride => $composableBuilder(
    column: $table.themeOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputFormat => $composableBuilder(
    column: $table.outputFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jpegQuality => $composableBuilder(
    column: $table.jpegQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get retentionMode => $composableBuilder(
    column: $table.retentionMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $BoothProfilesOrderingComposer get boothProfileId {
    final $BoothProfilesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesOrderingComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventsAnnotationComposer extends Composer<_$BoothDatabase, Events> {
  $EventsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CalendarDate?, String> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get venue =>
      $composableBuilder(column: $table.venue, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CameraLens, String> get lens =>
      $composableBuilder(column: $table.lens, builder: (column) => column);

  GeneratedColumn<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<GuestOrientationPreference, String>
  get guestOrientation => $composableBuilder(
    column: $table.guestOrientation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotCount =>
      $composableBuilder(column: $table.shotCount, builder: (column) => column);

  GeneratedColumn<int> get countdownSeconds => $composableBuilder(
    column: $table.countdownSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shotIntervalSeconds => $composableBuilder(
    column: $table.shotIntervalSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RetakePolicy, String> get retakePolicy =>
      $composableBuilder(
        column: $table.retakePolicy,
        builder: (column) => column,
      );

  GeneratedColumn<int> get retakeLimit => $composableBuilder(
    column: $table.retakeLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get welcomeTitle => $composableBuilder(
    column: $table.welcomeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get welcomeMessage => $composableBuilder(
    column: $table.welcomeMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentText => $composableBuilder(
    column: $table.consentText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get guestChoosesTemplate => $composableBuilder(
    column: $table.guestChoosesTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finishTimeoutSeconds => $composableBuilder(
    column: $table.finishTimeoutSeconds,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PorcelainThemeProfile?, String>
  get themeOverride => $composableBuilder(
    column: $table.themeOverride,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<OutputFormat, String> get outputFormat =>
      $composableBuilder(
        column: $table.outputFormat,
        builder: (column) => column,
      );

  GeneratedColumn<int> get jpegQuality => $composableBuilder(
    column: $table.jpegQuality,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RetentionMode, String> get retentionMode =>
      $composableBuilder(
        column: $table.retentionMode,
        builder: (column) => column,
      );

  GeneratedColumn<int> get retentionDays => $composableBuilder(
    column: $table.retentionDays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  $BoothProfilesAnnotationComposer get boothProfileId {
    final $BoothProfilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesAnnotationComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> appSettingsRefs<T extends Object>(
    Expression<T> Function($AppSettingsAnnotationComposer a) f,
  ) {
    final $AppSettingsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appSettings,
      getReferencedColumn: (t) => t.boothEventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AppSettingsAnnotationComposer(
            $db: $db,
            $table: $db.appSettings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventTemplatesRefs<T extends Object>(
    Expression<T> Function($EventTemplatesAnnotationComposer a) f,
  ) {
    final $EventTemplatesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTemplates,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventTemplatesAnnotationComposer(
            $db: $db,
            $table: $db.eventTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> captureSessionsRefs<T extends Object>(
    Expression<T> Function($CaptureSessionsAnnotationComposer a) f,
  ) {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventDeliveryOptionsRefs<T extends Object>(
    Expression<T> Function($EventDeliveryOptionsAnnotationComposer a) f,
  ) {
    final $EventDeliveryOptionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventDeliveryOptions,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventDeliveryOptionsAnnotationComposer(
            $db: $db,
            $table: $db.eventDeliveryOptions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $EventsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          Events,
          EventRow,
          $EventsFilterComposer,
          $EventsOrderingComposer,
          $EventsAnnotationComposer,
          $EventsCreateCompanionBuilder,
          $EventsUpdateCompanionBuilder,
          (EventRow, $EventsReferences),
          EventRow,
          PrefetchHooks Function({
            bool boothProfileId,
            bool appSettingsRefs,
            bool eventTemplatesRefs,
            bool captureSessionsRefs,
            bool eventDeliveryOptionsRefs,
          })
        > {
  $EventsTableManager(_$BoothDatabase db, Events table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EventsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EventsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EventsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> boothProfileId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<CalendarDate?> eventDate = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<EventStatus> status = const Value.absent(),
                Value<CameraLens> lens = const Value.absent(),
                Value<bool> mirrorPreview = const Value.absent(),
                Value<bool> mirrorOutput = const Value.absent(),
                Value<GuestOrientationPreference> guestOrientation =
                    const Value.absent(),
                Value<int> shotCount = const Value.absent(),
                Value<int> countdownSeconds = const Value.absent(),
                Value<int> shotIntervalSeconds = const Value.absent(),
                Value<RetakePolicy> retakePolicy = const Value.absent(),
                Value<int> retakeLimit = const Value.absent(),
                Value<String?> welcomeTitle = const Value.absent(),
                Value<String?> welcomeMessage = const Value.absent(),
                Value<String?> consentText = const Value.absent(),
                Value<bool> guestChoosesTemplate = const Value.absent(),
                Value<int> finishTimeoutSeconds = const Value.absent(),
                Value<PorcelainThemeProfile?> themeOverride =
                    const Value.absent(),
                Value<OutputFormat> outputFormat = const Value.absent(),
                Value<int> jpegQuality = const Value.absent(),
                Value<RetentionMode> retentionMode = const Value.absent(),
                Value<int?> retentionDays = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                boothProfileId: boothProfileId,
                title: title,
                eventDate: eventDate,
                venue: venue,
                notes: notes,
                status: status,
                lens: lens,
                mirrorPreview: mirrorPreview,
                mirrorOutput: mirrorOutput,
                guestOrientation: guestOrientation,
                shotCount: shotCount,
                countdownSeconds: countdownSeconds,
                shotIntervalSeconds: shotIntervalSeconds,
                retakePolicy: retakePolicy,
                retakeLimit: retakeLimit,
                welcomeTitle: welcomeTitle,
                welcomeMessage: welcomeMessage,
                consentText: consentText,
                guestChoosesTemplate: guestChoosesTemplate,
                finishTimeoutSeconds: finishTimeoutSeconds,
                themeOverride: themeOverride,
                outputFormat: outputFormat,
                jpegQuality: jpegQuality,
                retentionMode: retentionMode,
                retentionDays: retentionDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String boothProfileId,
                required String title,
                Value<CalendarDate?> eventDate = const Value.absent(),
                Value<String?> venue = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required EventStatus status,
                required CameraLens lens,
                required bool mirrorPreview,
                required bool mirrorOutput,
                required GuestOrientationPreference guestOrientation,
                required int shotCount,
                required int countdownSeconds,
                required int shotIntervalSeconds,
                required RetakePolicy retakePolicy,
                required int retakeLimit,
                Value<String?> welcomeTitle = const Value.absent(),
                Value<String?> welcomeMessage = const Value.absent(),
                Value<String?> consentText = const Value.absent(),
                required bool guestChoosesTemplate,
                required int finishTimeoutSeconds,
                Value<PorcelainThemeProfile?> themeOverride =
                    const Value.absent(),
                required OutputFormat outputFormat,
                required int jpegQuality,
                required RetentionMode retentionMode,
                Value<int?> retentionDays = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                boothProfileId: boothProfileId,
                title: title,
                eventDate: eventDate,
                venue: venue,
                notes: notes,
                status: status,
                lens: lens,
                mirrorPreview: mirrorPreview,
                mirrorOutput: mirrorOutput,
                guestOrientation: guestOrientation,
                shotCount: shotCount,
                countdownSeconds: countdownSeconds,
                shotIntervalSeconds: shotIntervalSeconds,
                retakePolicy: retakePolicy,
                retakeLimit: retakeLimit,
                welcomeTitle: welcomeTitle,
                welcomeMessage: welcomeMessage,
                consentText: consentText,
                guestChoosesTemplate: guestChoosesTemplate,
                finishTimeoutSeconds: finishTimeoutSeconds,
                themeOverride: themeOverride,
                outputFormat: outputFormat,
                jpegQuality: jpegQuality,
                retentionMode: retentionMode,
                retentionDays: retentionDays,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Events, EventRow>(table),
                  $EventsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                boothProfileId = false,
                appSettingsRefs = false,
                eventTemplatesRefs = false,
                captureSessionsRefs = false,
                eventDeliveryOptionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appSettingsRefs) db.appSettings,
                    if (eventTemplatesRefs) db.eventTemplates,
                    if (captureSessionsRefs) db.captureSessions,
                    if (eventDeliveryOptionsRefs) db.eventDeliveryOptions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (boothProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.boothProfileId,
                            referencedTable: $EventsReferences
                                ._boothProfileIdTable(db),
                            referencedColumn: $EventsReferences
                                ._boothProfileIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (appSettingsRefs)
                        await $_getPrefetchedData<
                          EventRow,
                          Events,
                          AppSettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $EventsReferences
                              ._appSettingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $EventsReferences(db, table, p0).appSettingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.boothEventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventTemplatesRefs)
                        await $_getPrefetchedData<
                          EventRow,
                          Events,
                          EventTemplateRow
                        >(
                          currentTable: table,
                          referencedTable: $EventsReferences
                              ._eventTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) => $EventsReferences(
                            db,
                            table,
                            p0,
                          ).eventTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (captureSessionsRefs)
                        await $_getPrefetchedData<
                          EventRow,
                          Events,
                          CaptureSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $EventsReferences
                              ._captureSessionsRefsTable(db),
                          managerFromTypedResult: (p0) => $EventsReferences(
                            db,
                            table,
                            p0,
                          ).captureSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventDeliveryOptionsRefs)
                        await $_getPrefetchedData<
                          EventRow,
                          Events,
                          EventDeliverySettingsRow
                        >(
                          currentTable: table,
                          referencedTable: $EventsReferences
                              ._eventDeliveryOptionsRefsTable(db),
                          managerFromTypedResult: (p0) => $EventsReferences(
                            db,
                            table,
                            p0,
                          ).eventDeliveryOptionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $EventsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      Events,
      EventRow,
      $EventsFilterComposer,
      $EventsOrderingComposer,
      $EventsAnnotationComposer,
      $EventsCreateCompanionBuilder,
      $EventsUpdateCompanionBuilder,
      (EventRow, $EventsReferences),
      EventRow,
      PrefetchHooks Function({
        bool boothProfileId,
        bool appSettingsRefs,
        bool eventTemplatesRefs,
        bool captureSessionsRefs,
        bool eventDeliveryOptionsRefs,
      })
    >;
typedef $AppSettingsCreateCompanionBuilder = AppSettingsCompanion Function({
  Value<int> id,
  required String boothProfileId,
  Value<DateTime?> setupCompletedAt,
  Value<String?> boothEventId,
});
typedef $AppSettingsUpdateCompanionBuilder = AppSettingsCompanion Function({
  Value<int> id,
  Value<String> boothProfileId,
  Value<DateTime?> setupCompletedAt,
  Value<String?> boothEventId,
});

final class $AppSettingsReferences
    extends BaseReferences<_$BoothDatabase, AppSettings, AppSettingsRow> {
  $AppSettingsReferences(super.$_db, super.$_table, super.$_typedResult);

  static BoothProfiles _boothProfileIdTable(_$BoothDatabase db) => db
      .boothProfiles
      .createAlias('app_settings__booth_profile_id__booth_profiles__id');

  $BoothProfilesProcessedTableManager get boothProfileId {
    final $_column = $_itemColumn<String>('booth_profile_id')!;

    final manager = $BoothProfilesTableManager(
      $_db,
      $_db.boothProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boothProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Events _boothEventIdTable(_$BoothDatabase db) =>
      db.events.createAlias('app_settings__booth_event_id__events__id');

  $EventsProcessedTableManager? get boothEventId {
    final $_column = $_itemColumn<String>('booth_event_id');
    if ($_column == null) return null;
    final manager = $EventsTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_boothEventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AppSettingsFilterComposer
    extends Composer<_$BoothDatabase, AppSettings> {
  $AppSettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get setupCompletedAt => $composableBuilder(
    column: $table.setupCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $BoothProfilesFilterComposer get boothProfileId {
    final $BoothProfilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesFilterComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $EventsFilterComposer get boothEventId {
    final $EventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsOrderingComposer
    extends Composer<_$BoothDatabase, AppSettings> {
  $AppSettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get setupCompletedAt => $composableBuilder(
    column: $table.setupCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $BoothProfilesOrderingComposer get boothProfileId {
    final $BoothProfilesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesOrderingComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $EventsOrderingComposer get boothEventId {
    final $EventsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsAnnotationComposer
    extends Composer<_$BoothDatabase, AppSettings> {
  $AppSettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get setupCompletedAt => $composableBuilder(
    column: $table.setupCompletedAt,
    builder: (column) => column,
  );

  $BoothProfilesAnnotationComposer get boothProfileId {
    final $BoothProfilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothProfileId,
      referencedTable: $db.boothProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $BoothProfilesAnnotationComposer(
            $db: $db,
            $table: $db.boothProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $EventsAnnotationComposer get boothEventId {
    final $EventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.boothEventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AppSettingsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          AppSettings,
          AppSettingsRow,
          $AppSettingsFilterComposer,
          $AppSettingsOrderingComposer,
          $AppSettingsAnnotationComposer,
          $AppSettingsCreateCompanionBuilder,
          $AppSettingsUpdateCompanionBuilder,
          (AppSettingsRow, $AppSettingsReferences),
          AppSettingsRow,
          PrefetchHooks Function({bool boothProfileId, bool boothEventId})
        > {
  $AppSettingsTableManager(_$BoothDatabase db, AppSettings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AppSettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AppSettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AppSettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> boothProfileId = const Value.absent(),
                Value<DateTime?> setupCompletedAt = const Value.absent(),
                Value<String?> boothEventId = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                boothProfileId: boothProfileId,
                setupCompletedAt: setupCompletedAt,
                boothEventId: boothEventId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String boothProfileId,
                Value<DateTime?> setupCompletedAt = const Value.absent(),
                Value<String?> boothEventId = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                boothProfileId: boothProfileId,
                setupCompletedAt: setupCompletedAt,
                boothEventId: boothEventId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<AppSettings, AppSettingsRow>(table),
                  $AppSettingsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({boothProfileId = false, boothEventId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (boothProfileId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.boothProfileId,
                            referencedTable: $AppSettingsReferences
                                ._boothProfileIdTable(db),
                            referencedColumn: $AppSettingsReferences
                                ._boothProfileIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (boothEventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.boothEventId,
                            referencedTable: $AppSettingsReferences
                                ._boothEventIdTable(db),
                            referencedColumn: $AppSettingsReferences
                                ._boothEventIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $AppSettingsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      AppSettings,
      AppSettingsRow,
      $AppSettingsFilterComposer,
      $AppSettingsOrderingComposer,
      $AppSettingsAnnotationComposer,
      $AppSettingsCreateCompanionBuilder,
      $AppSettingsUpdateCompanionBuilder,
      (AppSettingsRow, $AppSettingsReferences),
      AppSettingsRow,
      PrefetchHooks Function({bool boothProfileId, bool boothEventId})
    >;
typedef $OperatorAccessCreateCompanionBuilder =
    OperatorAccessCompanion Function({
      Value<int> id,
      Value<String?> recoveryVerifier,
      Value<int> pinFailures,
      Value<DateTime?> pinLastFailureAt,
      Value<int> recoveryFailures,
      Value<DateTime?> recoveryLastFailureAt,
    });
typedef $OperatorAccessUpdateCompanionBuilder =
    OperatorAccessCompanion Function({
      Value<int> id,
      Value<String?> recoveryVerifier,
      Value<int> pinFailures,
      Value<DateTime?> pinLastFailureAt,
      Value<int> recoveryFailures,
      Value<DateTime?> recoveryLastFailureAt,
    });

class $OperatorAccessFilterComposer
    extends Composer<_$BoothDatabase, OperatorAccess> {
  $OperatorAccessFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryVerifier => $composableBuilder(
    column: $table.recoveryVerifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pinFailures => $composableBuilder(
    column: $table.pinFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pinLastFailureAt => $composableBuilder(
    column: $table.pinLastFailureAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recoveryFailures => $composableBuilder(
    column: $table.recoveryFailures,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recoveryLastFailureAt => $composableBuilder(
    column: $table.recoveryLastFailureAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $OperatorAccessOrderingComposer
    extends Composer<_$BoothDatabase, OperatorAccess> {
  $OperatorAccessOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryVerifier => $composableBuilder(
    column: $table.recoveryVerifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pinFailures => $composableBuilder(
    column: $table.pinFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pinLastFailureAt => $composableBuilder(
    column: $table.pinLastFailureAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recoveryFailures => $composableBuilder(
    column: $table.recoveryFailures,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recoveryLastFailureAt => $composableBuilder(
    column: $table.recoveryLastFailureAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OperatorAccessAnnotationComposer
    extends Composer<_$BoothDatabase, OperatorAccess> {
  $OperatorAccessAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recoveryVerifier => $composableBuilder(
    column: $table.recoveryVerifier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pinFailures => $composableBuilder(
    column: $table.pinFailures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pinLastFailureAt => $composableBuilder(
    column: $table.pinLastFailureAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recoveryFailures => $composableBuilder(
    column: $table.recoveryFailures,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recoveryLastFailureAt => $composableBuilder(
    column: $table.recoveryLastFailureAt,
    builder: (column) => column,
  );
}

class $OperatorAccessTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          OperatorAccess,
          OperatorAccessRow,
          $OperatorAccessFilterComposer,
          $OperatorAccessOrderingComposer,
          $OperatorAccessAnnotationComposer,
          $OperatorAccessCreateCompanionBuilder,
          $OperatorAccessUpdateCompanionBuilder,
          (
            OperatorAccessRow,
            BaseReferences<_$BoothDatabase, OperatorAccess, OperatorAccessRow>,
          ),
          OperatorAccessRow,
          PrefetchHooks Function()
        > {
  $OperatorAccessTableManager(_$BoothDatabase db, OperatorAccess table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OperatorAccessFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OperatorAccessOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OperatorAccessAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> recoveryVerifier = const Value.absent(),
                Value<int> pinFailures = const Value.absent(),
                Value<DateTime?> pinLastFailureAt = const Value.absent(),
                Value<int> recoveryFailures = const Value.absent(),
                Value<DateTime?> recoveryLastFailureAt = const Value.absent(),
              }) => OperatorAccessCompanion(
                id: id,
                recoveryVerifier: recoveryVerifier,
                pinFailures: pinFailures,
                pinLastFailureAt: pinLastFailureAt,
                recoveryFailures: recoveryFailures,
                recoveryLastFailureAt: recoveryLastFailureAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> recoveryVerifier = const Value.absent(),
                Value<int> pinFailures = const Value.absent(),
                Value<DateTime?> pinLastFailureAt = const Value.absent(),
                Value<int> recoveryFailures = const Value.absent(),
                Value<DateTime?> recoveryLastFailureAt = const Value.absent(),
              }) => OperatorAccessCompanion.insert(
                id: id,
                recoveryVerifier: recoveryVerifier,
                pinFailures: pinFailures,
                pinLastFailureAt: pinLastFailureAt,
                recoveryFailures: recoveryFailures,
                recoveryLastFailureAt: recoveryLastFailureAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<OperatorAccess, OperatorAccessRow>(table),
                  BaseReferences<
                    _$BoothDatabase,
                    OperatorAccess,
                    OperatorAccessRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $OperatorAccessProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      OperatorAccess,
      OperatorAccessRow,
      $OperatorAccessFilterComposer,
      $OperatorAccessOrderingComposer,
      $OperatorAccessAnnotationComposer,
      $OperatorAccessCreateCompanionBuilder,
      $OperatorAccessUpdateCompanionBuilder,
      (
        OperatorAccessRow,
        BaseReferences<_$BoothDatabase, OperatorAccess, OperatorAccessRow>,
      ),
      OperatorAccessRow,
      PrefetchHooks Function()
    >;
typedef $TemplatesCreateCompanionBuilder = TemplatesCompanion Function({
  required String id,
  required String displayName,
  Value<String?> category,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});
typedef $TemplatesUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<String?> category,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> archivedAt,
  Value<int> rowid,
});

final class $TemplatesReferences
    extends BaseReferences<_$BoothDatabase, Templates, TemplateRow> {
  $TemplatesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<TemplateRevisions, List<TemplateRevisionRow>>
  _templateRevisionsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateRevisions,
        aliasName: 'templates__id__template_revisions__template_id',
      );

  $TemplateRevisionsProcessedTableManager get templateRevisionsRefs {
    final manager = $TemplateRevisionsTableManager(
      $_db,
      $_db.templateRevisions,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<TemplateDrafts, List<TemplateDraftRow>>
  _templateDraftsRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.templateDrafts,
    aliasName: 'templates__id__template_drafts__template_id',
  );

  $TemplateDraftsProcessedTableManager get templateDraftsRefs {
    final manager = $TemplateDraftsTableManager(
      $_db,
      $_db.templateDrafts,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateDraftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TemplatesFilterComposer extends Composer<_$BoothDatabase, Templates> {
  $TemplatesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateRevisionsRefs(
    Expression<bool> Function($TemplateRevisionsFilterComposer f) f,
  ) {
    final $TemplateRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsFilterComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> templateDraftsRefs(
    Expression<bool> Function($TemplateDraftsFilterComposer f) f,
  ) {
    final $TemplateDraftsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDrafts,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateDraftsFilterComposer(
            $db: $db,
            $table: $db.templateDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TemplatesOrderingComposer extends Composer<_$BoothDatabase, Templates> {
  $TemplatesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $TemplatesAnnotationComposer
    extends Composer<_$BoothDatabase, Templates> {
  $TemplatesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  Expression<T> templateRevisionsRefs<T extends Object>(
    Expression<T> Function($TemplateRevisionsAnnotationComposer a) f,
  ) {
    final $TemplateRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> templateDraftsRefs<T extends Object>(
    Expression<T> Function($TemplateDraftsAnnotationComposer a) f,
  ) {
    final $TemplateDraftsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDrafts,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateDraftsAnnotationComposer(
            $db: $db,
            $table: $db.templateDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TemplatesTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          Templates,
          TemplateRow,
          $TemplatesFilterComposer,
          $TemplatesOrderingComposer,
          $TemplatesAnnotationComposer,
          $TemplatesCreateCompanionBuilder,
          $TemplatesUpdateCompanionBuilder,
          (TemplateRow, $TemplatesReferences),
          TemplateRow,
          PrefetchHooks Function({
            bool templateRevisionsRefs,
            bool templateDraftsRefs,
          })
        > {
  $TemplatesTableManager(_$BoothDatabase db, Templates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TemplatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TemplatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TemplatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                displayName: displayName,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<String?> category = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                displayName: displayName,
                category: category,
                createdAt: createdAt,
                updatedAt: updatedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Templates, TemplateRow>(table),
                  $TemplatesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateRevisionsRefs = false, templateDraftsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateRevisionsRefs) db.templateRevisions,
                    if (templateDraftsRefs) db.templateDrafts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateRevisionsRefs)
                        await $_getPrefetchedData<
                          TemplateRow,
                          Templates,
                          TemplateRevisionRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplatesReferences
                              ._templateRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) => $TemplatesReferences(
                            db,
                            table,
                            p0,
                          ).templateRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (templateDraftsRefs)
                        await $_getPrefetchedData<
                          TemplateRow,
                          Templates,
                          TemplateDraftRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplatesReferences
                              ._templateDraftsRefsTable(db),
                          managerFromTypedResult: (p0) => $TemplatesReferences(
                            db,
                            table,
                            p0,
                          ).templateDraftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TemplatesProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      Templates,
      TemplateRow,
      $TemplatesFilterComposer,
      $TemplatesOrderingComposer,
      $TemplatesAnnotationComposer,
      $TemplatesCreateCompanionBuilder,
      $TemplatesUpdateCompanionBuilder,
      (TemplateRow, $TemplatesReferences),
      TemplateRow,
      PrefetchHooks Function({
        bool templateRevisionsRefs,
        bool templateDraftsRefs,
      })
    >;
typedef $TemplateRevisionsCreateCompanionBuilder =
    TemplateRevisionsCompanion Function({
      required String id,
      required String templateId,
      required int revisionNumber,
      required int documentSchemaVersion,
      required String manifestPath,
      required String checksum,
      required int pageWidthPx,
      required int pageHeightPx,
      required int photoSlotCount,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $TemplateRevisionsUpdateCompanionBuilder =
    TemplateRevisionsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<int> revisionNumber,
      Value<int> documentSchemaVersion,
      Value<String> manifestPath,
      Value<String> checksum,
      Value<int> pageWidthPx,
      Value<int> pageHeightPx,
      Value<int> photoSlotCount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $TemplateRevisionsReferences
    extends
        BaseReferences<
          _$BoothDatabase,
          TemplateRevisions,
          TemplateRevisionRow
        > {
  $TemplateRevisionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Templates _templateIdTable(_$BoothDatabase db) => db.templates
      .createAlias('template_revisions__template_id__templates__id');

  $TemplatesProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $TemplatesTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    TemplateRevisionAssets,
    List<TemplateRevisionAssetRow>
  >
  _templateRevisionAssetsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateRevisionAssets,
        aliasName: 'template_revisions__id__template_revision_assets__template_revision_id',
      );

  $TemplateRevisionAssetsProcessedTableManager get templateRevisionAssetsRefs {
    final manager =
        $TemplateRevisionAssetsTableManager(
          $_db,
          $_db.templateRevisionAssets,
        ).filter(
          (f) => f.templateRevisionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _templateRevisionAssetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<TemplateDrafts, List<TemplateDraftRow>>
  _templateDraftsRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.templateDrafts,
    aliasName: 'template_revisions__id__template_drafts__base_revision_id',
  );

  $TemplateDraftsProcessedTableManager get templateDraftsRefs {
    final manager = $TemplateDraftsTableManager(
      $_db,
      $_db.templateDrafts,
    ).filter((f) => f.baseRevisionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateDraftsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<EventTemplates, List<EventTemplateRow>>
  _eventTemplatesRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.eventTemplates,
    aliasName: 'template_revisions__id__event_templates__template_revision_id',
  );

  $EventTemplatesProcessedTableManager get eventTemplatesRefs {
    final manager = $EventTemplatesTableManager($_db, $_db.eventTemplates)
        .filter(
          (f) => f.templateRevisionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_eventTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaptureSessions, List<CaptureSessionRow>>
  _captureSessionsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.captureSessions,
        aliasName:
            'template_revisions__id__capture_sessions__template_revision_id',
      );

  $CaptureSessionsProcessedTableManager get captureSessionsRefs {
    final manager = $CaptureSessionsTableManager($_db, $_db.captureSessions)
        .filter(
          (f) => f.templateRevisionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _captureSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $TemplateRevisionsFilterComposer
    extends Composer<_$BoothDatabase, TemplateRevisions> {
  $TemplateRevisionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get documentSchemaVersion => $composableBuilder(
    column: $table.documentSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manifestPath => $composableBuilder(
    column: $table.manifestPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageWidthPx => $composableBuilder(
    column: $table.pageWidthPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageHeightPx => $composableBuilder(
    column: $table.pageHeightPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get photoSlotCount => $composableBuilder(
    column: $table.photoSlotCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $TemplatesFilterComposer get templateId {
    final $TemplatesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> templateRevisionAssetsRefs(
    Expression<bool> Function($TemplateRevisionAssetsFilterComposer f) f,
  ) {
    final $TemplateRevisionAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisionAssets,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionAssetsFilterComposer(
            $db: $db,
            $table: $db.templateRevisionAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> templateDraftsRefs(
    Expression<bool> Function($TemplateDraftsFilterComposer f) f,
  ) {
    final $TemplateDraftsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDrafts,
      getReferencedColumn: (t) => t.baseRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateDraftsFilterComposer(
            $db: $db,
            $table: $db.templateDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventTemplatesRefs(
    Expression<bool> Function($EventTemplatesFilterComposer f) f,
  ) {
    final $EventTemplatesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTemplates,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventTemplatesFilterComposer(
            $db: $db,
            $table: $db.eventTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> captureSessionsRefs(
    Expression<bool> Function($CaptureSessionsFilterComposer f) f,
  ) {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TemplateRevisionsOrderingComposer
    extends Composer<_$BoothDatabase, TemplateRevisions> {
  $TemplateRevisionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get documentSchemaVersion => $composableBuilder(
    column: $table.documentSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manifestPath => $composableBuilder(
    column: $table.manifestPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageWidthPx => $composableBuilder(
    column: $table.pageWidthPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageHeightPx => $composableBuilder(
    column: $table.pageHeightPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get photoSlotCount => $composableBuilder(
    column: $table.photoSlotCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $TemplatesOrderingComposer get templateId {
    final $TemplatesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateRevisionsAnnotationComposer
    extends Composer<_$BoothDatabase, TemplateRevisions> {
  $TemplateRevisionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revisionNumber => $composableBuilder(
    column: $table.revisionNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get documentSchemaVersion => $composableBuilder(
    column: $table.documentSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get manifestPath => $composableBuilder(
    column: $table.manifestPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get pageWidthPx => $composableBuilder(
    column: $table.pageWidthPx,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageHeightPx => $composableBuilder(
    column: $table.pageHeightPx,
    builder: (column) => column,
  );

  GeneratedColumn<int> get photoSlotCount => $composableBuilder(
    column: $table.photoSlotCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $TemplatesAnnotationComposer get templateId {
    final $TemplatesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> templateRevisionAssetsRefs<T extends Object>(
    Expression<T> Function($TemplateRevisionAssetsAnnotationComposer a) f,
  ) {
    final $TemplateRevisionAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisionAssets,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionAssetsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisionAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> templateDraftsRefs<T extends Object>(
    Expression<T> Function($TemplateDraftsAnnotationComposer a) f,
  ) {
    final $TemplateDraftsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateDrafts,
      getReferencedColumn: (t) => t.baseRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateDraftsAnnotationComposer(
            $db: $db,
            $table: $db.templateDrafts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventTemplatesRefs<T extends Object>(
    Expression<T> Function($EventTemplatesAnnotationComposer a) f,
  ) {
    final $EventTemplatesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventTemplates,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventTemplatesAnnotationComposer(
            $db: $db,
            $table: $db.eventTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> captureSessionsRefs<T extends Object>(
    Expression<T> Function($CaptureSessionsAnnotationComposer a) f,
  ) {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.templateRevisionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $TemplateRevisionsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          TemplateRevisions,
          TemplateRevisionRow,
          $TemplateRevisionsFilterComposer,
          $TemplateRevisionsOrderingComposer,
          $TemplateRevisionsAnnotationComposer,
          $TemplateRevisionsCreateCompanionBuilder,
          $TemplateRevisionsUpdateCompanionBuilder,
          (TemplateRevisionRow, $TemplateRevisionsReferences),
          TemplateRevisionRow,
          PrefetchHooks Function({
            bool templateId,
            bool templateRevisionAssetsRefs,
            bool templateDraftsRefs,
            bool eventTemplatesRefs,
            bool captureSessionsRefs,
          })
        > {
  $TemplateRevisionsTableManager(_$BoothDatabase db, TemplateRevisions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TemplateRevisionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TemplateRevisionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TemplateRevisionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<int> revisionNumber = const Value.absent(),
                Value<int> documentSchemaVersion = const Value.absent(),
                Value<String> manifestPath = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<int> pageWidthPx = const Value.absent(),
                Value<int> pageHeightPx = const Value.absent(),
                Value<int> photoSlotCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateRevisionsCompanion(
                id: id,
                templateId: templateId,
                revisionNumber: revisionNumber,
                documentSchemaVersion: documentSchemaVersion,
                manifestPath: manifestPath,
                checksum: checksum,
                pageWidthPx: pageWidthPx,
                pageHeightPx: pageHeightPx,
                photoSlotCount: photoSlotCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required int revisionNumber,
                required int documentSchemaVersion,
                required String manifestPath,
                required String checksum,
                required int pageWidthPx,
                required int pageHeightPx,
                required int photoSlotCount,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TemplateRevisionsCompanion.insert(
                id: id,
                templateId: templateId,
                revisionNumber: revisionNumber,
                documentSchemaVersion: documentSchemaVersion,
                manifestPath: manifestPath,
                checksum: checksum,
                pageWidthPx: pageWidthPx,
                pageHeightPx: pageHeightPx,
                photoSlotCount: photoSlotCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TemplateRevisions, TemplateRevisionRow>(table),
                  $TemplateRevisionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                templateId = false,
                templateRevisionAssetsRefs = false,
                templateDraftsRefs = false,
                eventTemplatesRefs = false,
                captureSessionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateRevisionAssetsRefs) db.templateRevisionAssets,
                    if (templateDraftsRefs) db.templateDrafts,
                    if (eventTemplatesRefs) db.eventTemplates,
                    if (captureSessionsRefs) db.captureSessions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateId,
                            referencedTable: $TemplateRevisionsReferences
                                ._templateIdTable(db),
                            referencedColumn: $TemplateRevisionsReferences
                                ._templateIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateRevisionAssetsRefs)
                        await $_getPrefetchedData<
                          TemplateRevisionRow,
                          TemplateRevisions,
                          TemplateRevisionAssetRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplateRevisionsReferences
                              ._templateRevisionAssetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TemplateRevisionsReferences(
                                db,
                                table,
                                p0,
                              ).templateRevisionAssetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateRevisionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (templateDraftsRefs)
                        await $_getPrefetchedData<
                          TemplateRevisionRow,
                          TemplateRevisions,
                          TemplateDraftRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplateRevisionsReferences
                              ._templateDraftsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TemplateRevisionsReferences(
                                db,
                                table,
                                p0,
                              ).templateDraftsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.baseRevisionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventTemplatesRefs)
                        await $_getPrefetchedData<
                          TemplateRevisionRow,
                          TemplateRevisions,
                          EventTemplateRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplateRevisionsReferences
                              ._eventTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TemplateRevisionsReferences(
                                db,
                                table,
                                p0,
                              ).eventTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateRevisionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (captureSessionsRefs)
                        await $_getPrefetchedData<
                          TemplateRevisionRow,
                          TemplateRevisions,
                          CaptureSessionRow
                        >(
                          currentTable: table,
                          referencedTable: $TemplateRevisionsReferences
                              ._captureSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $TemplateRevisionsReferences(
                                db,
                                table,
                                p0,
                              ).captureSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.templateRevisionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $TemplateRevisionsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      TemplateRevisions,
      TemplateRevisionRow,
      $TemplateRevisionsFilterComposer,
      $TemplateRevisionsOrderingComposer,
      $TemplateRevisionsAnnotationComposer,
      $TemplateRevisionsCreateCompanionBuilder,
      $TemplateRevisionsUpdateCompanionBuilder,
      (TemplateRevisionRow, $TemplateRevisionsReferences),
      TemplateRevisionRow,
      PrefetchHooks Function({
        bool templateId,
        bool templateRevisionAssetsRefs,
        bool templateDraftsRefs,
        bool eventTemplatesRefs,
        bool captureSessionsRefs,
      })
    >;
typedef $AssetsCreateCompanionBuilder = AssetsCompanion Function({
  required String id,
  required AssetMediaType mediaType,
  required String relativePath,
  required int byteLength,
  Value<int?> widthPx,
  Value<int?> heightPx,
  Value<String?> displayName,
  required AssetOrigin origin,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $AssetsUpdateCompanionBuilder = AssetsCompanion Function({
  Value<String> id,
  Value<AssetMediaType> mediaType,
  Value<String> relativePath,
  Value<int> byteLength,
  Value<int?> widthPx,
  Value<int?> heightPx,
  Value<String?> displayName,
  Value<AssetOrigin> origin,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $AssetsReferences
    extends BaseReferences<_$BoothDatabase, Assets, AssetRow> {
  $AssetsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    TemplateRevisionAssets,
    List<TemplateRevisionAssetRow>
  >
  _templateRevisionAssetsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateRevisionAssets,
        aliasName: 'assets__id__template_revision_assets__asset_id',
      );

  $TemplateRevisionAssetsProcessedTableManager get templateRevisionAssetsRefs {
    final manager = $TemplateRevisionAssetsTableManager(
      $_db,
      $_db.templateRevisionAssets,
    ).filter((f) => f.assetId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateRevisionAssetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $AssetsFilterComposer extends Composer<_$BoothDatabase, Assets> {
  $AssetsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetMediaType, AssetMediaType, String>
  get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AssetOrigin, AssetOrigin, String> get origin =>
      $composableBuilder(
        column: $table.origin,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateRevisionAssetsRefs(
    Expression<bool> Function($TemplateRevisionAssetsFilterComposer f) f,
  ) {
    final $TemplateRevisionAssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisionAssets,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionAssetsFilterComposer(
            $db: $db,
            $table: $db.templateRevisionAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AssetsOrderingComposer extends Composer<_$BoothDatabase, Assets> {
  $AssetsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AssetsAnnotationComposer extends Composer<_$BoothDatabase, Assets> {
  $AssetsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AssetMediaType, String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widthPx =>
      $composableBuilder(column: $table.widthPx, builder: (column) => column);

  GeneratedColumn<int> get heightPx =>
      $composableBuilder(column: $table.heightPx, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<AssetOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> templateRevisionAssetsRefs<T extends Object>(
    Expression<T> Function($TemplateRevisionAssetsAnnotationComposer a) f,
  ) {
    final $TemplateRevisionAssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateRevisionAssets,
      getReferencedColumn: (t) => t.assetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionAssetsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisionAssets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $AssetsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          Assets,
          AssetRow,
          $AssetsFilterComposer,
          $AssetsOrderingComposer,
          $AssetsAnnotationComposer,
          $AssetsCreateCompanionBuilder,
          $AssetsUpdateCompanionBuilder,
          (AssetRow, $AssetsReferences),
          AssetRow,
          PrefetchHooks Function({bool templateRevisionAssetsRefs})
        > {
  $AssetsTableManager(_$BoothDatabase db, Assets table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AssetsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AssetsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AssetsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<AssetMediaType> mediaType = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int> byteLength = const Value.absent(),
                Value<int?> widthPx = const Value.absent(),
                Value<int?> heightPx = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<AssetOrigin> origin = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                mediaType: mediaType,
                relativePath: relativePath,
                byteLength: byteLength,
                widthPx: widthPx,
                heightPx: heightPx,
                displayName: displayName,
                origin: origin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required AssetMediaType mediaType,
                required String relativePath,
                required int byteLength,
                Value<int?> widthPx = const Value.absent(),
                Value<int?> heightPx = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                required AssetOrigin origin,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                mediaType: mediaType,
                relativePath: relativePath,
                byteLength: byteLength,
                widthPx: widthPx,
                heightPx: heightPx,
                displayName: displayName,
                origin: origin,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Assets, AssetRow>(table),
                  $AssetsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateRevisionAssetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateRevisionAssetsRefs) db.templateRevisionAssets,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateRevisionAssetsRefs)
                    await $_getPrefetchedData<
                      AssetRow,
                      Assets,
                      TemplateRevisionAssetRow
                    >(
                      currentTable: table,
                      referencedTable: $AssetsReferences
                          ._templateRevisionAssetsRefsTable(db),
                      managerFromTypedResult: (p0) => $AssetsReferences(
                        db,
                        table,
                        p0,
                      ).templateRevisionAssetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.assetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $AssetsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      Assets,
      AssetRow,
      $AssetsFilterComposer,
      $AssetsOrderingComposer,
      $AssetsAnnotationComposer,
      $AssetsCreateCompanionBuilder,
      $AssetsUpdateCompanionBuilder,
      (AssetRow, $AssetsReferences),
      AssetRow,
      PrefetchHooks Function({bool templateRevisionAssetsRefs})
    >;
typedef $TemplateRevisionAssetsCreateCompanionBuilder =
    TemplateRevisionAssetsCompanion Function({
      required String templateRevisionId,
      required String assetId,
      Value<int> rowid,
    });
typedef $TemplateRevisionAssetsUpdateCompanionBuilder =
    TemplateRevisionAssetsCompanion Function({
      Value<String> templateRevisionId,
      Value<String> assetId,
      Value<int> rowid,
    });

final class $TemplateRevisionAssetsReferences
    extends
        BaseReferences<
          _$BoothDatabase,
          TemplateRevisionAssets,
          TemplateRevisionAssetRow
        > {
  $TemplateRevisionAssetsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static TemplateRevisions _templateRevisionIdTable(
    _$BoothDatabase db,
  ) => db.templateRevisions.createAlias(
    'template_revision_assets__template_revision_id__template_revisions__id',
  );

  $TemplateRevisionsProcessedTableManager get templateRevisionId {
    final $_column = $_itemColumn<String>('template_revision_id')!;

    final manager = $TemplateRevisionsTableManager(
      $_db,
      $_db.templateRevisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateRevisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Assets _assetIdTable(_$BoothDatabase db) =>
      db.assets.createAlias('template_revision_assets__asset_id__assets__id');

  $AssetsProcessedTableManager get assetId {
    final $_column = $_itemColumn<String>('asset_id')!;

    final manager = $AssetsTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TemplateRevisionAssetsFilterComposer
    extends Composer<_$BoothDatabase, TemplateRevisionAssets> {
  $TemplateRevisionAssetsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $TemplateRevisionsFilterComposer get templateRevisionId {
    final $TemplateRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsFilterComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $AssetsFilterComposer get assetId {
    final $AssetsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AssetsFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateRevisionAssetsOrderingComposer
    extends Composer<_$BoothDatabase, TemplateRevisionAssets> {
  $TemplateRevisionAssetsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $TemplateRevisionsOrderingComposer get templateRevisionId {
    final $TemplateRevisionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsOrderingComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $AssetsOrderingComposer get assetId {
    final $AssetsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AssetsOrderingComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateRevisionAssetsAnnotationComposer
    extends Composer<_$BoothDatabase, TemplateRevisionAssets> {
  $TemplateRevisionAssetsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $TemplateRevisionsAnnotationComposer get templateRevisionId {
    final $TemplateRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $AssetsAnnotationComposer get assetId {
    final $AssetsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assetId,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AssetsAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateRevisionAssetsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          TemplateRevisionAssets,
          TemplateRevisionAssetRow,
          $TemplateRevisionAssetsFilterComposer,
          $TemplateRevisionAssetsOrderingComposer,
          $TemplateRevisionAssetsAnnotationComposer,
          $TemplateRevisionAssetsCreateCompanionBuilder,
          $TemplateRevisionAssetsUpdateCompanionBuilder,
          (TemplateRevisionAssetRow, $TemplateRevisionAssetsReferences),
          TemplateRevisionAssetRow,
          PrefetchHooks Function({bool templateRevisionId, bool assetId})
        > {
  $TemplateRevisionAssetsTableManager(
    _$BoothDatabase db,
    TemplateRevisionAssets table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TemplateRevisionAssetsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TemplateRevisionAssetsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TemplateRevisionAssetsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> templateRevisionId = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateRevisionAssetsCompanion(
                templateRevisionId: templateRevisionId,
                assetId: assetId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String templateRevisionId,
                required String assetId,
                Value<int> rowid = const Value.absent(),
              }) => TemplateRevisionAssetsCompanion.insert(
                templateRevisionId: templateRevisionId,
                assetId: assetId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TemplateRevisionAssets, TemplateRevisionAssetRow>(
                    table,
                  ),
                  $TemplateRevisionAssetsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateRevisionId = false, assetId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateRevisionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateRevisionId,
                            referencedTable: $TemplateRevisionAssetsReferences
                                ._templateRevisionIdTable(db),
                            referencedColumn: $TemplateRevisionAssetsReferences
                                ._templateRevisionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (assetId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.assetId,
                            referencedTable: $TemplateRevisionAssetsReferences
                                ._assetIdTable(db),
                            referencedColumn: $TemplateRevisionAssetsReferences
                                ._assetIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $TemplateRevisionAssetsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      TemplateRevisionAssets,
      TemplateRevisionAssetRow,
      $TemplateRevisionAssetsFilterComposer,
      $TemplateRevisionAssetsOrderingComposer,
      $TemplateRevisionAssetsAnnotationComposer,
      $TemplateRevisionAssetsCreateCompanionBuilder,
      $TemplateRevisionAssetsUpdateCompanionBuilder,
      (TemplateRevisionAssetRow, $TemplateRevisionAssetsReferences),
      TemplateRevisionAssetRow,
      PrefetchHooks Function({bool templateRevisionId, bool assetId})
    >;
typedef $TemplateDraftsCreateCompanionBuilder =
    TemplateDraftsCompanion Function({
      required String templateId,
      required String baseRevisionId,
      required String document,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $TemplateDraftsUpdateCompanionBuilder =
    TemplateDraftsCompanion Function({
      Value<String> templateId,
      Value<String> baseRevisionId,
      Value<String> document,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $TemplateDraftsReferences
    extends BaseReferences<_$BoothDatabase, TemplateDrafts, TemplateDraftRow> {
  $TemplateDraftsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Templates _templateIdTable(_$BoothDatabase db) =>
      db.templates.createAlias('template_drafts__template_id__templates__id');

  $TemplatesProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $TemplatesTableManager(
      $_db,
      $_db.templates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static TemplateRevisions _baseRevisionIdTable(_$BoothDatabase db) => db
      .templateRevisions
      .createAlias('template_drafts__base_revision_id__template_revisions__id');

  $TemplateRevisionsProcessedTableManager get baseRevisionId {
    final $_column = $_itemColumn<String>('base_revision_id')!;

    final manager = $TemplateRevisionsTableManager(
      $_db,
      $_db.templateRevisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_baseRevisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TemplateDraftsFilterComposer
    extends Composer<_$BoothDatabase, TemplateDrafts> {
  $TemplateDraftsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $TemplatesFilterComposer get templateId {
    final $TemplatesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsFilterComposer get baseRevisionId {
    final $TemplateRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsFilterComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateDraftsOrderingComposer
    extends Composer<_$BoothDatabase, TemplateDrafts> {
  $TemplateDraftsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get document => $composableBuilder(
    column: $table.document,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $TemplatesOrderingComposer get templateId {
    final $TemplatesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsOrderingComposer get baseRevisionId {
    final $TemplateRevisionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsOrderingComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateDraftsAnnotationComposer
    extends Composer<_$BoothDatabase, TemplateDrafts> {
  $TemplateDraftsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get document =>
      $composableBuilder(column: $table.document, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $TemplatesAnnotationComposer get templateId {
    final $TemplatesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplatesAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsAnnotationComposer get baseRevisionId {
    final $TemplateRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.baseRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TemplateDraftsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          TemplateDrafts,
          TemplateDraftRow,
          $TemplateDraftsFilterComposer,
          $TemplateDraftsOrderingComposer,
          $TemplateDraftsAnnotationComposer,
          $TemplateDraftsCreateCompanionBuilder,
          $TemplateDraftsUpdateCompanionBuilder,
          (TemplateDraftRow, $TemplateDraftsReferences),
          TemplateDraftRow,
          PrefetchHooks Function({bool templateId, bool baseRevisionId})
        > {
  $TemplateDraftsTableManager(_$BoothDatabase db, TemplateDrafts table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TemplateDraftsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TemplateDraftsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TemplateDraftsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> templateId = const Value.absent(),
                Value<String> baseRevisionId = const Value.absent(),
                Value<String> document = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateDraftsCompanion(
                templateId: templateId,
                baseRevisionId: baseRevisionId,
                document: document,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String templateId,
                required String baseRevisionId,
                required String document,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TemplateDraftsCompanion.insert(
                templateId: templateId,
                baseRevisionId: baseRevisionId,
                document: document,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<TemplateDrafts, TemplateDraftRow>(table),
                  $TemplateDraftsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateId = false, baseRevisionId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (templateId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateId,
                            referencedTable: $TemplateDraftsReferences
                                ._templateIdTable(db),
                            referencedColumn: $TemplateDraftsReferences
                                ._templateIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (baseRevisionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.baseRevisionId,
                            referencedTable: $TemplateDraftsReferences
                                ._baseRevisionIdTable(db),
                            referencedColumn: $TemplateDraftsReferences
                                ._baseRevisionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $TemplateDraftsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      TemplateDrafts,
      TemplateDraftRow,
      $TemplateDraftsFilterComposer,
      $TemplateDraftsOrderingComposer,
      $TemplateDraftsAnnotationComposer,
      $TemplateDraftsCreateCompanionBuilder,
      $TemplateDraftsUpdateCompanionBuilder,
      (TemplateDraftRow, $TemplateDraftsReferences),
      TemplateDraftRow,
      PrefetchHooks Function({bool templateId, bool baseRevisionId})
    >;
typedef $EventTemplatesCreateCompanionBuilder =
    EventTemplatesCompanion Function({
      required String eventId,
      required String templateRevisionId,
      required int position,
      required bool isDefault,
      Value<int> rowid,
    });
typedef $EventTemplatesUpdateCompanionBuilder =
    EventTemplatesCompanion Function({
      Value<String> eventId,
      Value<String> templateRevisionId,
      Value<int> position,
      Value<bool> isDefault,
      Value<int> rowid,
    });

final class $EventTemplatesReferences
    extends BaseReferences<_$BoothDatabase, EventTemplates, EventTemplateRow> {
  $EventTemplatesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Events _eventIdTable(_$BoothDatabase db) =>
      db.events.createAlias('event_templates__event_id__events__id');

  $EventsProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $EventsTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static TemplateRevisions _templateRevisionIdTable(_$BoothDatabase db) =>
      db.templateRevisions.createAlias(
        'event_templates__template_revision_id__template_revisions__id',
      );

  $TemplateRevisionsProcessedTableManager get templateRevisionId {
    final $_column = $_itemColumn<String>('template_revision_id')!;

    final manager = $TemplateRevisionsTableManager(
      $_db,
      $_db.templateRevisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateRevisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EventTemplatesFilterComposer
    extends Composer<_$BoothDatabase, EventTemplates> {
  $EventTemplatesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  $EventsFilterComposer get eventId {
    final $EventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsFilterComposer get templateRevisionId {
    final $TemplateRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsFilterComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventTemplatesOrderingComposer
    extends Composer<_$BoothDatabase, EventTemplates> {
  $EventTemplatesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  $EventsOrderingComposer get eventId {
    final $EventsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsOrderingComposer get templateRevisionId {
    final $TemplateRevisionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsOrderingComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventTemplatesAnnotationComposer
    extends Composer<_$BoothDatabase, EventTemplates> {
  $EventTemplatesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  $EventsAnnotationComposer get eventId {
    final $EventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsAnnotationComposer get templateRevisionId {
    final $TemplateRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventTemplatesTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          EventTemplates,
          EventTemplateRow,
          $EventTemplatesFilterComposer,
          $EventTemplatesOrderingComposer,
          $EventTemplatesAnnotationComposer,
          $EventTemplatesCreateCompanionBuilder,
          $EventTemplatesUpdateCompanionBuilder,
          (EventTemplateRow, $EventTemplatesReferences),
          EventTemplateRow,
          PrefetchHooks Function({bool eventId, bool templateRevisionId})
        > {
  $EventTemplatesTableManager(_$BoothDatabase db, EventTemplates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EventTemplatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EventTemplatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EventTemplatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> templateRevisionId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventTemplatesCompanion(
                eventId: eventId,
                templateRevisionId: templateRevisionId,
                position: position,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String templateRevisionId,
                required int position,
                required bool isDefault,
                Value<int> rowid = const Value.absent(),
              }) => EventTemplatesCompanion.insert(
                eventId: eventId,
                templateRevisionId: templateRevisionId,
                position: position,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EventTemplates, EventTemplateRow>(table),
                  $EventTemplatesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({eventId = false, templateRevisionId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $EventTemplatesReferences
                                ._eventIdTable(db),
                            referencedColumn: $EventTemplatesReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (templateRevisionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateRevisionId,
                            referencedTable: $EventTemplatesReferences
                                ._templateRevisionIdTable(db),
                            referencedColumn: $EventTemplatesReferences
                                ._templateRevisionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $EventTemplatesProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      EventTemplates,
      EventTemplateRow,
      $EventTemplatesFilterComposer,
      $EventTemplatesOrderingComposer,
      $EventTemplatesAnnotationComposer,
      $EventTemplatesCreateCompanionBuilder,
      $EventTemplatesUpdateCompanionBuilder,
      (EventTemplateRow, $EventTemplatesReferences),
      EventTemplateRow,
      PrefetchHooks Function({bool eventId, bool templateRevisionId})
    >;
typedef $OriginalPhotosCreateCompanionBuilder =
    OriginalPhotosCompanion Function({
      required String id,
      required String relativePath,
      required int widthPx,
      required int heightPx,
      required int byteLength,
      required String sha256,
      required CameraLens lens,
      required int sensorOrientation,
      required CaptureOrientation deviceOrientation,
      Value<int?> exifOrientation,
      required bool mirrorPreview,
      required bool mirrorOutput,
      required CaptureOrigin origin,
      required DateTime capturedAt,
      required DateTime committedAt,
      Value<int> rowid,
    });
typedef $OriginalPhotosUpdateCompanionBuilder =
    OriginalPhotosCompanion Function({
      Value<String> id,
      Value<String> relativePath,
      Value<int> widthPx,
      Value<int> heightPx,
      Value<int> byteLength,
      Value<String> sha256,
      Value<CameraLens> lens,
      Value<int> sensorOrientation,
      Value<CaptureOrientation> deviceOrientation,
      Value<int?> exifOrientation,
      Value<bool> mirrorPreview,
      Value<bool> mirrorOutput,
      Value<CaptureOrigin> origin,
      Value<DateTime> capturedAt,
      Value<DateTime> committedAt,
      Value<int> rowid,
    });

final class $OriginalPhotosReferences
    extends BaseReferences<_$BoothDatabase, OriginalPhotos, OriginalPhotoRow> {
  $OriginalPhotosReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<SessionPhotos, List<SessionPhotoRow>>
  _sessionPhotosRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionPhotos,
    aliasName: 'original_photos__id__session_photos__original_id',
  );

  $SessionPhotosProcessedTableManager get sessionPhotosRefs {
    final manager = $SessionPhotosTableManager(
      $_db,
      $_db.sessionPhotos,
    ).filter((f) => f.originalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $OriginalPhotosFilterComposer
    extends Composer<_$BoothDatabase, OriginalPhotos> {
  $OriginalPhotosFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CameraLens, CameraLens, String> get lens =>
      $composableBuilder(
        column: $table.lens,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sensorOrientation => $composableBuilder(
    column: $table.sensorOrientation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CaptureOrientation, CaptureOrientation, String>
  get deviceOrientation => $composableBuilder(
    column: $table.deviceOrientation,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get exifOrientation => $composableBuilder(
    column: $table.exifOrientation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CaptureOrigin, CaptureOrigin, String>
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionPhotosRefs(
    Expression<bool> Function($SessionPhotosFilterComposer f) f,
  ) {
    final $SessionPhotosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPhotos,
      getReferencedColumn: (t) => t.originalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionPhotosFilterComposer(
            $db: $db,
            $table: $db.sessionPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OriginalPhotosOrderingComposer
    extends Composer<_$BoothDatabase, OriginalPhotos> {
  $OriginalPhotosOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lens => $composableBuilder(
    column: $table.lens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sensorOrientation => $composableBuilder(
    column: $table.sensorOrientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceOrientation => $composableBuilder(
    column: $table.deviceOrientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exifOrientation => $composableBuilder(
    column: $table.exifOrientation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OriginalPhotosAnnotationComposer
    extends Composer<_$BoothDatabase, OriginalPhotos> {
  $OriginalPhotosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widthPx =>
      $composableBuilder(column: $table.widthPx, builder: (column) => column);

  GeneratedColumn<int> get heightPx =>
      $composableBuilder(column: $table.heightPx, builder: (column) => column);

  GeneratedColumn<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CameraLens, String> get lens =>
      $composableBuilder(column: $table.lens, builder: (column) => column);

  GeneratedColumn<int> get sensorOrientation => $composableBuilder(
    column: $table.sensorOrientation,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CaptureOrientation, String>
  get deviceOrientation => $composableBuilder(
    column: $table.deviceOrientation,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exifOrientation => $composableBuilder(
    column: $table.exifOrientation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mirrorPreview => $composableBuilder(
    column: $table.mirrorPreview,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get mirrorOutput => $composableBuilder(
    column: $table.mirrorOutput,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<CaptureOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get committedAt => $composableBuilder(
    column: $table.committedAt,
    builder: (column) => column,
  );

  Expression<T> sessionPhotosRefs<T extends Object>(
    Expression<T> Function($SessionPhotosAnnotationComposer a) f,
  ) {
    final $SessionPhotosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPhotos,
      getReferencedColumn: (t) => t.originalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionPhotosAnnotationComposer(
            $db: $db,
            $table: $db.sessionPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OriginalPhotosTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          OriginalPhotos,
          OriginalPhotoRow,
          $OriginalPhotosFilterComposer,
          $OriginalPhotosOrderingComposer,
          $OriginalPhotosAnnotationComposer,
          $OriginalPhotosCreateCompanionBuilder,
          $OriginalPhotosUpdateCompanionBuilder,
          (OriginalPhotoRow, $OriginalPhotosReferences),
          OriginalPhotoRow,
          PrefetchHooks Function({bool sessionPhotosRefs})
        > {
  $OriginalPhotosTableManager(_$BoothDatabase db, OriginalPhotos table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OriginalPhotosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OriginalPhotosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OriginalPhotosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<int> widthPx = const Value.absent(),
                Value<int> heightPx = const Value.absent(),
                Value<int> byteLength = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<CameraLens> lens = const Value.absent(),
                Value<int> sensorOrientation = const Value.absent(),
                Value<CaptureOrientation> deviceOrientation =
                    const Value.absent(),
                Value<int?> exifOrientation = const Value.absent(),
                Value<bool> mirrorPreview = const Value.absent(),
                Value<bool> mirrorOutput = const Value.absent(),
                Value<CaptureOrigin> origin = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime> committedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OriginalPhotosCompanion(
                id: id,
                relativePath: relativePath,
                widthPx: widthPx,
                heightPx: heightPx,
                byteLength: byteLength,
                sha256: sha256,
                lens: lens,
                sensorOrientation: sensorOrientation,
                deviceOrientation: deviceOrientation,
                exifOrientation: exifOrientation,
                mirrorPreview: mirrorPreview,
                mirrorOutput: mirrorOutput,
                origin: origin,
                capturedAt: capturedAt,
                committedAt: committedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String relativePath,
                required int widthPx,
                required int heightPx,
                required int byteLength,
                required String sha256,
                required CameraLens lens,
                required int sensorOrientation,
                required CaptureOrientation deviceOrientation,
                Value<int?> exifOrientation = const Value.absent(),
                required bool mirrorPreview,
                required bool mirrorOutput,
                required CaptureOrigin origin,
                required DateTime capturedAt,
                required DateTime committedAt,
                Value<int> rowid = const Value.absent(),
              }) => OriginalPhotosCompanion.insert(
                id: id,
                relativePath: relativePath,
                widthPx: widthPx,
                heightPx: heightPx,
                byteLength: byteLength,
                sha256: sha256,
                lens: lens,
                sensorOrientation: sensorOrientation,
                deviceOrientation: deviceOrientation,
                exifOrientation: exifOrientation,
                mirrorPreview: mirrorPreview,
                mirrorOutput: mirrorOutput,
                origin: origin,
                capturedAt: capturedAt,
                committedAt: committedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<OriginalPhotos, OriginalPhotoRow>(table),
                  $OriginalPhotosReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionPhotosRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionPhotosRefs) db.sessionPhotos,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionPhotosRefs)
                    await $_getPrefetchedData<
                      OriginalPhotoRow,
                      OriginalPhotos,
                      SessionPhotoRow
                    >(
                      currentTable: table,
                      referencedTable: $OriginalPhotosReferences
                          ._sessionPhotosRefsTable(db),
                      managerFromTypedResult: (p0) => $OriginalPhotosReferences(
                        db,
                        table,
                        p0,
                      ).sessionPhotosRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.originalId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $OriginalPhotosProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      OriginalPhotos,
      OriginalPhotoRow,
      $OriginalPhotosFilterComposer,
      $OriginalPhotosOrderingComposer,
      $OriginalPhotosAnnotationComposer,
      $OriginalPhotosCreateCompanionBuilder,
      $OriginalPhotosUpdateCompanionBuilder,
      (OriginalPhotoRow, $OriginalPhotosReferences),
      OriginalPhotoRow,
      PrefetchHooks Function({bool sessionPhotosRefs})
    >;
typedef $PendingOriginalCommitsCreateCompanionBuilder =
    PendingOriginalCommitsCompanion Function({
      required String id,
      required String sha256,
      required int byteLength,
      required String metadata,
      required DateTime startedAt,
      Value<int> rowid,
    });
typedef $PendingOriginalCommitsUpdateCompanionBuilder =
    PendingOriginalCommitsCompanion Function({
      Value<String> id,
      Value<String> sha256,
      Value<int> byteLength,
      Value<String> metadata,
      Value<DateTime> startedAt,
      Value<int> rowid,
    });

class $PendingOriginalCommitsFilterComposer
    extends Composer<_$BoothDatabase, PendingOriginalCommits> {
  $PendingOriginalCommitsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $PendingOriginalCommitsOrderingComposer
    extends Composer<_$BoothDatabase, PendingOriginalCommits> {
  $PendingOriginalCommitsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PendingOriginalCommitsAnnotationComposer
    extends Composer<_$BoothDatabase, PendingOriginalCommits> {
  $PendingOriginalCommitsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $PendingOriginalCommitsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          PendingOriginalCommits,
          PendingOriginalCommitRow,
          $PendingOriginalCommitsFilterComposer,
          $PendingOriginalCommitsOrderingComposer,
          $PendingOriginalCommitsAnnotationComposer,
          $PendingOriginalCommitsCreateCompanionBuilder,
          $PendingOriginalCommitsUpdateCompanionBuilder,
          (
            PendingOriginalCommitRow,
            BaseReferences<
              _$BoothDatabase,
              PendingOriginalCommits,
              PendingOriginalCommitRow
            >,
          ),
          PendingOriginalCommitRow,
          PrefetchHooks Function()
        > {
  $PendingOriginalCommitsTableManager(
    _$BoothDatabase db,
    PendingOriginalCommits table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PendingOriginalCommitsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PendingOriginalCommitsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PendingOriginalCommitsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> byteLength = const Value.absent(),
                Value<String> metadata = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingOriginalCommitsCompanion(
                id: id,
                sha256: sha256,
                byteLength: byteLength,
                metadata: metadata,
                startedAt: startedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sha256,
                required int byteLength,
                required String metadata,
                required DateTime startedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingOriginalCommitsCompanion.insert(
                id: id,
                sha256: sha256,
                byteLength: byteLength,
                metadata: metadata,
                startedAt: startedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PendingOriginalCommits, PendingOriginalCommitRow>(
                    table,
                  ),
                  BaseReferences<
                    _$BoothDatabase,
                    PendingOriginalCommits,
                    PendingOriginalCommitRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PendingOriginalCommitsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      PendingOriginalCommits,
      PendingOriginalCommitRow,
      $PendingOriginalCommitsFilterComposer,
      $PendingOriginalCommitsOrderingComposer,
      $PendingOriginalCommitsAnnotationComposer,
      $PendingOriginalCommitsCreateCompanionBuilder,
      $PendingOriginalCommitsUpdateCompanionBuilder,
      (
        PendingOriginalCommitRow,
        BaseReferences<
          _$BoothDatabase,
          PendingOriginalCommits,
          PendingOriginalCommitRow
        >,
      ),
      PendingOriginalCommitRow,
      PrefetchHooks Function()
    >;
typedef $CaptureSessionsCreateCompanionBuilder =
    CaptureSessionsCompanion Function({
      required String id,
      required String eventId,
      required int sequence,
      required String templateRevisionId,
      required int plannedShots,
      required String planJson,
      required SessionStatus status,
      Value<SessionEndReason?> endReason,
      Value<int> renderAttempts,
      Value<String?> outputId,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });
typedef $CaptureSessionsUpdateCompanionBuilder =
    CaptureSessionsCompanion Function({
      Value<String> id,
      Value<String> eventId,
      Value<int> sequence,
      Value<String> templateRevisionId,
      Value<int> plannedShots,
      Value<String> planJson,
      Value<SessionStatus> status,
      Value<SessionEndReason?> endReason,
      Value<int> renderAttempts,
      Value<String?> outputId,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> endedAt,
      Value<int> rowid,
    });

final class $CaptureSessionsReferences
    extends
        BaseReferences<_$BoothDatabase, CaptureSessions, CaptureSessionRow> {
  $CaptureSessionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Events _eventIdTable(_$BoothDatabase db) =>
      db.events.createAlias('capture_sessions__event_id__events__id');

  $EventsProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $EventsTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static TemplateRevisions _templateRevisionIdTable(_$BoothDatabase db) =>
      db.templateRevisions.createAlias(
        'capture_sessions__template_revision_id__template_revisions__id',
      );

  $TemplateRevisionsProcessedTableManager get templateRevisionId {
    final $_column = $_itemColumn<String>('template_revision_id')!;

    final manager = $TemplateRevisionsTableManager(
      $_db,
      $_db.templateRevisions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateRevisionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<SessionPhotos, List<SessionPhotoRow>>
  _sessionPhotosRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionPhotos,
    aliasName: 'capture_sessions__id__session_photos__session_id',
  );

  $SessionPhotosProcessedTableManager get sessionPhotosRefs {
    final manager = $SessionPhotosTableManager(
      $_db,
      $_db.sessionPhotos,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<SessionOutputs, List<SessionOutputRow>>
  _sessionOutputsRefsTable(_$BoothDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionOutputs,
    aliasName: 'capture_sessions__id__session_outputs__session_id',
  );

  $SessionOutputsProcessedTableManager get sessionOutputsRefs {
    final manager = $SessionOutputsTableManager(
      $_db,
      $_db.sessionOutputs,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sessionOutputsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ExportBatchItems, List<ExportBatchItemRow>>
  _exportBatchItemsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exportBatchItems,
        aliasName: 'capture_sessions__id__export_batch_items__session_id',
      );

  $ExportBatchItemsProcessedTableManager get exportBatchItemsRefs {
    final manager = $ExportBatchItemsTableManager(
      $_db,
      $_db.exportBatchItems,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exportBatchItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<DeliveryIntents, List<DeliveryIntentRow>>
  _deliveryIntentsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.deliveryIntents,
        aliasName: 'capture_sessions__id__delivery_intents__session_id',
      );

  $DeliveryIntentsProcessedTableManager get deliveryIntentsRefs {
    final manager = $DeliveryIntentsTableManager(
      $_db,
      $_db.deliveryIntents,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _deliveryIntentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CaptureSessionsFilterComposer
    extends Composer<_$BoothDatabase, CaptureSessions> {
  $CaptureSessionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedShots => $composableBuilder(
    column: $table.plannedShots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionEndReason?, SessionEndReason, String>
  get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get renderAttempts => $composableBuilder(
    column: $table.renderAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  $EventsFilterComposer get eventId {
    final $EventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsFilterComposer get templateRevisionId {
    final $TemplateRevisionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsFilterComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sessionPhotosRefs(
    Expression<bool> Function($SessionPhotosFilterComposer f) f,
  ) {
    final $SessionPhotosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPhotos,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionPhotosFilterComposer(
            $db: $db,
            $table: $db.sessionPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionOutputsRefs(
    Expression<bool> Function($SessionOutputsFilterComposer f) f,
  ) {
    final $SessionOutputsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionOutputs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionOutputsFilterComposer(
            $db: $db,
            $table: $db.sessionOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exportBatchItemsRefs(
    Expression<bool> Function($ExportBatchItemsFilterComposer f) f,
  ) {
    final $ExportBatchItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportBatchItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchItemsFilterComposer(
            $db: $db,
            $table: $db.exportBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deliveryIntentsRefs(
    Expression<bool> Function($DeliveryIntentsFilterComposer f) f,
  ) {
    final $DeliveryIntentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryIntents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DeliveryIntentsFilterComposer(
            $db: $db,
            $table: $db.deliveryIntents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CaptureSessionsOrderingComposer
    extends Composer<_$BoothDatabase, CaptureSessions> {
  $CaptureSessionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedShots => $composableBuilder(
    column: $table.plannedShots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get renderAttempts => $composableBuilder(
    column: $table.renderAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $EventsOrderingComposer get eventId {
    final $EventsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsOrderingComposer get templateRevisionId {
    final $TemplateRevisionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsOrderingComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaptureSessionsAnnotationComposer
    extends Composer<_$BoothDatabase, CaptureSessions> {
  $CaptureSessionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get plannedShots => $composableBuilder(
    column: $table.plannedShots,
    builder: (column) => column,
  );

  GeneratedColumn<String> get planJson =>
      $composableBuilder(column: $table.planJson, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionEndReason?, String> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);

  GeneratedColumn<int> get renderAttempts => $composableBuilder(
    column: $table.renderAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outputId =>
      $composableBuilder(column: $table.outputId, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  $EventsAnnotationComposer get eventId {
    final $EventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $TemplateRevisionsAnnotationComposer get templateRevisionId {
    final $TemplateRevisionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateRevisionId,
      referencedTable: $db.templateRevisions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $TemplateRevisionsAnnotationComposer(
            $db: $db,
            $table: $db.templateRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sessionPhotosRefs<T extends Object>(
    Expression<T> Function($SessionPhotosAnnotationComposer a) f,
  ) {
    final $SessionPhotosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionPhotos,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionPhotosAnnotationComposer(
            $db: $db,
            $table: $db.sessionPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sessionOutputsRefs<T extends Object>(
    Expression<T> Function($SessionOutputsAnnotationComposer a) f,
  ) {
    final $SessionOutputsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionOutputs,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SessionOutputsAnnotationComposer(
            $db: $db,
            $table: $db.sessionOutputs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exportBatchItemsRefs<T extends Object>(
    Expression<T> Function($ExportBatchItemsAnnotationComposer a) f,
  ) {
    final $ExportBatchItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportBatchItems,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchItemsAnnotationComposer(
            $db: $db,
            $table: $db.exportBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> deliveryIntentsRefs<T extends Object>(
    Expression<T> Function($DeliveryIntentsAnnotationComposer a) f,
  ) {
    final $DeliveryIntentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deliveryIntents,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DeliveryIntentsAnnotationComposer(
            $db: $db,
            $table: $db.deliveryIntents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CaptureSessionsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          CaptureSessions,
          CaptureSessionRow,
          $CaptureSessionsFilterComposer,
          $CaptureSessionsOrderingComposer,
          $CaptureSessionsAnnotationComposer,
          $CaptureSessionsCreateCompanionBuilder,
          $CaptureSessionsUpdateCompanionBuilder,
          (CaptureSessionRow, $CaptureSessionsReferences),
          CaptureSessionRow,
          PrefetchHooks Function({
            bool eventId,
            bool templateRevisionId,
            bool sessionPhotosRefs,
            bool sessionOutputsRefs,
            bool exportBatchItemsRefs,
            bool deliveryIntentsRefs,
          })
        > {
  $CaptureSessionsTableManager(_$BoothDatabase db, CaptureSessions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CaptureSessionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CaptureSessionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CaptureSessionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> templateRevisionId = const Value.absent(),
                Value<int> plannedShots = const Value.absent(),
                Value<String> planJson = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<SessionEndReason?> endReason = const Value.absent(),
                Value<int> renderAttempts = const Value.absent(),
                Value<String?> outputId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaptureSessionsCompanion(
                id: id,
                eventId: eventId,
                sequence: sequence,
                templateRevisionId: templateRevisionId,
                plannedShots: plannedShots,
                planJson: planJson,
                status: status,
                endReason: endReason,
                renderAttempts: renderAttempts,
                outputId: outputId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String eventId,
                required int sequence,
                required String templateRevisionId,
                required int plannedShots,
                required String planJson,
                required SessionStatus status,
                Value<SessionEndReason?> endReason = const Value.absent(),
                Value<int> renderAttempts = const Value.absent(),
                Value<String?> outputId = const Value.absent(),
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaptureSessionsCompanion.insert(
                id: id,
                eventId: eventId,
                sequence: sequence,
                templateRevisionId: templateRevisionId,
                plannedShots: plannedShots,
                planJson: planJson,
                status: status,
                endReason: endReason,
                renderAttempts: renderAttempts,
                outputId: outputId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                endedAt: endedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CaptureSessions, CaptureSessionRow>(table),
                  $CaptureSessionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventId = false,
                templateRevisionId = false,
                sessionPhotosRefs = false,
                sessionOutputsRefs = false,
                exportBatchItemsRefs = false,
                deliveryIntentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sessionPhotosRefs) db.sessionPhotos,
                    if (sessionOutputsRefs) db.sessionOutputs,
                    if (exportBatchItemsRefs) db.exportBatchItems,
                    if (deliveryIntentsRefs) db.deliveryIntents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (eventId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.eventId,
                            referencedTable: $CaptureSessionsReferences
                                ._eventIdTable(db),
                            referencedColumn: $CaptureSessionsReferences
                                ._eventIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (templateRevisionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.templateRevisionId,
                            referencedTable: $CaptureSessionsReferences
                                ._templateRevisionIdTable(db),
                            referencedColumn: $CaptureSessionsReferences
                                ._templateRevisionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sessionPhotosRefs)
                        await $_getPrefetchedData<
                          CaptureSessionRow,
                          CaptureSessions,
                          SessionPhotoRow
                        >(
                          currentTable: table,
                          referencedTable: $CaptureSessionsReferences
                              ._sessionPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CaptureSessionsReferences(
                                db,
                                table,
                                p0,
                              ).sessionPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionOutputsRefs)
                        await $_getPrefetchedData<
                          CaptureSessionRow,
                          CaptureSessions,
                          SessionOutputRow
                        >(
                          currentTable: table,
                          referencedTable: $CaptureSessionsReferences
                              ._sessionOutputsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CaptureSessionsReferences(
                                db,
                                table,
                                p0,
                              ).sessionOutputsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (exportBatchItemsRefs)
                        await $_getPrefetchedData<
                          CaptureSessionRow,
                          CaptureSessions,
                          ExportBatchItemRow
                        >(
                          currentTable: table,
                          referencedTable: $CaptureSessionsReferences
                              ._exportBatchItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CaptureSessionsReferences(
                                db,
                                table,
                                p0,
                              ).exportBatchItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deliveryIntentsRefs)
                        await $_getPrefetchedData<
                          CaptureSessionRow,
                          CaptureSessions,
                          DeliveryIntentRow
                        >(
                          currentTable: table,
                          referencedTable: $CaptureSessionsReferences
                              ._deliveryIntentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CaptureSessionsReferences(
                                db,
                                table,
                                p0,
                              ).deliveryIntentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CaptureSessionsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      CaptureSessions,
      CaptureSessionRow,
      $CaptureSessionsFilterComposer,
      $CaptureSessionsOrderingComposer,
      $CaptureSessionsAnnotationComposer,
      $CaptureSessionsCreateCompanionBuilder,
      $CaptureSessionsUpdateCompanionBuilder,
      (CaptureSessionRow, $CaptureSessionsReferences),
      CaptureSessionRow,
      PrefetchHooks Function({
        bool eventId,
        bool templateRevisionId,
        bool sessionPhotosRefs,
        bool sessionOutputsRefs,
        bool exportBatchItemsRefs,
        bool deliveryIntentsRefs,
      })
    >;
typedef $SessionPhotosCreateCompanionBuilder = SessionPhotosCompanion Function({
  required String sessionId,
  required int shotIndex,
  required int attempt,
  required int round,
  required int slotIndex,
  required String originalId,
  required DateTime capturedAt,
  Value<int> rowid,
});
typedef $SessionPhotosUpdateCompanionBuilder = SessionPhotosCompanion Function({
  Value<String> sessionId,
  Value<int> shotIndex,
  Value<int> attempt,
  Value<int> round,
  Value<int> slotIndex,
  Value<String> originalId,
  Value<DateTime> capturedAt,
  Value<int> rowid,
});

final class $SessionPhotosReferences
    extends BaseReferences<_$BoothDatabase, SessionPhotos, SessionPhotoRow> {
  $SessionPhotosReferences(super.$_db, super.$_table, super.$_typedResult);

  static CaptureSessions _sessionIdTable(_$BoothDatabase db) => db
      .captureSessions
      .createAlias('session_photos__session_id__capture_sessions__id');

  $CaptureSessionsProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $CaptureSessionsTableManager(
      $_db,
      $_db.captureSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static OriginalPhotos _originalIdTable(_$BoothDatabase db) => db
      .originalPhotos
      .createAlias('session_photos__original_id__original_photos__id');

  $OriginalPhotosProcessedTableManager get originalId {
    final $_column = $_itemColumn<String>('original_id')!;

    final manager = $OriginalPhotosTableManager(
      $_db,
      $_db.originalPhotos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_originalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SessionPhotosFilterComposer
    extends Composer<_$BoothDatabase, SessionPhotos> {
  $SessionPhotosFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get shotIndex => $composableBuilder(
    column: $table.shotIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get slotIndex => $composableBuilder(
    column: $table.slotIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CaptureSessionsFilterComposer get sessionId {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $OriginalPhotosFilterComposer get originalId {
    final $OriginalPhotosFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalId,
      referencedTable: $db.originalPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OriginalPhotosFilterComposer(
            $db: $db,
            $table: $db.originalPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionPhotosOrderingComposer
    extends Composer<_$BoothDatabase, SessionPhotos> {
  $SessionPhotosOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get shotIndex => $composableBuilder(
    column: $table.shotIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get round => $composableBuilder(
    column: $table.round,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get slotIndex => $composableBuilder(
    column: $table.slotIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CaptureSessionsOrderingComposer get sessionId {
    final $CaptureSessionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsOrderingComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $OriginalPhotosOrderingComposer get originalId {
    final $OriginalPhotosOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalId,
      referencedTable: $db.originalPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OriginalPhotosOrderingComposer(
            $db: $db,
            $table: $db.originalPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionPhotosAnnotationComposer
    extends Composer<_$BoothDatabase, SessionPhotos> {
  $SessionPhotosAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get shotIndex =>
      $composableBuilder(column: $table.shotIndex, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<int> get round =>
      $composableBuilder(column: $table.round, builder: (column) => column);

  GeneratedColumn<int> get slotIndex =>
      $composableBuilder(column: $table.slotIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  $CaptureSessionsAnnotationComposer get sessionId {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $OriginalPhotosAnnotationComposer get originalId {
    final $OriginalPhotosAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.originalId,
      referencedTable: $db.originalPhotos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OriginalPhotosAnnotationComposer(
            $db: $db,
            $table: $db.originalPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionPhotosTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          SessionPhotos,
          SessionPhotoRow,
          $SessionPhotosFilterComposer,
          $SessionPhotosOrderingComposer,
          $SessionPhotosAnnotationComposer,
          $SessionPhotosCreateCompanionBuilder,
          $SessionPhotosUpdateCompanionBuilder,
          (SessionPhotoRow, $SessionPhotosReferences),
          SessionPhotoRow,
          PrefetchHooks Function({bool sessionId, bool originalId})
        > {
  $SessionPhotosTableManager(_$BoothDatabase db, SessionPhotos table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SessionPhotosFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SessionPhotosOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SessionPhotosAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> shotIndex = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<int> round = const Value.absent(),
                Value<int> slotIndex = const Value.absent(),
                Value<String> originalId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionPhotosCompanion(
                sessionId: sessionId,
                shotIndex: shotIndex,
                attempt: attempt,
                round: round,
                slotIndex: slotIndex,
                originalId: originalId,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int shotIndex,
                required int attempt,
                required int round,
                required int slotIndex,
                required String originalId,
                required DateTime capturedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionPhotosCompanion.insert(
                sessionId: sessionId,
                shotIndex: shotIndex,
                attempt: attempt,
                round: round,
                slotIndex: slotIndex,
                originalId: originalId,
                capturedAt: capturedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SessionPhotos, SessionPhotoRow>(table),
                  $SessionPhotosReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, originalId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $SessionPhotosReferences
                            ._sessionIdTable(db),
                        referencedColumn: $SessionPhotosReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (originalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.originalId,
                        referencedTable: $SessionPhotosReferences
                            ._originalIdTable(db),
                        referencedColumn: $SessionPhotosReferences
                            ._originalIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SessionPhotosProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      SessionPhotos,
      SessionPhotoRow,
      $SessionPhotosFilterComposer,
      $SessionPhotosOrderingComposer,
      $SessionPhotosAnnotationComposer,
      $SessionPhotosCreateCompanionBuilder,
      $SessionPhotosUpdateCompanionBuilder,
      (SessionPhotoRow, $SessionPhotosReferences),
      SessionPhotoRow,
      PrefetchHooks Function({bool sessionId, bool originalId})
    >;
typedef $SessionOutputsCreateCompanionBuilder =
    SessionOutputsCompanion Function({
      required String id,
      required String sessionId,
      required String relativePath,
      required String sha256,
      required int byteLength,
      required int widthPx,
      required int heightPx,
      required OutputFormat format,
      required int renderVersion,
      required DateTime createdAt,
      Value<SessionOutputOrigin> origin,
      Value<int> rowid,
    });
typedef $SessionOutputsUpdateCompanionBuilder =
    SessionOutputsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> relativePath,
      Value<String> sha256,
      Value<int> byteLength,
      Value<int> widthPx,
      Value<int> heightPx,
      Value<OutputFormat> format,
      Value<int> renderVersion,
      Value<DateTime> createdAt,
      Value<SessionOutputOrigin> origin,
      Value<int> rowid,
    });

final class $SessionOutputsReferences
    extends BaseReferences<_$BoothDatabase, SessionOutputs, SessionOutputRow> {
  $SessionOutputsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CaptureSessions _sessionIdTable(_$BoothDatabase db) => db
      .captureSessions
      .createAlias('session_outputs__session_id__capture_sessions__id');

  $CaptureSessionsProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $CaptureSessionsTableManager(
      $_db,
      $_db.captureSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SessionOutputsFilterComposer
    extends Composer<_$BoothDatabase, SessionOutputs> {
  $SessionOutputsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<OutputFormat, OutputFormat, String>
  get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get renderVersion => $composableBuilder(
    column: $table.renderVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SessionOutputOrigin,
    SessionOutputOrigin,
    String
  >
  get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $CaptureSessionsFilterComposer get sessionId {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionOutputsOrderingComposer
    extends Composer<_$BoothDatabase, SessionOutputs> {
  $SessionOutputsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get renderVersion => $composableBuilder(
    column: $table.renderVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  $CaptureSessionsOrderingComposer get sessionId {
    final $CaptureSessionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsOrderingComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionOutputsAnnotationComposer
    extends Composer<_$BoothDatabase, SessionOutputs> {
  $SessionOutputsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get byteLength => $composableBuilder(
    column: $table.byteLength,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widthPx =>
      $composableBuilder(column: $table.widthPx, builder: (column) => column);

  GeneratedColumn<int> get heightPx =>
      $composableBuilder(column: $table.heightPx, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OutputFormat, String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get renderVersion => $composableBuilder(
    column: $table.renderVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionOutputOrigin, String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  $CaptureSessionsAnnotationComposer get sessionId {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SessionOutputsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          SessionOutputs,
          SessionOutputRow,
          $SessionOutputsFilterComposer,
          $SessionOutputsOrderingComposer,
          $SessionOutputsAnnotationComposer,
          $SessionOutputsCreateCompanionBuilder,
          $SessionOutputsUpdateCompanionBuilder,
          (SessionOutputRow, $SessionOutputsReferences),
          SessionOutputRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $SessionOutputsTableManager(_$BoothDatabase db, SessionOutputs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SessionOutputsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SessionOutputsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SessionOutputsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> byteLength = const Value.absent(),
                Value<int> widthPx = const Value.absent(),
                Value<int> heightPx = const Value.absent(),
                Value<OutputFormat> format = const Value.absent(),
                Value<int> renderVersion = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<SessionOutputOrigin> origin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionOutputsCompanion(
                id: id,
                sessionId: sessionId,
                relativePath: relativePath,
                sha256: sha256,
                byteLength: byteLength,
                widthPx: widthPx,
                heightPx: heightPx,
                format: format,
                renderVersion: renderVersion,
                createdAt: createdAt,
                origin: origin,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String relativePath,
                required String sha256,
                required int byteLength,
                required int widthPx,
                required int heightPx,
                required OutputFormat format,
                required int renderVersion,
                required DateTime createdAt,
                Value<SessionOutputOrigin> origin = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionOutputsCompanion.insert(
                id: id,
                sessionId: sessionId,
                relativePath: relativePath,
                sha256: sha256,
                byteLength: byteLength,
                widthPx: widthPx,
                heightPx: heightPx,
                format: format,
                renderVersion: renderVersion,
                createdAt: createdAt,
                origin: origin,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SessionOutputs, SessionOutputRow>(table),
                  $SessionOutputsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $SessionOutputsReferences
                            ._sessionIdTable(db),
                        referencedColumn: $SessionOutputsReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $SessionOutputsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      SessionOutputs,
      SessionOutputRow,
      $SessionOutputsFilterComposer,
      $SessionOutputsOrderingComposer,
      $SessionOutputsAnnotationComposer,
      $SessionOutputsCreateCompanionBuilder,
      $SessionOutputsUpdateCompanionBuilder,
      (SessionOutputRow, $SessionOutputsReferences),
      SessionOutputRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $ExportBatchesCreateCompanionBuilder = ExportBatchesCompanion Function({
  required String id,
  required ShareOutcome outcome,
  Value<String?> destination,
  required int fileCount,
  required int failureCount,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $ExportBatchesUpdateCompanionBuilder = ExportBatchesCompanion Function({
  Value<String> id,
  Value<ShareOutcome> outcome,
  Value<String?> destination,
  Value<int> fileCount,
  Value<int> failureCount,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $ExportBatchesReferences
    extends BaseReferences<_$BoothDatabase, ExportBatches, ExportBatchRow> {
  $ExportBatchesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ExportBatchItems, List<ExportBatchItemRow>>
  _exportBatchItemsRefsTable(_$BoothDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.exportBatchItems,
        aliasName: 'export_batches__id__export_batch_items__batch_id',
      );

  $ExportBatchItemsProcessedTableManager get exportBatchItemsRefs {
    final manager = $ExportBatchItemsTableManager(
      $_db,
      $_db.exportBatchItems,
    ).filter((f) => f.batchId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _exportBatchItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ExportBatchesFilterComposer
    extends Composer<_$BoothDatabase, ExportBatches> {
  $ExportBatchesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ShareOutcome, ShareOutcome, String>
  get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> exportBatchItemsRefs(
    Expression<bool> Function($ExportBatchItemsFilterComposer f) f,
  ) {
    final $ExportBatchItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportBatchItems,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchItemsFilterComposer(
            $db: $db,
            $table: $db.exportBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExportBatchesOrderingComposer
    extends Composer<_$BoothDatabase, ExportBatches> {
  $ExportBatchesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileCount => $composableBuilder(
    column: $table.fileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ExportBatchesAnnotationComposer
    extends Composer<_$BoothDatabase, ExportBatches> {
  $ExportBatchesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ShareOutcome, String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileCount =>
      $composableBuilder(column: $table.fileCount, builder: (column) => column);

  GeneratedColumn<int> get failureCount => $composableBuilder(
    column: $table.failureCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> exportBatchItemsRefs<T extends Object>(
    Expression<T> Function($ExportBatchItemsAnnotationComposer a) f,
  ) {
    final $ExportBatchItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.exportBatchItems,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchItemsAnnotationComposer(
            $db: $db,
            $table: $db.exportBatchItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ExportBatchesTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          ExportBatches,
          ExportBatchRow,
          $ExportBatchesFilterComposer,
          $ExportBatchesOrderingComposer,
          $ExportBatchesAnnotationComposer,
          $ExportBatchesCreateCompanionBuilder,
          $ExportBatchesUpdateCompanionBuilder,
          (ExportBatchRow, $ExportBatchesReferences),
          ExportBatchRow,
          PrefetchHooks Function({bool exportBatchItemsRefs})
        > {
  $ExportBatchesTableManager(_$BoothDatabase db, ExportBatches table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExportBatchesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExportBatchesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExportBatchesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ShareOutcome> outcome = const Value.absent(),
                Value<String?> destination = const Value.absent(),
                Value<int> fileCount = const Value.absent(),
                Value<int> failureCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportBatchesCompanion(
                id: id,
                outcome: outcome,
                destination: destination,
                fileCount: fileCount,
                failureCount: failureCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required ShareOutcome outcome,
                Value<String?> destination = const Value.absent(),
                required int fileCount,
                required int failureCount,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ExportBatchesCompanion.insert(
                id: id,
                outcome: outcome,
                destination: destination,
                fileCount: fileCount,
                failureCount: failureCount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExportBatches, ExportBatchRow>(table),
                  $ExportBatchesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({exportBatchItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (exportBatchItemsRefs) db.exportBatchItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (exportBatchItemsRefs)
                    await $_getPrefetchedData<
                      ExportBatchRow,
                      ExportBatches,
                      ExportBatchItemRow
                    >(
                      currentTable: table,
                      referencedTable: $ExportBatchesReferences
                          ._exportBatchItemsRefsTable(db),
                      managerFromTypedResult: (p0) => $ExportBatchesReferences(
                        db,
                        table,
                        p0,
                      ).exportBatchItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.batchId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $ExportBatchesProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      ExportBatches,
      ExportBatchRow,
      $ExportBatchesFilterComposer,
      $ExportBatchesOrderingComposer,
      $ExportBatchesAnnotationComposer,
      $ExportBatchesCreateCompanionBuilder,
      $ExportBatchesUpdateCompanionBuilder,
      (ExportBatchRow, $ExportBatchesReferences),
      ExportBatchRow,
      PrefetchHooks Function({bool exportBatchItemsRefs})
    >;
typedef $ExportBatchItemsCreateCompanionBuilder =
    ExportBatchItemsCompanion Function({
      required String batchId,
      required String sessionId,
      required ExportFileKind kind,
      required String sourceId,
      required String fileName,
      Value<int> rowid,
    });
typedef $ExportBatchItemsUpdateCompanionBuilder =
    ExportBatchItemsCompanion Function({
      Value<String> batchId,
      Value<String> sessionId,
      Value<ExportFileKind> kind,
      Value<String> sourceId,
      Value<String> fileName,
      Value<int> rowid,
    });

final class $ExportBatchItemsReferences
    extends
        BaseReferences<_$BoothDatabase, ExportBatchItems, ExportBatchItemRow> {
  $ExportBatchItemsReferences(super.$_db, super.$_table, super.$_typedResult);

  static ExportBatches _batchIdTable(_$BoothDatabase db) => db.exportBatches
      .createAlias('export_batch_items__batch_id__export_batches__id');

  $ExportBatchesProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $ExportBatchesTableManager(
      $_db,
      $_db.exportBatches,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaptureSessions _sessionIdTable(_$BoothDatabase db) => db
      .captureSessions
      .createAlias('export_batch_items__session_id__capture_sessions__id');

  $CaptureSessionsProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $CaptureSessionsTableManager(
      $_db,
      $_db.captureSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ExportBatchItemsFilterComposer
    extends Composer<_$BoothDatabase, ExportBatchItems> {
  $ExportBatchItemsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ExportFileKind, ExportFileKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  $ExportBatchesFilterComposer get batchId {
    final $ExportBatchesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.exportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchesFilterComposer(
            $db: $db,
            $table: $db.exportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaptureSessionsFilterComposer get sessionId {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExportBatchItemsOrderingComposer
    extends Composer<_$BoothDatabase, ExportBatchItems> {
  $ExportBatchItemsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  $ExportBatchesOrderingComposer get batchId {
    final $ExportBatchesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.exportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchesOrderingComposer(
            $db: $db,
            $table: $db.exportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaptureSessionsOrderingComposer get sessionId {
    final $CaptureSessionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsOrderingComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExportBatchItemsAnnotationComposer
    extends Composer<_$BoothDatabase, ExportBatchItems> {
  $ExportBatchItemsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ExportFileKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  $ExportBatchesAnnotationComposer get batchId {
    final $ExportBatchesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.exportBatches,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ExportBatchesAnnotationComposer(
            $db: $db,
            $table: $db.exportBatches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaptureSessionsAnnotationComposer get sessionId {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ExportBatchItemsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          ExportBatchItems,
          ExportBatchItemRow,
          $ExportBatchItemsFilterComposer,
          $ExportBatchItemsOrderingComposer,
          $ExportBatchItemsAnnotationComposer,
          $ExportBatchItemsCreateCompanionBuilder,
          $ExportBatchItemsUpdateCompanionBuilder,
          (ExportBatchItemRow, $ExportBatchItemsReferences),
          ExportBatchItemRow,
          PrefetchHooks Function({bool batchId, bool sessionId})
        > {
  $ExportBatchItemsTableManager(_$BoothDatabase db, ExportBatchItems table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ExportBatchItemsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ExportBatchItemsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ExportBatchItemsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> batchId = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<ExportFileKind> kind = const Value.absent(),
                Value<String> sourceId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExportBatchItemsCompanion(
                batchId: batchId,
                sessionId: sessionId,
                kind: kind,
                sourceId: sourceId,
                fileName: fileName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String batchId,
                required String sessionId,
                required ExportFileKind kind,
                required String sourceId,
                required String fileName,
                Value<int> rowid = const Value.absent(),
              }) => ExportBatchItemsCompanion.insert(
                batchId: batchId,
                sessionId: sessionId,
                kind: kind,
                sourceId: sourceId,
                fileName: fileName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ExportBatchItems, ExportBatchItemRow>(table),
                  $ExportBatchItemsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.batchId,
                        referencedTable: $ExportBatchItemsReferences
                            ._batchIdTable(db),
                        referencedColumn: $ExportBatchItemsReferences
                            ._batchIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $ExportBatchItemsReferences
                            ._sessionIdTable(db),
                        referencedColumn: $ExportBatchItemsReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ExportBatchItemsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      ExportBatchItems,
      ExportBatchItemRow,
      $ExportBatchItemsFilterComposer,
      $ExportBatchItemsOrderingComposer,
      $ExportBatchItemsAnnotationComposer,
      $ExportBatchItemsCreateCompanionBuilder,
      $ExportBatchItemsUpdateCompanionBuilder,
      (ExportBatchItemRow, $ExportBatchItemsReferences),
      ExportBatchItemRow,
      PrefetchHooks Function({bool batchId, bool sessionId})
    >;
typedef $PendingFileDeletionsCreateCompanionBuilder =
    PendingFileDeletionsCompanion Function({
      required String relativePath,
      required DateTime queuedAt,
      Value<int> rowid,
    });
typedef $PendingFileDeletionsUpdateCompanionBuilder =
    PendingFileDeletionsCompanion Function({
      Value<String> relativePath,
      Value<DateTime> queuedAt,
      Value<int> rowid,
    });

class $PendingFileDeletionsFilterComposer
    extends Composer<_$BoothDatabase, PendingFileDeletions> {
  $PendingFileDeletionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $PendingFileDeletionsOrderingComposer
    extends Composer<_$BoothDatabase, PendingFileDeletions> {
  $PendingFileDeletionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get queuedAt => $composableBuilder(
    column: $table.queuedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PendingFileDeletionsAnnotationComposer
    extends Composer<_$BoothDatabase, PendingFileDeletions> {
  $PendingFileDeletionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get queuedAt =>
      $composableBuilder(column: $table.queuedAt, builder: (column) => column);
}

class $PendingFileDeletionsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          PendingFileDeletions,
          PendingFileDeletionRow,
          $PendingFileDeletionsFilterComposer,
          $PendingFileDeletionsOrderingComposer,
          $PendingFileDeletionsAnnotationComposer,
          $PendingFileDeletionsCreateCompanionBuilder,
          $PendingFileDeletionsUpdateCompanionBuilder,
          (
            PendingFileDeletionRow,
            BaseReferences<
              _$BoothDatabase,
              PendingFileDeletions,
              PendingFileDeletionRow
            >,
          ),
          PendingFileDeletionRow,
          PrefetchHooks Function()
        > {
  $PendingFileDeletionsTableManager(
    _$BoothDatabase db,
    PendingFileDeletions table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PendingFileDeletionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PendingFileDeletionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PendingFileDeletionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> relativePath = const Value.absent(),
                Value<DateTime> queuedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingFileDeletionsCompanion(
                relativePath: relativePath,
                queuedAt: queuedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String relativePath,
                required DateTime queuedAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingFileDeletionsCompanion.insert(
                relativePath: relativePath,
                queuedAt: queuedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PendingFileDeletions, PendingFileDeletionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$BoothDatabase,
                    PendingFileDeletions,
                    PendingFileDeletionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PendingFileDeletionsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      PendingFileDeletions,
      PendingFileDeletionRow,
      $PendingFileDeletionsFilterComposer,
      $PendingFileDeletionsOrderingComposer,
      $PendingFileDeletionsAnnotationComposer,
      $PendingFileDeletionsCreateCompanionBuilder,
      $PendingFileDeletionsUpdateCompanionBuilder,
      (
        PendingFileDeletionRow,
        BaseReferences<
          _$BoothDatabase,
          PendingFileDeletions,
          PendingFileDeletionRow
        >,
      ),
      PendingFileDeletionRow,
      PrefetchHooks Function()
    >;
typedef $EventDeliveryOptionsCreateCompanionBuilder =
    EventDeliveryOptionsCompanion Function({
      required String eventId,
      required bool enabled,
      required bool offlineQueue,
      required int linkDays,
      required int sendLimit,
      Value<int> rowid,
    });
typedef $EventDeliveryOptionsUpdateCompanionBuilder =
    EventDeliveryOptionsCompanion Function({
      Value<String> eventId,
      Value<bool> enabled,
      Value<bool> offlineQueue,
      Value<int> linkDays,
      Value<int> sendLimit,
      Value<int> rowid,
    });

final class $EventDeliveryOptionsReferences
    extends
        BaseReferences<
          _$BoothDatabase,
          EventDeliveryOptions,
          EventDeliverySettingsRow
        > {
  $EventDeliveryOptionsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static Events _eventIdTable(_$BoothDatabase db) =>
      db.events.createAlias('event_delivery_options__event_id__events__id');

  $EventsProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $EventsTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $EventDeliveryOptionsFilterComposer
    extends Composer<_$BoothDatabase, EventDeliveryOptions> {
  $EventDeliveryOptionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get offlineQueue => $composableBuilder(
    column: $table.offlineQueue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkDays => $composableBuilder(
    column: $table.linkDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendLimit => $composableBuilder(
    column: $table.sendLimit,
    builder: (column) => ColumnFilters(column),
  );

  $EventsFilterComposer get eventId {
    final $EventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventDeliveryOptionsOrderingComposer
    extends Composer<_$BoothDatabase, EventDeliveryOptions> {
  $EventDeliveryOptionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get offlineQueue => $composableBuilder(
    column: $table.offlineQueue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkDays => $composableBuilder(
    column: $table.linkDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendLimit => $composableBuilder(
    column: $table.sendLimit,
    builder: (column) => ColumnOrderings(column),
  );

  $EventsOrderingComposer get eventId {
    final $EventsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventDeliveryOptionsAnnotationComposer
    extends Composer<_$BoothDatabase, EventDeliveryOptions> {
  $EventDeliveryOptionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get offlineQueue => $composableBuilder(
    column: $table.offlineQueue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linkDays =>
      $composableBuilder(column: $table.linkDays, builder: (column) => column);

  GeneratedColumn<int> get sendLimit =>
      $composableBuilder(column: $table.sendLimit, builder: (column) => column);

  $EventsAnnotationComposer get eventId {
    final $EventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $EventsAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $EventDeliveryOptionsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          EventDeliveryOptions,
          EventDeliverySettingsRow,
          $EventDeliveryOptionsFilterComposer,
          $EventDeliveryOptionsOrderingComposer,
          $EventDeliveryOptionsAnnotationComposer,
          $EventDeliveryOptionsCreateCompanionBuilder,
          $EventDeliveryOptionsUpdateCompanionBuilder,
          (EventDeliverySettingsRow, $EventDeliveryOptionsReferences),
          EventDeliverySettingsRow,
          PrefetchHooks Function({bool eventId})
        > {
  $EventDeliveryOptionsTableManager(
    _$BoothDatabase db,
    EventDeliveryOptions table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $EventDeliveryOptionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $EventDeliveryOptionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $EventDeliveryOptionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> offlineQueue = const Value.absent(),
                Value<int> linkDays = const Value.absent(),
                Value<int> sendLimit = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventDeliveryOptionsCompanion(
                eventId: eventId,
                enabled: enabled,
                offlineQueue: offlineQueue,
                linkDays: linkDays,
                sendLimit: sendLimit,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required bool enabled,
                required bool offlineQueue,
                required int linkDays,
                required int sendLimit,
                Value<int> rowid = const Value.absent(),
              }) => EventDeliveryOptionsCompanion.insert(
                eventId: eventId,
                enabled: enabled,
                offlineQueue: offlineQueue,
                linkDays: linkDays,
                sendLimit: sendLimit,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<EventDeliveryOptions, EventDeliverySettingsRow>(
                    table,
                  ),
                  $EventDeliveryOptionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.eventId,
                        referencedTable: $EventDeliveryOptionsReferences
                            ._eventIdTable(db),
                        referencedColumn: $EventDeliveryOptionsReferences
                            ._eventIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $EventDeliveryOptionsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      EventDeliveryOptions,
      EventDeliverySettingsRow,
      $EventDeliveryOptionsFilterComposer,
      $EventDeliveryOptionsOrderingComposer,
      $EventDeliveryOptionsAnnotationComposer,
      $EventDeliveryOptionsCreateCompanionBuilder,
      $EventDeliveryOptionsUpdateCompanionBuilder,
      (EventDeliverySettingsRow, $EventDeliveryOptionsReferences),
      EventDeliverySettingsRow,
      PrefetchHooks Function({bool eventId})
    >;
typedef $DeliveryPairingsCreateCompanionBuilder =
    DeliveryPairingsCompanion Function({
      Value<int> id,
      required String baseUrl,
      required String boothId,
      required String boothName,
      required String brandName,
      required DateTime pairedAt,
      Value<bool> paused,
      Value<String?> capabilitiesJson,
      Value<DateTime?> checkedAt,
    });
typedef $DeliveryPairingsUpdateCompanionBuilder =
    DeliveryPairingsCompanion Function({
      Value<int> id,
      Value<String> baseUrl,
      Value<String> boothId,
      Value<String> boothName,
      Value<String> brandName,
      Value<DateTime> pairedAt,
      Value<bool> paused,
      Value<String?> capabilitiesJson,
      Value<DateTime?> checkedAt,
    });

class $DeliveryPairingsFilterComposer
    extends Composer<_$BoothDatabase, DeliveryPairings> {
  $DeliveryPairingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boothId => $composableBuilder(
    column: $table.boothId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boothName => $composableBuilder(
    column: $table.boothName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $DeliveryPairingsOrderingComposer
    extends Composer<_$BoothDatabase, DeliveryPairings> {
  $DeliveryPairingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUrl => $composableBuilder(
    column: $table.baseUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boothId => $composableBuilder(
    column: $table.boothId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boothName => $composableBuilder(
    column: $table.boothName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brandName => $composableBuilder(
    column: $table.brandName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DeliveryPairingsAnnotationComposer
    extends Composer<_$BoothDatabase, DeliveryPairings> {
  $DeliveryPairingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseUrl =>
      $composableBuilder(column: $table.baseUrl, builder: (column) => column);

  GeneratedColumn<String> get boothId =>
      $composableBuilder(column: $table.boothId, builder: (column) => column);

  GeneratedColumn<String> get boothName =>
      $composableBuilder(column: $table.boothName, builder: (column) => column);

  GeneratedColumn<String> get brandName =>
      $composableBuilder(column: $table.brandName, builder: (column) => column);

  GeneratedColumn<DateTime> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<String> get capabilitiesJson => $composableBuilder(
    column: $table.capabilitiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);
}

class $DeliveryPairingsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          DeliveryPairings,
          DeliveryPairingRow,
          $DeliveryPairingsFilterComposer,
          $DeliveryPairingsOrderingComposer,
          $DeliveryPairingsAnnotationComposer,
          $DeliveryPairingsCreateCompanionBuilder,
          $DeliveryPairingsUpdateCompanionBuilder,
          (
            DeliveryPairingRow,
            BaseReferences<
              _$BoothDatabase,
              DeliveryPairings,
              DeliveryPairingRow
            >,
          ),
          DeliveryPairingRow,
          PrefetchHooks Function()
        > {
  $DeliveryPairingsTableManager(_$BoothDatabase db, DeliveryPairings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeliveryPairingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeliveryPairingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DeliveryPairingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> baseUrl = const Value.absent(),
                Value<String> boothId = const Value.absent(),
                Value<String> boothName = const Value.absent(),
                Value<String> brandName = const Value.absent(),
                Value<DateTime> pairedAt = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<String?> capabilitiesJson = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
              }) => DeliveryPairingsCompanion(
                id: id,
                baseUrl: baseUrl,
                boothId: boothId,
                boothName: boothName,
                brandName: brandName,
                pairedAt: pairedAt,
                paused: paused,
                capabilitiesJson: capabilitiesJson,
                checkedAt: checkedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String baseUrl,
                required String boothId,
                required String boothName,
                required String brandName,
                required DateTime pairedAt,
                Value<bool> paused = const Value.absent(),
                Value<String?> capabilitiesJson = const Value.absent(),
                Value<DateTime?> checkedAt = const Value.absent(),
              }) => DeliveryPairingsCompanion.insert(
                id: id,
                baseUrl: baseUrl,
                boothId: boothId,
                boothName: boothName,
                brandName: brandName,
                pairedAt: pairedAt,
                paused: paused,
                capabilitiesJson: capabilitiesJson,
                checkedAt: checkedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DeliveryPairings, DeliveryPairingRow>(table),
                  BaseReferences<
                    _$BoothDatabase,
                    DeliveryPairings,
                    DeliveryPairingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeliveryPairingsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      DeliveryPairings,
      DeliveryPairingRow,
      $DeliveryPairingsFilterComposer,
      $DeliveryPairingsOrderingComposer,
      $DeliveryPairingsAnnotationComposer,
      $DeliveryPairingsCreateCompanionBuilder,
      $DeliveryPairingsUpdateCompanionBuilder,
      (
        DeliveryPairingRow,
        BaseReferences<_$BoothDatabase, DeliveryPairings, DeliveryPairingRow>,
      ),
      DeliveryPairingRow,
      PrefetchHooks Function()
    >;
typedef $DeliveryIntentsCreateCompanionBuilder =
    DeliveryIntentsCompanion Function({
      required String id,
      required String sessionId,
      required String eventId,
      required String outputId,
      required String phoneLast4,
      required bool phoneStored,
      required String consentTextVersion,
      required String consentTextDigest,
      required DateTime consentAcceptedAt,
      required String locale,
      required int linkDays,
      required int sendLimit,
      required bool queueAllowed,
      required String idempotencyKey,
      required DeliveryIntentState state,
      Value<DeliveryPhase?> localOutcome,
      Value<String?> remoteJobId,
      Value<String?> remoteStatus,
      Value<DateTime?> remoteUpdatedAt,
      Value<String?> lastErrorCode,
      Value<int> attemptCount,
      Value<DateTime?> retryAt,
      required DateTime expiresAt,
      Value<String> historyJson,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $DeliveryIntentsUpdateCompanionBuilder =
    DeliveryIntentsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> eventId,
      Value<String> outputId,
      Value<String> phoneLast4,
      Value<bool> phoneStored,
      Value<String> consentTextVersion,
      Value<String> consentTextDigest,
      Value<DateTime> consentAcceptedAt,
      Value<String> locale,
      Value<int> linkDays,
      Value<int> sendLimit,
      Value<bool> queueAllowed,
      Value<String> idempotencyKey,
      Value<DeliveryIntentState> state,
      Value<DeliveryPhase?> localOutcome,
      Value<String?> remoteJobId,
      Value<String?> remoteStatus,
      Value<DateTime?> remoteUpdatedAt,
      Value<String?> lastErrorCode,
      Value<int> attemptCount,
      Value<DateTime?> retryAt,
      Value<DateTime> expiresAt,
      Value<String> historyJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $DeliveryIntentsReferences
    extends
        BaseReferences<_$BoothDatabase, DeliveryIntents, DeliveryIntentRow> {
  $DeliveryIntentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CaptureSessions _sessionIdTable(_$BoothDatabase db) => db
      .captureSessions
      .createAlias('delivery_intents__session_id__capture_sessions__id');

  $CaptureSessionsProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $CaptureSessionsTableManager(
      $_db,
      $_db.captureSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DeliveryIntentsFilterComposer
    extends Composer<_$BoothDatabase, DeliveryIntents> {
  $DeliveryIntentsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneLast4 => $composableBuilder(
    column: $table.phoneLast4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get phoneStored => $composableBuilder(
    column: $table.phoneStored,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentTextVersion => $composableBuilder(
    column: $table.consentTextVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentTextDigest => $composableBuilder(
    column: $table.consentTextDigest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linkDays => $composableBuilder(
    column: $table.linkDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendLimit => $composableBuilder(
    column: $table.sendLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get queueAllowed => $composableBuilder(
    column: $table.queueAllowed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    DeliveryIntentState,
    DeliveryIntentState,
    String
  >
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DeliveryPhase?, DeliveryPhase, String>
  get localOutcome => $composableBuilder(
    column: $table.localOutcome,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteStatus => $composableBuilder(
    column: $table.remoteStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CaptureSessionsFilterComposer get sessionId {
    final $CaptureSessionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsFilterComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DeliveryIntentsOrderingComposer
    extends Composer<_$BoothDatabase, DeliveryIntents> {
  $DeliveryIntentsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputId => $composableBuilder(
    column: $table.outputId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneLast4 => $composableBuilder(
    column: $table.phoneLast4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get phoneStored => $composableBuilder(
    column: $table.phoneStored,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentTextVersion => $composableBuilder(
    column: $table.consentTextVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentTextDigest => $composableBuilder(
    column: $table.consentTextDigest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linkDays => $composableBuilder(
    column: $table.linkDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendLimit => $composableBuilder(
    column: $table.sendLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get queueAllowed => $composableBuilder(
    column: $table.queueAllowed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localOutcome => $composableBuilder(
    column: $table.localOutcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteStatus => $composableBuilder(
    column: $table.remoteStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get retryAt => $composableBuilder(
    column: $table.retryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CaptureSessionsOrderingComposer get sessionId {
    final $CaptureSessionsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsOrderingComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DeliveryIntentsAnnotationComposer
    extends Composer<_$BoothDatabase, DeliveryIntents> {
  $DeliveryIntentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get outputId =>
      $composableBuilder(column: $table.outputId, builder: (column) => column);

  GeneratedColumn<String> get phoneLast4 => $composableBuilder(
    column: $table.phoneLast4,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get phoneStored => $composableBuilder(
    column: $table.phoneStored,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentTextVersion => $composableBuilder(
    column: $table.consentTextVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentTextDigest => $composableBuilder(
    column: $table.consentTextDigest,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get consentAcceptedAt => $composableBuilder(
    column: $table.consentAcceptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<int> get linkDays =>
      $composableBuilder(column: $table.linkDays, builder: (column) => column);

  GeneratedColumn<int> get sendLimit =>
      $composableBuilder(column: $table.sendLimit, builder: (column) => column);

  GeneratedColumn<bool> get queueAllowed => $composableBuilder(
    column: $table.queueAllowed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DeliveryIntentState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeliveryPhase?, String> get localOutcome =>
      $composableBuilder(
        column: $table.localOutcome,
        builder: (column) => column,
      );

  GeneratedColumn<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteStatus => $composableBuilder(
    column: $table.remoteStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get retryAt =>
      $composableBuilder(column: $table.retryAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get historyJson => $composableBuilder(
    column: $table.historyJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $CaptureSessionsAnnotationComposer get sessionId {
    final $CaptureSessionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.captureSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaptureSessionsAnnotationComposer(
            $db: $db,
            $table: $db.captureSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DeliveryIntentsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          DeliveryIntents,
          DeliveryIntentRow,
          $DeliveryIntentsFilterComposer,
          $DeliveryIntentsOrderingComposer,
          $DeliveryIntentsAnnotationComposer,
          $DeliveryIntentsCreateCompanionBuilder,
          $DeliveryIntentsUpdateCompanionBuilder,
          (DeliveryIntentRow, $DeliveryIntentsReferences),
          DeliveryIntentRow,
          PrefetchHooks Function({bool sessionId})
        > {
  $DeliveryIntentsTableManager(_$BoothDatabase db, DeliveryIntents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeliveryIntentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeliveryIntentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DeliveryIntentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> outputId = const Value.absent(),
                Value<String> phoneLast4 = const Value.absent(),
                Value<bool> phoneStored = const Value.absent(),
                Value<String> consentTextVersion = const Value.absent(),
                Value<String> consentTextDigest = const Value.absent(),
                Value<DateTime> consentAcceptedAt = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> linkDays = const Value.absent(),
                Value<int> sendLimit = const Value.absent(),
                Value<bool> queueAllowed = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<DeliveryIntentState> state = const Value.absent(),
                Value<DeliveryPhase?> localOutcome = const Value.absent(),
                Value<String?> remoteJobId = const Value.absent(),
                Value<String?> remoteStatus = const Value.absent(),
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> retryAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<String> historyJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryIntentsCompanion(
                id: id,
                sessionId: sessionId,
                eventId: eventId,
                outputId: outputId,
                phoneLast4: phoneLast4,
                phoneStored: phoneStored,
                consentTextVersion: consentTextVersion,
                consentTextDigest: consentTextDigest,
                consentAcceptedAt: consentAcceptedAt,
                locale: locale,
                linkDays: linkDays,
                sendLimit: sendLimit,
                queueAllowed: queueAllowed,
                idempotencyKey: idempotencyKey,
                state: state,
                localOutcome: localOutcome,
                remoteJobId: remoteJobId,
                remoteStatus: remoteStatus,
                remoteUpdatedAt: remoteUpdatedAt,
                lastErrorCode: lastErrorCode,
                attemptCount: attemptCount,
                retryAt: retryAt,
                expiresAt: expiresAt,
                historyJson: historyJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String eventId,
                required String outputId,
                required String phoneLast4,
                required bool phoneStored,
                required String consentTextVersion,
                required String consentTextDigest,
                required DateTime consentAcceptedAt,
                required String locale,
                required int linkDays,
                required int sendLimit,
                required bool queueAllowed,
                required String idempotencyKey,
                required DeliveryIntentState state,
                Value<DeliveryPhase?> localOutcome = const Value.absent(),
                Value<String?> remoteJobId = const Value.absent(),
                Value<String?> remoteStatus = const Value.absent(),
                Value<DateTime?> remoteUpdatedAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> retryAt = const Value.absent(),
                required DateTime expiresAt,
                Value<String> historyJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeliveryIntentsCompanion.insert(
                id: id,
                sessionId: sessionId,
                eventId: eventId,
                outputId: outputId,
                phoneLast4: phoneLast4,
                phoneStored: phoneStored,
                consentTextVersion: consentTextVersion,
                consentTextDigest: consentTextDigest,
                consentAcceptedAt: consentAcceptedAt,
                locale: locale,
                linkDays: linkDays,
                sendLimit: sendLimit,
                queueAllowed: queueAllowed,
                idempotencyKey: idempotencyKey,
                state: state,
                localOutcome: localOutcome,
                remoteJobId: remoteJobId,
                remoteStatus: remoteStatus,
                remoteUpdatedAt: remoteUpdatedAt,
                lastErrorCode: lastErrorCode,
                attemptCount: attemptCount,
                retryAt: retryAt,
                expiresAt: expiresAt,
                historyJson: historyJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<DeliveryIntents, DeliveryIntentRow>(table),
                  $DeliveryIntentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $DeliveryIntentsReferences
                            ._sessionIdTable(db),
                        referencedColumn: $DeliveryIntentsReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $DeliveryIntentsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      DeliveryIntents,
      DeliveryIntentRow,
      $DeliveryIntentsFilterComposer,
      $DeliveryIntentsOrderingComposer,
      $DeliveryIntentsAnnotationComposer,
      $DeliveryIntentsCreateCompanionBuilder,
      $DeliveryIntentsUpdateCompanionBuilder,
      (DeliveryIntentRow, $DeliveryIntentsReferences),
      DeliveryIntentRow,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $DeliveryRemoteRevocationsCreateCompanionBuilder =
    DeliveryRemoteRevocationsCompanion Function({
      required String remoteJobId,
      required DateTime requestedAt,
      Value<int> rowid,
    });
typedef $DeliveryRemoteRevocationsUpdateCompanionBuilder =
    DeliveryRemoteRevocationsCompanion Function({
      Value<String> remoteJobId,
      Value<DateTime> requestedAt,
      Value<int> rowid,
    });

class $DeliveryRemoteRevocationsFilterComposer
    extends Composer<_$BoothDatabase, DeliveryRemoteRevocations> {
  $DeliveryRemoteRevocationsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $DeliveryRemoteRevocationsOrderingComposer
    extends Composer<_$BoothDatabase, DeliveryRemoteRevocations> {
  $DeliveryRemoteRevocationsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $DeliveryRemoteRevocationsAnnotationComposer
    extends Composer<_$BoothDatabase, DeliveryRemoteRevocations> {
  $DeliveryRemoteRevocationsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get remoteJobId => $composableBuilder(
    column: $table.remoteJobId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get requestedAt => $composableBuilder(
    column: $table.requestedAt,
    builder: (column) => column,
  );
}

class $DeliveryRemoteRevocationsTableManager
    extends
        RootTableManager<
          _$BoothDatabase,
          DeliveryRemoteRevocations,
          DeliveryRemoteRevocationRow,
          $DeliveryRemoteRevocationsFilterComposer,
          $DeliveryRemoteRevocationsOrderingComposer,
          $DeliveryRemoteRevocationsAnnotationComposer,
          $DeliveryRemoteRevocationsCreateCompanionBuilder,
          $DeliveryRemoteRevocationsUpdateCompanionBuilder,
          (
            DeliveryRemoteRevocationRow,
            BaseReferences<
              _$BoothDatabase,
              DeliveryRemoteRevocations,
              DeliveryRemoteRevocationRow
            >,
          ),
          DeliveryRemoteRevocationRow,
          PrefetchHooks Function()
        > {
  $DeliveryRemoteRevocationsTableManager(
    _$BoothDatabase db,
    DeliveryRemoteRevocations table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DeliveryRemoteRevocationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DeliveryRemoteRevocationsOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $DeliveryRemoteRevocationsAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> remoteJobId = const Value.absent(),
                Value<DateTime> requestedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeliveryRemoteRevocationsCompanion(
                remoteJobId: remoteJobId,
                requestedAt: requestedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String remoteJobId,
                required DateTime requestedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeliveryRemoteRevocationsCompanion.insert(
                remoteJobId: remoteJobId,
                requestedAt: requestedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    DeliveryRemoteRevocations,
                    DeliveryRemoteRevocationRow
                  >(table),
                  BaseReferences<
                    _$BoothDatabase,
                    DeliveryRemoteRevocations,
                    DeliveryRemoteRevocationRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $DeliveryRemoteRevocationsProcessedTableManager =
    ProcessedTableManager<
      _$BoothDatabase,
      DeliveryRemoteRevocations,
      DeliveryRemoteRevocationRow,
      $DeliveryRemoteRevocationsFilterComposer,
      $DeliveryRemoteRevocationsOrderingComposer,
      $DeliveryRemoteRevocationsAnnotationComposer,
      $DeliveryRemoteRevocationsCreateCompanionBuilder,
      $DeliveryRemoteRevocationsUpdateCompanionBuilder,
      (
        DeliveryRemoteRevocationRow,
        BaseReferences<
          _$BoothDatabase,
          DeliveryRemoteRevocations,
          DeliveryRemoteRevocationRow
        >,
      ),
      DeliveryRemoteRevocationRow,
      PrefetchHooks Function()
    >;

class $BoothDatabaseManager {
  final _$BoothDatabase _db;
  $BoothDatabaseManager(this._db);
  $BoothProfilesTableManager get boothProfiles =>
      $BoothProfilesTableManager(_db, _db.boothProfiles);
  $EventsTableManager get events => $EventsTableManager(_db, _db.events);
  $AppSettingsTableManager get appSettings =>
      $AppSettingsTableManager(_db, _db.appSettings);
  $OperatorAccessTableManager get operatorAccess =>
      $OperatorAccessTableManager(_db, _db.operatorAccess);
  $TemplatesTableManager get templates =>
      $TemplatesTableManager(_db, _db.templates);
  $TemplateRevisionsTableManager get templateRevisions =>
      $TemplateRevisionsTableManager(_db, _db.templateRevisions);
  $AssetsTableManager get assets => $AssetsTableManager(_db, _db.assets);
  $TemplateRevisionAssetsTableManager get templateRevisionAssets =>
      $TemplateRevisionAssetsTableManager(_db, _db.templateRevisionAssets);
  $TemplateDraftsTableManager get templateDrafts =>
      $TemplateDraftsTableManager(_db, _db.templateDrafts);
  $EventTemplatesTableManager get eventTemplates =>
      $EventTemplatesTableManager(_db, _db.eventTemplates);
  $OriginalPhotosTableManager get originalPhotos =>
      $OriginalPhotosTableManager(_db, _db.originalPhotos);
  $PendingOriginalCommitsTableManager get pendingOriginalCommits =>
      $PendingOriginalCommitsTableManager(_db, _db.pendingOriginalCommits);
  $CaptureSessionsTableManager get captureSessions =>
      $CaptureSessionsTableManager(_db, _db.captureSessions);
  $SessionPhotosTableManager get sessionPhotos =>
      $SessionPhotosTableManager(_db, _db.sessionPhotos);
  $SessionOutputsTableManager get sessionOutputs =>
      $SessionOutputsTableManager(_db, _db.sessionOutputs);
  $ExportBatchesTableManager get exportBatches =>
      $ExportBatchesTableManager(_db, _db.exportBatches);
  $ExportBatchItemsTableManager get exportBatchItems =>
      $ExportBatchItemsTableManager(_db, _db.exportBatchItems);
  $PendingFileDeletionsTableManager get pendingFileDeletions =>
      $PendingFileDeletionsTableManager(_db, _db.pendingFileDeletions);
  $EventDeliveryOptionsTableManager get eventDeliveryOptions =>
      $EventDeliveryOptionsTableManager(_db, _db.eventDeliveryOptions);
  $DeliveryPairingsTableManager get deliveryPairings =>
      $DeliveryPairingsTableManager(_db, _db.deliveryPairings);
  $DeliveryIntentsTableManager get deliveryIntents =>
      $DeliveryIntentsTableManager(_db, _db.deliveryIntents);
  $DeliveryRemoteRevocationsTableManager get deliveryRemoteRevocations =>
      $DeliveryRemoteRevocationsTableManager(
        _db,
        _db.deliveryRemoteRevocations,
      );
}
