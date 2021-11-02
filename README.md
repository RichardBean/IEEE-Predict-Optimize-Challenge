# ieee-predict-optimize
Code for IEEE-CIS Technical Challenge on Predict+Optimize for Renewable Energy Scheduling

Forecast
========

phase2-days.R is run with PHASE = 1 to check what the MASE is for phase 1. For the competition data, this was 0.5166. 
Then the exact same approach is used with PHASE = 2 for Phase 2 to avoid bugs. It takes about half an hour on my laptop.

Final MASE for my phase 1 submission (0.6320) and after tuning for Phase 1 (0.5166).

0.4301476 0.6115447 0.3309595 0.5636557 1.036976 0.767598 0.8478676 0.4618923 0.5250502 0.5910244 0.562383 0.8559337 -- PHASE1 .6320
0.3858967 0.425088  0.2913441 0.5636557 0.838308 0.733639 0.6558243 0.3618853 0.4139292 0.4989962 0.421899 0.609157  -- FINAL  .5166  

Ideas:
* based on GEFCOM 2014 and 2017, use quantile regression forests of Meinshausen, but actually use the "ranger" R package implementation as it's multithreaded. The median forecast with quantile 0.5 gets a significant lower MASE than the mean forecast.
* each building and solar instance has 4 random forests trained for each period -- as meteorological variables will be weighted differently depending on what part of the hour is being forecast; ECMWF data is provided hourly
* tune "mtry" based on MASE for phase 1 i.e. Oct 2020, and use "ntree" value 2000. I could have spent more time tuning "mtry" and perhaps increased "ntree", or used the "tuneRanger" package to try other parameters, but I don't think it would have made much difference and would have taken time away from the optimization task.
* Final choices: building 0/1/3/6 mtry = 43, building 1 mtry = 2, building 6 mtry = 19, solar mtry = 13
* Use BOM and ECMWF data together -- bos.csv file provided, has daily data from three solar sites in Melbourne. BOM solar data was complete for 2019-2020, although the other BOM variables had quite a few values missing. BOM also has paid data available for solar and other weather variables (hourly). 
* The BOM data had to be scraped from the BOM website with some difficulty which was very kludgy - this probably discouraged some competitiors. I only joined on 9 Sep after seeing ECMWF data had been added; I use ECMWF data in my solar, electricity and bike-sharing demand forecasting.
* Buildings 4 and 5 are just set to the median values of October 2020 of 1 and 19 as they appear have no connection to time or weather at all. Better than setting to the average values.
* Pick start dates for Buildings 0, 1, 3, 6 -- months 5, 1, 4, 0 i.e. June, February, May, January of 2020. These result in the lowest MASE in Phase 1. I tried exponential decay in the "ranger" training to weight the newest observations higher, but this made no difference whatever. So they are all weighted equally. There doesn't seem to be any point in training with the November 2020 data, unless it's like a jack-in-the-box and everything at Monash comes back to life in November which seemed unlikely.
* Holidays -- I wanted to weight Friday before Grand Final Day (23 Oct 2020) with a different weekend value - it seemed to affect some buildings but not others. So I left it out of the training data (ie weekend variable was set to NA). Melbourne Cup day (3 Nov 2020) was just modelled as a normal day as it didn't seem to have any effect in the previous years. Nothing special was done for other holidays of 2020 e.g. Easter - there didn't seem to be much difference.
* Train Building 0, 1, 3, 6 together, use a kitchen sink variables approach, all variables plus 3 hours leading and lagging (except MSLP 1 hour leading and lagging), plus temperatures 24, 48 and 72 hours ago (Clement and Li), plus Fourier value of hour / day of year, plus day of week variable for each of seven days, plus weekend variable, plus Mon/Fri var, plus Tue/Wed/Thu var
* However, this only predicts buildings 0 and 3 ultimately. The first period forecast for these buildings is taken from the last period of the training data, so we are sure to have that right. After that, the values are just repeated in blocks of four. However, the b0 and b3 forecasts are slightly different based on the phase 1 experience - b0 ultimately doesn't use the "period 1" forecast of each hour. b0, 1, 3, 6 are normalized and a variable is attached to the training data based on Smyl and Hua (2019)
* Next, b1 and b6 are forecast, without normalization. Building 1 has slightly fewer variables - there was some overfitting.
* Lastly, solar 0,1,2,3,4,5 are all forecast together. Using BOM data is critical here. Only a selection of relevant variables are used: BOM, temperature, SSRD, STRD, cloud cover (very useful for capturing shade), MSLP, Fourier values for hour and day. All variables +/- 3 hours except for MSLP which was +/- 1 hour.
* Cleaning: s0 and s5 have very problematic low values. Only "rows" (i.e. sets of four values) with a value over 0.05 kW were considered in training - i.e. filtered. This improved the MASE for Solar5 by about 0.2. Other solar traces have cumulative values in them for 2020 which would have been a disaster for training. Ultimately, s1, s2 and s3 were truncated at day 142 of 2020, while all of s4 was used, and all of s0 and s5 (with the filter applied). 
* Solar forecast was also normalized using the maximum observed values in the selected training data. Solar0 has a value of 52 kW in Oct 2020 which is higher than any previously observed value -- unsure whether to leave that in or not, but I assumed it was a genuine reading i.e. even in October, performance had somehow improved perhaps due to solar panel cleaning or shade being removed, or the angle changing. If I'd had more time I would have used the Weatherman approach to derive the angle and tilt of the panels and forecast directly. (Solcast estimates these values too).
* For a better forecast, we could have used a grid of ECMWF data, the GFS 3-hourly data, the JRA-55 data, MERRA-2 data, AEMO solar data in the vicinity, and PV-Output.org data. Using a grid of ECMWF data instead of the point provided would have allowed competitors to demonstrate other skill sets i.e. inverse distance weighting the output, different weighting depending on time of day, and different weighting depending on wind speed and cloud cover in surrounding grid points. In the solar model here wind speed was not used at all.
* The GFS, MERRA-2 and JRA-55 data are also free. This is the Solcast approach i.e. an ensemble of NWP forecasts, plus Himawari-8 satellite data to provide a real-time "nowcast". ECMWF data is only updated every 6 hours while the satellite data is updated several times an hour.
 
