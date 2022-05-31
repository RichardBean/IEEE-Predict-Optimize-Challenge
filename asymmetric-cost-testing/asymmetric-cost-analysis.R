## code for producing spreadsheet error metrics and figures in paper on asymmetric cost metrics

library(MLmetrics) # MAE 

setwd("c:/Users/uqrbean1/OneDrive - The University of Queensland/Documents/ieee")

# create_data_sets is from "mase_calculator.R" in IEEE competition
# ieee_mase() is a truncated version of the calculate_mase() there 

create_test_sets <- function(input_file, forecast_horizon){
  loaded_data <- convert_tsf_to_tsibble(input_file, "series_value", "series_name", "start_timestamp")
  dataset <- loaded_data[[1]]
  
  all_serie_names <- unique(dataset$series_name)
  
  training_set <- list()
  test_set <- matrix(0, nrow = length(all_serie_names), ncol = forecast_horizon)
  
  for(s in seq_along(all_serie_names)){
    series_data <- dataset[dataset$series_name == as.character(all_serie_names[s]), ]
    training_set[[s]] <- series_data[1:(nrow(series_data) - forecast_horizon),][["series_value"]]
    test_set[s,] <- series_data[(nrow(series_data) - forecast_horizon + 1):nrow(series_data),][["series_value"]]
  }
  
  list(training_set, data.frame(test_set), all_serie_names)
}

ieee_mase <- function(input_file, forecasts, forecast_horizon){
  
  output <- create_test_sets(input_file, forecast_horizon)
  training_data <- output[[1]]
  actual_data <- output[[2]]
  
  required_forecasts <- forecasts[-1]
  required_forecasts <- data.frame(sapply(required_forecasts, as.numeric))
  mase_per_series <- NULL
for(k in 1:nrow(required_forecasts))
mase_per_series[k] <- MASE(as.numeric(actual_data[k,]), as.numeric(required_forecasts[k,]), mean(abs(diff(as.numeric(training_data[[k]]), lag = 2688, differences = 1)), na.rm = T))
mean(mase_per_series)
}

# actual.csv is October 2020 data, actnov.csv is November 2020 data 

f2 <- read.csv("actnov.csv",header=F)
realnv <- colSums(f2[1:6,-1])-colSums(f2[7:12,-1])

##################################################################################################################
##################################################################################################################
#### produce the spreadsheet error metrics
##################################################################################################################
##################################################################################################################

for (f in c("ranger2.csv", "i2dh-Nov_submission.csv", "submission_november_18Oct.csv",
            "fresno.csv", "phase2_benchmark.csv", "zhu.csv", "ranger_lg2.csv", "ranger_lg2552.csv", "actual.csv", "actnov.csv",
            "f10p.csv","f20p.csv","f30p.csv","f40p.csv","f50p.csv","f10n.csv","f20n.csv","f30n.csv","f40n.csv","f50n.csv"))
{
  f2 <- read.csv(f,header=F)
  f2[,1] <- building_names
  if (f == "actual.csv") f2 <- f2[,1:2881] # first 30 days of October 2020 
  
  net_load <- colSums(f2[1:6,-1])-colSums(f2[7:12,-1])
  
  cat(f, ieee_mase("nov_data.tsf",f2,2880), MAE(realnv,net_load),  max(realnv-net_load),  max(net_load-realnv), cor(realnv,net_load) ,"\n")
}

#######################

## ggplot with regression line

sim <- read.table("sim-results.csv",header=T,row.names=1,sep=",")
sim1 <- data.frame(t(sim))

colnames(sim1)[1] <- "Mean_MASE"
colnames(sim1)[2] <- "Overall_MAE"
colnames(sim1)[3] <- "Max_Actual_minus_Forecast"
colnames(sim1)[4] <- "Max_Forecast_minus_Actual"
colnames(sim1)[5] <- "Cor_Forecast_Actual"
colnames(sim1)[6] <- "Cost"

## produce MASE vs cost diagram

rs <- gsub(".csv","",rownames(sim1))
rs <- gsub("f10.actual","actual",rs)
rs <- gsub("LG2552","LG_Opt",rs)
pdf(file="Mean_MASE_vs_Cost.pdf")
ggplot(sim1, aes(x=Mean_MASE, y=Cost,label=rs)) + geom_point() +   geom_text()+  geom_smooth(method=lm) + theme(text = element_text(size = 20)) 
dev.off()


####################################################
### derive parameters for Khabibrakhmanov equations

co <- c(34252,35010,34381,35475,35142,35183,34435,34353,37182,33308,33638,34186,33765,34247,35555,33499,33513,33828,33992,34362)

# compare against net forecast
# model cost as 

# a modification of RMSE formula 
cost <- function(net,f,gamma,eps) { N <- length(net); 1/(2*N) * sum((net-f)^2) + 1/N * gamma * sum((net-f)) + eps * 1/(3*N) * sum((net-f)^3) } 

building_names <- c("Building0","Building1","Building3","Building4","Building5","Building6", "Solar0","Solar1","Solar2","Solar3","Solar4","Solar5")

cdiff <- function(gb)
{
  tot <- NULL
  gamma <- gb[1]
  beta <- gb[2]
  
  for (i in 1:20)
  {
    tot <- c(tot, cost(ff[i,],realnv,gamma,beta)) 
  }
  cot <- -cor(co,tot)
  cot
}

