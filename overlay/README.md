# Local Overlays

The build process for the container image uses this directory as the source of
files to be overlaid on top of the distributions and standard configuration.
The main use for this facility is to provide local configuration, but it can also
be used to provide quick local patches.

Overlays can be directories, and a directory will be created for each potential
overlay if it doesn't already exist when the build process starts.

An overlay can also be a symbolic link to somewhere else in the filesystem.
This allows for overlays to be part of another Git repository (overlays are
not part of this repository, so that it can be public).

## `jetty-base-`xxx Overlays

The appropriate overlay for the version of Jetty in use
(e.g., `overlay/jetty-base-11.0`; `overlay/jetty-base-12.0`)
is applied to the Jetty base directory in the image.
