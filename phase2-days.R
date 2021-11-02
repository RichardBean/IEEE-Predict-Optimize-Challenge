### Phase 1/2 using ranger -- final -- Sat 30 October 2021
### solar uses 39 variables - mtry = 13

### building forecasts b0,1,3,6 together then takes b0 and b3 out - with mtry = 43

### forecast b1 with mtry = 2
### forecast b6 with mtry = 19

PHASE <- 2

FLIST <- c("phase_1_data.tsf","phase_2_data.tsf")

PDAY <- c(31,30)
PMONTH <- c(10,11)

DAYS <- PDAY[PHASE]
PERIODS <- DAYS * 24 * 4
HOURS <- DAYS * 24
HOUR1 <- HOURS - 1
FIRSTPERIOD <- paste("2020-",PMONTH[PHASE],"-01 00:00:00",sep="")

MTRY_B0136 <- 43
MTRY_B1 <- 2
MTRY_B6 <- 19 
MTRY_SOLAR <- 13

TREES <- 2000

FILE <- FLIST[PHASE]

#### PHASE 2 forecast -- use BOM and ECMWF data 

library(lubridate) # with_tz 
library(xts)
library(ranger)
source("data_loader.R")

setwd("C:/users/uqrbean1/OneDrive - The University of Queensland/Documents/ieee")

### training Building / Solar data

data2 <- convert_tsf_to_tsibble(file=FILE,key="series_name") # Building 0  -- 1744.1 values are unfixed 

#########################
########### BOM #########
#########################

bom <- read.csv("bos.csv",header=F) # 731 days 3 columns 

b20 <- as.POSIXlt("2019-01-01 00:00:00",tz="UTC")+(0:17543)*3600
btime <- with_tz(b20,tzone="Australia/Melbourne")
rl <- rle(as.POSIXlt(btime,tz="Australia/Melbourne")$yday)$lengths

brep <- matrix(0,ncol=ncol(bom),nrow=nrow(bom)*24)

for (i in 1:ncol(brep))
  brep[,i] <- c(rep(bom[,i],times=rl[1:731]),rep(NA,11)) ## fix for bomsolar.csv

###################################################################################################################################################
#
# BUILDING DATA
#
###################################################################################################################################################

e5oo <- read.csv("ERA5_Weather_Data_Monash.csv") ## UTC date time -- this should match b0 etc - merge.xts is useful 
e5o <- e5oo[,-c(2,3,4,5)]
etime <- as.POSIXlt(e5o$datetime..UTC.,tz="UTC")

e5o <- e5o[etime$year %in% 119:120,]
etime <- as.POSIXlt(e5o$datetime..UTC.,tz="UTC")
etime_mel <- with_tz(etime,tzone="Australia/Melbourne")

nr <- nrow(e5o)

e5x <- cbind.data.frame(e5o, 
                        b8 = brep[,1],
                        b9 = brep[,2],
                        b10 = brep[,3],
                        t1= c(rep(NA,1),e5o$temperature..degC.[1:(nr-1)]),
                        t2= c(rep(NA,2),e5o$temperature..degC.[1:(nr-2)]),
                        t3= c(rep(NA,3),e5o$temperature..degC.[1:(nr-3)]),
                        tf =c(e5o$temperature..degC.[2:(nr)],rep(NA,1)),
                        tf2=c(e5o$temperature..degC.[3:(nr)],rep(NA,2)),
                        tf3=c(e5o$temperature..degC.[4:(nr)],rep(NA,3)),
                        t24=c(rep(NA,24),e5o$temperature..degC.[1:(nr-24)]),
                        t48=c(rep(NA,48),e5o$temperature..degC.[1:(nr-48)]),
                        t72=c(rep(NA,72),e5o$temperature..degC.[1:(nr-72)]),
                        s1=c(rep(NA,1),e5o$surface_solar_radiation..W.m.2.[1:(nr-1)]),
                        s2=c(rep(NA,2),e5o$surface_solar_radiation..W.m.2.[1:(nr-2)]),
                        s3=c(rep(NA,3),e5o$surface_solar_radiation..W.m.2.[1:(nr-3)]),
                        sf =c(e5o$surface_solar_radiation..W.m.2.[2:(nr)],rep(NA,1)),
                        sf2=c(e5o$surface_solar_radiation..W.m.2.[3:(nr)],rep(NA,2)),
                        sf3=c(e5o$surface_solar_radiation..W.m.2.[4:(nr)],rep(NA,3)),
                        st1=c(rep(NA,1),e5o$surface_thermal_radiation..W.m.2.[1:(nr-1)]),
                        st2=c(rep(NA,2),e5o$surface_thermal_radiation..W.m.2.[1:(nr-2)]),
                        st3=c(rep(NA,3),e5o$surface_thermal_radiation..W.m.2.[1:(nr-3)]),
                        stf =c(e5o$surface_thermal_radiation..W.m.2.[2:nr],rep(NA,1)),
                        stf2=c(e5o$surface_thermal_radiation..W.m.2.[3:nr],rep(NA,2)),
                        stf3=c(e5o$surface_thermal_radiation..W.m.2.[4:nr],rep(NA,3)),
                        w1=c(rep(NA,1),e5o$wind_speed..m.s.[1:(nr-1)]),
                        w2=c(rep(NA,2),e5o$wind_speed..m.s.[1:(nr-2)]),
                        w3=c(rep(NA,3),e5o$wind_speed..m.s.[1:(nr-3)]),
                        wf1=c(e5o$wind_speed..m.s.[2:(nr)],rep(NA,1)),
                        wf2=c(e5o$wind_speed..m.s.[3:(nr)],rep(NA,2)),
                        wf3=c(e5o$wind_speed..m.s.[4:(nr)],rep(NA,3)),
                        d1=c(rep(NA,1),e5o$dewpoint_temperature..degC.[1:(nr-1)]),
                        d2=c(rep(NA,2),e5o$dewpoint_temperature..degC.[1:(nr-2)]),
                        d3=c(rep(NA,3),e5o$dewpoint_temperature..degC.[1:(nr-3)]),
                        df1=c(e5o$dewpoint_temperature..degC.[2:(nr)],rep(NA,1)),
                        df2=c(e5o$dewpoint_temperature..degC.[3:(nr)],rep(NA,2)),
                        df3=c(e5o$dewpoint_temperature..degC.[4:(nr)],rep(NA,3)),
                        rh1=c(rep(NA,1),e5o$relative_humidity...0.1..[1:(nr-1)]),
                        rh2=c(rep(NA,2),e5o$relative_humidity...0.1..[1:(nr-2)]),
                        rh3=c(rep(NA,3),e5o$relative_humidity...0.1..[1:(nr-3)]),
                        rhf1=c(e5o$relative_humidity...0.1..[2:(nr)],rep(NA,1)),
                        rhf2=c(e5o$relative_humidity...0.1..[3:(nr)],rep(NA,2)),
                        rhf3=c(e5o$relative_humidity...0.1..[4:(nr)],rep(NA,3)),
                        cc1=c(rep(NA,1),e5o$total_cloud_cover..0.1.[1:(nr-1)]),
                        cc2=c(rep(NA,2),e5o$total_cloud_cover..0.1.[1:(nr-2)]),
                        cc3=c(rep(NA,3),e5o$total_cloud_cover..0.1.[1:(nr-3)]),
                        ccf1=c(e5o$total_cloud_cover..0.1.[2:(nr)],rep(NA,1)),
                        ccf2=c(e5o$total_cloud_cover..0.1.[3:(nr)],rep(NA,2)),
                        ccf3=c(e5o$total_cloud_cover..0.1.[4:(nr)],rep(NA,3)),
                        mslp1=c(rep(NA,1),e5o$mean_sea_level_pressure..Pa.[1:(nr-1)]),
                        mslpf=c(e5o$mean_sea_level_pressure..Pa.[1:(nr-1)],rep(NA,1)),
                        hr1=etime$hour,
                        sin_hr = sin(2*pi*(etime$hour*60+etime$min)/1440),
                        cos_hr = cos(2*pi*(etime$hour*60+etime$min)/1440),
                        wd = 1*(etime_mel$wd %in% c(0,6)),
                        wd1 = 1*(etime_mel$wd %in% c(1,5)),
                        wd2 = 1*(etime_mel$wd %in% c(2,3,4)),
                        wdx0 = 1*(etime_mel$wd == 0),
                        wdx1 = 1*(etime_mel$wd == 1),
                        wdx2 = 1*(etime_mel$wd == 2),
                        wdx3 = 1*(etime_mel$wd == 3),
                        wdx4 = 1*(etime_mel$wd == 4),
                        wdx5 = 1*(etime_mel$wd == 5),
                        wdx6 = 1*(etime_mel$wd == 6),
                        sin_day = sin(2*pi*etime$yday/365),
                        cos_day = cos(2*pi*etime$yday/365)) 

