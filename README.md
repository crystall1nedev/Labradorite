# Labradorite
*noun*
1. a crystal with the properties of being able to find yourself and your wisdom
2. the name of my API<!--, framework, and app--> to make Apple device information available with ease
---
## What is it?
<!-- Labradorite has four components: -->
- A **work-in-progress** API server for Apple device specifications. This server is designed from the ground up
to provide easy-to-use endpoints for integration into other projects (a great example is my own copy of CorpNewt's
[CorpBot.py](https://github.com/CorpNewt/CorpBot.py))
<!--
- A **work-in-progress** Swift framework that uses this API - but not after attempting to derive device information
from the device itself, to stay as private as possible while providing the most information.
- Two **work-in-progress** Swift programs - a SwiftUI application, and command line tool - that use this framework to
provide device information at a glance, and allow you to browse information from any device supported by the API.
-->

## What do I need?
<!-- ### API -->
Something that's capable of sending a `GET` request to a server, and receiving any of the following:
- `application/json`
- `text/plain`
- HTTP error codes `200`, `400`, `404`, `405`, `500`

While the API works best when integrated into projects, the simplest way to get data from it is through a web browser.

<!-- 
### Swift framework, cli, and app[^1]
Any of the following operating systems:
- **iOS or iPadOS 14.0** or later
- **macOS Big Sur 11.0** or later
- **tvOS 14.0** or later
- **watchOS 7.0** or later
- **visionOS 1.0** or later
- **bridgeOS 7.0** or later[^2]

-->

## How do I get it?
<!-- ### API -->
Just send a `GET` request to one of the endpoints on `https://labradorite.crystall1ne.dev`:

`/help` - Return more detailed documentation in `text/plain`.  
`/api/v0/identifier` - Return information on the passed identifier (i.e. iPhone17,2).  
`/api/v0/model` - Return information on the passed model number (i.e. A3084).  
`/api/v0/boardconfig` - Return information on the passed boardconfig (i.e. D94AP).  

For running the API server on your own device, you'll need to have one of the following operating systems:
- **macOS Big Sur 11.0** or later[^1]
- **iOS or iPadOS 14.0** or later[^1][^2]
- **tvOS 14.0** or later[^1][^2]
<!--
- Linux NEEDS TO BE TESTED
- Windows NEEDS TO BE TESTED
-->

<!--
### Framework
copied from old readme, this needs to be updated for the Makefile setup, TODO
I'll release the first build of Labradorite in the Releases tab when it's ready for prime time. Until then:
1. Clone this repo
2. Open `Labradorite.xcodeproj`[^3]
3. Change the codesigning team in `Signing & Capabilities`
4. Build for your desired OS!

### App, CLI
uh, fucking open it??? TODO
-->

## How do I contribute?
### Labradorite's API data
I'm not currently taking contributions for the data available on my server. If you want to
know when I will be, hit up the #labradorite channel in [my Discord server](https://discord.crystall1ne.dev).

### Labradorite's API server
1. Clone this repo
2. Open `Codesigning.example.xcconfig`, make changes, and save it as `Codesigning.xcconfig`.
3. Open `Labradorite.xcworkspace`
4. Select `Labradorite-Server`
5. Build `labradorite-server`!

<!--
### Labradorite's framework
copied from old readme, this needs to be updated for the Makefile setup, TODO
1. Clone this repo
2. Open `Labradorite.xcodeproj`[^3]
3. Change the codesigning team in `Signing & Capabilities`
4. Edit and build for your desired OS!

### Labradorite's app, cli
same shit different day, TODO
-->


<!--
[^1]: This list is what I hope to target all the way through. If development hurdles come up, some functionality may be restricted to newer releases that are not listed here.
[^2]: Due to hardware and software restrictions, bridgeOS will not receive the SwiftUI-based application, and the framework will not feature API fallback functionality found on other platforms. 
-->

[^1]: Note that the source code should work down to **macOS Mojave 10.14** and **iOS 12**. Both are untested, and unsupported.
[^2]: Running the API server on iOS or tvOS requires a jailbreak.
