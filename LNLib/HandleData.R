############################################## INFO ################################################################
# The LNLib.readAndTreatDataset method:
#         - removes all missing values (if it least one attribute is null, the instance is removed)
#         - converts the dataset to factor (integer) data type
# Input: dataset.path (string with the path where the dataset is located, Ex: "../arcene.arff")
# Output: a treated dataframe
#####################################################################################################################
library(foreign) #read.arff

LNLib.convertToInt <- function(x) {
  #convert numeric data to factor
  if (!is.numeric(x)) {
    x = as.integer(x)
  }
  return(x)
}

LNLib.readAndTreatDataset <- function(dataset.path) {
  dt <- read.arff(dataset.path) #read dataset
  iClass <- ncol(dt)		#class index (last column)
  
  dt1 = sapply(dt[, -iClass], function(x)
    LNLib.convertToInt(x)) ## convert to factor
  dt1 = as.data.frame(dt1) #transform new result in data.frame
  dt1$class = dt$class # add a 'class' column
  dt = dt1
  dat <-
    na.omit(dt) # create a new dataset with no missing values (if it least one attribute is null, the instance is removed)
  return(dat)
}

############################################## INFO ################################################################
# The LNLib.getCleanedData method:
#     - generates noiseless datasets (by removing instances that were incorrectly classified by all algorithms )
# Input:  1. dat (a dataset of dataframe type with a column named class in the last position)
# Output: 1. a dataframe
# Steps:
#   1. A dataset is classified by all algorithms  ("LNLib.getKFoldClassification")
#   2. Each instance incorrectly classified by all algorithms is removed
#   3. A new dataset is returned
#####################################################################################################################

#source('Classification.R')

LNLib.getCleanedData <- function(dat) {
  dat.classified = LNLib.getKFoldClassification(dat, 10) ### Getting classification of all algorithms using LibClassifyWithKFold.R
  dat.classified$row.number = NULL
  ## cleaning data by applying consensus vote (if all classifiers misclassify an instance, then remove it)
  lz = which(apply(dat.classified, 1, sum) == 0) #get lines to be removed
  
  if (length(lz) != 0)
    dat = dat[-lz, ] #remove lines
  
  return(dat)
}

############################################## INFO ################################################################
# The LNLib.generateIR method:
#   - generates a dataset with a specific imbalance ratio, by undersampling the minority class
# Input: 1. dataset (a dataset of dataframe type with a column named class in the last position)
#        2. IR (should be LNLib.IR.VALUES$IR.5050 for 50:50,
#                         or LNLib.IR.VALUES$IR.3070 for 30:70
#                         or LNLib.IR.VALUES$IR.3070 for 20:80 )
# Ouput: 3. a dataframe
#####################################################################################################################

LNLib.IR.VALUES <-
  list(IR.5050 = 1,
       IR.3070 = 2.33,
       IR.2080 = 4) ##Imbalance ratio variables

LNLib.generateIR <- function(dataset, IR = LNLib.IR.VALUES$IR.5050) {
  classes.proportion = data.frame(sort(table(dataset$class), decreasing = FALSE))
  
  class.under = 1 #get index of minority class
  class.ref = 2 #get index of majority class
  if (IR == LNLib.IR.VALUES$IR.5050) {
    class.under = 2 #get index of majority class
    class.ref = 1 #get index of minority class
  }
  label.under = classes.proportion$Var1[class.under] #get the label of the class which will be undersampled
  class.rows = which(dataset$class == label.under) #get which rows from dataset are from a certain class
  n.remove = classes.proportion$Freq[class.under] - classes.proportion$Freq[class.ref] /
    IR  #get number of rows to be removed
  
  
  remove.rows = sample(class.rows, n.remove , replace = FALSE) #get random lines to be removed
  imbalanced.data = dataset[-remove.rows, ] #new data with proper imbalanced ratio
  
  return(imbalanced.data)
  
}
