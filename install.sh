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
Bone framework comes with a Docker development environment. We recommend using this. However it is completely optional
and you can use your own web server, PHP and database.
"

read -p "Do you wish to use the Docker development environment? (Y/n)" yesno
case $yesno in
    [Nn]* )
        useDocker=0
        echo ""
        echo "Skipping server setup."
        if [[ -z $whichComposer ]]; then
          echo 'Unable to find composer, aborting.'
          exit 1;
        fi
    ;;
    * ) echo "" && echo "Using boneframework/lamp.";;
esac

echo "
Bone Framework can either be installed 'bare bones' via boneframework/skeleton, or come pre-configured with
many packages installed, such as user registration and login functionality, via boneframework/bone-native-backend-api.
If you will be using Bone Native to create smartphone apps, or if you just want the user login functionality, select
'Yes'. Otherwise select 'no' to use the skeleton app.
"

read -p "Do you wish to use the Bone Native Backend API? (Y/n)" yesno
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
Please give a name for this project, this will be the name of the directory we create. The native app folder (if installed)
will be suffixed with '-native'

Please enter a project name:"
read -r projectName
echo ''
echo "Please enter a development domain name (default is awesome.bone):"
read -r domainName
echo ''

if [[ -z domainName ]]; then
  domainName='awesome.bone'
fi

echo "Using https://$domainName for development.
You should add '127.0.0.1 $domainName' to your /etc/hosts file.
"

if (($useDocker == 0)); then
  if (($useBackend == 0)); then
    echo "Installing boneframework/skeleton."
    git clone https://github.com/boneframework/skeleton.git $projectName
  else
    echo "Installing boneframework/bone-native-backend-api"
    git clone https://github.com/boneframework/bone-native-backend-api.git $projectName
  fi
  cd $projectName
  rm -fr .git
  git init
  cp .env.example .env
  cat .env | sed -e "s/DOMAIN_NAME=awesome.bone/DOMAIN_NAME=$domainName/" > tmp && mv tmp .env
  composer install
  if (($useBackend == 1)); then
    echo "Run migrations, fixtures, deploy assets, etc"
  fi
else
  echo "Installing boneframework/lamp."
  git clone https://github.com/boneframework/lamp.git $projectName
  cd $projectName
  rm -fr .git
  rm -fr code
  if (($useBackend == 0)); then
    echo "Installing boneframework/skeleton."
    git clone https://github.com/boneframework/skeleton.git code
  else
    echo "Installing boneframework/bone-native-backend-api"
    git clone https://github.com/boneframework/bone-native-backend-api.git code
  fi
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
  echo ""
  echo "The development server is ready to be started. In order to continue, please open another shell terminal, and"
  echo "enter the following commands:"
  echo ""
  echo "cd $projectPath"
  echo "bin/start"
  echo ""
  echo "The Docker development environment will start up, once the servers are up, press [RETURN] to continue:"
  read pressToContinue
  bin/run vendor/bin/bone migrant:diff --no-interaction
  bin/run vendor/bin/bone migrant:migrate --no-interaction
  bin/run vendor/bin/bone migrant:generate-proxies --no-interaction
  bin/run vendor/bin/bone migrant:fixtures --no-interaction
  bin/run vendor/bin/bone assets:deploy --no-interaction
fi

if (($useNative == 1)); then
  cd ..
  git clone https://github.com/boneframework/skeleton.git ${projectName}-native
  cd ${projectName}-native
  npm ci --save-all
fi

echo "Time to set sail! Your project $projectName is ready to use!

Make sure you add '127.0.0.1 $domainName' to your /etc/hosts file.

Then head on over to https://$domainName and you should see the Bone Framework skeleton (or backend API)) home page.
To stop the server, CTRL-C in the terminal tab where you ran bin/start, and then run bin/stop"

if (($useNative == 1)); then
  echo "
The native app is installed in $projectPath-native. On your smartphone, download Expo Go from Google Play or Apple App Store.
To start the app, first run:

  cd $projectPath-native
  npx expo start

Then scan the QR code with your phone's camera in order to launch the app (or open Expo Go and open it that way)"
fi

echo "☠️ Welcome aboard and good luck on  your voyage!"
exit 0
