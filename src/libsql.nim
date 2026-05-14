import std/[options, os]

when defined(macosx):
  const liblibsql = "liblibsql.dylib"
elif defined(windows):
  const liblibsql = "liblibsql.dll"
else:
  const liblibsql = "liblibsql.so"

when defined(libsqlStatic):
  {.passL: "-L" & getEnv("HOME") & "/.local/lib -l:liblibsql.a" .}
  {.push cdecl.}
else:
  {.push cdecl, dynlib: liblibsql.}

type
  libsql_cypher_t* {.size: sizeof(cint).} = enum
    LIBSQL_CYPHER_DEFAULT = 0
    LIBSQL_CYPHER_AES256

  libsql_type_t* {.size: sizeof(cint).} = enum
    LIBSQL_TYPE_INTEGER = 1
    LIBSQL_TYPE_REAL = 2
    LIBSQL_TYPE_TEXT = 3
    LIBSQL_TYPE_BLOB = 4
    LIBSQL_TYPE_NULL = 5

  libsql_tracing_level_t* {.size: sizeof(cint).} = enum
    LIBSQL_TRACING_LEVEL_ERROR = 1
    LIBSQL_TRACING_LEVEL_WARN
    LIBSQL_TRACING_LEVEL_INFO
    LIBSQL_TRACING_LEVEL_DEBUG
    LIBSQL_TRACING_LEVEL_TRACE

type
  libsql_error_t* = object

  libsql_database_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_connection_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_statement_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_transaction_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_rows_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_row_t* = object
    err*: ptr libsql_error_t
    inner*: pointer

  libsql_batch_t* = object
    err*: ptr libsql_error_t

  libsql_slice_t* = object
    data*: pointer
    len*: csize_t

  libsql_value_union_t* {.union.} = object
    integer*: int64
    real*: cdouble
    text*: libsql_slice_t
    blob*: libsql_slice_t

  libsql_value_t* = object
    value*: libsql_value_union_t
    type_field* {.importc: "type".}: libsql_type_t

  libsql_result_value_t* = object
    err*: ptr libsql_error_t
    ok*: libsql_value_t

  libsql_sync_t* = object
    err*: ptr libsql_error_t
    frame_no*: uint64
    frames_synced*: uint64

  libsql_bind_t* = object
    err*: ptr libsql_error_t

  libsql_execute_t* = object
    err*: ptr libsql_error_t
    rows_changed*: uint64

  libsql_connection_info_t* = object
    err*: ptr libsql_error_t
    last_inserted_rowid*: int64
    total_changes*: uint64

  libsql_log_t* = object
    message*: cstring
    target*: cstring
    file*: cstring
    timestamp*: uint64
    line*: csize_t
    level*: libsql_tracing_level_t

  libsql_database_desc_t* {.bycopy.} = object
    url*: cstring
    path*: cstring
    auth_token*: cstring
    encryption_key*: cstring
    sync_interval*: uint64
    cypher*: libsql_cypher_t
    disable_read_your_writes*: bool
    webpki*: bool
    synced*: bool
    disable_safety_assert*: bool
    namespace*: cstring

  libsql_config_t* = object
    logger*: proc (log: libsql_log_t) {.cdecl.}
    version*: cstring

