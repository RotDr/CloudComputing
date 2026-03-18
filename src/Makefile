.PHONY: build dev patch

patch:
	sed -i 's/result\.then/result.try/g' build/packages/lustre_http/src/lustre_http.gleam

build: patch
	gleam build

check:
	gleam build 2>&1 | grep -v "build/packages"
	
dev: patch
	gleam run -m lustre/dev start