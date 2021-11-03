# IEEE-CIS Technical Challenge on Predict+Optimize for Renewable Energy Scheduling
This is my code, data and approach for the <a href="https://ieee-dataport.org/competitions/ieee-cis-technical-challenge-predictoptimize-renewable-energy-scheduling">IEEE-CIS Technical Challenge on Predict+Optimize for Renewable Energy Scheduling.</a> The competition ran from 1 July to 3 November 2021, although I only became involved on 10 September.

Forecast
========

phase2-days.R is run with PHASE = 1 to check what the MASE is for phase 1. For the competition data, this was 0.5166. 
Then the exact same approach is used with PHASE = 2 for Phase 2 to avoid bugs. Each phase takes about half an hour on my laptop.

The final MASE for my phase 1 submission was 0.6320 and after getting access to the individual time series - 0.5166.

|	Case      | MASE Phase 1   | MASE after tuning
|:---------:|:--------------:|:---------------:|
|	Building0	| 0.4301         |  0.3859         |
|	Building1	| 0.6115         |  0.4251         |
|	Building3	| 0.3310         |  0.2913         |
|	Building4	| 0.5637         |  0.5637         |
|	Building5	| 1.0370         |  0.8383         | 
|	Building6	| 0.7676         |  0.7336         |
|	Solar0	   | 0.8479         |  0.6558         |
|	Solar1	   | 0.4619         |  0.3619         | 
|	Solar2	   | 0.5251         |  0.4139         |
|	Solar3	   | 0.5910         |  0.4990         |
|	Solar4	   | 0.5624         |  0.4219         |
|	Solar5	   | 0.8559         |  0.6092         |
|	**Mean**  | **0.6320**     |  **0.5166**     |

Ideas:
* Initially I used GAMs (generalized additive models) of <a href="https://www.jstor.org/stable/24771867">Wood, Goude and Shaw</a> which is great for visualizations and explainability, especially for bike-sharing demand forecasting (see <a href="https://doi.org/10.1016/j.jtrangeo.2021.103155">Bean, Pojani and Corcoran 2021</a>) but switched to random forests as the competition was only about performance. This is NOT the <a href="https://ieee-dataport.org/competitions/fuzz-ieee-competition-explainable-energy-prediction">Explainable Energy Competition.</a>
* I also tried the <a href="https://cran.r-project.org/web/packages/EZtune/index.html">R "eztune" package</a> to look at adaboost, support vector machines, gradient boosting machines, and elastic net. None performed as well as random forests. I considered using an ensemble of random forests and something else but didn't have time. I also tried to look at lightGBM but the R package was broken.
* So, based on <a href="http://dx.doi.org/10.1016/j.ijforecast.2015.11.013">GEFCOM 2014</a> and <a href="http://dx.doi.org/10.1016/j.ijforecast.2019.02.006">2017</a> winning entries, I used <a href="https://www.jmlr.org/papers/v7/meinshausen06a.html">quantile regression forests of Meinshausen (2006).</a> I used the <a href="https://cran.r-project.org/web/packages/ranger/index.html">"ranger" R package</a> implementation as it's multithreaded. The median forecast with quantile 0.5 gets a significantly lower MASE than the mean forecast.
* Each building and solar instance has 4 random forests trained for each period -- as meteorological variables will be weighted differently depending on what part of the hour is being forecast; ECMWF data is provided hourly
* I tuned "mtry" based on MASE for phase 1 i.e. Oct 2020, and use "ntree" value 2000. I could have spent more time tuning "mtry" and perhaps increased "ntree", or used the "tuneRanger" package to try other parameters, but I don't think it would have made much difference and would have taken time away from the optimization task.
* The final choices were: building 0/1/3/6 mtry = 43, building 1 mtry = 2, building 6 mtry = 19, solar mtry = 13
* I used BOM and ECMWF data together: see the bos.csv file provided, which has daily data from three solar sites in Melbourne. 
* BOM solar data was complete for 2019-2020, although the other BOM variables had quite a few values missing. 
* BOM also has paid data available for solar and other weather variables (hourly). Of course we were not allowed to use this in the competition.
* The BOM data had to be scraped from the BOM website with some difficulty which was very kludgy - this probably discouraged some competitiors. I only joined after seeing ECMWF data had been added; I use ECMWF data in my solar, electricity and bike-sharing demand forecasting.

