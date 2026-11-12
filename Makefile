.PHONY: build install clean test integration
GIT_SHA=`git rev-parse --short HEAD || echo`

build:
	@echo "Building confd..."
	@mkdir -p bin
	@go build -ldflags "-X main.GitSHA=${GIT_SHA}" -o bin/confd .

install:
	@echo "Installing confd..."
	@install -c bin/confd /usr/local/bin/confd

clean:
	@rm -f bin/*

test:
	@echo "Running tests..."
	@go test ./...

integration:
	@echo "Running integration tests..."
	@for i in `find ./integration -name test.sh`; do \
		echo "Running $$i"; \
		bash $$i || exit 1; \
		bash integration/expect/check.sh || exit 1; \
		rm /tmp/confd-*; \
	done
