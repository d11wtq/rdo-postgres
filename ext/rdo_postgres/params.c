/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "params.h"
#include <string.h>

/** Get the strlen of the marker (e.g. $2) based on its index */
#define RDO_PG_MARKER_LEN(n) (n >= 100 ? 4 : (n >= 10 ? 3 : 2))

/** Replace e.g. "SELECT ? WHERE ?" with "SELECT $1 WHERE $2" */
char * rdo_postgres_params_inject_markers(char * stmt) {
  char * buf  = malloc(sizeof(char) * strlen(stmt) * 4);
  char * s    = stmt;
  char * b    = buf;
  int    n    = 0;

  for (; *s; ++s, ++b) {
    switch (*s) {
      case '?':
        sprintf(b, "$%i", ++n);
        b += RDO_PG_MARKER_LEN(n -1) - 1;
        break;

      default:
        *b = *s;
        break;
    }
  }

  *b = '\0';

  return buf;
}
