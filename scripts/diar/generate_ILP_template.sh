#!/bin/bash

# Copyright     2013  Daniel Povey
#               2014  David Snyder
# Apache 2.0.

# This script extracts iVectors for a set of utterances, given
# features and a trained iVector extractor.

# Begin configuration section.
nj=1
cmd="run.pl"
stage=0
seg_min=0
num_gselect=20 # Gaussian-selection using diagonal model: number of Gaussians to select
min_post=0.025 # Minimum posterior to use (posteriors below this are pruned out)
posterior_scale=1.0 # This scale helps to control for successve features being highly
                    # correlated.  E.g. try 0.1 or 0.3.
delta=30 # delta parameter for ILP clustering
# End configuration section.

echo "$0 $@"  # Print the command line for logging

if [ -f path.sh ]; then . ./path.sh; fi
. parse_options.sh || exit 1;

if [ $# != 4 ]; then
  echo "Usage: $0 <extractor_dir> <data> <segment_dir> <output_dir>"
  exit 1;
fi

srcdir=$1
data=$2
segment_dir=$3
dir=$4


for f in $srcdir/final.ie $srcdir/final.ubm $data/feats.scp ; do
  [ ! -f $f ] && echo "No such file $f" && exit 1;
done

# Set various variables.
mkdir -p $dir/log; mkdir -p $dir/post; rm -f $dir/log/*; rm -f $dir/post/*; rm -f $dir/glpk.template.ilp
sdata=$data/split$nj;
utils/split_data.sh $data $nj || exit 1;

delta_opts=`cat $srcdir/delta_opts 2>/dev/null`

## Set up features.
feats="ark,s,cs:add-deltas $delta_opts scp:$sdata/JOB/feats.scp ark:- | apply-cmvn-sliding --norm-vars=false --center=true --cmn-window=300 ark:- ark:- |"


if [ $stage -le 0 ]; then
  echo "$0: extracting iVectors"
  dubm="fgmm-global-to-gmm $srcdir/final.ubm -|"

  $cmd JOB=1:$nj $dir/log/extract_posterior.JOB.log \
     gmm-gselect --n=$num_gselect "$dubm" "$feats" ark:- \| \
     fgmm-global-gselect-to-post --min-post=$min_post $srcdir/final.ubm "$feats" \
	ark,s,cs:- ark:- \| scale-post ark:- $posterior_scale ark,t:$dir/post/posterior.JOB || exit 1;

  $cmd JOB=1:$nj $dir/log/generate_ILP.JOB.log \
     writeTemplateILP --delta=$delta --seg_min=$seg_min $segment_dir/segments.scp "$feats" ark,s,cs:$dir/post/posterior.JOB $srcdir/final.ie scp:exp/dev.iv/ivector.scp ark:data/dev/utt2spk $dir/glpk.template.ilp || exit 1;

fi

