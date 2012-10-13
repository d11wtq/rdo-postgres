/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "arrays.h"
#include "casts.h"
#include "macros.h"
#include <ruby.h>
#include <libpq-fe.h>

/** Parse a bytea string into a binary Ruby String */
VALUE rdo_postgres_array_bytea_parse_value(VALUE self, VALUE s) {
  s = rb_call_super(1, &s);
  Check_Type(s, T_STRING);
  return rdo_postgres_cast_bytea(RSTRING_PTR(s), RSTRING_LEN(s));
}

/** Format a value as a bytea */
VALUE rdo_postgres_array_bytea_format_value(VALUE self, VALUE v) {
  if (TYPE(v) != T_STRING) {
    v = RDO_OBJ_TO_S(v);
  }

  size_t          len   = 0;
  unsigned char * bytea = PQescapeBytea((unsigned char *) RSTRING_PTR(v),
      RSTRING_LEN(v), &len);

  VALUE escaped   = rb_str_new((char *) bytea, len - 1);
  VALUE formatted = rb_call_super(1, &escaped);

  PQfreemem(bytea);

  return formatted;
}

/** Initialize Array extensions */
void Init_rdo_postgres_arrays(void) {
  VALUE cByteaArray = rb_path2class("RDO::Postgres::Array::Bytea");

  rb_define_method(cByteaArray,
      "parse_value", rdo_postgres_array_bytea_parse_value, 1);

  rb_define_method(cByteaArray,
      "format_value", rdo_postgres_array_bytea_format_value, 1);
}
