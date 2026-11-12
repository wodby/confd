# Contributing

This fork exists to build confd for Wodby Edge, so it keeps a small scope: the etcd v3
and env backends, current dependencies, and fixes that Edge needs. Open an issue or a pull
request against `master`.

Before opening a pull request, run:

```
gofmt -l .
go vet ./...
make test
```

Keep changes compatible with the command-line flags, configuration files, template
resources and template functions that Edge uses, and add an entry to `CHANGELOG`.
