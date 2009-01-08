
Whiteboard
(Base sample code from WiTap, GLPaint)

================================================================================
DESCRIPTION:

Whiteboard is a collaborative drawing app for iPhone and iPod touch (iTouch) devices. It includes multiplayer peer-to-peer network communication to allow multiple people to draw on the same whiteboard simultaneously. Using Bonjour, your device will both advertise a whiteboard and search for other whiteboards to join on the local network.

Wait for another person to connect to your whiteboard, or select another whiteboard to connect to. Once connected, draw on your whiteboard to see the same drawing simultaneously performed on the remote device.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.5.3, Xcode 3.1, iPhone OS 2.0

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.5.3, iPhone OS 2.0

===========================================================================
PACKAGING LIST:

AppController.h
AppController.m
UIApplication's delegate class, the central controller of the application.

TapView.h
TapView.m
UIView subclass that can highlight itself when locally or remotely tapped.

Picker.h
Picker.m
A view that displays both the currently advertised game name and a list of other games
available on the local network (discovered & displayed by BrowserViewController).

Networking/TCPServer.h
Networking/TCPServer.m
A TCP server that listens on an arbitrary port.

Networking/BrowserViewController.h
Networking/BrowserViewController.m
View controller for the service instance list.
This object manages a NSNetServiceBrowser configured to look for Bonjour services.
It has an array of NSNetService objects that are displayed in a table view.
When the service browser reports that it has discovered a service, the corresponding NSNetService is added to the array.
When a service goes away, the corresponding NSNetService is removed from the array.
Selecting an item in the table view asynchronously resolves the corresponding net service.
When that resolution completes, the delegate is called with the corresponding net service.

main.m
The main file for the Whiteboard application.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Whiteboard Version 1.0
- Renamed from WiTap to Whiteboard and reset version number to 1.0.
- Integrated with GLPaint code.
- Changed to a whiteboard and added many other enhancements.
- Known issue: anything drawn before connecting is not sent over the network.

Version 1.5
- Updated for and tested with iPhone OS 2.0. First public release.

Version 1.4
- Updated for Beta 7.
- Code clean up.
- Improved Bonjour support.

Version 1.3
- Updated for Beta 4. 
- Added code signing.

Version 1.2
- Added icon.

Copyright ©2008 Apple Inc. All rights reserved.