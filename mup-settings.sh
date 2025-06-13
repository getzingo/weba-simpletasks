#!/bin/bash

# This script helps you set up your mup deployment files

# First fill out your needed infos:
EC2_IP=""
SSH_KEY_LOCATION=""

# This probably doesn't need to be changed
EC2_USER="admin"

# Requested Url, this magically creates a temporary nameserver entry,
# pointin <url>.weba.ditm.at to the ip the curl call was made to.
URL=""
LETSENCRYPT_MAIL=""

# Mongodb Atlas
MONGO_CON_STRING=""



# Mup installed?
if [ -d ".deploy" ]; then
	echo "Meteor Up is ready"
  echo "---"
else
	echo "Please run Meteor Up init first via"
    echo "mup init"
    exit 2
fi

# All requirements set?
if ! [ -n "$EC2_IP" ]; then
	echo "Public ip of endpoint server not set"
	echo "Pls set EC2_IP"
	exit 3
fi

if ! [ -n "$EC2_USER" ]; then
	EC2_USER="admin"
fi

if ! [ -n "$URL" ]; then
	echo "Url not set"
	echo "Pls set URL"
	exit 4
fi

if [ -z "$SSH_KEY_LOCATION" ]; then
    for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa" "$HOME/.ssh/id_dsa"; do
        if [ -f "$key" ]; then
            SSH_KEY_LOCATION="$key"
            break
        fi
    done
fi

if [ -f "$SSH_KEY_LOCATION" ]; then
	echo "no ssh key found"
	exit 5
fi

if ! [ -n "$LETSENCRYPT_MAIL" ]; then
  echo "LETSENCRYPT_MAIL not set"
  echo "Pls set mail for letsencrypt"
  exit 4
fi

MUP_FILE=".deploy/mup.js"

mv $MUP_FILE $MUP_FILE.bak



cat > "$MUP_FILE" <<EOF
module.exports = {
  servers: {
    one: {
      host: "$EC2_IP",
      username: "$EC2_USER",
      pem: "$SSH_KEY_LOCATION"
    }
  },

  app: {
    name: "simpletasks",
    path: "../",

    servers: {
      one: {},
    },

    buildOptions: {
      serverOnly: true,
    },

    env: {
      ROOT_URL: "https://$URL.weba.ditm.at",
      MONGO_URL: "$MONGO_CON_STRING"
    },

    docker: {
      image: 'zodern/meteor:root',
    },
  },

  proxy: {
    domains: "$URL.weba.ditm.at",
    ssl: {
      letsEncryptEmail: "$LETSENCRYPT_MAIL",
      forceSSL: true
    }
  },

  hooks: {
    'pre.deploy': {
      remoteCommand: "curl https://weba-dynamic-dns.glitch.me/api/dnsname/$URL"
    },
    'post.deploy': {
      localCommand: "echo Try to go to https://$URL.weba.ditm.at"
    }
  }
};
EOF

echo "SUCCESS"
echo 'now run "mup setup"'