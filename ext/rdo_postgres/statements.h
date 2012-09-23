/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>
#include <ruby.h>

/** Factory to create a new StatementExecutor */
VALUE rdo_postgres_statement_executor_new(VALUE driver, VALUE cmd, VALUE name);

/** Initializer for the statements framework */
void Init_rdo_postgres_statements(void);
