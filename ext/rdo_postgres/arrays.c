/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include "arrays.h"
#include "casts.h"
#include "macros.h"
#include <ruby.h>
#include <libpq-fe.h>

/** Use to represent state information during a parse */
typedef struct {
  int     encoding;
  VALUE   wrapper;
  VALUE   ary;
  char  * ptr;
  char  * buf;
} RDOPostgresArrayParseContext;

/** Forward-declaration of RDO::Postgres::Array.parse */
static VALUE rdo_postgres_array_parse(VALUE self, VALUE str);

/** Push a sub-array onto the stack */
static void rdo_postgres_array_parse_subarray(VALUE self,
    RDOPostgresArrayParseContext * ctx) {

  rb_ary_push(ctx->ary,
      rdo_postgres_array_parse(self,
        RDO_STRING(ctx->buf, ctx->ptr - ctx->buf, ctx->encoding)));
}

/** Push a value onto the stack */
static void rdo_postgres_array_parse_value(VALUE self,
    RDOPostgresArrayParseContext * ctx) {

  rb_ary_push(ctx->ary,
      rb_funcall(ctx->wrapper,
        rb_intern("parse_value_or_null"), 1,
        RDO_STRING(ctx->buf, ctx->ptr - ctx->buf, ctx->encoding)));
}

/** Parse the given PostgreSQL formatted array String into an Array */
static VALUE rdo_postgres_array_parse(VALUE self, VALUE str) {
  Check_Type(str, T_STRING);

  RDOPostgresArrayParseContext ctx = {
    .encoding = rb_enc_get_index(str),
    .wrapper  = rb_funcall(self, rb_intern("new"), 0),
    .ary      = rb_ary_new(),
    .buf      = malloc(sizeof(char) * RSTRING_LEN(str)),
    .ptr      = NULL
  };

  ctx.ptr = ctx.buf;

  char * cstr   = RSTRING_PTR(str);
  char * s      = cstr;
  int    braces = 0;
  int    quotes = 0;

  for (; *s; ++s) {
    switch (*s) {
      case '{':
        if (quotes) {
          *(ctx.ptr++) = *s;
          break;
        }

        if (braces) // nested brace
          *(ctx.ptr++) = *s;
        ++braces;
        break;

      case '}':
        if (quotes) {
          *(ctx.ptr++) = *s;
          break;
        }

        --braces;
        if (braces) {
          *(ctx.ptr++) = *s;
          if (braces == 1) { // child
            rdo_postgres_array_parse_subarray(self, &ctx);
            ctx.ptr = ctx.buf;
          }
        } else {
          if (ctx.ptr != ctx.buf) { // not empty braces
            rdo_postgres_array_parse_value(self, &ctx);
            ctx.ptr = ctx.buf;
          }
        }
        break;

      case '"':
        quotes = !quotes; // jump in and out of quotes
        *(ctx.ptr++) = *s;
        break;

      case '\\':
        *(ctx.ptr++) = *(s++); // swallow anything after escape
        *(ctx.ptr++) = *s;
        break;

      case ',':
        if (quotes) {
          *(ctx.ptr++) = *s;
          break;
        }

        if (braces > 1) { // still in child
          *(ctx.ptr++) = *s;
        } else {
          if (ctx.ptr != ctx.buf) { // not an outer array
            rdo_postgres_array_parse_value(self, &ctx);
            ctx.ptr = ctx.buf;
          }
        }
        break;

      default:
        *(ctx.ptr++) = *s;
    }
  }

  free(ctx.buf);

  return rb_funcall(ctx.wrapper, rb_intern("replace"), 1, ctx.ary);
}

/** Parse a bytea string into a binary Ruby String */
static VALUE rdo_postgres_array_bytea_parse_value(VALUE self, VALUE s) {
  Check_Type((s = rb_call_super(1, &s)), T_STRING);
  return rdo_postgres_cast_bytea(RSTRING_PTR(s), RSTRING_LEN(s));
}

/** Format a value as a bytea */
static VALUE rdo_postgres_array_bytea_format_value(VALUE self, VALUE v) {
  if (TYPE(v) != T_STRING) {
    v = RDO_OBJ_TO_S(v);
  }

  size_t          len   = 0;
  unsigned char * bytea = PQescapeBytea((unsigned char *) RSTRING_PTR(v),
      RSTRING_LEN(v), &len);

  VALUE escaped   = rb_str_new((char *) bytea, len - 1);
  VALUE formatted = rb_call_super(1, &escaped);

  PQfreemem(bytea);

  return formatted;
}

/** Initialize Array extensions */
void Init_rdo_postgres_arrays(void) {
  VALUE cArray      = rb_path2class("RDO::Postgres::Array");
  VALUE cByteaArray = rb_path2class("RDO::Postgres::Array::Bytea");

  rb_define_singleton_method(cArray, "parse", rdo_postgres_array_parse, 1);

  rb_define_method(cByteaArray,
      "parse_value", rdo_postgres_array_bytea_parse_value, 1);

  rb_define_method(cByteaArray,
      "format_value", rdo_postgres_array_bytea_format_value, 1);
}
