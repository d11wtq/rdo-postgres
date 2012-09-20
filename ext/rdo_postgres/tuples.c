/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "tuples.h"

/** class RDO::Postgres::TupleList */
VALUE rdo_postgres_cTupleList;

/** Wrapper for the TupleList class */
typedef struct {
  PGresult * res;
} RDOPostgresTupleList;

/** Used to free the struct wrapped by TupleList during GC */
void rdo_postgres_tuple_list_free(RDOPostgresTupleList * list) {
  PQclear(list->res);
  free(list);
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
VALUE rdo_postgres_tuple_list_each(VALUE self) {
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
          rb_str_new(
            PQgetvalue(list->res, i, j),
            PQgetlength(list->res, i, j)));
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
