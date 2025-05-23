# PatchDAC
Direct inference of molecular subtype of PDAC samples from WSI

# Quick Start
In order to run, the script `runPDAC_multiarc.sh` requires three arguments in the following format:

``` bash runPDAC_multiarc.sh /PATH/TO/SVS/ /PATH/TO/INFERENCE_OUTPUT/ /PATCH/TO/PATCH_OUTPUT/ ```

# Required data structure and software
* Argument 1: Directory containing SVS files
* Arguments 2 and 3: These are intermediate and output directories
* Requires either docker or singularity

# Output structure
```
inference_output/cluster_dir
├── **inference_feat.pickle**
├── **inference_list.pickle**
├── patchwise_cluster_vit_features.csv
└── patient_wise_stacked_cluster 
    ├── SVS1.png
    ├── SVS2.png
    └── etc.

patch_output/
└── one folder per svs filled with one png per patch
```
- _**inference_feat.pickle**_ and _**inference_list.pickle**_ contain what you will need for downstream predictions. _**inference_feat.pickle**_ is in the structure of _n_ rows (1 row per .svs) by 20 columns, with each cell representing the percentage of the svs that was classified as belonging to that cluster. _**inference_list.pickle**_ contains the svs file names in the same order as the row-level entries of _**inference_feat.pickle**_.
- the patient wise stacked clusters show representative images of each cluster type from each WSI. It is normal for many rows to be blank, as not all morphologies are present in all cases.
- patchwise cluster vit features can be used for patch level analyses (BETA)
  
# Implementing prediction pipeline (in development)
Once you have run the prediction pipeline on your dataset, run the .R file `implementPipeline.R` to generate a basal-like probability output
