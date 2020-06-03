/*-------------------------------------------------------------------------
 *
 * postgres_fdw.c
 *		  Global tables machinery
 *
 * Copyright (c) 2019-2020, Postgres Professional
 *
 * IDENTIFICATION
 *		  contrib/gtables_fdw/gtables_fdw.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "fmgr.h"

PG_MODULE_MAGIC;

void _PG_init(void);

/*
 * Module Load Callback
 */
void
_PG_init(void)
{
}

