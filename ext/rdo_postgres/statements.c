/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "statements.h"
#include "driver.h"
#include "params.h"
#include "tuples.h"
#include <libpq-fe.h>
#include <postgres.h>

/** RDO::Postgres::StatementExecutor */
static VALUE rdo_postgres_cStatementExecutor;

/** Struct that the StatementExecutor is wrapped around */
typedef struct {
  char              * stmt_name;
  char              * cmd;
  RDOPostgresDriver * driver;
} RDOPostgresStatementExecutor;

/** Free memory associated with the StatementExecutor during GC */
static void rdo_postgres_statement_executor_free(
    RDOPostgresStatementExecutor * executor) {
  free(executor->stmt_name);
  free(executor->cmd);
  free(executor);
}

/** Extract information about the result into a ruby Hash */
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

#define RDO_PG_NO_OIDS 0
#define RDO_PG_INFER_TYPES NULL
#define RDO_PG_TEXT_INPUT NULL
#define RDO_PG_TEXT_OUTPUT 0

/** Actually issue the PQprepare() command */
static void rdo_postgres_statement_executor_prepare(VALUE self) {
  RDOPostgresStatementExecutor * executor;
  Data_Get_Struct(self, RDOPostgresStatementExecutor, executor);

  if (!(executor->driver->is_open)) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Unable to prepare statement: connection is not open");
  }

  char * cmd = rdo_postgres_params_inject_markers(executor->cmd);

  PGresult * res = PQprepare(
      executor->driver->conn_ptr,
      executor->stmt_name,
      cmd,
      RDO_PG_NO_OIDS,
      RDO_PG_INFER_TYPES);

  free(cmd);

  ExecStatusType status = PQresultStatus(res);

  PQclear(res);

  if (status == PGRES_BAD_RESPONSE || status == PGRES_FATAL_ERROR) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Failed to prepare statement: %s", PQresultErrorMessage(res));
  }
}

/** Factory method to return a new StatementExecutor */
VALUE rdo_postgres_statement_executor_new(VALUE driver, VALUE cmd, VALUE name) {
  Check_Type(cmd,  T_STRING);
  Check_Type(name, T_STRING);

  RDOPostgresStatementExecutor * executor =
    malloc(sizeof(RDOPostgresStatementExecutor));

  Data_Get_Struct(driver, RDOPostgresDriver, executor->driver);
  executor->stmt_name = strdup(RSTRING_PTR(name));
  executor->cmd       = strdup(RSTRING_PTR(cmd));

  VALUE self = Data_Wrap_Struct(rdo_postgres_cStatementExecutor, 0,
      rdo_postgres_statement_executor_free, executor);

  rb_obj_call_init(self, 1, &driver);

  return self;
}

/** Initialize the StatementExecutor with the given driver and command */
static VALUE rdo_postgres_statement_executor_initialize(VALUE self, VALUE driver) {
  rb_iv_set(self, "driver", driver); // make sure GC doesn't swallow it
  rdo_postgres_statement_executor_prepare(self);
  return self;
}

/** Accessor for the @command ivar */
static VALUE rdo_postgres_statement_executor_command(VALUE self) {
  RDOPostgresStatementExecutor * executor;
  Data_Get_Struct(self, RDOPostgresStatementExecutor, executor);
  return rb_str_new2(executor->cmd);
}

/** Execute the prepared statement and return a Result */
static VALUE rdo_postgres_statement_executor_execute(int argc, VALUE * args,
    VALUE self) {

  RDOPostgresStatementExecutor * executor;
  Data_Get_Struct(self, RDOPostgresStatementExecutor, executor);

  if (!(executor->driver->is_open)) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Unable to execute statement: connection is not open");
  }

  char * values[argc];
  int    lengths[argc];

  char * cstr;
  int    i = 0;

  for (; i < argc; ++i) {
    Check_Type(args[i], T_STRING);
    cstr = RSTRING_PTR(args[i]);

    values[i]  = cstr;
    lengths[i] = strlen(cstr);
  }

  PGresult * res = PQexecPrepared(
      executor->driver->conn_ptr,
      executor->stmt_name,
      argc,
      values,
      lengths,
      RDO_PG_TEXT_INPUT,
      RDO_PG_TEXT_OUTPUT);

  ExecStatusType status = PQresultStatus(res);

  if (status == PGRES_BAD_RESPONSE || status == PGRES_FATAL_ERROR) {
    rb_raise(rb_path2class("RDO::Exception"),
        "Failed to execute statement: %s", PQresultErrorMessage(res));
  }

  return rb_funcall(rb_path2class("RDO::Result"),
      rb_intern("new"), 2,
      rdo_postgres_tuple_list_new(res),
      rdo_postgres_result_info_new(res));
}

/** Statements framework initializer, called during extension init */
void Init_rdo_postgres_statements(void) {
  VALUE mPostgres = rb_path2class("RDO::Postgres");

  rdo_postgres_cStatementExecutor = rb_define_class_under(
      mPostgres, "StatementExecutor", rb_cObject);

  rb_define_method(rdo_postgres_cStatementExecutor,
      "initialize", rdo_postgres_statement_executor_initialize, 1);

  rb_define_method(rdo_postgres_cStatementExecutor,
      "command", rdo_postgres_statement_executor_command, 0);

  rb_define_method(rdo_postgres_cStatementExecutor,
      "execute", rdo_postgres_statement_executor_execute, -1);

  Init_rdo_postgres_tuples();
}
