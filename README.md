# confd

`confd` keeps local configuration files up to date using data stored in
[etcd](https://etcd.io), processes [template resources](docs/template-resources.md),
and reloads applications to pick up the new files.

This is Wodby's fork of [kelseyhightower/confd](https://github.com/kelseyhightower/confd),
which has had no release since 2018. It is built into the
[Wodby Edge](https://github.com/wodby/edge-alpine) image, and is maintained for that use:

- Only the etcd v3 backend (`-backend etcdv3`, or `-backend etcd`, which upstream
  already mapped to the same client) and the dependency-free `env` backend remain.
  The consul, dynamodb, file, rancher, redis, ssm, vault and zookeeper backends and
  their flags are removed.
- Command-line flags, configuration files, template resources and template functions
  otherwise work as in upstream confd.
- Dependencies are kept current. The etcd client follows the etcd 3.6 line that Wodby
  runs.

## Building

Go 1.26 or later is required.

```
make build
```

The binary is written to `bin/confd`. Tests:

```
make test
```

`make integration` runs the template integration tests for the `env` and `etcdv3`
backends. The `etcdv3` test needs `etcdctl` and an etcd server on `127.0.0.1:2379`.

## Releases

Releases are `vX.Y.Z` Git tags, and Wodby Edge builds confd from the tag's source.
Maintainers sign the tags they publish and list the changes in `CHANGELOG`.

Dependabot proposes security updates only. When CI passes on one of its pull requests,
the Release security updates workflow merges it and publishes the next patch tag, with
the updated modules in the tag message. An update that would move the etcd client off
3.6, or that changes more than `go.mod` and `go.sum`, stays open for review.

## Documentation

- [Quick start guide](docs/quick-start-guide.md)
- [Command line flags](docs/command-line-flags.md)
- [Configuration guide](docs/configuration-guide.md)
- [Template resources](docs/template-resources.md) and [templates](docs/templates.md)

## License

MIT, see [LICENSE](LICENSE). confd was created by Kelsey Hightower and its contributors.
