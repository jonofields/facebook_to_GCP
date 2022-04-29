/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} event Event payload.
 * @param {!Object} context Metadata for the event.
 */
 const compute = require('@google-cloud/compute');
 const instancesClient = new compute.InstancesClient();
 const operationsClient = new compute.ZoneOperationsClient();
 
 async function waitForOperation(projectId, operation) {
   while (operation.status !== 'DONE') {
     [operation] = await operationsClient.wait({
       operation: operation.name,
       project: projectId,
       zone: operation.zone.split('/').pop(),
     });
   }
 }
 
 /**
  * Starts Compute Engine instances.
  *
  * Expects a PubSub message with JSON-formatted event data containing the
  * following attributes:
  *  zone - the GCP zone the instances are located in.
  *  label - the label of instances to start.
  *
  * @param {!object} event Cloud Function PubSub message event.
  * @param {!object} callback Cloud Function PubSub callback indicating
  *  completion.
  */
 exports.startInstancePubSub = async (event, context, callback) => {
   try {
     const project = await instancesClient.getProjectId();
     const payload = _validatePayload(event);
     const options = {
       filter: `labels.${payload.label}`,
       project,
       zone: payload.zone,
     };
 
     const [instances] = await instancesClient.list(options);
 
     await Promise.all(
       instances.map(async instance => {
         const [response] = await instancesClient.start({
           project,
           zone: payload.zone,
           instance: instance.name,
         });
 
         return waitForOperation(project, response.latestResponse);
       })
     );
 
     // Operation complete. Instance successfully started.
     const message = 'Successfully started instance(s)';
     console.log(message);
     callback(null, message);
   } catch (err) {
     console.log(err);
     callback(err);
   }
 };
 
 /**
  * Validates that a request payload contains the expected fields.
  *
  * @param {!object} payload the request payload to validate.
  * @return {!object} the payload object.
  */
 const _validatePayload = event => {
   let payload;
   try {
     payload = JSON.parse(Buffer.from(event.data, 'base64').toString());
   } catch (err) {
     throw new Error('Invalid Pub/Sub message: ' + err);
   }
   if (!payload.zone) {
     throw new Error("Attribute 'zone' missing from payload");
   } else if (!payload.label) {
     throw new Error("Attribute 'label' missing from payload");
   }
   return payload;
 };
 