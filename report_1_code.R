rm(list = ls())

## Setup ##
Nsim = 100000
n_1976 = 318.0
n_1995 = 315.0

## define pearson chi-sq stat 
statPearson = function(obs, exp){
  stat = sum((obs - exp)^2/ exp)
  return(stat)
}

## define likelihood ratio chi-sq stat
statLRT = function(obs, exp){
  g.sq = 2* sum(obs * log(obs/exp))
  return(g.sq)
}

## estimates of proportions 
pi_d1 = 280.0/n_1976
pi_d2 = 254.0/n_1995
odds1 = pi_d1 / (1-pi_d1)
odds2 = pi_d2 / (1-pi_d2)

## relative risk 
rr = (pi_d1/pi_d2)

## odds ratio 
theta = (odds1/odds2)

print(paste("1976 Death Rate:", pi_d1))
print(paste("1995 Death Rate:", pi_d2))
print(paste("The relatie risk:", rr))
print(paste("The odds ratio:", theta))


## calculate CI for proportions, relative risk, and the odds ratio ##
se_pi_d1 = sqrt(pi_d1 * (1-pi_d1) / n_1976)
se_pi_d2 = sqrt(pi_d2 * (1-pi_d2) / n_1995)
se_log_rr = sqrt(38.0/(280.0*318.0) + 61.0/(254.0*315))
se_theta = sqrt(1.0/38 + 1.0/280 + 1.0/61 + 1.0/254)

pi_d1_ci = c(pi_d1 - 1.96 * se_pi_d1, pi_d1 + 1.96 * se_pi_d1)
pi_d2_ci = c(pi_d2 - 1.96 * se_pi_d2, pi_d2 + 1.96 * se_pi_d2)
rr_ci = exp(c(log(rr)-1.96*se_log_rr, log(rr) + 1.96*se_log_rr))
theta_ci = exp(c(log(theta) - 1.96 * se_theta, log(theta) + 1.96 * se_theta))

### Pearson Chi-Squared Test 
obs = c(280.0, 38.0, 254.0, 61.0)
mle = (280.0 + 254.0) / (n_1976 + n_1995)
exp = c(318*mle, 318*(1-mle), 315*mle, 315*(1-mle))
pearson_obs = statPearson(obs, exp)
lrt_obs  = statLRT(obs, exp)

## p-value for Pearson and LRT
pearson_pvalue = 1- pchisq(pearson_obs, df = 1)
lrt_pvalue = 1 - pchisq(lrt_obs, df = 1)

## simulation ##
pearson_extreme  = rep(0, Nsim)
lrt_extreme = rep(0, Nsim)
obser  = matrix(nrow = Nsim, ncol = 4, 0)
expec = matrix(nrow = Nsim, ncol = 4, 0)
MLE = rep(0, Nsim)
emp_pearsonstat  = rep(0, Nsim)
emp_lrtstat = rep(0, Nsim)

set.seed(111)
for(i in 1: Nsim){
  d_1976 = rbinom(1, 318, mle)
  d_1995 = rbinom(1, 315, mle)
  obser[i, ] =  c(d_1976, n_1976 - d_1976, d_1995, n_1995 - d_1995)
  MLE[i] = (d_1976 + d_1995) / (n_1976 + n_1995)
  expec[i, ] = c(n_1976*MLE[i], n_1976*(1-MLE[i]), n_1995*MLE[i], n_1995*(1-MLE[i]))
  
  pearson_extreme[i] = statPearson(obser[i, ], expec[i, ]) > pearson_obs
  lrt_extreme[i] = statLRT(obser[i, ], expec[i, ]) > lrt_obs
  
  emp_pearsonstat[i] = statPearson(obser[i, ], expec[i, ])
  emp_lrtstat[i] = statLRT(obser[i, ], expec[i, ])
  
  empirical_lrt_pvalue = sum(pearson_extreme)/ Nsim
  empirical_pearson_pvalue = sum(lrt_extreme) / Nsim
}


hist(emp_pearsonstat, prob = T, main = "Empirical Pearson Chi-sq Statistics & Reference Chi-sq (1)")
x = rchisq(Nsim, df = 1)
curve(dchisq(x, df=1), col='red', add=TRUE ) 

hist(emp_lrtstat, prob = T, main = "Empirical Likelihood Ratio Chi-sq and Reference Chi-sq(1)")
x = rchisq(Nsim, df = 1)
curve(dchisq(x, df=1), col='red', add=TRUE ) 

empirical_lrt_pvalue
empirical_pearson_pvalue


#research question: H0: pi_1d = pi_2d +0.05 vs Ha: pi_1d > pi_2d +0.05
#use Asymptotic Normality
test = (pi_d1 - pi_d2 - 0.05) / sqrt(se_pi_d1^2 + se_pi_d2^2)
ptest = 1 - pnorm(test, lower.tail = T)
ptest
