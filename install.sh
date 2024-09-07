#!/usr/bin/env bash

echo "
  {}           {}
    \  _---_  /       ____                       ______                                           _
     \/     \/       |  _ \                     |  ____|                                         | |
      |() ()|        | |_) | ___  _ __   ___    | |__ _ __ __ _ _ __ ___   _____      _____  _ __| | __
       \ + /         |  _ < / _ \| '_ \ / _ \   |  __| '__/ _\` | '_ \` _ \ / _ \ \ /\ / / _ \| '__| |/ /
      / HHH  \       | |_) | (_) | | | |  __/   | |  | | | (_| | | | | | |  __/\ V  V / (_) | |  |   <
     /  \_/   \      |____/ \___/|_| |_|\___|   |_|  |_|  \__,_|_| |_| |_|\___| \_/\_/ \___/|_|  |_|\_\\
   {}          {}    Installer


Welcome to the Bone Framework installer.
"
useDocker=1
useBackend=1
useNative=1

whichGit=$(which git)
whichDocker=$(which docker)
whichComposer=$(which composer)
whichNpm=$(which npm)
whichNpx=$(which npx)

if [[ -z $whichGit ]]; then
  echo 'Git must be installed on this computer, aborting.'
  exit 1;
fi

if [[ -z $whichDocker ]]; then
  echo 'Docker must be installed on this computer, aborting.'
  exit 1;
fi

echo "
This installer will install the Bone Native Backend API and several Bone packages which provide user registration and login.
Of course, Bone Framework can also be installed 'bare bones' via boneframework/skeleton.
If you will be using Bone Native to create smartphone apps, or if you just want a website with login functionality, select
'Yes'. Otherwise select 'No' to use the skeleton app.
"

read -p "Do you wish to use the preconfigured Bone Framework? (Y/n)" yesno
case $yesno in
    [Nn]* )
        useBackend=0
        useNative=0
        echo ""
        echo "Using boneframework/skeleton."
    ;;
    * ) echo "" && echo "Using boneframework/bone-native-backend-api.";;
esac

if ((useBackend == 1)); then
  echo "
Bone Framework has a ready for development React Native Expo app via boneframework/bone-native.
  "
  read -p "Do you wish to use Bone Native? (Y/n)" yesno
  case $yesno in
      [Nn]* )
          useNative=0
          echo "Skipping boneframework/bone-native."
      ;;
      * )
          echo "Using boneframework/bone-native."
          if [[ -z $whichNpm ]]; then
            echo 'Unable to find npm, please install it.'
            exit 1;
          fi
          if [[ -z $whichNpx ]]; then
            echo 'Unable to find npx, please install it.'
            exit 1;
          fi
      ;;
  esac
fi

echo "
Please give a name for this project, this will be the name of the directory we create."
if (($useNative == 1)); then
  echo "The native app folder will be suffixed with '-native'"
fi

echo "Please enter a project name:"
read -r projectName
echo ''
echo "Please enter a development domain name (default is boneframework.docker):"
read -r domainName
echo ''

if [[ -z $domainName ]]; then
  domainName='boneframework.docker'
fi

echo "Using https://$domainName for development.
You should add '127.0.0.1 $domainName' to your /etc/hosts file.
"

# Install the LAMP stack
echo "Installing boneframework/lamp."
git clone https://github.com/boneframework/lamp.git $projectName
cd $projectName
rm -fr .git
rm -fr code

# Copy over custom SSL certificates
echo ""
read -p "Would you like to use an existing SSL certificate instead of generating one? (y/N)" yesno
case $yesno in
    [Yy]* )
        copied=false
        while ! $copied ; do
          read -p "Please give the path to your .crt file:  " crtFile
          if [[ -f $crtFile ]]; then
            cp $crtFile build/certificates/server.crt
            copied=true
          else
            echo "File $crtFile not found."
            ls ~/Desktop/
            ls $crtFile
          fi
        done
        copied=false
        while ! $copied ; do
          read -p "Please give the path to your .key file:  " keyFile
          if [[ -f "$keyFile" ]]; then
            cp $keyFile build/certificates/server.key
            copied=true
          else
            echo "File not found."

          fi
        done
    ;;
    * ) echo "" && echo "A self signed certificate for $domainName will be generated.";;
esac



if (($useBackend == 0)); then
  echo "Installing boneframework/skeleton."
  git clone https://github.com/boneframework/skeleton.git code
  cd code
  rm -fr .git
  git init
  cp .env.example .env
  cd ..
  echo "COMPOSE_PROJECT_NAME=$projectName" >> .env
  bin/setdomain $domainName
  projectPath=$(pwd)
  bin/run composer install
  echo "Time to set sail! Your Bone Framework project is ready for development."
  echo "Make sure you add '127.0.0.1 $domainName' to your /etc/hosts file."
  echo "To start the sever, run the following commands"
  echo ""
  echo "cd $projectPath"
  echo "bin/start"
  echo ""
  echo "To stop the server, press CTRL-C and then run bin/stop."
  echo ""
  echo "☠️  Welcome aboard and good luck on your voyage!"
  cd ..
  exit 0
else
  echo "Installing boneframework/bone-native-backend-api"
  git clone https://github.com/boneframework/bone-native-backend-api.git code
  cd code
  rm -fr .git
  git init
  cp .env.example .env
  cd ..
  echo "COMPOSE_PROJECT_NAME=$projectName" >> .env
  bin/setdomain $domainName
  projectPath=$(pwd)
  bin/run openssl genrsa -out private.key 2048
  bin/run openssl rsa -in private.key -pubout -out public.key
  mv code/public.key code/data/keys/public.key
  chmod 660 code/data/keys/public.key
  mv code/private.key code/data/keys/private.key
  chmod 660 code/data/keys/private.key
  bin/run composer install
  docker volume rm ${projectName}_db_data >/dev/null 2>&1
  echo ""
  echo "The development server is ready to be started. In order to continue, please open another shell terminal, and"
  echo "enter the following commands:"
  echo ""
  echo "cd $projectPath"
  echo "bin/start"
  echo ""
  echo "The Docker development environment will start up, once the servers are up, press [RETURN] to continue:"
  read pressToContinue
  bin/execute vendor/bin/bone migrant:diff --no-interaction
  bin/execute vendor/bin/bone migrant:migrate --no-interaction
  bin/execute vendor/bin/bone migrant:generate-proxies --no-interaction
  bin/execute vendor/bin/bone migrant:fixtures --no-interaction
  bin/execute vendor/bin/bone assets:deploy --no-interaction
fi

if (($useNative == 1)); then
  cd ..
  git clone https://github.com/boneframework/bone-native.git ${projectName}-native
  cd ${projectName}-native
  rm -fr .git
  git init
  npm ci --save-all
  cat .env | sed -e "s/EXPO_PUBLIC_API_URL=https:\/\/boneframework.docker/EXPO_PUBLIC_API_URL=https:\/\/$domainName/" > tmp && mv tmp .env
  cd ../${projectName}
  ipAddress=$(ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}' | head -n 1)
  bin/query "UPDATE Client SET redirectUri='exp://$ipAddress:8081/--/oauth2/callback'"
  docker compose exec $domainName bash -c "cat /etc/ssl/certs/server.crt" > ${domainName}.crt
  docker compose exec $domainName bash -c "cat /etc/ssl/certs/server.key" > ${domainName}.key
  source .env
  command="mariadb --user=$MYSQL_USER --password=\"$MYSQL_ROOT_PASSWORD\" --database=awesome -s -N --execute=\"SELECT identifier from Client where id = 1\""
  clientId=$(docker compose --env-file=.env exec -it mariadb bash -c "$command")
  cd ../${projectName}-native
  cat .env | sed -e "s/EXPO_PUBLIC_API_CLIENT_ID=.+/EXPO_PUBLIC_API_CLIENT_ID=$projectId/" > tmp && mv tmp .env
  echo "Please enter an Expo project ID (or press RETURN to skip):"
  read -r projectID
  echo ''
  if [[ -z $projectID ]]; then
    projectID='d216e1c7-29aa-4d2d-a535-88065482b06e'
  fi
  cat app.json | sed -e "s/        \"projectId\": \"d216e1c7-29aa-4d2d-a535-88065482b06e\"/        \"projectId\": \"$projectId\"/" > tmp && mv tmp app.json
  cat app.json | sed -e "s/    \"name\": \"Bone Native\"/    \"name\": \"$projectName\"/" > tmp && mv tmp app.json
  cat app.json | sed -e "s/    \"slug\": \"bone-native\"/    \"name\": \"$projectName\"/" > tmp && mv tmp app.json
fi

echo "Time to set sail! Your project $projectName is ready to use!

Make sure you add '127.0.0.1 $domainName' to your /etc/hosts file.

Then head on over to https://$domainName and you should see the Bone Framework skeleton (or backend API)) home page.
To stop the server, CTRL-C in the terminal tab where you ran bin/start, and then run bin/stop"

if (($useNative == 1)); then
  echo "
The native app is installed in $projectPath-native. On your smartphone, download Expo Go from Google Play or Apple App Store.

You will first need to install the site's self-signed certificate onto your phone, and add it to Prroxyman. See the REAME.md for more details.
The certificate can be found at $projectPath/${domainName}.crt, as can the key.

We detected your IP as $ipAddress, and so have set the API Client redirect URL to exp://${ipAddress}:8081/--/oauth2/callback
You should change this in the Client table of the database if you are on a different network

Open Proxyman recommended, and set your phone's WiFi connection to use the proxy IP ad port (typically ${ipAddress}:9090)
Then scan the QR code with your phone's camera in order to launch the app (or open Expo Go and open it that way)
"
  echo "The Docker backend is already running in your other tab."
  read -p "Do you wish to start the React Native Expo project too? (Y/n)" yesno
  case $yesno in
      [Nn]* )
          echo ""
          echo "Skipping $projectName-native launch."
          cd ..
      ;;
      * )
        echo "Launching Expo.."
        npx expo start
      ;;
  esac
else
  cd ..
fi

echo "
☠️  Welcome aboard and good luck on your voyage!"
exit 0
