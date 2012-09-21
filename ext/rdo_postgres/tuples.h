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
#include <catalog/pg_type.h>

/**
 * Create a new RDO::Postgres::TupleList.
 */
VALUE rdo_postgres_tuple_list_new(PGresult * res);

/**
 * Called during driver initialization to define needed tuple classes.
 */
void Init_rdo_postgres_tuples(void);
