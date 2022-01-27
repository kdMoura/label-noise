############################################## INFO ################################################################
## The LNLib.injectNoise method:
##    - returns a dataset (dataframe type) with a percentage of noise.
##        Noise is distributed per class according to the selected noise model
##
## Input: 1. dataset (a dataset of dataframe type with a column named class in the last position)
##        2. noise.perc (the percentage of noise, ex: 5%, 10%, 20%..)
##        3. noise.ratio (should be NCAR - noise equally distributed per class
##                                  or NAR.MIN - more noise in minority class, proportion of 1:9
##                                  or NAR.MAJ - more noise in majority class, proportion of 1:9,
##                                  it is NCAR by default)
## Output: a list with:
##        1.$changes.made (dataframe)
##        2.$noisy.data (dataframe - the dataset with noise)
##        3.$noise.perc (numeric)
##        4.$noise.ratio (one of LNLib.NOISE.MODEL)
#####################################################################################################################

##Noise models/noise ratios
LNLib.NOISE.MODEL <-
  list(NCAR = 1,
       NAR.MIN = 9,
       NAR.MAJ = 0.1111111)

LNLib.injectNoise <-
  function(dataset, noise.perc, noise.ratio = LNLib.NOISE.MODEL$NCAR) {
    # get rows (by class) that should be changed (noisy row)
    list.of.rows = LNLib.getNoisyRowsList(dataset, noise.perc, noise.ratio)
    
    
    ## changing labels
    for (il in 1:length(list.of.rows)) {
      #execute for every class
      
      ## OBS: if there are 3 labels, then label1 gets label2, label2 gets label3 and label3 gets label1 and forth
      rows = list.of.rows[[il]]$rows
      if (il == length(list.of.rows)) {
        ##check if it is already the last class (for the above ex: it checks if it is label3)
        new.label = list.of.rows[[1]]$class #if it is true, this class gets the label of first class (label3 gets label1)
      } else{
        new.label = list.of.rows[[il + 1]]$class #otherwise, this class gets the next class label
      }
      
      ##store which rows were changed to use in validation
      if (il == 1) {
        changed.rows = rows
        original.class = as.character(dataset[rows,]$class)
        dataset[rows,]$class = new.label ##add new labels
        new.class = as.character(dataset[rows,]$class)
      }
      else{
        ##append
        changed.rows = append(changed.rows, rows)
        original.class = append(original.class, as.character(dataset[rows,]$class))
        dataset[rows,]$class = new.label ##add new labels
        new.class = append(new.class, as.character(dataset[rows,]$class))
      }
      
    }
    
    changes.made = data.frame(changed.rows, original.class, new.class)
    result = list(
      changes.made = changes.made,
      noisy.data = dataset,
      noise.perc = noise.perc,
      noise.ratio = noise.ratio
    )
    
    return(result)
  }

############################################## INFO ################################################################
## The LNLib.getNoisyRowsList method:
##    - returns the rows (by class) that should be changed (noisy row)
## Input: 1. dataset (a dataset of dataframe type with a column named class in the last position)
##        2. noise.perc (the percentage of noise, ex: 5%, 10%, 20%..)
##        3. noise.ratio (should be NCAR - noise equally distributed per class
##                                  or NAR.MIN - more noise in minority class, proportion of 1:9
##                                  or NAR.MAJ - more noise in majority class, proportion of 1:9,
##                                  it is NCAR by default)
## output: a list with items (for each class), each item contains:
##        1.$class (class name)
##        2.$rows (rows whose class labels should be changed)
##        - item example:
##            $class
##            [1] "malignant"
##            $rows
##            [1] 308 147 121 672 141 114 289 170 214 326  36 270
#####################################################################################################################



LNLib.getNoisyRowsList <-
  function(dataset, noise.perc, noise.ratio = LNLib.NOISE.MODEL$NCAR) {
    #Example: Suppose a dataset with 200 rows and 10% of noise is required, i.e, 20 rows with noise
    #         a) for NCAR, aprox. 10 noisy rows will be injected into each class
    #         b) for NAR.MIN, aprox. 18 noisy rows will be injected into the minority class and 2 into the majority one
    #         c) for NAR.MAJ, aprox. 18 noisy rows will be injected into the majority class and 2 into the minority one
    
    classes.proportion = sort(table(dataset$class), decreasing = FALSE) #get info about class distribution
    
    total.ocurr = length(dataset$class) #get number of rows
    
    p1 = (noise.perc * total.ocurr * 0.01) / ((noise.ratio + 1) * classes.proportion[2]) #calc percentage
    p0 = (noise.ratio * p1 * classes.proportion[2]) / classes.proportion[1] ##calc percentage
    
    perc.v = c(p0, p1)
    
    noisy.rows.list = list() #list with results to be returned
    
    for (i in 1:length(classes.proportion)) {
      # execute for every class
      n.occurr = as.numeric(classes.proportion[i]) # get the number of occurrences per class
      n.noisy.rows = round(n.occurr * perc.v[i]) #calc the number of labels should be changed
      n.noisy.rows = ifelse(n.noisy.rows == 0, 1, n.noisy.rows)
      class.name = names(classes.proportion[i])  #get class name (to be saved later on)
      n.class.rows = which(dataset$class == class.name) #get which rows from the dataset are from a certain class
      n.noisy.rows = ifelse(length(n.class.rows) < n.noisy.rows,
                            length(n.class.rows),
                            n.noisy.rows)
      noisy.rows = sample(n.class.rows, n.noisy.rows , replace = FALSE) #get random rows to be changed
      noisy.rows = sort(noisy.rows) #ordering result (to make validation easier )
      l <-
        list(class = class.name, rows = noisy.rows) #create nested list with results for each class
      noisy.rows.list[[i]] = l
    }
    return(noisy.rows.list)
  }
