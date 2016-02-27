#---------------------------------------------------------------------------
# tdm_ModalControlZernike.tcl                          tcl script
# (aka zernikeProcs.tcl)
#
# Procedures for computation of the Laplacian of a Zernike series by
# analytical calculation.  Procedures in this file include:
#
#   computeLaplacianOfZernikeSeries
#                       Computes laplacian of an arbitrary function, expressed
#                       as a Zernike series (must initLapZernMatrix prior to
#                       calling).  Computation is done analytically to prevent
#                       spikes in the data.
#
#   initLapZernMatrix   Populates array gLapZernMatrix which allows computation
#                       of Laplacian of an arbitrary Zernike series by a
#                       matrix multiplication.
#
#   lapzNmatrix         Computes laplacian of Zernike polynomial N
#                       (Wavescope OTA) index number N
#
#   divergence          Numerically compute the divergence of a 2-D function.
#
#   decomposeWavefrontIntoZernikeCoeffs
#
#   and others...
#
# version 4
# 7/21/2005
#---------------------------------------------------------------------------
global gLapZernMatrix
global gNumZernikes



#------------------------------------------------------------------------------
# computeLaplacianOfZernikeSeries
#
# Computes coefficients of laplacian of the zernike series specifed by the
# input coefficients.   Computation is based upon analytical computation of
# each Zernike polynomial.  "OTA" Zernikes are assumed in this procedure.
#
# input array refers to a function expressed as a zernike series:
#
#            xi =  sum  Aj * Zj
#
#       del2 xi = sum {j=1, N, Aj del2 Zj }
#               = sum {j=1, N, Sum {i=1,N, Aj Bji Zi } }
#
# where Bji = gLapZernMatrix.  See written notes.
#
# NOTE:  N = gNumZernikes below
#
# NOTE: must run initLapZernMatrix prior to calling this procedure!
#
# parameters:
#       inZCoeffV2       input (wavefront) coefficients, in vector 2 format
#                        <index value>.  Index from 1...N.  Value_i is the
#                        Zernike coefficient corresponding to Wavescope
#                        OTA Zernike i+1.
#
#       ioLapCoeffV2     output (laplacian) coefficients, in vector 2 format
#                        <index value>.  Index from 1...N.  Value_i is the
#                        Zernike coefficient corresponding to Wavescope
#                        OTA Zernike i+1.
#
# called by:
#
# completed. Debugged.
#
# 7/17/2005
#------------------------------------------------------------------------------
proc computeLaplacianOfZernikeSeries {inZCoeffV2 ioLapCoeffV2 } \
{
   global gLapZernMatrix
   global gNumZernikes

   upvar $inZCoeffV2 theWavCoefV2
   upvar $ioLapCoeffV2 theLapCoefV2

   set theNumZernikes $gNumZernikes

   a.v2toxy theWavCoefV2 = theIndex theWavCoefA
   a.v2toxy theLapCoefV2 = theIndex theLapCoefA

   a.cols theIndex = theNCols
   a.tilt theNCols 1 1 = theIndex

   a.make 0 = theSum
   a.make 0 = theSummand

   puts stdout "computeLaplacianOfZernikeSeries:"
   puts stdout "     theWavCoefA: [a.info theWavCoefA]"

   # loop over the columns of gLapZernMatrix
   for { set i 0 } { $i < $theNumZernikes } { incr i } \
   {
      a.extcol gLapZernMatrix $i = theColA

      # matrix multiply input column vector,
      # theWavCoefA, by one row of Laplacian matrix,
      # gLapZernMatrix, to generate one element of the
      # column vector output, theLapCoef.  See notes in
      # initLapZernMatrix procedure for formatting of the
      # laplacian matrix gLapZernMatrix.
      a.mul theSum 0 = theSum
      for { set j 1 } { $j <= $theNumZernikes } { incr j } \
      {
           set theRow [expr $j-1]

           #puts stdout "computeLaplacianOfZernikeSeries: theRow=$theRow"

           a.extele theWavCoefA $theRow = theAj
           a.extele gLapZernMatrix $j $i = theBij
           a.mul theAj theBij = theSummand
           a.add theSummand theSum = theSum
      }
      a.repele theSum theLapCoefA $i = theLapCoefA
   }
   a.xytov2 theIndex theLapCoefA = theLapCoefV2 
}



