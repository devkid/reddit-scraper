Reddit Scraper
==============

With this little Ruby script you can download the latest pictures from your favorite subreddit on reddit.com. It is initially intended for downloading images from /r/EarthPorn as wallpapers.

As of now it can download pictures from the following sources:

* direct links to image files (ending in .jpg or .png)
* links to imgur.com (single images or first image of an album)
* more to follow

With several command line options you can filter which images you want to download by:

* resolution
* aspect ratio
* minimum number of upvotes
* hot, new, top, etc.

You can also specify how many of those images to keep in your download folder. If there are you new images available on reddit, old ones can be deleted automatically.

For a list of all options call the script with -h or --help parameter. 
