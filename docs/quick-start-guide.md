# Quick Start Guide

Before we begin be sure to [download and install confd](installation.md).

## Select a backend

This fork of confd supports the following backends:

* etcd (v3 API; `-backend etcdv3` or `-backend etcd`)
* environment variables

### Add keys

This guide assumes you have a working [etcd](https://etcd.io/docs/latest/quickstart/) server up and running and the ability to add new keys.

#### etcd

```
etcdctl put /myapp/database/url db.example.com
etcdctl put /myapp/database/user rob
```

#### environment variables

```
export MYAPP_DATABASE_URL=db.example.com
export MYAPP_DATABASE_USER=rob
```

### Create the confdir

The confdir is where template resource configs and source templates are stored.

```
sudo mkdir -p /etc/confd/{conf.d,templates}
```

### Create a template resource config

Template resources are defined in [TOML](https://github.com/mojombo/toml) config files under the `confdir`.

/etc/confd/conf.d/myconfig.toml
```
[template]
src = "myconfig.conf.tmpl"
dest = "/tmp/myconfig.conf"
keys = [
    "/myapp/database/url",
    "/myapp/database/user",
]
```

### Create the source template

Source templates are [Golang text templates](http://golang.org/pkg/text/template/#pkg-overview).

/etc/confd/templates/myconfig.conf.tmpl
```
[myconfig]
database_url = {{getv "/myapp/database/url"}}
database_user = {{getv "/myapp/database/user"}}
```

### Process the template

confd supports two modes of operation daemon and onetime. In daemon mode confd polls a backend for changes and updates destination configuration files if necessary.

#### etcd

```
confd -onetime -backend etcd -node http://127.0.0.1:2379
```

#### env

```
confd -onetime -backend env
```

## Advanced Example

In this example we will use confd to manage two nginx config files using a single template.

### Add keys

#### etcd

```
etcdctl put /myapp/subdomain myapp
etcdctl put /myapp/upstream/app2 "10.0.1.100:80"
etcdctl put /myapp/upstream/app1 "10.0.1.101:80"
etcdctl put /yourapp/subdomain yourapp
etcdctl put /yourapp/upstream/app2 "10.0.1.102:80"
etcdctl put /yourapp/upstream/app1 "10.0.1.103:80"
```

### Create template resources

/etc/confd/conf.d/myapp-nginx.toml

```
[template]
prefix = "/myapp"
src = "nginx.tmpl"
dest = "/tmp/myapp.conf"
owner = "nginx"
mode = "0644"
keys = [
  "/subdomain",
  "/upstream",
]
check_cmd = "/usr/sbin/nginx -t -c {{.src}}"
reload_cmd = "/usr/sbin/service nginx reload"
```

/etc/confd/conf.d/yourapp-nginx.toml

```
[template]
prefix = "/yourapp"
src = "nginx.tmpl"
dest = "/tmp/yourapp.conf"
owner = "nginx"
mode = "0644"
keys = [
  "/subdomain",
  "/upstream",
]
check_cmd = "/usr/sbin/nginx -t -c {{.src}}"
reload_cmd = "/usr/sbin/service nginx reload"
```

### Create the source template

/etc/confd/templates/nginx.tmpl
```
upstream {{getv "/subdomain"}} {
{{range getvs "/upstream/*"}}
    server {{.}};
{{end}}
}

server {
    server_name  {{getv "/subdomain"}}.example.com;
    location / {
        proxy_pass        http://{{getv "/subdomain"}};
        proxy_redirect    off;
        proxy_set_header  Host             $host;
        proxy_set_header  X-Real-IP        $remote_addr;
        proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
   }
}
```
