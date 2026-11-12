# Command Line Flags

Command line flags override the confd [configuration file](configuration-guide.md).

```
confd -h
```

```Text
Usage of confd:
  -backend string
      backend to use (default "etcd")
  -basic-auth
      Use Basic Auth to authenticate
  -client-ca-keys string
      client ca keys
  -client-cert string
      the client cert
  -client-insecure
      Allow connections to SSL sites without certs (only used with -backend=etcd)
  -client-key string
      the client key
  -confdir string
      confd conf directory (default "/etc/confd")
  -config-file string
      the confd config file (default "/etc/confd/confd.toml")
  -interval int
      backend polling interval (default 600)
  -keep-stage-file
      keep staged files
  -log-level string
      level which confd should log messages
  -node value
      list of backend nodes
  -noop
      only show pending changes
  -onetime
      run once and exit
  -password string
      the password to authenticate with
  -prefix string
      key path prefix
  -scheme string
      the backend URI scheme for nodes retrieved from DNS SRV records (http or https) (default "http")
  -srv-domain string
      the name of the resource record
  -srv-record string
      the SRV record to search for backends nodes. Example: _etcd-client._tcp.example.com
  -sync-only
      sync without check_cmd and reload_cmd
  -username string
      the username to authenticate as
  -version
      print version and exit
  -watch
      enable watch support
```

> The -scheme flag is only used to set the URL scheme for nodes retrieved from DNS SRV records.
