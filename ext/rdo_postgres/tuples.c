/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "tuples.h"

/** Wrapper for the TupleList class */
typedef struct {
  PGresult * res;
} RDOPostgresTupleList;

/** class RDO::Postgres::TupleList */
static VALUE rdo_postgres_cTupleList;

/** Used to free the struct wrapped by TupleList during GC */
static void rdo_postgres_tuple_list_free(RDOPostgresTupleList * list) {
  PQclear(list->res);
  free(list);
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

  rb_include_module(rdo_postgres_cTupleList, rb_mEnumerable);
}
