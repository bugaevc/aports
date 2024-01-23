# How do I use this?

You should have a system with `abuild` (the Alpine Linux package build system) installed. An Alpine Linux
installation (or container) will do.

Do the setup described in [the Alpine wiki](https://wiki.alpinelinux.org/wiki/Creating_an_Alpine_package);
notably you need to generate keys with `abuild-keygen`.

Now to the uglier part: you have to patch your `/usr/share/abuild/functions.sh` to make it recognize glibc
and the Hurd; apply [`abuild-functions.patch`](abuild-functions.patch) from this repo:

```
$ doas patch --directory=/ -p1 < abuild-functions.patch
```

We should make this step less hacky, as patching system files in not nice, and the changes will be lost on
the next package upgrade.

To bootstrap, run

```
$ LANG_ADA=false scripts/bootstrap.sh x86-hurd
```

(Ada bootstrap [is borken in upstream Alpine](https://gitlab.alpinelinux.org/alpine/aports/-/issues/15381)).
If things work, you should have a bunch of APK packages in `~/packages/` now :) You can install them with

```
$ doas apk --arch x86-hurd --repository ~/packages/main/ --root ~/sysroot-x86-hurd/ --initdb --no-script add pacakge1 package2 package3
```

try `glibc-utils`, `hurd`, `curl`, `apk-tools` packages for example.

The first package that does not build is `grub`.