if (PHASE==2) e5x[etime_mel$year == 120 & etime_mel$yday == as.POSIXlt("2020-10-23")$yday,]$wd <- NA ## Oct 23 grand final holiday -- not good for prediction -- omit

e5time <- as.POSIXlt(e5x[,1],tz="UTC")
e5xts <- xts(e5x[,-1],order.by=e5time,tzone="UTC")

nov1 <- which(e5x$datetime..UTC.==FIRSTPERIOD)
e5_nov20 <- e5x[nov1:(nov1+768+24),]
e5_nov20_time <- as.POSIXlt(e5_nov20[,1],tz="UTC")
e5_nov20_xts <- xts(e5_nov20[,-1],order.by=e5_nov20_time,tzone="UTC")

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

s0_time <- as.POSIXlt(s0$start_timestamp,tz="UTC")
s1_time <- as.POSIXlt(s1$start_timestamp,tz="UTC")
s2_time <- as.POSIXlt(s2$start_timestamp,tz="UTC")
s3_time <- as.POSIXlt(s3$start_timestamp,tz="UTC")
s4_time <- as.POSIXlt(s4$start_timestamp,tz="UTC")
s5_time <- as.POSIXlt(s5$start_timestamp,tz="UTC")

b0$series_value[b0$series_value > 606.5] <- NA ## this also fixes the rubbish in October 2020 data 
b3$series_value[b3$series_value > 2264] <- NA
b3$series_value[b3$series_value < 193] <- NA

b0_time <- as.POSIXlt(b0$start_timestamp,tz="UTC")
b1_time <- as.POSIXlt(b1$start_timestamp,tz="UTC")
b3_time <- as.POSIXlt(b3$start_timestamp,tz="UTC")
b4_time <- as.POSIXlt(b4$start_timestamp,tz="UTC")
b5_time <- as.POSIXlt(b5$start_timestamp,tz="UTC")
b6_time <- as.POSIXlt(b6$start_timestamp,tz="UTC")

b0xts <- xts(b0$series_value,order.by=b0_time)
b1xts <- xts(b1$series_value,order.by=b1_time)
b3xts <- xts(b3$series_value,order.by=b3_time)
b4xts <- xts(b4$series_value,order.by=b4_time)
b5xts <- xts(b5$series_value,order.by=b5_time)
b6xts <- xts(b6$series_value,order.by=b6_time)

nb0 <- nrow(b0)
nb1 <- nrow(b1)
nb3 <- nrow(b3)
nb4 <- nrow(b4)
nb5 <- nrow(b5)
nb6 <- nrow(b6)

b0xx <- cbind.data.frame(x1=b0[seq(3,nb0-3,4),]$series_value,x2=b0[seq(4,nb0-2,4),]$series_value,x3=b0[seq(5,nb0-1,4),]$series_value,x4=b0[seq(6,nb0,4),]$series_value)
b1xx <- cbind.data.frame(x1=b1[seq(4,nb1-3,4),]$series_value,x2=b1[seq(5,nb1-2,4),]$series_value,x3=b1[seq(6,nb1-1,4),]$series_value,x4=b1[seq(7,nb1,4),]$series_value)
b3xx <- cbind.data.frame(x1=b3[seq(4,nb3-3,4),]$series_value,x2=b3[seq(5,nb3-2,4),]$series_value,x3=b3[seq(6,nb3-1,4),]$series_value,x4=b3[seq(7,nb3,4),]$series_value)
b4xx <- cbind.data.frame(x1=b4[seq(2,nb4-3,4),]$series_value,x2=b4[seq(3,nb4-2,4),]$series_value,x3=b4[seq(4,nb4-1,4),]$series_value,x4=b4[seq(5,nb4,4),]$series_value)
b5xx <- cbind.data.frame(x1=b5[seq(1,nb5-3,4),]$series_value,x2=b5[seq(2,nb5-2,4),]$series_value,x3=b5[seq(3,nb5-1,4),]$series_value,x4=b5[seq(4,nb5,4),]$series_value)
b6xx <- cbind.data.frame(x1=b6[seq(2,nb6-3,4),]$series_value,x2=b6[seq(3,nb6-2,4),]$series_value,x3=b6[seq(4,nb6-1,4),]$series_value,x4=b6[seq(5,nb6,4),]$series_value)

b0xts <- xts(b0xx,order.by=b0_time[seq(3,nb0,4),],tzone="UTC")
b1xts <- xts(b1xx,order.by=b1_time[seq(4,nb1,4),],tzone="UTC")
b3xts <- xts(b3xx,order.by=b3_time[seq(4,nb3,4),],tzone="UTC")
b4xts <- xts(b4xx,order.by=b4_time[seq(2,nb4,4),],tzone="UTC")
b5xts <- xts(b5xx,order.by=b5_time[seq(1,nb5,4),],tzone="UTC")
b6xts <- xts(b6xx,order.by=b6_time[seq(2,nb6,4),],tzone="UTC")

b0e <- merge.xts(e5xts,b0xts)
b1e <- merge.xts(e5xts,b1xts)
b3e <- merge.xts(e5xts,b3xts)
b4e <- merge.xts(e5xts,b4xts)
b5e <- merge.xts(e5xts,b5xts)
b6e <- merge.xts(e5xts,b6xts)

