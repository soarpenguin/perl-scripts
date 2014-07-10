perl -ne 'push(@w, length); END {printf "%0d\n" , (sort({$b <=> $a} @w))[0]}' *.cpp 
