// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppNotificationCollection on Isar {
  IsarCollection<AppNotification> get appNotifications => this.collection();
}

const AppNotificationSchema = CollectionSchema(
  name: r'AppNotification',
  id: 7576332975032865864,
  properties: {
    r'body': PropertySchema(id: 0, name: r'body', type: IsarType.string),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'intakeId': PropertySchema(id: 2, name: r'intakeId', type: IsarType.long),
    r'medicationId': PropertySchema(
      id: 3,
      name: r'medicationId',
      type: IsarType.long,
    ),
    r'needsSync': PropertySchema(
      id: 4,
      name: r'needsSync',
      type: IsarType.bool,
    ),
    r'pushSentAt': PropertySchema(
      id: 5,
      name: r'pushSentAt',
      type: IsarType.dateTime,
    ),
    r'pushStatus': PropertySchema(
      id: 6,
      name: r'pushStatus',
      type: IsarType.byte,
      enumMap: _AppNotificationpushStatusEnumValueMap,
    ),
    r'readAt': PropertySchema(id: 7, name: r'readAt', type: IsarType.dateTime),
    r'remoteId': PropertySchema(
      id: 8,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'title': PropertySchema(id: 9, name: r'title', type: IsarType.string),
    r'type': PropertySchema(
      id: 10,
      name: r'type',
      type: IsarType.byte,
      enumMap: _AppNotificationtypeEnumValueMap,
    ),
  },

  estimateSize: _appNotificationEstimateSize,
  serialize: _appNotificationSerialize,
  deserialize: _appNotificationDeserialize,
  deserializeProp: _appNotificationDeserializeProp,
  idName: r'id',
  indexes: {
    r'remoteId': IndexSchema(
      id: 6301175856541681032,
      name: r'remoteId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'remoteId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'medicationId': IndexSchema(
      id: -3054361819135306882,
      name: r'medicationId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'medicationId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'intakeId': IndexSchema(
      id: 8049441451066735704,
      name: r'intakeId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'intakeId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _appNotificationGetId,
  getLinks: _appNotificationGetLinks,
  attach: _appNotificationAttach,
  version: '3.3.0',
);

int _appNotificationEstimateSize(
  AppNotification object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.body;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.title;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appNotificationSerialize(
  AppNotification object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.body);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.intakeId);
  writer.writeLong(offsets[3], object.medicationId);
  writer.writeBool(offsets[4], object.needsSync);
  writer.writeDateTime(offsets[5], object.pushSentAt);
  writer.writeByte(offsets[6], object.pushStatus.index);
  writer.writeDateTime(offsets[7], object.readAt);
  writer.writeString(offsets[8], object.remoteId);
  writer.writeString(offsets[9], object.title);
  writer.writeByte(offsets[10], object.type.index);
}

AppNotification _appNotificationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppNotification();
  object.body = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.intakeId = reader.readLongOrNull(offsets[2]);
  object.medicationId = reader.readLongOrNull(offsets[3]);
  object.needsSync = reader.readBool(offsets[4]);
  object.pushSentAt = reader.readDateTimeOrNull(offsets[5]);
  object.pushStatus =
      _AppNotificationpushStatusValueEnumMap[reader.readByteOrNull(
        offsets[6],
      )] ??
      PushStatus.pending;
  object.readAt = reader.readDateTimeOrNull(offsets[7]);
  object.remoteId = reader.readStringOrNull(offsets[8]);
  object.title = reader.readStringOrNull(offsets[9]);
  object.type =
      _AppNotificationtypeValueEnumMap[reader.readByteOrNull(offsets[10])] ??
      NotificationType.reminder;
  return object;
}

P _appNotificationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (_AppNotificationpushStatusValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              PushStatus.pending)
          as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (_AppNotificationtypeValueEnumMap[reader.readByteOrNull(offset)] ??
              NotificationType.reminder)
          as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AppNotificationpushStatusEnumValueMap = {
  'pending': 0,
  'sent': 1,
  'failed': 2,
  'notApplicable': 3,
};
const _AppNotificationpushStatusValueEnumMap = {
  0: PushStatus.pending,
  1: PushStatus.sent,
  2: PushStatus.failed,
  3: PushStatus.notApplicable,
};
const _AppNotificationtypeEnumValueMap = {
  'reminder': 0,
  'missed': 1,
  'skipped': 2,
  'caregiverAlert': 3,
  'system': 4,
};
const _AppNotificationtypeValueEnumMap = {
  0: NotificationType.reminder,
  1: NotificationType.missed,
  2: NotificationType.skipped,
  3: NotificationType.caregiverAlert,
  4: NotificationType.system,
};

Id _appNotificationGetId(AppNotification object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _appNotificationGetLinks(AppNotification object) {
  return [];
}

void _appNotificationAttach(
  IsarCollection<dynamic> col,
  Id id,
  AppNotification object,
) {
  object.id = id;
}

extension AppNotificationQueryWhereSort
    on QueryBuilder<AppNotification, AppNotification, QWhere> {
  QueryBuilder<AppNotification, AppNotification, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhere>
  anyMedicationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'medicationId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhere> anyIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'intakeId'),
      );
    });
  }
}

