#include <stdio.h>
#include <ruby.h>
#include <postgres.h>
#include <libpq-fe.h>

typedef struct {
  PGconn * ptr;
} RDOPostgres;

void rdo_postgres_connection_free(RDOPostgres * conn) {
  PQfinish(conn->ptr);
  free(conn);
}

static VALUE rdo_postgres_connection_allocate(VALUE klass) {
  RDOPostgres * conn = malloc(sizeof(RDOPostgres));
  conn->ptr = NULL;

  VALUE self = Data_Wrap_Struct(klass, 0,
      rdo_postgres_connection_free, conn);

  return self;
}

static VALUE rdo_postgres_connection_open(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);
  conn->ptr = PQconnectdb(
      RSTRING_PTR(rb_funcall(self, rb_intern("connect_db_string"), 0)));

  if (conn->ptr == NULL || PQstatus(conn->ptr) == CONNECTION_BAD) {
    return Qfalse;
  }

  return Qtrue;
}

void Init_rdo_postgres(void) {
  rb_require("rdo/postgres/connection");

  VALUE cPostgresConnection = rb_path2class("RDO::Postgres::Connection");

  rb_define_method(
      cPostgresConnection,
      "open", rdo_postgres_connection_open, 0);
  rb_define_alloc_func(
      cPostgresConnection,
      rdo_postgres_connection_allocate);

}
