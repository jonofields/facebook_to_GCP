## facebook_to_GCP

This project is the code for a ETL pipeline for Facebook Ads Insights and Google Cloud Platform.  The Google Cloud products that are used for this
pipeline include: Cloud Functions, Google Cloud Storage, a lightweight VM within Compute Engine, Pub Sub, Cloud Scheduler, and BigQuery.  The pipeline starts at 
7am by uploading all existing Facebook Ads data to a Cloud Storage bucket.  The function will transform the data into newline delimited json format, for easy BigQuery table
creation, and name the file as "date".json.  Not much later, a scheduled VM instance starts, which runs a shell script on start-up with crontab. This shell script
creates a BigQuery table, loads the recently uploaded data, and defines the schema with a json file in the VMs memory.  The table expires before the next day's
data is uploaded.

The point of the pipeline is to create a queryable Facebook Ads Insights table that recycles itself.  This way your BigQuery datasets don't get bogged down 
with tables, and if going back in time is ever necesary, it is as simple as creating a table from old data in Cloud Storage.

Here are the steps if you wish to set up this pipeline using the GCP console:

1. Set up an account within Facebook for Developers.  This account needs to be linked to your Facebook account that is associated with the Business in order 
to access the data from the API.

2. Create an app within Facebook for Developers and make sure that you mark that you will be using this app for accessing Insights API data and generate an access token.
In order to make calls to the API you will need the APP ID, APP SECRET, ACCESS TOKEN, and the ACCOUNT ID (of the business account).  

3. Navigate to Google Cloud Storage and create a bucket.

4. Within Google Cloud create a Cloud Function and set that function to be triggered by pub sub. If you are using the console, the option to create a Pub Sub Topic 
will be in the drop down when you are asked which Topic to use for your function.  

5. Configure the function as you see fit - for reference our call returns a little under a GB, and the execution takes around 30s.  Though, leave plenty of room for growth!

6. Set the functions runtime to Python and copy and paste the main.py file, requirements.txt file into the GCP code editor.  You can also upload the files as a zip, though make sure you select both files individually and then compress.  If you create a folder for the files and compress the folder, the function will return an error. 
    a. In order to create customizations in the python function, use the Facebook Insights API docs for the specific attribute names.  For instance, if you would prefer a smaller window of time, like 90 days instead of the maximum.
    b. GCP asks for the function's name as an entry point.  In my case this was facebook_to_storage.
    c. Make sure that within the upload_blob function all arguments are updated.  Set the bucket name value to the GCS bucket you create earlier!!!!


7. The next step is to set up Cloud Scheduler. Input the function, the pub sub topic, the time in cron - my time was 7am - "0 7 * * *", the message to be sent, and the attributes (access token and previously mentioned info).  Make sure the message matches the message within you Cloud Function if statement, and the attributes are all correct so the API can be called.

8. Test your setup by having Cloud Scheduler run the job.  Navigate to the Cloud Function interface and make sure that the job ran with 'ok'.  If the function failed check the logs to troubleshoot any issues.  If all went according to plan there should be a json file with the current date as the name, and json of all of your Facebook ads data. If you click the "download" button for the text file a new tab will open with the ugliest json you have ever seen, but it is palatable for BigQuery!


9. From here you will need to start a VM instance within Compute Engine.  Since the VM instances come with the GCP CLI pre-installed, and a service account that can access your other cloud resources, we can create tables in BigQuery and load our facebook data into the tables.  When creating the VM instance:
    a. Use a low memory VM.
    b. Give it access to the appropriate cloud resources.
    c. Give the VM a GCP variable (distinct key and value)
    
    
10. Before you continue: Create a dataset within bigquery, and make sure that dataset name is updated in the shell script.  Upload that script, and the schema.json file to a cloud bucket.


11. Open the ssh and create a directory (mkdir) called scripts.  Use the cp command to copy the .sh file and schema file from the cloud storage bucket they are placed in, and use the scripts directory and their destination.  You should be able to test the script by running sh scripts/to_bq.sh and there should be a new data table in BigQuery!


12. Open up crontab with the command crontab -e and create a new cron job with - @reboot sh scripts/to_bq.sh


13. Now replicate the cloud function - cloud scheduler process we did earlier to create start compute instance, stop compute instance functions that will start and stop our VM automatically at the requested time.  Due to the cron job, our .sh file will run any time the compute instance is started.  


IMPORTANT - the table that is created in BigQuery has an expiration for a little less than one day.  A new table will not be created anytime there is already a table in the dataset, and the script will not work, so anytime you run the script before the before the automatic expiration, the old table must be deleted.  If you run the script outside of the schedule, make sure to delete that table so the scheduled process works.