# Note: C returns const libsql_error_t*, but Nim doesn't distinguish const ptr
# The const only means the pointed-to data won't be modified through this pointer
proc libsql_setup*(config: libsql_config_t): ptr libsql_error_t {.importc.}
proc libsql_error_message*(self: ptr libsql_error_t): cstring {.importc.}
proc libsql_error_deinit*(self: ptr libsql_error_t) {.importc.}
proc libsql_database_init*(desc: libsql_database_desc_t): libsql_database_t {.importc.}
proc libsql_database_sync*(self: libsql_database_t): libsql_sync_t {.importc.}
proc libsql_database_connect*(self: libsql_database_t): libsql_connection_t {.importc.}
proc libsql_database_deinit*(self: libsql_database_t) {.importc.}
proc libsql_connection_transaction*(self: libsql_connection_t): libsql_transaction_t {.importc.}
proc libsql_connection_batch*(self: libsql_connection_t, sql: cstring): libsql_batch_t {.importc.}
proc libsql_connection_info*(self: libsql_connection_t): libsql_connection_info_t {.importc.}
proc libsql_connection_prepare*(self: libsql_connection_t, sql: cstring): libsql_statement_t {.importc.}
proc libsql_connection_deinit*(self: libsql_connection_t) {.importc.}
proc libsql_transaction_batch*(self: libsql_transaction_t, sql: cstring): libsql_batch_t {.importc.}
proc libsql_transaction_prepare*(self: libsql_transaction_t, sql: cstring): libsql_statement_t {.importc.}
proc libsql_transaction_commit*(self: libsql_transaction_t) {.importc.}
proc libsql_transaction_rollback*(self: libsql_transaction_t) {.importc.}
proc libsql_statement_execute*(self: libsql_statement_t): libsql_execute_t {.importc.}
proc libsql_statement_query*(self: libsql_statement_t): libsql_rows_t {.importc.}
proc libsql_statement_reset*(self: libsql_statement_t) {.importc.}
proc libsql_statement_column_count*(self: libsql_statement_t): csize_t {.importc.}
proc libsql_statement_bind_named*(self: libsql_statement_t, name: cstring, value: libsql_value_t): libsql_bind_t {.importc.}
proc libsql_statement_bind_value*(self: libsql_statement_t, value: libsql_value_t): libsql_bind_t {.importc.}
proc libsql_statement_deinit*(self: libsql_statement_t) {.importc.}
proc libsql_rows_next*(self: libsql_rows_t): libsql_row_t {.importc.}
proc libsql_rows_column_name*(self: libsql_rows_t, index: int32): libsql_slice_t {.importc.}
proc libsql_rows_column_count*(self: libsql_rows_t): int32 {.importc.}
proc libsql_rows_deinit*(self: libsql_rows_t) {.importc.}
proc libsql_row_value*(self: libsql_row_t, index: int32): libsql_result_value_t {.importc.}
proc libsql_row_name*(self: libsql_row_t, index: int32): libsql_slice_t {.importc.}
proc libsql_row_length*(self: libsql_row_t): int32 {.importc.}
proc libsql_row_empty*(self: libsql_row_t): bool {.importc.}
proc libsql_row_deinit*(self: libsql_row_t) {.importc.}
proc libsql_integer*(integer: int64): libsql_value_t {.importc.}
proc libsql_real*(real: cdouble): libsql_value_t {.importc.}
proc libsql_text*(ptr_str: cstring, len: csize_t): libsql_value_t {.importc.}
proc libsql_blob*(ptr_blob: ptr uint8, len: csize_t): libsql_value_t {.importc.}
proc libsql_null*(): libsql_value_t {.importc.}
proc libsql_slice_deinit*(value: libsql_slice_t) {.importc.}

{.pop.}

type
  ValueKind* = enum
    vkInteger
    vkReal
    vkText
    vkBlob
    vkNull

  Value* = object
    case kind*: ValueKind
    of vkInteger: intVal*: int64
    of vkReal: floatVal*: float64
    of vkText: strVal*: string
    of vkBlob: blobVal*: seq[byte]
    of vkNull: discard

  DbConfig* = object
    url*: Option[string]
    path*: string
    authToken*: Option[string]
    encryptionKey*: Option[string]
    syncInterval*: Option[uint64]
    cypher*: libsql_cypher_t
    disableReadYourWrites*: bool
    webpki*: bool
    synced*: bool
    disableSafetyAssert*: bool
    namespace*: Option[string]

  LibSqlError* = object of CatchableError

  Database* = object
    handle*: libsql_database_t

  Connection* = object
    db*: Database
    handle*: libsql_connection_t

  Transaction* = object
    conn*: Connection
    handle*: libsql_transaction_t
    committed*: bool

  Statement* = object
    conn*: Connection
    tx*: Option[Transaction]
    handle*: libsql_statement_t

  Row* = object
    values*: seq[Value]
    columnNames*: seq[string]

  Rows* = object
    handle*: libsql_rows_t
    columnCount*: int
    columnNames*: seq[string]

  ExecInfo* = object
    rowsChanged*: uint64
    lastInsertRowid*: int64
    totalChanges*: uint64

