/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "tuples.h"

#define RDO_PG_NEW_HEX_P(s, len) (len > 2 && s[0] == '\\' && s[1] == 'x')

/** Wrapper for the TupleList class */
typedef struct {
  PGresult * res;
} RDOPostgresTupleList;

/** Lookup table for fast conversion of bytea hex strings to binary data */
static char * RDOPostgres_HexLookup;

/** class RDO::Postgres::TupleList */
static VALUE rdo_postgres_cTupleList;

/** Used to free the struct wrapped by TupleList during GC */
static void rdo_postgres_tuple_list_free(RDOPostgresTupleList * list) {
  PQclear(list->res);
  free(list);
}

/** Cast from a bytea to a String according to the new (PG 9.0) hex format */
static VALUE rdo_postgres_tuple_list_cast_bytea_hex(char * hex, size_t len) {
  if ((len % 2) != 0) {
    rb_raise(rb_eRuntimeError,
        "Bad hex value provided for bytea (not divisible by 2)");
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
static VALUE rdo_postgres_tuple_list_cast_bytea_escape(char * escaped, size_t len) {
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
static VALUE rdo_postgres_tuple_list_cast_value(PGresult * res, int row, int col) {
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

    case BOOLOID:
      return (value[0] == 't') ? Qtrue : Qfalse;

    case BYTEAOID:
      if (RDO_PG_NEW_HEX_P(value, length)) {
        return rdo_postgres_tuple_list_cast_bytea_hex(value, length);
      } else {
        return rdo_postgres_tuple_list_cast_bytea_escape(value, length);
      }

    default:
      return rb_str_new(value, length);
  }
}

/** Factory to return a new instance of TupleList for a result */
VALUE rdo_postgres_tuple_list_new(PGresult * res) {
  RDOPostgresTupleList * list = malloc(sizeof(RDOPostgresTupleList));
  list->res = res;

  VALUE obj = Data_Wrap_Struct(rdo_postgres_cTupleList, 0,
      rdo_postgres_tuple_list_free, list);

  rb_obj_call_init(obj, 0, NULL);

  return obj;
}

/** Allow iteration over all tuples, yielding Hashes into a block */
static VALUE rdo_postgres_tuple_list_each(VALUE self) {
  if (!rb_block_given_p()) {
    return self;
  }

  RDOPostgresTupleList * list;
  Data_Get_Struct(self, RDOPostgresTupleList, list);

  int i     = 0;
  int ntups = PQntuples(list->res);

  for (; i < ntups; ++i) {
    VALUE hash  = rb_hash_new();
    int j       = 0;
    int nfields = PQnfields(list->res);

    for (; j < nfields; ++j) {
      rb_hash_aset(hash,
          ID2SYM(rb_intern(PQfname(list->res, j))),
          rdo_postgres_tuple_list_cast_value(list->res, i, j));
    }

    rb_yield(hash);
  }

  return self;
}

/**
 * Invoked during driver initialization to set up the TupleList.
 */
void Init_rdo_postgres_tuples(void) {
  VALUE mPostgres = rb_path2class("RDO::Postgres");

  rdo_postgres_cTupleList = rb_define_class_under(mPostgres,
      "TupleList", rb_cObject);

  rb_define_method(rdo_postgres_cTupleList,
      "each", rdo_postgres_tuple_list_each, 0);

  /* Initialize hex decoding lookup table */
  RDOPostgres_HexLookup = malloc(sizeof(char) * 128);

  if (RDOPostgres_HexLookup == NULL) {
    rb_raise(rb_eRuntimeError,
        "Failed to allocate 128 bytes for internal lookup table");
  }

  // initialize hexadecimal lookup table
  char c;

  for (c = '\0'; c < '\x7f'; ++c)
    RDOPostgres_HexLookup[c] = 0;

  for (c = '0'; c <= '9'; ++c)
    RDOPostgres_HexLookup[c] = c - '0';

  for (c = 'a'; c <= 'f'; ++c)
    RDOPostgres_HexLookup[c] = 10 + c - 'a';

  for (c = 'A'; c <= 'F'; ++c)
    RDOPostgres_HexLookup[c] = 10 + c - 'A';

  rb_include_module(rdo_postgres_cTupleList, rb_mEnumerable);
}
