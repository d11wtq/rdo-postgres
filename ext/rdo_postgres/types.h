/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

/*
 * Definitions for types taken from postgres/catalog/pg_type.h.
 *
 * Since not all the types we care about have named defines, they exist here.
 */

// integers
#define RDO_PG_INT2OID 21
#define RDO_PG_INT4OID 23
#define RDO_PG_INT8OID 20

// floats
#define RDO_PG_FLOAT4OID 700
#define RDO_PG_FLOAT8OID 701

// precision decimals
#define RDO_PG_NUMERICOID 1700

// boolean
#define RDO_PG_BOOLOID 16

// bytea
#define RDO_PG_BYTEAOID 17

// dates
#define RDO_PG_DATEOID 1082

// timestamps
#define RDO_PG_TIMESTAMPOID   1114
#define RDO_PG_TIMESTAMPTZOID 1184

// text/char
#define RDO_PG_TEXTOID    25
#define RDO_PG_CHAROID    18
#define RDO_PG_VARCHAROID 1043
#define RDO_PG_BPCHAROID  1042

// text[]/char[]
#define RDO_PG_TEXTARRAYOID    1009
#define RDO_PG_CHARARRAYOID    1002
#define RDO_PG_BPCHARARRAYOID  1014
#define RDO_PG_VARCHARARRAYOID 1015

// integer[]
#define RDO_PG_INT2ARRAYOID 1005
#define RDO_PG_INT4ARRAYOID 1007
#define RDO_PG_INT8ARRAYOID 1016

// float[]
#define RDO_PG_FLOAT4ARRAYOID 1021
#define RDO_PG_FLOAT8ARRAYOID 1022

// numeric[]/decimal[]
#define RDO_PG_NUMERICARRAYOID 1231

// boolean[]
#define RDO_PG_BOOLARRAYOID 1000

// bytea[]
#define RDO_PG_BYTEAARRAYOID 1001

// date[]
#define RDO_PG_DATEARRAYOID 1182

// timestamp[]/timestamptz[]
#define RDO_PG_TIMESTAMPARRAYOID   1115
#define RDO_PG_TIMESTAMPTZARRAYOID 1185