proc raiseIfError(err: ptr libsql_error_t) =
  if err != nil:
    let msg = $libsql_error_message(err)
    libsql_error_deinit(err)
    raise newException(LibSqlError, msg)

proc sliceToString(slice: libsql_slice_t): string =
  if slice.len == 0:
    return ""
  var s = newString(slice.len)
  copyMem(addr s[0], slice.data, slice.len)
  if s[^1] == '\0':
    s.setLen(s.len - 1)
  return s

proc toValue*(v: libsql_value_t): Value =
  case v.type_field
  of LIBSQL_TYPE_INTEGER:
    Value(kind: vkInteger, intVal: v.value.integer)
  of LIBSQL_TYPE_REAL:
    Value(kind: vkReal, floatVal: v.value.real)
  of LIBSQL_TYPE_TEXT:
    Value(kind: vkText, strVal: sliceToString(v.value.text))
  of LIBSQL_TYPE_BLOB:
    var blob = newSeq[byte](v.value.blob.len)
    if v.value.blob.len > 0:
      copyMem(addr blob[0], v.value.blob.data, v.value.blob.len)
    Value(kind: vkBlob, blobVal: blob)
  of LIBSQL_TYPE_NULL:
    Value(kind: vkNull)

proc toLibSqlValue*(v: Value): libsql_value_t =
  case v.kind
  of vkInteger:
    libsql_integer(v.intVal)
  of vkReal:
    libsql_real(v.floatVal)
  of vkText:
    libsql_text(v.strVal.cstring, v.strVal.len.csize_t)
  of vkBlob:
    if v.blobVal.len > 0:
      libsql_blob(cast[ptr uint8](unsafeAddr v.blobVal[0]), v.blobVal.len.csize_t)
    else:
      libsql_blob(nil, 0)
  of vkNull:
    libsql_null()

proc defaultDbConfig*(path: string): DbConfig =
  result.path = path
  result.cypher = LIBSQL_CYPHER_DEFAULT
  result.disableReadYourWrites = false
  result.webpki = false
  result.synced = false
  result.disableSafetyAssert = false

proc memoryDbConfig*(): DbConfig =
  result.path = ":memory:"
  result.cypher = LIBSQL_CYPHER_DEFAULT

proc remoteDbConfig*(url, authToken: string): DbConfig =
  result.url = some(url)
  result.path = ""
  result.authToken = some(authToken)
  result.cypher = LIBSQL_CYPHER_DEFAULT

proc setupLibSql*() =
  let err = libsql_setup(libsql_config_t(logger: nil, version: nil))
  raiseIfError(err)

proc openDatabase*(config: DbConfig): Database =
  var desc: libsql_database_desc_t
  if config.url.isSome:
    desc.url = config.url.get.cstring
  if config.path != "":
    desc.path = config.path.cstring
  if config.authToken.isSome:
    desc.auth_token = config.authToken.get.cstring
  if config.encryptionKey.isSome:
    desc.encryption_key = config.encryptionKey.get.cstring
  if config.syncInterval.isSome:
    desc.sync_interval = config.syncInterval.get
  desc.cypher = config.cypher
  desc.disable_read_your_writes = config.disableReadYourWrites
  desc.webpki = config.webpki
  desc.synced = config.synced
  desc.disable_safety_assert = config.disableSafetyAssert
  if config.namespace.isSome:
    desc.namespace = config.namespace.get.cstring
  result.handle = libsql_database_init(desc)
  raiseIfError(result.handle.err)

proc sync*(db: Database) =
  let res = libsql_database_sync(db.handle)
  raiseIfError(res.err)

proc close*(db: var Database) =
  libsql_database_deinit(db.handle)
  db.handle.inner = nil
  db.handle.err = nil