Optimization
============

Solving the model as a MIP is much easier than solving the MIQP. Almost all of the submitted solution depends on starting from the best MIP solution found (i.e. minimizing the recurring load or minimizing the recurring + once-off load). Then we just have to cross our fingers that our forecast is good enough so that the estimated cost is very close to the actual cost.

I based my initial approach on the 0-1 MIP explained by Taheri at https://youtu.be/uPi5DyPYYzg and https://youtu.be/0EUX3ua2liU ... sample code was provided on the Gurobi website for scheduling in Python (I fixed some bugs) and the video was excellent and focussed on practicalities i.e. things you wouldn't read in the Gurobi manual. 

The most important advice was: use Python in Gurobi, not R, C, C++, C# or another language. In particularly, Gurobi with R would have required a matrix based approach which would have been very slow and error-prone. Using Gurobi alone also saved me from having to implement in another modelling language i.e. AMPL or GAMS. Also, ANY "warm start" initial solution (as provided in the competition for the recurring activities) is better than none, while a good "warm start" is better than a bad "warm start".

Taheri suggested two approaches - one based on arrays and one based on 0-1 MIPs. I chose the 0-1 MIPs approach as there was sample code for pulling out the start hour of each activity straight away, and the arrays approach seemed to require choosing a somewhat arbitary slack variable.

I used Gurobi 9.1.2 on my laptop for Phase 1 and UQ HPC for Phase 2.

First, "phase2flat" minimizes the recurring load over 532 periods, with no batteries and no once-off activities.

Then, "phase2flat_oct24" minimizes the recurring and once-off load over 2880 periods, with no batteries; used to build up over the best "flat" solution found given an initial solution.

This produces a whole series of possible solutions (up to about 50 per case) which are passed as initial solutions to Gurobi, which fills out the battery schedule heuristically.

Ultimately, only Large 2 and Large 4 used recurring activities. I should have let the addition of once-off activities run a bit longer.

Quadratic programs are used in a series of paper by Ratnam et al on scheduling residential battery charging and discharging while avoiding backflow.

Then, "phase2update" adds the quadratic objective function and batteries, optimizing over 2880 periods; the only extra constraint is that battery charging cannot occur in "peak" which means weeks 1-4 i.e. 2-6, 9-13, 16-20, 23-27 November during 9am-5pm. Periods on 30 Nov and 1 Dec 9am-5pm (Mel time) are not considered "peak" for the recurring activities or battery charging, although once-off activities can be scheduled in these 10 hours and still get the "bonus".

Simultaneously, "flat_once_improve" starts with the recurring and once-off load, adds the quadratic objective function, and optimizes over 2880 periods. This is effectively just adding the battery in as no better solutions were found in the run time.

