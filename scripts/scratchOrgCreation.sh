#! /bin/bash
# ECHO COMMAND

echo "Authenticating Dev Hub"
authURL = "force://PlatformCLI::5Aep861FpKlGRwv8KDJ.IORqWSwK27gBwEalQxDVda6lxUsH_ZPvpOwxauEp6WebKaklxAtu3EfCy3gcVJOiLKD@poprekcloudsolutions-dev-ed.my.salesforce.com"
echo "${authURL}" > ./DEVHUB_SFDX_URL.txt

sfdx auth:sfdxurl:store --sfdxurlfile ./DEVHUB_SFDX_URL.txt --setdefaultdevhubusername --setalias integrationDevSB 

if [ "$?" = "1" ]
  then
    echo "ERROR: Authentication failed"
      exit
  fi
echo "Authentication Successful"
rm -f ./DEVHUB_SFDX_URL.txt
echo "Creating Scratch Org..."
sfdx force:org:create 
                   --targetdevhubusername integrationDevSB 
                   --definitionfile ./config/project-scratch-def.json 
                   --setalias validationOrg 
                   --setdefaultusername 
                   --durationdays 1

if [ "$?" = "1" ]
  then
    echo "ERROR: Scratch Org Creation failed"
      exit
  fi
echo "Scratch Org Created Successfully..."
echo "🐼 Installing package, please wait. It may take a while."
packageId="04t4W000002g0asQAA"
sfdx force:package:install -p "${packageId}" -u validationOrg -w 10
if [ "$?" = "1" ]
then
  echo "🐼 "
    echo "🐼 ERROR: Installing Packing"
  echo "🐼 "
    read -n 1 -s -r -p "🐼 Press any key to continue"
    exit
fi
interval=180
((end_time=${SECONDS}+3600))
while ((${SECONDS} < ${end_time}))
 do
  sfdx force:source:deploy -p force-app/main/default -u validationOrg
  if [ "$?" = "1" ]
  then
      echo "Package installation in progress"
    else
        echo "Package installed successfully" 
    fi
    sleep ${interval}
  done 

echo "Running Test Classes..."
sfdx force:apex:test:run 
                   --testlevel RunAllTestsInOrg 
                   --codecoverage 
                   --resultformat human 
                   --outputdir ./tests/apex 
                   --wait 20

echo "Deleting the scratch Org..."
sfdx force:org:delete 
                   --noprompt 
                   --targetusername validationOrg

echo "Validation Successful..."
