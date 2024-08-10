/*
 * Non-Degree Granting Education License -- for use at non-degree
 * granting, nonprofit, education, and research organizations only. Not
 * for commercial or industrial use.
 *
 * eml_mtimes_helper.h
 *
 * Code generation for function 'eml_mtimes_helper'
 *
 */

#pragma once

/* Include files */
#include "fDIC_xcf_mat_types.h"
#include "rtwtypes.h"
#include "emlrt.h"
#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function Declarations */
void dynamic_size_checks(const emlrtStack *sp, const emxArray_creal_T *a,
                         const emxArray_creal_T *b, int32_T innerDimA,
                         int32_T innerDimB);

/* End of code generation (eml_mtimes_helper.h) */
