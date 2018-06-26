# `shibboleth-idp-docker`

## Shibboleth v3 Identity Provider Deployment using Docker

This project is a workspace in which I am experimenting with deploying the
[Shibboleth](http://shibboleth.net)
[v3 Identity Provider](https://wiki.shibboleth.net/confluence/display/IDP30/Home)
software using the [Docker](http://www.docker.com) container technology.

Although this is what I'm using to deploy my own, rather minimal,
identity provider in "production", there's no guarantee that anything
here actually works. If you find
something useful you're welcome to take advantage of it.

## Base Image and Java

Although the Shibboleth IdP *usually* works with the OpenJDK variant of
Java, there have historically been some problems with it and we therefore
recommend the use of Oracle's version.

This Docker build is therefore based on my
[`iay/java:oracle-8`](https://github.com/iay/java-docker) image, which
incidentally includes the
[Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files]
(http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html).
Without these, the IdP can't use some useful encryption algorithms with "long" keys.
One important example is 256-bit AES, which is eligible for use in XML encryption
of messages sent to service providers.

As Oracle's license conditions mean that I can't distribute that image,
you will need to build a copy of it locally before building this image
on top of it.

## Fetching the Jetty Distribution

You should execute the `./fetch-jetty` script to pull down a copy of the Jetty distribution
into `jetty-dist/dist`. A variable at the top of the script controls the version acquired.

Some minimal validation is performed of the downloaded file, but at present it's on a "leap of faith"
basis as Jetty's approach to distribution signing has been a little hit and miss. Feel free to submit
a pull request if you have a better way of handling this.

## Building the Image

Execute the `./build` script to build a new container image. This new image will be
tagged as `shibboleth-idp` and incorporate the Jetty distribution fetched earlier. It will *not* include
the contents of `shibboleth-idp`; instead, they will be mounted into the container at `/opt/shibboleth-idp` when
a container is run from the image.

One important result of this approach is that the container image does not incorporate any secrets that are
part of the Shibboleth configuration, such as passwords. On the other hand, the container image doesn't really
contain much of the IdP, just a tailored environment for it.

**Note:** If a new version of Jetty is released and you wish to incorporate it, simply change the
version components in `VERSIONS`, and then execute `./fetch-jetty` and `./build`. Then,
terminate and re-create your container. You don't need to reinstall Shibboleth for this, as it's
not part of the image.

## Fetching the Shibboleth Distribution

You should execute the `./fetch-shib` script to pull down a copy of the Shibboleth IdP distribution
into `fetched/shibboleth-dist`. A variable at the top of the script controls the version acquired.

Some minimal validation is performed of the downloaded file using a file of PGP keys published by
the Shibboleth project and included here to avoid taking a complete "leap of faith" approach.

## Shibboleth "Install"

Before attempting the next step, you should edit the `install-idp` script to change the critical
parameters at the top:

* `UFPASS` and `SEALERPASS` are passwords to use if the user-facing TLS credential or data sealer keystores,
respectively, need to be generated. It's arguable whether changing the default `X-changethis` values
really adds any security given that the values are just put in the clear in property files anyway.
* `SCOPE` should be your organizational scope.
* `HOST` is built from `SCOPE` by prepending `idp2.`, which probably won't suit you.
* `ENTITYID` is built from `HOST`. The default here is the same as the interactive install would suggest.

Executing the `./install` script will now run the Shibboleth install process in a container based on the
`iay/java:oracle-8` image. If you do not have a `shibboleth-idp` directory, this will act like a first-time
install using the parameters you set before, resulting in a basic installation in that directory.

If `shibboleth-idp` already exists, `./install` will act to upgrade it to the latest distribution. This should
be idempotent; you should be able to just run `./install` at any time without changing the results. In this
case, the variables set at the top of the `install` script won't have any effect as the appropriate values
are already frozen into the configuration.

## Container Configuration

A rudimentary mechanism is provided to allow configuration of the scripts provided to interact with the Docker
container. Each relevant script defers configuration to `script-functions`, which sets defaults and then in turn
invokes `CONFIG` (if present) to override those defaults. An example `CONFIG` file is provided as
`CONFIG.example`.

By default, the container's port 443 and 8443 are bound to the Docker host's same-numbered ports on all
available interfaces. This is probably the right choice for most people. If you need to override this, you
can set `IPADDR` to a specific IP address in the `CONFIG` file.

Setting `IPADDR=127.0.0.1`, for example, might be useful to allow access to the IdP from only the
Docker host itself during testing. Another use for `IPADDR` would be to single out a specific host
interface on a multi-homed host.

## Executing the Container

Start a randomly named container from the image using the `./test` script. This is set up to be an interactive
container; you will see a couple of lines of logging and then it will appear to pause. Use ^C to stop the
container; it will be automatically removed when you do so.

All state, such as logs, will appear at appropriate locations in the `shibboleth-idp` directory tree.

## Other Lifecycle Scripts

Also included are:

* `./run` is a more conventional script to start a container called `shibboleth-idp` from the image
and run it in the background.
* `./stop` stops the `shibboleth-idp` container.
* `./terminate` stops the `shibboleth-idp` container and removes the container. This is useful if
you want to build and run another container version.
* `./cleanup` can be used at any time to remove orphaned
containers and images, which Docker tends to create in abundance during
development. Use `./cleanup -n` to "dry run" and see what it would remove.
Docker has got a fair bit better at doing this itself over time, but you may still want
to run this once in a while to clear out dead wood.

## Service Integration

The `service` directory includes service integration scripts that you can use after you have
used `./run` to fire up a container.

### `upstart` Integration

`service/shibboleth-idp.conf` is for `upstart`-based systems such as Ubuntu 14.04 LTS.
To work round a [known problem in Docker](https://github.com/docker/docker/issues/6647),
it makes use of the `inotifywait` command from the `inotify-tools` package, which may
not already be installed.

Install the service configuration as follows:

    # apt-get install inotify-tools
    # cp service/shibboleth-idp.conf /etc/init
    # initctl start shibboleth-idp

### `systemd` Integration

`service/shibboleth-idp` is for `systemd`-based systems. It is at present untested.

## OpenSSL Tips

You will often find that you have keys and certificates in a format other than the one you'd like. Here are
some recipes I've found useful in this work.

### Self-signed Certificate and Key to PKCS12

If you have a pair of PEM files (normally a self-signed certificate and the corresponding private key) and
need them in PKCS12 form for use with Jetty, you can try something like this:

    $ openssl pkcs12 -export -out X.p12 -inkey X.key -in X.crt

You'll be prompted for the output password, and the input password if one is required.

### Commercial Certificate and Key to PKCS12

If you have a certificate from a commercial CA, it will normally come with a bundle of intermediates
which need to be presented by the server in addition to the end entity certificate. If you need to
convert a private key, certificate and bundle to PKCS12 form for use with Jetty, try this:

    $ openssl pkcs12 -export -out X.p12 -inkey X.key -in X.crt -certfile chain.pem

Again, you'll be prompted for any relevant passwords.


## Copyright and License

The entire package is Copyright (C) 2014--2016, Ian A. Young.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

