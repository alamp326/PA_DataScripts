#Created by Aaron Lamplugh, PhD
#2-24-2023 11AM
#This script will run a comparative analysis of A&B channels from a folder of purple air files
#The Good_YesNo column is arbitrary and the metrics can be altered on Lines 100, 189, and 278
#PM2.5 disagreement is also arbitrary and currently set as percent difference >70% on lines 57, 144, and 234

#Import Data
#Select multiple Data files to load

library(stringr)
library(lubridate)

list = choose.files(default = "", caption = "Select files",
             multi = TRUE, filters = Filters,
             index = nrow(Filters))

MonitorChecks = data.frame(Monitor="",Slope=0,Y_Int=0,R2=0,Max_Value=0,Percent_Zero=0,PM2.5.Disagreement=0,Good_YesNo="")

dev.new()

#imports multiple files as data.frames
#names of dataframes are stored in namelist vector
for (i in 1:length(list)){

	folderloc = list[i]
	search1 = which(strsplit(list[i], "")[[1]] == "\\") 
	search2 = which(strsplit(list[i], "")[[1]] == ".")
	num1 = max(search1)+1
	num2 = min(search2)-1 
	vecname = substr(folderloc,num1,num2)
	vecname = gsub(" ", "_", vecname)

	df = read.csv(folderloc,header=TRUE,sep=",")
	assign(vecname,  df)
	
	if (i==1){
	namelist2 = vecname}
	else	{
	namelist2[i] = vecname
	}
}

#stores names of B channels and then removes them from all names list
bchannels = which(endsWith(namelist2,"_B"))
newnamelist = namelist2[-bchannels]

