# ThumbHostSCAD
A macOS app that hosts a thumbnail provider that makes the Finder displays the thumbnails in some .scad files, and a command line tool for putting them there.

I wrote this because the normal way of giving a .scad file a custom icon caused the custom icon to be erased if you then opened the file in OpenSCAD and saved it again.

But, the normal way of giving a Mac file a custom icon is: 

* Use ⌘⇧4 to get a selection cursor and sweep out a rectangle you like. This will create a screenshot file on the desktop.

* Double-click that file then type: ⌘A⌘C⌘W (Select all, copy, close), then select the .scad file and type: ⌘I, and in the upper left corner of the Get Info window, select the file’s icon and type: ⌘V.

Note that if you edit your .scad files in an external editor, (I use Xcode), then the custom icon is preserved across saves.

So, the actual code here is pretty much an academic exercise. I'm posting it because I said I would.

## IMPORTANT: 

* macOS requires that apps that host Quicklook plugins, like ThumbHostSCAD, MUST be in `/Applications` or one of its subdirectories for the Quicklook plugin to function correctly! Note this is the actual `/Application` directory, and not an Application directory inside your home directory.

## To Install:

* Download, compile, and run the ThumbHostSCAD app. 

* Use ThumbHostSCAD's **File > Open** menu item and point at a directory containing .scad files: that will kick the Finder into noticing the embedded thumbnail presenter.

* The first time you install this, you should restart the Finder so it will see the new Quicklook plugin.

* To compile it yourself, use your team and domain name. I uploaded this as com.example, but in the release I signed it with my team and domain name.

To get previews in your .scad files, in OpenSCAD, open the .scad file, preview or render, and adjust the camera angle to your liking, then use ⌘⇧4 to get a selection cursor and sweep out a rectangle you like. This will create a screenshot file on the desktop.

Use the scadthumb commandline utility included in this repository, and in Terminal, type `scadthumb `
then drag the .scad file's icon from Finder into the Terminal window,  drag the screenshot file’s icon to the Terminal window and hit the return key.

## License

Apache 2 [License](LICENSE)
