<?php declare(strict_types=1);

namespace App\OpenTelemetry;

require dirname(__DIR__) . '/../vendor/autoload_runtime.php';


use OpenTelemetry\API\Trace\Propagation\TraceContextPropagator;
use OpenTelemetry\SDK\Common\Time\ClockFactory;
use OpenTelemetry\Contrib\Otlp\OtlpHttpTransportFactory;
use OpenTelemetry\Contrib\Otlp\SpanExporter;
use OpenTelemetry\SDK\Common\Attribute\Attributes;
use OpenTelemetry\SDK\Trace\SpanProcessor\BatchSpanProcessor;
use OpenTelemetry\SDK\Trace\TracerProvider;
use OpenTelemetry\SDK\Sdk;
use OpenTelemetry\API\Signals;
use OpenTelemetry\SDK\Common\Configuration\Configuration;
use OpenTelemetry\SDK\Common\Configuration\Variables;
use OpenTelemetry\SDK\Resource\ResourceInfo;
use OpenTelemetry\SemConv\ResourceAttributes;
use OpenTelemetry\Contrib\Otlp\OtlpUtil;


class SdkBuilder
{

    public function build(array $resourceAttributes = []): void
    {
        $resource = ResourceInfo::create(Attributes::create([
            ResourceAttributes::SERVICE_NAMESPACE => 'Demo',
            ResourceAttributes::SERVICE_NAME => 'year-php',
            ...$resourceAttributes
        ]));

        $headers = [];
        $headers = OtlpUtil::getHeaders(Signals::TRACE);

        // If using collector, it probably works better with 'application/json'. For Honeycomb it only worked with 'application/x-protobuf'/ C
        $transport = (new OtlpHttpTransportFactory())->create(Configuration::getString(Variables::OTEL_EXPORTER_OTLP_ENDPOINT), 'application/x-protobuf', $headers);
        $exporter = new SpanExporter($transport);

        /**
         * BatchSpanProcessor is used instead of SimpleSpanProcessor to avoid sending requests to the collector every time
         * a span ends. BatchSpanProcessor will submit a single request for every span within a given interval or when
         * the number of span accumulated exceeded a certain threshold.
         */
        $tracerProvider = new TracerProvider(
            spanProcessors: [new BatchSpanProcessor($exporter, ClockFactory::getDefault())],
            resource: $resource,
        );



        Sdk::builder()
            ->setTracerProvider($tracerProvider)
            ->setPropagator(TraceContextPropagator::getInstance())
            ->setAutoShutdown(true)
            ->buildAndRegisterGlobal();
    }
}