#goes through each dataframe and plots A vs B channels
for (i in 1:length(newnamelist)){

    currentvec = newnamelist[i]
    bchan = paste(currentvec,"B",sep="_")
      
    if (length(get(currentvec)$X0.3_um_count_a)>0 && length(get(bchan)$X0.3_um_count_b)>0){
      
      if (length(get(currentvec)$X0.3_um_count_a)-length(get(bchan)$X0.3_um_count_b)==0){
      
        PM2.5.disagreementRaw = which(abs(get(currentvec)$X0.3_um_count_a-get(bchan)$X0.3_um_count_b)/get(currentvec)$X0.3_um_count_a>0.7)
        PM2.5.disagreementpercent = length(PM2.5.disagreementRaw)/length(get(currentvec)$X0.3_um_count_a)

        Zeroes = which(get(currentvec)$X0.3_um_count_a==0)
        PercentZeroes = length(Zeroes)/length(get(currentvec)$X0.3_um_count_a)
        #TEMP.disagreementRaw = which(abs(get(currentvec)$Temperature_F-get(bchan)$Temperature_F)/get(currentvec)$Temperature_F>0.3)
        #TEMP.disagreementpercent = length(TEMP.disagreementRaw)/length(get(currentvec)$Temperature_F)
      
        #RH.disagreementRaw = which(abs(get(currentvec)$Humidity_.-get(bchan)$Humidity_.)/get(currentvec)$Humidity_.>0.3)
        #RH.disagreementpercent = length(RH.disagreementRaw)/length(get(currentvec)$Humidity_.)
        
        TempA = get(currentvec)$X0.3_um_count_a
        TempB = get(bchan)$X0.3_um_count_b
        
        if (length(PM2.5.disagreementRaw)>0){
        
          TempA = TempA[-PM2.5.disagreementRaw]
          TempB = TempB[-PM2.5.disagreementRaw]
        
        }
        
        MaxVal = max(TempA)
        
        if (length(TempA)>3 && length(TempB)>3){
	  		  
          dev.new(width=30,height=10,unit="in")
	  		  #par(mar=c(1,1,1,1),mfrow=c(1,3))
	  		  trend = lm(TempA ~ TempB)
	  		  trendsum = summary(trend)
	  		  r2 = trendsum$adj.r.squared
	  		  s = trendsum$coefficients[2]
	  		  y_int = trendsum$coefficients[1]
	  		  mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
	  		  mylabel2 = bquote(italic(Slope) == .(format(s, digits = 3)))

        } else {
          
          s=NaN
          r2=NaN
          y_int=NaN
          
        }
	  		  
  			if (PM2.5.disagreementpercent<0.3 && r2>0.6 && s>0.5 && s<1.5 && y_int>-50 && y_int<50){
			  
  			  monitorcheck="Yes"
			  
  			} else {
			  
  			  monitorcheck="No"
			  
  			}
			
	  		MonitorChecks[i,1:8] = c(currentvec,s,y_int,r2,MaxVal,PercentZeroes,PM2.5.disagreementpercent,monitorcheck)

	  		plot(TempB,TempA,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"PM2.5_Clean",sep=" "), log = "xy", ylim=c(0.01,10000),xlim=c(0.01,10000))
	  		abline(trend,untf = TRUE)
	  		#plot(get(bchan)$Temperature_F,get(currentvec)$Temperature_F,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"Temp",sep=" "), ylim=c(0,100),xlim=c(0,100))
	  		#plot(get(bchan)$PM2.5_ATM_ug.m3,get(currentvec)$PM2.5_ATM_ug.m3,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"RH",sep=" "), ylim=c(0,100),xlim=c(0,100))

      } else if(length(get(currentvec)$X0.3_um_count_a)-length(get(bchan)$X0.3_um_count_b)>0){
        
          lines2delete = length(get(currentvec)$X0.3_um_count_a)-length(get(bchan)$X0.3_um_count_b)
          timea = as.POSIXlt(get(currentvec)$date_time_utc,format="%Y-%m-%d %H:%M:%S",tz="GMT")
          timeb = as.POSIXlt(get(bchan)$date_time_utc,format="%Y-%m-%d %H:%M:%S",tz="GMT")
          tempdf = get(currentvec)
          
          for(j in 1:length(timea)){
          
           if(lines2delete>0 && j<length(timea)){  
            
            if(timea[j]>(timeb[j]+seconds(45)) || timea[j]<(timeb[j]-seconds(45))){
              
              tempdf=tempdf[-j,]
              lines2delete = (lines2delete-1)
              
            }
           } else if (lines2delete>0 && j==length(timea)){
             
             tempdf=tempdf[-j,]
             lines2delete = (lines2delete-1)
             
           }
          }
          
          assign(currentvec,tempdf)
          
          PM2.5.disagreementRaw = which(abs(get(currentvec)$X0.3_um_count_a-get(bchan)$X0.3_um_count_b)/get(currentvec)$X0.3_um_count_a>0.7)
          PM2.5.disagreementpercent = length(PM2.5.disagreementRaw)/length(get(currentvec)$X0.3_um_count_a)
          
          Zeroes = which(get(currentvec)$X0.3_um_count_a==0)
          PercentZeroes = length(Zeroes)/length(get(currentvec)$X0.3_um_count_a)
          
          #TEMP.disagreementRaw = which(abs(get(currentvec)$Temperature_F-get(bchan)$Temperature_F)/get(currentvec)$Temperature_F>0.3)
          #TEMP.disagreementpercent = length(TEMP.disagreementRaw)/length(get(currentvec)$Temperature_F)
          
          #RH.disagreementRaw = which(abs(get(currentvec)$Humidity_.-get(bchan)$Humidity_.)/get(currentvec)$Humidity_.>0.3)
          #RH.disagreementpercent = length(RH.disagreementRaw)/length(get(currentvec)$Humidity_.)
          
          TempA = get(currentvec)$X0.3_um_count_a
          TempB = get(bchan)$X0.3_um_count_b
          
          if (length(PM2.5.disagreementRaw)>0){
            
            TempA = TempA[-PM2.5.disagreementRaw]
            TempB = TempB[-PM2.5.disagreementRaw]
            
          }
          
          MaxVal = max(TempA)
          
          if (length(TempA)>3 && length(TempB)>3){
          
            dev.new(width=30,height=10,unit="in")
            #par(mar=c(1,1,1,1),mfrow=c(1,3))
            trend = lm(TempA ~ TempB)
            trendsum = summary(trend)
            r2 = trendsum$adj.r.squared
            s = trendsum$coefficients[2]
            y_int = trendsum$coefficients[1]
            mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
            mylabel2 = bquote(italic(Slope) == .(format(s, digits = 3)))
          
          } else {
        
            s=NaN
            r2=NaN
            y_int=NaN
        
          }            
            
            
          if (PM2.5.disagreementpercent<0.3 && r2>0.6 && s>0.5 && s<1.5 && y_int>-50 && y_int<50){
            
            monitorcheck="Yes"
            
          } else {
            
            monitorcheck="No"
            
          }
          
          MonitorChecks[i,1:8] = c(currentvec,s,y_int,r2,MaxVal,PercentZeroes,PM2.5.disagreementpercent,monitorcheck)
          
          plot(TempB,TempA,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"PM2.5_Clean",sep=" "), log = "xy", ylim=c(0.01,10000),xlim=c(0.01,10000))
          abline(trend,untf = TRUE)
          #plot(get(bchan)$Temperature_F,get(currentvec)$Temperature_F,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"Temp",sep=" "), ylim=c(0,100),xlim=c(0,100))
          #plot(get(bchan)$PM2.5_ATM_ug.m3,get(currentvec)$PM2.5_ATM_ug.m3,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"RH",sep=" "), ylim=c(0,100),xlim=c(0,100))
          
        
      } else if(length(get(currentvec)$X0.3_um_count_a)-length(get(bchan)$X0.3_um_count_b)<0){
        
        lines2delete = length(get(bchan)$X0.3_um_count_b)-length(get(currentvec)$X0.3_um_count_a)
        timea = as.POSIXlt(get(currentvec)$date_time_utc,format="%Y-%m-%d %H:%M:%S",tz="GMT")
        timeb = as.POSIXlt(get(bchan)$date_time_utc,format="%Y-%m-%d %H:%M:%S",tz="GMT")
        tempdf = get(bchan)
        
        for(j in 1:length(timeb)){
          
         if(lines2delete>0 && j<length(timeb)){  
          
          if(timeb[j]>(timea[j]+seconds(45)) || timeb[j]<(timea[j]-seconds(45)) ){
            
            tempdf=tempdf[-j,]
            lines2delete = (lines2delete-1)
            
          }
         } else if (lines2delete>0 && j==length(timeb)){
           
           tempdf=tempdf[-j,]
           lines2delete = (lines2delete-1)
           
         }  
        }
        
        assign(bchan,tempdf)
        
        PM2.5.disagreementRaw = which(abs(get(currentvec)$X0.3_um_count_a-get(bchan)$X0.3_um_count_b)/get(currentvec)$X0.3_um_count_a>0.7)
        PM2.5.disagreementpercent = length(PM2.5.disagreementRaw)/length(get(currentvec)$X0.3_um_count_a)
        
        Zeroes = which(get(currentvec)$X0.3_um_count_a==0)
        PercentZeroes = length(Zeroes)/length(get(currentvec)$X0.3_um_count_a)
        
        #TEMP.disagreementRaw = which(abs(get(currentvec)$Temperature_F-get(bchan)$Temperature_F)/get(currentvec)$Temperature_F>0.3)
        #TEMP.disagreementpercent = length(TEMP.disagreementRaw)/length(get(currentvec)$Temperature_F)
        
        #RH.disagreementRaw = which(abs(get(currentvec)$Humidity_.-get(bchan)$Humidity_.)/get(currentvec)$Humidity_.>0.3)
        #RH.disagreementpercent = length(RH.disagreementRaw)/length(get(currentvec)$Humidity_.)
        
        TempA = get(currentvec)$X0.3_um_count_a
        TempB = get(bchan)$X0.3_um_count_b
 
        if (length(PM2.5.disagreementRaw)>0){
          
          TempA = TempA[-PM2.5.disagreementRaw]
          TempB = TempB[-PM2.5.disagreementRaw]
          
        }
        
        MaxVal = max(TempA)
        
        if(length(TempA)>3 && length(TempB)>3){
        
          dev.new(width=30,height=10,unit="in")
          #par(mar=c(1,1,1,1),mfrow=c(1,3))
          trend = lm(TempA ~ TempB)
          trendsum = summary(trend)
          r2 = trendsum$adj.r.squared
          s = trendsum$coefficients[2]
          y_int = trendsum$coefficients[1]
          mylabel = bquote(italic(R)^2 == .(format(r2, digits = 3)))
          mylabel2 = bquote(italic(Slope) == .(format(s, digits = 3)))
        
        } else {
        
          s=NaN
          r2=NaN
          y_int=NaN
        
        }            
          
        if (PM2.5.disagreementpercent<0.3 && r2>0.6 && s>0.5 && s<1.5 && y_int>-50 && y_int<50){
          
          monitorcheck="Yes"
          
        } else {
          
          monitorcheck="No"
          
        }
        
        MonitorChecks[i,1:8] = c(currentvec,s,y_int,r2,MaxVal,PercentZeroes,PM2.5.disagreementpercent,monitorcheck)
        
        if (length(TempA)>3 && length(TempB)>3 && max(TempA)>0 && max(TempB)>0){
        
          plot(TempB,TempA,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"PM2.5",sep=" "), log = "xy", ylim=c(0.01,10000),xlim=c(0.01,10000))
          abline(trend,untf = TRUE)
          #plot(get(bchan)$Temperature_F,get(currentvec)$Temperature_F,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"Temp",sep=" "), ylim=c(0,100),xlim=c(0,100))
          #plot(get(bchan)$PM2.5_ATM_ug.m3,get(currentvec)$PM2.5_ATM_ug.m3,xlab="Ch B", ylab="Ch A", main=paste(currentvec,"RH",sep=" "), ylim=c(0,100),xlim=c(0,100))
        
        }
      }
    } else {
      
      MonitorChecks[i,1:8] = c(currentvec,0,0,0,0,0,0,"No")
      
    }  
}

View(MonitorChecks)
 