#---------------------------------------------------------------------------
# initLapZernMatrix
#
# Determines the matrix B, where
#              del2(Zj) = Bjj' Zj'
#
# where Zj is a Zernike polynomial (Wavescope OTA Basis).  This procedure
# populates the gLapZernMatrix as follows:
#
# Columns are matrix elements in equation: del2(zj) = Sum bjj'Zj'
#
# The array has dimension N+1 X N+1 where N = inNumZernikes
#
# Positioning of matrix is as follows:
#   column:
#   0       1       2     3 ...  N
#   ------------------------------
#   matrix:
#   0       b11
#   0       b12
#   0       b13                  bNN
#   0       0       0     0 ...  0
#
# ie. Column 1 = {b11, b12, b13 ... b1N} is the laplacian of z_j=1 etc.
# With this scheme, del2(zj) = sum {i,1..N} B{col=j,row=i-1}*zi
#
# Note:  Zernike j index runs from 1...N.
#
# parameter:  inNumZernikes     Number of Zernikes in the desired expansion.
#                               Also, the dimension of gLapZernMatrix is
#                               inNumZernikes+1
#
#
# 7/17/2005
#---------------------------------------------------------------------------
proc initLapZernMatrix { inNumZernikes } \
{
   global gLapZernMatrix
   global gNumZernikes

   set gNumZernikes $inNumZernikes

   set theFinalArrDim [expr $gNumZernikes+1]
   a.make 0 $theFinalArrDim $gNumZernikes = theTempLapMatrix
   a.make 0 $theFinalArrDim $theFinalArrDim = gLapZernMatrix

   # increase the array size for greater precision in the
   # numerical integrations.  Array size of 15 gave same
   # results for first few zernike coefficients (out to
   # four decimal places) as array size of 51.  Smaller
   # array size will execute faster.
   set theArrSize 15
   set theHalfSize [expr $theArrSize/2.0]

   a.make 0 $theArrSize $theArrSize = theLZj
   for { set j 1 } { $j <= $gNumZernikes } { incr j } \
   {
        lapzNmatrix theLZj $j
        zern.decomp.surf.coefs theLZj \
                               $gNumZernikes \
                               $theHalfSize \
                               $theHalfSize \
                               $theHalfSize \
                               = theLZjCoefsV2
        a.v2toxy theLZjCoefsV2 = theIndex theLZjCoefsA
        a.repcol theLZjCoefsA gLapZernMatrix $j = gLapZernMatrix
   }

}



#---------------------------------------------------------------------------
# lapzNmatrix
#
# Computes the Laplacian of Zernike polynomial "N" and returns the result
# as ioDataF.   Some zernike polynomials have zero Laplacian.  But most
# do not, contrary to popular belief.
#
# This procedure computes the laplacian for Zernikes 1...34.  Other zernikes
# will return a zero array.
#
# parameters:  ioDataF   an NxN floating point (scalar) array.  Defined on
#                        input; on output contains the Laplacian of Zernike
#                        polynomial N.
#
#              N         the Wavescope number of the "OTA" Zernike polynomial
#                        This corresponds approximately to the "j" index for
#                        Zernikes defined in the paper by Noll.  However there
#                        are subtle differences between the wavescope
#                        indexing scheme and the Noll indexing scheme.  Beware.
#
#---------------------------------------------------------------------------
proc lapzNmatrix { ioDataF inN } \
{
   upvar $ioDataF theDataF

   zern.set.type "OTA"
   lapz00matrix theDataF

   if {$inN ==  4 } { lapz04matrix theDataF }
   if {$inN ==  7 } { lapz07matrix theDataF }
   if {$inN ==  8 } { lapz08matrix theDataF }
   if {$inN == 11 } { lapz11matrix theDataF }
   if {$inN == 12 } { lapz12matrix theDataF }
   if {$inN == 13 } { lapz13matrix theDataF }
   if {$inN == 16 } { lapz16matrix theDataF }
   if {$inN == 17 } { lapz17matrix theDataF }
   if {$inN == 18 } { lapz18matrix theDataF }
   if {$inN == 19 } { lapz19matrix theDataF }
   if {$inN == 22 } { lapz22matrix theDataF }
   if {$inN == 23 } { lapz23matrix theDataF }
   if {$inN == 24 } { lapz24matrix theDataF }
   if {$inN == 25 } { lapz25matrix theDataF }
   if {$inN == 26 } { lapz26matrix theDataF }
   if {$inN == 29 } { lapz29matrix theDataF }
   if {$inN == 30 } { lapz30matrix theDataF }
   if {$inN == 31 } { lapz31matrix theDataF }
   if {$inN == 32 } { lapz32matrix theDataF }
   if {$inN == 33 } { lapz33matrix theDataF }
   if {$inN == 34 } { lapz34matrix theDataF }
   if {$inN == 37 } { lapz37matrix theDataF }
   if {$inN == 38 } { lapz38matrix theDataF }
   if {$inN == 39 } { lapz39matrix theDataF }

   
}




#---------------------------------------------------------------------------
# lapz00matrix
#
# Default laplacian matrix.  Sets all elements of the input array to zero.
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz00matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]


   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theValue 0

             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz04matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z4 = 3.4641(r^2-0.5000) (Focus)
