/*
 * Non-Degree Granting Education License -- for use at non-degree
 * granting, nonprofit, education, and research organizations only. Not
 * for commercial or industrial use.
 *
 * fDIC_xcf_mat.h
 *
 * Code generation for function 'fDIC_xcf_mat'
 *
 */

#ifndef FDIC_XCF_MAT_H
#define FDIC_XCF_MAT_H

/* Include files */
#include "fDIC_xcf_mat_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void fDIC_xcf_mat(const emxArray_real_T *Image_ref,
                         const emxArray_real_T *Image_test,
                         const struct0_T *ROI, const double Filters_setting[4],
                         double XCF_mesh, const emxArray_real_T *hfilter,
                         const emxArray_real_T *FFTfilter,
                         emxArray_real_T *Shift_X, emxArray_real_T *Shift_Y,
                         emxArray_real_T *CCmax);

#ifdef __cplusplus
}
#endif

#endif
/* End of code generation (fDIC_xcf_mat.h) */
