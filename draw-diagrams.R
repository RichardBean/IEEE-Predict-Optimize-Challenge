# plot figures for the paper

library(ggplot2)
library(gridExtra)

source("data_loader.R") # this and "nov_data.tsf" from files downloadable from https://doi.org/10.21227/1x9c-0161

data2 <- convert_tsf_to_tsibble(file="nov_data.tsf",key="series_name") # Building 0  -- 1744.1 values have been changed to 100 

b0 <- data2[[1]][data2[[1]]$series_name=="Building0",c(2,3)] # 148,810 
b1 <- data2[[1]][data2[[1]]$series_name=="Building1",c(2,3)] # 60,483 ... a lot of b1 is one hour data 
b3 <- data2[[1]][data2[[1]]$series_name=="Building3",c(2,3)] # 160,783
b4 <- data2[[1]][data2[[1]]$series_name=="Building4",c(2,3)] # 43,757
b5 <- data2[[1]][data2[[1]]$series_name=="Building5",c(2,3)] # 41,572
b6 <- data2[[1]][data2[[1]]$series_name=="Building6",c(2,3)] # 41,657

s0 <- data2[[1]][data2[[1]]$series_name=="Solar0",c(2,3)] # 15,208
s1 <- data2[[1]][data2[[1]]$series_name=="Solar1",c(2,3)] # 61,388
s2 <- data2[[1]][data2[[1]]$series_name=="Solar2",c(2,3)] # 46,408
s3 <- data2[[1]][data2[[1]]$series_name=="Solar3",c(2,3)] # 46,408
s4 <- data2[[1]][data2[[1]]$series_name=="Solar4",c(2,3)] # 46,408
s5 <- data2[[1]][data2[[1]]$series_name=="Solar5",c(2,3)] # 59,948 - crappy data 

b0_oct20 <- b0[as.POSIXlt(b0$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b0$start_timestamp,tz="UTC")$year == 120,]$series_value
b0_oct20[1710:1713] <- c(152.8, 152.6, 152.3, 152.8) ## my prediction

