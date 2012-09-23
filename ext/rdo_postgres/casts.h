/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>
#include <ruby.h>
#include <libpq-fe.h>

/** Cast the given value from the result to a ruby type */
VALUE rdo_postgres_cast_value(PGresult * res, int row, int col);

/** Initialize the casting framework */
void Init_rdo_postgres_casts(void);
