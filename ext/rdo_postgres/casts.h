/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>
#include <ruby.h>
#include <libpq-fe.h>

/** Predicate test if the given string is formatted as \x0afe... */
#define RDO_PG_NEW_HEX_P(s, len) (len >= 2 && s[0] == '\\' && s[1] == 'x')

/** Cast the given value from the result to a ruby type */
VALUE rdo_postgres_cast_value(PGresult * res, int row, int col);

/** Initialize the casting framework */
void Init_rdo_postgres_casts(void);
