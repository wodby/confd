package backends

import (
	"errors"
	"strings"

	"github.com/wodby/confd/backends/env"
	"github.com/wodby/confd/backends/etcdv3"
	"github.com/wodby/confd/log"
)

// The StoreClient interface is implemented by objects that can retrieve
// key/value pairs from a backend store.
type StoreClient interface {
	GetValues(keys []string) (map[string]string, error)
	WatchPrefix(prefix string, keys []string, waitIndex uint64, stopChan chan bool) (uint64, error)
}

// New is used to create a storage client based on our configuration.
// This fork keeps only the etcd v3 backend, which "etcd" also selects as it
// did upstream, and the dependency-free env backend.
func New(config Config) (StoreClient, error) {
	if config.Backend == "" {
		config.Backend = "etcd"
	}
	backendNodes := config.BackendNodes

	log.Info("%s", "Backend source(s) set to "+strings.Join(backendNodes, ", "))

	switch config.Backend {
	case "etcd", "etcdv3":
		return etcdv3.NewEtcdClient(backendNodes, config.ClientCert, config.ClientKey, config.ClientCaKeys, config.BasicAuth, config.Username, config.Password)
	case "env":
		return env.NewEnvClient()
	}
	return nil, errors.New("Invalid backend")
}
