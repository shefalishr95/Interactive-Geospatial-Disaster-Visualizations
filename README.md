# Interactive geospatial visualization of disasters using FEMA dataset on RShiny app

### This project was completed as a part of 'Applied Data Science' course at Columbia University by a team of 4.

Term: Fall 2023

![screenshot](doc/figs/map.jpg)

+ Team 9
+ **Interactive geospatial visualization of disasters using FEMA dataset on RShiny app**: + Team members
	+ Ritika Nandi
	+ Shefali Shrivastava
	+ Yuchen Wu
	+ Roy
	+ Harini


Imagine you're on the verge of buying your dream home. You've saved up for a down payment and organized your finances. Now, you're ready to take the plunge. But before deciding on a location, wouldn't you like to know more about the county or state? What's the school quality like? How many public spaces are there? What's the transportation system like? And most importantly, how likely (or rather, unlikely) are natural or artificial disasters in the area?

We've developed an app to help you answer this crucial question. The app utilizes open datasets from the Federal Emergency Management Agency to provide historical data on number of disasters in your state, along with the average economic costs associated with those disasters. The main components of app are as follows:
1. County-wise disaster map.
2. Economic costs associated with disasters.
3. Word cloud of common disasters.

#### County-wise disaster map
This section uses open FEMA dataset to display the count of disasters by state, county, and year on the map of the United States. To see the count in your area, just select your state and county, and the year of interest. The map will automatically readjust to show you the number of disasters in the selected year in that area. Depending on the internet bandwidth and local memory, this map might take anywhere from 1 to 6 minutes to load – so please be patient!
As you scroll down, you'll encounter an alternate visualization—an informative bar plot. For all those who prefer seeing the numbers on a chart, we’ve created a bar plot illustrating the count of disasters in the selected year, county and state (meaning, you don’t need to re-select your specifications). Additionally, the bar plot also shows the number of disasters by category (such as ‘Fire’, ‘Flood’ etc.)

#### Economic costs associated with disasters
Say you do face an unfortunate disaster (we do hope that you don’t!). The next question that follows is: how much would this cost me? While it is difficult to collect primary information on financial repercussions, we can use disaster insurance claims as an alternate to estimate the cost of damages incurred.
In this section, you can check the average cost of disasters, as well as the estimated support from FEMA to mitigate cost of disasters (based on historical data). 

#### Word cloud of disasters
In the last section, we have an interesting visualization for those who prefer words over numbers and figures. The Word Cloud presented below displays the most frequent disasters in your state, for the selected year, using scale as a dimension. That means, the most commonly occurring disaster in your area is the biggest word, and second most common disaster is the second biggest word, and so forth. This visualization provides a succinct representation of the most commonly encountered disasters in your locality.


+ **Contribution statement**: ([default](doc/a_note_on_contributions.md)) All team members contributed equally in all stages of this project. All team members approve our work presented in this GitHub repository including this contributions statement. 

Following [suggestions](http://nicercode.github.io/blog/2013-04-05-projects/) by [RICH FITZJOHN](http://nicercode.github.io/about/#Team) (@richfitz). This folder is orgarnized as follows.

```
proj/
├── app/
├── lib/
├── data/
├── doc/
└── output/
```

Please see each subfolder for a README file.

