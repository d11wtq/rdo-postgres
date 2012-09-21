/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>
#include <ruby.h>
#include <postgres.h>
#include <libpq-fe.h>

#include "tuples.h"

/** RDO::Postgres::Connection wraps this struct */
typedef struct {
  PGconn * ptr;
  int      is_open;
} RDOPostgres;

/** During GC, free any stranded connection */
static void rdo_postgres_connection_free(RDOPostgres * conn) {
  PQfinish(conn->ptr);
  free(conn);
}

/** Postgres outputs notices (e.g. auto-generating sequence...) unless overridden */
static void rdo_postgres_connection_notice_processor(void * arg, const char * msg) {}

static VALUE rdo_postgres_result_info_new(PGresult * res) {
  VALUE info = rb_hash_new();
  rb_hash_aset(info, ID2SYM(rb_intern("count")), INT2NUM(PQntuples(res)));
  if (strlen(PQcmdTuples(res)) > 0) {
    rb_hash_aset(info,
        ID2SYM(rb_intern("affected_rows")),
        rb_cstr2inum(PQcmdTuples(res), 10));
  }
  return info;
}

/** Allocate memory for the connection struct */
static VALUE rdo_postgres_connection_allocate(VALUE klass) {
  RDOPostgres * conn = malloc(sizeof(RDOPostgres));

  conn->ptr     = NULL;
  conn->is_open = 0;

  VALUE self = Data_Wrap_Struct(klass, 0,
      rdo_postgres_connection_free, conn);

  return self;
}

/** Connect to the postgres server */
static VALUE rdo_postgres_connection_open(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);

  if (conn->is_open) {
    return Qtrue;
  }

  conn->ptr = PQconnectdb(
      RSTRING_PTR(rb_funcall(self, rb_intern("connect_db_string"), 0)));

  if (conn->ptr == NULL || PQstatus(conn->ptr) == CONNECTION_BAD) {
    rb_raise(rb_path2class("RDO::Exception"),
        "PostgreSQL connection failed: %s",
        PQerrorMessage(conn->ptr));
  } else if (PQprotocolVersion(conn->ptr) < 3) {
    rb_raise(rb_path2class("RDO::Exception"),
        "rdo-postgres requires PostgreSQL protocol version >= 3 (using %u). "
        "PostgreSQL >= 7.4 required.",
        PQprotocolVersion(conn->ptr));
  } else {
    PQsetNoticeProcessor(conn->ptr, &rdo_postgres_connection_notice_processor, NULL);
    conn->is_open = 1;
  }

  return Qtrue;
}

/** Disconnect from the postgres server, and release memory */
static VALUE rdo_postgres_connection_close(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);

  PQfinish(conn->ptr);
  conn->ptr     = NULL;
  conn->is_open = 0;

  return Qtrue;
}

/** Preciate test if connection is open */
static VALUE rdo_postgres_connection_open_p(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);
  return conn->is_open ? Qtrue : Qfalse;
}

/** Execute a statement, with optional bind parameters */
static VALUE rdo_postgres_connection_execute(int argc, VALUE * args, VALUE self) {
  if (argc < 1) {
    rb_raise(rb_eArgError, "Wrong number of arguments (%d for 1)", argc);
  }

  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);

  if (!(conn->is_open)) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Unable to execute query: connection is not open");
  }

  Check_Type(args[0], T_STRING);

  PGresult       * res    = PQexec(conn->ptr, RSTRING_PTR(args[0]));
  ExecStatusType   status = PQresultStatus(res);

  if (status == PGRES_BAD_RESPONSE || status == PGRES_FATAL_ERROR) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Failed to execute query: %s", PQresultErrorMessage(res));
  }

  return rb_funcall(rb_path2class("RDO::Result"),
      rb_intern("new"), 2,
      rdo_postgres_tuple_list_new(res),
      rdo_postgres_result_info_new(res));
}

/**
 * Extension initializer.
 */
void Init_rdo_postgres(void) {
  rb_require("rdo/postgres/connection");

  VALUE cPostgresConnection = rb_path2class("RDO::Postgres::Connection");

  rb_define_alloc_func(
      cPostgresConnection,
      rdo_postgres_connection_allocate);

  rb_define_method(
      cPostgresConnection,
      "open", rdo_postgres_connection_open, 0);

  rb_define_method(
      cPostgresConnection,
      "close", rdo_postgres_connection_close, 0);

  rb_define_method(
      cPostgresConnection,
      "open?", rdo_postgres_connection_open_p, 0);

  rb_define_method(
      cPostgresConnection,
      "execute", rdo_postgres_connection_execute, -1);

  Init_rdo_postgres_tuples();
}
