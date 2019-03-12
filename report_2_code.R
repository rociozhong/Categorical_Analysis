rm(list = ls())
getwd()
setwd("/Users/Rocio/Library/Mobile Documents/com~apple~CloudDocs/STAT_426")
cyclone <- read.table("cyclone.txt", header = T)

names(cyclone)
dim(cyclone)

# Describe and summarize the variables. 
# Include a table of marginal totals (summed over all seasons) 
# of each category for each basin, and comment. Also, for each basin separately, 
# produce a plot of total number of storms versus August ONI.



#install.packages("stargazer")
library(stargazer)
stargazer(cyclone, summary = T)

attach(cyclone)
dta_by_season <- aggregate(cyclone[, 3:6], by = list(Category = Season), FUN = sum)
dta_by_basin <- aggregate(cyclone[, 3:6], by = list(Category = Basin), FUN = sum)

library(xtable)
xtable(dta_by_basin)
xtable(dta_by_season)

library(ggplot2)
g <- ggplot(data = cyclone, aes(x = ONIAug, y = Total, colour = Basin))
g + geom_point() + scale_colour_grey() 

## Fit a loglinear regression model for the total number of named storms,
## with a term for season (linear in year — not categorical), 
## basin (indicator variable), August ONI, and interaction between basin and August ONI.
cycfit <- glm(Total ~ Season + factor(Basin) + ONIAug + ONIAug*factor(Basin), 
              family = poisson, data = cyclone)
summary(cycfit)

stargazer(cycfit, title = "Results of loglinear regression")



## Goodness-of-Fit Test
deviance(cycfit)
df.residual(cycfit)
1 - pchisq(deviance(cycfit), df.residual(cycfit)) ## p-value, cannot reject the null hypothesis


## For log(mu), basin NorthAtlantic intercept will be
intercept_na <- coef(cycfit)[1] + coef(cycfit)[3] 
## slope for ONIAug for basin NorthAtlantic
slope_aug_na <- coef(cycfit)[4] + coef(cycfit)[5]


## For log(mu), basinEasternPacific intercept is
coef(cycfit)[1]
## slope for ONIAug for basin EasternPacific
coef(cycfit)[4]

## multiplicative effect of a one-unit increase in August ONI 
## on the mean number of named storms, for basin NorthAtlantic
exp(coef(cycfit)[4] + coef(cycfit)[5]) 

## multiplicative effect of a one-unit increase in August ONI 
## on the mean number of named storms, for basin EasternPacific
exp(coef(cycfit)[4]) 


## Consider logistic regression for the probability that a named tropical cyclone
## becomes a major hurricane
## 3 way interaction between season, basin and ONIAug
cycfull <- glm(cbind(MajorHurricane, Total - MajorHurricane) ~ Season * factor(Basin) * ONIAug,
               family = binomial, data = cyclone)

summary(cycfull)

## backward elimination

backmod <- step(cycfull)
summary(backmod)

## coef for basin EasternPacific
coef_ep <- c(coef(backmod)[1], coef(backmod)[2], coef(backmod)[4])

## coefs for basin NorthAtlantic
coef_na <- c(coef(backmod)[1] + coef(backmod)[3], coef(backmod)[2] + coef(backmod)[5], 
  coef(backmod)[4] + coef(backmod)[6])

## create a table for 2017 different ONI AUG values
pred_data <- data.frame(matrix(0, 6, 3))
colnames(pred_data) <- c("Season", "Basin", "ONIAug")
pred_data$Season <- rep(2017, 6)
pred_data$Basin <- c(rep("EasternPacific", 3), rep("NorthAtlantic", 3))
pred_data$ONIAug <- rep(c(-1.5, 0, 1.5), 2)
pred_data$y <- predict(backmod, pred_data, type = "response")
pred_data


## double check 
ep_fun<- function(oniaug, year){
  result <- coef_ep[1] + coef_ep[2]*year + coef_ep[3]*oniaug
  return(result)
}

na_fun <- function(oniaug, year){
  result <- coef_na[1] + coef_na[2]*year + coef_na[3]*oniaug
  return(result)
}

exp(unname(ep_fun(c(-1.5, 0, 1.5), 2017)))/ (1 + exp(unname(ep_fun(c(-1.5, 0, 1.5), 2017))))
exp(unname(na_fun(c(-1.5, 0, 1.5), 2017)))/ (1 + exp(unname(na_fun(c(-1.5, 0, 1.5), 2017))))

## a) For the loglinear regression: For each basin, 
## form a (transformed) Wald 95% confidence interval 
## for the multiplicative effect of a one-unit increase in August ONI 
## on the mean number of named storms.

# for basin EaternPacific:
beta_vcov = vcov(cycfit)
ci_ep = exp(c(cycfit$coefficients[4] - 1.96*sqrt(beta_vcov[4,4]),
             cycfit$coefficients[4] + 1.96*sqrt(beta_vcov[4,4])))

# for basin NorthAtlantic:
slope_na_se = sqrt(beta_vcov[4,4] + 2*beta_vcov[4,5] + beta_vcov[5,5])
ci_na = exp(c(slope_aug_na - 1.96 * slope_na_se, 
            slope_aug_na + 1.96 * slope_na_se))

ci_ep
ci_na

## b) For the logistic regression: 
## Assess the fit of your final model (after backward elimination) 
## using appropriate residuals.
backmod_res_pearson <- residuals(backmod, "pearson")
backmod_res_dev <- residuals(backmod)

sum(residuals(backmod, "pearson")^2) ## 
deviance(backmod) ## deviance
1- pchisq(deviance(backmod), df.residual(backmod)) 
## p-value is large indicating no evidence of lack of fit.
which(abs(rstandard(backmod, type  = "pearson")) > 2)
which(abs(rstandard(backmod, type  = "pearson")) > 3)

library(grid)
library(gridExtra)
p1 <- ggplot(data = cyclone, aes(x = fitted(backmod), y = backmod_res_pearson)) + geom_point()
p2 <- ggplot(data = cyclone, aes(x = fitted(backmod), y = backmod_res_dev)) + geom_point()
grid.arrange(p1, p2, ncol = 2)
