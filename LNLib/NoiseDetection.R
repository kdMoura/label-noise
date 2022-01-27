############################################## INFO ################################################################
## The LNLIb.getNoiseDetectionMeasures method:
##      - returns the prediction, recall, and f_measure variables
##
## input: 1. noise.injection.info (a list from NoiseInjection.R -> LNLib.getNoisyData
##        2. classification.result (a dataframe from Classification.R -> LNLib.getClassification
##        3. ensemble.threshold (a percentage number, ex: 10.0, 25.0, etc.
##                                  For majority vote use LNLib.ENSEMBLE.THRESHOLD$MAJORITY)
##        4. beta.f (beta f measure value, 2 by default)
##
## output: a list with:
##        1. $precision (numeric)
##        2. $recall (numeric)
##        3. $f_measure (numeric)
##        4. $n.correct.detection (number of correctly detected noise) (numeric)
##        5. $n.noise.detected (number of all noise detected) (numeric)
##        6. $n.noisy.labels (number of noise in data) (numeric)
#####################################################################################################################

LNLib.ENSEMBLE.THRESHOLD <- list(CONSENSUS = 100.0, MAJORITY = -1)

LNLib.getNoiseDetectionMeasures <-
  function(noise.injection.info,
           #from NoiseInjection.R -> LNLib.getNoisyData
           classification.result,
           #from Classification.R -> LNLib.getClassification
           ensemble.threshold = LNLib.ENSEMBLE.THRESHOLD$MAJORITY,
           beta.f = 2) {
    classifiers.preds = classification.result
    classifiers.preds$row.number = NULL #remove row number column. All remaining columns are the classifiers predictions
    
    noisy.labels = vector(mode = "integer", length = nrow(classifiers.preds)) # vector with 1's and 0's (1= noise, 0 = noiseless)
    noisy.rows = noise.injection.info$changes.made$changed.rows #get rows number with noise
    noisy.labels[noisy.rows] = 1 # rows with noise
    noisy.labels[-noisy.rows] = 0 # rows without noise
    
    n.classifiers = length(classifiers.preds)
    et = ifelse(
      ensemble.threshold == LNLib.ENSEMBLE.THRESHOLD$MAJORITY,
      #majority vote is a special case = 50% of classifiers + 1
      n.classifiers * 0.5 + 1,
      n.classifiers * ensemble.threshold * 0.01
    )
    
    #if a row is incorrectly classified by a number greater or equal than the ensemble threshold, it is set to 1 and 0 otherwise
    ensemble.pred  = apply(classifiers.preds, 1,
                           function(x)
                             ifelse(abs(length(x) - sum(x)) >= et, 1, 0))
    
    ## Noise detection measures calculation
    n.noise.detected = sum(ensemble.pred) # number of all noise detected
    n.noisy.labels = sum(noisy.labels) #number of noise in data
    
    predictions = replace(ensemble.pred, ensemble.pred == 0, 2) #trick to compare vectors, while one vector contains 1's and 0's, the other one contains 1's and 2's
    n.correct.detection = sum(as.integer(as.logical(predictions == noisy.labels))) #number of correctly detected noise
    
    precision = (n.correct.detection / n.noise.detected) * 100.0
    recall = (n.correct.detection / n.noisy.labels) * 100.0
    f_measure = (beta.f * precision * recall) / (precision + recall)
    
    measures = list(
      precision = round(precision, digits = 1),
      recall = round(recall, digits = 1),
      f_measure = round(f_measure, digits = 1),
      n.correct.detection = n.correct.detection,
      n.noise.detected = n.noise.detected,
      n.noisy.labels = n.noisy.labels
    )
    
    return(measures)
    
  }