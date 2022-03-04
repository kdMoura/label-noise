# Overview

This repository contains the code used for the article [_Label noise detection under the Noise at Random model with ensemble filters._](https://arxiv.org/abs/2112.01617) 


## Installation

#### Install required packages
```
# classifiers
install.packages('RSNNS') #mlp
install.packages('party') #ad
install.packages('class') #knn
install.packages('e1071') #svm
install.packages('randomForest') #randomForest
install.packages('RoughSets') #CN2
install.packages('naivebayes') #Naive Bayes
install.packages('RWeka') #J48 

install.packages("dismo") #"kfold" for stratified cross validation
install.packages('foreign') #read.arff
install.packages('caTools') #sample.split

```

#### Load libraries and source files

```
# libraies
library(RSNNS)
library(party)
library(class)
library(e1071)
library(randomForest)
library(RoughSets)
library(naivebayes)
library(RWeka)
library(dismo)
library(foreign)
library(caTools)

#sources
setwd("[path to the lable-noise repository folder]/label-noise")
source('./LNLib/Classifiers.R')
source('./LNLib/HandleData.R')
source('./LNLib/Classification.R')
source('./LNLib/NoiseInjection.R')
source('./LNLib/NoiseDetection.R')

```

## How it works

![process](https://user-images.githubusercontent.com/40217238/151442573-37d1d1fb-d1f6-45a0-9cb2-b53f6fdedcea.png)

 #### 1. Data Cleaning 
 
   ```
   dat = LNLib.readAndTreatDataset("sample_data.arff")
   cleaned.data = LNLib.getCleanedData(dat)
   ```

#### 2. Generate Imbalance Ratio (IR)
   
   ```
   #For IR of 50:50, use LNLib.IR.VALUES$IR.5050
   #For IR of 30:70, use LNLib.IR.VALUES$IR.3070
   #For IR of 20:80, use LNLib.IR.VALUES$IR.2080
   data.2080 = LNLib.generateIR(cleaned.data,LNLib.IR.VALUES$IR.2080)
   ```
   
#### 3. Split data
   ```
  sample = sample.split(data.2080$class, SplitRatio = 0.70)
  train = subset(data.2080, sample == TRUE)
  test  = subset(data.2080, sample == FALSE)
  ```

#### 4. Noise Injection
   
   ```
   #For 15% of noise and NCAR noise model (or noise ratio):
   info.injection = LNLib.injectNoise(test, 15, LNLib.NOISE.MODEL$NCAR)
   noisy.test = info.injection$noisy.data
   ```
##### About noise models
   The label noise model should be one of the following:
   1. `LNLib.NOISE.MODEL$NCAR` - noise equally distributed per class
   2. or `LNLib.NOISE.MODEL$NAR.MIN` - more noise in minority class, proportion of 1:9
   3. or `LNLib.NOISE.MODEL$NAR.MAJ` - more noise in majority class, proportion of 1:9

Example: suppose a dataset with 200 rows and we want to inject 10% of noise into the data, i.e, 20 rows with noise
- for `NCAR`, aprox. 10 noisy rows will be injected into each class 
- for `NAR.MIN`, aprox. 18 noisy rows will be injected into the minority class and 2 into the majority one
- for `NAR.MAJ`, aprox. 18 noisy rows will be injected into the majority class and 2 into the minority one
   
##### About `LNLib.injectNoise` result

   
```
set.seed(165421)

#Dataset with 10 rows ( 5 rows from class 1, and 5 rows from class 2)
dat = as.data.frame(
          list( col1 = c(1,2,3,4,5,6,7,8,9,10),
                col2 = c(10,9,8,7,6,5,4,3,2,1), 
                class  = c(1,1,1,1,1,2,2,2,2,2)))
                
##If we inject 10% of noise.. 
LNLib.injectNoise(dat,10,LNLib.NOISE.MODEL$NCAR)

##We get:
$changes.made
  changed.rows original.class new.class
1            5              1         2
2           10              2         1

Results:
$noisy.data
   col1 col2 class
1     1   10     1
2     2    9     1
3     3    8     1
4     4    7     1
5     5    6     2
6     6    5     2
7     7    4     2
8     8    3     2
9     9    2     2
10   10    1     1

$noise.perc
[1] 10

$noise.ratio
[1] 1

``` 

#### 5. Select vote threshold / Ensemble prediction / Evaluation
```
#Get classification (of all algorithms) after noise being injected 
classified.test = LNLib.getClassification(train,noisy.test) 

#Set ensemble vote threshold = 60% (i.e., an instance is considered noisy if 60% of all algorithms misclassify it) 
ensemble.treshold = 60.0 

measures = LNLib.getNoiseDetectionMeasures(info.injection,
                              classified.test,
                              ensemble.treshold)
```
##### Sample result of `measures`

```
$precision
[1] 28
$recall
[1] 87.5
$f_measure
[1] 42.4
$n.correct.detection #Number of correct detections
[1] 7
$n.noise.detected #Number of detections (correct or not)
[1] 25
$n.noisy.labels #Number of noisy labels in data
[1] 8
```
##### About ensemble threshold
It is also possible to use one of the following options as input 
1. `LNLib.ENSEMBLE.THRESHOLD$CONSENSUS` (100% of algorithms)
2. or `LNLib.ENSEMBLE.THRESHOLD$MAJORITY` (50% + 1 algorithms)


## How to reproduce the article experiments

- Set the same seed used before running code
`set.seed(165421)`

- Use the same datasets (all data should be in .arff format) 

| Dataset | Source |
| ------ | ------ |
| arcene | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Arcene) or [OpenML](https://www.openml.org/d/1458) |
| breast-c | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/breast+cancer+wisconsin+(original)) or [OpenML](https://www.openml.org/d/15) |
| column2c | [UCI Machine Learning Repository](http://archive.ics.uci.edu/ml/datasets/vertebral+column)
| credit | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/credit+approval) or [OpenML](https://www.openml.org/d/29) |
| cylinder-bands | [OpenML](https://www.openml.org/d/6332)
| diabetes | [OpenML](https://www.openml.org/d/42608)
| eeg-eye-state | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/EEG+Eye+State) or [OpenML](https://www.openml.org/d/1471) |
| glass0 | [KEEL-dataset repository](https://sci2s.ugr.es/keel/imbalanced.php) or [OpenML](https://www.openml.org/search?q=glass&type=data) |
| glass1 | [KEEL-dataset repository](https://sci2s.ugr.es/keel/imbalanced.php)
| heart-c | [OpenML](https://www.openml.org/d/49)
| heart-statlog | [OpenML](https://www.openml.org/d/53)
| hill-valley | [OpenML](https://www.openml.org/d/1566)
| ionosphere | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/ionosphere)
| kr-vs-kp | [KEEL-dataset repository](https://www.openml.org/d/3)
| mushroom | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/mushroom) or [OpenML](https://www.openml.org/d/24) |
| pima | [KEEL-dataset repository](https://sci2s.ugr.es/keel/imbalanced.php)
| sonar | [OpenML](https://www.openml.org/d/40)
| steel-plates-fault | [OpenML](https://www.openml.org/d/1504)
| tic-tac-toe | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/Tic-Tac-Toe+Endgame)
| voting | [UCI Machine Learning Repository](https://archive.ics.uci.edu/ml/datasets/congressional+voting+records)

- Given the memory and processing time needed, each step (data cleaning, generate IR..) was executed for every dataset and results were temporarily saved into a file 

- The training and testing step was run multiple times and measures were evaluated by average values 

- Important: the code is a script and has no error handler. It is important data is well structured, organized, and correct, and that the script is executed as previously described.


## Citation
```
bibtex
@article{DBLP:journals/corr/abs-2112-01617,
  author    = {Kecia G. Moura and Ricardo B. C. Prud{\^{e}}ncio and George D. C. Cavalcanti},
  title     = {Label noise detection under the Noise at Random model with ensemble filters},
  journal   = {arXiv preprint arXiv:2112.01617},
  year      = {2021}
}
```

## License
All data is provided under Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International and available in full [here](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) and summarized [here](https://creativecommons.org/licenses/by-nc-sa/4.0/).


