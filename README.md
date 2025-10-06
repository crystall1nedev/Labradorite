# Labradorite
*noun*
1. a crystal with the properties of being able to find yourself and your wisdom
2. the name of my API to make device information available with ease
---
## What is it?
Labradorite is a **work-in-progress** API, ~~hoarding~~ cataloging Apple device specifications.

## How do I use it?
Just send a `GET` request to one of the endpoints on `https://labradorite.crystall1ne.dev`:

`/help` - Return more detailed documentation in `text/plain`.  
`/api/v0/identifier` - Return information on the passed identifier (i.e. iPhone17,2).  
`/api/v0/model` - Return information on the passed model number (i.e. A3084).  
`/api/v0/boardconfig` - Return information on the passed boardconfig (i.e. D94AP).  

## How do I contribute?
### Labradorite's data
I'm not currently taking contributions for the data available on my server yet.

### Labradorite's API server
The server component is in `src/`. It's a bunch of files written in the Go programming language, which makes it easy to get going - and fast.

TODO
