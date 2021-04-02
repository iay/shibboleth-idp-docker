# `shibboleth-idp-docker`

## Shibboleth v4 Identity Provider Deployment using Docker

This project represents my personal deployment of the
[Shibboleth](http://shibboleth.net)
[v4 Identity Provider](https://wiki.shibboleth.net/confluence/display/IDP4)
software using the [Docker](http://www.docker.com) container technology.

If you find something useful here you're welcome to take advantage of it.
However, there's no guarantee that anything here actually works and I can't
really offer support. If you're starting out with the Shibboleth IdP and are
looking for a container deployment, I'd recommend looking at
[Internet2's TIER "Standalone" Shibboleth-IdP][tier-container] instead.
Far more people are using that these days, so you will find it easier to get
assistance.

[tier-container]: https://github.internet2.edu/docker/shib-idp


## Base Image and Java

This Docker build is based on [Amazon Corretto][] 11, an OpenJDK distribution
with long term support. This is produced by Amazon and used for many of their
own production services.

[Amazon Corretto]: https://aws.amazon.com/corretto/

If you want to replace this with another Java distribution, change the definition
of `JAVA_VERSION` in `VERSIONS`.

Any JDK from Java 11 onwards will _probably_ work, see the [system requirements][] for the IdP.
Note that JDKs from Java 15 onwards no longer bundle a Javascript engine, for example.

[system requirements]: https://wiki.shibboleth.net/confluence/display/IDP4/SystemRequirements


## Fetching the Jetty Distribution

You should execute the `./fetch-jetty` script to pull down a copy of the Jetty distribution
into `jetty-dist/dist`. The variables `JETTY_VERSION` and `JETTY_DATE` in the `VERSIONS` file
control the version acquired.

Some minimal validation is performed of the downloaded file using a locally compiled collection
of PGP keys referenced in the Jetty project's `KEYS.txt` file.

## Jetty 9.4 Configuration

Prior to 2020-02-04, the Jetty configuration used was part of the IdP installation mounted into
the running container. The actual configuration used was derived from the Jetty base used by the
Shibboleth project's Windows installer, and then locally edited. One advantage of this setup was
that the keystore passwords were not made part of the container image. One disadvantage is that
the installer mechanisms used to do this were not part of the supported API.

In the current iteration, the Jetty configuration has been moved inside the container image.
As part of the build, the `jetty-base-9.4` directory in this repository is copied to `/opt/jetty-base`
in the image. This is still _derived_ from the same source, but no longer depends on undocumented
features of the Shibboleth installer and comes pre-customised for the container environment.
Additionally, it lives outside the `/opt/shibboleth-idp` directory, which gives a cleaner
separation between Jetty and the IdP.

This default configuration uses default keystore passwords as follows.

In `jetty-base-9.4/start.d/idp.ini`:

```
## Keystore password
jetty.sslContext.keyStorePassword=changeit
## Truststore password
jetty.sslContext.trustStorePassword=changeit
## KeyManager password
jetty.sslContext.keyManagerPassword=changeit
```

In `jetty-base-9.4/start.d/idp-backchannel.ini`:

```
## Backchannel keystore password
# idp.backchannel.keyStorePassword=changeit
```

Arguably, there's little point in changing these values in the obvious way, as whatever you do
will end up on disk and additionally in a container image. I do want to use Docker secrets, or
Vault, or some other secrets management system to acquire and inject secrets like this. Until I get
round to that, though, I'd be delighted to get a pull request in this area.

If you do want to change these or other values, or make any other local customisations to the
Jetty configuration, you can of course just make a private branch of this repository and change
the files in `jetty-base-9.4` directly. I have also provided an overlay system to make this a
bit cleaner.

If you create, for example, `overlay/jetty-base-9.4/start.d/idp.ini`, then that file will overwrite
the one taken from `jetty-base-9.4`. Anything under `overlay` is ignored by Git so it can be a local
repository unconnected with this one. I have also made it possible for `overlay/jetty-base-9.4` to be
a symbolic link so that it can link to somewhere _inside_ another local repository.

See [`overlay/README.md`](overlay/README.md) for more detail on the overlay system.


## Jetty 9.3 Configuration

Version 4 of the identity provider requires Jetty 9.4 (if you're using Jetty) so it's no
longer possible to use Jetty 9.3. Support for that version has therefore been removed.

## Jetty 10.0 Configuration

Coming soon, maybe.

## Building the Image

Execute the `./build` script to build a new container image. This new image will be
tagged as `shibboleth-idp` and incorporate the Jetty distribution fetched earlier,
the `jetty-base` from this repository and any `overlay/jetty-base` you have created.

It will *not* include
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

* `TSPASS` and `SEALERPASS` are passwords to use if the trust fabric credentials or data sealer keystores,
respectively, need to be generated. It's arguable whether changing the default `changeit` values
really adds any security given that the values are just put in the clear in property files anyway.
I recommend leaving the values at their defaults.
* `SCOPE` should be your organizational scope.
* `HOST` is built from `SCOPE` by prepending `idp2.`, which probably won't suit you.
* `ENTITYID` is built from `HOST`. The default here is the same as the interactive install would suggest.

Executing the `./install` script will now run the Shibboleth install process in a container based on the
configured Docker Java image. If you do not have a `shibboleth-idp` directory, this will act like a first-time
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

## Credentials

An IdP deployment uses a number of cryptographic credentials. We've already
talked about some of these, but for clarity here's a summary of each along
with details to allow you to get started.

### Browser-facing credential

The _browser-facing_ credential, often referred to as the _user-facing_ or
_front channel_ credential, is used in the form of a TLS certificate presented
to the user's browser.

In this deployment, the browser-facing credential is entirely the concern of
the Jetty configuration, which assumes that a PKCS#12 keystore exists at
`.../credentials/idp-userfacing.p12`.
As described earlier, `jetty-base-9.4/start.d/idp.ini` assumes a default
password of `changeit` for this keystore, and I don't recommend changing this.

The `idp-userfacing.p12` keystore is *not* created by the process described
above, and the container will fail to start up properly until one is provided.

There are several ways to create this credential:

* If you're just testing, or if you're not planning to use front-channel TLS
access because your IdP is behind a reverse proxy of some kind, you can
generate a dummy keystore using the `./gen-selfsigned-cert` script. You may need
to edit the script to generate a certificate with appropriate subject fields.
The password you provide at the end of the `./gen-selfsigned-cert` process must
match the one in `jetty-base-9.4/start.d/idp.ini`.

* If you already have a commercial or in-house-issued credential for the IdP's
domain name, you can convert that to a `.p12` file using the instructions at
the end of this document and use that.

* You can use something like [certbot](https://certbot.eff.org) with
[Let's Encrypt](https://letsencrypt.org) to create and maintain a valid
short-lived certificate. The scripts `docker-certbot-initial` and
`docker-certbot-renew` do this, but I no longer use them in my configuration.

    If you want to try these:

    * Edit both files to use your domain name, not mine.
    * Create the three directories under `/srv` that they expect (see
      `script-functions` for defaults, or override them in a `CONFIG` file).
    * Run `./docker-certbot-initial` to create the initial certificate.
    * Every few days, run `./docker-certbot-renew` to acquire a new certificate
      and swap it into place if necessary.

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
* `./console` will give you a `bash` prompt inside the running container, with the current directory
  set to the IdP's home directory (`/opt/shibboleth-idp`).
* `./cleanup` can be used at any time to remove orphaned
containers and images, which Docker tends to create in abundance during
development. Use `./cleanup -n` to "dry run" and see what it would remove.
Docker has got a fair bit better at doing this itself over time, but you may still want
to run this once in a while to clear out dead wood.
* `docker-deploy-stack` deploys a container as part of a Docker "swarm mode" stack, defined in `stack.yml`.
  This is what I currently
  use "in production". In this deployment, the container runs behind a Traefik reverse proxy which terminates
  the TLS connection and manages Let's Encrypt certificates; the port 8443 back-channel is bound as a host
  port and is not proxied, to make it simpler for it to acquire the client certificate.
* `docker-remove-stack` removes the deployed stack.
* For IdP V4.1 and later, `plugin` and `module` run the `bin/plugin.sh` and `bin/module.sh` commands to manipulate
  IdP plugins and modules respectively. These commands require that the IdP is not already running, and run up
  an independent Docker container to perform their operations.

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

The entire package is Copyright (C) 2014&ndash;2021, Ian A. Young.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
