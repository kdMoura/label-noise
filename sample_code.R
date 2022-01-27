rm(list = ls(all = TRUE))

set.seed(165421)

#set working directory
setwd("~/Downloads/label-noise")

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
source('./LNLib/Classifiers.R')
source('./LNLib/HandleData.R')
source('./LNLib/Classification.R')
source('./LNLib/NoiseInjection.R')
source('./LNLib/NoiseDetection.R')

#Data Cleaning
dat = LNLib.readAndTreatDataset("sample_data.arff")
cleaned.data = LNLib.getCleanedData(dat)


#Generate Imbalance Ratio (IR)

#For IR of 50:50, use LNLib.IR.VALUES$IR.5050
#For IR of 30:70, use LNLib.IR.VALUES$IR.3070
#For IR of 20:80, use LNLib.IR.VALUES$IR.2080
data.2080 = LNLib.generateIR(cleaned.data,LNLib.IR.VALUES$IR.2080)


#Split data
sample = sample.split(data.2080$class, SplitRatio = 0.70)
train = subset(data.2080, sample == TRUE)
test  = subset(data.2080, sample == FALSE)


#Noise Injection

#For NCAR, use LNLib.NOISE.MODEL$NCAR
#For NAR (1:9), use  LNLib.NOISE.MODEL$NAR.MAJ
#For NAR (9:1), use LNLib.NOISE.MODEL$NAR.MIN

#For 15% of noise and NCAR noise model (or noise ratio):
info.injection = LNLib.injectNoise(test, 15, LNLib.NOISE.MODEL$NCAR)
noisy.test = info.injection$noisy.data


#Select vote threshold / Ensemble prediction / Evaluation

#Get classification (of all algorithms) after noise being injected 
classified.test = LNLib.getClassification(train,noisy.test) 

#Set ensemble vote threshold = 60% (i.e., an instance is considered noisy if 60% of all algorithms misclassify it) 
ensemble.treshold = 60.0 

measures = LNLib.getNoiseDetectionMeasures(info.injection,
                                           classified.test,
                                           ensemble.treshold)
print(measures)
