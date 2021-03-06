#!/bin/bash
# Launch AWS EMR Spark Application using aws cli
# Usage: ./aws_launch_spark_app.sh CLUSTER_NAME INSTANCE_TYPE INSTANCE_COUNT LOG_URI CONFIG_FILE [-s step_class_full_name step_class_jar [step_class_params]...]...

CLUSTER_NAME=$1
INSTANCE_TYPE=$2
INSTANCE_COUNT=$3
LOG_URI=$4
CONFIG_FILE=$5

STEPS=""

# Build steps argument text
for arg in "$@"; do
  shift
  if [ $arg = '-s' ]; then
    step_class_full_name=$1
    step_class_jar=$2
    step_class_params_array=${@:3}
    step_class_params=""

    # Build step class params argument text
    for step_class_param in $step_class_params_array; do
      if [ $step_class_param = '-s' ]; then
        break
      fi
      step_class_params+=",$step_class_param"
    done

    step="$step_class_full_name,$step_class_jar$step_class_params"

    # Build the step name
    # Include step class params with length < 20
    char_class="[a-Z0-9\/]"
    char_class_rep=""
    for i in {2..20}; do
      char_class_rep+=$char_class
    done
    shopt -s extglob  # Turn on extended pattern support
    step_class_params=${step_class_params//$char_class_rep+($char_class)/}
    step_class_params=${step_class_params//,/}
    # Include step class
    step_name="$step_class_full_name$step_class_params"

    STEPS+="Type=Spark,Name=$step_name,Args=[--deploy-mode,cluster,--master,yarn-cluster,--class,$step] "
  fi
done

aws emr create-cluster \
--name $CLUSTER_NAME \
--release-label emr-5.0.0 \
--instance-type $INSTANCE_TYPE \
--instance-count $INSTANCE_COUNT \
--service-role EMR_DefaultRole \
--ec2-attributes KeyName=define_key_name,InstanceProfile=EMR_EC2_DefaultRole \
--applications Name=Spark \
--log-uri $LOG_URI \
--configurations $CONFIG_FILE \
--steps $STEPS\
--auto-terminate