b0e_time <- as.POSIXlt(index(b0e),tz="UTC")
b1e_time <- as.POSIXlt(index(b1e),tz="UTC")
b3e_time <- as.POSIXlt(index(b3e),tz="UTC")
b6e_time <- as.POSIXlt(index(b6e),tz="UTC")

#######

btop <- names(e5x)
btop0<-c("b10","b8","b9","cos_day","cos_hr","hr1","mslp1","rhf1","s1","s2","s3","sf","sf2","sf3","sin_day","sin_hr","surface_solar_radiation..W.m.2.","t72","tf","wd","wdx0","wdx1","wdx2","wdx3","wdx4","wdx5","wdx6")
#### OLD btop1<-c("b8","cos_day","cos_hr","df3","hr1","s1","sf","sf2","sf3","sin_day","surface_solar_radiation..W.m.2.","t1","t2","t24","temperature..degC.","tf","tf2","tf3","wd","wd1","wd2")

btop1<-c("b8","cos_day","cos_hr","b9","b10","hr1","s1","sf","sf2","sf3","sin_day","surface_solar_radiation..W.m.2.","t1","t2","t24","temperature..degC.","tf","tf2","tf3","wd","wd1","wd2","wdx0","wdx1","wdx2","wdx3","wdx4","wdx5","wdx6")

#### BAD btop3<-c("b10","b8","b9","cos_day","cos_hr","hr1","mean_sea_level_pressure..Pa.","mslp1","mslpf","rh3","s1","s2","s3","sf","sf2","sf3","sin_day","sin_hr","surface_solar_radiation..W.m.2.","t1","t2","t24","t3","t48","t72","temperature..degC.","tf")

btop3 <- c("b10", "b8" , "b9", "cos_day", "cos_hr", "hr1" ,"mean_sea_level_pressure..Pa.", "mslp1", "mslpf",  "s1", "s2" , "s3","sf","sf2","sf3","sin_day","sin_hr" ,
           "surface_solar_radiation..W.m.2.", "t1","t2","t24","t3","t48" , "t72" ,"temperature..degC.","tf", "wd", "wd1" , "wd2", "wdx0","wdx1","wdx2","wdx3","wdx4","wdx5","wdx6" )

#######

###### first we do our multi-forecast for b0, b1, b3 and b6 all together -- mtry = 43 

b0etrain <- na.omit(b0e[b0e_time$year == 120 & b0e_time$mon >= 5,])
b1etrain <- na.omit(b1e[b1e_time$year == 120 & b1e_time$mon >= 1,])
b3etrain <- na.omit(b3e[b3e_time$year == 120 & b3e_time$mon >= 4,])
b6etrain <- na.omit(b6e[b6e_time$year == 120 & b6e_time$mon >= 0,])

lx1 <- which(colnames(b0etrain)=="x1")
lx2 <- which(colnames(b0etrain)=="x2")
lx3 <- which(colnames(b0etrain)=="x3")
lx4 <- which(colnames(b0etrain)=="x4")

b0_t1 <- b0etrain[,-c(lx2,lx3,lx4)]
b0_t2 <- b0etrain[,-c(lx1,lx3,lx4)]
b0_t3 <- b0etrain[,-c(lx1,lx2,lx4)]
b0_t4 <- b0etrain[,-c(lx1,lx2,lx3)]

b1_t1 <- b1etrain[,-c(lx2,lx3,lx4)]
b1_t2 <- b1etrain[,-c(lx1,lx3,lx4)]
b1_t3 <- b1etrain[,-c(lx1,lx2,lx4)]
b1_t4 <- b1etrain[,-c(lx1,lx2,lx3)]

b3_t1 <- b3etrain[,-c(lx2,lx3,lx4)]
b3_t2 <- b3etrain[,-c(lx1,lx3,lx4)]
b3_t3 <- b3etrain[,-c(lx1,lx2,lx4)]
b3_t4 <- b3etrain[,-c(lx1,lx2,lx3)]

b6_t1 <- b6etrain[,-c(lx2,lx3,lx4)]
b6_t2 <- b6etrain[,-c(lx1,lx3,lx4)]
b6_t3 <- b6etrain[,-c(lx1,lx2,lx4)]
b6_t4 <- b6etrain[,-c(lx1,lx2,lx3)]

###
btop <- names(e5x)

b0_t1 <- cbind.data.frame(wh=6,b0_t1[,which(names(b0_t1) %in% c("x1",btop))])
b0_t2 <- cbind.data.frame(wh=6,b0_t2[,which(names(b0_t2) %in% c("x2",btop))])
b0_t3 <- cbind.data.frame(wh=6,b0_t3[,which(names(b0_t3) %in% c("x3",btop))])
b0_t4 <- cbind.data.frame(wh=6,b0_t4[,which(names(b0_t4) %in% c("x4",btop))])

b1_t1 <- cbind.data.frame(wh=7,b1_t1[,which(names(b1_t1) %in% c("x1",btop))])
b1_t2 <- cbind.data.frame(wh=7,b1_t2[,which(names(b1_t2) %in% c("x2",btop))])
b1_t3 <- cbind.data.frame(wh=7,b1_t3[,which(names(b1_t3) %in% c("x3",btop))])
b1_t4 <- cbind.data.frame(wh=7,b1_t4[,which(names(b1_t4) %in% c("x4",btop))])

b3_t1 <- cbind.data.frame(wh=8,b3_t1[,which(names(b3_t1) %in% c("x1",btop))])
b3_t2 <- cbind.data.frame(wh=8,b3_t2[,which(names(b3_t2) %in% c("x2",btop))])
b3_t3 <- cbind.data.frame(wh=8,b3_t3[,which(names(b3_t3) %in% c("x3",btop))])
b3_t4 <- cbind.data.frame(wh=8,b3_t4[,which(names(b3_t4) %in% c("x4",btop))])

b6_t1 <- cbind.data.frame(wh=9,b6_t1[,which(names(b6_t1) %in% c("x1",btop))])
b6_t2 <- cbind.data.frame(wh=9,b6_t2[,which(names(b6_t2) %in% c("x2",btop))])
b6_t3 <- cbind.data.frame(wh=9,b6_t3[,which(names(b6_t3) %in% c("x3",btop))])
b6_t4 <- cbind.data.frame(wh=9,b6_t4[,which(names(b6_t4) %in% c("x4",btop))])

##

bmax <- c(
  max(c(b0etrain$x1,b0etrain$x2,b0etrain$x3,b0etrain$x4)),
  max(c(b1etrain$x1,b1etrain$x2,b1etrain$x3,b1etrain$x4)),
  max(c(b3etrain$x1,b3etrain$x2,b3etrain$x3,b3etrain$x4)),
  max(c(b6etrain$x1,b6etrain$x2,b6etrain$x3,b6etrain$x4))
)

