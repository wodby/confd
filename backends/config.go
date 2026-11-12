package backends

import (
	util "github.com/wodby/confd/util"
)

type Config struct {
	Backend        string     `toml:"backend"`
	BasicAuth      bool       `toml:"basic_auth"`
	ClientCaKeys   string     `toml:"client_cakeys"`
	ClientCert     string     `toml:"client_cert"`
	ClientKey      string     `toml:"client_key"`
	ClientInsecure bool       `toml:"client_insecure"`
	BackendNodes   util.Nodes `toml:"nodes"`
	Password       string     `toml:"password"`
	Scheme         string     `toml:"scheme"`
	Username       string     `toml:"username"`
}