### Summary of phase 1 forecasting MASE with leaderboard
* <a href="https://cran.r-project.org/web/packages/mgcv/index.html">GAM</a> - MASE 0.8752 then with <a href="https://cran.r-project.org/web/packages/randomForest/index.html">R randomForest package</a> 0.8165 (10 September) - variables: some leading and lagging solar, 24/48/72 hr lagging temperature, hour, weekend, day of year, "lockdown" percentage estimate included but not used. Building 0 and 3 high and low data thresholded (b0: omit > 606.5 kW, b3 omit < 193 kW and > 2264 kW)
* random forests with feature selection, top of the leaderboard going past Chun Fu presumably using lightGBM at 0.7205 (MASE 0.6881, 17 September); added Fourier values of hour of day / day of year, more leading and lagging solar, Mon/Fri, Tue/Wed/Thu variable; all solar values < 0.05 kW set to 0; examined variable importance in output 
* tried out <a href="https://www.analyticsvidhya.com/blog/2016/01/xgboost-algorithm-easy-steps/">XGBoost</a> - very slow, poor performance, and lots of hyperparameter tuning needed; automated approach also didn't work well (17 September); also experimented with <a href="https://cran.r-project.org/web/packages/caret/vignettes/caret.html">R "caret" package</a> very briefly but was fairly committed to random forest approach by then
* performed more feature selection and set Building 4 equal to 1 kW (MASE 0.6625, 17 September)
* tuned the start months in 2020 for all the buildings (MASE 0.6528, 20 September). This remained better than any other forecast on the leaderboard for Phase 1. The closest forecasts were Nils Einecke (and Steffen Limmer) "Nasty II" 0.6589 on 30 September and Dong Minhui "Sub16" 0.6580 on 13 October.
* Used median forecasting with <a href="https://cran.r-project.org/web/packages/quantregForest/index.html">quantregForest</a> (MASE 0.6474, 27 September)
* A lot of playing with various quantiles which was completely invalid but fun, while learning how to use Gurobi (MASE 0.6404, 27 September) - everything set at a quantile of 0.37 to try to experiment with improving the optimization result
* Building 0 set at 0.37, everything else set at 0.50 (MASE 0.6396, 9 October) - obviously that approach would not generalize to Phase 2!
* Added in BOM solar data, no cheating with quantiles (MASE 0.6320, 10 October) - so that was down from 0.6474 

