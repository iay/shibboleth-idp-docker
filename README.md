# `shibboleth-idp-docker`

## Shibboleth V3.0 Identity Provider Deployment using Docker

This project is a workspace in which I am experimenting with deploying the
[Shibboleth](http://shibboleth.net)
[V3.0 Identity Provider](https://wiki.shibboleth.net/confluence/display/IDP30/Home)
software using the [Docker](http://www.docker.com) container technology.

There's no guarantee that anything here actually works, but if you find
something useful you're welcome to take advantage of it.

## Base Image and Java

Although the Shibboleth IdP *usually* works with the OpenJDK variant of
Java, there have historically been some problems with it and we therefore
recommend the use of Oracle's version.

This Docker build is therefore based on the `oracle-java8` tagged variant of
the [`dockerfile/java`](https://registry.hub.docker.com/u/dockerfile/java/) image.
This is an automated build providing the latest Oracle JDK in an Ubuntu
14.04 (Trusty Tahr) environment. It's quite a large container (about 750MB) but
as I use it for most of my development I don't find it to be significant in practice.

One limitation of this base container is that it doesn't include the
[Java Cryptography Extension (JCE) Unlimited Strength Jurisdiction Policy Files]
(http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html).
Without these, the IdP can't use some useful encryption algorithms with "long" keys.
One important example is 256-bit AES, which is eligible for use in XML encryption
of messages sent to service providers.

The solution to this is to install the policy files as part of the `docker build`
operation, and the `Dockerfile` assumes you have them available:

* Download `jce_policy-8.zip` [from Oracle](http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html).
You will need to accept their license agreement to do this, which is why I don't just include the files here.
* `gunzip jce_policy-8.zip` will generate the `UnlimitedJCEPolicyJDK8`
directory assumed by the `Dockerfile`.



## Copyright and License

The entire package is Copyright (C) 2014, Ian A. Young.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

