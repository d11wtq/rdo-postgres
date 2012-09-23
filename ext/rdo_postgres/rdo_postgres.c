/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>
#include <ruby.h>
#include <libpq-fe.h>
#include <postgres.h>

#include "macros.h"
#include "driver.h"
#include "statements.h"

/** During GC, free any stranded connection */
static void rdo_postgres_driver_free(RDOPostgresDriver * driver) {
  PQfinish(driver->conn_ptr);
  free(driver);
}

/** Postgres outputs notices (e.g. auto-generating sequence...) unless overridden */
static void rdo_postgres_driver_notice_processor(void * arg, const char * msg) {}

/** Allocate memory for the connection struct */
static VALUE rdo_postgres_driver_allocate(VALUE klass) {
  RDOPostgresDriver * driver = malloc(sizeof(RDOPostgresDriver));

  driver->conn_ptr   = NULL;
  driver->is_open    = 0;
  driver->stmt_count = 0;

  VALUE self = Data_Wrap_Struct(klass, 0,
      rdo_postgres_driver_free, driver);

  return self;
}

/** Connect to the postgres server */
static VALUE rdo_postgres_driver_open(VALUE self) {
  RDOPostgresDriver * driver;
  Data_Get_Struct(self, RDOPostgresDriver, driver);

  if (driver->is_open) {
    return Qtrue;
  }

  driver->conn_ptr = PQconnectdb(
      RSTRING_PTR(rb_funcall(self, rb_intern("connect_db_string"), 0)));

  if (driver->conn_ptr == NULL || PQstatus(driver->conn_ptr) == CONNECTION_BAD) {
    rb_raise(rb_path2class("RDO::Exception"),
        "PostgreSQL connection failed: %s",
        PQerrorMessage(driver->conn_ptr));
  } else if (PQprotocolVersion(driver->conn_ptr) < 3) {
    rb_raise(rb_path2class("RDO::Exception"),
        "rdo-postgres requires PostgreSQL protocol version >= 3 (using %u). "
        "PostgreSQL >= 7.4 required.",
        PQprotocolVersion(driver->conn_ptr));
  } else {
    PQsetNoticeProcessor(driver->conn_ptr, &rdo_postgres_driver_notice_processor, NULL);
    driver->is_open    = 1;
    driver->stmt_count = 0;
    rb_funcall(self, rb_intern("set_time_zone"), 0);
  }

  return Qtrue;
}

/** Disconnect from the postgres server, and release memory */
static VALUE rdo_postgres_driver_close(VALUE self) {
  RDOPostgresDriver * driver;
  Data_Get_Struct(self, RDOPostgresDriver, driver);

  PQfinish(driver->conn_ptr);
  driver->conn_ptr   = NULL;
  driver->is_open    = 0;
  driver->stmt_count = 0;

  return Qtrue;
}

/** Preciate test if connection is open */
static VALUE rdo_postgres_driver_open_p(VALUE self) {
  RDOPostgresDriver * driver;
  Data_Get_Struct(self, RDOPostgresDriver, driver);
  return driver->is_open ? Qtrue : Qfalse;
}

/** Prepare a statement for execution */
static VALUE rdo_postgres_driver_prepare(VALUE self, VALUE cmd) {
  Check_Type(cmd, T_STRING);

  RDOPostgresDriver * driver;
  Data_Get_Struct(self, RDOPostgresDriver, driver);

  if (!(driver->is_open)) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Unable to prepare statement: connection is not open");
  }

  char name[32];
  sprintf(name, "rdo_stmt_%i", ++driver->stmt_count);

  return RDO_STATEMENT(rdo_postgres_statement_executor_new(
        self, cmd, rb_str_new2(name)));
}

/**
 * Extension initializer.
 */
void Init_rdo_postgres(void) {
  rb_require("rdo");
  rb_require("rdo/postgres/driver");

  VALUE cPostgresConnection = rb_path2class("RDO::Postgres::Driver");

  rb_define_alloc_func(
      cPostgresConnection,
      rdo_postgres_driver_allocate);

  rb_define_method(
      cPostgresConnection,
      "open", rdo_postgres_driver_open, 0);

  rb_define_method(
      cPostgresConnection,
      "close", rdo_postgres_driver_close, 0);

  rb_define_method(
      cPostgresConnection,
      "open?", rdo_postgres_driver_open_p, 0);

  rb_define_method(
      cPostgresConnection,
      "prepare", rdo_postgres_driver_prepare, 1);

  Init_rdo_postgres_statements();
}
