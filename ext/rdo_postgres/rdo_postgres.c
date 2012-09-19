#include <stdio.h>
#include <ruby.h>
#include <postgres.h>
#include <libpq-fe.h>

typedef struct {
  PGconn * ptr;
  int      is_open;
} RDOPostgres;

void rdo_postgres_connection_free(RDOPostgres * conn) {
  PQfinish(conn->ptr);
  free(conn);
}

static VALUE rdo_postgres_connection_allocate(VALUE klass) {
  RDOPostgres * conn = malloc(sizeof(RDOPostgres));

  conn->ptr     = NULL;
  conn->is_open = 0;

  VALUE self = Data_Wrap_Struct(klass, 0,
      rdo_postgres_connection_free, conn);

  return self;
}

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
        "rdo-postgres requires PostgreSQL protocol version >= 3 (using %u)",
        PQprotocolVersion(conn->ptr));
  } else {
    conn->is_open = 1;
  }

  return Qtrue;
}

static VALUE rdo_postgres_connection_close(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);

  PQfinish(conn->ptr);
  conn->ptr     = NULL;
  conn->is_open = 0;

  return Qtrue;
}

static VALUE rdo_postgres_connection_open_p(VALUE self) {
  RDOPostgres * conn;
  Data_Get_Struct(self, RDOPostgres, conn);
  return conn->is_open ? Qtrue : Qfalse;
}

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
}
