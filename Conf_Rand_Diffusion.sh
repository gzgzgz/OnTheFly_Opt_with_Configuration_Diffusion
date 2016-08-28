#!/bin/bash -f

module load vmd
# First we extract out the total number of atoms
atom_no=`wc $1 | awk '{ print $1-3 }'`
fail_flag=0
stepsize=1
threshold=4.0

IFS=.
input_filename=($1)
file_prehead=${input_filename[0]}
unset IFS

# invoke a loop to repeatedly carry out diffusion simulation
for((i=1;i<301;i++))
do
echo "Initiating simulation run #$i ..."
if (($i==1))
then
	obj_filename=$1
else
	obj_filename=${file_prehead}_run${i}.mop
fi

# Let's invoke mopac to optimize the structure

if (( (($fail_flag==0)) || (($i==1)) )) 
then
	~/MOPAC2012/MOPAC2012.exe $obj_filename 
fi

# Now extract final coordinate form mopac output
if (($i==1))
then
	mopac_outfile=${file_prehead}.out
else
	mopac_outfile=${file_prehead}_run${i}.out
fi
# First check if converged
success_mini=`grep "SCF FIELD WAS ACHIEVED" $mopac_outfile`
#success_mini=`grep "GRADIENTS WERE INITIALLY ACCEPTABLY SMALL" $mopac_outfile`
#success_mini=`grep "HERBERTS TEST WAS SATISFIED IN BFGS" $mopac_outfile`

if [[ $success_mini ]]
then
	# Next we look for the updated coordinates
	line=`grep -n "CARTESIAN COORDINATES" $mopac_outfile| awk -F: '{if (NR==2) print $1}' `
	begin_line=$((${line} + 2))
	end_line=$(( $begin_line + $atom_no- 1))
	# Now, we want to reconstruct the input file for the next run
	
	sed -n "$begin_line, $end_line p" $mopac_outfile | awk '{ print $2, $3, $4, $5}'> tmp_${file_prehead}
	runenergy=`grep "FINAL HEAT OF FORMATION" $mopac_outfile | awk '{ print $6 }'`
	if (($i==1))
	then
		prev_energy=$runenergy;
	else
		delta_energy=`echo "((${runenergy})-(${prev_energy}))" | bc`
		delta_flag=`echo "${delta_energy} < 2.0 && ${delta_energy} > -2.0" | bc`
		if (( ${delta_flag}==1 ))
		then
			if (( $fail_flag==0 ))
			then
				echo "Energy unchanged from last cycle, increasing step size to escape..."
					#stepsize=$((${stepsize} * 2))	
					stepsize=$((${stepsize} + 1))
			else	
				if (( $stepsize!=1 ))
				then
					stepsize=$((${stepsize} - 1))
				fi
				fail_flag=0
			fi
		else
			stepsize=1
		fi
		prev_energy=$runenergy;
		
	fi
	echo "$atom_no" >${file_prehead}_run${i}.xyz
	echo "run #$i has energy ${runenergy} Kcal/mol" >> ${file_prehead}_run${i}.xyz
	cat tmp_${file_prehead} >> ${file_prehead}_run${i}.xyz
	# Extract positions of Cl, I and Pb atoms for random move	
	scaling=$2	# the scaling factor

	awk "BEGIN{
        	srand();
		}

		{
        		flag=0;

        		if (\$1 == \"I\") flag=1;
			if (\$1 == \"Cl\") flag=1;
			if (\$1 == \"Pb\") flag=1;


        		if (flag==1) {
                		\$2=\$2+$scaling*(rand()-0.5)/5.0*$stepsize;
                		\$3=\$3+$scaling*(rand()-0.5)/5.0*$stepsize;
                		\$4=\$4+$scaling*(rand()-0.5)/5.0*$stepsize;
        		}

        		print \$1,\$2,\$3,\$4;

		}" tmp_${file_prehead} > tmp2_${file_prehead}
		
	echo "$atom_no" > movtmp_${file_prehead}.xyz
	echo " " >> movtmp_${file_prehead}.xyz
	cat tmp2_${file_prehead} >> movtmp_${file_prehead}.xyz
	cat adjust.tcl | vmd -dispdev text movtmp_${file_prehead}.xyz
	sed -n '3,$ p' adjusted.xyz > tmp2_${file_prehead}
	
	# Write MOPAC input keyword section

	echo "PM7 PL EF CYCLES=2000 ITRY=100 SHIFT=10 GNORM=10" > tmp3_${file_prehead} 
	echo "Current scaling is $(( $scaling * $stepsize ))" >> tmp3_${file_prehead} 
	echo "Current run is #$i" >> tmp3_${file_prehead} 

	run_no=$(($i + 1))
	cat tmp3_${file_prehead} tmp2_${file_prehead} > ${file_prehead}_run${run_no}.mop 
	rm tmp_${file_prehead} tmp2_${file_prehead} tmp3_${file_prehead}
	
else
	#echo "Geometry optimization failed! Check your mopac output!"
	echo "Geometry optimization failed! Rewinding back..."
	# Let's rewind back
	i=$(($i - 2))
	fail_flag=1
	#exit
fi
done

