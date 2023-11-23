# Labradorite
*noun*
1. a crystal with the properties of being able to find yourself and your wisdom
2. the name of my framework to make device information available with ease
---
## What is it?
Labradorite is a **work-in-progress** framework aiming to make getting device information from Apple *OS' fast, easy, and secure. 

## What do I need?[^1]
| OS | Minimum |
| --- | --- |
| iOS | 14.0 |
| iPadOS | 14.0 |
| macOS | 11.0 |
| tvOS | 14.0 |
| watchOS | 7.0 |
| bridgeOS[^2] | 5.0 |
| visionOS | 1.0 |

## What can I do with this?
TBD, still need to make a list of what I am going to implement.

## How do I get it?
I'll release the first build of Labradorite in the Releases tab when it's ready for prime time. Until then:
1. Clone this repo
2. Open `Labradorite.xcodeproj`[^3]
3. Change the codesigning team in `Signing & Capabilities`
4. Build for your desired OS!

[^1]: This list is what I hope to target all the way through. If development hurdles come up, some functionality may be restricted to newer releases that are not listed here.
[^2]: bridgeOS support is not guaranteed as I do not have a working device with the Apple T2 Security chip. AFAIK, compiling with the iOS or watchOS SDKs and then jamming it onto a bridgeOS device should yield proper execution.
[^3]: Labradorite.xcworkspace can also be used, as long as you change the scheme to the Labradorite framework. LabradoriteFrontend is an internal testing and production suite that I'm working on, and not yet comfortable in releasing.
