/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "casts.h"
#include <postgres.h>
#include <catalog/pg_type.h>

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

static VALUE rdo_postgres_cast_float(char * str) {
  if (strcmp(str, "NaN") == 0) {
    return rb_const_get(rb_cFloat, rb_intern("NAN"));
  } else if (strcmp(str, "Infinity") == 0) {
    return rb_const_get(rb_cFloat, rb_intern("INFINITY"));
  } else if (strcmp(str, "-Infinity") == 0) {
    return rb_funcall(rb_const_get(rb_cFloat, rb_intern("INFINITY")),
        rb_intern("*"), 1, INT2NUM(-1));
  }

  return rb_float_new(rb_cstr_to_dbl(str, Qfalse));
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
      return rb_cstr2inum(value, 10);

    case FLOAT4OID:
    case FLOAT8OID:
      return rdo_postgres_cast_float(value);

    case NUMERICOID:
      return rb_funcall(rb_path2class("BigDecimal"),
          rb_intern("new"), 1,
          rb_str_new(value, length));

    case BOOLOID:
      return (value[0] == 't') ? Qtrue : Qfalse;

    case BYTEAOID:
      if (RDO_PG_NEW_HEX_P(value, length)) {
        return rdo_postgres_cast_bytea_hex(value, length);
      } else {
        return rdo_postgres_cast_bytea_escape(value, length);
      }

    default:
      return rb_str_new(value, length);
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
