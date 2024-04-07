export DEBIAN_FRONTEND=noninteractive

echo "[*] Running Configuration Script"

# upd/g
apt update
apt upgrade -y

# fail2ban
apt install fail2ban -y
cat <<EOT >> /etc/fail2ban/jail.d/customized-ssh-jail.conf
[DEFAULT]
ignoreip = 127.0.0.1
findtime = 3600
bantime = 604800
maxretry = 3
[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
EOT
service fail2ban restart

# https://sshaudit.com
rm /etc/ssh/ssh_host_*
ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli
sed -i 's/^\#HostKey \/etc\/ssh\/ssh_host_\(rsa\|ed25519\)_key$/HostKey \/etc\/ssh\/ssh_host_\1_key/g' /etc/ssh/sshd_config
echo -e "KexAlgorithms sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org,gss-curve25519-sha256-,diffie-hellman-group16-sha512,gss-group16-sha512-,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256\n\nCiphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr\n\nMACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com\n\nHostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nCASignatureAlgorithms sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256\n\nGSSAPIKexAlgorithms gss-curve25519-sha256-,gss-group16-sha512-\n\nHostbasedAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256\n\nPubkeyAcceptedAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-256" > /etc/ssh/sshd_config.d/ssha_hardening.conf
service ssh restart

# disable root bash history
echo "HISTFILESIZE=0" >> ~/.bashrc
history -c; history -w
source ~/.bashrc

echo "\n"

# add new admin user
echo "[?] Enter username for admin user:"
read admin_username

echo "[?] Enter password for admin user:"
read admin_password

useradd $admin_username
echo "$admin_username:$admin_password" | chpasswd

mkdir -p /home/$admin_username/.ssh
cp /root/.ssh/authorized_keys /home/$admin_username/.ssh/authorized_keys
chown -R $admin_username:$admin_username /home/$admin_username
usermod -aG sudo $admin_username
chsh -s $(which bash) $admin_username

# ufw
ufw allow OpenSSH
ufw enable

# tweak sshd_config; disable root and password login
sed -i -E 's/^(#)?PermitRootLogin (prohibit-password|yes)/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i -E 's/^(#)?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i -E 's/^(#)?PermitEmptyPasswords (yes|no)/PermitEmptyPasswords no/' /etc/ssh/sshd_config
service ssh restart

# set timezone
timedatectl set-timezone Europe/Malta
