/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdio.h>

/**
 * Make a copy of the string sql, replacing '?' markers with numbered $1, $2 etc.
 *
 * Memory must be released with free() once the new string is no longer in use.
 */
char * rdo_postgres_params_inject_markers(char * sql);
