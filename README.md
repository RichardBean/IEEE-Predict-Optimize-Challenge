# ieee-predict-optimize
Code for IEEE-CIS Technical Challenge on Predict+Optimize for Renewable Energy Scheduling

First, "phase2flat" minimizes the recurring load over 532 periods, with no batteries and no once-off activities

Then, "phase2flat_oct24" minimizes the recurring and once-off load over 2880 periods, with no batteries; used to build up over the best "flat" solution found given an initial solution

Then, "phase2update" adds the quadratic objective function and batteries, optimizing over 2880 periods; the only extra constraint is that battery charging cannot occur in "peak" which means weeks 1-4 i.e. 2-6, 9-13, 16-20, 23-27 November during 9am-5pm. Periods on 30 Nov and 1 Dec 9am-5pm (Mel time) are not considered "peak" for the recurring activities or battery charging, although once-off activities can be scheduled in these 10 hours and still get the "bonus".

Simultaneously, "flat_once_improve" starts with the recurring and once-off load, adds the quadratic objective function, and optimizes over 2880 periods. This is effectively just adding the battery in as no better solutions were found in the run time.
