//---------------------------------------------------------------------------
// NumRecipes.h                                             C header file
//
//---------------------------------------------------------------------------

extern "C" double **dmatrix(int nrl, int nrh, int ncl, int nch);
extern "C" double *dvector(int nl,int nh);
extern "C" void free_dmatrix(double **m, int nrl, int nrh, int ncl, int nch);
extern "C" void free_dvector(double *v, int nl, int nh);
extern "C" void nrerror(char *error_text);
extern "C" void tridagd(double *a,
                        double *b,
                        double *c,
                        double *r,
                        double *u,
                        int     n);

extern "C" void adi(double **a,
                    double **b,
                    double **c,
                    double **d,
                    double **e,
                    double **f,
                    double **g,
                    double **u,
                    int   jmax,
                    int      k,
                    double alpha,
                    double  beta,
                    double   eps);

 