Eventually, only Large 2 and 4 had once-off activities added in the peak (putting them in the off-peak looked too costly for phase 2; although I did let the "onceIn" binary variable float freely i.e. the solver could choose if it wanted once-off activities in or out, so it wasn't all once-off activities either in or out). 

I considered that allowing the once-off activities to be in ANY of the 2880 periods instead of the 680 "weekday working" periods would have made the problem harder for Gurobi.

I considered five approaches for building the submitted solution: conservative, forced discharge, no forced discharge, liberal and very liberal. 

Conservative is just choosing the lowest recurring load and lowest recurring + once off load and evaluating cost using a naive or flat forecast. 

This was probably the winning approach for cost in Phase 1, as some competitiors had winning results with no forecast, or a poor forecast, but seemed pointless to me as the organizers said quality of forecast should contribute to results in phase 2.

Forced discharge forbids any charging in peak hours, and forces at least one of the two batteries to be discharging in every peak period. This was thought to avoid nasty surprises in the peak load as in phase 1 one of the actual observed values was 262 kW above my final forecast (i.e. forecast with 0.5166 MASE). However, although values drop randomly in and out of the building data, I hoped that there were no "outliers" in phase 2 as promised (although this "outlier" comment from the competition organizers probably referred to the 1744.1 kW in the Building 0 trace).

No forced discharge forbids any charging in peak hours, but the MIQP solver decides whether to discharge or do nothing in those hours.

Liberal allows charging in peak, but the maximum of recurring + once off + charge effect for each period is limited to the maximum of recurring + once off load over all periods. This is to avoid nasty surprises when the solver thinks that a period has low underlying load and schedules a charge (due to a low price in that period) but then accidentally increases the maximum load over all periods, which can be very costly.

Very liberal allows charging over peak and does not attempt to control the maximum of recurring + once off + charge effect. This would be the best approach if the forecast was perfect.

Other approaches could be weighting building at 60% quantile, and solar at 40% quantile as in Bean and Khan.

There is not really any way to know how "good" my phase 2 forecast was; so I just tested the last four approaches here with my final phase 1 data. Although the objective function values for "liberal" and "very liberal" were lowest, over all the 10 problems the "no forced discharge" approach had a slightly lower cost. Of course, the pool prices for Nov 2020 were quite different from the prices for Oct 2020, but I thought this "ad hoc" or "heuristic" approach was probably the best idea. 

The other idea was to add a constraint stating that any relaxation (i.e. increase) in the maximum observed load over the month had to be at least counterbalanced by a decrease in the cost of electricity. But this seemed unnecessarily constraining. I decided to trust the forecast, which may be a risky approach, but also had the best shot at developing the best schedule.

Errors
======

Time zone problems were a big problem in phase 1. The writers/organizers did not seem to realize that their scheduling problem was in Melbourne time (UTC+10 or UTC+11), the AEMO prices were in NEM time (UTC+10) while the ECMWF data was in UTC. The result was that the scheduling was actually taking place in the middle of the night in Melbourne (8pm-4am typically in Oct 2020). This made no sense to me. I was trying different things to improve the cost and nothing was working. The highest load was in the very first period (8pm) but all sorts of approaches weighting for this was not bringing the cost down at all.

It was only on 1 Oct that I learned that the "Optim_eval" output was supposed to correspond exactly with the leaderboard result.  Prior to this I thought this software was only a guide for competitors to evaluate their results and test validity.
After that I started messaging the organizers about time zone problems and the missing value problems. Also there were spammers and the leaderboard crashed regularly, which was quite frustrating for me. 
There were also bugs in the leaderboard evaluation causing some submissions to be evaluated as "worse" which was very discouraging and wasted a lot of my time.
Several bugs were corrected on Oct 25, a week before submissions closed.
I only realized at the last moment that the recurring load did NOT cover Nov 30 or Dec 1 (Melbourne time) and the once-off load DID count Nov 30 and Dec 1 (Melbourne time, 9am-5pm) as peak periods, after inserting lots of System.out.println statements in the provided Java code.
So even though this kind of solar and building challenge is very much my daily work, what seemed absolutely obvious and clear to the organizers was absolutely not obvious or clear to at least some of the competitors.
The competitors found critical bugs (e.g. time zone problems, solar traces being added to buildings in phase 1 instead of subtracted, etc).
I think I had some luck in joining at the correct time i.e. around 9 Sep when ECMWF data was added.

If I had to do it again, I'd let the "phase2flat_oct24" optimization run for much longer. 

I killed each Gurobi job as soon as it found an actual solution putting all the once-off activities in the peak, and then "unfixed" the recurring hour start variables, whereas this was a big mistake as Gurobi had spent a long time building a search tree and the best MIP solutions are found by branch-and-bound ("H" values in the log). Gurobi jobs cannot be stopped and restarted, although as mentioned starting from a good "warm start" is better than starting from a bad "warm start".

The best solution for recurring plus once-off would probably have been found if I'd just let the optimization continue, and I may have been able to add more once-off activities. However, time was limited and after the last bug was fixed (25 Oct) there was only about a week left.