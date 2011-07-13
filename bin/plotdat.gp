set key off
set term png
set out "plotdat.png"
set title "Input Spectra from korel.dat"
lam0=6506
file="korel.d"
#file2="korel.o-c"
dv=5
 plot file  u ((1+dv/299792.4562)**$0*lam0):($1-0.1*column(-2)) w l
# plot file2  u ((1+dv/299792.4562)**$0*lam0):($1-0.1*column(-2)) w l
 
