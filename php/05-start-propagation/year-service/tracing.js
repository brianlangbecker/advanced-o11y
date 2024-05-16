// tracing.js will contain your tracing setup code 
// tracing setup and configuration should be run before your application code
// We'll do this with the -r, --require module flag

const process = require('process');
const opentelemetry = require("@opentelemetry/sdk-node")
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");
const { OTLPTraceExporter } =  require('@opentelemetry/exporter-trace-otlp-grpc');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');




// Define the resource for the SDK, including the service name using a string key
const resource = new Resource({
  [SemanticResourceAttributes.SERVICE_NAME]: 'year-service',  // Replace 'your-service-name' with the actual name of your service
});

const sdk = new opentelemetry.NodeSDK({
  resource: resource,
  traceExporter: new OTLPTraceExporter(),
  instrumentations: [ getNodeAutoInstrumentations({
      // We recommend disabling fs automatic instrumentation because 
      // it can be noisy and expensive during startup
      '@opentelemetry/instrumentation-fs': {
        enabled: false,
      },
    })]
})


sdk.start()