b0_t1$x1 <- b0_t1$x1 / bmax[1]
b0_t2$x2 <- b0_t2$x2 / bmax[1]
b0_t3$x3 <- b0_t3$x3 / bmax[1]
b0_t4$x4 <- b0_t4$x4 / bmax[1]

b1_t1$x1 <- b1_t1$x1 / bmax[2]
b1_t2$x2 <- b1_t2$x2 / bmax[2]
b1_t3$x3 <- b1_t3$x3 / bmax[2]
b1_t4$x4 <- b1_t4$x4 / bmax[2]

b3_t1$x1 <- b3_t1$x1 / bmax[3]
b3_t2$x2 <- b3_t2$x2 / bmax[3]
b3_t3$x3 <- b3_t3$x3 / bmax[3]
b3_t4$x4 <- b3_t4$x4 / bmax[3]

b6_t1$x1 <- b6_t1$x1 / bmax[4]
b6_t2$x2 <- b6_t2$x2 / bmax[4]
b6_t3$x3 <- b6_t3$x3 / bmax[4]
b6_t4$x4 <- b6_t4$x4 / bmax[4]

b0136_t1 <- rbind(b0_t1,b1_t1,b3_t1,b6_t1)
b0136_t2 <- rbind(b0_t2,b1_t2,b3_t2,b6_t2)
b0136_t3 <- rbind(b0_t3,b1_t3,b3_t3,b6_t3)
b0136_t4 <- rbind(b0_t4,b1_t4,b3_t4,b6_t4)

# 21800 * 68 

co <- ncol(b0136_t1)
e5sub <- e5_nov20_xts[,which(names(e5_nov20_xts) %in% names(b0136_t1))]
e5sub6 <- cbind.data.frame(wh=6,e5sub)
e5sub7 <- cbind.data.frame(wh=7,e5sub)
e5sub8 <- cbind.data.frame(wh=8,e5sub)
e5sub9 <- cbind.data.frame(wh=9,e5sub)

b0136_rf1 <- ranger(x1~.,data=b0136_t1,mtry=MTRY_B0136,num.trees = TREES,quantreg = T)
b0136_rf2 <- ranger(x2~.,data=b0136_t2,mtry=MTRY_B0136,num.trees = TREES,quantreg = T)
b0136_rf3 <- ranger(x3~.,data=b0136_t3,mtry=MTRY_B0136,num.trees = TREES,quantreg = T)
b0136_rf4 <- ranger(x4~.,data=b0136_t4,mtry=MTRY_B0136,num.trees = TREES,quantreg = T)

b0rf_out1 <- predict(b0136_rf1,data=e5sub6,type="quantiles",quantiles=.5)$predictions*bmax[1]
b0rf_out2 <- predict(b0136_rf2,data=e5sub6,type="quantiles",quantiles=.5)$predictions*bmax[1]
b0rf_out3 <- predict(b0136_rf3,data=e5sub6,type="quantiles",quantiles=.5)$predictions*bmax[1]
b0rf_out4 <- predict(b0136_rf4,data=e5sub6,type="quantiles",quantiles=.5)$predictions*bmax[1]
b0_inter <- rep(0,PERIODS)

### b0 is special -- b0rf_out1 ultimately unused 

b0_inter[1] <- b0etrain[nrow(b0etrain),]$x4 # last value from 2020-xx-30 
b0_inter[seq(2,PERIODS,4)] <- (b0rf_out2[1:HOURS]+b0rf_out3[1:HOURS]+b0rf_out4[1:HOURS])/3
b0_inter[seq(3,PERIODS,4)] <- (b0rf_out2[1:HOURS]+b0rf_out3[1:HOURS]+b0rf_out4[1:HOURS])/3
b0_inter[seq(4,PERIODS,4)] <- (b0rf_out2[1:HOURS]+b0rf_out3[1:HOURS]+b0rf_out4[1:HOURS])/3
b0_inter[seq(5,PERIODS,4)] <- (b0rf_out2[1:HOUR1]+b0rf_out3[1:HOUR1]+b0rf_out4[1:HOUR1])/3

b3rf_out1 <- predict(b0136_rf1,data=e5sub8,type="quantiles",quantiles=.5)$predictions*bmax[3]
b3rf_out2 <- predict(b0136_rf2,data=e5sub8,type="quantiles",quantiles=.5)$predictions*bmax[3]
b3rf_out3 <- predict(b0136_rf3,data=e5sub8,type="quantiles",quantiles=.5)$predictions*bmax[3]
b3rf_out4 <- predict(b0136_rf4,data=e5sub8,type="quantiles",quantiles=.5)$predictions*bmax[3]

### b3 is special 

b3_inter <- rep(0,PERIODS)
b3_inter[1] <- b3etrain[nrow(b3etrain),]$x4 # last value from 2020-xx-30
b3_inter[seq(2,PERIODS,4)] <- (b3rf_out2[1:HOURS]+b3rf_out3[1:HOURS]+b3rf_out4[1:HOURS])/3
b3_inter[seq(3,PERIODS,4)] <- (b3rf_out2[1:HOURS]+b3rf_out3[1:HOURS]+b3rf_out4[1:HOURS])/3
b3_inter[seq(4,PERIODS,4)] <- (b3rf_out2[1:HOURS]+b3rf_out3[1:HOURS]+b3rf_out4[1:HOURS])/3
b3_inter[seq(5,PERIODS,4)] <- (b3rf_out1[2:HOURS]+b3rf_out2[1:HOUR1]+b3rf_out3[1:HOUR1]+b3rf_out4[1:HOUR1])/4

###############

### now b1 and b6 have their own models - b1 mtry = 2 and b6 mtry = 19
### not normalized here 

b1e_time <- as.POSIXlt(index(b1e),tz="UTC")
b1etrain <- na.omit(b1e[b1e_time$year == 120 & b1e_time$mon >= 1 ,]) 

b1_t1 <- b1etrain[,-c(lx2,lx3,lx4)]
b1_t2 <- b1etrain[,-c(lx1,lx3,lx4)]
b1_t3 <- b1etrain[,-c(lx1,lx2,lx4)]
b1_t4 <- b1etrain[,-c(lx1,lx2,lx3)]

b1_t1 <- b1_t1[,which(names(b1_t1) %in% c("x1",btop1))]
b1_t2 <- b1_t2[,which(names(b1_t2) %in% c("x2",btop1))]
b1_t3 <- b1_t3[,which(names(b1_t3) %in% c("x3",btop1))]
b1_t4 <- b1_t4[,which(names(b1_t4) %in% c("x4",btop1))]

b1_rf1 <- ranger(x1~.,data=b1_t1,mtry=MTRY_B1,num.trees = TREES,quantreg = T)
b1_rf2 <- ranger(x2~.,data=b1_t2,mtry=MTRY_B1,num.trees = TREES,quantreg = T)
b1_rf3 <- ranger(x3~.,data=b1_t3,mtry=MTRY_B1,num.trees = TREES,quantreg = T)
b1_rf4 <- ranger(x4~.,data=b1_t4,mtry=MTRY_B1,num.trees = TREES,quantreg = T)

