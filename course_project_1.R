csvfile <- "activity.csv"
if (!file.exists(csvfile)) {
        zipfile <- "repdata_data_activity.zip"
        if (!file.exists(zipfile)) {
                stop("Cannot find data files")
        } else {
                unzip(zipfile)
                if (!file.exists(csvfile)) {stop("Unzip Error")}
        }
}
# Load the data (i.e. read.csv())
data <- read.csv(csvfile)
# Process/transform the data (if necessary) into a format suitable for your analysis
# Get dates into better format
min<-as.character(data$interval%%100)
hr <-as.character(floor(data$interval/100))
hrmin <- paste(sep=":",hr,min,"00")
data$min <-min
data$hr  <-hr
data$time<-as.POSIXct(paste(as.character(data$date),hrmin))


# histogram and mean total number of steps each day
total.by.day<-tapply(data$steps,data$date,FUN=sum)
hist(total.by.day,breaks=10,
     main="Histogram of Total Number of Steps per Day",xlab="Steps",ylab="Frequency")

meanstep  <-mean(total.by.day,na.rm=TRUE)
medianstep<-median(total.by.day,na.rm=TRUE)


mean.by.minutesegment<-aggregate(data$steps,data["min"],FUN=mean,na.rm=TRUE)
mean.by.minutesegment<-mean.by.minutesegment[order(as.numeric(mean.by.minutesegment$min)),]
colnames(mean.by.minutesegment)<-c("min","steps")
plot(mean.by.minutesegment,type="l",
     xlab="5 Minute Interval (by Beginning Minute)",
     ylab="Mean Number of Steps",
     main="Mean Steps by Interval")


maxidx      <- which.max(mean.by.minutesegment$steps)
maxsegname  <- mean.by.minutesegment$min[maxidx]  # max segment for printing
maxsegsteps <- mean.by.minutesegment$steps[maxidx]  # max value value for printing



# here I cheat a little.  I assume that all the intervals and dates
# are there rather than imputing them
numnastep <- sum(as.numeric(is.na(data$step))) # number of missing values - steps
# impute the steps by taking the median across that interval for all days
median.by.interval<-aggregate(data$steps,data["interval"],median,na.rm=TRUE)
colnames(median.by.interval) <- c("interval","imputed")
data.na.rm<-data
data.na.rm$origsteps<-data.na.rm$steps #store original data including NAs
data.na.rm <- merge(data.na.rm,median.by.interval,by="interval")
data.na.rm[is.na(data.na.rm$steps),"steps"]<-data.na.rm[is.na(data.na.rm$steps),"imputed"]
# I'm going to keep this array, but resort into the same order 
# as the original frame "data" and drop the columns "origsteps" and "imputed"
# to make it identical to "data" but with steps replaced by steps if there's
# data and imputed steps if there's an NA.  This decision is based on
# what the assignment says: 
# "Create a new dataset that is equal to the original 
#  dataset but with the missing data filled in."
# The new frame is called "dataimpute"
dataimpute <- data.na.rm[,!(names(data.na.rm) %in% c("origsteps","imputed"))]
dataimpute <- dataimpute[order(dataimpute$time),]
dataimpute<-dataimpute[,names(data)]
# get mean and median from imputed data
total.by.day.impute<-tapply(dataimpute$steps,dataimpute$date,FUN=sum)
hist(total.by.day.impute,breaks=10,
     main="Histogram of Total Number of Steps per Day\nWith Imputed Values",
     xlab="Steps",ylab="Frequency")



meanstep.impute  <-mean(total.by.day.impute)  # note remore na.rm=TRUE 
medianstep.impute<-median(total.by.day.impute)# because we imputed NAs
pctdiffmean   <- abs(100*(meanstep-meanstep.impute)/mean(meanstep,meanstep.impute))
pctdiffmedian <- abs(100*(medianstep-medianstep.impute)/mean(medianstep,medianstep.impute))


library(xtable)
mtable<-data.frame(c("NAs removed","Imputed"),c(meanstep,meanstep.impute),c(medianstep,medianstep.impute))
names(mtable)<-c("Method","Mean","Median")
xt<-xtable(mtable)
print(xt, type="html")




# weekday/weekend part of analysis
# Assignment doesn't specify whether to use imputed or raw dataset
# I will choose imputed because I don't have to worry about NAs 
# in that case.
dataimpute$day   <- weekdays(dataimpute$time)
dataimpute$wkday <- "Weekday"
dataimpute[dataimpute$day=="Saturday"|dataimpute$day=="Sunday",]$wkday<-"Weekend"
dataimpute$wkday<-as.factor(dataimpute$wkday)
# I can't stand seeing the gaps in this plot due to 55 being next to 00
# so create a new interval variable which is number of minutes from
# the beginning of the day
dataimpute$Minterval <- as.numeric(dataimpute$min) + 60*as.numeric(dataimpute$hr)
mean.by.wkday<-aggregate(steps~Minterval+wkday,data=dataimpute,FUN=mean)
library(ggplot2)
p <- ggplot(mean.by.wkday, aes(Minterval,steps)) 
p + geom_line() +
        facet_grid(wkday ~. ) + 
        labs(title="Compared Average Steps by Interval\nFor the Weekdays and Weekend",
             x="Interval in Minutes from Midnight",
             y="Steps Averaged Over All Days")



library(knitr)

