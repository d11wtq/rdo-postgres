/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "casts.h"
#include <stdlib.h>
#include "macros.h"
#include "types.h"

/** Predicate test if the given string is formatted as \x0afe... */
#define RDO_PG_NEW_HEX_P(s, len) (len >= 2 && s[0] == '\\' && s[1] == 'x')

/** Parse a PostgreSQL array and return an Array for the given type */
#define RDO_PG_ARRAY(clsname, s, len) \
  (rb_funcall((rb_funcall(rb_path2class("RDO::Postgres::Array::" clsname), \
                          rb_intern("parse"), 1, rb_str_new(s, len))), \
              rb_intern("to_a"), 0))

/** Lookup table for fast conversion of bytea hex strings to binary data */
static char * RDOPostgres_HexLookup;

/** Cast from a bytea to a String according to the new (PG 9.0) hex format */
static VALUE rdo_postgres_cast_bytea_hex(char * hex, size_t len) {
  if ((len % 2) != 0) {
    rb_raise(rb_eRuntimeError,
        "Bad hex value provided for bytea (length not divisible by 2)");
  }

  size_t   buflen = (len - 2) / 2;
  char   * buffer = malloc(sizeof(char) * buflen);
  char   * s      = hex + 2;
  char   * b      = buffer;

  if (buffer == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate %ld bytes for bytea conversion", buflen);
  }

  for (; *s; s += 2, ++b)
    *b = (RDOPostgres_HexLookup[*s] << 4) + (RDOPostgres_HexLookup[*(s + 1)]);

  VALUE str = rb_str_new(buffer, buflen);
  free(buffer);

  return str;
}

/** Cast from a bytea to a String according to a regular escape format */
static VALUE rdo_postgres_cast_bytea_escape(char * escaped, size_t len) {
  unsigned char * buffer  = PQunescapeBytea((unsigned char *) escaped, &len);

  if (buffer == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate memory for PQunescapeBytea() conversion");
  }

  VALUE str = rb_str_new((char *) buffer, len);
  PQfreemem(buffer);

  return str;
}

/** Cast from a bytea to a String, automatically detecting the format */
VALUE rdo_postgres_cast_bytea(char * escaped, size_t len) {
  if (RDO_PG_NEW_HEX_P(escaped, len))
    return rdo_postgres_cast_bytea_hex(escaped, len);
  else
    return rdo_postgres_cast_bytea_escape(escaped, len);
}

/** Get the value as a ruby type */
VALUE rdo_postgres_cast_value(PGresult * res, int row, int col, int enc) {
  if (PQgetisnull(res, row, col)) {
    return Qnil;
  }

  char * value  = PQgetvalue(res, row, col);
  int    length = PQgetlength(res, row, col);

  switch (PQftype(res, col)) {
    case RDO_PG_INT2OID:
    case RDO_PG_INT4OID:
    case RDO_PG_INT8OID:
      return RDO_FIXNUM(value);

    case RDO_PG_FLOAT4OID:
    case RDO_PG_FLOAT8OID:
      return RDO_FLOAT(value);

    case RDO_PG_NUMERICOID:
      return RDO_DECIMAL(value);

    case RDO_PG_BOOLOID:
      return RDO_BOOL(value);

    case RDO_PG_BYTEAOID:
      return rdo_postgres_cast_bytea(value, length);

    case RDO_PG_DATEOID:
      return RDO_DATE(value);

    case RDO_PG_TIMESTAMPOID:
      return RDO_DATE_TIME_WITHOUT_ZONE(value);

    case RDO_PG_TIMESTAMPTZOID:
      return RDO_DATE_TIME_WITH_ZONE(value);

    case RDO_PG_TEXTOID:
    case RDO_PG_CHAROID:
    case RDO_PG_VARCHAROID:
    case RDO_PG_BPCHAROID:
      return RDO_STRING(value, length, enc);

    case RDO_PG_TEXTARRAYOID:
    case RDO_PG_CHARARRAYOID:
    case RDO_PG_BPCHARARRAYOID:
    case RDO_PG_VARCHARARRAYOID:
      return RDO_PG_ARRAY("Text", value, length);

    case RDO_PG_INT2ARRAYOID:
    case RDO_PG_INT4ARRAYOID:
    case RDO_PG_INT8ARRAYOID:
      return RDO_PG_ARRAY("Integer", value, length);

    case RDO_PG_FLOAT4ARRAYOID:
    case RDO_PG_FLOAT8ARRAYOID:
      return RDO_PG_ARRAY("Float", value, length);

    case RDO_PG_NUMERICARRAYOID:
      return RDO_PG_ARRAY("Numeric", value, length);

    case RDO_PG_BOOLARRAYOID:
      return RDO_PG_ARRAY("Boolean", value, length);

    case RDO_PG_BYTEAARRAYOID:
      return RDO_PG_ARRAY("Bytea", value, length);

    case RDO_PG_DATEARRAYOID:
      return RDO_PG_ARRAY("Date", value, length);

    case RDO_PG_TIMESTAMPARRAYOID:
      return RDO_PG_ARRAY("Timestamp", value, length);

    default:
      return RDO_BINARY_STRING(value, length);
  }
}

/* Initialize hex decoding lookup table */
void Init_rdo_postgres_casts(void) {
  RDOPostgres_HexLookup = malloc(sizeof(char) * 256);

  if (RDOPostgres_HexLookup == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate 256 bytes for internal lookup table");
  }

  char c;

  for (c = '\0'; c < '\x7f'; ++c)
    RDOPostgres_HexLookup[c] = 0;

  for (c = '0'; c <= '9'; ++c)
    RDOPostgres_HexLookup[c] = c - '0';

  for (c = 'a'; c <= 'f'; ++c)
    RDOPostgres_HexLookup[c] = 10 + c - 'a';

  for (c = 'A'; c <= 'F'; ++c)
    RDOPostgres_HexLookup[c] = 10 + c - 'A';
}
