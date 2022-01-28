# ZDownloaderSample

URLSession has an ability to download in background, or to continue downloading even the app is killed.

This feature is grate if you app needs to download large amount of data, such as book or newspaper contents, or downloadable contents for games.  Users may not have to wait and keep watching download progress util done.

This sample code demonstrate how to take advantage from such background download feature.

You can find my presentation slide related to this here.

https://speakerdeck.com/codelynx/urlsession-reloaded

Sample code:

This sample app try download random 256 images from the internet.  It uses `URLSessionDownloadTask` to download images in background.  You may kill this app while downloading, and wait for few minutes, then launch this app once again, all the requested images may have been downloaded by system, and feed them to app, after relaunch the app.


### License

MIT License







