package main

// Version is the release version. Release builds set it from the tag with
// "-ldflags -X main.Version=X.Y.Z"; it is a variable so they can.
var Version = "0.17.0-dev"

// We want to replace this variable at build time with "-ldflags -X main.GitSHA=xxx", where const is not supported.
var GitSHA = ""