b1_oct20 <- b1[as.POSIXlt(b1$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b1$start_timestamp,tz="UTC")$year == 120,]$series_value
b3_oct20 <- b3[as.POSIXlt(b3$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b3$start_timestamp,tz="UTC")$year == 120,]$series_value
b4_oct20 <- b4[as.POSIXlt(b4$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b4$start_timestamp,tz="UTC")$year == 120,]$series_value
b5_oct20 <- b5[as.POSIXlt(b5$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b5$start_timestamp,tz="UTC")$year == 120,]$series_value
b6_oct20 <- b6[as.POSIXlt(b6$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(b6$start_timestamp,tz="UTC")$year == 120,]$series_value

s0_oct20 <- s0[as.POSIXlt(s0$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s0$start_timestamp,tz="UTC")$year == 120,]$series_value
s1_oct20 <- s1[as.POSIXlt(s1$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s1$start_timestamp,tz="UTC")$year == 120,]$series_value
s2_oct20 <- s2[as.POSIXlt(s2$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s2$start_timestamp,tz="UTC")$year == 120,]$series_value
s3_oct20 <- s3[as.POSIXlt(s3$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s3$start_timestamp,tz="UTC")$year == 120,]$series_value
s4_oct20 <- s4[as.POSIXlt(s4$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s4$start_timestamp,tz="UTC")$year == 120,]$series_value
s5_oct20 <- s5[as.POSIXlt(s5$start_timestamp,tz="UTC")$mon == 9 & as.POSIXlt(s5$start_timestamp,tz="UTC")$year == 120,]$series_value

###########

rn1 <- read.csv("rangerwd1.csv",header=F) # the final Phase 1 forecast of 2 Nov 2021, with MASE 0.5166 on uncorrected Phase 1 data (Oct 2020)

pdf(file="b1new.pdf")
plot(b1_oct20[1:672],type="l",ylim=c(0,35),ylab="Building 1 (kW)",xlab="Period")
par(new=T)
plot(as.numeric(rn1[2,2:673]),type="l",col="red",ylim=c(0,35),ylab="",xlab="")
legend("topright",title="Building time series", legend=c("Actual","Forecast"),col=c("black","red"),lty=1)
dev.off()

pdf(file="s0new.pdf")
plot(s0_oct20[1:672],type="l",ylim=c(0,55),ylab="Solar 0 (kW)",xlab="Period")
par(new=T)
plot(as.numeric(rn1[7,2:673]),type="l",col="red",ylim=c(0,55),ylab="",xlab="")
legend("topright",title="Solar time series", legend=c("Actual","Forecast"),col=c("black","red"),lty=1)
dev.off()

#####
pdf(file="qq.pdf")
tenth <- function(x) { y <- x$series_value/max(x$series_value); y <- y[sample(length(y),length(y)/10)] }

qqnorm(tenth(s0),col=1,xlim=c(0,3),ylim=c(0,1))
par(new=T)
qqnorm(tenth(s1),col=2,xlim=c(0,3),ylim=c(0,1))
par(new=T)
qqnorm(tenth(s2),col=3,xlim=c(0,3),ylim=c(0,1))
par(new=T)
qqnorm(tenth(s3),col=4,xlim=c(0,3),ylim=c(0,1))
par(new=T)
qqnorm(tenth(s4),col=5,xlim=c(0,3),ylim=c(0,1))
par(new=T)
qqnorm(tenth(s5),col=6,xlim=c(0,3),ylim=c(0,1))
legend("bottomright",title="Solar time series", legend=c("Solar0","Solar1","Solar2","Solar3","Solar4","Solar5"),col=1:6,lty=1)
dev.off()

####

lims <- as.POSIXct(strptime(c("2020-10-01 00:00","2020-10-31 23:45"),format="%Y-%m-%d %H:%M"))

data0 <- s0[as.POSIXlt(s0$start_timestamp)$year == 120 & as.POSIXlt(s0$start_timestamp)$mon == 9,]
data1 <- s1[as.POSIXlt(s1$start_timestamp)$year == 120 & as.POSIXlt(s1$start_timestamp)$mon == 9,]
data2 <- s2[as.POSIXlt(s2$start_timestamp)$year == 120 & as.POSIXlt(s2$start_timestamp)$mon == 9,]
data3 <- s3[as.POSIXlt(s3$start_timestamp)$year == 120 & as.POSIXlt(s3$start_timestamp)$mon == 9,]
data4 <- s4[as.POSIXlt(s4$start_timestamp)$year == 120 & as.POSIXlt(s4$start_timestamp)$mon == 9,]
data5 <- s5[as.POSIXlt(s5$start_timestamp)$year == 120 & as.POSIXlt(s5$start_timestamp)$mon == 9,]

p0 <- ggplot(data0,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar0 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p1 <- ggplot(data1,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar1 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p2 <- ggplot(data2,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar2 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p3 <- ggplot(data3,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar3 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p4 <- ggplot(data4,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar4 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p5 <- ggplot(data5,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Solar5 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))

pdf("ggsolar.pdf")
grid.arrange(p0,p1,p2,p3,p4,p5)
dev.off()

###

b0[which(b0$series_value > 1700 & b0$series_value < 1800),]$series_value <- 100 # fix silly values for the chart
data0 <- b0[as.POSIXlt(b0$start_timestamp)$year == 120 & as.POSIXlt(b0$start_timestamp)$mon == 9,]
data1 <- b1[as.POSIXlt(b1$start_timestamp)$year == 120 & as.POSIXlt(b1$start_timestamp)$mon == 9,]
data2 <- b3[as.POSIXlt(b3$start_timestamp)$year == 120 & as.POSIXlt(b3$start_timestamp)$mon == 9,]
data3 <- b4[as.POSIXlt(b4$start_timestamp)$year == 120 & as.POSIXlt(b4$start_timestamp)$mon == 9,]
data4 <- b5[as.POSIXlt(b5$start_timestamp)$year == 120 & as.POSIXlt(b5$start_timestamp)$mon == 9,]
data5 <- b6[as.POSIXlt(b6$start_timestamp)$year == 120 & as.POSIXlt(b6$start_timestamp)$mon == 9,]


p0 <- ggplot(data0,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building0 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p1 <- ggplot(data1,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building1 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p2 <- ggplot(data2,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building3 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p3 <- ggplot(data3,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building4 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p4 <- ggplot(data4,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building5 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))
p5 <- ggplot(data5,aes(x=start_timestamp, y=series_value)) + geom_line() + xlab("")+ ylab("Building6 (kW)") + scale_x_datetime(limits=lims,expand=c(0,0))

pdf("ggbuild.pdf")
grid.arrange(p0,p1,p2,p3,p4,p5)
dev.off()