## build up a 20 row 2880 col matrix with forecasts 

ff <- matrix(0,nrow=20,ncol=2880)
cl <- c("ranger2.csv", "i2dh-Nov_submission.csv", "submission_november_18Oct.csv",
        "fresno.csv", "phase2_benchmark.csv", "zhu.csv", "ranger_lg2.csv", "ranger_lg2552.csv", "actual.csv", "actnov.csv",
        "f10p.csv","f20p.csv","f30p.csv","f40p.csv","f50p.csv","f10n.csv","f20n.csv","f30n.csv","f40n.csv","f50n.csv")
for (i in 1:20)
{
  f <- cl[i]
  f2 <- read.csv(f,header=F)
  f2[,1] <- building_names
  if (f == "actual.csv") f2 <- f2[,1:2881] # October "actual" 
  ff[i,] <- colSums(f2[1:6,-1])-colSums(f2[7:12,-1])
  
}

##################################################################################################
#### comp entries

cdiff1 <- function(gb)
{
  tot <- NULL
  gamma <- gb[1]
  eps <- gb[2]
  
  for (i in c(1:8,10))  {
    
    tot <- c(tot, cost(ff[i,],realnv,gamma,eps)) 
  }
  cot <- -cor(co[c(1:8,10)],tot)
  cot
}

optim(par=c(1,1),cdiff1,control=list(trace=TRUE))

#########################
#### perturbed 

cdiff2 <- function(gb)
{
  tot <- NULL
  gamma <- gb[1]
  eps <- gb[2]
  
  for (i in c(11:20))
  {
    
    tot <- c(tot, cost(ff[i,],realnv,gamma,eps)) 
  }
  cot <- -cor(co[c(11:20)],tot)
  cot
}

optim(par=c(1,1),cdiff2,control=list(trace=TRUE))

#########################
### combined 

cdiff3 <- function(gb)
{
  tot <- NULL
  gamma <- gb[1]
  eps <- gb[2]
  
  for (i in c(1:8,10:20))
  {
    tot <- c(tot, cost(ff[i,],realnv,gamma,eps)) 
  }
  cot <- -cor(co[c(1:8,10:20)],tot)
  cot
}

optim(par=c(1,1),cdiff3,control=list(trace=TRUE))

##################################################################################################

op <- optim(par=c(1,1),cdiff1,control=list(trace=TRUE))$par

cdiffs <- function(gb)
{
  tot <- NULL
  gamma <- gb[1]
  beta <- gb[2]
  
  for (i in c(1:8,10))
  {
    ff_s <- (ff[i,] - mean(ff[i,]))/sd(ff[i,])
    tot <- c(tot, cost(ff_s,real_s,gamma,beta)) 
  }
  cot <- -cor(co_s[c(1:8,10)],tot)
  cot
}

ops <- optim(par=c(1,1),cdiffs,control=list(trace=TRUE))$par # 1.61 and 0.30
op <- optim(par=c(1,1),cdiff1,control=list(trace=TRUE))$par # 20.98 and 0.001

# Equation 4
# solar forecast needs to be "corrected" to optimize for a specific metric
# i.e. a cost function which takes the forecast as input 

u <- function(ab)
{
  a <- ab[1]
  b <- ab[2]
  
    pnew <- b + a * bean
  
  sum((realnv-pnew)^2)
}

v <- function(ab)
{
  g <- ab[1]
  e <- ab[2]
  a <- ab[3]
  b <- ab[4]
  
  pnew <- b + a * bean
  
  N <- length(bean) # 2880 for Nov
  
  sum(1/(2*N)*sum((realnv-pnew)^2) + 1/N * g * sum(realnv-pnew) + 1 / (3*N) * e * sum((realnv-pnew)^3)  )
}

real_s <- (realnv-mean(realnv)) / sd(realnv)
bean_s <- (bean-mean(bean)) / sd(bean)

vv <- function(ab)
{
  g <- op[1]
  e <- op[2]
  a <- ab[1]
  b <- ab[2]
  
  pnew <- b + a * bean
  
  N <- length(bean) # 2880 for Nov
  
  sum(1/(2*N)*sum((realnv-pnew)^2) + 1/N * g * sum(realnv-pnew) + 1 / (3*N) * e * sum((realnv-pnew)^3)  )
}

o <- optim(par=c(0,0),vv,control=list(trace=TRUE)) # for "regression2.pdf"

# op - [1] 11.049017581  0.001595233 (based on 1:8,10)
# ops - [1] 1.6531516 0.1099052 (based on 1:8,10)

optim(par=c(0,0),u,control=list(trace=TRUE))
library(ggplot2)

# plot the two regression lines for equation U and V 

pdf(file="regression2.pdf")
load <- cbind.data.frame(realnv,bean)
ggplot(load, aes(x=bean,y=realnv)) + 
  geom_point() + 
  geom_smooth(method=lm,aes(colour="Linear regression")) +
  geom_abline(aes(intercept = o$par[2], slope = o$par[1], colour="Corrected regression"),show.legend=F) +
  xlab("Predicted net load (kW)") + ylab("Actual net load (kW)") +
  labs(colour="") + 
  scale_colour_manual(name="", values=c("blue", "red")) +
  theme(text = element_text(size = 20)) +
  theme(legend.position="bottom")
dev.off()