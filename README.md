# Charm - Simple Tasks

This is a fork for the course **"Web-Architekturen"**.
This should serve as a guide for assessing colleagues, to install this App and get it running as easy as possible.

This was tested on a fresh Debian 12 machine.

## Step 1: Install Meteor on local machine

```bash
# As standard user
sudo apt update
sudo apt install curl git

# Instructions from nvm repo (current latest version)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Add to path
echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc

source ~/.bashrc

# latest version of node
nvm install node
npx meteor

echo 'export PATH="$HOME"/.meteor:$PATH' >> ~/.bashrc
source ~/.bashrc

# If you don't yet have a ssh key, generate one:
ssh-keygen -t ed25519
```


## Step 2+3: Run SimpleTasks

Also includes changes of the navbar-logo and changes of the colors of the gradients.

These changes are:

```jsx
//// ui/pages/tasks/tasks-page.jsx
// -
bgGradient="linear(to-l, #675AAA, #4399E1)"
// +
bgGradient="linear(to-l, #B54343, #8566B3)"


//// ui/pages/tasks/components/task-form.jsx
// -
bg="blue.600"
// +
bg="telegram.700"


//// ui/common/components/navbar.jsx
// -
bgGradient="linear(to-l, #675AAA, #4399E1)"
// +
bgGradient="linear(to-l, #B54343, #8566B3)"

// -
Simple Tasks
// +
 /\/\
````

```bash
# As standard user
git clone https://github.com/getzingo/weba-simpletasks.git
cd weba-simpletasks

# Optional, but following course instructions,
# adding changes to color them and logo
cp ui/common/components/navbar.gez.jsx ui/common/components/navbar.jsx
cp ui/pages/tasks/components/task-form.gez.jsx ui/pages/tasks/components/task-form.jsx
cp ui/pages/tasks/tasks-page.gez.jsx ui/pages/tasks/tasks-page.jsx

# Dependencies
meteor npm install

# Because this is not ran on localhost, we want to expose it via
# IP-address of the virtual machine, after successfull launch
# address will be displayed in the Meteor shell output
meteor --port $(hostname -I | awk '{print $1}'):5000
```

This exposes the app to your VM's primary IP so it’s accessible externally; if running locally, use --port 5000.

If there is no firewall in place, you should be able to reach the simpletasks app at port 5000.

Ctrl + C to stop the process.


## Step 4: Deploy on AWS EC2 via Meteor Up

Now that there is a working local version of the webapp, let's deploy it on AWS.

### Create Instance

Optional: get your local public ssh-key with `cat ~/.ssh/id_ed25519.pub`

1. Create new EC2 Instance on AWS Management Console:
  - OS: Debian 12
  - Type: t2.micro
  - Drive capacity: >10GB
  - Security Group: allow ssh, http, https
  - Keypair: (Existing Pair or the one generated before)
2. Create Elastic IP for public access
  - Under "Network & Security" -> Elastic IPs
  - Create new IP
  - Assign it to the new EC2 Instance
  - take a note of the IP, we need it later
3. Connect: `ssh -i labsuser.pem admin@<ip>`

ssh connection is essential.

### Create Atlas Account

- Go to [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) and register an account
- Create a Cluster
- Be sure to pick free tier
- Create user and password
- Add public IP of the ec2 instance to 'Network Access List'


### Deploy with Meteor Up

Meteor Up prepares your JS app, packages it into a docker container, as to make dependencies easier, and manages the deployment, even offering modular extensions.
We will be using the proxy module for letsencrypt and the hooks module, to automatically generate a nameserver entry.

To do that, you first need a few things:
1. Ssh privkey of the remote ec2 instance
2. Public IP of the ec2 instance
3. An Url where your tasks-app is going to be reachable
4. Mongodb Atlas Account and ultimately the connect string, should kinda look like `mongodb+srv://<user>:<pw>@url.mongodb.net/?retryWrites=true&w=majority&appName=blablabla`
5. A mailaddress needed to verify authenticity to receive a certificate with letsencrypt


#### Install Meteor Up

```bash
# still in weba-simpletasks directory on the local machine
npm install -g mup

# This created a .deploy directory with all infos
mup init
```


#### Populate settings

To simplify injecting the infos listed above into the mup config, add them to the top of mup-settings.sh. Do this via `./mup-settings.sh`

```bash
# go to the .deploy directory
cd .deploy

# verify settings
less mup.js

# Prepare the remote server, this installs all dependencies
mup setup

# If there are no errors, we can deploy the app
mup deploy
```

Now you can try to see if the app is reachable at https://<chosen url>.weba.ditm.at

#### Troubleshooting

Many problems are mentioned here at the [official docs](https://meteor-up.com/docs.html#common-problems)

I really only had one error during deployment, I solved with
meteor npm install --save @babel/runtime

---

# Build the app as selfcontained container image

First install your favorite container runtime, for example docker with the [official instructions](https://docs.docker.com/engine/install/debian/).

Then clone this repo `git clone https://github.com/getzingo/weba-simpletasks.git` if you haven't already.

Cd into the folder:
```bash
cd weba-simpletasks
```

Build the container image, I chose debian, to stay consistent and because I know it the best:
```bash
podman build -t simpletasks-dev:latest .
```

And finally you can run the Container:

```bash
p run --network=host --name simpletasks simpletasks-dev
```

Try to go to http://localhost:3000 to reach the web-app.


**Notes:**
I had a lot of troubles with the official node images and to build on top of them. So i opted for debian instead.

Also be sure to give the machine that builds the server enough memory, I ran into many Out-Of-Memory errors during build.

Resulting Image will be huge, around 1.7GB!



---

**Original README** can be found at [here](ORIG-README.md)



---

Sources:
- https://docs.meteor.com/cli
- https://forums.meteor.com
- https://docs.docker.com/engine/install/debian/
- https://docs.podman.io/en/latest/
- 