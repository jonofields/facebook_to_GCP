from google.cloud import storage
from facebook_business.api import FacebookAdsApi
import logging
from facebook_business.adobjects.adaccount import AdAccount
from facebook_business.adobjects.adsinsights import AdsInsights
from facebook_business.adobjects.campaign import Campaign
from datetime import datetime, date
import base64
import json


date_td = date.today()
logger = logging.getLogger()

         

def upload_blob(bucket_name, destination_blob_name, contents):

    storage_client = storage.Client()
    #formats contents into newline delimited json
    contents = '\n'.join(map(json.dumps,[c for c in contents] ))
    
    
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_string(contents)    

    print('Data has been sent as {} to {}'.format(destination_blob_name,bucket_name))


def facebook_to_storage(event,context):

    
    
    pubsub_message = base64.b64decode(event['data']).decode('utf-8')

    if pubsub_message == 'get_facebook':

        app_id = event['attributes']['app_id']
        app_secret = event['attributes']['app_secret']
        access_token = event['attributes']['access_token']
        account_id = event['attributes']['account_id']

    

        try:
            FacebookAdsApi.init(app_id,app_secret,access_token)

            account = AdAccount('act_'+str(account_id))
    


            insights = account.get_insights(fields=[
                AdsInsights.Field.campaign_id,
                AdsInsights.Field.campaign_name,
                AdsInsights.Field.adset_name,
                AdsInsights.Field.ad_name,
                AdsInsights.Field.spend,
                AdsInsights.Field.impressions,
                AdsInsights.Field.actions,
                AdsInsights.Field.cost_per_action_type,
                AdsInsights.Field.date_start,
                AdsInsights.Field.date_stop
            ],
            params={
                'level': 'ad',
                'date_preset' : 'maximum'
            })
   
        except Exception as e:
            logger.info(e)
            print(e)
            raise    
        
     

        fb_data = []
    

        for index, item in enumerate(insights):

            actions_i = []
            cost_per_action_i = []

            if 'actions' in item:
                  for i, value in enumerate(item['actions']):
                      actions_i.append({'action_type' : value['action_type'],'value' : value['value']})

            if 'cost_per_action_type' in item:          
                for i, value in enumerate(item['cost_per_action_type']):
                      cost_per_action_i.append({'action_type' : value['action_type'],'value' : value['value']})    
                
    

            fb_data.append({'date_start' : item['date_start'],
                           'date_stop' : item['date_stop'],
                           'campaign_name' : item['campaign_name'],
                           'campaign_id' : item['campaign_id'],
                           'adset_name' : item['adset_name'],
                           'ad_name' : item['ad_name'],
                           'spend' : item['spend'],
                           'impressions' : item['impressions'],
                           'action' : actions_i,
                           'cost_per_action' : cost_per_action_i
                        
                           })                   
        


        upload_blob(<bucket name>, f'facebook/{date_td}.json',fb_data)

        print("""This Function was triggered by messageId {} published at {} to {}
    """.format(context.event_id, context.timestamp, context.resource["name"]))

        return 'ok'
