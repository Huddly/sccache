#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <version tag, for example v0.17.1>" >&2
	exit 2
fi

version_tag=$1
release_version=${version_tag#v}
release_target=x86_64-unknown-linux-musl
release_name="sccache-${version_tag}-${release_target}"
repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

cd "$repo_root"

cargo_version=$(awk -F '"' '/^version = / { print $2; exit }' Cargo.toml)
if [ "$version_tag" = "$release_version" ] || [ "$cargo_version" != "$release_version" ]; then
	echo "Version tag must match Cargo.toml version $cargo_version" >&2
	exit 2
fi

if [ -e "${release_name}.tar.gz" ]; then
	echo "${release_name}.tar.gz already exists" >&2
	exit 1
fi

sudo apt install -y musl-tools
rustup target add "$release_target"

CC_x86_64_unknown_linux_musl=musl-gcc \
CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=musl-gcc \
cargo build --locked --release \
	--bin sccache \
	--target "$release_target" \
	--features=openssl/vendored

tar -zcvf "${release_name}.tar.gz" \
	--transform="s|^|${release_name}/|" \
	-C "target/${release_target}/release" sccache \
	-C "$repo_root" README.md LICENSE
