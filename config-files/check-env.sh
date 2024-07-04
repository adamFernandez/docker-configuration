#!/bin/bash

. ./config-files/get/package_front.sh

mkdir -p ./config-files/logs

if [ ! -f config-files/logs/.check-env_done ]; then

  echo -e "\nValues between brackets are the default ones. \nLeave blank and press enter if you don't know the Imgix, AS3 or GTM project settings:"
  sleep 1;

  read -p $'\n'"Imgix url [https://backendplay.imgix.net]: " imgix
  imgix=${imgix:-https://backendplay.imgix.net}

  read -p "As3 url [https://backend-playground.s3.amazonaws.com]: " as3
  as3=${as3:-https://backend-playground.s3.amazonaws.com}

  read -p "As3 Access Id [backend-playground]: " aid
  aid=${aid:-AKIAQOCTXXCCOKI5SL5Z}

  read -p "As3 Secret Key [backend-playground]: " skey
  skey=${skey:-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}

  read -p "GTM id [GTM-XXXXXXX]: " gtm
  gtm=${gtm:-GTM-XXXXXXX}

  echo -e "\nImgix: $imgix"
  echo "AS3: $as3"
  echo "AS3 Access Id: $aid"
  echo "AS3 Secret Key: $skey"
  echo -e "GTM id: $gtm\n"

  front_imgix=$([ $front_type == "astro" ] && echo "IMGIX_SOURCE_DOMAIN" ||  echo "IMGIX_URL")

  sed -i '' -e "s/IMGIX_URL=/$front_imgix=/g" \
            -e "/^$front_imgix=/s|=.*|=$imgix|" \
            -e "/^S3_URL=/s|=.*|=$as3|" \
            -e "/^GTM_ID=/s|=.*|=$gtm|" $front_type/.env

  sed -i '' -e "/^S3_ACCESS_ID=/s|=.*|=$aid|" \
            -e "/^S3_SECRET_KEY=/s|=.*|=$skey|" cms/.env
  
  sleep 1

  read -p $'\n'"Is the latest db in the db-seed folder? Press enter when ready..."

  touch config-files/logs/.check-env_done
else 
  echo "Env setup already completed."; 
fi