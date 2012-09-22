/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "casts.h"
#include <postgres.h>
#include <catalog/pg_type.h>
#include "macros.h"

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
  unsigned char * buffer  = PQunescapeBytea(escaped, &len);

  if (buffer == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate memory for PQunescapeBytea() conversion");
  }

  VALUE str = rb_str_new(buffer, len);
  PQfreemem(buffer);

  return str;
}

/** Get the value as a ruby type */
VALUE rdo_postgres_cast_value(PGresult * res, int row, int col) {
  if (PQgetisnull(res, row, col)) {
    return Qnil;
  }

  char * value  = PQgetvalue(res, row, col);
  int    length = PQgetlength(res, row, col);

  switch (PQftype(res, col)) {
    case INT2OID:
    case INT4OID:
    case INT8OID:
      return RDO_FIXNUM(value);

    case FLOAT4OID:
    case FLOAT8OID:
      return RDO_FLOAT(value);

    case NUMERICOID:
      return RDO_DECIMAL(value);

    case BOOLOID:
      return RDO_BOOL(value);

    case BYTEAOID:
      if (RDO_PG_NEW_HEX_P(value, length)) {
        return rdo_postgres_cast_bytea_hex(value, length);
      } else {
        return rdo_postgres_cast_bytea_escape(value, length);
      }

    case DATEOID:
      return RDO_DATE(value);

    case TIMESTAMPOID:
      return RDO_DATE_TIME_WITHOUT_ZONE(value);

    case TIMESTAMPTZOID:
      return RDO_DATE_TIME_WITH_ZONE(value);

    case TEXTOID:
    case CHAROID:
      return RDO_STRING(value, length);

    default:
      return RDO_BINARY_STRING(value, length);
  }
}

/* Initialize hex decoding lookup table */
void Init_rdo_postgres_casts(void) {
  RDOPostgres_HexLookup = malloc(sizeof(char) * 128);

  if (RDOPostgres_HexLookup == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate 128 bytes for internal lookup table");
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
