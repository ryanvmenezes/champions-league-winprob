# model notes: v2.2

Instead of every model using the data for just the points at that one minute of the tie, this approach used a window of data before and after the minute. For example, in model v2.1, the model for minute 40 looked at every data point for the 40th minute in every match, and used that to make a prediction. In this approach, the model for minute 40 used data points from minutes 30 to 50 to create a prediction for minute 40. This is more true to the spirit of a local regression, where predictions are based on a certain window of data.

This artisanal approach allowed me to finely calibrate the window of data for each of the 210 models (one for every minute in two 90-minute matches, plus another 30 minutes for extra time games). After some trial and error I settled on these windows:
* For minutes before 170: All data points 10 minutes before and 10 minutes after
* For minutes 170 to 179: All data points 3 minutes before and 3 minutes after
* For minute 180: Just minute 180 data
* For minutes 181 to 199 (extra time, much less data starting here): All data points 10 minutes before and 10 minutes after
* For minutes 200 to 209: All data points 3 minutes before and 3 minutes after
* For minutes 210: Just minute 210 data

This performed much better than v2.1, though there were still some games where the model would not converge to one end or the other properly. 
