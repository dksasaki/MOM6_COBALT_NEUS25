#!/bin/bash
#SBATCH -J NWA25_NEUS_bp
#SBATCH --error=NWA25_NEUS.err
#SBATCH --output=NWA25_NEUS.out
#SBATCH --time=08:00:00
#SBATCH --partition=short
#SBATCH --mem=32G
#SBATCH --constrain=ib

ntasks=$SLURM_NTASKS 
njobs=400

#-------------------------------- system settings ----- ---------------------------

#export UCX_NET_DEVICES=mlx5_0:1

source intel.env






sleep 10
# setup the run directory
if [ ! -d RESTART ] ; then mkdir RESTART ; fi
if [ ! -d outputs_raw ] ; then mkdir outputs_raw ; fi
if [ ! -d restarts_raw ] ; then mkdir restarts_raw ; fi
if [ ! -d logs ] ; then mkdir logs ; fi

#--------------------------------- prepare input files ---------------------------

ctrldir=$( pwd )
subscript="mom.sub.x"
subscript_args="--ntasks=$ntasks"

cd configs
ln -sf MOM_layout.$ntasks MOM_layout
cd ..

if [ ! -f jobscompleted ] ; then touch jobscompleted ; fi

lastjob=$( tail -1 jobscompleted )
thisjob=$(( $lastjob + 1 )) # if file empty, takes job number one

echo 'starting job #' $thisjob

# at first job, replace restart by cold start
if [[ $thisjob == 1 ]] ; then
sed -i -e "s/input_filename = 'r'/input_filename = 'n'/g" input.nml
# at second job, replace init by restart
elif [[ $thisjob > 1 ]] ; then
sed -i -e "s/input_filename = 'n'/input_filename = 'r'/g" input.nml
fi

# grep month interval
month_dt=$( grep "months" input.nml | sed -e "s/,/ /g" | awk '{print $3}')


# grep the first year of the run
yearbeg=$( grep "current_date" input.nml | sed -e "s/,/ /g" | awk '{print $3}' )

#thisyear=$(( $yearbeg + $(( $(($thisjob))*$month_dt/12 )) ))
thisyear=$(( yearbeg + ((thisjob-1) * month_dt) / 12 ))


# # grep month of the run 
# monthbeg=$( grep "current_date" input.nml | sed -e "s/,/ /g" | awk '{print $4}' )


# thismonth=$(($monthbeg+$month_dt))

# if [[ $thismonth>13 ]]; then thismonth=$(($thismonth-12)); fi

# monthformatted=$( printf "%02d" $thismonth)
# thisyearmonth=$(( $thisyear$monthformatted ))


cat data_table.template | sed -e "s/<YEAR>/$thisyear/g" > data_table
cat configs/MOM_override.template | sed -e "s/<YEAR>/$thisyear/g" > configs/MOM_override

#--------------------------------- run the model -----------------------------------



# Main condition test
#if [ -z "$(ibstat 2>/dev/null)" ]; then
#    echo "RESULT: Using TCP (ibstat empty or command not found)"
#    mpiexec -np $ntasks --mca btl tcp,self --mca pml ob1 ./mom6
#else
#    echo "RESULT: Using standard (ibstat has output)"
#    mpiexec -np $ntasks ./mom6
#fi

mpiexec -np $ntasks --mca pml_base_verbose 10 ./mom6


#--------------------------------- check status of run -----------------------------

runok=$( tail -200 NWA25_NEUS.out | grep -i "Total runtime" )
run_start_failed1=$( tail -200 NWA25_NEUS.out | grep -i "Resource temporarily unavailable")
run_start_failed2=$( tail -200 NWA25_NEUS.err | grep -i "An ORTE daemon has unexpectedly failed after launch and before")
echo $run_start_failed2
if [[ $runok != '' ]] ; then
  # move outputs
  mv *.nc ./outputs_raw/.
  #mv *.nc.???? ./outputs_raw/.
  # initiate transfer
  #sbatch transfer.sub $thisyear
  # save restarts and move to input
  tar -cvf restarts.$thisjob RESTART/*
  mv restarts.$thisjob ./restarts_raw
  mv RESTART/* INPUT/.
  # move logs
  tar -cvf logs.tar.$thisjob MOM_parameter_doc.* SIS_parameter_doc.* NWA25_NEUS.err NWA25_NEUS.out ocean.stats* logfile.000000.out available_diags.000000 seaice.stats SIS.available_diags SIS_fast.available_diags ocean_stats*
  mv logs.tar.$thisjob ./logs/.

  # notify completion
  echo $thisjob >> $ctrldir/jobscompleted
  # test for resubmission
  if (( $thisjob < $njobs )) ; then
      cd $ctrldir ; sbatch $subscript_args ./$subscript 
    else
    # final job
      echo this is the last job
    fi
  elif [[ $run_start_failed1 != '' ]] || [[ $run_start_failed2 != '' ]] ; then

  echo "run restart failed, attempting again"
  #sleep 1m
  cd $ctrldir ; sbatch $subscript_args ./$subscript

else
  # run blew up11
  echo "run blew up"
  exit 1
fi
