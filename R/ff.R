## Fama French size and bm factor return

require(dplyr)
require(reshape2)
require(ggplot2)

setwd("/Users/wang/Documents/Undergraduate/ps1")

## import dataset 
# monthly stock trading file
msf1 <- data.table::fread("TRD_Mnth1.csv")    
msf2 <- data.table::fread("TRD_Mnth2.csv") 
# banlance sheet 
bs <- data.table::fread("FS_Combas.csv")
msf<-rbind(msf1, msf2) 
str(msf)

## alphanumeric transfomation
mon_encode <- data.frame(mon_name=month.abb, 
                         mon=1:12,
                         stringsAsFactors = F)

msf <- msf %>% 
    filter(Markettype %in% c(1L,4L,16L)) %>%
    mutate(yr = as.integer(substr(Trdmnt, 5,6)),  # year var
           mon_name = substr(Trdmnt, 1,3), # month var
           mcap = Msmvttl*1000   # market cap
           ) %>%
    select(Stkcd, yr, mon_name, ret=Mretwd, mcap)

msf <- msf[complete.cases(msf),] %>%  # delete missing values
    left_join(mon_encode) %>%
    mutate(yr=yr+1900L*(yr>=90)+2000L*(yr<90)) %>%
    select(Stkcd, yr, mon, ret, mcap)

## check if key var is unique
if(nrow(msf)-nrow(distinct(msf, Stkcd, yr, mon))==0)
message('No dupkey')

## merge b/s with mkt cap in DEC
bs <- bs %>% 
    mutate(Accper = as.Date(Accper), 
           yr = as.integer(substr(Accper,1,4)),
           mon = as.integer(substr(Accper,6,7))) %>%
    # only select yearly consolidated statement
    filter(Typrep == 'A', months(Accper, abbreviate=T) == '12') %>% 
    select(Stkcd, yr, mon, Accper, be = A003000000)
    
bs <- bs[complete.cases(bs),]
if(nrow(bs)-nrow(distinct(bs, Stkcd, yr, mon))==0)
    message('No dupkey')

# book/market ratio
bm <- msf %>% 
    inner_join(bs, by = c("Stkcd", "yr", "mon")) %>%
    mutate(bm = be/mcap) %>%
    select(Stkcd, yr, bm)

## merge size and BM factor with msf(monthly stock trading file)
size <- msf %>% filter(mon == 4L) %>%
    select(Stkcd, yr, size = mcap) # use mcap at Apr. 30

ff <- msf %>% mutate(yr4bm = yr-1,
                      yr4size = ifelse(mon<=4, yr-1, yr)) %>%
    inner_join(bm, by=c("Stkcd"="Stkcd", "yr4bm"="yr")) %>% 
    inner_join(size, by=c("Stkcd"="Stkcd", "yr4size"="yr")) %>%
    select(Stkcd, yr, mon, ret, bm, size)
    
## each month, construct 2*3 ports based on size/bm
ff <- ff %>%
    group_by(yr, mon) %>% 
    mutate(size_rank = ntile(size, 2)) %>%
    group_by(size_rank, add = T) %>%
    mutate(
        bm_rank = ifelse(
            percent_rank(bm) < 0.3, 1,
                  ifelse(percent_rank(bm) <0.7, 2, 3)
                   )
        )

## calculate equal weighted port ret 
port_ret <- ff %>% 
    group_by(yr, mon, size_rank, bm_rank) %>%
    summarise(ret = mean(ret),
              obs = n())
# convert from long to wide to calculate ff factor
port_ret_l <- melt(port_ret, 
                 id.vars = c("yr", "mon", "size_rank", "bm_rank"),
                 measure.vars = "ret") 
port_ret_w <- dcast(port_ret_l, yr+mon ~ size_rank + bm_rank)
names(port_ret_w)[3:8] <- paste0("p", names(port_ret_w)[3:8])

ff <- port_ret_w %>%
    mutate(smb=(p1_1+p1_2+p1_3-p2_1-p2_2-p2_3)/3,
           hml=(p1_3+p2_3-p1_1-p2_1)/2) %>%
    select(yr, mon, smb, hml) %>%
    arrange(yr, mon)

## plot size and bm premium
ff <- ff %>% 
    mutate(date = as.Date(paste(yr, mon, '01', sep='-'))) %>%
    filter(date>=as.Date("2000-01-01")) %>%
    select(date, smb, hml)

ff <- melt(ff, id.vars = 'date', 
           variable.name = 'ff.factor',
           value.name = 'ff.premium')

ggplot(data=ff, aes(x=date, y=ff.premium, colour=ff.factor)) + geom_line()  
ggsave("ffpremium.pdf")

## house cleaning
rm(list=ls())