#
# lap(Z_04) = 8 sqrt(3)
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
# a.make 0 51 51 = lz
# lapz04matrix lz
# zern.decomp.surf.coefs lz07 42 25.5 25.5 25.5 = lzcoefs
#% zern.conv.string lzcoefs
# Zygo Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   0   13.856406  # 1.0 (Piston)
#   1   -0.000000  # rcos(t) (X Tilt)
#   2   -0.000000  # rsin(t) (Y Tilt)
#   3   -0.000000  # 2r^2-1 (Focus)
#
# These coefs agree with the analytical result.
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz04matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr 8*sqrt(3)]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz07matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z_j=07 = sqrt(8) * ( 3*r^3 - 2r )cos(theta)
#
# lap(Z_07) = 33.9411 * Z_02  = sqrt(8) * 24 r * cos( theta )
#
# NOTE:  This is wavescope Z_7 = Noll Z_8
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
# % a.make 0 51 51 = lz
#ARRAY7751
#% lapz07matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY10353
#% a.dump lzcoefs
# (
#<     1.00000 1.19650e-016>
#<     2.00000      33.9411>
#<     3.00000 -2.31105e-016>
#<     4.00000 -1.65680e-016>
#<     5.00000 -3.48578e-017>
#
# These coefs agree with the analytical result.
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz07matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(8)]
             set theRTerm [expr 24*$theR]
             set theThetaTerm [expr cos($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz08matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z_j=08 = sqrt(8) * ( 3*r^3 - 2r )sin(theta)
#
# lap(Z_08) = 33.9411 * Z_02  = sqrt(8) * 24 r * sin( theta )
#
# NOTE:  This is wavescope Z_8 = Noll Z_7.
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
# a.make 0 51 51 = lz07
# lapz07matrix lz07
# zern.decomp.surf.coefs lz07 42 25.5 25.5 25.5 = lz7coefs
# a.dump lz7coefs
# <     1.00000 -1.14157e-015>
# <     2.00000 -1.35693e-016>
# <     3.00000      33.9411>
# <     4.00000 -2.79412e-017>
# <     5.00000 2.34191e-016>
# <     6.00000 5.48069e-016>
# <     7.00000 6.21300e-017>
# <     8.00000 -8.05443e-008>
#
# These coefs agree with the analytical result.
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz08matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(8)]
             set theRTerm [expr 24*$theR]
             set theThetaTerm [expr sin($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz11matrix
#
# computes a matrix that is the laplacian of zernike 11.  The function
# is computed from analytical formula.
#
# lap(z11) = sqrt(5) * ( 96*r^2 - 24 )   --> = 24 sqrt(5)z1 + 48 sqrt(5/3) z4
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z11
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
#     1.00000      53.6656>
#     2.00000 3.68749e-016>
#     3.00000 -3.99059e-016>
#     4.00000      61.9677>
#     5.00000 -3.24877e-014>
#     6.00000 4.97388e-016>
#     7.00000 -8.52458e-016>
#
# These coefs agree with the analytical result.
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz11matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]

             set theRTerm [expr 96*pow($theR,2) - 24]
             set theCoef [expr sqrt(5)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theCoef * $theRTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz12matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
# z12 = 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
# lap(Z_12) = sqrt(10) * 48 r^2 * cos( 2 theta )
#
#           = 61.9677 * Z_5    Note: Wavescope Z_5 = Noll Z_6 !!!
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz12matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY12955
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4    0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   61.967731  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz12matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(10)]
             set theRTerm [expr 48*$theR*$theR]
             set theThetaTerm [expr cos(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}




#---------------------------------------------------------------------------
# lapz13matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
# z13 = 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
# lap(Z13) = sqrt(10) * 48 r^2 * sint(2t)
#
#           = 61.9677 * Z_6    Note: Wavescope Z_6 = Noll Z_5 !!!
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
# % a.make 0 51 51 = lz
#ARRAY7751
#% lapz13matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY18159
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   61.967735  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#
# These coefs agree with the analytical result.
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz13matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(10)]
             set theRTerm [expr 48*$theR*$theR]
             set theThetaTerm [expr sin(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}

#---------------------------------------------------------------------------
# lapz16matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z16 = 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
# lap(Z_16) = sqrt(12) * 48 (5r^3-2r) * cos(t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz16matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY20761
#% zern.conv.string lzcoefs
## OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2  110.851250  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5    0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   97.979591  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9    0.000000  # 2.8284r^3cos(3t) (X Clover)
#
#
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz16matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(12)]
             set theRTerm [expr 48*(5*$theR*$theR*$theR - 2*$theR)]
             set theThetaTerm [expr cos($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz17matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z17=34.6410(r^5-1.2000r^3+0.3000r)sin(t)
# lap(Z_17) = sqrt(12) * 48 (5r^3-2r) * sin(t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz17matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY23363
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3  110.851250  # 2.0000rsin(t) (Y Tilt)
#   4    0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   97.979591  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz17matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(12)]
             set theRTerm [expr 48*(5*$theR*$theR*$theR - 2*$theR)]
             set theThetaTerm [expr sin($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}





#---------------------------------------------------------------------------
# lapz18matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# 17.3205(r^5-0.8000r^3)cos(3t)
# lap(Z_18) = sqrt(12) * 80 r^3cos(3t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz18matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY25965
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4    0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   97.979591  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz18matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(12)]
             set theRTerm [expr 80*($theR*$theR*$theR)]
             set theThetaTerm [expr cos(3*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz19matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# 17.3205(r^5-0.8000r^3)sin(3t)
# lap(Z_18) = sqrt(12) * 80 r^3sin(3t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz19matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY28567
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2   -0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9    0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   97.979591  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz19matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(12)]
             set theRTerm [expr 80*($theR*$theR*$theR)]
             set theThetaTerm [expr sin(3*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz22matrix
#
# computes a matrix that is the laplacian of zernike 22.  The function
# is computed from analytical formula.
#
# lap z22 = 127.0 z1 + 183.3 z4 + 142.0 z11
#
# Above equation was determined using this script to generate data for
# lap z22 and then using wavescope scripts to decompose the output into
# a zernike series, e.g.:
#
#       % a.make 0 51 51 = lz22
#       % lapz22matrix lz22
#       % zern.decomp.surf.coefs lz22 35 25.5 25.5 25.5 = lz22coefs
#       % a.dump lz22coefs
#
# (output)
#     1.00000      126.996>
#     2.00000 4.56965e-017>
#     3.00000 -9.27624e-016>
#     4.00000      183.303>
#     5.00000 -1.04640e-013>
#     6.00000 -2.03904e-015>
#     7.00000 -3.97550e-016>
#     8.00000 -9.94548e-015>
#     9.00000 -3.22081e-015>
#     10.0000 4.76827e-016>
#     11.0000      141.986>
#     12.0000 -4.24598e-014>
#     13.0000 -2.03995e-015>
#
#
# 7/8/2005
#---------------------------------------------------------------------------
proc lapz22matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]

             set theRTerm [expr 15*pow($theR,4) - 10*pow($theR,2) + 1]
             set theCoef [expr 48*sqrt(7)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theCoef * $theRTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}





#---------------------------------------------------------------------------
# lapz23matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z23=56.1249(r^6-1.3333r^4+0.4000r^2)cos(2t)
# lap(Z_23) = sqrt(14) * 240 (2r^4-r^2)cos(2t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz23matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY31169
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5  183.303024  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12  141.985916  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz23matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(14)]
             set theRTerm [expr 240*(2*$theR*$theR*$theR*$theR-$theR*$theR)]
             set theThetaTerm [expr cos(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz24matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z24=56.1249(r^6-1.3333r^4+0.4000r^2)sin(2t)
# lap(Z_24) = sqrt(14) * 240 (2r^4-r^2)sin(2t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz24matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY33771
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2   -0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5    0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6  183.303024  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13  141.985916  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14   -0.000000  # 3.1623r^4cos(4t) (Ashtray)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz24matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(14)]
             set theRTerm [expr 240*(2*$theR*$theR*$theR*$theR-$theR*$theR)]
             set theThetaTerm [expr sin(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz25matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z25=22.4499(r^6-0.8333r^4)cos(4t)
# lap(Z_25) = sqrt(14) * 240 r^4cos(4t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz25matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY36373
#% zern.conv.string lzcoefs
## OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000001  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000001  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9    0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14  567.943665  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz25matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(14)]
             set theRTerm [expr 240*(2*$theR*$theR*$theR*$theR)]
             set theThetaTerm [expr cos(4*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz26matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z26=22.4499(r^6-0.8333r^4)sin(4t)
# lap(Z_26) = sqrt(14) * 240 r^4sin(4t)
#
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz26matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY38975
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4    0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13   -0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14   -0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15  567.943665  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz26matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(14)]
             set theRTerm [expr 240*(2*$theR*$theR*$theR*$theR)]
             set theThetaTerm [expr sin(4*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}




#---------------------------------------------------------------------------
# lapz29matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z29=140.0000(r^7-1.7143r^5+0.8571r^3-0.1143r)cos(t)
# lap(Z_29) = sqrt(16) * 240 (7r^5-6r^3+r)cos(t)
#
# NOTE:  wavescope z29 = Noll z30.  This routine uses wavescope z29.
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz29matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY41577
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2  240.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7  271.528992  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000001  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16  193.989685  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz29matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 240*(7*pow($theR,5)-6*pow($theR,3)+$theR)]
             set theThetaTerm [expr cos($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz30matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z30=140.0000(r^7-1.7143r^5+0.8571r^3-0.1143r)sin(t)
# lap(Z_30) = sqrt(16) * 240 (7r^5-6r^3+r)sin(t)
#
# NOTE:  wavescope z30 = Noll z29.  This routine uses wavescope z30.
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz30matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY44179
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2   -0.000000  # 2.0000rcos(t) (X Tilt)
#   3  240.000000  # 2.0000rsin(t) (Y Tilt)
#   4    0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8  271.528992  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000001  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13   -0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17  193.989685  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19    0.000001  # 17.3205(r^5-0.8000r^3)sin(3t)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz30matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 240*(7*pow($theR,5)-6*pow($theR,3)+$theR)]
             set theThetaTerm [expr sin($theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz31matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z31=84.0000(r^7-1.4286r^5+0.4762r^3)cos(3t)
# lap(Z_31) = sqrt(16) * 120 (7r^5-4r^3)cos(3t)
#
# NOTE:  wavescope z31 = Noll z32.  This procedure uses wavescope z31
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz31matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY46781
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2   -0.000001  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000001  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9  543.057983  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13   -0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14   -0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15    0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18  387.979370  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19   -0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20   -0.000002  # 3.4641r^5cos(5t)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz31matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 240*(7*pow($theR,5)-4*pow($theR,3))]
             set theThetaTerm [expr cos(3*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


#---------------------------------------------------------------------------
# lapz32matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z32=84.0000(r^7-1.4286r^5+0.4762r^3)sin(3t)
# lap(Z_32) = sqrt(16) * 120 (7r^5-4r^3)sin(3t)
#
# NOTE:  wavescope z32= Noll z31.  This procedure uses wavescope z32
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz32matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY49383
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000001  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5    0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000001  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9    0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10  543.057983  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13   -0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14   -0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15    0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19  387.979370  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20   -0.000000  # 3.4641r^5cos(5t)
#  21    0.000002  # 3.4641r^5sin(5t)
#
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz32matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 240*(7*pow($theR,5)-4*pow($theR,3))]
             set theThetaTerm [expr sin(3*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}




#---------------------------------------------------------------------------
# lapz33matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z33=28.0000(r^7-0.8571r^5)cos(5t)
# lap(Z_33) = sqrt(16) * 168 (r^5)cos(5t)
#
# NOTE:  wavescope z33= Noll z34.  This procedure uses wavescope z33
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz33matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY51985
#% zern.conv.string lzcoefs
## OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2   -0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5    0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19   -0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20  193.989685  # 3.4641r^5cos(5t)
#  21    0.000000  # 3.4641r^5sin(5t)
#  22    0.000000  # 52.9150(r^6-1.5000r^4+0.6000r^2-0.0500) (5th Order Spherical)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz33matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 168*(pow($theR,5))]
             set theThetaTerm [expr cos(5*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}





#---------------------------------------------------------------------------
# lapz34matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z34=28.0000(r^7-0.8571r^5)sin(5t)
# lap(Z_33) = sqrt(16) * 168 (r^5)sin(5t)
#
# NOTE:  wavescope z34= Noll z33.  This procedure uses wavescope z34
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
# zern.set.type "OTA"
#% lapz34matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY54587
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2   -0.000000  # 2.0000rcos(t) (X Tilt)
#   3   -0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6   -0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8    0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12    0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14   -0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15    0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19    0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20   -0.000000  # 3.4641r^5cos(5t)
#  21  193.989685  # 3.4641r^5sin(5t)
#  22   -0.000000  # 52.9150(r^6-1.5000r^4+0.6000r^2-0.0500) (5th Order Spherical)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz34matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(16)]
             set theRTerm [expr 168*(pow($theR,5))]
             set theThetaTerm [expr sin(5*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz37matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z37=210.0000(r^8-2.0000r^6+1.2857r^4-0.2857r^2+0.0143)
# lap(Z_37) = sqrt(2)*240*(56r^6-63r^4+18r^2-1)
#
# NOTE:  wavescope z34= Noll z33.  This procedure uses wavescope z34
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
#% zern.set.type "OTA"
#OTA
#% a.make 0 51 51 = lz
#ARRAY2604
#% lapz37matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY5206
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1  339.411255  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4  529.089783  # 3.4641(r^2-0.5000) (Focus)
#   5   -0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10    0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11  531.262634  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13   -0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000001  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18    0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19    0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20   -0.000000  # 3.4641r^5cos(5t)
#  21    0.000000  # 3.4641r^5sin(5t)
#  22  359.199097  # 52.9150(r^6-1.5000r^4+0.6000r^2-0.0500) (5th Order Spherical)
#  23    0.000000  # 56.1249(r^6-1.3333r^4+0.4000r^2)cos(2t)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz37matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(2)]
             set theRTerm \
                [expr 240*(56*pow($theR,6)-63*pow($theR,4)+18*pow($theR,2)-1)]
             set theThetaTerm 1

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz38matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z38=237.5879(r^8-1.8750r^6+1.0714r^4-0.1786r^2)cos(2t)
# lap(Z_38) = sqrt(2)*3*240*(14r^6-63r^4+3r^2)cos(2t)
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
#% zern.set.type "OTA"
#OTA
#% a.make 0 51 51 = lz
#ARRAY5207
#% lapz38matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY7809
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1    0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5  374.122986  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6    0.000000  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7    0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9   -0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11    0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12  375.659424  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13    0.000000  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15   -0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16   -0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19    0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20    0.000000  # 3.4641r^5cos(5t)
#  21   -0.000000  # 3.4641r^5sin(5t)
#  22    0.000000  # 52.9150(r^6-1.5000r^4+0.6000r^2-0.0500) (5th Order Spherical)
#  23  253.992126  # 56.1249(r^6-1.3333r^4+0.4000r^2)cos(2t)
#  24   -0.000000  # 56.1249(r^6-1.3333r^4+0.4000r^2)sin(2t)
#  25    0.000000  # 22.4499(r^6-0.8333r^4)cos(4t)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz38matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(2)]
             set theRTerm \
                [expr 3*240*(14*pow($theR,6)-14*pow($theR,4)+3*pow($theR,2))]
             set theThetaTerm [expr cos(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}



#---------------------------------------------------------------------------
# lapz39matrix
#
# computes a matrix that is the laplacian of zernike 07.  The function
# is computed from analytical formula.
#
# z39=237.5879(r^8-1.8750r^6+1.0714r^4-0.1786r^2)sin(2t)
# lap(Z_39) = sqrt(2)*3*240*(14r^6-63r^4+3r^2)sin(2t)
#
#
# results of testing:  when zern.decomp.surf.coefs is used to decompose
# the output of this procedure, the following output results (for z07
# a 51x51 array; center col, center row, pupil rad. = 25.5):
#
# (example wish session)
#% zern.set.type "OTA"
#OTA
#% a.make 0 51 51 = lz
#ARRAY7810
#% lapz39matrix lz
#% zern.decomp.surf.coefs lz 42 25.5 25.5 25.5 = lzcoefs
#ARRAY10412
#% zern.conv.string lzcoefs
# OTA_Obscured Zernike Coefficients
# Obscuration Ratio = 0.0000
#Index Coefs(microns) Equation
#   1   -0.000000  # 1.0 (Piston)
#   2    0.000000  # 2.0000rcos(t) (X Tilt)
#   3    0.000000  # 2.0000rsin(t) (Y Tilt)
#   4   -0.000000  # 3.4641(r^2-0.5000) (Focus)
#   5    0.000000  # 2.4495r^2cos(2t) (0 Astigmatism)
#   6  374.122986  # 2.4495r^2sin(2t) (45 Astigmatism)
#   7   -0.000000  # 8.4853(r^3-0.6667r)cos(t) (X Coma)
#   8   -0.000000  # 8.4853(r^3-0.6667r)sin(t) (Y Coma)
#   9    0.000000  # 2.8284r^3cos(3t) (X Clover)
#  10   -0.000000  # 2.8284r^3sin(3t) (Y Clover)
#  11   -0.000000  # 13.4164(r^4-1.0000r^2+0.1667) (Spherical)
#  12   -0.000000  # 12.6491(r^4-0.7500r^2)cos(2t) (Sphere Astigmatism)
#  13  375.659424  # 12.6491(r^4-0.7500r^2)sin(2t) (Sphere Astigmatism)
#  14    0.000000  # 3.1623r^4cos(4t) (Ashtray)
#  15    0.000000  # 3.1623r^4sin(4t) (Ashtray)
#  16    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)cos(t)
#  17    0.000000  # 34.6410(r^5-1.2000r^3+0.3000r)sin(t)
#  18   -0.000000  # 17.3205(r^5-0.8000r^3)cos(3t)
#  19    0.000000  # 17.3205(r^5-0.8000r^3)sin(3t)
#  20    0.000000  # 3.4641r^5cos(5t)
#  21    0.000000  # 3.4641r^5sin(5t)
#  22    0.000000  # 52.9150(r^6-1.5000r^4+0.6000r^2-0.0500) (5th Order Spherical)
#  23   -0.000000  # 56.1249(r^6-1.3333r^4+0.4000r^2)cos(2t)
#  24  253.992126  # 56.1249(r^6-1.3333r^4+0.4000r^2)sin(2t)
#  25   -0.000000  # 22.4499(r^6-0.8333r^4)cos(4t)
#  26    0.000000  # 22.4499(r^6-0.8333r^4)sin(4t)
#
# parameters:
#       ioDataF         2D array of float data.  Ideally, the array should
#                       have an odd number of rows/cols.  Laplacian of Z11
#                       is stored in this array on output.
#
# 7/17/2005
#---------------------------------------------------------------------------
proc lapz39matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             if { $theX == 0 && $theY == 0 } \
             {
                  set theTheta 0
             } else \
             {
                  set theTheta [expr atan2($theY,$theX)]
             }

             set theNorm [expr sqrt(2)]
             set theRTerm \
                [expr 3*240*(14*pow($theR,6)-14*pow($theR,4)+3*pow($theR,2))]
             set theThetaTerm [expr sin(2*$theTheta)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theNorm * $theRTerm * $theThetaTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}






#---------------------------------------------------------------------------
# zXXmatrix
#
# computes a matrix that is the laplacian of zernike 22.  The function
# is computed from analytical formula.
#
# 7/8/2005
#---------------------------------------------------------------------------
proc zXXmatrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]

             set theRTerm [expr 15*pow($theR,4) - 10*pow($theR,3) + $theR]
             set theCoef [expr 48*sqrt(7)]

             if { $theR < 1.0 } \
             {
                  set theValue [expr $theCoef * $theRTerm]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}




#---------------------------------------------------------------------------
# proc divergence                             tcl script
#
# from tdm_ModalControlTraining_v8.tcl
#
# Takes the divergence of the input data.  Used for computing the
# laplacian of the wavefront.  Based on calcLap in dm_panels_5dms.tcl
#
# called by:  computeWavefrontAndLaplacianByWavescopeMethod
#
# completed.  Needs debugging.
# 6/28/2005
#---------------------------------------------------------------------------
proc divergence { inVectV2 outDivF } \
{

    upvar $inVectV2 theVect
    upvar $outDivF theDiv

    a.v2toxy theVect = xg yg
    a.grad xg = dxg
    a.v2toxy dxg = dxx dxy
    a.grad yg = dyg
    a.v2toxy dyg = dyx dyy

    a.add dxx dyy = theDiv
}







#------------------------------------------------------------------------------
# decomposeWavefrontIntoZernikeCoeffs
#
# parameters: inGradV4       vector 4 array of wavefront position & gradients
#                            these data are from the wavefront sensor, for
#                            example as set by calcGrad
#                            < xi  yi   dxi   dyi >
#
#             inPupilF       Floating point array of three values:
#                            Center Column [pix], Center Row [pix],
#                            Pupil Radius [pix].  e.g. wlCalibrate(Pupil)
#
#             ioCoefsV2      Vector 2 array of Zernike coefficients:
#                            <index Coeff.>
# called by:
#
# Completed.  Debugged with wavescope generated zernikes only (not verified
# with actual wfs data).  See TestDecomposeWavefrontProcedure_wish_session_
# 07-07-2005.txt
#
# version 2
# plk 7/7/2005
#------------------------------------------------------------------------------
proc decomposeWavefrontIntoZernikeCoeffs { inGradV4 inPupilF ioCoefsV2 } \
{

   upvar $inGradV4 theGradV4
   upvar $inPupilF thePupilF
   upvar *ioCoefsV2 theCoefsV2

   set theCenterColumn [a.extele thePupilF 0]
   set theCenterRow [a.extele thePupilF 1]
   set thePupilRadius_pix [a.extele thePupilF 2]


   set theNumberOfZernikeTerms $gNumZernikes



   # DEBUG
   # typical values (determined during WFS calibration)
   # CenterRow         242.88
   # CenterCol         358.34
   # Radius (pix)      240
   # plk 5/2/2005

   puts "theCenterRow        = $theCenterRow"
   puts "theCenterColumn     = $theCenterColumn"
   puts "thePupilRadius_pix  = $thePupilRadius_pix"



   # wavefront gradients stored in Grad array (v4), which is
   # populated during a WFS measurment called by calcGrad
   zern.decomp.grad.coefs theGradV4 \
                          $theNumberOfZernikeTerms \
                          $theCenterColumn \
                          $theCenterRow \
                          $thePupilRadius_pix \
                          = theCoeffsV2


   # DEBUG
   # convert the coeffs. to strings, and print...
   zern.conv.string theCoeffsV2


}




#------------------------------------------------------------------------------
# computeLapFromZernikeSeries                  OLD PROCEDURE.  NOT IN USE.
#                                                 INCORRECT CALCULATION
#                                                     OF LAPLACIAN!
#
# Computes coefficients of laplacian of the zernike series specifed by the
# input coefficients.   Computation is based upon analytical computation of
# each Zernike polynomial.  "OTA" Zernikes are assumed in this procedure.
#
# input array refers to a function expressed as a zernike series:
#
#            xi =  sum  Aj * Zj
#
# Laplacian is computed term by term, using the fact that most zernikes have
# zero laplacian (except for Z4, Z11, Z22 ... )
#
#       del2 xi =  sum Aj * del2 Zj  = sum  Lj Zj    {j=4,11,22...}
#
#
# NOTE: BUG in wavescope software -- zern.set.coef re-numbers the indices
# of a V2 zernike array if they are indexed from 1...N, so that they are
# numbered 0...N-1.  OTA zernikes are not indexed from 0...N-1, so that
# subsequent calls to zernike procedures will have errors.  zern.get.coef
# also appears to re-number the zernike array index values to 0...N-1.
#
#
# NOTE:  N = theNumZernikeTerms below
#
# parameters:
#       inZCoeffV2       input (wavefront) coefficients, in vector 2 format
#                        <index value>.  Index from 1...N
#
#       ioLapCoeffV2     output (laplacian) coefficients, in vector 2 format
#                        <index value>.  Index from 1...N
#
# called by:
#
# completed. Debugged.
#
# 7/8/2005
#------------------------------------------------------------------------------
proc computeLapFromZernikeSeries {inZCoeffV2 ioLapCoeffV2 } \
{
   upvar $inZCoeffV2 theWavCoeffV2
   upvar $ioLapCoeffV2 theLapCoeffV2

   set theNumZernikeTerms 35

   # extract coeff. for z=4 zernike
   a.extele theWavCoeffV2 3 = theWavA4V2
   a.v2toxy theWavA4V2 = i theWavA4A
   set theWavA4 [a.dump theWavA4A]

   # extract coeff. for z = 11 zernike
   a.extele theWavCoeffV2 10 = theWavA11V2
   a.v2toxy theWavA11V2 = i theWavA11A
   set theWavA11 [a.dump theWavA11A]

   # extract coeff. for z = 22 zernike
   a.extele theWavCoeffV2 21 = theWavA22V2
   a.v2toxy theWavA22V2 = i theWavA22A
   set theWavA22 [a.dump theWavA22A]


   # these constants determined from analytical differentiation
   # of zernike polynomials (C1...C3) or numerical calculation
   # using wavescope atomic functions (C4...C6).
   set C1 [expr 8*sqrt(3)]
   set C2 [expr 24*sqrt(5)]
   set C3 [expr 48*sqrt(1.666667)]
   set C4 127.0
   set C5 183.3
   set C6 142.0

   set theLapA1 [expr $C1*$theWavA4 + $C2*$theWavA11 + $C4*$theWavA22]
   set theLapA4 [expr $C3*$theWavA11 + $C5*$theWavA22]
   set theLapA11 [expr $C6*$theWavA22]


   # problem with this code:  cannot replace the coefficient
   # of theLapCoeffV2 array with the right value.  Code is
   # not reading the values of the input array.
   #
   # zern.get.coef above is setting values to 0.  Use a.extele
   # to extract array instead?  Problem with zernikes using
   # non-consecutive indices?

   a.tilt $theNumZernikeTerms 1 1 = theIndex
   a.make 0 $theNumZernikeTerms = theValue
   a.xytov2 theIndex theValue = theLapCoeffV2
   a.repele "<1 $theLapA1>" theLapCoeffV2 0 = theLapCoeffV2
   a.repele "<4 $theLapA4>" theLapCoeffV2 3 = theLapCoeffV2
   a.repele "<11 $theLapA11>" theLapCoeffV2 10 = theLapCoeffV2


}




proc z4matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             #set theTheta [expr atan2($theY,$theX)]
             if { $theR < 1.0 } \
             {
                  set theValue [expr 3.464*($theR*$theR - 0.5)]
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


proc x2matrix { ioDataF } \
{
   upvar $ioDataF theDataF

   set theNumCols [a.cols theDataF]
   set theNumRows [a.rows theDataF]

   set theCentCol [expr $theNumCols/2]
   set theCentRow [expr $theNumRows/2]

   set thePupilRadius $theNumCols
   for { set i 0 } { $i < $theNumCols } { incr i } \
   {
        for { set j 0 } { $j < $theNumRows } { incr j } \
        {
             set theX [expr 2.0*($i - $theCentCol)/$thePupilRadius]
             set theY [expr 2.0*($j - $theCentRow)/$thePupilRadius]

             set theX2 [expr $theX * $theX]
             set theY2 [expr $theY * $theY]
             set theR2 [expr $theX2 + $theY2]
             set theR [expr sqrt($theR2)]
             #set theTheta [expr atan2($theY,$theX)]
             if { $theR < 1.0 } \
             {
                  set theValue $theX2
             } else \
             {
                  set theValue 0
             }
             a.repele $theValue theDataF $i $j = theDataF
        }
   }
}


