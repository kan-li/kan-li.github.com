rm(list=ls())
dataDir = ""
setwd(dataDir)
library(gglasso)

#set cross validation
dat = read.csv("sample_500gene_ad.csv",header =T)
n.cv = 5
cv = cut(seq(1, nrow(dat)),breaks=n.cv,labels=FALSE)
set.seed(24578)
dat$cv = sample(cv,length(cv))

dat$lable = -1
dat[dat$disease==1, "lable"]=1
group=seq(1:500)

dat[,1:500] = apply(dat[,1:500], 2, scale)

# sparse logistic regression 
#-----------------------------------------------
accs = NULL
senss = NULL
specs = NULL

for(i in 1:n.cv){
  print(i)
  print("#-----------------------------------")
  train = dat[dat$cv!=i,]
  test = dat[dat$cv==i,]
  
  cv.model = cv.gglasso(x = as.matrix(train[,1:500]), y= train$lable, group=group, loss="logit", lambda.factor=0.05, nfolds=5)
  lambda = cv.model$lambda.min
  model = gglasso(x = as.matrix(train[,1:500]), y= train$lable, group=group, loss="logit", lambda=lambda)
  predicts = predict(model, newx=as.matrix(test[1:500]), type = "class" )
  a = table(t=test$lable,p=c(predicts))
  acc = (a[1,1]+a[2,2])/nrow(test)
  sens = a[2,2]/(a[2,1]+a[2,2])
  spec = a[1,1]/(a[1,1]+a[1,2])
  save(model, lambda, predicts, a, acc,sens,spec, file=paste(c(dataDir,"/output/plogit_cv_",i ,".rdata"),collapse = ""))
  accs = c(accs, acc)
  senss = c(senss, sens)
  specs = c(specs, spec)
}

table = cbind(accs, senss, specs)
table = rbind(table,c(c(mean(accs), mean(senss), mean(specs))))
rownames(table) = c("cv1","cv2","cv3","cv4","cv5","mean")
colnames(table) = c("accuracy", "sensitivity", "specificity")
write.table(table, file=paste(c(dataDir,"output/logit.txt"),collapse = ""))


# sparse support vector machine 
#-----------------------------------------------
accs = NULL
senss = NULL
specs = NULL

for(i in 1:n.cv){
  print(i)
  print("#-----------------------------------")
  train = dat[dat$cv!=i,]
  test = dat[dat$cv==i,]
  
  cv.model = cv.gglasso(x = as.matrix(train[,1:500]), y= train$lable, group=group, loss="hsvm", nfolds=5)
  lambda = cv.model$lambda.min
  model = gglasso(x = as.matrix(train[,1:500]), y= train$lable, group=group, loss="hsvm", lambda=lambda)
  predicts = predict(model, newx=as.matrix(test[1:500]), s=lambda, type = "class" )
  a = table(t=test$lable,p=c(predicts))
  acc = (a[1,1]+a[2,2])/nrow(test)
  sens = a[2,2]/(a[2,1]+a[2,2])
  spec = a[1,1]/(a[1,1]+a[1,2])
  save(model, lambda, predicts, a, acc,sens,spec, file=paste(c(dataDir,"/output/hsvm_cv_",i ,".rdata"),collapse = ""))
  accs = c(accs, acc)
  senss = c(senss, sens)
  specs = c(specs, spec)
}

table = cbind(accs, senss, specs)
table = rbind(table,c(c(mean(accs), mean(senss), mean(specs))))
rownames(table) = c("cv1","cv2","cv3","cv4","cv5","mean")
colnames(table) = c("accuracy", "sensitivity", "specificity")
write.table(table, file=paste(c(dataDir,"output/svm.txt"),collapse = ""))


# FPCA
#---------------------------------------
library(refund)
library(Hotelling)
fpc = fpca.sc(as.matrix(dat[,1:500]),pve=0.95)
dim(fpc$scores)
K= 2
print(hotelling.test(fpc$scores[dat$disease==0, 1:K], fpc$scores[dat$disease==1, 1:K]))
