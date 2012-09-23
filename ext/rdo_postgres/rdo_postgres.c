/*
 * RDO Postgres Driver.
 * Copyright © 2012 Chris Corbyn.
 *
 * See LICENSE file for details.
 */

#include <stdlib.h>
#include <ruby.h>
#include "driver.h"

/**
 * Extension initializer.
 */
void Init_rdo_postgres(void) {
  rb_require("rdo");
  Init_rdo_postgres_driver();
}
