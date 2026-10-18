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
  late final GeneratedColumnWithTypeConverter<AssetOrigin, String> origin =
      GeneratedColumn<String>(
        'origin',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (origin IN (\'imported\', \'package\'))',
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
  late final Trigger assetsAreImmutable = Trigger(
    'CREATE TRIGGER assets_are_immutable BEFORE UPDATE ON assets BEGIN SELECT RAISE (ABORT, \'assets are immutable\');END',
    'assets_are_immutable',
  );
  late final TemplateRevisionAssets templateRevisionAssets =
      TemplateRevisionAssets(this);
  late final Index templateRevisionAssetsByAsset = Index(
    'template_revision_assets_by_asset',
    'CREATE INDEX template_revision_assets_by_asset ON template_revision_assets (asset_id)',
  );
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
    assetsAreImmutable,
    templateRevisionAssets,
    templateRevisionAssetsByAsset,
    eventsByStatus,
    eventTemplates,
    eventTemplatesOneDefault,
    eventTemplatesByRevision,
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
        'events',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('event_templates', kind: UpdateKind.delete)],
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appSettingsRefs) db.appSettings,
                    if (eventTemplatesRefs) db.eventTemplates,
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
          PrefetchHooks Function({bool templateRevisionsRefs})
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
          prefetchHooksCallback: ({templateRevisionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateRevisionsRefs) db.templateRevisions,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
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
      PrefetchHooks Function({bool templateRevisionsRefs})
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
            bool eventTemplatesRefs,
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
                eventTemplatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateRevisionAssetsRefs) db.templateRevisionAssets,
                    if (eventTemplatesRefs) db.eventTemplates,
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
        bool eventTemplatesRefs,
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
  $EventTemplatesTableManager get eventTemplates =>
      $EventTemplatesTableManager(_db, _db.eventTemplates);
}