e5sub <- e5_nov20_xts[,which(names(e5_nov20_xts) %in% names(b1_t1))]

b1rf_out1 <- predict(b1_rf1,data=e5sub,type="quantiles",quantiles=.5)$predictions
b1rf_out2 <- predict(b1_rf2,data=e5sub,type="quantiles",quantiles=.5)$predictions
b1rf_out3 <- predict(b1_rf3,data=e5sub,type="quantiles",quantiles=.5)$predictions
b1rf_out4 <- predict(b1_rf4,data=e5sub,type="quantiles",quantiles=.5)$predictions

b1_inter <- rep(0,PERIODS)
b1_inter[seq(1,PERIODS,4)] <- b1rf_out1[1:HOURS]
b1_inter[seq(2,PERIODS,4)] <- b1rf_out2[1:HOURS]
b1_inter[seq(3,PERIODS,4)] <- b1rf_out3[1:HOURS]
b1_inter[seq(4,PERIODS,4)] <- b1rf_out4[1:HOURS]

###

b6e_time <- as.POSIXlt(index(b6e),tz="UTC")
b6etrain <- na.omit(b6e[b6e_time$year == 120 & b6e_time$mon >= 0,]) 

b6_t1 <- b6etrain[,-c(lx2,lx3,lx4)]
b6_t2 <- b6etrain[,-c(lx1,lx3,lx4)]
b6_t3 <- b6etrain[,-c(lx1,lx2,lx4)]
b6_t4 <- b6etrain[,-c(lx1,lx2,lx3)]

b6_t1 <- b6_t1[,which(names(b6_t1) %in% c("x1",btop))]
b6_t2 <- b6_t2[,which(names(b6_t2) %in% c("x2",btop))]
b6_t3 <- b6_t3[,which(names(b6_t3) %in% c("x3",btop))]
b6_t4 <- b6_t4[,which(names(b6_t4) %in% c("x4",btop))]

b6_rf1 <- ranger(x1~.,data=b6_t1,mtry=MTRY_B6,num.trees = TREES,quantreg = T)
b6_rf2 <- ranger(x2~.,data=b6_t2,mtry=MTRY_B6,num.trees = TREES,quantreg = T)
b6_rf3 <- ranger(x3~.,data=b6_t3,mtry=MTRY_B6,num.trees = TREES,quantreg = T)
b6_rf4 <- ranger(x4~.,data=b6_t4,mtry=MTRY_B6,num.trees = TREES,quantreg = T)

e5sub <- e5_nov20_xts[,which(names(e5_nov20_xts) %in% names(b6_t1))]

b6rf_out1 <- predict(b6_rf1,data=e5sub,type="quantiles",quantiles=.5)$predictions
b6rf_out2 <- predict(b6_rf2,data=e5sub,type="quantiles",quantiles=.5)$predictions
b6rf_out3 <- predict(b6_rf3,data=e5sub,type="quantiles",quantiles=.5)$predictions
b6rf_out4 <- predict(b6_rf4,data=e5sub,type="quantiles",quantiles=.5)$predictions

b6_inter <- rep(0,PERIODS)
b6_inter[seq(1,PERIODS,4)] <- b6rf_out1[1:HOURS]
b6_inter[seq(2,PERIODS,4)] <- b6rf_out2[1:HOURS]
b6_inter[seq(3,PERIODS,4)] <- b6rf_out3[1:HOURS]
b6_inter[seq(4,PERIODS,4)] <- b6rf_out4[1:HOURS]

## b4 and b5 aren't predicted -- just repeats 

b4_inter <- rep(1,PERIODS)
b5_inter <- rep(19,PERIODS)

###############################################
#
# SOLAR DATA
#
###############################################

b5oo <- read.csv("ERA5_Weather_Data_Monash.csv") ## UTC date time -- this should match b0 etc - merge.xts is useful 
b5oo <- b5oo[,-c(2,3,4,5)]

btime <- as.POSIXlt(b5oo$datetime..UTC.,tz="UTC")
b5o <- b5oo[btime$year %in% 119:120,]

btime <- as.POSIXlt(b5o$datetime..UTC.,tz="UTC")

nr <- nrow(b5o)

b5x <- cbind.data.frame(b5o, 
                        b8 = brep[,1],
                        b9 = brep[,2],
                        b10 = brep[,3],
                        t1= c(rep(NA,1),b5o$temperature..degC.[1:(nr-1)]),
                        t2= c(rep(NA,2),b5o$temperature..degC.[1:(nr-2)]),
                        t3= c(rep(NA,3),b5o$temperature..degC.[1:(nr-3)]),
                        tf =c(b5o$temperature..degC.[2:(nr)],rep(NA,1)),
                        tf2=c(b5o$temperature..degC.[3:(nr)],rep(NA,2)),
                        tf3=c(b5o$temperature..degC.[4:(nr)],rep(NA,3)),
                        s1=c(rep(NA,1),b5o$surface_solar_radiation..W.m.2.[1:(nr-1)]),
                        s2=c(rep(NA,2),b5o$surface_solar_radiation..W.m.2.[1:(nr-2)]),
                        s3=c(rep(NA,3),b5o$surface_solar_radiation..W.m.2.[1:(nr-3)]),
                        sf =c(b5o$surface_solar_radiation..W.m.2.[2:(nr)],rep(NA,1)),
                        sf2=c(b5o$surface_solar_radiation..W.m.2.[3:(nr)],rep(NA,2)),
                        sf3=c(b5o$surface_solar_radiation..W.m.2.[4:(nr)],rep(NA,3)),
                        
                        st1=c(rep(NA,1),b5o$surface_thermal_radiation..W.m.2.[1:(nr-1)]),
                        st2=c(rep(NA,2),b5o$surface_thermal_radiation..W.m.2.[1:(nr-2)]),
                        st3=c(rep(NA,3),b5o$surface_thermal_radiation..W.m.2.[1:(nr-3)]),
                        
                        stf =c(b5o$surface_thermal_radiation..W.m.2.[2:nr],rep(NA,1)),
                        stf2=c(b5o$surface_thermal_radiation..W.m.2.[3:nr],rep(NA,2)),
                        stf3=c(b5o$surface_thermal_radiation..W.m.2.[4:nr],rep(NA,3)),
                        
                        cc1=c(rep(NA,1),b5o$total_cloud_cover..0.1.[1:(nr-1)]),
                        cc2=c(rep(NA,2),b5o$total_cloud_cover..0.1.[1:(nr-2)]),
                        cc3=c(rep(NA,3),b5o$total_cloud_cover..0.1.[1:(nr-3)]),
                        ccf1=c(b5o$total_cloud_cover..0.1.[2:(nr)],rep(NA,1)),
                        ccf2=c(b5o$total_cloud_cover..0.1.[3:(nr)],rep(NA,2)),
                        ccf3=c(b5o$total_cloud_cover..0.1.[4:(nr)],rep(NA,3)),
                        
                        mslp1=c(rep(NA,1),b5o$mean_sea_level_pressure..Pa.[1:(nr-1)]),
                        
                        mslpf1=c(b5o$mean_sea_level_pressure..Pa.[2:(nr)],rep(NA,1)),
                        
                        sin_hr = sin(2*pi*(btime$hour*60+btime$min)/1440),
                        cos_hr = cos(2*pi*(btime$hour*60+btime$min)/1440),
                        sin_day = sin(2*pi*btime$yday/365),
                        cos_day = cos(2*pi*btime$yday/365)) 

