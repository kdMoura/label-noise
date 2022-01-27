############################################## INFO ################################################################
## This file contains all classifiers used in the experiments.
## All functions have the inputs:
##             1. train (the training dataset of dataframe type with a column named class in the last position)
##             2. test  (the test dataset of dataframe type with a column named class in the last position)
## All functions return a list as result. The list contains:
##   - $name = name of the algorithm
##   - $predictions = classification result (factor data type)
#####################################################################################################################

#library(RSNNS) #install.packages("RSNNS") #mlp
#library(party) #install.packages("party") #ad
#library(class) #install.packages('class') #knn
#library(e1071) #install.packages('e1071') #svm
#library(randomForest) #install.packages('randomForest') #randomForest
#library(RoughSets) #install.packages('RoughSets') #CN2
#library(naivebayes) #install.packages('naivebayes') #Naive Bayes
#library(RWeka) #install.packages('RWeka') #J48

#CN2(rule learner)
LNLib.algorithm.1 <- function(train, test) {
  ## transform to DecisionTableFormat
  data.decTable.trt = SF.asDecisionTable(train, decision.attr = ncol(train))
  data.decTable.tst = SF.asDecisionTable(test, decision.attr = ncol(test))
  
  ## discretization:
  cut.values <-
    D.discretization.RST(data.decTable.trt,
                         type.method = "unsupervised.quantiles",
                         nOfIntervals = 3)
  data.trt <- SF.applyDecTable(data.decTable.trt, cut.values)
  data.tst <- SF.applyDecTable(data.decTable.tst, cut.values)
  
  ##rule induction from the training set:
  
  rules <- RI.CN2Rules.RST(data.trt,  K = 5)
  
  ## predicitons for the test set:
  pred.vals <- predict(rules, data.tst)
  
  pred.vals = as.factor(unlist(pred.vals)) ##convert to factor
  ##
  result = list(name = "CN2", predictions = pred.vals)
  
  return(result)
}

#kNN
LNLib.algorithm.2 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  predict = knn(train[, 1:nAtt], test[, 1:nAtt], train$class, k = 7, prob =
                  FALSE)
  
  ##
  result = list(name = "kNN", predictions = predict)
  return(result)
}

#Naive Bayes
LNLib.algorithm.3 <- function(train, test) {
  #Naive Bayes
  nAtt <- ncol(train) - 1 #get number of attributes
  nb <- naive_bayes(train[, 1:nAtt], train$class)
  predict = predict(nb, test[, 1:nAtt])
  
  ##
  result = list(name = "NaiveBayes", predictions = predict)
  return(result)
}

#Random Forest
LNLib.algorithm.4 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  rf <- randomForest(train[, 1:nAtt], train$class)
  predict <- predict(rf, test[, 1:nAtt])
  
  ##
  result = list(name = "RandomForest", predictions = predict)
  return(result)
  
}

#SVM
LNLib.algorithm.5 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  model <- svm(train[, 1:nAtt], train$class)
  predict <- predict(model, test[, 1:nAtt])
  
  ##
  result = list(name = "SVM", predictions = predict)
  return(result)
}

#J48
LNLib.algorithm.6 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  resultJ48 <- J48(as.factor(class) ~ ., train)
  predict <- predict(resultJ48, newdata = test[, 1:nAtt])
  
  ##
  result = list(name = "J48", predictions = predict)
  return(result)
}

#JRIP
LNLib.algorithm.7 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  model <- JRip(as.factor(class) ~ ., train)
  predict <- predict(model, newdata = test[, 1:nAtt])
  
  ##
  result = list(name = "JRip", predictions = predict)
  return(result)
}

#Multilayer perceptron
LNLib.algorithm.8 <- function(train, test) {
  ##MLP
  nAtt <- ncol(train) - 1 #get number of attributes
  targetTrain = decodeClassLabels(train$class)
  targetTest <- decodeClassLabels(test$class)
  model <-
    mlp(train[, 1:nAtt],
        targetTrain,
        inputsTest = test[, 1:nAtt],
        targetsTest = targetTest)
  predictions <- predict(model, test[, 1:nAtt])
  
  vReal = encodeClassLabels(targetTest)
  vPredicted = encodeClassLabels(predictions)
  
  N = length(vPredicted)
  v_pred = array("", dim = c(N))
  
  i = 1
  for (i in 1:N) {
    searchFor = as.integer(vPredicted[i]) ##which label to search for
    indexReference = min(which(vReal == searchFor)) ##label index  (min = first occurrence)
    v_pred[i] = as.character(test[indexReference, nAtt + 1])
    
  }
  
  v_pred = as.factor(unlist(v_pred)) ##convert to factor
  ##
  result = list(name = "MLP", predictions = v_pred)
  return(result)
  
}

#SMO
LNLib.algorithm.9 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  model <- SMO(as.factor(class) ~ ., train)
  predict <- predict(model, newdata = test[, 1:nAtt])
  
  ##
  result = list(name = "SMO", predictions = predict)
  return(result)
}

#DecisionTree
LNLib.algorithm.10 <- function(train, test) {
  nAtt <- ncol(train) - 1 #get number of attributes
  model <- ctree(class ~ ., data = train)
  predict = predict(model, test[, 1:nAtt])
  
  ##
  result = list(name = "DecisionTree", predictions = predict)
  return(result)
}


LNLib.getAccuracyRate <-
  function(real, predicted) {
    #Return the accuracy rate given real and predicted vectors
    acc = 0
    
    size = length(predicted)
    
    for (l in 1:size) {
      if (predicted[l] == real[l])
        acc = acc + 1
      
    }
    return(acc / size)
    
  }
