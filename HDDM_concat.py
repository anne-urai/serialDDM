#!/usr/bin/env python
# encoding: utf-8

"""
Anne Urai, 2016
takes input arguments from stopos
Important: on Cartesius, call module load python2.7.9 before running
(the only environment where HDDM is installed)
"""

# ============================================ #
# HDDM cheat sheet
# ============================================ #

# v     = drift rate
# a     = boundary separation
# t     = nondecision time
# z     = starting point
# dc    = drift driterion
# sv    = inter-trial variability in drift-rate
# st    = inter-trial variability in non-decision time
# sz    = inter-trial variability in starting-point

# ============================================ #
# parse input arguments
# ============================================ #

from optparse import OptionParser
usage = "HDDM_run.py [options]"
parser = OptionParser ( usage)
parser.add_option ( "-d", "--dataset",
        default = 0,
        type = "int",
        help = "Which dataset, see below" )
parser.add_option ( "-v", "--version",
        default = 0,
        type = "int",
        help = "Version of the model to run" )

opts,args       = parser.parse_args()
model_version   = opts.version
d               = opts.dataset

# ============================================ #
# define the function that will do the work
# ============================================ #

def concat_models(mypath, model_name):

    import os, hddm
    from IPython import embed as shell

    shell()

    allmodels = []
    print "appending models"
    for trace_id in range(14): # 15 models were run
        model_filename              = os.path.join(mypath, model_name, 'modelfit-md%d.model'%trace_id)
        modelExists                 = os.path.isfile(model_filename)
        assert modelExists == True # if not, this model has to be rerun
        thism                       = hddm.load(model_filename)
        allmodels.append(thism)

    # compute rhat stats
    hddm.analyse.gelman_rubin(allmodels)

    # save
    text_file = open(os.path.join(mypath, model_name, 'gelman_rubin.txt'), 'w')
    for p in gr.items():
        text_file.write("%s:%s\n" % p)
    text_file.close()
    print "done"

    # now actually concatenate them, see email Gilles
    combined_model = kabuki.utils.concat_models(allmodels)

    return combined_model

# ============================================ #
# run one model per job
# ============================================ #

# which model are we running at the moment?
models = {0: 'stimcoding',
    1: 'stimcoding_prevresp_dc',
    2: 'stimcoding_prevresp_z',
    3: 'regress_dc',
    4: 'regress_dc_prevresp',
    5: 'regress_dc_prevresp_prevpupil_prevrt'}

datasets = {0: 'RT_RDK', 1: 'MEG-PL'}

# find path depending on location and dataset
import os, time
mypath = os.path.realpath(os.path.expanduser('~/Data/%s/HDDM'%datasets[d]))

# and... go!
starttime = time.time()
concat_models(mypath, models[model_version])
elapsed = time.time() - starttime
print( "Elapsed time: %f seconds\n" %elapsed )

# and plot
# import HDDM_plotOutput
# HDDM_plotOutput.plot_model(mypath, models[model_version], trace_id)