b5time <- as.POSIXlt(b5x[,1],tz="UTC")
a5xts <- xts(b5x[,-1],order.by=b5time)

nov1 <- which(b5x$datetime..UTC.==FIRSTPERIOD)
b5_nov20 <- b5x[nov1:(nov1+768),]
b5_nov20_time <- as.POSIXlt(b5_nov20[,1],tz="UTC")
b5_nov20_xts <- xts(b5_nov20[,-1],order.by=b5_nov20_time)

ns0 <- nrow(s0)
ns1 <- nrow(s1)
ns2 <- nrow(s2)
ns3 <- nrow(s3)
ns4 <- nrow(s4)
ns5 <- nrow(s5)

s0xx <- cbind.data.frame(x1=s0[seq(1,ns0-3,4),]$series_value,x2=s0[seq(2,ns0-2,4),]$series_value,x3=s0[seq(3,ns0-1,4),]$series_value,x4=s0[seq(4,ns0,4),]$series_value)
s1xx <- cbind.data.frame(x1=s1[seq(1,ns1-3,4),]$series_value,x2=s1[seq(2,ns1-2,4),]$series_value,x3=s1[seq(3,ns1-1,4),]$series_value,x4=s1[seq(4,ns1,4),]$series_value)
s2xx <- cbind.data.frame(x1=s2[seq(1,ns2-3,4),]$series_value,x2=s2[seq(2,ns2-2,4),]$series_value,x3=s2[seq(3,ns2-1,4),]$series_value,x4=s2[seq(4,ns2,4),]$series_value)
s3xx <- cbind.data.frame(x1=s3[seq(1,ns3-3,4),]$series_value,x2=s3[seq(2,ns3-2,4),]$series_value,x3=s3[seq(3,ns3-1,4),]$series_value,x4=s3[seq(4,ns3,4),]$series_value)
s4xx <- cbind.data.frame(x1=s4[seq(1,ns4-3,4),]$series_value,x2=s4[seq(2,ns4-2,4),]$series_value,x3=s4[seq(3,ns4-1,4),]$series_value,x4=s4[seq(4,ns4,4),]$series_value)
s5xx <- cbind.data.frame(x1=s5[seq(1,ns5-3,4),]$series_value,x2=s5[seq(2,ns5-2,4),]$series_value,x3=s5[seq(3,ns5-1,4),]$series_value,x4=s5[seq(4,ns5,4),]$series_value)

s0xts <- xts(s0xx,order.by=s0_time[seq(1,ns0-3,4),],tzone="UTC")
s1xts <- xts(s1xx,order.by=s1_time[seq(1,ns1-3,4),],tzone="UTC")
s2xts <- xts(s2xx,order.by=s2_time[seq(1,ns2-3,4),],tzone="UTC")
s3xts <- xts(s3xx,order.by=s3_time[seq(1,ns3-3,4),],tzone="UTC")
s4xts <- xts(s4xx,order.by=s4_time[seq(1,ns4-3,4),],tzone="UTC")
s5xts <- xts(s5xx,order.by=s5_time[seq(1,ns5-3,4),],tzone="UTC")

s0e <- merge.xts(a5xts,s0xts)
s1e <- merge.xts(a5xts,s1xts)
s2e <- merge.xts(a5xts,s2xts)
s3e <- merge.xts(a5xts,s3xts)
s4e <- merge.xts(a5xts,s4xts)
s5e <- merge.xts(a5xts,s5xts)

s1e_time <- as.POSIXlt(index(s1e),tz="UTC")
s2e_time <- as.POSIXlt(index(s2e),tz="UTC")
s3e_time <- as.POSIXlt(index(s3e),tz="UTC")

stop <- setdiff(names(b5x),c("wind_speed..m.s.","relative_humidity...0.1..","dewpoint_temperature..degC."))

#############################


#s0etrain <- na.omit(s0e) ## 30 Oct
s0etrain <- na.omit(s0e[s0e$x1 > 0.05 | s0e$x2 > 0.05 | s0e$x3 > 0.05 | s0e$x4 > 0.05,]) ## 31 Oct
s1etrain <- na.omit(s1e[s1e_time$year == 120 & s1e_time$yday >= 142,])
s2etrain <- na.omit(s2e[s2e_time$year == 120 & s2e_time$yday >= 142,])
s3etrain <- na.omit(s3e[s3e_time$year == 120 & s3e_time$yday >= 142,])
s4etrain <- na.omit(s4e)
s5etrain <- na.omit(s5e[s5e$x1 > 0.05 | s5e$x2 > 0.05 | s5e$x3 > 0.05 | s5e$x4 > 0.05,])

lx1 <- which(colnames(s0etrain)=="x1")
lx2 <- which(colnames(s0etrain)=="x2")
lx3 <- which(colnames(s0etrain)=="x3")
lx4 <- which(colnames(s0etrain)=="x4")

s0_t1 <- s0etrain[,-c(lx2,lx3,lx4)]
s0_t2 <- s0etrain[,-c(lx1,lx3,lx4)]
s0_t3 <- s0etrain[,-c(lx1,lx2,lx4)]
s0_t4 <- s0etrain[,-c(lx1,lx2,lx3)]

s1_t1 <- s1etrain[,-c(lx2,lx3,lx4)]
s1_t2 <- s1etrain[,-c(lx1,lx3,lx4)]
s1_t3 <- s1etrain[,-c(lx1,lx2,lx4)]
s1_t4 <- s1etrain[,-c(lx1,lx2,lx3)]

s2_t1 <- s2etrain[,-c(lx2,lx3,lx4)]
s2_t2 <- s2etrain[,-c(lx1,lx3,lx4)]
s2_t3 <- s2etrain[,-c(lx1,lx2,lx4)]
s2_t4 <- s2etrain[,-c(lx1,lx2,lx3)]

s3_t1 <- s3etrain[,-c(lx2,lx3,lx4)]
s3_t2 <- s3etrain[,-c(lx1,lx3,lx4)]
s3_t3 <- s3etrain[,-c(lx1,lx2,lx4)]
s3_t4 <- s3etrain[,-c(lx1,lx2,lx3)]

s4_t1 <- s4etrain[,-c(lx2,lx3,lx4)]
s4_t2 <- s4etrain[,-c(lx1,lx3,lx4)]
s4_t3 <- s4etrain[,-c(lx1,lx2,lx4)]
s4_t4 <- s4etrain[,-c(lx1,lx2,lx3)]

