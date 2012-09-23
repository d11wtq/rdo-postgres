/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <ruby.h>
#include <libpq-fe.h>

/** Struct that RDO::Postgres::Driver wraps */
typedef struct {
  PGconn * conn_ptr;
  int      is_open;
  int      stmt_count;
  int      encoding;
} RDOPostgresDriver;

/** Initializer called during extension init */
void Init_rdo_postgres_driver(void);
