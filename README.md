# send_1001Tracklist
a crap and dirty perl code which checks if a new tracklist of a given artist/dj at 1001tracklist.com is released and send it to discord

# usage
./script.pl adambeyer "Adam Beyer"

the first arg is the 1001tracklist.com name of the artist (you can find it in the url e.g. https://www.1001tracklists.com/dj/adambeyer/index.html

the second arg is the display name. you can choose whatever you want. this is only used for the embed discord message (because "adambeyer" isnt quite sexy for a title of a message...)

you also need a file for each artist which is located in the same folder as "script.pl". the file must be named like the 1001tracklis-artist-name (e.g. "adambeyer"). this is needed for checking if a new title appeared. 

# else to say

the exec time is 8 secs on my machine so its MAYBE A KIND OF unefficient... if someone has a better way to do that, pls tell me :D