### Summary of phase 1 forecasting MASE tuning against individual time series
* 13 October - phase 1 (October 2020) individual time series became available
* The "mase_calculator.R" provided uses the MASE function from the <a href="https://cran.r-project.org/web/packages/greybox/index.html">greybox R package.</a> It's equivalent to MAE divided by a scaling factor, so I calculated the scaling factors for each of the 12 time series.
* added cloud cover +/- 3 hours (MASE 0.6243, 16 October)
* solar data from beginning of 2020 instead of from day 142 (MASE 0.6063, 17 October)
* selected start month (0-8) for each of 4 building series (from 2020), added all possible weather variables, set Building 5 equal to 19 kW (MASE 0.5685, 18 October)
* fixed up Solar5 data by filtering (MASE 0.5387, 24 October)
* noticed that forecasting Solar0 and Solar5 as linear combinations of the other Solar variables was working better than my actual Solar0/5 prediction
* noticed that some pairs of solar series were much more highly correlated than other pairs, and buildings 3/6 were also highly correlated
* 27 October - was reminded about possibly using <a href="https://stats.stackexchange.com/questions/196653/assigning-more-weight-to-more-recent-observations-in-regression">exponential decay</a> from <a href="https://cbergmeir.com/talks/acml-tutorial/">Bergmeir's notes</a> - seemed that it would be quite useful for the buildings for 2020, or for solar panels degrading over time. In the process learned about the <a href="https://cran.r-project.org/web/packages/ranger/index.html">R "ranger" package</a> which allowed <a href="https://stats.stackexchange.com/questions/83104/weighting-more-recent-data-in-random-forest-model">weighted observations,</a> but more importantly multi-threaded quantile regression forest works in Windows, unlike with "quantregForest"
* trained all solar and building data together after seeing the <a href="https://doi.org/10.1016/j.ijforecast.2019.02.002">Smyl and Hua paper</a> and competition text about training series together (MASE 0.5220, 30 October)
* fixed up Solar0 data by same filtering as for Solar5 (MASE 0.5207, 31 October)
* added in separate weekday variables (MASE 0.5166, 2 November)
* for reference: ranger with mean rather median forecast: MASE 0.5387 (3 November)
* for reference: with Building0 outliers fixed (i.e. four 1744.1 kW building 0 values replaced by 100 kW) MASE 0.5121 (3 November) -- hopeful of similar result on phase 2
* for reference: with Building 0 outliers of training 2020 NOT fixed in training - MASE for Phase TWO = X.XXXX compared to 0.6460 with outliers fixed in training (is this why people's forecasts went so wrong?)

### Building Forecast

* Buildings 4 and 5 are just set to the median values of October 2020 of 1 and 19 as they appear have no connection to time or weather at all. This is better in MASE terms than setting them to the average values.
* I picked start dates for Buildings 0, 1, 3, 6 -- months 5, 1, 4, 0 i.e. June, February, May, January of 2020. These result in the lowest MASE in Phase 1. I tried <a href="https://cbergmeir.com/talks/acml-tutorial/">exponential decay</a> in the "ranger" training to weight the newest observations higher, but any improvement was tiny. So all observations are all weighted equally. There doesn't seem to be any point in training with the November 2020 data, unless it's like a jack-in-the-box and everything at Monash comes back to life in November which seemed unlikely. The Monash Occupancy percentages in the <a href="https://ieee-dataport.s3.amazonaws.com/docs/65076/Data_Description_v1.pdf?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAJOHYI4KJCE6Q7MIQ%2F20211103%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20211103T032552Z&X-Amz-SignedHeaders=Host&X-Amz-Expires=86400&X-Amz-Signature=5ad22eb1e61bcf33df3b57038706a2924861dc6033c68eef090c09726808ef4a">data description</a> were not useful.
* Holidays -- I wanted to weight Friday before Grand Final Day (23 Oct 2020) with a different weekend value - it seemed to affect some buildings but not others. So I left it out of the training data (ie weekend variable was set to NA). Melbourne Cup day (3 Nov 2020) was just modelled as a normal day as it didn't seem to have any effect in the previous years. Nothing special was done for other holidays of 2020 e.g. Easter - there didn't seem to be much difference.
* I trained Buildings 0, 1, 3, and 6 together, used a kitchen sink variables approach, all variables plus 3 hours leading and lagging (except MSLP 1 hour leading and lagging), plus temperatures 24, 48 and 72 hours ago (<a href="https://eprints.qut.edu.au/95170/">Clements and Li 2016</a>), plus Fourier value of hour / day of year, plus day of week variable for each of seven days, plus weekend variable, plus Mon/Fri var, plus Tue/Wed/Thu var
* However, this only predicts buildings 0 and 3 ultimately. The first period forecast for these buildings is taken from the last period of the training data, so we are sure to have that right. After that, the values are just repeated in blocks of four. 
* The b0 and b3 forecasts are slightly different based on the phase 1 experience - b0 ultimately doesn't use the "period 1" forecast of each hour. 
* b0, 1, 3, 6 are normalized and a variable is attached to the training data based on <a href="doi.org/10.1016/j.ijforecast.2019.02.002">Smyl and Hua (2019).</a>
* Next, b1 and b6 are forecast, without normalization. Building 1 has slightly fewer variables - there was some overfitting.

### Solar Forecast 

* Lastly, solar 0,1,2,3,4,5 are all forecast together. Using BOM data is critical here. Only a selection of relevant variables are used: BOM, temperature, SSRD, STRD, cloud cover (very useful for capturing shade), MSLP, Fourier values for hour and day. All variables +/- 3 hours except for MSLP which was +/- 1 hour.
* Cleaning: s0 and s5 have very problematic low values. Only "rows" (i.e. sets of four values) with a value over 0.05 kW were considered in training - i.e. filtered. 
* This improved the MASE for Solar5 by about 0.2.
* Other solar traces have cumulative values in them for 2019 which would have been a disaster for training. Ultimately, s1, s2 and s3 were truncated at day 142 of 2020, while all of s4 was used, and all of s0 and s5 (with the filter applied). 
* Solar forecast was also normalized using the maximum observed values in the selected training data. 
* Solar0 has a value of 52 kW in Oct 2020 which is higher than any previously observed value. 
* I was unsure whether to leave that in or not, but I assumed it was a genuine reading i.e. even in October, performance had somehow improved perhaps due to solar panel cleaning or shade being removed, or the angle changing. 
* If I'd had more time I would have used the <a href="https://ieeexplore.ieee.org/document/8258032">Weatherman approach</a> to derive the angle and tilt of the panels and forecast directly with the R <a href="https://cran.r-project.org/web/packages/solaR/index.html">solaR package</a>. (<a href="https://solcast.com/">Solcast</a> estimates these values too).
* For a better forecast, we could have used a grid of ECMWF data, the <a href="https://rda.ucar.edu/datasets/ds084.1/">Global Forecasting System (GFS) 3-hourly data</a>, the Japanese Re-Analysis <a href="https://rda.ucar.edu/datasets/ds628.0/">JRA-55</a> data, NASA <a href="https://gmao.gsfc.nasa.gov/reanalysis/MERRA-2/">MERRA-2 data</a>, AEMO ASEFS solar data in the vicinity, and <a href="https://pvoutput.org/">PV-Output.org</a> data. 
* Using a grid of ECMWF data instead of the point provided would have allowed competitors to demonstrate other skill sets i.e. inverse distance weighting the output, different weighting depending on time of day, and different weighting depending on wind speed and cloud cover in surrounding grid points. In the solar model here wind speed was not used at all.
* The GFS, MERRA-2 and JRA-55 data are also free. This is the <a href="https://solcast.com/solar-irradiance-forecasting-weather-models/">Solcast approach</a> i.e. an ensemble of NWP forecasts, plus Himawari-8 satellite data to provide a real-time "nowcast". ECMWF data is only updated every 6 hours while the satellite data is updated several times an hour. <a href="https://openclimatefix.org/">Open Climate Fix</a> uses similar input data.
 
### Post-mortem perfectionism
* Every series with a MASE above 0.5 (Phase 1) makes me uncomfortable. However, I couldn't find any relationship between Building4/5 and time/day/weather
* I also couldn't see a good way to improve Solar 0/5 yet. I wonder why the MASE is so high for those.
 
Optimization
============

Solving the model as a MIP is much easier than solving the MIQP. Almost all of the submitted solution depends on starting from the best MIP solution found (i.e. minimizing the recurring load or minimizing the recurring + once-off load). Then we just have to cross our fingers that our forecast is good enough so that the estimated cost is very close to the actual cost.

### Choosing Gurobi

I based my initial approach on the 0-1 MIP explained by Taheri at <a href="https://youtu.be/uPi5DyPYYzg">Advanced Methods for Scheduling using Gurobi</a> and <a href="https://youtu.be/0EUX3ua2liU">Tips and Tricks for Optimal Scheduling with End-to-End Analytics and Gurobi</a> 

<a href="https://www.gurobi.com/resource/job-scheduling-tips-and-tricks/">Sample code</a> was provided on the Gurobi website for scheduling in Python (I fixed some bugs) and the video was excellent and focussed on practicalities i.e. things you wouldn't read in the Gurobi manual. 

The most important advice was: use Python in Gurobi, not R, C, C++, C# or another language.

In particular, Gurobi with R would have required a matrix based approach which would have been very slow and error-prone. 

Using Gurobi alone also saved me from having to implement in another modelling language i.e. AMPL or GAMS. 

Also, ANY "warm start" initial solution (as provided in the competition for the recurring activities) is better than none, while a good "warm start" is better than a bad "warm start".

Taheri suggested two approaches - one based on arrays and one based on 0-1 MIPs. I chose the 0-1 MIPs approach as there was sample code for pulling out the start hour of each activity straight away, and the arrays approach seemed to require choosing a somewhat arbitary slack variable.

I used Gurobi 9.1.2 on my laptop for Phase 1 and UQ HPC for Phase 2.

### First solve as a MIP to flatten recurring and once-off load

First, "phase2flat" minimizes the recurring load over 532 periods, with no batteries and no once-off activities.

Then, "phase2flat_oct24" minimizes the recurring and once-off load over 2880 periods, with no batteries; used to build up over the best "flat" solution found given an initial solution.

This produces a whole series of possible solutions (up to about 50 per case) which are passed as initial solutions to Gurobi, which fills out the battery schedule heuristically.

Ultimately, only Large 2 and Large 4 used recurring activities. I should have let the addition of once-off activities run a bit longer.

I looked for ways to speed up the MIP solving to approximate a better solution in the complete MIQP. In Phase 1, I tried to bias the recurring activities away from Wednesday as the average pool price on that day was around $90 compared to around $44 for all days.

This slowed down the solution process quite a bit; choosing to bias the activities so that the average load of the five days of the week occurred in descending order slowed it down too much. In Phase 2 the pool prices over the weekdays were similar so I didn't implement this idea.

Quadratic programs are used in a series of papers by <a href="https://ieeexplore.ieee.org/document/6629420">Ratnam et al</a> on scheduling residential battery charging and discharging while avoiding backflow.

### Solve as a MIQP to add batteries and tune

Then, "phase2update" adds the quadratic objective function and batteries, optimizing over 2880 periods; the only extra constraint is that battery charging cannot occur in "peak" which means weeks 1-4 i.e. 2-6, 9-13, 16-20, 23-27 November during 9am-5pm. Periods on 30 Nov and 1 Dec 9am-5pm (Mel time) are not considered "peak" for the recurring activities or battery charging, although once-off activities can be scheduled in these 10 hours and still get the "bonus".

Simultaneously, "flat_once_improve" starts with the recurring and once-off load, adds the quadratic objective function, and optimizes over 2880 periods. This is effectively just adding the battery in as no better solutions were found in the run time.

Eventually, only Large 2 and 4 had once-off activities added in the peak (putting them in the off-peak looked too costly for phase 2; although I did let the "onceIn" binary variable float freely i.e. the solver could choose if it wanted once-off activities in or out, so it wasn't all once-off activities either in or out). 

I considered that allowing the once-off activities to be in ANY of the 2880 periods instead of the 680 "weekday working" periods would have made the problem harder for Gurobi.

### Possible approaches

I considered five approaches for building the submitted solution: conservative, forced discharge, no forced discharge, liberal and very liberal. 

1. **Conservative** is just choosing the lowest recurring load and lowest recurring + once off load and evaluating cost using a naive or flat forecast. 
This was probably the winning approach for cost in Phase 1, as some competitiors had winning results with no forecast, or a poor forecast, but seemed pointless to me as the organizers said quality of forecast should contribute to results in phase 2.

2. **Forced discharge** forbids any charging in peak hours, and forces at least one of the two batteries to be discharging in every peak period. This was thought to avoid nasty surprises in the peak load as in phase 1 one of the actual observed values (period 2702 of 2976) was ~260 kW above my final forecast (i.e. forecast with 0.5166 MASE). However, although values drop randomly in and out of the building data, I hoped that there were no "outliers" in phase 2 as promised (although this "outlier" comment from the competition organizers probably referred to the repeated 1744.1 kW values in the Building 0 trace - periods 1710 to 1713 of 2976).

3. **No forced discharge** forbids any charging in peak hours, but the MIQP solver decides whether to discharge or do nothing in those hours.

4. **Liberal** allows charging in peak, but the maximum of recurring + once off + charge effect for each period is limited to the maximum of recurring + once off load over all periods. This is to avoid nasty surprises when the solver thinks that a period has low underlying load and schedules a charge (due to a low price in that period) but then accidentally increases the maximum load over all periods, which can be very costly.

5. **Very liberal** allows charging over peak and does not attempt to control the maximum of recurring + once off + charge effect. This would be the best approach if the forecast was perfect.

Other approaches could be weighting buildings at 60% quantile, and solar at 40% quantile as in <a href="https://arxiv.org/abs/1810.11178">Bean and Khan (2018).</a> Bean and Khan also avoided any charging in peak, and operated off a net load forecast as in this challenge. I felt these values could be rather arbitrary. Bean and Khan also includes the possibility of changing the charge/discharge rate (compared to this competition).

There is not really any way to know how "good" my phase 2 forecast was; so I just tested the last four approaches here with my final phase 1 data. 

The objective function values for "liberal" and "very liberal" were lowest of the approaches. But over all the 10 problems, the "no forced discharge" approach had a slightly lower cost as evaluated against the actual net load. Of course, the pool prices for Nov 2020 were quite different from the prices for Oct 2020, but I thought this "ad hoc" or "heuristic" approach was probably the best idea. 

The other idea was to add a constraint stating that any relaxation (i.e. increase) in the maximum observed load over the month had to be at least counterbalanced by a decrease in the cost of electricity. But this seemed unnecessarily constraining. I decided to trust the forecast, which may be a risky approach, but also had the best shot at developing the best schedule.

Estimated total cost (3 November) -- $261,906

|	Case      | Estimated Cost | Actual Cost     |
|:---------:|:--------------:|:---------------:|
|	small0   	|  26681         |                 |
|	small1   	|  26233         |                 |
|	small2   	|  26251         |                 |
|	small3   	|  26452         |                 |
|	small4   	|  26107         |                 | 
|	large0   	|  26265         |                 |
|	large1    |  26666         |                 |
|	large2 	  |  25389         |                 | 
|	large3    |  26010         |                 |
|	large4	   |  25849         |                 |
|	**Total** | **261906**     |                 |

Errors
======

Phase 1 of the competition had serious time zone issues.

The writers/organizers did not seem to realize that their scheduling problem was in Melbourne time (UTC+10 or UTC+11) and the AEMO prices were in NEM time (UTC+10), while the ECMWF data was in UTC. 

The result was that the activity scheduling was taking place in the middle of the night in Melbourne instead of 9am-5pm Melbourne time, typically 8pm-4am in Oct 2020 (UTC+11).

This made no sense to me. I was trying different things to improve the cost and nothing was working. The highest load was in the very first period (8pm) but all sorts of approaches weighting for this were not bringing the leaderboard cost down at all.

It was only on 1 Oct that I learned that the "Optim_eval" output was supposed to correspond exactly with the leaderboard result.  Prior to this I thought this software was only a guide for competitors to evaluate their results and test validity.

After that I started messaging the organizers about time zone problems and the missing value problems. Also there were spammers and the leaderboard crashed regularly, which was quite frustrating for me. 

There were also bugs in the leaderboard evaluation causing some submissions to be evaluated as "worse" which was very discouraging and wasted a lot of my time.
Several bugs were corrected on Oct 25, a week before submissions closed.

I only realized on 2 November that the recurring load did NOT cover Nov 30 or Dec 1 (Melbourne time) and the once-off load DID count Nov 30 and Dec 1 (Melbourne time, 9am-5pm) as peak periods, after inserting lots of System.out.println statements in the provided Java code. The Java code had changed at some point completely (ChronicsHandler.java and ChronicsScheduleChecker.java) to explicitly start on the first Monday and run for four complete weeks only, while many months such as Dec 2020 would have only three weeks complete.

So even though this kind of solar and building challenge is very much my daily work, what seemed absolutely obvious and clear to the organizers was not obvious or clear to me. In Phase 1, there were many entries clustered in the $480,000 range and I wondered if they had just misunderstood the time zones.

The competitors found critical bugs (e.g. time zone problems, solar traces being added to buildings in phase 1 instead of subtracted, etc).

I think I had some luck in joining at the correct time around 10 Sep after the ECMWF data was added. I had downloaded the files, ECMWF/ERA5 and BOM data on 10 August, and then did nothing more until 10 Sep. I may not have bothered entering without the ECMWF data.

If I had to do it again, I'd let the "phase2flat_oct24" optimization run for much longer. 

I killed each Gurobi job as soon as it found an actual solution putting all the once-off activities in the peak, and then "unfixed" the recurring hour start variables, whereas this was a big mistake as Gurobi had spent a long time building a search tree and the best MIP solutions are found by branch-and-bound ("H" values in the log). Gurobi jobs cannot be stopped and restarted, although as mentioned starting from a good "warm start" is better than starting from a bad "warm start".

The best solution for recurring plus once-off would probably have been found if I'd just let the optimization continue, and I may have been able to add more once-off activities. However, time was limited and after the last bug was fixed (25 Oct) there was only about a week left.

Thanks
======

Thanks to the competition organizers, to Archie Chapman for mentioning the competition on our work Slack channel and David Green of UQ HPC for updated Gurobi to 9.1.2 and spending hours helping me experiment and tinker to see how Gurobi operated in multi-threaded mode.
