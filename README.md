# installer
Installer for Bone Framework on a Docker LAMP stack, bare bones or with preconfigured user functionality and API, and 
Native App. 
## requirements
- Linux / Mac / WSL
- Git
- [Docker](https://www.docker.com/)
- [Node LTS](https://github.com/nvm-sh/nvm)
- [Proxyman](https://proxyman.io/)
- [Expo Go](https://expo.dev/go) (on your phone)
## usage
Download and run the install.sh script from this repository using this command
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/boneframework/installer/master/install.sh)"
```
## post install tasks
The installer can't do everything by itself. We need to manually setup the VirtualHost, the proxy, and the SSL certificates.

### virual host
You've probably done this a hundred or more times before. Simply add your domain to `/etc/hosts`, like so:
```
127.0.0.1 boneframework.docker
```
Now you should be able to browse to `https://boneframework.docker` from your laptop's browser.
### proxy
Your phone will not be able to see your custom development domain name (that's hosted on your laptop) until you change the 
WiFi settings on it to use a proxy. Launch Proxyman on your laptop, and enter the IP address and port (typically 9090)
into the WiFi Proxy settings on your phone (info circle for your connection).

![Proxy](https://github.com/boneframework/.github/blob/master/profile/installer/proxy.PNG?raw=true) ![Proxy Settings](https://github.com/boneframework/.github/blob/master/profile/installer/proxy2.PNG?raw=true)

In Proxyman, find your domain in the domain section, right click, and select "Pin". \
In the panel on  the right, enable SSL Proxying.

![Pin Domain](https://github.com/boneframework/.github/blob/master/profile/installer/pin_domain.png?raw=true) ![Enable SSL Proxying](https://github.com/boneframework/.github/blob/master/profile/installer/ssl_proxy.png?raw=true)

### ssl certificates
Your custom SSL Certificate will first need to be installed on your phone before it can connect to your API properly, so 
you need to send the certificate to your phone.
#### Mac/iOS
- Right click on `/path/to/project/server.crt` and click 'Share'
- Select Airdrop, and send to your phone
 
![Airdrop](https://github.com/boneframework/.github/blob/master/profile/installer/1_airdrop.png?raw=true)

- Open Settings, and click on 'Profile' Downloaded, and install the certificate

![Airdrop](https://github.com/boneframework/.github/blob/master/profile/installer/2_profile_downloaded.PNG?raw=true)   ![Downloaded](https://github.com/boneframework/.github/blob/master/profile/installer/3_install_profile.png?raw=true)   ![Confirm](https://github.com/boneframework/.github/blob/master/profile/installer/4_confirm.PNG?raw=true)   ![Installed](https://github.com/boneframework/.github/blob/master/profile/installer/5_installed.PNG?raw=true)

- In Settings > About, scroll to the bottom and click 'Certificate Trust Settings'
- Flip the switch on and confirm 
- Open Safari and scroll to `https://boneframework.docker` (or your custom domain) and you should now be able to reach it.

![Certificate Trust Settings](https://github.com/boneframework/.github/blob/master/profile/installer/6_trust_settings.png?raw=true)  ![Trust Certificate](https://github.com/boneframework/.github/blob/master/profile/installer/7_trust_certificate.PNG?raw=true)

Also, download the [Proxyman CA certificate](http://cert.proxyman.io) `http://cert.proxyman.io` on your phone, install 
and trust in the same way as the previous one.

You are now ready to open your App and start developing! There is a user ready in the database so you can immediately 
login. `man@work.com` with password `123456`.

#### Android
- to be documented

## dev workflow
When developing your app, the workflow typically goes something like this.
- Turn on Proxyman
- Set the proxy in your phone's Wifi Settings
- Open your terminal
- `cd /path/to/project`
- `bin/start` (Docker will launch the backend)
- Open another terminal tab
- `cd /path/to/project-native`
- `npx expo start`
- Scan QR with your phone's Camera to launch the App
- Start coding features!
- Commit your code!

To shut down, in the native project tab, simply press `CTRL-C`. In the backend server tab, press `CTRL-C`,
and then run `bin/stop`.

### note
There is oe last thing to be aware of. The OAuth2 callback URL for the app in the `Client` table of 
your database unfortunately has our IP address in it (e.g. `exp://192.168.0.6:8081/--/oauth2/callback`). If you are not 
on your usual network, your IP address will probably be different. You will need to change that value, replacing the old 
IP address with your current one. I like to use [SequelAce](https://github.com/Sequel-Ace/Sequel-Ace) on Mac, or 
[HeidiSQL](https://www.heidisql.com/) on Windows, for my database client.