proc connect*(db: Database): Connection =
  result.db = db
  result.handle = libsql_database_connect(db.handle)
  raiseIfError(result.handle.err)

proc close*(conn: var Connection) =
  libsql_connection_deinit(conn.handle)
  conn.handle.inner = nil
  conn.handle.err = nil

proc getInfo*(conn: Connection): ExecInfo =
  let info = libsql_connection_info(conn.handle)
  raiseIfError(info.err)
  result.lastInsertRowid = info.last_inserted_rowid
  result.totalChanges = info.total_changes

proc beginTransaction*(conn: Connection): Transaction =
  result.conn = conn
  result.handle = libsql_connection_transaction(conn.handle)
  raiseIfError(result.handle.err)
  result.committed = false

proc commit*(tx: var Transaction) =
  if not tx.committed:
    libsql_transaction_commit(tx.handle)
    tx.committed = true
    tx.handle.inner = nil
    tx.handle.err = nil

proc rollback*(tx: var Transaction) =
  if not tx.committed:
    libsql_transaction_rollback(tx.handle)
    tx.committed = true
    tx.handle.inner = nil
    tx.handle.err = nil

proc prepare*(conn: Connection, sql: string): Statement =
  result.conn = conn
  result.tx = none(Transaction)
  result.handle = libsql_connection_prepare(conn.handle, sql.cstring)
  raiseIfError(result.handle.err)

proc prepare*(tx: Transaction, sql: string): Statement =
  result.conn = tx.conn
  result.tx = some(tx)
  result.handle = libsql_transaction_prepare(tx.handle, sql.cstring)
  raiseIfError(result.handle.err)

proc bindParam*(stmt: var Statement, value: Value) =
  let lval = toLibSqlValue(value)
  let res = libsql_statement_bind_value(stmt.handle, lval)
  raiseIfError(res.err)

proc bindParam*(stmt: var Statement, name: string, value: Value) =
  let lval = toLibSqlValue(value)
  let res = libsql_statement_bind_named(stmt.handle, name.cstring, lval)
  raiseIfError(res.err)

proc reset*(stmt: var Statement) =
  libsql_statement_reset(stmt.handle)

proc finalize*(stmt: var Statement) =
  libsql_statement_deinit(stmt.handle)
  stmt.handle.inner = nil
  stmt.handle.err = nil

proc columnCount*(stmt: Statement): int =
  int(libsql_statement_column_count(stmt.handle))

proc execute*(stmt: var Statement): ExecInfo =
  let res = libsql_statement_execute(stmt.handle)
  raiseIfError(res.err)
  result.rowsChanged = res.rows_changed
  let info = libsql_connection_info(stmt.conn.handle)
  raiseIfError(info.err)
  result.lastInsertRowid = info.last_inserted_rowid
  result.totalChanges = info.total_changes

proc query*(stmt: var Statement): Rows =
  result.handle = libsql_statement_query(stmt.handle)
  raiseIfError(result.handle.err)
  result.columnCount = int(libsql_rows_column_count(result.handle))
  for i in 0..<result.columnCount:
    let slice = libsql_rows_column_name(result.handle, int32(i))
    result.columnNames.add(sliceToString(slice))
    libsql_slice_deinit(slice)

proc next*(rows: var Rows): Option[Row] =
  let row_handle = libsql_rows_next(rows.handle)
  if libsql_row_empty(row_handle):
    return none(Row)
  var row: Row
  row.columnNames = rows.columnNames
  let colCount = libsql_row_length(row_handle)
  for i in 0..<colCount:
    let val_res = libsql_row_value(row_handle, int32(i))
    if val_res.err != nil:
      libsql_row_deinit(row_handle)
      raiseIfError(val_res.err)
    row.values.add(toValue(val_res.ok))
  libsql_row_deinit(row_handle)
  return some(row)

proc close*(rows: var Rows) =
  libsql_rows_deinit(rows.handle)
  rows.handle.inner = nil
  rows.handle.err = nil