extension AppNotificationQueryWhere
    on QueryBuilder<AppNotification, AppNotification, QWhereClause> {
  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remoteId', value: [null]),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'remoteId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  remoteIdEqualTo(String? remoteId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'remoteId', value: [remoteId]),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  remoteIdNotEqualTo(String? remoteId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [],
                upper: [remoteId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [remoteId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [remoteId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'remoteId',
                lower: [],
                upper: [remoteId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'medicationId', value: [null]),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'medicationId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdEqualTo(int? medicationId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'medicationId',
          value: [medicationId],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdNotEqualTo(int? medicationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'medicationId',
                lower: [],
                upper: [medicationId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'medicationId',
                lower: [medicationId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'medicationId',
                lower: [medicationId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'medicationId',
                lower: [],
                upper: [medicationId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdGreaterThan(int? medicationId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'medicationId',
          lower: [medicationId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdLessThan(int? medicationId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'medicationId',
          lower: [],
          upper: [medicationId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  medicationIdBetween(
    int? lowerMedicationId,
    int? upperMedicationId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'medicationId',
          lower: [lowerMedicationId],
          includeLower: includeLower,
          upper: [upperMedicationId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'intakeId', value: [null]),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'intakeId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdEqualTo(int? intakeId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'intakeId', value: [intakeId]),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdNotEqualTo(int? intakeId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intakeId',
                lower: [],
                upper: [intakeId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intakeId',
                lower: [intakeId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intakeId',
                lower: [intakeId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'intakeId',
                lower: [],
                upper: [intakeId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdGreaterThan(int? intakeId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'intakeId',
          lower: [intakeId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdLessThan(int? intakeId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'intakeId',
          lower: [],
          upper: [intakeId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterWhereClause>
  intakeIdBetween(
    int? lowerIntakeId,
    int? upperIntakeId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'intakeId',
          lower: [lowerIntakeId],
          includeLower: includeLower,
          upper: [upperIntakeId],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AppNotificationQueryFilter
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {
  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'body'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'body'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'body',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'body',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'body',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'body', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  bodyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'body', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'intakeId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'intakeId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'intakeId', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'intakeId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'intakeId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  intakeIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'intakeId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'medicationId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'medicationId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'medicationId', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'medicationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'medicationId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  medicationIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'medicationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  needsSyncEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'needsSync', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'pushSentAt'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'pushSentAt'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pushSentAt', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pushSentAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pushSentAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushSentAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pushSentAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushStatusEqualTo(PushStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pushStatus', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushStatusGreaterThan(PushStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pushStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushStatusLessThan(PushStatus value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pushStatus',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  pushStatusBetween(
    PushStatus lower,
    PushStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pushStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'readAt'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'readAt'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'readAt', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'readAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'readAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  readAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'readAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'title'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'title'),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  typeEqualTo(NotificationType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  typeGreaterThan(NotificationType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  typeLessThan(NotificationType value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterFilterCondition>
  typeBetween(
    NotificationType lower,
    NotificationType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension AppNotificationQueryObject
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {}

extension AppNotificationQueryLinks
    on QueryBuilder<AppNotification, AppNotification, QFilterCondition> {}

extension AppNotificationQuerySortBy
    on QueryBuilder<AppNotification, AppNotification, QSortBy> {
  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByIntakeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByMedicationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicationId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByMedicationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicationId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByPushSentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushSentAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByPushSentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushSentAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByPushStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushStatus', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByPushStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushStatus', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AppNotificationQuerySortThenBy
    on QueryBuilder<AppNotification, AppNotification, QSortThenBy> {
  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByBody() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByBodyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'body', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByIntakeIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'intakeId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByMedicationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicationId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByMedicationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'medicationId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByNeedsSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'needsSync', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByPushSentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushSentAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByPushSentAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushSentAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByPushStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushStatus', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByPushStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pushStatus', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByReadAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'readAt', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QAfterSortBy>
  thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension AppNotificationQueryWhereDistinct
    on QueryBuilder<AppNotification, AppNotification, QDistinct> {
  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByBody({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'body', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByIntakeId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'intakeId');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByMedicationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'medicationId');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByNeedsSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'needsSync');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByPushSentAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pushSentAt');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct>
  distinctByPushStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pushStatus');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByReadAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'readAt');
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByRemoteId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppNotification, AppNotification, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension AppNotificationQueryProperty
    on QueryBuilder<AppNotification, AppNotification, QQueryProperty> {
  QueryBuilder<AppNotification, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppNotification, String?, QQueryOperations> bodyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'body');
    });
  }

  QueryBuilder<AppNotification, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AppNotification, int?, QQueryOperations> intakeIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'intakeId');
    });
  }

  QueryBuilder<AppNotification, int?, QQueryOperations> medicationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'medicationId');
    });
  }

  QueryBuilder<AppNotification, bool, QQueryOperations> needsSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'needsSync');
    });
  }

  QueryBuilder<AppNotification, DateTime?, QQueryOperations>
  pushSentAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pushSentAt');
    });
  }

  QueryBuilder<AppNotification, PushStatus, QQueryOperations>
  pushStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pushStatus');
    });
  }

  QueryBuilder<AppNotification, DateTime?, QQueryOperations> readAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'readAt');
    });
  }

  QueryBuilder<AppNotification, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<AppNotification, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<AppNotification, NotificationType, QQueryOperations>
  typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}
