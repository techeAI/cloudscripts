#!/bin/bash
apt update -y
apt upgrade -y
read -p "Do you want to deploy multiple organizations on a single domain name ?(Y/N) " answer

if [[ $answer == [Yy]* ]]; then
    echo "Please Provide org name in sort to use for subdomain (exapme org1)"
    read pdname
elif [[ $answer == [Nn]* ]]; then
        pdname=""
else
    echo "Invalid response. Please answer yes (y) or no (n)."
    echo "Please run script again."
    echo "exiting..."
    sleep 5
    exit 0

fi
echo "Please provide Base/Primary domain name (example: teche.ai)"
read dname
pip=$(curl -s https://ifconfig.me)
#echo "Public IP is $pip"

cp -r /etc/OT/sysconfig/teche_default.json /etc/OT/sysconfig/default_dash.json
cp -r /etc/OT/sysconfig/teche_default /etc/OT/sysconfig/default_nginx
cp -r /etc/OT/sysconfig/default-headscale-config.yaml /etc/OT/sysconfig/headscale-config.yaml



sed -i "s/domainname/$dname/g" /etc/OT/sysconfig/default_nginx
sed -i "s/prefix/$pdname/g" /etc/OT/sysconfig/default_nginx

sed -i "s/domainname/$dname/g" /etc/OT/sysconfig/default_dash.json
sed -i "s/prefix/$pdname/g" /etc/OT/sysconfig/default_dash.json

sed -i "s/domainname/$dname/g" /etc/OT/sysconfig/headscale-config.yaml
sed -i '/prefixes:/!s/prefix/'"$pdname"'/g' /etc/OT/sysconfig/headscale-config.yaml
#Teche Dashboard Redeploy
docker rm -f teche-dashboard
rm -rf /etc/OT/teche-dashboard_configs/default.json
rm -rf /etc/OT/teche-dashboard_data/*
docker run  --name teche-dashboard  --restart unless-stopped  -p 8080:7575  -v /etc/OT/teche-dashboard_configs:/app/data/configs  -v /var/run/docker.sock:/var/run/docker.sock -v /etc/OT/teche-dashboard_icons:/app/public/icons -v /etc/OT/teche-dashboard_data:/data  -d docker.io/techeai/techeos:latest
mv /etc/OT/sysconfig/default_dash.json /etc/OT/teche-dashboard_configs/default.json
      # END
#Redeploy vaultwarden
docker rm -f vaultwarden
rm -rf /etc/OT/vaultwarden/*
docker run -d --name vaultwarden --restart unless-stopped -v /etc/OT/vaultwarden/:/data/ -p 5023:80 vaultwarden/server:latest
        #END

#Redeploy Headscale
cd /root/headscale/ && docker-compose down
rm -rf /etc/OT/headscale/config/*
rm -rf /etc/OT/headscale/data/*
cp -r /etc/OT/sysconfig/headscale-config.yaml /etc/OT/headscale/config/config.yaml
cd /root/headscale/ && docker-compose up -d

#Setting Up nginx
mv /etc/OT/sysconfig/default_nginx /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sudo systemctl start nginx && sudo nginx -t
ttl=$(cat /etc/nginx/sites-enabled/default |grep server_name|sort | uniq|awk '{gsub(/;/, "", $2); print $2}' |wc -l)
echo "                                                         "
echo "************  Total No Of subdomains are : $ttl  *********************"
echo "                                                         "
echo "Create below mentioned subdomain in DNS and point to $pip IP with minimum TTL"
cat /etc/nginx/sites-enabled/default |grep server_name|sort | uniq|awk '{gsub(/;/, "", $2); print $2}'
sleep 5;
read -p "Once DNS is set press Y to continue? (Y/N): " choice
case "$choice" in
  [Yy])
    echo "Thanks for confirmation"
    echo "Waiting for 5 minutes to populate DNS"
    sleep 300
    echo "generating SSL certificates"
    certbot --nginx
    sudo systemctl restart nginx
    sudo systemctl enable nginx
    ;;
  [Nn])
    echo "You chose not to continue."
    exit 0
    ;;
  *)
    echo "Invalid input. Please enter Y or N."
    ;;
esac
hname=$(cat /etc/nginx/sites-enabled/default|grep server_name|grep dash|sort | uniq|awk '{gsub(/;/, "", $2); print $2}')
clear
echo "Dashboard is available at https://$hname"

