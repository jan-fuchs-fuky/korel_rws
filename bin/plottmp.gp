set term png
set out "plottmp.png"
set title "Input template from korel.tmp"
 plot "korel.tmp" u ((1+5/299792.4562)**$0*6506):1 w l
