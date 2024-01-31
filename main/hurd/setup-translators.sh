#! /bin/sh

st() {
	local node="$1"; shift

	# Can't use 2>/dev/null yet.
	if [ ! -e "$node" ] || ! /bin/showtrans --silent "$node"; then
		/bin/settrans -c "$node" "$@"
	fi
}

stsock() {
	local domain="$1"; shift
	local name="$1"; shift

	st /servers/socket/"$domain" "$@"
	if [ ! -e /servers/socket/"$name" ]; then
		ln -s "$domain" /servers/socket/"$name"
	fi
}

md() {
	( cd /dev; /sbin/MAKEDEV --keep-all "$@" )
}

# Start by creating /dev/null and /servers/socket/1,
# before anything tries to use them.
mkdir -p /dev /servers/socket /servers/bus
> /dev/null
st /dev/null /hurd/null
chmod 666 /dev/null
stsock 1 local /hurd/pflocal
stsock 2 inet /hurd/pfinet -6 /servers/socket/26
stsock 26 inet6 /hurd/pfinet -4 /servers/socket/2

md std

st /servers/exec /hurd/exec
st /servers/default-pager /hurd/proxy-defpager
# st /servers/bus/pci /hurd/pci-arbiter
# st /servers/acpi /hurd/acpi
st /servers/shutdown /hurd/shutdown
st /servers/password /hurd/password

st /servers/crash-kill /hurd/crash --kill
st /servers/crash-suspend /hurd/crash --suspend
st /servers/crash-dump-core /hurd/crash --dump-core
ln -s crash-dump-core /servers/crash

md shm
st /tmp /hurd/tmpfs --mode=1777 50%

# md netdde
# md eth0
st /dev/eth0 /hurd/devnode eth0
chmod 660 /dev/eth0

md ptyp ptyq

st /proc /hurd/procfs --compatible
