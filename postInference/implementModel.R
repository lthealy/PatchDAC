implementModel <- function(pathToClusterDir){
   ## load required files
   ## Note - if you are having trouble here you may need to set your reticulate python version
   require("reticulate")
   Sys.setenv(RETICULATE_PYTHON = "~/miniconda3/bin/python3")
   use_python("~/miniconda3/bin/python3")
   source_python("read_pickle.py")
   pickle_data <- read_pickle_file(pathToClusterDir)
   load("DiRL_10x_20clust_alpha1_trainedModel.RData")
}