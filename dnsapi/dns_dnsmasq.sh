#!/bin/sh

_configure() {
	DNSMASQ_HOSTS="${DNSMASQ_HOSTS:-$(_readaccountconf_mutable DNSMASQ_HOSTS)}"
	DNSMASQ_REMOTE_USER="${DNSMASQ_REMOTE_USER:-$(_readaccountconf_mutable DNSMASQ_REMOTE_USER)}"
	DNSMASQ_REMOTE_DIRECTORY="${DNSMASQ_REMOTE_DIRECTORY:-$(_readaccountconf_mutable DNSMASQ_REMOTE_DIRECTORY)}"

	# set some defaults if not provided explicitly
	DNSMASQ_REMOTE_USER=${DNSMASQ_REMOTE_USER:-root}
	DNSMASQ_REMOTE_DIRECTORY=${DNSMASQ_REMOTE_DIRECTORY:-/etc/dnsmasq.d}

	if [ -z "$DNSMASQ_HOSTS" ]; then
		_err "You must specify a list of hosts in DNSMASQ_HOSTS"
		return 1
	fi

	_saveaccountconf_mutable DNSMASQ_HOSTS "$DNSMASQ_HOSTS"
	_saveaccountconf_mutable DNSMASQ_REMOTE_USER "$DNSMASQ_REMOTE_USER"
	_saveaccountconf_mutable DNSMASQ_REMOTE_DIRECTORY "$DNSMASQ_REMOTE_DIRECTORY"
}

dns_dnsmasq_add() {
	fulldomain=$1
	txtvalue=$2

	_configure || return 1

	_debug fulldomain $fulldomain
	_debug dnsmasq_hosts ${DNSMASQ_HOSTS}
	_debug dnsmasq_remote_user ${DNSMASQ_REMOTE_USER}
	_debug dnsmasq_remote_directory ${DNSMASQ_REMOTE_DIRECTORY}

	for host in $DNSMASQ_HOSTS; do
		_info "creating challenge for $fulldomain on host $host"
		ssh ${DNSMASQ_REMOTE_USER}@${host} bash <<-EOF
		echo txt-record=${fulldomain},"${txtvalue}" >> ${DNSMASQ_REMOTE_DIRECTORY}/${fulldomain}.conf
		dnsmasq --test || return 1
		systemctl restart dnsmasq
		EOF
	done
}

dns_dnsmasq_rm() {
	fulldomain=$1
	txtvalue=$2

	_configure || return 1

	_debug fulldomain $fulldomain
	_debug dnsmasq_remote_host ${DNSMASQ_REMOTE_HOST}
	_debug dnsmasq_remote_user ${DNSMASQ_REMOTE_USER}

	for host in $DNSMASQ_HOSTS; do
		_info "removing challenge for $fulldomain from host $host"
		ssh ${DNSMASQ_REMOTE_USER}@${host} bash <<-EOF
		rm -f ${DNSMASQ_REMOTE_DIRECTORY}/${fulldomain}.conf
		dnsmasq --test || return 1
		systemctl restart dnsmasq
		EOF
	done
}