iterator items*(rows: var Rows): Row =
  var row = rows.next()
  while row.isSome():
    yield row.get()
    row = rows.next()

proc exec*(conn: Connection, sql: string, params: varargs[Value]): ExecInfo =
  if params.len == 0:
    let batch = libsql_connection_batch(conn.handle, sql.cstring)
    raiseIfError(batch.err)
  else:
    var stmt = conn.prepare(sql)
    for param in params:
      stmt.bindParam(param)
    result = stmt.execute()
    stmt.finalize()

proc exec*(tx: Transaction, sql: string, params: varargs[Value]) =
  if params.len == 0:
    let batch = libsql_transaction_batch(tx.handle, sql.cstring)
    raiseIfError(batch.err)
  else:
    var stmt = tx.prepare(sql)
    for param in params:
      stmt.bindParam(param)
    discard stmt.execute()
    stmt.finalize()

proc tryExec*(conn: Connection, sql: string, params: varargs[Value]): bool =
  try:
    discard conn.exec(sql, params)
    return true
  except LibSqlError:
    return false

proc query*(conn: Connection, sql: string, params: varargs[Value]): seq[Row] =
  var stmt = conn.prepare(sql)
  for param in params:
    stmt.bindParam(param)
  var rows = stmt.query()
  for row in rows:
    result.add(row)
  rows.close()
  stmt.finalize()

proc getAllRows*(conn: Connection, sql: string, params: varargs[Value]): seq[Row] =
  query(conn, sql, params)

proc getRow*(conn: Connection, sql: string, params: varargs[Value]): Option[Row] =
  var stmt = conn.prepare(sql)
  for param in params:
    stmt.bindParam(param)
  var rows = stmt.query()
  result = rows.next()
  rows.close()
  stmt.finalize()

proc v*(i: int64): Value = Value(kind: vkInteger, intVal: i)
proc v*(i: int): Value = Value(kind: vkInteger, intVal: int64(i))
proc v*(f: float64): Value = Value(kind: vkReal, floatVal: f)
proc v*(s: string): Value = Value(kind: vkText, strVal: s)
proc v*(b: seq[byte]): Value = Value(kind: vkBlob, blobVal: b)
proc nullVal*(): Value = Value(kind: vkNull)

proc getInt*(v: Value): int64 =
  if v.kind != vkInteger: raise newException(LibSqlError, "Not an integer")
  v.intVal

proc getFloat*(v: Value): float64 =
  if v.kind != vkReal: raise newException(LibSqlError, "Not a real")
  v.floatVal

proc getString*(v: Value): string =
  if v.kind != vkText: raise newException(LibSqlError, "Not text")
  v.strVal

proc getBlob*(v: Value): seq[byte] =
  if v.kind != vkBlob: raise newException(LibSqlError, "Not a blob")
  v.blobVal

proc isNull*(v: Value): bool = v.kind == vkNull

proc `[]`*(row: Row, index: int): Value =
  if index < 0 or index >= row.values.len:
    raise newException(IndexDefect, "Column index out of bounds")
  row.values[index]

proc `[]`*(row: Row, name: string): Value =
  for i, colName in row.columnNames:
    if colName == name:
      return row.values[i]
  raise newException(KeyError, "Column not found: " & name)

proc get*(row: Row, index: int, default: Value): Value =
  if index < 0 or index >= row.values.len: return default
  row.values[index]

proc get*(row: Row, name: string, default: Value): Value =
  for i, colName in row.columnNames:
    if colName == name:
      return row.values[i]
  return default

proc len*(row: Row): int = row.values.len

proc `$`*(v: Value): string =
  case v.kind
  of vkInteger: $v.intVal
  of vkReal: $v.floatVal
  of vkText: v.strVal
  of vkBlob: "BLOB(" & $v.blobVal.len & " bytes)"
  of vkNull: "NULL"

proc `$`*(row: Row): string =
  result = "Row("
  for i, val in row.values:
    if i > 0: result.add(", ")
    result.add(row.columnNames[i] & ": " & $val)
  result.add(")")

setupLibSql()