s5_t1 <- s5etrain[,-c(lx2,lx3,lx4)]
s5_t2 <- s5etrain[,-c(lx1,lx3,lx4)]
s5_t3 <- s5etrain[,-c(lx1,lx2,lx4)]
s5_t4 <- s5etrain[,-c(lx1,lx2,lx3)]

###

s0_t1 <- cbind.data.frame(wh=0,s0_t1[,which(names(s0_t1) %in% c("x1",stop))])
s0_t2 <- cbind.data.frame(wh=0,s0_t2[,which(names(s0_t2) %in% c("x2",stop))])
s0_t3 <- cbind.data.frame(wh=0,s0_t3[,which(names(s0_t3) %in% c("x3",stop))])
s0_t4 <- cbind.data.frame(wh=0,s0_t4[,which(names(s0_t4) %in% c("x4",stop))])

s1_t1 <- cbind.data.frame(wh=1,s1_t1[,which(names(s1_t1) %in% c("x1",stop))])
s1_t2 <- cbind.data.frame(wh=1,s1_t2[,which(names(s1_t2) %in% c("x2",stop))])
s1_t3 <- cbind.data.frame(wh=1,s1_t3[,which(names(s1_t3) %in% c("x3",stop))])
s1_t4 <- cbind.data.frame(wh=1,s1_t4[,which(names(s1_t4) %in% c("x4",stop))])

s2_t1 <- cbind.data.frame(wh=2,s2_t1[,which(names(s2_t1) %in% c("x1",stop))])
s2_t2 <- cbind.data.frame(wh=2,s2_t2[,which(names(s2_t2) %in% c("x2",stop))])
s2_t3 <- cbind.data.frame(wh=2,s2_t3[,which(names(s2_t3) %in% c("x3",stop))])
s2_t4 <- cbind.data.frame(wh=2,s2_t4[,which(names(s2_t4) %in% c("x4",stop))])

s3_t1 <- cbind.data.frame(wh=3,s3_t1[,which(names(s3_t1) %in% c("x1",stop))])
s3_t2 <- cbind.data.frame(wh=3,s3_t2[,which(names(s3_t2) %in% c("x2",stop))])
s3_t3 <- cbind.data.frame(wh=3,s3_t3[,which(names(s3_t3) %in% c("x3",stop))])
s3_t4 <- cbind.data.frame(wh=3,s3_t4[,which(names(s3_t4) %in% c("x4",stop))])

s4_t1 <- cbind.data.frame(wh=4,s4_t1[,which(names(s4_t1) %in% c("x1",stop))])
s4_t2 <- cbind.data.frame(wh=4,s4_t2[,which(names(s4_t2) %in% c("x2",stop))])
s4_t3 <- cbind.data.frame(wh=4,s4_t3[,which(names(s4_t3) %in% c("x3",stop))])
s4_t4 <- cbind.data.frame(wh=4,s4_t4[,which(names(s4_t4) %in% c("x4",stop))])

s5_t1 <- cbind.data.frame(wh=5,s5_t1[,which(names(s5_t1) %in% c("x1",stop))])
s5_t2 <- cbind.data.frame(wh=5,s5_t2[,which(names(s5_t2) %in% c("x2",stop))])
s5_t3 <- cbind.data.frame(wh=5,s5_t3[,which(names(s5_t3) %in% c("x3",stop))])
s5_t4 <- cbind.data.frame(wh=5,s5_t4[,which(names(s5_t4) %in% c("x4",stop))])

###

smax <- c(max(c(s0etrain$x1,s0etrain$x2,s0etrain$x3,s0etrain$x4)),
          max(c(s1etrain$x1,s1etrain$x2,s1etrain$x3,s1etrain$x4)),
          max(c(s2etrain$x1,s2etrain$x2,s2etrain$x3,s2etrain$x4)),
          max(c(s3etrain$x1,s3etrain$x2,s3etrain$x3,s3etrain$x4)),
          max(c(s4etrain$x1,s4etrain$x2,s4etrain$x3,s4etrain$x4)),
          max(c(s5etrain$x1,s5etrain$x2,s5etrain$x3,s5etrain$x4))
)

s0_t1$x1 <- s0_t1$x1 / smax[1]
s0_t2$x2 <- s0_t2$x2 / smax[1]
s0_t3$x3 <- s0_t3$x3 / smax[1]
s0_t4$x4 <- s0_t4$x4 / smax[1]

s1_t1$x1 <- s1_t1$x1 / smax[2]
s1_t2$x2 <- s1_t2$x2 / smax[2]
s1_t3$x3 <- s1_t3$x3 / smax[2]
s1_t4$x4 <- s1_t4$x4 / smax[2]

s2_t1$x1 <- s2_t1$x1 / smax[3]
s2_t2$x2 <- s2_t2$x2 / smax[3]
s2_t3$x3 <- s2_t3$x3 / smax[3]
s2_t4$x4 <- s2_t4$x4 / smax[3]

s3_t1$x1 <- s3_t1$x1 / smax[4]
s3_t2$x2 <- s3_t2$x2 / smax[4]
s3_t3$x3 <- s3_t3$x3 / smax[4]
s3_t4$x4 <- s3_t4$x4 / smax[4]

s4_t1$x1 <- s4_t1$x1 / smax[5]
s4_t2$x2 <- s4_t2$x2 / smax[5]
s4_t3$x3 <- s4_t3$x3 / smax[5]
s4_t4$x4 <- s4_t4$x4 / smax[5]

s5_t1$x1 <- s5_t1$x1 / smax[6]
s5_t2$x2 <- s5_t2$x2 / smax[6]
s5_t3$x3 <- s5_t3$x3 / smax[6]
s5_t4$x4 <- s5_t4$x4 / smax[6]

s012345_t1 <- rbind(s0_t1,s1_t1,s2_t1,s3_t1,s4_t1,s5_t1)
s012345_t2 <- rbind(s0_t2,s1_t2,s2_t2,s3_t2,s4_t2,s5_t2)
s012345_t3 <- rbind(s0_t3,s1_t3,s2_t3,s3_t3,s4_t3,s5_t3)
s012345_t4 <- rbind(s0_t4,s1_t4,s2_t4,s3_t4,s4_t4,s5_t4)

# 33547 * 40

co <- ncol(s012345_t1)
e5sub <- b5_nov20_xts[,which(names(b5_nov20_xts) %in% names(s012345_t1))]
e5sub0 <- cbind.data.frame(wh=0,e5sub)
e5sub1 <- cbind.data.frame(wh=1,e5sub)
e5sub2 <- cbind.data.frame(wh=2,e5sub)
e5sub3 <- cbind.data.frame(wh=3,e5sub)
e5sub4 <- cbind.data.frame(wh=4,e5sub)
e5sub5 <- cbind.data.frame(wh=5,e5sub)

s012345_rf1 <- ranger(x1~.,data=s012345_t1,mtry=MTRY_SOLAR,num.trees = TREES,quantreg = T)
s012345_rf2 <- ranger(x2~.,data=s012345_t2,mtry=MTRY_SOLAR,num.trees = TREES,quantreg = T)
s012345_rf3 <- ranger(x3~.,data=s012345_t3,mtry=MTRY_SOLAR,num.trees = TREES,quantreg = T)
s012345_rf4 <- ranger(x4~.,data=s012345_t4,mtry=MTRY_SOLAR,num.trees = TREES,quantreg = T)

