############################################## INFO ################################################################
##  This file contains: the LNLib.getClassification and LNLib.getKFoldClassification methods.
##  Both methods classify data using all algorithms in Classifiers.R
##  Input:
##     - LNLib.getClassification:
##         1. training (the training dataset of dataframe type with a column named class in the last position)
##         2. test  (the test dataset of dataframe type with a column named class in the last position)
##     - LNLib.getKFoldClassification:
##         1. dataset (a dataframe with a column named class)
##         2. K (the k-fold value, 10 by default)
##  Output: 1. a dataframe with classification results
##        OBS: The dataframe rows = classified instances
##             The dataframe columns = classifiers (except for the first column = instance's row number)
##             The dataframe values (cells) = 1/0 (1 correct and 0 wrong classification)
##
## =>>>>to add a new classifier into the ensemble, it is necessary to create a new method in "Classifiers.R" and,
##          to use it, it must be included in the "list.of.algorithms" variable in this file
#####################################################################################################################

#library(dismo) #install.packages("dismo") #"kfold" for stratified cross validation
#source('Classifiers.R')

LNLib.callAlgorithm <- function(training, test, algorithm) {
  #calls classifiers dynamically
  return(algorithm(training, test))
}

LNLib.classify <- function(trt, tst, tst.rows) {
  lits.of.algorithms = c(
    LNLib.algorithm.1,
    LNLib.algorithm.2,
    LNLib.algorithm.3,
    LNLib.algorithm.4,
    LNLib.algorithm.5,
    LNLib.algorithm.6,
    LNLib.algorithm.7,
    LNLib.algorithm.8,
    LNLib.algorithm.9,
    LNLib.algorithm.10
  )
  
  NUMBER.OF.ALGORITHMS = length(lits.of.algorithms)
  
  col.names = array("", dim = c(NUMBER.OF.ALGORITHMS + 1))
  col.names[1] = "row.number" #label for the first column
  
  final.result = tst.rows #initialize final.result with row numbers (first column)
  
  for (j in 1:NUMBER.OF.ALGORITHMS) {
    #execute for every algorithm
    result = LNLib.callAlgorithm(trt, tst, algorithm = lits.of.algorithms[[j]]) #prediction result
    
    col.names[j + 1] = result$name #algorithm's name (used as col name)
    
    if (length(levels(tst$class)) != length(levels(result$predictions)))
      #workaround in case algorithm returns only one class (level)
      result$predictions = factor(result$predictions, levels(tst$class))
    
    compared.result = result$predictions == tst$class #compare result with test -> returns TRUE/FALSE
    binary.result = as.integer(as.logical(compared.result)) # transform TRUE/FALSE into 1/0
    
    final.result = cbind(final.result, binary.result) #appended by column
  }
  return(list(classification = final.result, col.names = col.names))
  
}

LNLib.getKFoldClassification <- function(dataset, k = 10) {
  folds <-
    kfold(dataset, k, by = dataset$class) ## get folds according to parameter K and class
  folds.id <- 1:k
  
  result = ""
  for (i in folds.id) {
    tst = subset(dataset, folds == i)
    trt = subset(dataset, folds != i)
    
    tst.rows = which(folds == i) #get row numbers
    
    info <- LNLib.classify(trt, tst, tst.rows)
    
    if (i == 1) {
      result = info$classification #initialize result
    } else{
      result = rbind(result, info$classification) #append by row = results from the fold
    }
  }
  
  colnames(result) = info$col.names #set col names
  result = as.data.frame(result) #transform matrix to data.frame type
  new.data <-
    result[order(result$row.number), ] #sort all results by row numbers
  return(new.data)
  
}


LNLib.getClassification <- function(training, test) {
  test.rows = 1:nrow(test)
  info <- LNLib.classify(training, test, test.rows)
  result = info$classification
  colnames(result) = info$col.names #set col names
  result = as.data.frame(result) #transform matrix to data.frame type
  new.data <-
    result[order(result$row.number), ] #sort all results by row numbers
  return(new.data)
  
}
