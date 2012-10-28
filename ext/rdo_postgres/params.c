/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "params.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

/** Get the strlen of the marker (e.g. $2) based on its index */
#define RDO_PG_MARKER_LEN(n) (n > 0 ? (int) floor(log10(n)) + 2 : 2)

/**
 * Replace e.g. "SELECT ? WHERE ?" with "SELECT $1 WHERE $2".
 *
 * Handles string literals and comments.
 *
 * This function is deliberately not broken apart, since it needs to be extremely fast.
 */
char * rdo_postgres_params_inject_markers(char * stmt) {
  int    len     = strlen(stmt);
  char * buf     = malloc(sizeof(char) * len ? (len * (floor(log10(len)) + 2)) : 0);
  char * s       = stmt;
  char * b       = buf;
  int    n       = 0;
  int    instr   = 0;
  int    inident = 0;
  int    inslcmt = 0;
  int    inmlcmt = 0;

  for (; *s; ++s, ++b) {
    switch (*s) {
      case '/':
        if (!instr && !inident && !inslcmt && *(s + 1) == '*') {
          ++inmlcmt;
          *b = *s;
          *(++b) = *(++s);
        } else {
          *b = *s;
        }
        break;

      case '*':
        if (inmlcmt && *(s + 1) == '/') {
          --inmlcmt;
          *b = *s;
          *(++b) = *(++s);
        } else {
          *b = *s;
        }
        break;

      case '-':
        if (!instr && !inident && !inmlcmt && *(s + 1) == '-') {
          inslcmt = 1;
          *b = *s;
          *(++b) = *(++s);
        } else {
          *b = *s;
        }
        break;

      case '\n':
      case '\r':
        inslcmt = 0;
        *b = *s;
        break;

      case '\'':
        if (!inident && !inmlcmt && !inslcmt) {
          instr = !instr;
          *b = *s;
        } else {
          *b = *s;
        }
        break;

      case '\\':
        if (!instr && !inident && !inmlcmt && !inslcmt && *(s + 1) == '?')
          ++s;

        *b = *s;
        break;

      case '"':
        if (!instr && !inmlcmt && !inslcmt) {
          inident = !inident;
          *b = *s;
        } else {
          *b = *s;
        }
        break;

      case '?':
        if (!instr && !inident && !inmlcmt && !inslcmt) {
          sprintf(b, "$%i", ++n);
          b += RDO_PG_MARKER_LEN(n) - 1;
        } else {
          *b = *s;
        }
        break;

      default:
        *b = *s;
        break;
    }
  }

  *b = '\0';

  return buf;
}
