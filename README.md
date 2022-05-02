# facebook_to_GCP

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

3. Within Google Cloud create a Cloud Function and set that function to be triggered by pub sub. If you are using the console, the option to create a Pub Sub Topic 
will be in the drop down when you are asked which Topic to use for your function.  

4. Configure the function as you see fit - for reference our call returns a little under a GB, and the execution takes around 30s.  Though, leave plenty of room for growth!


