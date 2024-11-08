#!/bin/sh

# Update and install essential packages
apt-get update
apt-get install -y whiptail locales wget fdisk parted

# Set locale to US English UTF-8
export LANG=C
export LC_CTYPE=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Configure locale settings
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e 's/en_IN UTF-8/# en_IN UTF-8/' /etc/locale.gen
locale-gen en_US en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/environment
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8

# Disable IPv6 as it is often not needed
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null

# Disable unnecessary services
systemctl stop ufw 2>/dev/null
systemctl disable ufw 2>/dev/null
systemctl stop apparmor 2>/dev/null
systemctl disable apparmor 2>/dev/null

# Set aliases for convenience and CentOS-like behavior
cat <<EOL >> /etc/bash.bashrc
alias cp='cp -i'
alias l.='ls -d .* --color=auto'
alias ll='ls -l --color=auto'
alias ls='ls --color=auto'
alias mv='mv -i'
alias rm='rm -i'
export EDITOR=vi
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
# export KUBECONFIG="/etc/kubernetes/admin.conf"
EOL

# Configure /etc/rc.local to disable IPv6 and other boot settings
setup_rc_local() {
  mkdir -p /opt/old-config-backup
  cp -pR /etc/rc.local /opt/old-config-backup/old-rc.local-$(date +%s) >/dev/null 2>/dev/null
  cat <<EOF > /etc/rc.local
#!/bin/bash
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl vm.swappiness=0
swapoff -a
modprobe overlay
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1
exit 0
EOF
  chmod 755 /etc/rc.local
}
setup_rc_local

# Create systemd service for rc-local
cat <<EOF > /etc/systemd/system/rc-local.service
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable rc-local
systemctl start rc-local

# Kubernetes prerequisites
cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Adjust journald settings to avoid rate limiting
sed -i "s/#RateLimitIntervalSec=30s/RateLimitIntervalSec=0/" /etc/systemd/journald.conf
sed -i "s/#RateLimitBurst=10000/RateLimitBurst=0/" /etc/systemd/journald.conf
systemctl restart systemd-journald
systemctl daemon-reload

# Auto-confirmations for CPAN Perl package manager
(echo y;echo o conf prerequisites_policy follow;echo o conf commit) | cpan >/dev/null

# Configure Vim for new users to disable automatic mouse-based visual mode
echo "\"set mouse=a/g" > ~/.vimrc
echo "syntax on" >> ~/.vimrc
echo "\"set mouse=a/g" > /etc/skel/.vimrc
echo "syntax on" >> /etc/skel/.vimrc

# Enable IP forwarding for routing purposes
sed -i "s/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g" /etc/sysctl.conf

# Optional: Enable root login over SSH on custom port (7722)
# Uncomment the following to enable this:
# sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
# sed -i "s/#Port 22/Port 7722/g" /etc/ssh/sshd_config
# systemctl restart ssh

# Final package cleanup and upgrade
apt update
apt -y autoremove
apt -y upgrade
apt -y dist-upgrade

# Install additional essential packages and tools
CFG_HOSTNAME_FQDN=$(hostname -f)
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $CFG_HOSTNAME_FQDN" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt -y install vim chrony openssh-server screen net-tools git mc postfix sendemail tmux \
    sudo wget curl ethtool iptraf-ng traceroute telnet rsyslog software-properties-common \
    dirmngr parted gdisk apt-transport-https lsb-release ca-certificates iputils-ping \
    bridge-utils iptables jq conntrack gnupg nfs-common socat ipset \
    rsyslog-kubernetes kubetail kubecolor ebtables elinks iftop vnstat

# Disable swap for Kubernetes
sed -i '/swap/s/^/#/' /etc/fstab
swapoff -a
## Enable ip forward - routing..
sysctl -w net.ipv4.ip_forward=1

echo ""
echo "---------------------------------------------------------"
echo "Reboot to load kernel update if any and swapoff for k8s"
echo "---------------------------------------------------------"
echo ""