s0rf_out1 <- predict(s012345_rf1,data=e5sub0,type="quantiles",quantiles=.5)$predictions*smax[1]
s0rf_out2 <- predict(s012345_rf2,data=e5sub0,type="quantiles",quantiles=.5)$predictions*smax[1]
s0rf_out3 <- predict(s012345_rf3,data=e5sub0,type="quantiles",quantiles=.5)$predictions*smax[1]
s0rf_out4 <- predict(s012345_rf4,data=e5sub0,type="quantiles",quantiles=.5)$predictions*smax[1]

s0_inter <- rep(0,PERIODS)
s0_inter[seq(1,PERIODS,4)] <- s0rf_out1[1:HOURS]
s0_inter[seq(2,PERIODS,4)] <- s0rf_out2[1:HOURS]
s0_inter[seq(3,PERIODS,4)] <- s0rf_out3[1:HOURS]
s0_inter[seq(4,PERIODS,4)] <- s0rf_out4[1:HOURS]

s1rf_out1 <- predict(s012345_rf1,data=e5sub1,type="quantiles",quantiles=.5)$predictions*smax[2]
s1rf_out2 <- predict(s012345_rf2,data=e5sub1,type="quantiles",quantiles=.5)$predictions*smax[2]
s1rf_out3 <- predict(s012345_rf3,data=e5sub1,type="quantiles",quantiles=.5)$predictions*smax[2]
s1rf_out4 <- predict(s012345_rf4,data=e5sub1,type="quantiles",quantiles=.5)$predictions*smax[2]
s1_inter <- rep(0,PERIODS)
s1_inter[seq(1,PERIODS,4)] <- s1rf_out1[1:HOURS]
s1_inter[seq(2,PERIODS,4)] <- s1rf_out2[1:HOURS]
s1_inter[seq(3,PERIODS,4)] <- s1rf_out3[1:HOURS]
s1_inter[seq(4,PERIODS,4)] <- s1rf_out4[1:HOURS]

s2rf_out1 <- predict(s012345_rf1,data=e5sub2,type="quantiles",quantiles=.5)$predictions*smax[3]
s2rf_out2 <- predict(s012345_rf2,data=e5sub2,type="quantiles",quantiles=.5)$predictions*smax[3]
s2rf_out3 <- predict(s012345_rf3,data=e5sub2,type="quantiles",quantiles=.5)$predictions*smax[3]
s2rf_out4 <- predict(s012345_rf4,data=e5sub2,type="quantiles",quantiles=.5)$predictions*smax[3]
s2_inter <- rep(0,PERIODS)
s2_inter[seq(1,PERIODS,4)] <- s2rf_out1[1:HOURS]
s2_inter[seq(2,PERIODS,4)] <- s2rf_out2[1:HOURS]
s2_inter[seq(3,PERIODS,4)] <- s2rf_out3[1:HOURS]
s2_inter[seq(4,PERIODS,4)] <- s2rf_out4[1:HOURS]

s3rf_out1 <- predict(s012345_rf1,data=e5sub3,type="quantiles",quantiles=.5)$predictions*smax[4]
s3rf_out2 <- predict(s012345_rf2,data=e5sub3,type="quantiles",quantiles=.5)$predictions*smax[4]
s3rf_out3 <- predict(s012345_rf3,data=e5sub3,type="quantiles",quantiles=.5)$predictions*smax[4]
s3rf_out4 <- predict(s012345_rf4,data=e5sub3,type="quantiles",quantiles=.5)$predictions*smax[4]
s3_inter <- rep(0,PERIODS)
s3_inter[seq(1,PERIODS,4)] <- s3rf_out1[1:HOURS]
s3_inter[seq(2,PERIODS,4)] <- s3rf_out2[1:HOURS]
s3_inter[seq(3,PERIODS,4)] <- s3rf_out3[1:HOURS]
s3_inter[seq(4,PERIODS,4)] <- s3rf_out4[1:HOURS]

s4rf_out1 <- predict(s012345_rf1,data=e5sub4,type="quantiles",quantiles=.5)$predictions*smax[5]
s4rf_out2 <- predict(s012345_rf2,data=e5sub4,type="quantiles",quantiles=.5)$predictions*smax[5]
s4rf_out3 <- predict(s012345_rf3,data=e5sub4,type="quantiles",quantiles=.5)$predictions*smax[5]
s4rf_out4 <- predict(s012345_rf4,data=e5sub4,type="quantiles",quantiles=.5)$predictions*smax[5]
s4_inter <- rep(0,PERIODS)
s4_inter[seq(1,PERIODS,4)] <- s4rf_out1[1:HOURS]
s4_inter[seq(2,PERIODS,4)] <- s4rf_out2[1:HOURS]
s4_inter[seq(3,PERIODS,4)] <- s4rf_out3[1:HOURS]
s4_inter[seq(4,PERIODS,4)] <- s4rf_out4[1:HOURS]

s5rf_out1 <- predict(s012345_rf1,data=e5sub5,type="quantiles",quantiles=.5)$predictions*smax[6]
s5rf_out2 <- predict(s012345_rf2,data=e5sub5,type="quantiles",quantiles=.5)$predictions*smax[6]
s5rf_out3 <- predict(s012345_rf3,data=e5sub5,type="quantiles",quantiles=.5)$predictions*smax[6]
s5rf_out4 <- predict(s012345_rf4,data=e5sub5,type="quantiles",quantiles=.5)$predictions*smax[6]
s5_inter <- rep(0,PERIODS)
s5_inter[seq(1,PERIODS,4)] <- s5rf_out1[1:HOURS]
s5_inter[seq(2,PERIODS,4)] <- s5rf_out2[1:HOURS]
s5_inter[seq(3,PERIODS,4)] <- s5rf_out3[1:HOURS]
s5_inter[seq(4,PERIODS,4)] <- s5rf_out4[1:HOURS]

########################################################
ss <- rbind(c("Building0",b0_inter),c("Building1",b1_inter),c("Building3",b3_inter),c("Building4",b4_inter),c("Building5",b5_inter),c("Building6",b6_inter),
            c("Solar0",s0_inter),c("Solar1",s1_inter),c("Solar2",s2_inter),c("Solar3",s3_inter),c("Solar4",s4_inter),c("Solar5",s5_inter))

for (i in 1:12)
  ss[i,-1] <- round(as.numeric(ss[i,-1]),2)

outfile <- paste("ranger",PHASE,".csv",sep="")
write.table(ss,outfile,row.names = F,quote=F,col.names=F,sep=",")

flatfile <- paste("ranger",PHASE,".flat",sep="")
ss1 <- apply(ss[,-1],2,as.numeric)
netload <- colSums(ss1[1:6,])-colSums(ss1[7:12,]) 
write(netload,flatfile,ncolumns=1)