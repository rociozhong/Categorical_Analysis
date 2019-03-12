rm(list = ls())
getwd()
setwd("/Users/Rocio/Library/Mobile Documents/com~apple~CloudDocs/STAT_426")
dta  = read.csv("party113cong.csv", header = T, sep = ",")
str(dta)

summary(dta[, 4:13])
library(stargazer)
stargazer(dta[, 4:13], digits = 1)

# sort the data according to the total population 
df.pop = dta[order(dta$totPop),]

# summary of categorical vars: state, party choice and districts
df3 = xtabs(~state + party, data=dta)
df4 = as.data.frame.matrix(df3)
xtable(df4)

# fit main effect model 
dta$dem = ifelse(dta$party == "D", 1, 0)
fit1 = glm(dem ~ medAge+ medHouseIncome + medFamilyIncome + 
             pctUnemp + pctPov + pctHS + pctBach + pctBlack + pctHisp, family = binomial, data = dta)

summary(fit1)

# main effect and two way interactions 
fullmod1  = glm(dem ~ (medAge+ medHouseIncome + medFamilyIncome + 
                 pctUnemp + pctPov + pctHS + pctBach + pctBlack + pctHisp)^2, family = binomial, data = dta)

# main-effects-only probit
fit2 = glm(dem ~ medAge+ medHouseIncome + medFamilyIncome + 
             pctUnemp + pctPov + pctHS + pctBach + pctBlack + pctHisp, family = binomial(link = "probit"), data = dta)

# main effect and two way interactions probit
fullmod2  = glm(dem ~ (medAge + medHouseIncome + medFamilyIncome + 
                         pctUnemp + pctPov + pctHS + pctBach + pctBlack + pctHisp)^2, family = binomial(link = "probit"), data = dta)

# backward elimination for main logit model 
backfit1 = step(fit1)
summary(backfit1) # houseincome, popHS removed

# backward elimination for full logistic model
backmod1 = step(fullmod1)
summary(backmod1) ## best model, smallest AIC

# backward elimination for main probit model 
backfit2 = step(fit2)
summary(backfit2) # houseincome, pctHS removed

# backward elimination for full probit model
backmod2 = step(fullmod2)
summary(backmod2)

# correlation measure
cor(dta$dem, fitted(backmod1))

# an apparent classification table, with estimated sensitivity and specificity

pi0 = 0.5
table(y=dta$dem, yhat=as.numeric(fitted(backmod1) > pi0))

# apparent sensitivity
161/(41 + 161)

# apparent specificity
204/(204 + 30)

# a cross-validated classification table, with estimated sensitivity and specificity
pihatcv <- numeric(nrow(dta))

for(i in 1:nrow(dta))
  pihatcv[i] <- predict(update(backmod1, subset=-i), newdata=dta[i,],
                        type="response")

table(y=dta$dem, yhat=as.numeric(pihatcv > pi0))

# cross-validated sensitivity
145/(57 + 145)

# cross-validated specificity
192/(192 + 42)


# ROC Curve (Model 3)

n <- nrow(dta)

pihat <- fitted(backmod1)

true.pos <- cumsum(dta$dem[order(pihat, decreasing=TRUE)])

false.pos <- 1:n - true.pos

plot(false.pos/false.pos[n], true.pos/true.pos[n], type="l",
     main="ROC Curve", xlab="1 - Specificity", ylab="Sensitivity")
abline(a=0, b=1, lty=2, col="blue")


mean(outer(pihat[dta$dem==1], pihat[dta$dem==0], ">") +
       0.5 * outer(pihat[dta$dem==1], pihat[dta$dem==0], "=="))
# area under curve (concordance index)


# Graduate section 
# Conditional Dependence of Party and Affluence
# remove all state which has 1 district and DC
library(plyr)
newdf = as.data.frame( dta %>% group_by(state) %>% filter(n() > 1))

# just for check
df  = count(newdf, 'state')
which(df$freq == 1)

# create a wealth indicator var.
# districts with median household income exceeding $52000 as “Wealthy” and others as “Non-Wealthy”
which(newdf$medHouseIncome == 52000)
newdf$wealth = ifelse(newdf$medHouseIncome > 52000, 1, 0) # wealty = 1, non-wealthy = 0

fitwealth = glm(dem ~ wealth + state, family = binomial, data = newdf)
summary(fitwealth)


exp( -1.10e+00)  # MLE of common conditional odds ratio
exp( -1.10e+00  + c(-1,1) * 1.96 * 2.94e-01)  # transformed Wald interval

# Cochran-Mantel-Haenszel Approach

# marginal odds ratio
fitmar = glm(dem ~ wealth, family = binomial, data = newdf)
summary(fitmar)


newdf.array <- xtabs(~dem + wealth + state, data= newdf, drop.unused.levels = T)

newdf.array

mantelhaen.test(newdf.array, correct=FALSE)







