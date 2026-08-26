# rancher/hardened-crictl

## Build

```sh
TAG=v1.17.0 make
```

This image is never used directly but consumed by the RKE2 image to include crictl

Unlike other image-build-XXXX repositories, this one contains multiple values in the TAG file, since we support multiple minor branches of crictl. UpdateCLI and the CI is setup to consistently build the 3 newest minor versions of crictl. Calling `make` with no arguments with build only the latest version of crictl, but you can build all versions by calling `make image-build-all`.