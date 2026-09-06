## The Mixlists Project

Visualize and explore over 2000 songs laid out across 108 playlists. See links between the playlists stitched out by songs, artists, albums. Mix and match which ones to listen to, explore insights about trends over time, read stories about the context in which each of the playlists was made. Perhaps even listen to them all in a grand jukebox without duplicates. 

Most of these whirlwind features will require Spotify API integration but I'm sure we can handily solve that. 

Ultimately we're looking for insights like:

* What other mixlists is this song present on? 
* How many times is this artist featured across mixlists? (even if songs are duplicate)
* What artists are often featured together? (think The Offspring and Green Day or The Wonder Years and TSSF)

And most importantly: a simple and clever way to illustrate the aesthetic structures which guide the flow of many mixlists out there. I'd add to that having "brother mixlists", trilogies and even callbacks / links across the different mixlists.

Ultimately this could evolve into either an artistic experiment (autofiction driven by why I made these playlists in the first place) or a catch-all application to store and visualize playlists in (attempted before, but surely shoddily).

Previous efforts on Mixlists project include:
* Demonstration Go project which led to the Simple Output. That one was using json from Spotify Export which was much sparser in information. We now have links to spotify tracks which allow you to play tracks straight from the app easily without an explicit Spotify API integration.
* Simple SQLite database with basic tables structure - not sure where this one is but I'm positive I wrote a simple bash script to generate that database, not unlike that first year coursework.
