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

# Making an image and booting

Make and mount a disk image. You can use `qemu-img` / `qemu-nbd` to make a qcow2 image (or just `truncate`
or `dd` to make a raw one), `parted` to make a partition table with a partition on it, `mke2fs -o hurd` to
create the ext2 FS, then mount it.

Install `gnumach hurd alpine-base` into the guest chroot using the command above. You may need to copy
the signing key into `/mnt/etc/apk/keys`, or use `--allow-untrsuted`.

Make the other built packages available on the system, e.g.:

```
$ mkdir -p /mnt/root/packages/x86-hurd
$ cp ~/packages/main/x86-hurd/* /mnt/root/packages/x86-hurd/
$ echo /root/packages >> /mnt/etc/apk/repositories
```

Copy out `/boot/gnumach`, `/hurd/ext2fs.static`, and `/lib/ld.so.1` from the image to your host FS. Unmount
the image (and disconnect NBD if you're using that).

There is no GRUB yet, so you have to boot using QEMU's built-in multiboot support:

```
$ qemu-system-i386 -m 2G -enable-kvm \
    -drive file=/path/to/your-disk-file.qcow2,format=qcow2 \
    -kernel /path/to/gnumach -append 'root=part:1:device:hd0 console=com0 init=/bin/sh' \
    -initrd '/path/to/ext2fs.static --host-priv-port=${host-port} --device-master-port=${device-port} -T typed ${root} --readonly --multiboot-command-line=${kernel-command-line} --exec-server-task=${exec-task} $(fs-task=task-create) $(task-resume),/path/to/ld.so.1 /hurd/exec $(exec-task=task-create)' -nographic
```

This should boot to `/bin/sh`. Run `fsysopts / --writable`; then run `apk fix busybox` twice.
You can then try running `apk fix hurd` (or `/lib/hurd/setup-translators.sh` directly), but
this may break your system (ext2fs assertion failure & corruption). Also the system does not
boot at all if `/dev/random` (or `urandom`?) node is present, so unlink it if you do manage
to set up translator nodes.

If you boot without `init=/bin/sh`, OpenRC starts booting, but seems to hang somewhere.
